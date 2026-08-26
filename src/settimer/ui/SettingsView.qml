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

            RoundButton {
                id: backButton

                flat: true
                font.pixelSize: 26
                implicitHeight: 40
                implicitWidth: 40
                text: "‹"
                onClicked: root.appController.closeSettings()

                contentItem: Text {
                    color: root.theme.textSecondary
                    font: backButton.font
                    horizontalAlignment: Text.AlignHCenter
                    text: backButton.text
                    verticalAlignment: Text.AlignVCenter
                }
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
                            hint: "继续前给你 3 秒重新就位"
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
                            hint: "训练中用中文播报阶段"
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
                            hint: "适合边看视频边训练"
                            label: "窗口始终置顶"
                            theme: root.theme
                            width: parent.width - parent.leftPadding - parent.rightPadding
                            onToggled: checked => root.appController.setAlwaysOnTop(checked)
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
                    text: "快捷键"
                }
                Rectangle {
                    border.color: root.theme.border
                    border.width: 1
                    color: root.theme.surface
                    height: shortcuts.implicitHeight + 28
                    radius: root.theme.radiusLarge
                    width: parent.width

                    GridLayout {
                        id: shortcuts

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        columns: 2
                        columnSpacing: 18
                        rowSpacing: 10

                        Label {
                            color: root.theme.textSecondary
                            text: "开始 / 暂停 / 继续"
                        }
                        Label {
                            Layout.alignment: Qt.AlignRight
                            color: root.theme.textTertiary
                            text: "Space"
                        }
                        Label {
                            color: root.theme.textSecondary
                            text: "全屏"
                        }
                        Label {
                            Layout.alignment: Qt.AlignRight
                            color: root.theme.textTertiary
                            text: "F"
                        }
                        Label {
                            color: root.theme.textSecondary
                            text: "静音"
                        }
                        Label {
                            Layout.alignment: Qt.AlignRight
                            color: root.theme.textTertiary
                            text: "M"
                        }
                        Label {
                            color: root.theme.textSecondary
                            text: "返回 / 取消"
                        }
                        Label {
                            Layout.alignment: Qt.AlignRight
                            color: root.theme.textTertiary
                            text: "Esc"
                        }
                    }
                }

                Label {
                    color: root.theme.textTertiary
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    text: "SetTimer 0.1.0 · 为按组训练而设计"
                    width: parent.width
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
    }
}
