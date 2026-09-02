pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// The VPN plugin's `main` entry point: headless, backend-aware state and logic,
// no UI. The host keeps one instance alive across content mounts and hands it to
// every view as pluginApi.mainInstance, so the bar glyph, the bar panel and the
// desktop card all bind the same live state.
//
// Two backends live side by side as inline objects `ts` (Tailscale) and `nm`
// (NetworkManager), each polled on its own commands. The svc root folds them
// into the aggregate a view reads: connected, headline, barText, uptime,
// lastAction. No click in any view ever mutates the network; the mutations live
// here, behind named actions, and a privileged action only ever runs on the
// panel's explicit AUTHORISE tap through pkexec.
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
    readonly property int poll: Math.max(3, Math.min(60, Math.round(_num("poll", 10))))
    // What rides beside the bar mark: nothing, the headline, or the IPv4.
    readonly property string barLabel: _str("barLabel", "name")
    // Whether turning off an exit-node VPN asks first. A UI arm the views honour;
    // the service only exposes the flag and the exitNodeActive state it keys on.
    readonly property bool confirmOff: _bool("confirmOff", true)

    // ── shared nmcli terse-line splitter ─────────────────────────────────────
    // Split one nmcli terse line on unescaped ':'. Terse mode backslash-escapes
    // ':' and '\' inside a field, so a plain split would mangle a value with a
    // colon in it (an IPv6 address, a NAME with a colon).
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

    // ── aggregate state the views bind ───────────────────────────────────────
    // True when either backend has a live tunnel.
    readonly property bool connected: ts.up || nm.activeCount > 0
    // The one line naming the connection: the Tailscale host when it is up, else
    // the first active NetworkManager profile's name, else empty.
    readonly property string headline: ts.up ? ts.hostName
        : (nm.activeProfile ? nm.activeProfile.name : "")
    // What the bar mark carries, per the barLabel setting.
    readonly property string barText: {
        if (barLabel === "none") return "";
        if (barLabel === "ip")
            return ts.up ? ts.ip4 : (nm.activeProfile ? nm.activeProfile.ip4 : "");
        return headline;
    }
    // First sighting of the current connection, for uptime; 0 when nothing is up.
    property double since: 0
    readonly property string uptime: {
        clock.tick;
        if (!connected || since <= 0) return "";
        var s = Math.max(0, Math.floor((Date.now() - since) / 1000));
        var h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
        return h > 0 ? h + "h " + m + "m" : (m > 0 ? m + "m" : s + "s");
    }
    // One line describing the last mutation and how it went (the error on fail).
    property string lastAction: ""

    onConnectedChanged: since = connected ? Date.now() : 0

    // a pulse so uptime re-derives without a network poll
    Timer { id: clock; property int tick: 0; interval: 30000; running: svc.connected; repeat: true; onTriggered: tick++ }

    // A one-shot refresh 1 s after any action, so a view reflects the new state
    // without waiting for the poll timer.
    Timer {
        id: soon
        interval: 1000
        repeat: false
        onTriggered: { ts.refresh(); nm.refresh(); }
    }
    function _bumpSoon() { soon.restart(); }

    // Poll both backends on the cadence, and once on load.
    Timer {
        interval: svc.poll * 1000
        running: true
        repeat: true
        onTriggered: { ts.refresh(); nm.refresh(); }
    }
    Component.onCompleted: { ts.refresh(); nm.refresh(); }

    // ── Tailscale backend ────────────────────────────────────────────────────
    // Installed is discovered by running `tailscale status --json`: a clean exit
    // means the CLI is there, a failed start means it is not. Mutations go
    // through `tailscale up|down|set`; when one is refused for want of an
    // operator (this box has none set) needsOperator is raised and the pending
    // action is retried after the panel's AUTHORISE sets the operator via pkexec.
    property QtObject ts: QtObject {
        id: ts

        property bool installed: false
        // Running | Stopped | NeedsLogin | NoState | Missing.
        property string state: "Missing"
        readonly property bool up: state === "Running"
        property string hostName: ""
        property string dnsName: ""      // trailing dot stripped
        property string ip4: ""
        property string ip6: ""
        property string tailnet: ""      // CurrentTailnet.Name
        property string magicDns: ""     // MagicDNSSuffix
        property string exitNodeName: "" // resolved peer HostName, "" when none
        property bool exitNodeActive: false
        property string relay: ""        // Self.Relay
        property int peersOnline: 0
        property int peersTotal: 0
        property string version: ""
        property var health: []          // Health[] minus "Tailscale is stopped."
        // Raised when a mutation is refused for want of an operator; cleared by
        // authorise(), which then re-runs the action that tripped it.
        property bool needsOperator: false
        property string _pending: ""     // "up" | "down" | "exitoff"

        function _apply(text) {
            var j;
            try { j = JSON.parse(text); } catch (e) { return; }
            if (!j) return;
            var bs = j.BackendState || "";
            ts.state = bs === "Running" ? "Running"
                : bs === "Stopped" ? "Stopped"
                : bs === "NeedsLogin" ? "NeedsLogin" : "NoState";
            var self = j.Self || ({});
            ts.hostName = self.HostName || "";
            var dn = self.DNSName || "";
            ts.dnsName = (dn.length > 0 && dn.charAt(dn.length - 1) === ".") ? dn.slice(0, -1) : dn;
            var ips = self.TailscaleIPs || j.TailscaleIPs || [];
            var v4 = "", v6 = "";
            for (var i = 0; i < ips.length; i++) {
                if (String(ips[i]).indexOf(":") >= 0) { if (v6 === "") v6 = ips[i]; }
                else if (v4 === "") v4 = ips[i];
            }
            ts.ip4 = v4; ts.ip6 = v6;
            ts.relay = self.Relay || "";
            var ct = j.CurrentTailnet || ({});
            ts.tailnet = ct.Name || "";
            ts.magicDns = j.MagicDNSSuffix || "";
            ts.version = j.Version || "";
            // exit node: ExitNodeStatus.ID resolved against the peer table.
            var es = j.ExitNodeStatus || null;
            ts.exitNodeActive = !!es;
            var en = "";
            var peers = j.Peer || ({});
            var keys = Object.keys(peers);
            var online = 0;
            for (var k = 0; k < keys.length; k++) {
                var p = peers[keys[k]];
                if (p && p.Online === true) online++;
                if (es && p && p.ID === es.ID) en = p.HostName || "";
            }
            ts.exitNodeName = en;
            ts.peersTotal = keys.length;
            ts.peersOnline = online;
            // health minus the redundant "Tailscale is stopped." banner (the OFF
            // pill already says as much); real warnings survive.
            var hl = j.Health || [];
            var kept = [];
            for (var h = 0; h < hl.length; h++) {
                if (String(hl[h]).trim() !== "Tailscale is stopped.")
                    kept.push(hl[h]);
            }
            ts.health = kept;
            ts.installed = true;
        }

        // Poll: read status as JSON. A failed start means the CLI is missing.
        property string _statusBuf: ""
        property Process _status: Process {
            command: ["tailscale", "status", "--json"]
            stdout: StdioCollector { onStreamFinished: ts._statusBuf = text }
            onExited: (code) => {
                if (code === 0) ts._apply(ts._statusBuf);
                else { ts.installed = false; ts.state = "Missing"; }
                ts._statusBuf = "";
            }
        }
        function refresh() {
            if (_status.running) return;
            _statusBuf = "";
            _status.running = true;
        }

        // Mutations: up / down / clear-exit-node share one Process; the tag
        // records which ran, so an operator refusal knows what to retry.
        property string _actErr: ""
        property string _actTag: ""
        property Process _act: Process {
            stderr: StdioCollector { onStreamFinished: ts._actErr = text }
            onExited: (code) => ts._afterAct(code)
        }
        function _run(cmd, tag) {
            if (_act.running) return;
            ts._actErr = "";
            ts._actTag = tag;
            _act.command = cmd;
            _act.running = true;
        }
        function _label(tag) {
            return tag === "up" ? "up" : tag === "down" ? "down"
                : tag === "exitoff" ? "exit-node off" : tag;
        }
        function _afterAct(code) {
            var err = String(ts._actErr).trim();
            if (code !== 0 && /access denied|--operator|\boperator\b/i.test(err)) {
                // Refused for want of an operator: remember what to retry and ask
                // the UI to offer AUTHORISE.
                ts.needsOperator = true;
                if (ts._actTag === "up" || ts._actTag === "down" || ts._actTag === "exitoff")
                    ts._pending = ts._actTag;
                svc.lastAction = "tailscale " + ts._label(ts._actTag) + ": needs operator";
            } else if (code !== 0) {
                svc.lastAction = "tailscale " + ts._label(ts._actTag) + ": "
                    + (err.length > 0 ? err.split("\n")[0] : "failed");
            } else {
                svc.lastAction = "tailscale " + ts._label(ts._actTag) + ": ok";
            }
            svc._bumpSoon();
        }

        function turnOn()       { ts._run(["tailscale", "up"], "up"); }
        function turnOff()      { ts._run(["tailscale", "down"], "down"); }
        function stopExitNode() { ts._run(["tailscale", "set", "--exit-node="], "exitoff"); }

        // The one privileged action, from the panel's AUTHORISE tap only: set
        // this user as the operator so future up/down need no root. pkexec asks
        // for the password once; on success the pending action is retried.
        property string _authErr: ""
        property Process _auth: Process {
            stderr: StdioCollector { onStreamFinished: ts._authErr = text }
            onExited: (code) => ts._afterAuth(code)
        }
        function authorise() {
            if (_auth.running) return;
            var user = Quickshell.env("USER") || "";
            if (user.length === 0) { svc.lastAction = "authorise: no USER in environment"; return; }
            ts._authErr = "";
            _auth.command = ["pkexec", "tailscale", "set", "--operator=" + user];
            _auth.running = true;
        }
        function _afterAuth(code) {
            if (code === 0) {
                ts.needsOperator = false;
                svc.lastAction = "operator set; retrying";
                var p = ts._pending;
                ts._pending = "";
                if (p === "up") ts.turnOn();
                else if (p === "down") ts.turnOff();
                else if (p === "exitoff") ts.stopExitNode();
                svc._bumpSoon();
            } else {
                svc.lastAction = "authorise cancelled";
            }
        }

        // Read-only conveniences, fire-and-forget so nothing lingers holding the
        // clipboard selection or a browser handle.
        function copyIp()   { if (ts.ip4.length > 0) Quickshell.execDetached(["wl-copy", ts.ip4]); }
        function openAdmin() { Quickshell.execDetached(["xdg-open", "https://login.tailscale.com/admin/machines"]); }
    }

    // ── NetworkManager backend ───────────────────────────────────────────────
    // The VPN and WireGuard profiles NetworkManager knows, active flagged, with
    // per-active-profile addresses. A tun device or an externally managed /
    // unmanaged connection is never touched: those are other software's tunnels
    // (a Tailscale tun, a container link) and toggling them is not this plugin's
    // job.
    property QtObject nm: QtObject {
        id: nm

        // [{name, uuid, type, device, active, ip4, ip6, gateway, dns}]
        property var profiles: []
        property int activeCount: 0
        readonly property var activeProfile: {
            for (var i = 0; i < profiles.length; i++)
                if (profiles[i].active) return profiles[i];
            return null;
        }

        function _keep(type, device, state) {
            var t = String(type).toLowerCase();
            if (t !== "vpn" && t !== "wireguard") return false;
            if (String(device).indexOf("tun") === 0) return false;            // never a tun device
            var s = String(state).toLowerCase();
            if (s.indexOf("external") >= 0 || s.indexOf("unmanaged") >= 0) return false;
            return true;
        }
        function _noCidr(v) {
            var s = String(v);
            var slash = s.indexOf("/");
            return slash >= 0 ? s.slice(0, slash) : s;
        }

        // Poll: every profile, terse, five columns.
        property string _listBuf: ""
        property Process _list: Process {
            command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,DEVICE,STATE", "connection", "show"]
            stdout: StdioCollector { onStreamFinished: nm._listBuf = text }
            onExited: (code) => {
                if (code === 0) nm._applyList(nm._listBuf);
                else { nm.profiles = []; nm.activeCount = 0; }
                nm._listBuf = "";
            }
        }
        function refresh() {
            if (_list.running) return;
            _listBuf = "";
            _list.running = true;
        }

        function _applyList(text) {
            var lines = String(text).split("\n");
            var out = [];
            var active = 0;
            for (var i = 0; i < lines.length; i++) {
                if (lines[i].trim().length === 0) continue;
                var f = svc._fields(lines[i]);
                if (f.length < 5) continue;
                if (!nm._keep(f[2], f[3], f[4])) continue;
                var isActive = String(f[4]).toLowerCase() === "activated";
                if (isActive) active++;
                out.push({ name: f[0], uuid: f[1], type: f[2], device: f[3],
                           active: isActive, ip4: "", ip6: "", gateway: "", dns: "" });
            }
            // carry forward already-fetched details for still-present profiles so
            // a poll does not blank the addresses between detail fetches.
            for (var k = 0; k < out.length; k++) {
                for (var p = 0; p < nm.profiles.length; p++) {
                    if (nm.profiles[p].uuid === out[k].uuid) {
                        out[k].ip4 = nm.profiles[p].ip4;
                        out[k].ip6 = nm.profiles[p].ip6;
                        out[k].gateway = nm.profiles[p].gateway;
                        out[k].dns = nm.profiles[p].dns;
                        break;
                    }
                }
            }
            nm.profiles = out;
            nm.activeCount = active;
            nm._fetchDetails();
        }

        // Device details for active profiles, fetched one at a time off a queue.
        property var _queue: []
        property string _detailBuf: ""
        property string _detailUuid: ""
        property Process _detail: Process {
            stdout: StdioCollector { onStreamFinished: nm._detailBuf = text }
            onExited: (code) => {
                if (code === 0) nm._applyDetail();
                nm._detailBuf = "";
                nm._next();
            }
        }
        function _fetchDetails() {
            var q = [];
            for (var i = 0; i < profiles.length; i++)
                if (profiles[i].active && String(profiles[i].device).length > 0)
                    q.push({ uuid: profiles[i].uuid, device: profiles[i].device });
            nm._queue = q;
            if (!_detail.running) nm._next();
        }
        function _next() {
            if (_detail.running) return;
            if (nm._queue.length === 0) return;
            var item = nm._queue.shift();
            nm._detailUuid = item.uuid;
            nm._detailBuf = "";
            _detail.command = ["nmcli", "-t", "-f", "IP4.ADDRESS,IP6.ADDRESS,IP4.GATEWAY,IP4.DNS",
                               "device", "show", item.device];
            _detail.running = true;
        }
        function _applyDetail() {
            var lines = String(nm._detailBuf).split("\n");
            var v4 = "", v6 = "", gw = "", dns = "";
            for (var i = 0; i < lines.length; i++) {
                var f = svc._fields(lines[i]);
                if (f.length < 2) continue;
                var key = f[0], val = f.slice(1).join(":");
                if (key.indexOf("IP4.ADDRESS") === 0 && v4 === "") v4 = nm._noCidr(val);
                else if (key.indexOf("IP6.ADDRESS") === 0 && v6 === "" && val.indexOf("fe80:") !== 0) v6 = nm._noCidr(val);
                else if (key.indexOf("IP4.GATEWAY") === 0 && gw === "") gw = val;
                else if (key.indexOf("IP4.DNS") === 0 && dns === "") dns = val;
            }
            var arr = nm.profiles.slice();
            for (var p = 0; p < arr.length; p++) {
                if (arr[p].uuid === nm._detailUuid) {
                    arr[p].ip4 = v4; arr[p].ip6 = v6; arr[p].gateway = gw; arr[p].dns = dns;
                    break;
                }
            }
            nm.profiles = arr;
        }

        // Mutations: bring a profile up or down by UUID (stable across renames).
        property Process _act: Process { onExited: (code) => svc._bumpSoon() }
        function up(uuid) {
            if (uuid && String(uuid).length > 0 && !_act.running) {
                _act.command = ["nmcli", "connection", "up", "uuid", uuid];
                _act.running = true;
                svc.lastAction = "nmcli up " + uuid;
            }
        }
        function down(uuid) {
            if (uuid && String(uuid).length > 0 && !_act.running) {
                _act.command = ["nmcli", "connection", "down", "uuid", uuid];
                _act.running = true;
                svc.lastAction = "nmcli down " + uuid;
            }
        }
    }
}
