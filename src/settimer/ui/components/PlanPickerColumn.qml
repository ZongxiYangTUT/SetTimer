pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import ".."

AbstractButton {
    id: root

    required property Theme theme
    property string label: ""
    property string previousTwo: ""
    property string previousOne: ""
    property string value: ""
    property string nextOne: ""
    property string nextTwo: ""

    Accessible.name: `${label}，当前 ${value}`
    hoverEnabled: true
    implicitHeight: 164
    scale: down ? 0.985 : 1.0

    contentItem: Item {
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            color: root.theme.textSecondary
            font.pixelSize: 11
            font.weight: Font.Medium
            text: root.label
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: values.verticalCenter
            color: root.theme.surfaceStrong
            height: 34
            radius: 6
            width: parent.width - 12
        }

        Column {
            id: values

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 30
            width: parent.width

            Repeater {
                model: 5

                Text {
                    required property int index

                    color: index === 2 ? root.theme.text : root.theme.textTertiary
                    font.family: "Consolas"
                    font.pixelSize: index === 2 ? 20 : 13
                    font.weight: index === 2 ? Font.Bold : Font.Normal
                    height: 25
                    horizontalAlignment: Text.AlignHCenter
                    opacity: index === 2 ? 1.0 : (index === 1 || index === 3 ? 0.78 : 0.42)
                    text: [root.previousTwo, root.previousOne, root.value, root.nextOne, root.nextTwo][index]
                    verticalAlignment: Text.AlignVCenter
                    width: values.width
                }
            }
        }
    }

    background: Rectangle {
        border.color: root.hovered ? root.theme.borderStrong : root.theme.border
        border.width: 1
        color: root.theme.backgroundSoft
        radius: 9
    }

    Behavior on scale {
        NumberAnimation {
            duration: root.theme.durationFast
            easing.type: Easing.OutCubic
        }
    }
}
