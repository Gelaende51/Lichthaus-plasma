/*
 * tests/test_kcm.py: Configure → Sound in the System Settings host
 * (standalone/kcm.qml), against fake-hauslicht-ctl with every widget's clap
 * off. Prints FIRST once the test meter (clap-meter --listen) and Recent
 * sounds (clap-hits) answered, then picks a microphone; LAST after that
 * reply; ERROR when the host did not load.
 */
import QtQuick
import org.kde.plasma.plasmoid

Item {
    id: harness

    width: 800
    height: 600

    property var host: null
    readonly property var page: host ? host.pageStack.currentItem : null

    Component.onCompleted: {
        const component = Qt.createComponent(Qt.resolvedUrl("../../package/contents/standalone/kcm.qml"))
        host = component.createObject(harness, { "pageSource": "configSound.qml", "pageTitle": "Sound" })
        if (!host) {
            console.log("ERROR " + JSON.stringify(component.errorString()))
            Qt.quit()
        }
    }

    function dump(tag) {
        console.log(tag + " " + JSON.stringify({
            "title": page.title, "available": page.available, "listening": page.listening,
            "hearing": page.hearing, "test": page.meter.test === true, "sourceMissing": page.sourceMissing,
            "muted": page.muted, "last": page.lastText(), "summary": page.hitsSummary(),
            "hits": page.hitList.length, "sources": page.sources.length, "clapSource": page.st.clap_source || ""
        }))
    }

    property int step: 0
    property int waited: 0
    Timer {
        interval: 200
        repeat: true
        running: harness.host !== null
        onTriggered: harness.tick()
    }
    function tick() {
        if (!page || page.ctl.pending > 0) return
        if (step === 0) {
            // the meter and the hits arrive on their own timers (≤ 10 s)
            if ((page.meter.test === undefined || page.hitList.length === 0 || page.sources.length < 2) && ++waited < 50) return
            dump("FIRST")
            page.act(["set", "clap_source=usb_mic"])
        } else if (step === 2) {
            dump("LAST")
            Qt.quit()
        }
        step++
    }
}
