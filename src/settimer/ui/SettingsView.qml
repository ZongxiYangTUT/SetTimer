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
        anchors.margins: 24
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42

            IconButton {
                accessibleName: "返回"
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
                font.pixelSize: 18
                font.weight: Font.DemiBold
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
            contentHeight: settingsColumn.implicitHeight + 34
            contentWidth: width

            Column {
                id: settingsColumn

                spacing: 8
                width: flickable.width

                Item {
                    height: 16
                    width: 1
                }

                Label {
                    color: root.theme.textSecondary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    leftPadding: 4
                    text: "计时"
                }

                Rectangle {
                    border.color: root.theme.border
                    border.width: 1
                    color: root.theme.surface
                    height: timerSettings.implicitHeight
                    radius: root.theme.radiusLarge
                    width: parent.width

                    Column {
                        id: timerSettings

                        leftPadding: 16
                        rightPadding: 16
                        width: parent.width

                        ChoiceSettingRow {
                            iconName: "hourglass"
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
                            iconName: "restart"
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
                            checked: root.appController.countdownEnabled
                            iconName: "bell"
                            label: "最后 3 秒提示"
                            theme: root.theme
                            width: parent.width - parent.leftPadding - parent.rightPadding
                            onToggled: checked => root.appController.setCountdownEnabled(checked)
                        }
                    }
                }

                Item {
                    height: 14
                    width: 1
                }
                Label {
                    color: root.theme.textSecondary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    leftPadding: 4
                    text: "声音"
                }
                Rectangle {
                    border.color: root.theme.border
                    border.width: 1
                    color: root.theme.surface
                    height: audioSettings.implicitHeight
                    radius: root.theme.radiusLarge
                    width: parent.width

                    Column {
                        id: audioSettings

                        leftPadding: 16
                        rightPadding: 16
                        width: parent.width

                        ToggleSettingRow {
                            checked: root.appController.voiceEnabled
                            iconName: "microphone"
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
                        ToggleSettingRow {
                            checked: root.appController.soundEnabled
                            iconName: "volume"
                            label: "提示音"
                            theme: root.theme
                            width: parent.width - parent.leftPadding - parent.rightPadding
                            onToggled: checked => root.appController.setSoundEnabled(checked)
                        }
                    }
                }

                Item {
                    height: 14
                    width: 1
                }
                Label {
                    color: root.theme.textSecondary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    leftPadding: 4
                    text: "外观"
                }
                Rectangle {
                    border.color: root.theme.border
                    border.width: 1
                    color: root.theme.surface
                    height: appearanceSettings.implicitHeight
                    radius: root.theme.radiusLarge
                    width: parent.width

                    Column {
                        id: appearanceSettings

                        leftPadding: 16
                        rightPadding: 16
                        width: parent.width

                        ChoiceSettingRow {
                            iconName: "theme"
                            label: "主题"
                            labels: ["系统", "浅色", "深色"]
                            selected: root.appController.themePreference
                            theme: root.theme
                            values: ["system", "light", "dark"]
                            width: parent.width - parent.leftPadding - parent.rightPadding
                            onChosen: value => root.appController.setTheme(value)
                        }
                        Rectangle {
                            color: root.theme.border
                            height: 1
                            width: parent.width - parent.leftPadding - parent.rightPadding
                        }
                        ToggleSettingRow {
                            checked: root.appController.alwaysOnTop
                            iconName: "pin"
                            label: "窗口始终置顶"
                            theme: root.theme
                            width: parent.width - parent.leftPadding - parent.rightPadding
                            onToggled: checked => root.appController.setAlwaysOnTop(checked)
                        }
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                id: settingsScrollBar

                background: Item {}
                contentItem: Rectangle {
                    color: root.theme.borderStrong
                    implicitWidth: 4
                    opacity: settingsScrollBar.active ? 0.9 : 0.55
                    radius: width / 2
                }
                implicitWidth: 6
                policy: ScrollBar.AsNeeded
            }
        }
    }
}
