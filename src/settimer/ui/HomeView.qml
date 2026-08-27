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
        anchors.margins: 26
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 2

                IconButton {
                    accessibleName: "历史记录"
                    fillColor: "transparent"
                    iconColor: root.theme.textSecondary
                    iconName: "history-rounded"
                    implicitHeight: 36
                    implicitWidth: 36
                    outlined: false
                    theme: root.theme
                    onClicked: root.appController.openHistory()
                }
                IconButton {
                    accessibleName: "设置"
                    fillColor: "transparent"
                    iconColor: root.theme.textSecondary
                    iconName: "settings-sharp"
                    implicitHeight: 36
                    implicitWidth: 36
                    outlined: false
                    theme: root.theme
                    onClicked: root.appController.openSettings()
                }
            }
        }

        Item {
            Layout.preferredHeight: 18
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 164
            spacing: 8

            PlanPickerColumn {
                Layout.fillWidth: true
                itemCount: 99
                label: "组数"
                mode: "sets"
                objectName: "setPicker"
                selectedIndex: root.appController.setCount - 1
                theme: root.theme
                onValueSelected: value => root.appController.setSetCount(value)
            }

            PlanPickerColumn {
                Layout.fillWidth: true
                itemCount: Math.floor((3599 - startSeconds) / stepSeconds) + 1
                label: "训练"
                objectName: "workPicker"
                selectedIndex: Math.floor((root.appController.workSeconds - startSeconds) / stepSeconds)
                startSeconds: root.appController.workSeconds % stepSeconds === 0 ? stepSeconds : root.appController.workSeconds % stepSeconds
                stepSeconds: 30
                theme: root.theme
                onValueSelected: value => root.appController.setWorkSeconds(value)
            }

            PlanPickerColumn {
                Layout.fillWidth: true
                itemCount: Math.floor((3599 - startSeconds) / stepSeconds) + 1
                label: "休息"
                objectName: "restPicker"
                selectedIndex: Math.floor((root.appController.restSeconds - startSeconds) / stepSeconds)
                startSeconds: root.appController.restSeconds % stepSeconds
                stepSeconds: 15
                theme: root.theme
                onValueSelected: value => root.appController.setRestSeconds(value)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 66
            Layout.topMargin: 22
            color: root.theme.surface
            radius: 10

            Column {
                anchors.centerIn: parent
                spacing: 4

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.theme.text
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    text: `${root.appController.setCount} 组 × ${root.clockText(root.appController.workSeconds)} 训练 + ${root.clockText(root.appController.restSeconds)} 休息`
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.theme.accent
                    font.pixelSize: 11
                    text: `总计 ${root.appController.sessionEstimate}`
                }
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.minimumHeight: 24
        }

        PrimaryButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            text: "开始"
            theme: root.theme
            variant: "inverted"
            onClicked: root.appController.startSession()
        }
    }
}
