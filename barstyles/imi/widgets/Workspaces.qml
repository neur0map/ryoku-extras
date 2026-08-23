pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import shell.barkit as Pill
import shell.services
import "../components" as C

Item {
    id: root

    readonly property int currentWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    implicitHeight: 24
    implicitWidth: row.implicitWidth
    height: 24
    width: implicitWidth

    function isOccupied(wsId) {
        if (!Hyprland.workspaces) return false;
        const ws = Hyprland.workspaces.values;
        for (let i = 0; i < ws.length; ++i) {
            if (ws[i].id === wsId && (ws[i].windows > 0 || ws[i].tiledClients > 0))
                return true;
        }
        return false;
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: [1, 2, 3, 4]

            delegate: Item {
                id: wsDot
                required property int modelData
                readonly property int wsId: modelData
                readonly property bool isActive: root.currentWsId === wsId
                readonly property bool occupied: root.isOccupied(wsId)

                width: isActive ? 20 : (occupied ? 18 : 5)
                height: isActive ? 20 : (occupied ? 18 : 5)
                anchors.verticalCenter: parent.verticalCenter

                // Active Workspace: Solid Primary Circle with Dark Center Dot
                Rectangle {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    radius: 10
                    color: C.ColorTheme.primaryColor
                    visible: wsDot.isActive

                    Rectangle {
                        anchors.centerIn: parent
                        width: 6
                        height: 6
                        radius: 3
                        color: C.ColorTheme.onPrimaryColor
                    }
                }

                // Occupied Workspace: Dark container with App/Terminal Icon
                Rectangle {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    radius: 9
                    color: Qt.rgba(0.14, 0.18, 0.24, 0.95)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.12)
                    visible: !wsDot.isActive && wsDot.occupied

                    Pill.MaterialIcon {
                        anchors.centerIn: parent
                        text: "terminal"
                        font.pixelSize: 10
                        color: C.ColorTheme.textLight
                    }
                }

                // Inactive Workspace: Small Subtle Dot
                Rectangle {
                    anchors.centerIn: parent
                    width: 4
                    height: 4
                    radius: 2
                    color: C.ColorTheme.subtextColor
                    opacity: 0.4
                    visible: !wsDot.isActive && !wsDot.occupied
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + wsDot.wsId)
                }
            }
        }
    }

    WheelHandler {
        onWheel: event => {
            if (event.angleDelta.y < 0) Hyprland.dispatch("workspace e+1");
            else if (event.angleDelta.y > 0) Hyprland.dispatch("workspace e-1");
        }
    }
}
