import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    property bool uniform: false
    spacing: Appearance.spacing.space50
    uniformCellSizes: uniform
}
