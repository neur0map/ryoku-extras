pragma ComponentBehavior: Bound

import QtQuick
import shell.services

Rectangle {
    id: root

    default property alias data: contentRow.data
    property alias spacing: contentRow.spacing
    property real pillHeight: 30
    property real pillRadius: 15
    property string tone: "surface" // surface, primary, dark

    readonly property color toneBg: {
        switch (root.tone) {
        case "primary": return ColorTheme.primaryColor;
        case "dark": return Qt.rgba(0.07, 0.10, 0.14, 0.88);
        default: return Qt.rgba(0.09, 0.12, 0.17, 0.88);
        }
    }

    readonly property color toneBorder: {
        if (root.tone === "primary") return ColorTheme.primaryColor;
        return Qt.rgba(255, 255, 255, 0.08);
    }

    implicitHeight: pillHeight
    implicitWidth: contentRow.implicitWidth + (root.tone === "primary" ? 18 : 16)
    height: pillHeight
    width: implicitWidth
    radius: pillRadius
    color: toneBg
    border.width: 1
    border.color: toneBorder

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6
    }
}
