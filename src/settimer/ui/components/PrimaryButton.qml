import QtQuick
import QtQuick.Controls
import ".."

Button {
    id: root

    required property Theme theme
    property string variant: "secondary"
    property color fillColor: {
        if (variant === "primary")
            return theme.accent;
        if (variant === "danger")
            return theme.dangerSoft;
        if (variant === "ghost")
            return "transparent";
        return theme.surfaceStrong;
    }
    property color labelColor: {
        if (variant === "primary")
            return theme.accentInk;
        if (variant === "danger")
            return theme.danger;
        return theme.text;
    }

    implicitHeight: 50
    hoverEnabled: true
    scale: down ? 0.97 : 1.0

    contentItem: Text {
        color: root.enabled ? root.labelColor : root.theme.textTertiary
        elide: Text.ElideRight
        font.pixelSize: 14
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        text: root.text
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        border.color: root.variant === "secondary" ? root.theme.border : "transparent"
        border.width: 1
        color: root.enabled ? root.fillColor : root.theme.backgroundSoft
        opacity: root.hovered && !root.down ? 0.92 : 1.0
        radius: root.theme.radiusMedium

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
