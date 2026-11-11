# Lichthaus's settings in KDE System Settings (Plasma 6): five KCMs, one per
# Configure page of the widget (Bulbs, Profiles, Sound, Video, Notifications),
# in a category "Lichthaus" under Hardware. The pages themselves stay in the
# widget's package (../package/contents/ui); the KCMs only host them, see
# lichthauskcm.cpp and docs/system-settings.md.
#
#   cmake -S kcm -B build && cmake --build build && cmake --install build
#
# installs to Qt's plugin directory and share/systemsettings/categories under
# CMAKE_INSTALL_PREFIX (/usr: where System Settings looks without any setup).
# Per user (Lichthaus's install/install.sh):
#   -DCMAKE_INSTALL_PREFIX=$HOME/.local -DKDE_INSTALL_QTPLUGINDIR=lib/qt6/plugins
# and QT_PLUGIN_PATH must name ~/.local/lib/qt6/plugins in the session.
cmake_minimum_required(VERSION 3.22)
project(lichthaus-kcm VERSION 0.3 LANGUAGES CXX)

find_package(ECM 6.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 6.6 REQUIRED COMPONENTS Core Gui Widgets Qml Quick QuickWidgets)
find_package(KF6 6.0 REQUIRED COMPONENTS CoreAddons KCMUtils)

# QWidget KCMs: each hosts its page in a QQuickWidget with a QML engine of its
# own (System Settings shares one engine between its QML KCMs and its own
# window, and the pages need a stand-in for org.kde.plasma.plasmoid on it).
set(LICHTHAUS_PAGES bulbs profiles sound video notifications)
foreach(page IN LISTS LICHTHAUS_PAGES)
    set(target kcm_lichthaus_${page})
    set(LICHTHAUS_KCM_JSON "${CMAKE_CURRENT_SOURCE_DIR}/metadata/${target}.json")
    configure_file(plugin.cpp.in ${CMAKE_CURRENT_BINARY_DIR}/${target}.cpp @ONLY)
    kcoreaddons_add_plugin(${target}
        SOURCES ${CMAKE_CURRENT_BINARY_DIR}/${target}.cpp lichthauskcm.cpp lichthauskcm.h
        INSTALL_NAMESPACE "plasma/kcms/systemsettings_qwidgets")
    target_link_libraries(${target} PRIVATE
        Qt6::Widgets Qt6::Qml Qt6::Quick Qt6::QuickWidgets
        KF6::CoreAddons KF6::KCMUtils)
endforeach()

# The category the five KCMs are listed in (System Settings reads
# systemsettings/categories under the XDG data directories, ~/.local/share
# included).
install(FILES settings-hardware-lichthaus.desktop DESTINATION ${KDE_INSTALL_DATADIR}/systemsettings/categories)
