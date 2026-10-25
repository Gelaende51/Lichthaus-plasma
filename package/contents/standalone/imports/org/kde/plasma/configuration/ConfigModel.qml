/*
 * Stand-in for Plasma's ConfigModel, so the standalone window reads the
 * widget's own config/config.qml for its page list: the categories in
 * order, and count / get(i) like the real model.
 */
import QtQuick

QtObject {
    default property list<ConfigCategory> categories
    readonly property int count: categories.length
    function get(i) { return categories[i] }
}
