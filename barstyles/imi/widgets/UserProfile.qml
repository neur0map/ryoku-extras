pragma ComponentBehavior: Bound

import QtQuick
import shell.barkit as Pill
import shell.services
import "../components" as C

Item {
    id: root

    implicitHeight: 24
    implicitWidth: row.implicitWidth
    height: 24
    width: implicitWidth

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        // User Avatar Circle
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 9
            color: Qt.rgba(0.2, 0.3, 0.4, 0.35)

            Pill.MaterialIcon {
                anchors.centerIn: parent
                text: "account_circle"
                font.pixelSize: 14
                color: C.ColorTheme.primaryColor
            }
        }

        // Two-line Subtitle/Title
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -2

            Text {
                text: "xephy"
                color: C.ColorTheme.subtextColor
                font.family: Theme.fontFamily || "Space Grotesk"
                font.pixelSize: 9
                font.weight: Font.Normal
            }

            Text {
                text: "Arch Linux"
                color: C.ColorTheme.textLight
                font.family: Theme.fontFamily || "Space Grotesk"
                font.pixelSize: 11
                font.weight: Font.Bold
            }
        }
    }
}
