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

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "0/0"
            color: C.ColorTheme.textLight
            font.family: Theme.mono
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }

        // Coral/Red status circle
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 9
            color: C.ColorTheme.alertCoral

            Pill.MaterialIcon {
                anchors.centerIn: parent
                text: "package_2"
                font.pixelSize: 11
                color: "#4a0e0e"
            }
        }
    }
}
