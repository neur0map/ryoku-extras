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
        }
    }

    ImiBar.PopoutOverlay {
        modelData: root.modelData
    }
}
