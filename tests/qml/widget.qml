/*
 * tests/test_widget_settings.py: ui/WidgetSettings.qml with the real
 * HausCtl.qml against fake-lichthaus-ctl ($HOME/.local/bin in a temporary
 * home). The configuration is a plain object holding non-default values, as
 * a widget's would after the user chose them. Prints FIRST (after the first
 * gets: migration or the daemon's values), SECOND (after another front end
 * changed icon_set) and LAST (after a local change of invertScroll).
 */
import QtQuick
import "../../package/contents/ui"

Item {
    id: harness

    readonly property var args: Qt.application.arguments
    readonly property string scenario: args[args.length - 1]

    QtObject {
        id: cfg
        property bool invertScroll: true
        property string iconSet: "mdi-bulb"
        property string clapLast: "snap"
        property bool autoScanBluetooth: true
    }
    HausCtl {
        id: hc
        widget: 1
        poll.running: false
    }
    WidgetSettings {
        ctl: hc
        config: cfg
    }

    function dump(tag) {
        console.log(tag + " " + JSON.stringify({
            "invertScroll": cfg.invertScroll, "iconSet": cfg.iconSet,
            "clapLast": cfg.clapLast, "autoScanBluetooth": cfg.autoScanBluetooth
        }))
    }

    property int step: 0
    Timer {
        interval: 200
        repeat: true
        running: true
        onTriggered: harness.tick()
    }
    function tick() {
        if (hc.pending > 0) return
        step++
        if (step === 1 || step === 2) hc.refresh()
        else if (step === 3) { dump("FIRST"); hc.run(["fake-set", "icon_set=tabler-bulb"]) }
        else if (step === 4) hc.refresh()
        else if (step === 5) { dump("SECOND"); cfg.invertScroll = false }
        else if (step === 6) hc.refresh()
        else { dump("LAST"); Qt.quit() }
    }
}
