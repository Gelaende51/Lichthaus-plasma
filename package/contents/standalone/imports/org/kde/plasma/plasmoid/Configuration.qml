/*
 * Plasmoid.configuration for the standalone window: the keys of
 * config/main.xml with its defaults (tests/test_standalone.py checks that
 * they match). The window is widget 1 (widgetIndex stays at its default),
 * and openAddBulb is the popup's one-shot flag.
 *
 * invertScroll, iconSet, clapLast and autoScanBluetooth are widget 1's in
 * the daemon (ui/WidgetSettings.qml): taken from its `get`, polled, and a
 * change goes back to it, so the tray widget shows it too. Nothing is kept
 * in a file of the window's own; a daemon that does not answer or is too old
 * to keep them leaves the defaults, and a change lasts until the window
 * closes. The widget, not the window, carries its old values over.
 *
 * Like KConfigPropertyMap: keys(), and valueChanged(key, value) after every
 * change, which AddBulbRedirect.qml, configBulbs.qml and main.qml listen to.
 */
import QtQuick
import "../../../../../../ui"

QtObject {
    id: shim

    property int widgetIndex: 1
    property bool invertScroll: false
    property string iconSet: "lighthouse"
    property string clapLast: "both"
    property bool openAddBulb: false
    property bool autoScanBluetooth: false

    signal valueChanged(string key, var value)

    function keys() {
        return ["widgetIndex", "invertScroll", "iconSet", "clapLast", "openAddBulb", "autoScanBluetooth"]
    }

    // Widget 1 in the daemon: the window polls it as the tray widget does.
    readonly property HausCtl daemon: HausCtl { widget: 1 }
    readonly property WidgetSettings daemonSettings: WidgetSettings {
        ctl: shim.daemon
        config: shim
        migrate: false
    }

    onWidgetIndexChanged: valueChanged("widgetIndex", widgetIndex)
    onInvertScrollChanged: valueChanged("invertScroll", invertScroll)
    onIconSetChanged: valueChanged("iconSet", iconSet)
    onClapLastChanged: valueChanged("clapLast", clapLast)
    onOpenAddBulbChanged: valueChanged("openAddBulb", openAddBulb)
    onAutoScanBluetoothChanged: valueChanged("autoScanBluetooth", autoScanBluetooth)
}
