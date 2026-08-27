import QtQuick
import ".."

Item {
    id: root

    required property Theme theme
    property real progress: 1.0
    property color phaseColor: theme.accent
    property string timeText: "01:00"
    property bool paused: false

    implicitHeight: 340
    implicitWidth: 340
    scale: paused ? 0.975 : 1.0
    opacity: paused ? 0.76 : 1.0

    Canvas {
        id: canvas

        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const context = getContext("2d");
            const center = width / 2;
            const lineWidth = Math.max(5, width * 0.018);
            const radius = center - lineWidth - 4;
            context.reset();
            context.lineWidth = lineWidth;
            context.lineCap = "round";
            context.strokeStyle = root.theme.track;
            context.beginPath();
            context.arc(center, center, radius, 0, Math.PI * 2);
            context.stroke();
            if (root.progress > 0) {
                context.strokeStyle = root.phaseColor;
                context.beginPath();
                context.arc(center, center, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0, Math.min(1, root.progress)));
                context.stroke();
            }
        }
    }

    Text {
        anchors.centerIn: parent
        color: root.theme.text
        font.family: "Consolas"
        font.letterSpacing: -1.5
        font.pixelSize: root.timeText.length <= 2 ? 92 : Math.min(70, root.width * 0.19)
        font.weight: Font.Bold
        horizontalAlignment: Text.AlignHCenter
        text: root.timeText
        width: parent.width - 54
    }

    Behavior on opacity {
        NumberAnimation {
            duration: root.theme.durationNormal
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: root.theme.durationNormal
            easing.type: Easing.OutCubic
        }
    }
    Behavior on progress {
        NumberAnimation {
            duration: 80
        }
    }
    onPhaseColorChanged: canvas.requestPaint()
    onProgressChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
}
