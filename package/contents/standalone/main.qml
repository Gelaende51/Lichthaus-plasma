/*
 * The standalone settings window (`hauslicht config`): the widget's Configure
 * pages (config/config.qml, ui/config*.qml) in a window of their own, for
 * desktops without the widget and for other front ends' "Settings…" entries.
 *
 * Qt's qml runtime loads this file with standalone/imports first on the
 * import path, so `import org.kde.plasma.plasmoid` (the pages) and
 * `import org.kde.plasma.configuration` (config.qml) resolve to the small
 * shims there; Kirigami, kcmutils, kiconthemes and plasma5support are the
 * system's real modules. The layout follows Plasma's own Configure dialog
 * (AppletConfiguration.qml): categories on the left, the page on the right.
 * Every page changes the daemon directly; the few widget settings they hold
 * as cfg_ properties are saved as soon as they change, so there is no Apply.
 */
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.configuration

QQC2.ApplicationWindow {
    id: window

    readonly property bool german: Qt.locale().name.startsWith("de")

    title: german ? "Haus.Licht-Einstellungen" : "Haus.Licht settings"
    width: Kirigami.Units.gridUnit * 45
    height: Kirigami.Units.gridUnit * 35
    minimumWidth: Kirigami.Units.gridUnit * 30
    minimumHeight: Kirigami.Units.gridUnit * 21
    color: Kirigami.Theme.backgroundColor

    // Shown only once the app identity is set: on Wayland Qt derives the
    // window's app id from it when the window is first shown, as the domain
    // reversed plus the name the runtime was started under. "hauslicht
    // config" starts it through a link named HausLicht, which makes
    // io.github.gelaende51.HausLicht, Haus.Licht's desktop file: the
    // compositor shows its icon and name. (It also keeps Qt from sending the
    // qml runtime's own icon.)
    visible: false
    Component.onCompleted: {
        Qt.application.name = "HausLicht"
        Qt.application.organization = "Gelaende51"
        Qt.application.domain = "gelaende51.github.io"
        visible = true
    }

    // AddBulbRedirect.qml walks up from a page to the item with open() and
    // currentSource, as in Plasma's dialog; this is that item here.
    Item {
        id: root
        anchors.fill: parent

        property string currentSource: ""
        property var categories: []
        readonly property var config: Plasmoid.configuration

        function pageUrl(source) {
            const s = String(source)
            return s.indexOf(":") >= 0 ? s : Qt.resolvedUrl("../ui/" + s).toString()
        }

        // The page with the widget's settings as cfg_ properties (Plasma
        // sets them the same way); a change goes straight back to config.
        function open(item) {
            const url = pageUrl(item.source)
            if (url === currentSource) return
            const component = Qt.createComponent(url)
            if (component.status !== Component.Ready) {
                console.warn(component.errorString())
                return
            }
            const page = component.createObject(null, { "title": item.name })
            if (!page) return
            for (const key of config.keys()) {
                const prop = "cfg_" + key
                if (!(prop in page)) continue
                page[prop] = config[key]
                page[prop + "Changed"].connect(() => { root.config[key] = page[prop] })
            }
            const old = app.pageStack.currentItem
            if (app.pageStack.depth === 0) app.pageStack.push(page)
            else app.pageStack.replace(page)
            currentSource = url
            if (old && old !== page) old.destroy()
        }

        Component.onCompleted: {
            const component = Qt.createComponent(Qt.resolvedUrl("../config/config.qml"))
            const model = component.createObject(root) as ConfigModel
            if (!model) {
                console.warn(component.errorString())
                return
            }
            const list = []
            for (let i = 0; i < model.count; i++)
                if (model.get(i).visible) list.push(model.get(i))
            categories = list
            if (list.length > 0) open(list[0])
        }

        QQC2.ScrollView {
            id: categoriesScroll
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: Kirigami.Units.gridUnit * 7
            contentWidth: availableWidth
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            Kirigami.Theme.inherit: false
            activeFocusOnTab: true
            focus: true
            Accessible.role: Accessible.PageTabList
            background: Rectangle {
                color: Kirigami.Theme.backgroundColor
            }

            function step(delta) {
                const at = root.categories.findIndex(c => root.pageUrl(c.source) === root.currentSource)
                const next = at + delta
                if (next < 0 || next >= root.categories.length) return false
                root.open(root.categories[next])
                return true
            }
            Keys.onUpPressed: event => { event.accepted = step(-1) }
            Keys.onDownPressed: event => { event.accepted = step(1) }

            ColumnLayout {
                width: categoriesScroll.contentWidth
                spacing: 0

                Repeater {
                    model: root.categories
                    delegate: QQC2.ItemDelegate {
                        id: delegate

                        required property var modelData

                        Layout.fillWidth: true
                        hoverEnabled: true
                        highlighted: root.pageUrl(delegate.modelData.source) === root.currentSource
                        focus: highlighted
                        Accessible.role: Accessible.PageTab
                        Accessible.name: delegate.modelData.name
                        Accessible.onPressAction: delegate.clicked()
                        onClicked: root.open(delegate.modelData)

                        contentItem: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: Kirigami.Units.iconSizes.medium
                                implicitHeight: Kirigami.Units.iconSizes.medium
                                source: delegate.modelData.icon
                                selected: Window.active && (delegate.highlighted || delegate.pressed)
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.leftMargin: Kirigami.Units.smallSpacing
                                Layout.rightMargin: Kirigami.Units.smallSpacing
                                text: delegate.modelData.name
                                textFormat: Text.PlainText
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                                color: Window.active && (delegate.highlighted || delegate.pressed)
                                       ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                Accessible.ignored: true
                            }
                        }
                    }
                }
            }
        }

        Kirigami.Separator {
            id: verticalSeparator
            anchors {
                top: parent.top
                left: categoriesScroll.right
                bottom: parent.bottom
            }
            z: 1
        }

        Kirigami.ApplicationItem {
            id: app
            anchors {
                top: parent.top
                left: verticalSeparator.right
                right: parent.right
                bottom: parent.bottom
            }
            pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.Auto
            pageStack.globalToolBar.colorSet: Kirigami.Theme.Window
            wideScreen: true
        }
    }
}
