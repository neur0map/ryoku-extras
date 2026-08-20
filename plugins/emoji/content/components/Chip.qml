import QtQuick
import Ryoku.PluginKit.Singletons

Rectangle {
    id: chop
    property string label: ""
    property bool on: false
    property real s: 1
    signal picked

    width: chipLabel.implicitWidth + 20 * chop.s
    height: 24 * chop.s
    radius: Motion.rSmall * chop.s
    color: on ? Theme.brand : "transparent"
    border.width: 1
    border.color: on ? Theme.brand : Theme.hair
    Behavior on color { ColorAnimation { duration: Motion.fast } }

    Text {
        id: chipLabel
        anchors.centerIn: parent
        text: chop.label
        color: on ? Theme.cream : Theme.faint
        font.family: Theme.mono
        font.pixelSize: 10 * chop.s
        font.letterSpacing: 0.4
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chop.picked()
    }
}