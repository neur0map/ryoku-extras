import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var pluginApi
    property var flat: []
    property var groups: ["All"]
    property string query: ""
    property string group: "All"
    property var results: []
    property bool loaded: false
    property string loadError: ""
    readonly property string action: setting("action", "copy") === "insert" ? "insert" : "copy"

    function setting(k, def) {
        var s = pluginApi ? pluginApi.pluginSettings : null;
        if (!s || s[k] === undefined || s[k] === null || s[k] === "") return def;
        return s[k];
    }
    function boolSetting(k, def) { var v = setting(k, def); return v === true || v === "true"; }

    // The host assigns pluginApi after construction (PluginObjectSlot.configure),
    // so the catalogue load has to wait for it.
    onPluginApiChanged: if (pluginApi) root.load()
    function load() {
        var dir = pluginApi ? pluginApi.pluginDir : "";
        if (!dir) return;
        catalog.path = dir + "/data/emojis.json";
    }
    FileView {
        id: catalog
        path: ""
        onLoaded: root.digest(text())
    }

    function digest(raw) {
        try {
            var json = JSON.parse(raw);
            var out = [];
            var names = ["All"];
            json.groups.forEach(function (g) {
                names.push(g.g);
                g.subs.forEach(function (sub) {
                    sub.l.forEach(function (item) {
                        out.push({ e: item.e, n: item.n, g: g.g });
                    });
                });
            });
            root.groups = names;
            root.flat = out;
            root.loaded = true;
            root.apply();
        } catch (e) {
            root.loadError = "parse: " + e;
        }
    }

    function apply() {
        var q = root.query.toLowerCase().trim();
        var gr = root.group;
        var res = [];
        var src = root.flat;
        var i, it;
        for (i = 0; i < src.length; i++) {
            it = src[i];
            if (gr !== "All" && it.g !== gr) continue;
            if (q.length > 0) {
                if ((it.e.indexOf(q) >= 0) || (it.n.indexOf(q) >= 0)) res.push(it);
            } else {
                res.push(it);
            }
        }
        root.results = res;
    }
    function setQuery(q) { root.query = q; root.apply(); }
    function setGroup(g) { root.group = g; root.apply(); }

    function hostOpened() {}

    function act(mode, emoji) {
        var dir = pluginApi ? pluginApi.pluginDir : "";
        if (!dir) return;
        actProc.command = [dir + "/bin/ryoku-emoji", mode, emoji];
        actProc.running = true;
    }
    Process {
        id: actProc
        stderr: StdioCollector { onStreamFinished: console.warn("emoji: " + text.trim()) }
    }

    function pick(emoji) {
        act(root.action, emoji);
        if (root.boolSetting("closeAfterPick", true)) closeProc.running = true;
    }
    function copyOnly(emoji) { act("copy", emoji); }

    Process {
        id: closeProc
        command: ["ryoku-shell", "plugin", "emoji"]
    }
}