import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Item {
    id: root

    required property Theme theme
    property string label: ""
    property string value: ""
    property bool accentValue: false
    property bool showDivider: true

    implicitHeight: 46

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Label {
            Layout.fillWidth: true
            color: root.theme.textSecondary
            font.pixelSize: 12
            text: root.label
        }
        Label {
            color: root.accentValue ? root.theme.accent : root.theme.text
            font.family: "Consolas"
            font.pixelSize: 13
            font.weight: Font.Bold
            text: root.value
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        color: root.theme.border
        height: 1
        visible: root.showDivider
        width: parent.width
    }
}
