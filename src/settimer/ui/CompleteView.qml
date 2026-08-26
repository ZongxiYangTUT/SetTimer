import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Item {
    id: root

    required property AppBridge appController
    required property Theme theme

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 0

        Item {
            Layout.fillHeight: true
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 124
            Layout.preferredWidth: 124

            Rectangle {
                anchors.fill: parent
                color: root.theme.accentSoft
                radius: width / 2
            }
            Rectangle {
                anchors.centerIn: parent
                color: root.theme.accent
                height: 82
                radius: 41
                width: 82

                LineIcon {
                    anchors.centerIn: parent
                    color: root.theme.accentInk
                    height: 42
                    name: "check"
                    strokeWidth: 2.2
                    width: 42
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 28
            color: root.theme.text
            font.pixelSize: 34
            font.weight: Font.Bold
            text: "训练完成"
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 370
            Layout.preferredHeight: 94
            Layout.topMargin: 34
            border.color: root.theme.border
            border.width: 1
            color: root.theme.surface
            radius: root.theme.radiusLarge

            RowLayout {
                anchors.fill: parent
                anchors.margins: 18

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    LineIcon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 18
                        Layout.preferredWidth: 18
                        color: root.theme.textTertiary
                        name: "sets"
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        color: root.theme.text
                        font.pixelSize: 23
                        font.weight: Font.DemiBold
                        text: root.appController.sessionSetCount
                    }
                }
                Rectangle {
                    Layout.preferredHeight: 38
                    Layout.preferredWidth: 1
                    color: root.theme.borderStrong
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    LineIcon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 18
                        Layout.preferredWidth: 18
                        color: root.theme.textTertiary
                        name: "clock"
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        color: root.theme.text
                        font.pixelSize: 23
                        font.weight: Font.DemiBold
                        text: root.appController.elapsedText
                    }
                }
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 370
            Layout.topMargin: 34
            spacing: 7

            PrimaryButton {
                Layout.fillWidth: true
                iconName: "restart"
                text: "再来一次"
                theme: root.theme
                variant: "primary"
                onClicked: root.appController.startSession()
            }
            PrimaryButton {
                Layout.fillWidth: true
                iconName: "check"
                text: "完成"
                theme: root.theme
                variant: "ghost"
                onClicked: root.appController.completeSession()
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
