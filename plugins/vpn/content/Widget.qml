pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Ryoku.PluginKit.Singletons

// The VPN widget's one adaptive view. The bar host mounts it at `glyph` density
// on the top bar: a single Material mark that flips with the live VPN state,
// with the connection name beside it when there is room. A click toggles the
// VPN through the service; hover names the connection. Colour comes from the kit
// Theme so the mark matches the bar ink on any scheme, nothing is hardcoded.
Item {
    id: root

    // Host-set; read only, never assign.
    property var pluginApi
    property var screen
    property bool active: false
    property string density: "glyph"
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property bool connected: service ? service.connected : false
    readonly property bool showName: service ? service.showName : true
    readonly property string connName: service ? service.name : ""

    // The name rides beside the mark when it is asked for and there is a live
    // connection to name. Compact always shows it; glyph only when showName is on.
    readonly property bool nameShown: connName.length > 0
        && (density === "compact" || (density === "glyph" && showName))

    // Mark sizing tracks the bar's inner height so the ligature centres like a
    // native bar glyph. gap sits between the mark and the name.
    readonly property real mark: 19
    readonly property real gap: 6
    // Cap the name so a long connection cannot run the bar glyph off its budget.
    readonly property real nameMax: Math.max(60, (widthBudget > 0 ? widthBudget : 220) - mark - gap)

    implicitWidth: glyph.implicitWidth + (nameShown ? gap + nameLabel.width : 0)
    implicitHeight: Math.max(mark + 3, glyph.implicitHeight)

    Text {
        id: glyph
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        // Material Symbols ligature: a locked mark when a VPN is up, key-off when
        // none is. The shell ships this font (ttf-material-symbols-variable).
        text: root.connected ? "vpn_lock" : "vpn_key_off"
        font.family: "Material Symbols Rounded"
        font.pixelSize: root.mark
        font.weight: 500
        font.variableAxes: ({ "FILL": root.connected ? 1 : 0, "opsz": 20 })
        renderType: Text.QtRendering
        // An active VPN reads in the theme accent; idle drops to the dim ink so
        // the bar stays quiet until something is connected.
        color: root.connected ? Theme.accent : Theme.dim
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Text {
        id: nameLabel
        anchors.verticalCenter: parent.verticalCenter
        x: glyph.x + glyph.implicitWidth + root.gap
        visible: root.nameShown
        text: root.connName
        color: Theme.cream
        font.family: Theme.mono
        font.pixelSize: 11
        elide: Text.ElideRight
        width: Math.min(implicitWidth, root.nameMax)
    }

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.service) root.service.toggle()
    }

    // Hover text naming the connection. The kit ships no tooltip, so this is a
    // Theme-styled QtQuick.Controls ToolTip: the active VPN and how a click acts,
    // or a prompt to reconnect the last one.
    ToolTip {
        id: tip
        parent: root
        x: Math.round((root.width - width) / 2)
        y: root.height + 6
        delay: 350
        visible: hover.hovered
        text: root.connected
            ? qsTr("VPN: %1 (click to disconnect)").arg(root.connName)
            : ((root.service && root.service.lastVpn.length > 0)
                ? qsTr("VPN off (click to connect %1)").arg(root.service.lastVpn)
                : qsTr("No VPN connection"))
        background: Rectangle {
            color: Theme.panelBot
            border.color: Theme.border
            border.width: 1
            radius: 0
        }
        contentItem: Text {
            text: tip.text
            color: Theme.cream
            font.family: Theme.mono
            font.pixelSize: 11
        }
    }
}
