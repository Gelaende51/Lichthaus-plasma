/*
 * One Configure page in KDE System Settings: the host the KCMs of
 * Haus.Licht-plasma's kcm/ load (kcm_hauslicht_bulbs and its siblings, one
 * per page of config/config.qml). The KCM gives it a QML engine of its own
 * with standalone/imports on the import path, so the page's
 * `import org.kde.plasma.plasmoid` lands on the same stand-in as in the
 * standalone window (main.qml): the KCM acts as widget 1.
 *
 * The page gets the widget's settings as cfg_ properties, and a change goes
 * straight back to the stand-in (which keeps them in the daemon), as in
 * main.qml's open(). System Settings shows the page's name above it and has
 * no Apply: every page changes the daemon directly.
 *
 * pageSource, pageTitle and addBulb are set by the KCM (initial properties);
 * requestAddBulb() is called when System Settings is asked for "add" again.
 */
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Kirigami.ApplicationItem {
    id: root

    required property string pageSource   // as config/config.qml lists it, e.g. "configBulbs.qml"
    property string pageTitle
    property bool addBulb: false
    readonly property var config: Plasmoid.configuration

    // As KCMUtils' own host of QML KCMs (kcmoduleqml.cpp): the view's size,
    // never one of its own.
    width: Window.width
    height: Window.height
    implicitWidth: Math.max(pageStack.implicitWidth, Kirigami.Units.gridUnit * 36)
    implicitHeight: Math.max(pageStack.implicitHeight, Kirigami.Units.gridUnit * 20)

    // The title is System Settings' header above the KCM.
    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.None
    pageStack.columnView.columnResizeMode: Kirigami.ColumnView.SingleColumn
    wideScreen: true

    // The popup's "Connect new bulb…": the Bulbs page opens its Add dialog
    // while openAddBulb is set and clears it (configBulbs.qml).
    function requestAddBulb() {
        config.openAddBulb = true
    }

    Component.onCompleted: {
        const component = Qt.createComponent(Qt.resolvedUrl("../ui/" + pageSource))
        if (component.status !== Component.Ready) {
            console.warn(component.errorString())
            return
        }
        if (addBulb) requestAddBulb()
        const page = component.createObject(null, { "title": pageTitle })
        if (!page) return
        for (const key of config.keys()) {
            const prop = "cfg_" + key
            if (!(prop in page)) continue
            page[prop] = config[key]
            page[prop + "Changed"].connect(() => { root.config[key] = page[prop] })
        }
        pageStack.push(page)
    }

    // The daemon's values come after the page opened, or change in the tray
    // widget meanwhile: into the page's cfg_ property.
    Connections {
        target: root.config
        function onValueChanged(key, value) {
            const page = root.pageStack.currentItem
            const prop = "cfg_" + key
            if (page && prop in page && page[prop] !== value) page[prop] = value
        }
    }
}
