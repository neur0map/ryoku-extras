pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import shell.barkit as Pill
import shell.services
import "../components" as C

Item {
    id: root

    readonly property string winTitle: Hyprland.activeWindow && Hyprland.activeWindow.title
        ? Hyprland.activeWindow.title : ""
    readonly property string winClass: Hyprland.activeWindow && Hyprland.activeWindow.clazz
        ? Hyprland.activeWindow.clazz : ""
    readonly property int currentWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    readonly property string topText: winClass !== "" ? winClass : "Desktop"
    readonly property string bottomText: winTitle !== "" ? winTitle : ("Workspace " + currentWsId)

    implicitHeight: 24
    implicitWidth: row.implicitWidth
    height: 24
    width: implicitWidth

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        // Distro Icon Circle
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            radius: 10
            color: Qt.rgba(0.2, 0.3, 0.4, 0.35)

            Pill.BrandMark {
                anchors.centerIn: parent
                scale: 0.52
                color: C.ColorTheme.primaryColor
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.toggleLauncher()
            }
        }

        // Two-line Title
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -2

            Text {
                text: root.topText
                color: C.ColorTheme.subtextColor
                font.family: Theme.fontFamily || "Space Grotesk"
                font.pixelSize: 9
                font.weight: Font.Normal
                elide: Text.ElideRight
                maximumLineCount: 1
                width: Math.min(80, implicitWidth)
            }

            Text {
                text: root.bottomText
                color: C.ColorTheme.textLight
                font.family: Theme.fontFamily || "Space Grotesk"
                font.pixelSize: 11
                font.weight: Font.Bold
                elide: Text.ElideRight
                maximumLineCount: 1
                width: Math.min(80, implicitWidth)
            }
        }
    }
}
