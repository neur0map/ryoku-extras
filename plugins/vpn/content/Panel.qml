pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// The bar panel: the plugin's full view, mounted by the host in the shared
// plugin panel surface under the glyph. It reads the two backends off the
// service and lays out a Tailscale card (a switch and the tunnel's dossier) and
// a NetworkManager card (one row per VPN/WireGuard profile). Every mutation is a
// deliberate tap here; turning off an exit-node tunnel arms once before it acts.
// The panel draws no window chrome: the host owns the surface and sizes it to
// this root's implicitHeight.
Item {
    id: root

    // Host-set; read only, never assign.
    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 320
    property bool active: false

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property var ts: service ? service.ts : null
    readonly property var nm: service ? service.nm : null

    readonly property real w: widthBudget > 0 ? widthBudget : 320
    readonly property bool tsInstalled: ts ? ts.installed : false
    readonly property bool nmHas: nm ? nm.profiles.length > 0 : false
    readonly property bool noBackend: !tsInstalled && !nmHas

    // Header pill: the single word for the whole state.
    readonly property string pillText: {
        if (service && service.connected) return "UP";
        if (tsInstalled && ts.state === "NeedsLogin") return "NEEDS LOGIN";
        if (noBackend) return "NO BACKEND";
        return "OFF";
    }
    readonly property color pillInk: {
        if (pillText === "UP") return Theme.accent;
        if (pillText === "NEEDS LOGIN") return Theme.gold;
        return Theme.dim;
    }

    implicitWidth: w
    implicitHeight: col.implicitHeight

    // ── reusable bits ────────────────────────────────────────────────────────
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
            font.pixelSize: 10 * eb.s
            font.weight: Font.DemiBold
            font.letterSpacing: 2.2 * eb.s
            font.capitalization: Font.AllUppercase
        }
    }

    component Divider: Rectangle {
        width: parent ? parent.width : 0
        height: 1
        color: Theme.hair
    }

    // A bordered mono button. `strong` lifts the border for the primary action.
    component Btn: Rectangle {
        id: btn
        property string label: ""
        property bool enabledAction: true
        property bool strong: false
        signal tapped()
        implicitWidth: btnText.implicitWidth + 22 * root.s
        implicitHeight: 24 * root.s
        radius: 0
        color: btnHover.hovered && btn.enabledAction ? Theme.sheen : "transparent"
        border.width: 1
        border.color: btn.enabledAction ? (btn.strong ? Theme.lineStrong : Theme.border) : Theme.border
        opacity: btn.enabledAction ? 1 : 0.5
        Text {
            id: btnText
            anchors.centerIn: parent
            text: btn.label
            color: Theme.cream
            font.family: Theme.mono
            font.pixelSize: 9.5 * root.s
            font.weight: Font.DemiBold
            font.letterSpacing: 1.6 * root.s
        }
        HoverHandler { id: btnHover; cursorShape: btn.enabledAction ? Qt.PointingHandCursor : Qt.ArrowCursor }
        TapHandler { enabled: btn.enabledAction; onTapped: btn.tapped() }
    }

    // ── content ──────────────────────────────────────────────────────────────
    Column {
        id: col
        width: root.w
        spacing: 12 * root.s

        // head: title + state pill
        Item {
            width: parent.width
            height: 20 * root.s
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "VPN"
                color: Theme.cream
                font.family: Theme.mono
                font.pixelSize: 13 * root.s
                font.weight: Font.DemiBold
                font.letterSpacing: 2.4 * root.s
            }
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: pill.implicitWidth + 14 * root.s
                height: 17 * root.s
                radius: 0
                color: "transparent"
                border.width: 1
                border.color: root.pillInk
                Text {
                    id: pill
                    anchors.centerIn: parent
                    text: root.pillText
                    color: root.pillInk
                    font.family: Theme.mono
                    font.pixelSize: 8.5 * root.s
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.6 * root.s
                }
            }
        }

        // ── Tailscale card ────────────────────────────────────────────────
        Column {
            id: tsCard
            width: parent.width
            spacing: 9 * root.s
            visible: root.tsInstalled

            // arm state for the confirm-off flow
            property bool armed: false
            Timer { id: disarm; interval: 3000; repeat: false; onTriggered: tsCard.armed = false }

            Eyebrow { label: "Tailscale"; s: root.s }

            // switch row
            Item {
                width: parent.width
                height: 24 * root.s
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.ts && root.ts.up ? qsTr("Connected") : qsTr("Disconnected")
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    font.weight: Font.DemiBold
                }
                Btn {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    strong: true
                    label: tsCard.armed ? qsTr("CONFIRM OFF")
                        : (root.ts && root.ts.up ? qsTr("TURN OFF") : qsTr("TURN ON"))
                    onTapped: {
                        if (!root.ts) return;
                        if (root.ts.up) {
                            if (root.service.confirmOff && root.ts.exitNodeActive && !tsCard.armed) {
                                tsCard.armed = true;
                                disarm.restart();
                            } else {
                                root.ts.turnOff();
                                tsCard.armed = false;
                                disarm.stop();
                            }
                        } else {
                            root.ts.turnOn();
                        }
                    }
                }
            }

            // the exit-node confirm warning, shown only while armed
            Text {
                width: parent.width
                visible: tsCard.armed
                text: qsTr("TURN OFF? traffic leaves the exit node")
                color: Theme.gold
                font.family: Theme.mono
                font.pixelSize: 9.5 * root.s
                font.letterSpacing: 0.6 * root.s
                wrapMode: Text.WordWrap
            }

            Divider {}

            // the dossier rows
            Column {
                width: parent.width
                spacing: 3 * root.s

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
            }

            // health warnings, when tailscale reports any
            Column {
                width: parent.width
                spacing: 3 * root.s
                visible: root.ts && root.ts.health.length > 0
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
            }

            // the operator gate: shown when a mutation was refused for want of one
            Column {
                width: parent.width
                spacing: 7 * root.s
                visible: root.ts && root.ts.needsOperator
                Divider {}
                Text {
                    width: parent.width
                    text: qsTr("Tailscale only lets its operator switch it. Authorise this user once (asks for your password).")
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 10.5 * root.s
                    wrapMode: Text.WordWrap
                }
                Btn { strong: true; label: qsTr("AUTHORISE"); onTapped: if (root.ts) root.ts.authorise() }
            }

            Divider {}

            // footer
            Item {
                width: parent.width
                height: 24 * root.s
                Btn {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    label: qsTr("ADMIN CONSOLE")
                    onTapped: if (root.ts) root.ts.openAdmin()
                }
            }
        }

        // ── NetworkManager card ───────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 9 * root.s
            visible: root.nmHas

            Eyebrow { label: "NetworkManager"; s: root.s }

            Repeater {
                model: root.nm ? root.nm.profiles : []
                delegate: Column {
                    id: prof
                    required property var modelData
                    width: parent ? parent.width : 0
                    spacing: 3 * root.s

                    Item {
                        width: parent.width
                        height: 24 * root.s
                        Column {
                            anchors.left: parent.left
                            anchors.right: nmToggle.left
                            anchors.rightMargin: 8 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                width: parent.width
                                text: prof.modelData.name
                                color: Theme.cream
                                font.family: Theme.font
                                font.pixelSize: 12 * root.s
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: prof.modelData.type
                                color: Theme.dim
                                font.family: Theme.mono
                                font.pixelSize: 9 * root.s
                                elide: Text.ElideRight
                            }
                        }
                        Btn {
                            id: nmToggle
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            strong: true
                            label: prof.modelData.active ? qsTr("TURN OFF") : qsTr("TURN ON")
                            onTapped: {
                                if (!root.nm) return;
                                if (prof.modelData.active) root.nm.down(prof.modelData.uuid);
                                else root.nm.up(prof.modelData.uuid);
                            }
                        }
                    }

                    InfoRow { s: root.s; label: qsTr("Device");  value: prof.modelData.active ? prof.modelData.device : "" }
                    InfoRow { s: root.s; label: qsTr("IPv4");    value: prof.modelData.active ? prof.modelData.ip4 : "" }
                    InfoRow { s: root.s; label: qsTr("Gateway"); value: prof.modelData.active ? prof.modelData.gateway : "" }
                }
            }
        }

        // ── empty state ───────────────────────────────────────────────────
        Text {
            width: parent.width
            visible: root.noBackend
            text: qsTr("No VPN backend found. Install Tailscale, or add a VPN or WireGuard profile in NetworkManager, and it will show up here.")
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 11 * root.s
            wrapMode: Text.WordWrap
        }
    }
}
