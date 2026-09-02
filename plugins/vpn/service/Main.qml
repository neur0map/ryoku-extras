pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

// The VPN plugin's `main` entry point: headless state and logic, no UI. The bar
// host keeps one instance alive across content mounts and hands it to the widget
// as pluginApi.mainInstance, so the glyph binds live connection state.
//
// It polls NetworkManager for the active connection table and flips the VPN up
// or down on request. A connection counts as a VPN when its nmcli TYPE is one of
// the `types` the user configured (vpn / wireguard / tun by default).
Item {
    id: svc

    // Set by the host after this loads; the plugin's settings live behind it.
    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

    // Settings resolver: every value read behind a default, never hardcoded, so
    // a missing key (settings are not auto-seeded at runtime) falls back cleanly.
    function _has(k) {
        return settings && settings[k] !== undefined && settings[k] !== null && settings[k] !== "";
    }
    function _num(k, d) { return _has(k) ? Number(settings[k]) : d; }
    function _str(k, d) { return _has(k) ? String(settings[k]) : d; }
    function _bool(k, d) {
        if (!settings || settings[k] === undefined || settings[k] === null)
            return d;
        return settings[k] === true || settings[k] === "true";
    }

    // Poll cadence in seconds, clamped to the manifest's range.
    readonly property int poll: Math.max(2, Math.min(60, Math.round(_num("poll", 5))))
    // Whether the widget may draw the connection name beside the mark.
    readonly property bool showName: _bool("showName", true)
    // nmcli TYPEs that count as a VPN, as a comma or space separated list.
    readonly property string typesText: _str("types", "vpn,wireguard,tun")
    readonly property var types: {
        var out = [];
        var parts = typesText.split(/[,\s]+/);
        for (var i = 0; i < parts.length; i++) {
            var t = parts[i].trim().toLowerCase();
            if (t.length > 0 && out.indexOf(t) < 0)
                out.push(t);
        }
        return out;
    }

    // Live state the widget binds.
    // True while an active connection matches one of `types`.
    property bool connected: false
    // NAME of the active VPN connection, empty when none is up.
    property string name: ""
    // Last VPN NAME seen up, so a click can bring it back after it drops.
    property string lastVpn: ""

    // Split one nmcli terse line on unescaped ':'. Terse mode backslash-escapes
    // ':' and '\' inside a field, so a plain split would mangle a NAME with a
    // colon in it.
    function _fields(line) {
        var out = [];
        var cur = "";
        for (var i = 0; i < line.length; i++) {
            var c = line.charAt(i);
            if (c === "\\" && i + 1 < line.length) {
                cur += line.charAt(i + 1);
                i += 1;
            } else if (c === ":") {
                out.push(cur);
                cur = "";
            } else {
                cur += c;
            }
        }
        out.push(cur);
        return out;
    }

    function _isVpnType(t) {
        return types.indexOf(String(t).trim().toLowerCase()) >= 0;
    }

    // Fold the active-connection table into state: the first VPN-typed row wins
    // the headline, and its NAME is remembered so a later toggle can reconnect.
    function _apply(text) {
        var lines = String(text).split("\n");
        var found = false;
        var vpnName = "";
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].trim().length === 0)
                continue;
            var f = _fields(lines[i]);
            var nm = f.length > 0 ? f[0] : "";
            var ty = f.length > 1 ? f[1] : "";
            if (nm.length > 0 && _isVpnType(ty)) {
                found = true;
                vpnName = nm;
                break;
            }
        }
        connected = found;
        name = found ? vpnName : "";
        if (found)
            lastVpn = vpnName;
    }

    // Poll: read the active connections. active-first, terse, three columns.
    property string _out: ""
    Process {
        id: pollProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]
        stdout: StdioCollector { onStreamFinished: svc._out = text }
        onExited: svc._apply(svc._out)
    }

    function refresh() {
        if (pollProc.running)
            return;
        _out = "";
        pollProc.running = true;
    }

    // Toggle: down the active VPN, or bring the last-seen one back up. A refresh
    // right after the action lands reflects the new state without waiting for the
    // timer. With nothing active and nothing remembered there is nothing to do.
    Process {
        id: toggleProc
        onExited: svc.refresh()
    }

    function toggle() {
        if (toggleProc.running)
            return;
        if (connected && name.length > 0) {
            toggleProc.command = ["nmcli", "connection", "down", name];
            toggleProc.running = true;
        } else if (lastVpn.length > 0) {
            toggleProc.command = ["nmcli", "connection", "up", lastVpn];
            toggleProc.running = true;
        } else {
            console.log("vpn: nothing to toggle, no active or remembered VPN connection");
        }
    }

    // First read on load, then on the poll cadence.
    Timer {
        interval: svc.poll * 1000
        running: true
        repeat: true
        onTriggered: svc.refresh()
    }

    Component.onCompleted: refresh()
}
