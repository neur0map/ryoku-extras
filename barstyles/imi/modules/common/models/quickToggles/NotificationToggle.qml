import QtQuick
import Quickshell
import "../../../.."
import "../../../../services"
import "../.."
import "../../functions"
import "../../widgets"

QuickToggleModel {
    name: Translation.tr("Notifications")
    statusText: toggled ? Translation.tr("Show") : Translation.tr("Silent")
    toggled: !Notifications.silent
    icon: toggled ? "notifications_active" : "notifications_paused"

    mainAction: () => {
        Notifications.silent = !Notifications.silent;
    }

    tooltipText: Translation.tr("Show notifications")
}
