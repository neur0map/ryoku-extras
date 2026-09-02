pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// One key/value row in the VPN dossier, shared by the bar panel and the desktop
// card: a mono uppercase key on the left, its value on the right, and an optional
// action chip after it (COPY on the IPv4, STOP USING on an active exit node). The
// row hides itself when it has neither a value nor an action, so an absent field
// leaves no empty line. Colour comes from the kit Theme; nothing is hardcoded.
Item {
    id: row

    property real s: 1
    property string label: ""
    property string value: ""
    property real keyWidth: 74
    // "" hides the chip; otherwise the chip shows this text and emits on tap.
    property string actionText: ""
    property bool actionEnabled: true
    signal actionTriggered()

    readonly property bool hasAction: actionText.length > 0
    width: parent ? parent.width : 0
    visible: value.length > 0 || hasAction
    height: visible ? Math.max(17 * s, valueText.implicitHeight) : 0

    Text {
        id: keyText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: row.keyWidth * row.s
        text: row.label
        color: Theme.faint
        font.family: Theme.mono
        font.pixelSize: 9 * row.s
        font.letterSpacing: 1.2 * row.s
        font.capitalization: Font.AllUppercase
        elide: Text.ElideRight
    }

    Text {
        id: valueText
        anchors.left: keyText.right
        anchors.leftMargin: 6 * row.s
        anchors.right: row.hasAction ? chip.left : parent.right
        anchors.rightMargin: row.hasAction ? 8 * row.s : 0
        anchors.verticalCenter: parent.verticalCenter
        text: row.value
        color: Theme.cream
        font.family: Theme.mono
        font.pixelSize: 10.5 * row.s
        elide: Text.ElideMiddle
        horizontalAlignment: Text.AlignRight
    }

    Rectangle {
        id: chip
        visible: row.hasAction
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: chipText.implicitWidth + 12 * row.s
        height: 15 * row.s
        radius: 0
        color: chipHover.hovered && row.actionEnabled ? Theme.sheen : "transparent"
        border.width: 1
        border.color: row.actionEnabled ? Theme.lineStrong : Theme.border
        opacity: row.actionEnabled ? 1 : 0.5

        Text {
            id: chipText
            anchors.centerIn: parent
            text: row.actionText
            color: Theme.cream
            font.family: Theme.mono
            font.pixelSize: 8 * row.s
            font.weight: Font.DemiBold
            font.letterSpacing: 1.2 * row.s
        }

        HoverHandler { id: chipHover; cursorShape: row.actionEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
        TapHandler { enabled: row.actionEnabled; onTapped: row.actionTriggered() }
    }
}
