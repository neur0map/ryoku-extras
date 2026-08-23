pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import shell.services
import "../components" as C
import "../popouts" as Popouts
import "../shared" as S

Item {
    id: root

    property var now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    readonly property string timeStr: Qt.formatTime(root.now, "HH:mm")
    readonly property string dateStr: Qt.formatDate(root.now, "ddd, dd/MM")

    implicitHeight: 22
    implicitWidth: row.implicitWidth
    height: 22
    width: implicitWidth

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        // Date text
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.dateStr
            color: C.ColorTheme.textLight
            font.family: Theme.fontFamily || "Space Grotesk"
            font.pixelSize: 11
            font.weight: Font.Medium
        }

        // Solid Mint/Cyan Time Pill
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: timeText.implicitWidth + 12
            implicitHeight: 20
            radius: 10
            color: C.ColorTheme.primaryColor

            Text {
                id: timeText
                anchors.centerIn: parent
                text: root.timeStr
                color: C.ColorTheme.onPrimaryColor
                font.family: Theme.mono
                font.pixelSize: 11
                font.weight: Font.Bold
            }
        }
    }

    HoverHandler { id: hover }

    S.Popout {
        target: root
        targetHovered: hover.hovered
        namespace: "ryoku-imi-popout"
        content: Component { Popouts.CalendarPopout {} }
    }
}
