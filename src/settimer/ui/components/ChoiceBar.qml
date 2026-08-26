pragma ComponentBehavior: Bound

import QtQuick
import ".."

Item {
    id: root

    required property Theme theme
    required property list<string> labels
    required property list<string> values
    property string selected: ""
    signal chosen(string value)

    implicitHeight: 34
    implicitWidth: choiceRow.implicitWidth + 6

    Rectangle {
        anchors.fill: parent
        border.color: root.theme.border
        border.width: 1
        color: root.theme.backgroundSoft
        radius: 9
    }

    Row {
        id: choiceRow

        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.values.length

            Rectangle {
                id: option

                required property int index

                color: root.values[option.index] === root.selected ? root.theme.surfaceStrong : "transparent"
                height: 28
                radius: 7
                width: optionLabel.implicitWidth + 18

                Text {
                    id: optionLabel

                    anchors.centerIn: parent
                    color: root.values[option.index] === root.selected ? root.theme.text : root.theme.textSecondary
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    text: root.labels[option.index]
                }

                TapHandler {
                    onTapped: root.chosen(root.values[option.index])
                }
            }
        }
    }
}
