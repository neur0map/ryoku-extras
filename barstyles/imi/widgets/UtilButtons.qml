pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import shell.barkit as Pill
import shell.services
import "../components" as C

Item {
    id: root

    implicitHeight: 22
    implicitWidth: row.implicitWidth
    height: 22
    width: implicitWidth

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        // Screenshot Snip
        Pill.MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "screenshot_region"
            font.pixelSize: 14
            color: C.ColorTheme.subtextColor

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["sh", "-c", "flock -n -o /tmp/ryoshot.lock qs -c ryoshot"])
            }
        }

        // Virtual Keyboard
        Pill.MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "keyboard"
            font.pixelSize: 14
            color: C.ColorTheme.subtextColor

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["wvkbd-mobintl"])
            }
        }

        // Wallpaper Picker
        Pill.MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "imagesmode"
            font.pixelSize: 14
            color: C.ColorTheme.subtextColor

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.toggleWallpaperPicker()
            }
        }

        // Dark / Light Theme Toggle
        Pill.MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "light_mode"
            font.pixelSize: 14
            color: C.ColorTheme.subtextColor

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const nextMode = Theme.mode === "Dark" ? "Light" : "Dark";
                    ShellState.setThemeMode(nextMode);
                }
            }
        }
    }
}
