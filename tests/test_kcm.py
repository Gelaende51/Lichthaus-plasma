"""The System Settings KCMs (kcm/): one per page of config/config.qml, in the
category their metadata names, and the host they load (standalone/kcm.qml)
gives the page widget 1's settings from the daemon as cfg_ properties. The
QML part runs under Qt's qml runtime (offscreen) against fake-hauslicht-ctl,
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
    return [json.loads(p.read_text(encoding="utf-8")) for p in sorted(KCM.glob("metadata/kcm_hauslicht_*.json"))]


def test_one_kcm_per_configure_page_in_the_same_order():
    pages = sorted(metadata(), key=lambda m: m["X-KDE-Weight"])
    assert [(m["KPlugin"]["Name"], m["KPlugin"]["Icon"], m["X-HausLicht-Page"]) for m in pages] == categories()
    for m in pages:
        assert m["X-KDE-System-Settings-Parent-Category"] == "hauslicht"
        assert m["KPlugin"]["Name[de]"] and m["KPlugin"]["Description[de]"] and m["X-KDE-Keywords[de]"]


def test_cmake_builds_every_metadata_file():
    pages = re.search(r"set\(HAUSLICHT_PAGES ([^)]*)\)", (KCM / "CMakeLists.txt").read_text()).group(1).split()
    assert sorted(f"kcm_hauslicht_{p}.json" for p in pages) == sorted(p.name for p in KCM.glob("metadata/*.json"))


def test_the_category_sits_under_hardware():
    c = configparser.ConfigParser(interpolation=None)
    c.optionxform = str
    c.read(KCM / "settings-hardware-hauslicht.desktop", encoding="utf-8")
    entry = c["Desktop Entry"]
    assert entry["X-KDE-ServiceTypes"] == "SystemSettingsCategory"
    assert entry["X-KDE-System-Settings-Category"] == "hauslicht"
    assert entry["X-KDE-System-Settings-Parent-Category"] == "hardware"
    assert entry["Comment[de]"] and entry["X-KDE-Keywords[de]"]


def test_the_kcm_looks_for_the_host_the_package_has():
    source = (KCM / "hauslichtkcm.cpp").read_text(encoding="utf-8")
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
