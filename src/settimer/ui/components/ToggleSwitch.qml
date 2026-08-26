import QtQuick
import QtQuick.Controls
import ".."

AbstractButton {
    id: root

    required property Theme theme

    checkable: true
    implicitHeight: 28
    implicitWidth: 46
    scale: down ? 0.96 : 1.0

    background: Rectangle {
        border.color: root.checked ? "transparent" : root.theme.border
        border.width: 1
        color: root.checked ? root.theme.accent : root.theme.track
        radius: height / 2

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            color: "#ffffff"
            height: 20
            radius: 10
            width: 20
            x: root.checked ? parent.width - width - 4 : 4

            Behavior on x {
                NumberAnimation {
                    duration: root.theme.durationNormal
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: root.theme.durationNormal
            }
        }
    }
}
