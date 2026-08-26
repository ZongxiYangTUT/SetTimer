import QtQuick
import QtQuick.Controls
import ".."

AbstractButton {
    id: root

    required property Theme theme
    property string iconName: ""
    property string label: ""
    property string hint: ""
    property string value: ""
    property bool showChevron: true
    property bool transparentBackground: false

    implicitHeight: hint.length > 0 ? 70 : 62
    hoverEnabled: true

    contentItem: Item {
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
            anchors.right: valueText.left
            anchors.top: root.hint.length > 0 ? parent.top : undefined
            anchors.verticalCenter: root.hint.length === 0 ? parent.verticalCenter : undefined
            anchors.topMargin: root.hint.length > 0 ? 13 : 0
            color: root.theme.text
            elide: Text.ElideRight
            font.pixelSize: 15
            font.weight: Font.Medium
            text: root.label
        }

        Text {
            anchors.left: labelText.left
            anchors.right: valueText.left
            anchors.top: labelText.bottom
            anchors.topMargin: 3
            color: root.theme.textTertiary
            elide: Text.ElideRight
            font.pixelSize: 11
            text: root.hint
            visible: root.hint.length > 0
        }

        Text {
            id: valueText

            anchors.right: chevron.left
            anchors.rightMargin: root.showChevron ? 7 : 0
            anchors.verticalCenter: parent.verticalCenter
            color: root.theme.textSecondary
            font.pixelSize: 14
            text: root.value
        }

        Text {
            id: chevron

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: root.theme.textTertiary
            font.pixelSize: 20
            text: "›"
            visible: root.showChevron
        }
    }

    background: Rectangle {
        color: root.transparentBackground ? "transparent" : root.theme.surface
        opacity: root.hovered ? 0.86 : 1.0
        radius: root.theme.radiusLarge
    }
}
