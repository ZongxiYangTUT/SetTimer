import QtQuick
import ".."

Item {
    id: root

    required property Theme theme
    required property list<string> labels
    required property list<string> values
    property string iconName: ""
    property string label: ""
    property string selected: ""
    signal chosen(string value)

    implicitHeight: 64

    LineIcon {
        id: rowIcon

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: root.theme.textSecondary
        height: 20
        name: root.iconName
        visible: root.iconName.length > 0
        width: 20
    }

    Text {
        anchors.left: rowIcon.visible ? rowIcon.right : parent.left
        anchors.leftMargin: rowIcon.visible ? 12 : 0
        anchors.right: choice.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: root.theme.text
        elide: Text.ElideRight
        font.pixelSize: 15
        font.weight: Font.Medium
        text: root.label
    }

    ChoiceBar {
        id: choice

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        labels: root.labels
        selected: root.selected
        theme: root.theme
        values: root.values
        onChosen: value => root.chosen(value)
    }
}
