pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Dialog {
    id: root

    required property Theme theme
    property int selectedValue: 5
    signal valueAccepted(int value)

    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    dim: true
    height: 350
    modal: true
    padding: 22
    title: "训练组数"
    width: Math.min(380, Overlay.overlay ? Overlay.overlay.width - 36 : 380)

    onOpened: valueTumbler.currentIndex = Math.max(0, selectedValue - 1)

    background: Rectangle {
        border.color: root.theme.border
        border.width: 1
        color: root.theme.surface
        radius: root.theme.radiusXLarge
    }

    contentItem: ColumnLayout {
        spacing: 12

        Label {
            Layout.alignment: Qt.AlignHCenter
            color: root.theme.text
            font.pixelSize: 17
            font.weight: Font.DemiBold
            text: root.title
        }

        Tumbler {
            id: valueTumbler

            Layout.fillHeight: true
            Layout.fillWidth: true
            model: 99
            visibleItemCount: 5

            delegate: Text {
                required property int index
                required property int modelData

                color: root.theme.text
                font.pixelSize: 22
                font.weight: Tumbler.displacement === 0 ? Font.DemiBold : Font.Normal
                horizontalAlignment: Text.AlignHCenter
                opacity: 1.0 - Math.min(0.72, Math.abs(Tumbler.displacement) * 0.32)
                text: `${modelData + 1} 组`
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                anchors.centerIn: parent
                border.color: root.theme.border
                border.width: 1
                color: root.theme.backgroundSoft
                height: 48
                radius: root.theme.radiusMedium
                width: Math.min(180, parent.width)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            PrimaryButton {
                Layout.fillWidth: true
                text: "取消"
                theme: root.theme
                onClicked: root.close()
            }

            PrimaryButton {
                Layout.fillWidth: true
                text: "完成"
                theme: root.theme
                variant: "primary"
                onClicked: {
                    root.valueAccepted(valueTumbler.currentIndex + 1);
                    root.close();
                }
            }
        }
    }
}
