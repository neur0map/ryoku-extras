pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "modules/imi/bar" as ImiBar

Scope {
    id: root

    property var modelData: null

    PanelWindow {
        id: win
        screen: root.modelData

        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 48
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "ryoku-imi"

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 48

        ImiBar.BarContent {
            anchors.fill: parent

            // Double-tap anywhere on the bar to toggle edit mode
            // ReleaseWithinBounds lets DragHandlers steal the grab
            TapHandler {
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onDoubleTapped: GlobalStates.editMode = !GlobalStates.editMode
            }
        }
    }

    ImiBar.PopoutOverlay {
        modelData: root.modelData
    }

    // Click outside bar to dismiss edit mode
    PanelWindow {
        id: editDismiss
        screen: root.modelData
        visible: GlobalStates.editMode
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "ryoku-imi-edit-dismiss"

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: GlobalStates.editMode = false
        }
    }
}
