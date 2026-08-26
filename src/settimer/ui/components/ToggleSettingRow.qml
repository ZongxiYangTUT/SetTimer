import QtQuick
import ".."

Item {
    id: root

    required property Theme theme
    property string iconName: ""
    property string label: ""
    property string hint: ""
    property bool checked: false
    signal toggled(bool checked)

    implicitHeight: hint.length > 0 ? 72 : 62

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
        id: labelText

        anchors.left: rowIcon.visible ? rowIcon.right : parent.left
        anchors.leftMargin: rowIcon.visible ? 12 : 0
        anchors.right: toggle.left
        anchors.rightMargin: 14
        anchors.top: root.hint.length > 0 ? parent.top : undefined
        anchors.topMargin: root.hint.length > 0 ? 14 : 0
        anchors.verticalCenter: root.hint.length === 0 ? parent.verticalCenter : undefined
        color: root.theme.text
        elide: Text.ElideRight
        font.pixelSize: 15
        font.weight: Font.Medium
        text: root.label
    }

    Text {
        anchors.left: labelText.left
        anchors.right: toggle.left
        anchors.rightMargin: 14
        anchors.top: labelText.bottom
        anchors.topMargin: 3
        color: root.theme.textTertiary
        elide: Text.ElideRight
        font.pixelSize: 11
        text: root.hint
        visible: root.hint.length > 0
    }

    ToggleSwitch {
        id: toggle

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: root.checked
        theme: root.theme
        onClicked: root.toggled(toggle.checked)
    }
}
