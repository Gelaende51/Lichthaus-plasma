"""The System Settings KCMs (kcm/): one per page of config/config.qml, in the
category their metadata names, and the host they load (standalone/kcm.qml)
gives the page widget 1's settings from the daemon as cfg_ properties. The
QML part runs under Qt's qml runtime (offscreen) against fake-lichthaus-ctl,
as tests/test_widget_settings.py does; skipped where qml6 or Plasma5Support is
missing."""
import configparser
import json
import re
from pathlib import Path

import pytest

from test_widget_settings import IMPORTS, P5SUPPORT, RUNTIME, harness, sets

ROOT = Path(__file__).resolve().parent.parent
KCM = ROOT / "kcm"
CONTENTS = ROOT / "package" / "contents"


def categories():
    """config/config.qml's categories in order: (name, icon, source)."""
    text = (CONTENTS / "config" / "config.qml").read_text(encoding="utf-8")
    blocks = re.findall(r"ConfigCategory \{(.*?)\}", text, re.S)
    out = []
    for b in blocks:
        name = re.search(r'name: (?:german \? "[^"]*" : )?"([^"]*)"', b).group(1)
        out.append((name, re.search(r'icon: "([^"]*)"', b).group(1), re.search(r'source: "([^"]*)"', b).group(1)))
    return out


def metadata():
    return [json.loads(p.read_text(encoding="utf-8")) for p in sorted(KCM.glob("metadata/kcm_lichthaus_*.json"))]


def test_one_kcm_per_configure_page_in_the_same_order():
    pages = sorted(metadata(), key=lambda m: m["X-KDE-Weight"])
    assert [(m["KPlugin"]["Name"], m["KPlugin"]["Icon"], m["X-Lichthaus-Page"]) for m in pages] == categories()
    for m in pages:
        assert m["X-KDE-System-Settings-Parent-Category"] == "lichthaus"
        assert m["KPlugin"]["Name[de]"] and m["KPlugin"]["Description[de]"] and m["X-KDE-Keywords[de]"]


def test_cmake_builds_every_metadata_file():
    pages = re.search(r"set\(LICHTHAUS_PAGES ([^)]*)\)", (KCM / "CMakeLists.txt").read_text()).group(1).split()
    assert sorted(f"kcm_lichthaus_{p}.json" for p in pages) == sorted(p.name for p in KCM.glob("metadata/*.json"))


def test_the_category_sits_under_hardware():
    c = configparser.ConfigParser(interpolation=None)
    c.optionxform = str
    c.read(KCM / "settings-hardware-lichthaus.desktop", encoding="utf-8")
    entry = c["Desktop Entry"]
    assert entry["X-KDE-ServiceTypes"] == "SystemSettingsCategory"
    assert entry["X-KDE-System-Settings-Category"] == "lichthaus"
    assert entry["X-KDE-System-Settings-Parent-Category"] == "hardware"
    assert entry["Comment[de]"] and entry["X-KDE-Keywords[de]"]


def test_the_kcm_looks_for_the_host_the_package_has():
    source = (KCM / "lichthauskcm.cpp").read_text(encoding="utf-8")
    host = re.search(r'hostFile = u"([^"]+)"_s', source).group(1)
    imports = re.search(r'importsDir = u"([^"]+)"_s', source).group(1)
    assert (ROOT / "package" / host).is_file()
    assert (ROOT / "package" / imports) == IMPORTS


@pytest.mark.skipif(not (RUNTIME and P5SUPPORT), reason="needs qml6 and Plasma5Support")
def test_the_host_gives_the_page_widget_1s_settings(tmp_path):
    daemon = {"widgets": {"1": {"invert_scroll": True}}}
    dumps, state, calls = harness(tmp_path, "kcm.qml", daemon, "-I", str(IMPORTS))
    # the page, its title, the daemon's value as cfg_; the Add dialog took the request
    assert dumps["FIRST"] == {"depth": 1, "title": "Bulbs", "cfg_invertScroll": True,
                              "invertScroll": True, "openAddBulb": False}
    # a change on the page goes to the daemon as widget 1's
    assert dumps["LAST"]["invertScroll"] is False and dumps["LAST"]["cfg_invertScroll"] is False
    assert sets(calls)[-1] == ["invert_scroll=off"]
    assert state["widgets"]["1"]["invert_scroll"] is False
    assert all(not c[0].startswith("@") for c in calls)


DESKTOP_STYLE = any(Path(d, "org/kde/desktop/qmldir").is_file()
                    for d in ("/usr/lib/qt6/qml", "/usr/lib64/qt6/qml", "/usr/lib/x86_64-linux-gnu/qt6/qml"))


@pytest.mark.skipif(not (RUNTIME and P5SUPPORT and DESKTOP_STYLE),
                    reason="needs qml6, Plasma5Support and qqc2-desktop-style")
def test_the_page_loads_without_errors_in_plasmas_desktop_style(tmp_path, monkeypatch):
    # System Settings draws the pages in Plasma's desktop style
    # (qqc2-desktop-style), which reads a ComboBox's contentItem as the
    # TextInput of an editable box: the Icon set box's preview must answer it.
    monkeypatch.setenv("QT_QUICK_CONTROLS_STYLE", "org.kde.desktop")
    harness(tmp_path, "kcm.qml", {"widgets": {"1": {}}}, "--apptype", "widget", "-I", str(IMPORTS))
    log = (tmp_path / "qml.log").read_text()
    assert "TypeError" not in log, log


@pytest.mark.skipif(not (RUNTIME and P5SUPPORT), reason="needs qml6 and Plasma5Support")
def test_the_sound_page_runs_the_test_meter_while_clap_is_off(tmp_path):
    hit = {"time": "02:10:00.123", "kind": "clap", "family": 0.4, "accepted": True, "paired": True,
           "sequence": 3, "top": [["Clapping", 0.4]]}
    daemon = {"widgets": {"1": {}},
              "get": {"clap": "off", "clap_count": 3, "clap_status": {"state": "off", "available": True}},
              "replies": {
                  "clap-meter": {"state": "listening", "test": True, "level": 0.5, "source_missing": "gone_mic",
                                 "last": {"label": "Hands", "score": 0.5, "accepted": True, "age": 1.2}},
                  "clap-hits": {"count": 3, "hits": [hit] * 3},
                  "clap-sources": {"sources": [{"name": "usb_mic", "description": "USB microphone", "default": True}]},
                  "audio-sources": {"sources": []}}}
    dumps, state, calls = harness(tmp_path, "sound.qml", daemon, "-I", str(IMPORTS))
    # clap off everywhere: the page asks for a test run and shows what it hears
    assert dumps["FIRST"] == {"title": "Sound", "available": True, "listening": False, "hearing": True,
                              "test": True, "sourceMissing": "gone_mic", "muted": False,
                              "last": "Last: Hands 0.50 · 1 s ago", "summary": "Heard 3 · accepted 3 · triples 1",
                              "hits": 3, "sources": 2, "clapSource": ""}
    assert [c for c in calls if "clap-meter" in c][0][-2:] == ["clap-meter", "--listen"]
    # a microphone picked on the page reaches the daemon as the global setting
    assert any(c[-2:] == ["set", "clap_source=usb_mic"] for c in calls)
    assert state["get"]["clap_source"] == "usb_mic" and dumps["LAST"]["clapSource"] == "usb_mic"
