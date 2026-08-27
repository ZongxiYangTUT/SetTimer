import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Item {
    id: root

    required property AppBridge appController
    required property Theme theme

    function clockText(seconds: int): string {
        const normalized = Math.max(0, seconds);
        const minutes = Math.floor(normalized / 60);
        const finalSeconds = normalized % 60;
        return `${minutes.toString().padStart(2, "0")}:${finalSeconds.toString().padStart(2, "0")}`;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 0

        Item {
            Layout.preferredHeight: 58
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 62
            Layout.preferredWidth: 62
            border.color: root.theme.accent
            border.width: 3
            color: "transparent"
            radius: width / 2

            LineIcon {
                anchors.centerIn: parent
                color: root.theme.accent
                height: 30
                name: "check"
                strokeWidth: 2.2
                width: 30
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            color: root.theme.text
            font.pixelSize: 28
            font.weight: Font.Bold
            text: "训练完成!"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: statsColumn.implicitHeight + 28
            Layout.topMargin: 28
            border.color: root.theme.border
            border.width: 1
            color: root.theme.surface
            radius: 12

            Column {
                id: statsColumn

                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                StatRow {
                    label: "总时长"
                    theme: root.theme
                    value: root.appController.elapsedText
                    width: parent.width
                }
                StatRow {
                    label: "训练时间"
                    theme: root.theme
                    value: root.clockText(root.appController.workSeconds * root.appController.sessionSetCount)
                    width: parent.width
                }
                StatRow {
                    label: "休息时间"
                    theme: root.theme
                    value: root.clockText(root.appController.restSeconds * Math.max(0, root.appController.sessionSetCount - 1))
                    width: parent.width
                }
                StatRow {
                    accentValue: true
                    label: "完成组数"
                    showDivider: false
                    theme: root.theme
                    value: `${root.appController.sessionSetCount} / ${root.appController.sessionSetCount}`
                    width: parent.width
                }
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.minimumHeight: 30
        }

        PrimaryButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            text: "再来一次 (REPEAT)"
            theme: root.theme
            variant: "inverted"
            onClicked: root.appController.startSession()
        }

        PrimaryButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 42
            Layout.preferredWidth: 160
            text: "返回主页 (BACK)"
            theme: root.theme
            variant: "ghost"
            onClicked: root.appController.completeSession()
        }
    }
}
