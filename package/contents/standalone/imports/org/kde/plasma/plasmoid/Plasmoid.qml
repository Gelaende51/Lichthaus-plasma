/*
 * Stand-in for Plasma's org.kde.plasma.plasmoid in the standalone settings
 * window (standalone/main.qml). The window puts standalone/imports first on
 * the QML import path, so the Configure pages' `import org.kde.plasma.plasmoid`
 * lands here instead of on libplasma's module, which only works inside an
 * applet. The pages use nothing of it but Plasmoid.configuration.
 */
pragma Singleton
import QtQuick

QtObject {
    // True only here: a page can tell the standalone window from Plasma.
    readonly property bool standalone: true
    readonly property Configuration configuration: Configuration {}
}
