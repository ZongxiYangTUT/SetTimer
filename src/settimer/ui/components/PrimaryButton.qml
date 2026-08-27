import QtQuick
import QtQuick.Controls
import ".."

Button {
    id: root

    required property Theme theme
    property string iconName: ""
    property real iconSize: 18
    property string variant: "secondary"
    property color fillColor: {
        if (variant === "primary")
            return theme.accent;
        if (variant === "inverted")
            return theme.text;
        if (variant === "danger")
            return theme.dangerSoft;
        if (variant === "ghost")
            return "transparent";
        return theme.surfaceStrong;
    }
    property color labelColor: {
        if (variant === "primary")
            return theme.accentInk;
        if (variant === "inverted")
            return theme.background;
        if (variant === "danger")
            return theme.danger;
        return theme.text;
    }

    implicitHeight: 50
    hoverEnabled: true
    scale: down ? 0.97 : 1.0

    contentItem: Item {
        Row {
            anchors.centerIn: parent
            spacing: root.iconName.length > 0 && root.text.length > 0 ? 8 : 0

            LineIcon {
                color: root.enabled ? root.labelColor : root.theme.textTertiary
                height: root.iconSize
                name: root.iconName
                visible: root.iconName.length > 0
                width: root.iconSize
            }

            Text {
                color: root.enabled ? root.labelColor : root.theme.textTertiary
                font.pixelSize: 14
                font.weight: Font.DemiBold
                text: root.text
                visible: root.text.length > 0
            }
        }
    }

    background: Rectangle {
        border.color: root.variant === "secondary" ? root.theme.border : "transparent"
        border.width: 1
        color: root.enabled ? root.fillColor : root.theme.backgroundSoft
        opacity: root.hovered && !root.down ? 0.92 : 1.0
        radius: height / 2

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
