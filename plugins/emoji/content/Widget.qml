import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons
import "components"

// The `content` for the emoji plugin: search, category chips, and a pickable
// grid. It is one view for every host - the popout renders it at `full`, the
// desktop tile at `compact`. All state lives in the service
// (pluginApi.mainInstance); this file only reads it and forwards picks.
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active
    property string density: "compact"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null

    // grid selection driven by the arrow keys while typing in the search box.
    property int sel: 0
    readonly property var selected: root.service && root.service.results.length > 0
        ? root.service.results[Math.min(root.sel, root.service.results.length - 1)] : null

    function clampSel(v) {
        var n = root.service ? root.service.results.length : 0;
        if (n === 0) return 0;
        return Math.max(0, Math.min(n - 1, v));
    }
    function moveSel(d) { root.sel = root.clampSel(root.sel + d); }
    function pickSel() { if (root.selected) root.service.pick(root.selected.e); }

    // a fresh search/group wipes the cursor back to the first result.
    Connections {
        target: root.service ? root.service : null
        function onResultsChanged() { root.sel = 0; }
    }

    // grid geometry derived from the width the host gave us - never hardcoded.
    readonly property real contentW: density === "glyph" ? 26 * s
        : (widthBudget > 0 ? widthBudget : (density === "full" ? 520 * s : 360 * s))
    readonly property int cols: {
        var c = pluginApi && pluginApi.pluginSettings
            ? Number(pluginApi.pluginSettings.columns || 8) : 8;
        return Math.max(4, Math.min(16, isNaN(c) ? 8 : c));
    }
    readonly property real gap: 6 * s
    readonly property real pad: 12 * s
    readonly property real cell: Math.floor((contentW - 2 * pad - (gap * (cols - 1))) / cols)
    readonly property real gridH: Math.min(5 * (cell + gap), 340 * s)
    readonly property bool popout: density === "full"

    implicitWidth: contentW
    implicitHeight: density === "glyph" ? 26 * s : col.implicitHeight

    GlyphIcon {
        visible: root.density === "glyph"
        anchors.fill: parent
        name: "extension"
        color: Theme.iconDim
        stroke: 1.6
    }

    Column {
        id: col
        visible: root.density !== "glyph"
        width: root.contentW
        spacing: 10 * root.s

        // category chips: All + the emoji groups, wheel-scrollable.
        Flickable {
            width: root.contentW
            height: chipRow.implicitHeight
            contentWidth: chipRow.implicitWidth
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Row {
                id: chipRow
                spacing: 6 * root.s
                Repeater {
                    model: root.service ? root.service.groups : ["All"]
                    delegate: Chip {
                        label: modelData
                        on: root.service && root.service.group === modelData
                        s: root.s
                        onPicked: if (root.service) root.service.setGroup(modelData)
                    }
                }
            }
        }

        SearchField {
            id: search
            width: root.contentW
            s: root.s
            kanji: "$"
            placeholder: qsTr("Search emoji…")
            text: root.service ? root.service.query : ""
            onTextChanged: if (root.service) root.service.setQuery(text)
            // arrow keys navigate the grid around the caret; Enter copies/picks
            // the highlighted cell. Everything else still types into the box.
            onMoved: function (delta) { root.moveSel(delta > 0 ? root.cols : -root.cols) }
            onKeyPressed: function (event) {
                if (event.key === Qt.Key_Left) { root.moveSel(-1); event.accepted = true; }
                else if (event.key === Qt.Key_Right) { root.moveSel(1); event.accepted = true; }
            }
            onAccepted: root.pickSel()
        }

        Rectangle {
            width: root.contentW
            height: root.gridH
            radius: Motion.rSmall * 1.4 * root.s
            color: Theme.tileBg
            border.width: 1
            border.color: Theme.border

            GridView {
                id: grid
                anchors.fill: parent
                anchors.margins: root.pad
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                cellWidth: root.cell + root.gap
                cellHeight: root.cell + root.gap
                model: root.service ? root.service.results : []
                currentIndex: root.sel

                delegate: Rectangle {
                    id: cell
                    readonly property bool selected: index === root.sel
                    readonly property bool hot: cellClick.containsMouse || cellClick.pressed
                    width: root.cell
                    height: root.cell
                    radius: Motion.rSmall * root.s
                    color: selected ? Qt.alpha(Theme.brand, 0.22)
                        : (hot ? Qt.alpha(Theme.brand, 0.18) : "transparent")
                    border.width: selected ? 2 * root.s : 1
                    border.color: selected ? Theme.brand : Theme.hair
                    Behavior on color { ColorAnimation { duration: Motion.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.e
                        font.pixelSize: Math.max(15 * root.s, root.cell * 0.58)
                        renderType: Text.QtRendering
                    }

                    // pick action from settings, or force-copy on right-click.
                    // right-click is only taken in the popout (full density);
                    // the desktop tile leaves it to the host's grip menu.
                    MouseArea {
                        id: cellClick
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: root.popout
                            ? (Qt.LeftButton | Qt.RightButton) : Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function (mouse) {
                            if (!root.service) return;
                            if (mouse.button === Qt.RightButton)
                                root.service.copyOnly(modelData.e);
                            else
                                root.service.pick(modelData.e);
                        }
                    }
                }
            }
        }

        MicroLabel {
            visible: root.popout
            label: root.service && root.service.action === "insert"
                ? qsTr("Enter inserts into the focused window · ↑↓ to pick · right-click copies")
                : qsTr("Enter copies to clipboard · ↑↓ to pick · right-click copies")
            s: root.s
        }

        MicroLabel {
            visible: root.service && root.service.loadError !== ""
            label: qsTr("Emoji catalogue: %1").arg(root.service ? root.service.loadError : "")
            s: root.s
        }
    }

    // focus search as soon as the popout opens, so SUPER+. -> type -> Enter.
    onActiveChanged: {
        if (active && root.popout && search.input)
            Qt.callLater(() => search.input.forceActiveFocus())
    }
}