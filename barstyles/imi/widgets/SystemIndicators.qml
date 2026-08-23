pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import shell.barkit as Pill
import shell.services
import "../components" as C
import "../popouts" as Popouts
import "../shared" as S

Item {
    id: root

    readonly property var sink: Audio.sink
    readonly property var source: Audio.source
    readonly property bool muted: !!(root.sink && root.sink.audio && root.sink.audio.muted)
    readonly property bool micMuted: !!(root.source && root.source.audio && root.source.audio.muted)

    readonly property bool wired: Network.kind === "ethernet"
    readonly property bool wifiConnected: Network.wifiConnectivity === "Connected"
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: !!(root.adapter && root.adapter.enabled)

    readonly property color ink: C.ColorTheme.onPrimaryColor

    implicitHeight: 22
    implicitWidth: row.implicitWidth
    height: 22
    width: implicitWidth

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        // Keyboard layout badge
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "us"
            color: root.ink
            font.family: Theme.mono
            font.pixelSize: 10
            font.weight: Font.Bold
        }

        // Volume
        Pill.MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted ? "volume_off" : "volume_up"
            font.pixelSize: 14
            color: root.ink
        }

        // Mic
        Pill.MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.micMuted ? "mic_off" : "mic"
            font.pixelSize: 14
            color: root.ink
        }

        // Keyboard / language repeat
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "us"
            color: root.ink
            font.family: Theme.mono
            font.pixelSize: 10
            font.weight: Font.Bold
        }

        // Network / Wi-Fi
        Pill.MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.wired ? "lan" : (root.wifiConnected ? "wifi" : "wifi_off")
            font.pixelSize: 14
            color: root.ink
        }

        // Bluetooth
        Pill.MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.btOn ? "bluetooth" : "bluetooth_disabled"
            font.pixelSize: 14
            color: root.ink
        }
    }

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted;
        }
    }

    S.Popout {
        target: root
        targetHovered: hover.hovered
        namespace: "ryoku-imi-popout"
        content: Component { Popouts.AudioPopout {} }
    }
}
