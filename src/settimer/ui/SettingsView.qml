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
        anchors.margins: 22
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 48

            IconButton {
                accessibleName: "返回"
                fillColor: "transparent"
                iconColor: root.theme.text
                iconName: "back"
                implicitHeight: 40
                implicitWidth: 40
                outlined: false
                theme: root.theme
                onClicked: root.appController.closeSettings()
            }
            Label {
                Layout.fillWidth: true
                color: root.theme.text
                font.pixelSize: 20
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                text: "设置"
            }
            Item {
                implicitWidth: 40
            }
        }

        Flickable {
            id: flickable

            Layout.fillHeight: true
            Layout.fillWidth: true
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            contentHeight: settingsColumn.implicitHeight + 26
            contentWidth: width

            Column {
                id: settingsColumn

                spacing: 8
                width: flickable.width

                Item {
                    height: 14
                    width: 1
                }

                Label {
                    color: root.theme.textSecondary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    leftPadding: 2
                    text: "语音播报"
                }

                Rectangle {
                    border.color: root.theme.border
                    border.width: 1
                    color: root.theme.surface
                    height: voiceSettings.implicitHeight
                    radius: 14
                    width: parent.width

                    Column {
                        id: voiceSettings

                        leftPadding: 16
                        rightPadding: 16
                        width: parent.width

                        ToggleSettingRow {
                            checked: root.appController.voiceEnabled
                            label: "语音播报"
                            theme: root.theme
                            width: parent.width - parent.leftPadding - parent.rightPadding
                            onToggled: checked => root.appController.setVoiceEnabled(checked)
                        }
                        Rectangle {
                            color: root.theme.border
                            height: 1
                            width: parent.width - parent.leftPadding - parent.rightPadding
                        }
                        SettingsRow {
                            objectName: "voiceSettingRow"
                            iconName: "volume"
                            label: "播报声音"
                            theme: root.theme
                            transparentBackground: true
                            value: root.appController.voiceName
                            width: parent.width - parent.leftPadding - parent.rightPadding
                            onClicked: voicePicker.open()
                        }
                        Rectangle {
                            color: root.theme.border
                            height: 1
                            width: parent.width - parent.leftPadding - parent.rightPadding
                        }
                        ToggleSettingRow {
                            checked: root.appController.countdownEnabled
                            hint: "阶段结束前提示 3、2、1"
                            label: "结束倒计时"
                            theme: root.theme
                            width: parent.width - parent.leftPadding - parent.rightPadding
                            onToggled: checked => root.appController.setCountdownEnabled(checked)
                        }
                        Rectangle {
                            color: root.theme.border
                            height: 1
                            width: parent.width - parent.leftPadding - parent.rightPadding
                        }
                        ToggleSettingRow {
                            checked: root.appController.soundEnabled
                            label: "提示音"
                            theme: root.theme
                            width: parent.width - parent.leftPadding - parent.rightPadding
                            onToggled: checked => root.appController.setSoundEnabled(checked)
                        }
                    }
                }

                Item {
                    height: 12
                    width: 1
                }
                Label {
                    color: root.theme.textSecondary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    leftPadding: 2
                    text: "计时"
                }
                Rectangle {
                    border.color: root.theme.border
                    border.width: 1
                    color: root.theme.surface
                    height: timerSettings.implicitHeight
                    radius: 14
                    width: parent.width

                    Column {
                        id: timerSettings

                        leftPadding: 16
                        rightPadding: 16
                        width: parent.width

                        ChoiceSettingRow {
                            label: "开始前倒计时"
                            labels: ["关", "3 秒", "5 秒"]
                            selected: root.appController.preparationSeconds.toString()
                            theme: root.theme
                            values: ["0", "3", "5"]
                            width: parent.width - parent.leftPadding - parent.rightPadding
                            onChosen: value => root.appController.setPreparationSeconds(Number(value))
                        }
                        Rectangle {
                            color: root.theme.border
                            height: 1
                            width: parent.width - parent.leftPadding - parent.rightPadding
                        }
                        ToggleSettingRow {
                            checked: root.appController.resumeCountdownEnabled
                            label: "继续前倒计时"
                            theme: root.theme
                            width: parent.width - parent.leftPadding - parent.rightPadding
                            onToggled: checked => root.appController.setResumeCountdownEnabled(checked)
                        }
                        Rectangle {
                            color: root.theme.border
                            height: 1
                            width: parent.width - parent.leftPadding - parent.rightPadding
                        }
                        ToggleSettingRow {
                            checked: root.appController.alwaysOnTop
                            label: "窗口始终置顶"
                            theme: root.theme
                            width: parent.width - parent.leftPadding - parent.rightPadding
                            onToggled: checked => root.appController.setAlwaysOnTop(checked)
                        }
                    }
                }

                Item {
                    height: 12
                    width: 1
                }
                Label {
                    color: root.theme.textSecondary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    leftPadding: 2
                    text: "通用"
                }
                Rectangle {
                    border.color: root.theme.border
                    border.width: 1
                    color: root.theme.surface
                    height: 62
                    radius: 14
                    width: parent.width

                    SettingsRow {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        label: "深色模式"
                        showChevron: false
                        theme: root.theme
                        transparentBackground: true
                        value: "始终开启"
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOff
            }
        }
    }

    VoicePickerDialog {
        id: voicePicker

        objectName: "voicePickerDialog"
        appController: root.appController
        theme: root.theme
    }
}
