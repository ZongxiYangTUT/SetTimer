pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Dialog {
    id: root

    required property Theme theme
    property int durationSeconds: 60
    property bool allowZero: false
    signal durationAccepted(int seconds)

    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    dim: true
    height: 360
    modal: true
    padding: 22
    width: Math.min(420, Overlay.overlay ? Overlay.overlay.width - 36 : 420)

    onOpened: {
        minutes.currentIndex = Math.floor(durationSeconds / 60);
        seconds.currentIndex = durationSeconds % 60;
    }

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

        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.margins: 4
            spacing: 12

            Tumbler {
                id: minutes

                Layout.fillHeight: true
                Layout.fillWidth: true
                model: 60
                visibleItemCount: 5

                delegate: Text {
                    required property int index
                    required property int modelData

                    color: root.theme.text
                    font.pixelSize: 22
                    font.weight: Tumbler.displacement === 0 ? Font.DemiBold : Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 1.0 - Math.min(0.72, Math.abs(Tumbler.displacement) * 0.32)
                    text: modelData.toString().padStart(2, "0")
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    anchors.centerIn: parent
                    border.color: root.theme.border
                    border.width: 1
                    color: root.theme.backgroundSoft
                    height: 48
                    radius: root.theme.radiusMedium
                    width: parent.width
                }
            }

            Label {
                color: root.theme.text
                font.pixelSize: 24
                font.weight: Font.DemiBold
                text: ":"
            }

            Tumbler {
                id: seconds

                Layout.fillHeight: true
                Layout.fillWidth: true
                model: 60
                visibleItemCount: 5

                delegate: Text {
                    required property int index
                    required property int modelData

                    color: root.theme.text
                    font.pixelSize: 22
                    font.weight: Tumbler.displacement === 0 ? Font.DemiBold : Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 1.0 - Math.min(0.72, Math.abs(Tumbler.displacement) * 0.32)
                    text: modelData.toString().padStart(2, "0")
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    anchors.centerIn: parent
                    border.color: root.theme.border
                    border.width: 1
                    color: root.theme.backgroundSoft
                    height: 48
                    radius: root.theme.radiusMedium
                    width: parent.width
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            color: root.theme.danger
            font.pixelSize: 11
            text: "训练时间至少为 1 秒"
            visible: !root.allowZero && minutes.currentIndex === 0 && seconds.currentIndex === 0
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
                readonly property int selectedSeconds: minutes.currentIndex * 60 + seconds.currentIndex

                Layout.fillWidth: true
                enabled: root.allowZero || selectedSeconds > 0
                text: "完成"
                theme: root.theme
                variant: "primary"
                onClicked: {
                    root.durationAccepted(selectedSeconds);
                    root.close();
                }
            }
        }
    }
}
