/*
 * Plasmoid.configuration for the standalone window: the keys of
 * config/main.xml with its defaults (tests/test_standalone.py checks that
 * they match), kept in ~/.config/hauslicht/settings-window.ini instead of the
 * widget's appletsrc. The window is widget 1 (widgetIndex stays at its
 * default), and openAddBulb is the popup's one-shot flag: neither is saved.
 *
 * Like KConfigPropertyMap: keys(), and valueChanged(key, value) after every
 * change, which AddBulbRedirect.qml and configBulbs.qml listen to.
 */
import QtQuick
import QtCore

QtObject {
    id: config

    property int widgetIndex: 1
    property bool invertScroll: false
    property string iconSet: "lighthouse"
    property string clapLast: "both"
    property bool openAddBulb: false
    property bool autoScanBluetooth: false

    signal valueChanged(string key, var value)

    readonly property var saved: ["invertScroll", "iconSet", "clapLast", "autoScanBluetooth"]
    function keys() {
        return ["widgetIndex", "invertScroll", "iconSet", "clapLast", "openAddBulb", "autoScanBluetooth"]
    }

    property bool loaded: false
    property Settings store: Settings {
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation)
                  + "/hauslicht/settings-window.ini"
        category: "General"
    }

    // QSettings hands an INI value back as a string: "false" would be true.
    function load() {
        for (const key of saved) {
            const fallback = config[key]
            const value = store.value(key, fallback)
            config[key] = typeof fallback === "boolean" ? String(value) === "true"
                        : typeof fallback === "number" ? Number(value) : String(value)
        }
        loaded = true
    }
    function changed(key) {
        if (!loaded) return
        if (saved.indexOf(key) >= 0) {
            store.setValue(key, config[key])
            store.sync()
        }
        valueChanged(key, config[key])
    }

    onWidgetIndexChanged: changed("widgetIndex")
    onInvertScrollChanged: changed("invertScroll")
    onIconSetChanged: changed("iconSet")
    onClapLastChanged: changed("clapLast")
    onOpenAddBulbChanged: changed("openAddBulb")
    onAutoScanBluetoothChanged: changed("autoScanBluetooth")
    Component.onCompleted: load()
}
