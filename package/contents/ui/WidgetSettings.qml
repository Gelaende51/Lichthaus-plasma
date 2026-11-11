/*
 * The widget's own settings, kept by the daemon per widget (Lichthaus's
 * settings.widget_settings: `get` carries them, `widget-settings-set`
 * writes them), so the tray widget, the settings window (widget 1) and any
 * other front end show the same: invertScroll, iconSet, clapLast,
 * autoScanBluetooth.
 *
 * The configuration keys (main.xml, or the settings window's stand-in) stay
 * what the pages read: a cache, set from the daemon whenever its value
 * changes, and sent to it whenever a page changes one. A daemon from before
 * these settings (no widget_settings in `get`) or none at all: the cache is
 * all there is, as before.
 *
 * migrate: the daemon has no value for a key yet, so this widget writes its
 * own once (the Plasma widget: the user's icon set and scroll direction
 * carry over). The settings window leaves that to the widget it stands in for.
 */
import QtQuick

QtObject {
    id: sync

    property HausCtl ctl: null
    property var config: null
    property bool migrate: true

    // configuration key -> the daemon's key
    readonly property var keys: ({
        "invertScroll": "invert_scroll",
        "iconSet": "icon_set",
        "clapLast": "clap_last",
        "autoScanBluetooth": "auto_scan_bluetooth"
    })
    // Read from ctl.st itself, not through a binding: a binding on it may not
    // be re-evaluated yet when stChanged runs pull().
    function stored() {
        const st = ctl && ctl.loaded && ctl.reachable ? ctl.st : null
        return st && typeof st.widget_settings === "object" && st.widget_settings !== null
               ? st.widget_settings : null
    }

    property var pushing: ({})   // daemon key -> sends of it still without a reply
    property var seen: ({})      // daemon key -> the daemon's value last taken over
    property var gaveUp: ({})    // daemon key -> true: the daemon refused this widget's old value

    // Another widget index: its values are its own.
    readonly property int widget: ctl ? ctl.widget : 1
    onWidgetChanged: { seen = {}; pushing = {}; gaveUp = {} }

    // The local values the daemon is told about (watched for changes).
    readonly property var invertScroll: config ? config.invertScroll : undefined
    readonly property var iconSet: config ? config.iconSet : undefined
    readonly property var clapLast: config ? config.clapLast : undefined
    readonly property var autoScanBluetooth: config ? config.autoScanBluetooth : undefined
    onInvertScrollChanged: changed("invertScroll")
    onIconSetChanged: changed("iconSet")
    onClapLastChanged: changed("clapLast")
    onAutoScanBluetoothChanged: changed("autoScanBluetooth")

    function word(key, value) {
        return key + "=" + (typeof value === "boolean" ? (value ? "on" : "off") : String(value))
    }
    // A value worth sending: the daemon refuses empty names.
    function usable(value) {
        return typeof value === "boolean" || (typeof value === "string" && value !== "")
    }

    // The daemon's values into the cache, where they changed there; keys it
    // lacks get this widget's value (migrate).
    function pull() {
        const daemon = stored()
        if (!daemon || !config) return
        const missing = []
        for (const key in keys) {
            const dkey = keys[key]
            if (dkey in pushing) continue  // our own change is on its way
            if (!(dkey in daemon)) {
                if (migrate && !gaveUp[dkey] && usable(config[key])) missing.push(key)
                continue
            }
            const value = daemon[dkey]
            if (seen[dkey] === value) continue
            seen[dkey] = value
            if (config[key] !== value) config[key] = value
        }
        if (missing.length > 0) send(missing, true)
    }

    // A page or the popup changed a key: tell the daemon.
    function changed(key) {
        const daemon = stored()
        if (!daemon || !config || !usable(config[key])) return
        const dkey = keys[key]
        if (!(dkey in pushing) && daemon[dkey] === config[key]) return
        send([key], false)
    }

    function send(list, migrating) {
        const words = []
        const sent = []
        const marks = pushing
        for (const key of list) {
            const dkey = keys[key]
            marks[dkey] = (marks[dkey] || 0) + 1
            sent.push(dkey)
            words.push(word(dkey, config[key]))
        }
        pushing = marks
        ctl.run(["widget-settings-set"].concat(words), reply => {
            const left = sync.pushing
            for (const dkey of sent)
                if (--left[dkey] <= 0) delete left[dkey]
            sync.pushing = left
            if (reply.error) {
                console.warn("Lichthaus: widget-settings-set " + words.join(" ") + ": " + reply.error)
                const forget = sync.seen
                for (const dkey of sent) {
                    delete forget[dkey]  // the daemon's value wins again on the next get
                    if (migrating) sync.gaveUp[dkey] = true
                }
                sync.seen = forget
            }
            // The reply is the get object: ctl.st, then pull(), take it over.
        })
    }

    property Connections stateWatch: Connections {
        target: sync.ctl
        function onStChanged() { sync.pull() }
    }
}
