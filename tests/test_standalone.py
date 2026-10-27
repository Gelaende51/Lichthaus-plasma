"""The standalone settings window (package/contents/standalone/, run by
`hauslicht config`): its stand-in for Plasmoid.configuration declares every
key of config/main.xml with the same type and default, and the pages it hosts
are the ones config/config.qml lists."""
import re
import xml.etree.ElementTree as ET
from pathlib import Path

PLASMOID = Path(__file__).resolve().parent.parent / "package" / "contents"
STANDALONE = PLASMOID / "standalone"
SHIM = STANDALONE / "imports" / "org" / "kde" / "plasma" / "plasmoid" / "Configuration.qml"
KCFG = "{http://www.kde.org/standards/kcfg/1.0}"
QML_TYPES = {"Int": "int", "Bool": "bool", "String": "string"}


def main_xml():
    """{key: (qml type, default as QML source)} from config/main.xml."""
    out = {}
    for entry in ET.parse(PLASMOID / "config" / "main.xml").getroot().iter(f"{KCFG}entry"):
        kind = entry.get("type")
        default = entry.findtext(f"{KCFG}default", "")
        out[entry.get("name")] = (QML_TYPES[kind], f'"{default}"' if kind == "String" else default)
    return out


def shim():
    """The keys block: the properties declared before the valueChanged signal."""
    text = SHIM.read_text(encoding="utf-8").split("signal valueChanged")[0]
    return {name: (kind, value.strip()) for kind, name, value in
            re.findall(r"^    property (int|bool|string) (\w+): (.+)$", text, re.M)}


def test_shim_matches_main_xml():
    assert shim() == main_xml()


def test_shim_keys_list_matches():
    text = SHIM.read_text(encoding="utf-8")
    keys = re.search(r"function keys\(\) \{\s*return \[([^\]]*)\]", text).group(1)
    assert re.findall(r'"(\w+)"', keys) == list(main_xml())


def test_hosted_pages_exist():
    sources = re.findall(r'source: "([^"]+)"', (PLASMOID / "config" / "config.qml").read_text(encoding="utf-8"))
    assert sources
    for source in sources:
        assert (PLASMOID / "ui" / source).is_file()


def test_shim_keeps_the_widget_settings_in_the_daemon():
    """invertScroll, iconSet, clapLast, autoScanBluetooth: widget 1's in the
    daemon through ui/WidgetSettings.qml, no file of the window's own, and
    the window never carries its values over (the widget does)."""
    text = SHIM.read_text(encoding="utf-8")
    assert "settings-window.ini" not in text and not re.search(r"\bSettings \{", text) and "QtCore" not in text
    assert re.search(r"HausCtl \{ widget: 1 \}", text)
    assert re.search(r"WidgetSettings \{[^}]*migrate: false", text)
    synced = re.findall(r'"(\w+)": "\w+"', (PLASMOID / "ui" / "WidgetSettings.qml").read_text(encoding="utf-8"))
    assert synced == ["invertScroll", "iconSet", "clapLast", "autoScanBluetooth"]
    assert set(synced) <= set(main_xml())
