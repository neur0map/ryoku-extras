pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The desktop face: a dossier card. Closed, it is one line: the mark, the state,
// and the headline. Open (a tap on the head), it lists the same tunnel detail
// the bar panel shows, backend by backend, and offers CONNECT/DISCONNECT under
// the same confirm rule the panel uses (an exit-node tunnel arms once before it
// turns off). No tap here ever mutates until it is the deliberate button.
Item {
    id: root

    property var pluginApi
    property bool active: false
    property string density: "compact"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property var ts: service ? service.ts : null
    readonly property var nm: service ? service.nm : null

    readonly property real w: widthBudget > 0 ? widthBudget : 300 * s
    readonly property bool connected: service ? service.connected : false
    readonly property string headline: service ? service.headline : ""
    readonly property bool tsInstalled: ts ? ts.installed : false
    readonly property bool nmHas: nm ? nm.profiles.length > 0 : false
    readonly property bool noBackend: !tsInstalled && !nmHas
    readonly property bool canToggle: tsInstalled || nmHas

    property bool open: false
    property bool armed: false
    Timer { id: disarm; interval: 3000; repeat: false; onTriggered: root.armed = false }

    readonly property string stateLine: {
        if (connected) return qsTr("VPN up");
        if (tsInstalled && ts.state === "NeedsLogin") return qsTr("Needs login");
        if (noBackend) return qsTr("No backend");
        return qsTr("VPN off");
    }

    // CONNECT/DISCONNECT drives the present backend: Tailscale when installed,
    // else the first NetworkManager profile.
    function primaryToggle() {
        if (!service) return;
        if (tsInstalled) {
            if (ts.up) {
                if (service.confirmOff && ts.exitNodeActive && !root.armed) {
                    root.armed = true;
                    disarm.restart();
                } else {
                    ts.turnOff();
                    root.armed = false;
                    disarm.stop();
                }
            } else {
                ts.turnOn();
            }
        } else if (nmHas) {
            var p = nm.activeProfile;
            if (p) nm.down(p.uuid);
            else nm.up(nm.profiles[0].uuid);
        }
    }

    implicitWidth: w
    implicitHeight: card.implicitHeight

    // ── reusable bits (self-contained; only InfoRow is shared) ────────────────
    component Eyebrow: Row {
        id: eb
        property string label: ""
        property real s: 1
        spacing: 7 * eb.s
        Rectangle {
            width: 5 * eb.s; height: 5 * eb.s; radius: 1 * eb.s
            color: Theme.brand
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: eb.label
            color: Theme.faint
            font.family: Theme.mono
            font.pixelSize: 9.5 * eb.s
            font.weight: Font.DemiBold
            font.letterSpacing: 2 * eb.s
            font.capitalization: Font.AllUppercase
        }
    }

    Card {
        id: card
        width: root.w
        s: root.s

        // ── the head: mark, state, headline; tap to open ──
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
                    text: root.stateLine
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 12.5 * root.s
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: root.headline.length > 0 ? root.headline : qsTr("no connection")
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
                spacing: 8 * root.s

                Rectangle { width: parent.width; height: 1; color: Theme.hair }

                // ── Tailscale ──
                Column {
                    width: parent.width
                    spacing: 3 * root.s
                    visible: root.tsInstalled

                    Eyebrow { label: "Tailscale"; s: root.s }

                    InfoRow { s: root.s; label: qsTr("Device"); value: root.ts ? root.ts.hostName : "" }
                    InfoRow { s: root.s; label: qsTr("Name");   value: root.ts ? root.ts.dnsName : "" }
                    InfoRow {
                        s: root.s; label: qsTr("IPv4"); value: root.ts ? root.ts.ip4 : ""
                        actionText: (root.ts && root.ts.ip4.length > 0) ? qsTr("COPY") : ""
                        onActionTriggered: if (root.ts) root.ts.copyIp()
                    }
                    InfoRow { s: root.s; label: qsTr("IPv6");    value: root.ts ? root.ts.ip6 : "" }
                    InfoRow { s: root.s; label: qsTr("Tailnet"); value: root.ts ? root.ts.tailnet : "" }
                    InfoRow {
                        s: root.s; label: qsTr("Exit node")
                        value: root.ts ? (root.ts.exitNodeActive ? (root.ts.exitNodeName.length > 0 ? root.ts.exitNodeName : qsTr("active")) : "") : ""
                        actionText: (root.ts && root.ts.exitNodeActive) ? qsTr("STOP USING") : ""
                        onActionTriggered: if (root.ts) root.ts.stopExitNode()
                    }
                    InfoRow { s: root.s; label: qsTr("Relay"); value: root.ts ? root.ts.relay : "" }
                    InfoRow {
                        s: root.s; label: qsTr("Peers")
                        value: root.ts && root.ts.peersTotal > 0 ? (root.ts.peersOnline + " / " + root.ts.peersTotal) : ""
                    }
                    InfoRow { s: root.s; label: qsTr("Version"); value: root.ts ? root.ts.version : "" }
                    InfoRow { s: root.s; label: qsTr("Up for");  value: root.ts && root.ts.up && root.service ? root.service.uptime : "" }

                    // health warnings
                    Repeater {
                        model: root.ts ? root.ts.health : []
                        delegate: Text {
                            required property var modelData
                            width: parent ? parent.width : 0
                            text: "\u26a0 " + modelData
                            color: Theme.gold
                            font.family: Theme.mono
                            font.pixelSize: 9.5 * root.s
                            wrapMode: Text.WordWrap
                        }
                    }

                    // operator gate
                    Column {
                        width: parent.width
                        spacing: 6 * root.s
                        visible: root.ts && root.ts.needsOperator
                        Text {
                            width: parent.width
                            text: qsTr("Tailscale only lets its operator switch it. Authorise this user once (asks for your password).")
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 10 * root.s
                            wrapMode: Text.WordWrap
                        }
                        Rectangle {
                            width: authText.implicitWidth + 22 * root.s
                            height: 22 * root.s
                            color: authHover.hovered ? Theme.sheen : "transparent"
                            border.width: 1
                            border.color: Theme.lineStrong
                            Text {
                                id: authText
                                anchors.centerIn: parent
                                text: qsTr("AUTHORISE")
                                color: Theme.cream
                                font.family: Theme.mono
                                font.pixelSize: 9 * root.s
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.4 * root.s
                            }
                            HoverHandler { id: authHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: if (root.ts) root.ts.authorise() }
                        }
                    }
                }

                // ── NetworkManager ──
                Column {
                    width: parent.width
                    spacing: 4 * root.s
                    visible: root.nmHas

                    Eyebrow { label: "NetworkManager"; s: root.s }

                    Repeater {
                        model: root.nm ? root.nm.profiles : []
                        delegate: Column {
                            id: prof
                            required property var modelData
                            width: parent ? parent.width : 0
                            spacing: 2 * root.s
                            InfoRow {
                                s: root.s
                                label: prof.modelData.type
                                value: prof.modelData.name
                                actionText: prof.modelData.active ? qsTr("ON") : qsTr("OFF")
                                onActionTriggered: {
                                    if (!root.nm) return;
                                    if (prof.modelData.active) root.nm.down(prof.modelData.uuid);
                                    else root.nm.up(prof.modelData.uuid);
                                }
                            }
                            InfoRow { s: root.s; label: qsTr("IPv4");    value: prof.modelData.active ? prof.modelData.ip4 : "" }
                            InfoRow { s: root.s; label: qsTr("Gateway"); value: prof.modelData.active ? prof.modelData.gateway : "" }
                        }
                    }
                }

                // ── empty state ──
                Text {
                    visible: root.noBackend
                    width: parent.width
                    text: qsTr("No VPN backend found. Install Tailscale, or add a VPN or WireGuard profile in NetworkManager.")
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 10.5 * root.s
                    wrapMode: Text.WordWrap
                }

                // confirm-off warning
                Text {
                    visible: root.armed
                    width: parent.width
                    text: qsTr("TURN OFF? traffic leaves the exit node")
                    color: Theme.gold
                    font.family: Theme.mono
                    font.pixelSize: 9.5 * root.s
                    wrapMode: Text.WordWrap
                }

                // CONNECT / DISCONNECT
                Rectangle {
                    id: toggle
                    width: toggleText.implicitWidth + 24 * root.s
                    height: 24 * root.s
                    color: toggleHover.hovered && root.canToggle ? Theme.sheen : "transparent"
                    border.width: 1
                    border.color: root.canToggle ? Theme.lineStrong : Theme.border
                    opacity: root.canToggle ? 1 : 0.5
                    Text {
                        id: toggleText
                        anchors.centerIn: parent
                        text: root.armed ? qsTr("CONFIRM OFF")
                            : (root.connected ? qsTr("DISCONNECT") : qsTr("CONNECT"))
                        color: Theme.cream
                        font.family: Theme.mono
                        font.pixelSize: 9.5 * root.s
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.6 * root.s
                    }
                    HoverHandler { id: toggleHover; cursorShape: root.canToggle ? Qt.PointingHandCursor : Qt.ArrowCursor }
                    TapHandler { enabled: root.canToggle; onTapped: root.primaryToggle() }
                }
            }
        }
    }
}
