import QtQuick
import QtQuick.Controls
import ".."

AbstractButton {
    id: root

    required property Theme theme
    property string accessibleName: ""
    property color fillColor: theme.surface
    property int holdDuration: 900
    property real holdProgress: 0.0
    property color iconColor: theme.text
    property string iconName: "stop"
    signal held

    property bool completed: false

    Accessible.description: "长按操作"
    Accessible.name: accessibleName
    hoverEnabled: true
    implicitHeight: 58
    implicitWidth: 58
    scale: down ? 0.95 : 1.0

    ToolTip.delay: 450
    ToolTip.text: accessibleName
    ToolTip.visible: hovered && accessibleName.length > 0

    contentItem: LineIcon {
        color: root.iconColor
        name: root.iconName
    }

    background: Item {
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            color: root.fillColor
            radius: width / 2
        }

        Canvas {
            id: progressCanvas

            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const context = getContext("2d");
                const center = width / 2;
                const lineWidth = 3;
                const radius = center - lineWidth;
                context.reset();
                context.clearRect(0, 0, width, height);
                if (root.holdProgress <= 0)
                    return;
                context.lineWidth = lineWidth;
                context.lineCap = "round";
                context.strokeStyle = root.theme.danger;
                context.beginPath();
                context.arc(center, center, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * root.holdProgress);
                context.stroke();
            }
        }
    }

    onCanceled: resetHold()
    onPressed: {
        completed = false;
        holdProgress = 0;
        holdAnimation.restart();
    }
    onReleased: resetHold()

    function resetHold(): void {
        holdAnimation.stop();
        if (!completed)
            holdProgress = 0;
    }

    NumberAnimation {
        id: holdAnimation

        duration: root.holdDuration
        from: 0
        property: "holdProgress"
        target: root
        to: 1
        onFinished: {
            if (root.down) {
                root.completed = true;
                root.held();
                root.holdProgress = 0;
            }
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: root.theme.durationFast
            easing.type: Easing.OutCubic
        }
    }

    onHoldProgressChanged: progressCanvas.requestPaint()
}
