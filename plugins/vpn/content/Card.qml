pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The desktop face: a dossier card. Closed, it is one line: the mark, the
// state, and the connection name. Open (a tap on the head), it lists what is
// worth knowing about the tunnel: type, device, addresses, DNS, how long it has
// been up, and the poll cadence. The TOGGLE button does what the bar click does.
Item {
    id: root

    property var pluginApi
    property bool active: false
    property string density: "compact"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property bool connected: service ? service.connected : false
    readonly property string connName: service ? service.name : ""
    readonly property real w: widthBudget > 0 ? widthBudget : 300 * s
    property bool open: false

    implicitWidth: w
    implicitHeight: card.implicitHeight

    Card {
        id: card
        width: root.w
        s: root.s

        // ── the head: mark, state, name; tap to open ──
        Item {
            width: parent.width
            height: 24 * root.s

            Text {
                id: mark
                anchors.verticalCenter: parent.verticalCenter
                text: root.connected ? "vpn_lock" : "vpn_key_off"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20 * root.s
                font.variableAxes: ({ "FILL": root.connected ? 1 : 0 })
                renderType: Text.QtRendering
                color: root.connected ? Theme.accent : Theme.dim
                Behavior on color { ColorAnimation { duration: 140 } }
            }
            Column {
                anchors.left: mark.right
                anchors.leftMargin: 10 * root.s
                anchors.right: caret.left
                anchors.rightMargin: 8 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Text {
                    width: parent.width
                    text: root.connected ? qsTr("VPN up") : qsTr("VPN off")
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 12.5 * root.s
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: root.connected ? root.connName
                        : ((root.service && root.service.lastVpn.length > 0)
                            ? qsTr("last: %1").arg(root.service.lastVpn) : qsTr("no connection known"))
                    color: Theme.dim
                    font.family: Theme.mono
                    font.pixelSize: 10 * root.s
                    elide: Text.ElideRight
                }
            }
            Text {
                id: caret
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "\u276f"
                rotation: root.open ? 90 : 0
                color: Theme.faint
                font.family: Theme.mono
                font.pixelSize: 10 * root.s
                Behavior on rotation { NumberAnimation { duration: 140 } }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.open = !root.open
            }
        }

        // ── the details, folded under the head ──
        Item {
            width: parent.width
            clip: true
            height: root.open ? details.implicitHeight : 0
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Column {
                id: details
                width: parent.width
                spacing: 6 * root.s

                Rectangle { width: parent.width; height: 1; color: Theme.hair }

                Repeater {
                    model: [
                        { k: qsTr("TYPE"),   v: root.service ? root.service.type : "" },
                        { k: qsTr("DEVICE"), v: root.service ? root.service.device : "" },
                        { k: qsTr("IPV4"),   v: root.service ? root.service.ip4 : "" },
                        { k: qsTr("IPV6"),   v: root.service ? root.service.ip6 : "" },
                        { k: qsTr("DNS"),    v: root.service ? root.service.dns : "" },
                        { k: qsTr("UP FOR"), v: root.service ? root.service.uptime : "" },
                        { k: qsTr("POLL"),   v: root.service ? qsTr("every %1 s").arg(root.service.poll) : "" }
                    ]
                    delegate: Item {
                        id: row
                        required property var modelData
                        width: parent ? parent.width : 0
                        height: visible ? 16 * root.s : 0
                        visible: String(row.modelData.v).length > 0
                        Text {
                            id: key
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 58 * root.s
                            text: row.modelData.k
                            color: Theme.faint
                            font.family: Theme.mono
                            font.pixelSize: 9 * root.s
                            font.letterSpacing: 1.2 * root.s
                        }
                        Text {
                            anchors.left: key.right
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.v
                            color: Theme.cream
                            font.family: Theme.mono
                            font.pixelSize: 10.5 * root.s
                            elide: Text.ElideMiddle
                        }
                    }
                }

                // when nothing is up, the details say so instead of being blank
                Text {
                    visible: !root.connected
                    width: parent.width
                    text: qsTr("Nothing to show while no VPN is active.")
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 10.5 * root.s
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    id: btn
                    readonly property bool can: root.connected || (root.service && root.service.lastVpn.length > 0)
                    width: btnText.implicitWidth + 24 * root.s
                    height: 24 * root.s
                    color: hh.hovered && btn.can ? Theme.sheen : "transparent"
                    border.width: 1
                    border.color: btn.can ? Theme.lineStrong : Theme.border
                    opacity: btn.can ? 1 : 0.5
                    Text {
                        id: btnText
                        anchors.centerIn: parent
                        text: root.connected ? qsTr("DISCONNECT") : qsTr("CONNECT")
                        color: Theme.cream
                        font.family: Theme.mono
                        font.pixelSize: 9.5 * root.s
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.6 * root.s
                    }
                    HoverHandler { id: hh; cursorShape: btn.can ? Qt.PointingHandCursor : Qt.ArrowCursor }
                    TapHandler { enabled: btn.can; onTapped: if (root.service) root.service.toggle() }
                }
            }
        }
    }
}
