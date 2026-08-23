pragma ComponentBehavior: Bound

import QtQuick
import shell.barkit as Pill
import shell.services
import "../components" as C
import "../popouts" as Popouts
import "../shared" as S

Item {
    id: root

    readonly property string temp: Weather.available && Weather.temp.length > 0 ? Weather.temp : "16°C"

    implicitHeight: 22
    implicitWidth: row.implicitWidth
    height: 22
    width: implicitWidth

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.temp
            color: C.ColorTheme.textLight
            font.family: Theme.mono
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Pill.MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "dark_mode"
            color: C.ColorTheme.primaryColor
            font.pixelSize: 14
        }
    }

    HoverHandler { id: hover }

    S.Popout {
        target: root
        targetHovered: hover.hovered
        namespace: "ryoku-imi-popout"
        content: Component { Popouts.WeatherPopout {} }
    }
}
