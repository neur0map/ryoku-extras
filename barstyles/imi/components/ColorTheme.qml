pragma Singleton
import QtQuick
import shell.services

QtObject {
    readonly property color primaryColor: Theme.primary ? Theme.primary : "#9ec0db"
    readonly property color onPrimaryColor: Theme.onPrimary ? Theme.onPrimary : "#0b2030"
    readonly property color surfaceBg: Qt.rgba(0.09, 0.12, 0.17, 0.88)
    readonly property color subtextColor: "#8ca0b4"
    readonly property color textLight: "#e2e8f0"
    readonly property color alertCoral: "#f28b82"
}
