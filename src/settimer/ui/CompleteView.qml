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

                Label {
                    anchors.centerIn: parent
                    color: root.theme.accentInk
                    font.pixelSize: 42
                    font.weight: Font.DemiBold
                    text: "✓"
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 28
            color: root.theme.accent
            font.pixelSize: 13
            font.weight: Font.DemiBold
            text: "做得漂亮"
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            color: root.theme.text
            font.pixelSize: 34
            font.weight: Font.Bold
            text: "训练完成"
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            color: root.theme.textSecondary
            font.pixelSize: 14
            text: "今天的每一组都完成了。"
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
                    spacing: 4

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        color: root.theme.text
                        font.pixelSize: 23
                        font.weight: Font.DemiBold
                        text: root.appController.sessionSetCount
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        color: root.theme.textTertiary
                        font.pixelSize: 11
                        text: "训练组数"
                    }
                }
                Rectangle {
                    Layout.preferredHeight: 38
                    Layout.preferredWidth: 1
                    color: root.theme.borderStrong
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        color: root.theme.text
                        font.pixelSize: 23
                        font.weight: Font.DemiBold
                        text: root.appController.elapsedText
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        color: root.theme.textTertiary
                        font.pixelSize: 11
                        text: "总用时"
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
                text: "再来一次"
                theme: root.theme
                variant: "primary"
                onClicked: root.appController.startSession()
            }
            PrimaryButton {
                Layout.fillWidth: true
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
