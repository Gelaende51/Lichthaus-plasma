"""ui/WidgetSettings.qml: the widget's own settings (invertScroll, iconSet,
clapLast, autoScanBluetooth) kept by the daemon per widget. Runs the real
HausCtl.qml under Qt's qml runtime (offscreen) against a fake hauslicht-ctl
in a temporary home, so nothing reaches a live daemon: the one-time
migration of the widget's values, taking over the daemon's, a change from
another front end, a local change, an old daemon, no daemon, a refused
value, and the settings window's stand-in (widget 1, no migration).

Skipped where qml6 or Plasma5Support's QML module is missing (the CI's
pytest job); run locally with `python -m pytest -q tests`."""
import json
import os
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
QML = ROOT / "tests" / "qml"
IMPORTS = ROOT / "package" / "contents" / "standalone" / "imports"
RUNTIME = shutil.which("qml6") or shutil.which("qml-qt6")
P5SUPPORT = any(Path(d, "org/kde/plasma/plasma5support/qmldir").is_file()
                for d in ("/usr/lib/qt6/qml", "/usr/lib64/qt6/qml", "/usr/lib/x86_64-linux-gnu/qt6/qml"))
pytestmark = pytest.mark.skipif(not (RUNTIME and P5SUPPORT), reason="needs qml6 and Plasma5Support")

LOCAL = {"invertScroll": True, "iconSet": "mdi-bulb", "clapLast": "snap", "autoScanBluetooth": True}


def harness(tmp_path, qml, daemon, *extra):
    """Run a harness; returns (its FIRST/SECOND/LAST dumps, the fake's final
    state, the ctl calls in order)."""
    home = tmp_path / "home"
    (home / ".local" / "bin").mkdir(parents=True)
    shutil.copy(QML / "fake-hauslicht-ctl", home / ".local" / "bin" / "hauslicht-ctl")
    state = tmp_path / "state.json"
    state.write_text(json.dumps(daemon))
    env = {**os.environ, "HOME": str(home), "FAKE_HAUSLICHT_STATE": str(state),
           "HAUSLICHT_SOCK": str(tmp_path / "no.sock"),  # whatever runs: never the live daemon
           "XDG_CONFIG_HOME": str(home / ".config"), "QT_QPA_PLATFORM": "offscreen",
           "QT_FORCE_STDERR_LOGGING": "1", "LANG": "C"}
    env.pop("QT_LOGGING_RULES", None)
    p = subprocess.run([RUNTIME, *extra, str(QML / qml), "--", "run"], env=env, capture_output=True,
                       text=True, timeout=60)
    (tmp_path / "qml.log").write_text(p.stderr)  # the runtime's messages, for tests that read them
    dumps = {}
    for line in p.stderr.splitlines():
        tag, _, rest = line.removeprefix("qml: ").partition(" ")
        if tag in ("FIRST", "SECOND", "LAST"):
            dumps[tag] = json.loads(rest)
    assert "LAST" in dumps, p.stderr
    log = tmp_path / "state.json.log"
    calls = [json.loads(x) for x in log.read_text().splitlines()] if log.exists() else []
    return dumps, json.loads(state.read_text()), calls


def sets(calls):
    return [c[1:] for c in calls if c[:1] == ["widget-settings-set"]]


def before_fake_set(calls):
    return calls[:calls.index(["fake-set", "icon_set=tabler-bulb"])]


def test_first_contact_carries_the_widgets_values_over(tmp_path):
    dumps, state, calls = harness(tmp_path, "widget.qml", {"widgets": {}})
    assert dumps["FIRST"] == LOCAL
    assert sets(before_fake_set(calls)) == [["invert_scroll=on", "icon_set=mdi-bulb", "clap_last=snap",
                                              "auto_scan_bluetooth=on"]]
    # another front end's change arrives with the next get
    assert dumps["SECOND"] == {**LOCAL, "iconSet": "tabler-bulb"}
    # a local change goes to the daemon
    assert dumps["LAST"] == {**LOCAL, "iconSet": "tabler-bulb", "invertScroll": False}
    assert sets(calls)[-1] == ["invert_scroll=off"]
    assert state["widgets"]["1"] == {"invert_scroll": False, "icon_set": "tabler-bulb", "clap_last": "snap",
                                     "auto_scan_bluetooth": True}


def test_the_daemons_values_win_and_nothing_migrates(tmp_path):
    daemon = {"invert_scroll": False, "icon_set": "fluent-bulb", "clap_last": "clap", "auto_scan_bluetooth": False}
    dumps, state, calls = harness(tmp_path, "widget.qml", {"widgets": {"1": daemon}})
    assert dumps["FIRST"] == {"invertScroll": False, "iconSet": "fluent-bulb", "clapLast": "clap",
                              "autoScanBluetooth": False}
    assert sets(calls) == []  # LAST sets invertScroll to false: the daemon's already
    assert state["widgets"]["1"] == {**daemon, "icon_set": "tabler-bulb"}


def test_only_the_missing_keys_migrate(tmp_path):
    dumps, state, calls = harness(tmp_path, "widget.qml", {"widgets": {"1": {"icon_set": "fluent-bulb"}}})
    assert dumps["FIRST"] == {**LOCAL, "iconSet": "fluent-bulb"}
    assert sets(before_fake_set(calls)) == [["invert_scroll=on", "clap_last=snap", "auto_scan_bluetooth=on"]]


@pytest.mark.parametrize("daemon", [{"old": True, "widgets": {}}, {"down": True, "widgets": {}}],
                         ids=["old daemon", "no daemon"])
def test_without_the_commands_the_configuration_is_all_there_is(tmp_path, daemon):
    dumps, _state, calls = harness(tmp_path, "widget.qml", daemon)
    assert dumps["FIRST"] == LOCAL and dumps["SECOND"] == LOCAL
    assert dumps["LAST"] == {**LOCAL, "invertScroll": False}
    assert sets(calls) == []


def test_a_refused_migration_is_not_retried_on_every_get(tmp_path):
    dumps, _state, calls = harness(tmp_path, "widget.qml", {"refuse": True, "widgets": {}})
    assert dumps["FIRST"] == LOCAL
    assert len(sets(before_fake_set(calls))) == 1
    assert sum(c == ["get"] for c in before_fake_set(calls)) >= 2


def test_the_settings_window_is_widget_1_of_the_daemon(tmp_path):
    daemon = {"widgets": {"1": {"icon_set": "fluent-bulb", "invert_scroll": True}}}
    dumps, state, calls = harness(tmp_path, "window.qml", daemon, "-I", str(IMPORTS))
    # the daemon's values; the keys it lacks keep the defaults and are not written
    assert dumps["FIRST"] == {"invertScroll": True, "iconSet": "fluent-bulb", "clapLast": "both",
                              "autoScanBluetooth": False}
    assert dumps["LAST"]["autoScanBluetooth"] is True
    assert sets(calls) == [["auto_scan_bluetooth=on"]]
    assert all(c[0] != "@1" and not c[0].startswith("@") for c in calls)  # widget 1: no @N
    assert state["widgets"]["1"] == {"icon_set": "fluent-bulb", "invert_scroll": True, "auto_scan_bluetooth": True}
    assert not (tmp_path / "home" / ".config" / "hauslicht" / "settings-window.ini").exists()
