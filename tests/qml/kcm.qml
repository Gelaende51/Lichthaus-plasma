/*
 * tests/test_kcm.py: the System Settings host (standalone/kcm.qml) as the
 * KCM loads it (standalone/imports on the import path, pageSource and
 * addBulb as initial properties), against fake-hauslicht-ctl. Prints FIRST
 * once the daemon's widget 1 values arrived (the page's cfg_ properties,
 * whether its Add dialog took the request), LAST after the page changed
 * cfg_invertScroll; ERROR when the host did not load.
 */
import QtQuick
import org.kde.plasma.plasmoid

Item {
    id: harness

    width: 800
    height: 600

    readonly property var cfg: Plasmoid.configuration
    property var host: null
    readonly property var page: host ? host.pageStack.currentItem : null

    Component.onCompleted: {
        const component = Qt.createComponent(Qt.resolvedUrl("../../package/contents/standalone/kcm.qml"))
        host = component.createObject(harness, { "pageSource": "configBulbs.qml", "pageTitle": "Bulbs", "addBulb": true })
        if (!host) {
            console.log("ERROR " + JSON.stringify(component.errorString()))
            Qt.quit()
        }
    }

    function dump(tag) {
        console.log(tag + " " + JSON.stringify({
            "depth": host.pageStack.depth, "title": page ? page.title : null,
            "cfg_invertScroll": page ? page.cfg_invertScroll : null,
            "invertScroll": cfg.invertScroll, "openAddBulb": cfg.openAddBulb
        }))
    }

    property int step: 0
    Timer {
        interval: 200
        repeat: true
        running: harness.host !== null
        onTriggered: harness.tick()
    }
    function tick() {
        if (cfg.daemon.pending > 0) return
        step++
        if (step === 1) cfg.daemon.refresh()
        else if (step === 2) { dump("FIRST"); page.cfg_invertScroll = !page.cfg_invertScroll }
        else if (step === 3) cfg.daemon.refresh()
        else { dump("LAST"); Qt.quit() }
    }
}
