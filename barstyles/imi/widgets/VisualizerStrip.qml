pragma ComponentBehavior: Bound

import QtQuick
import shell.services
import "../components" as C

Item {
    id: root

    property int count: 16
    readonly property bool isPlaying: Media.playing

    implicitHeight: 18
    implicitWidth: row.implicitWidth
    height: 18
    width: implicitWidth

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2.5

        Repeater {
            model: root.count

            delegate: Rectangle {
                id: dot
                required property int index

                width: 2.2
                radius: 1.1
                anchors.verticalCenter: parent.verticalCenter
                color: C.ColorTheme.primaryColor
                opacity: root.isPlaying ? 0.85 : 0.30

                property real targetH: 2.2
                height: targetH

                Timer {
                    interval: 65 + (dot.index * 12)
                    running: root.isPlaying
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        dot.targetH = root.isPlaying ? (2.2 + Math.random() * 10) : 2.2;
                    }
                }

                Behavior on targetH {
                    NumberAnimation { duration: 60; easing.type: Easing.InOutQuad }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 160 }
                }
            }
        }
    }
}
