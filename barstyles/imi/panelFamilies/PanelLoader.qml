import QtQuick
import Quickshell

import "../modules/common"

LazyLoader {
    property bool extraCondition: true
    active: Config.ready && extraCondition
}
