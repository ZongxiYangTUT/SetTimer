import QtQuick
import QtQuick.Controls
import ".."

Button {
    id: root

    required property Theme theme
    property string accessibleName: ""
    property color fillColor: theme.surface
    property color iconColor: theme.textSecondary
    property string iconName: ""
    property bool outlined: true

    Accessible.name: accessibleName
    hoverEnabled: true
    implicitHeight: 44
    implicitWidth: 44
    scale: down ? 0.94 : 1.0

    ToolTip.delay: 450
    ToolTip.text: accessibleName
    ToolTip.visible: hovered && accessibleName.length > 0

    contentItem: LineIcon {
        color: root.enabled ? root.iconColor : root.theme.textTertiary
        name: root.iconName
    }

    background: Rectangle {
        border.color: root.outlined ? root.theme.border : "transparent"
        border.width: 1
        color: root.fillColor
        opacity: root.hovered && !root.down ? 0.86 : 1.0
        radius: width / 2

        Behavior on color {
            ColorAnimation {
                duration: root.theme.durationFast
            }
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: root.theme.durationFast
            easing.type: Easing.OutCubic
        }
    }
}
