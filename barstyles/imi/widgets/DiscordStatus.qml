pragma ComponentBehavior: Bound

import QtQuick
import shell.barkit as Pill
import shell.services
import "../components" as C

Item {
    id: root

    implicitHeight: 22
    implicitWidth: 20
    height: 22
    width: 20

    Pill.MaterialIcon {
        anchors.centerIn: parent
        text: "forum"
        font.pixelSize: 14
        color: C.ColorTheme.subtextColor

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.toggleNotificationInbox()
        }
    }
}
