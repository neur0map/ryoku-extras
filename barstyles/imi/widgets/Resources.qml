pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import shell.services
import "../components" as C
import "../popouts" as Popouts
import "../shared" as S

Item {
    id: root

    readonly property real cpuVal: Sysinfo.cpu
    readonly property real memVal: Sysinfo.mem
    readonly property real diskVal: 0.42
    readonly property real gpuVal: 0.18

    readonly property int cpuPct: Math.round(cpuVal * 100)
    readonly property int memPct: Math.round(memVal * 100)

    implicitHeight: 22
    implicitWidth: row.implicitWidth
    height: 22
    width: implicitWidth

    Component.onCompleted: Sysinfo.setActive(root, true)
    Component.onDestruction: Sysinfo.setActive(root, false)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        // 1. CPU Circular Ring
        C.CircularMeter {
            anchors.verticalCenter: parent.verticalCenter
            value: root.cpuVal
            icon: "memory"
            progressColor: root.cpuPct >= 85 ? C.ColorTheme.alertCoral : C.ColorTheme.primaryColor
        }

        // 2. RAM Circular Ring
        C.CircularMeter {
            anchors.verticalCenter: parent.verticalCenter
            value: root.memVal
            icon: "graphic_eq"
            progressColor: root.memPct >= 90 ? C.ColorTheme.alertCoral : C.ColorTheme.primaryColor
        }

        // 3. Disk Circular Ring
        C.CircularMeter {
            anchors.verticalCenter: parent.verticalCenter
            value: root.diskVal
            icon: "hard_drive"
            progressColor: C.ColorTheme.primaryColor
        }

        // 4. GPU / Speed Circular Ring
        C.CircularMeter {
            anchors.verticalCenter: parent.verticalCenter
            value: root.gpuVal
            icon: "speed"
            progressColor: C.ColorTheme.primaryColor
        }
    }

    HoverHandler { id: hover }

    S.Popout {
        target: root
        targetHovered: hover.hovered
        namespace: "ryoku-imi-popout"
        content: Component { Popouts.ResourcesPopout {} }
    }
}
