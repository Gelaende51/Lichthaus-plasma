/*
 * tests/test_widget_settings.py: the settings window's stand-in for
 * Plasmoid.configuration (standalone/imports first on the import path)
 * against fake-hauslicht-ctl. Prints FIRST once the daemon's widget 1 values
 * arrived, LAST after the window changed autoScanBluetooth.
 */
import QtQuick
import org.kde.plasma.plasmoid

Item {
    id: harness

    readonly property var cfg: Plasmoid.configuration

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
        if (cfg.daemon.pending > 0) return
        step++
        if (step === 1) cfg.daemon.refresh()
        else if (step === 2) { dump("FIRST"); cfg.autoScanBluetooth = true }
        else if (step === 3) cfg.daemon.refresh()
        else { dump("LAST"); Qt.quit() }
    }
}
