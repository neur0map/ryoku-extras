pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// The VPN widget's one adaptive view, by density: on the bar (`glyph`) a single
// mark with the bar text, whose click opens the plugin's bar panel; on the
// wallpaper (`compact`) a card that folds open into the tunnel's details. The
// bar panel itself is a separate entry point (content/Panel.qml) the host mounts
// under the glyph. The host sets pluginApi, density, s, widthBudget, active on
// this root; both faces read the same service through pluginApi.mainInstance.
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "glyph"
    property real s: 1
    property real widthBudget: 0

    implicitWidth: face.item ? face.item.implicitWidth : 0
    implicitHeight: face.item ? face.item.implicitHeight : 0

    Loader {
        id: face
        source: root.density === "glyph" ? "Glyph.qml" : "Card.qml"
        onLoaded: {
            item.pluginApi = Qt.binding(() => root.pluginApi)
            item.density = Qt.binding(() => root.density)
            item.s = Qt.binding(() => root.s)
            item.widthBudget = Qt.binding(() => root.widthBudget)
            item.active = Qt.binding(() => root.active)
        }
    }
}
