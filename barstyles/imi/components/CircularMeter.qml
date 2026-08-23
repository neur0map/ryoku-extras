pragma ComponentBehavior: Bound

import QtQuick
import shell.barkit as Pill
import shell.services

Item {
    id: root

    property real value: 0.35 // 0.0 to 1.0
    property string icon: ""
    property color trackColor: Qt.rgba(1, 1, 1, 0.12)
    property color progressColor: ColorTheme.primaryColor
    property color iconColor: "#8ca0b4"
    property real lineWidth: 1.8

    implicitWidth: 18
    implicitHeight: 18
    height: 18
    width: 18

    onValueChanged: canvas.requestPaint()
    onProgressColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            const ctx = canvas.getContext("2d");
            ctx.reset();
            const w = canvas.width;
            const h = canvas.height;
            const cx = w / 2;
            const cy = h / 2;
            const radius = (Math.min(w, h) - root.lineWidth) / 2;

            // Background track
            ctx.beginPath();
            ctx.arc(cx, cy, radius, 0, 2 * Math.PI);
            ctx.strokeStyle = root.trackColor;
            ctx.lineWidth = root.lineWidth;
            ctx.stroke();

            // Progress arc
            if (root.value > 0.01) {
                const startAngle = -0.5 * Math.PI;
                const sweep = Math.min(1.0, Math.max(0.0, root.value)) * 2 * Math.PI;
                ctx.beginPath();
                ctx.arc(cx, cy, radius, startAngle, startAngle + sweep);
                ctx.strokeStyle = root.progressColor;
                ctx.lineWidth = root.lineWidth;
                ctx.lineCap = "round";
                ctx.stroke();
            }
        }
    }

    Pill.MaterialIcon {
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: 9
        color: root.iconColor
    }
}
