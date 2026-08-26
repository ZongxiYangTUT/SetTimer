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
        anchors.margins: 28
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42

            RowLayout {
                spacing: 10

                Rectangle {
                    color: root.theme.text
                    implicitHeight: 28
                    implicitWidth: 28
                    radius: 9

                    Rectangle {
                        anchors.centerIn: parent
                        border.color: root.theme.accent
                        border.width: 2
                        color: "transparent"
                        height: 13
                        radius: 7
                        width: 13

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: -4
                            color: root.theme.accent
                            height: 3
                            radius: 2
                            width: 7
                        }
                    }
                }

                Label {
                    color: root.theme.text
                    font.pixelSize: 17
                    font.weight: Font.Bold
                    text: "SetTimer"
                }
            }

            Item {
                Layout.fillWidth: true
            }

            RoundButton {
                id: settingsButton

                flat: true
                font.pixelSize: 20
                implicitHeight: 40
                implicitWidth: 40
                text: "⚙"
                onClicked: root.appController.openSettings()

                contentItem: Text {
                    color: root.theme.textSecondary
                    font: settingsButton.font
                    horizontalAlignment: Text.AlignHCenter
                    text: settingsButton.text
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Item {
            Layout.preferredHeight: Math.max(38, root.height * 0.065)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 7

            Label {
                color: root.theme.accent
                font.capitalization: Font.AllUppercase
                font.pixelSize: 13
                font.weight: Font.DemiBold
                text: "今日训练"
            }

            Label {
                Layout.fillWidth: true
                color: root.theme.text
                font.pixelSize: Math.min(34, Math.max(27, root.width * 0.065))
                font.weight: Font.Bold
                text: "准备好，按自己的节奏来。"
                wrapMode: Text.WordWrap
            }

            Label {
                Layout.fillWidth: true
                color: root.theme.textSecondary
                font.pixelSize: 14
                text: "设置一次，接下来的每组交给 SetTimer。"
                wrapMode: Text.WordWrap
            }
        }

        Item {
            Layout.preferredHeight: 27
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: configColumn.implicitHeight
            border.color: root.theme.border
            border.width: 1
            color: root.theme.surface
            radius: root.theme.radiusLarge

            Column {
                id: configColumn

                anchors.left: parent.left
                anchors.right: parent.right

                SettingsRow {
                    label: "训练时间"
                    theme: root.theme
                    transparentBackground: true
                    value: root.appController.workDurationLabel
                    width: parent.width
                    onClicked: {
                        workDialog.durationSeconds = root.appController.workSeconds;
                        workDialog.open();
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.theme.border
                    height: 1
                    width: parent.width - 32
                }

                SettingsRow {
                    label: "休息时间"
                    theme: root.theme
                    transparentBackground: true
                    value: root.appController.restDurationLabel
                    width: parent.width
                    onClicked: {
                        restDialog.durationSeconds = root.appController.restSeconds;
                        restDialog.open();
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.theme.border
                    height: 1
                    width: parent.width - 32
                }

                SettingsRow {
                    label: "训练组数"
                    theme: root.theme
                    transparentBackground: true
                    value: `${root.appController.setCount} 组`
                    width: parent.width
                    onClicked: {
                        setDialog.selectedValue = root.appController.setCount;
                        setDialog.open();
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 23
            spacing: 9

            Rectangle {
                Layout.preferredHeight: 1
                Layout.preferredWidth: 30
                color: root.theme.borderStrong
            }
            Label {
                color: root.theme.textTertiary
                font.pixelSize: 12
                text: root.appController.sessionEstimate
            }
            Label {
                color: root.theme.textTertiary
                font.pixelSize: 11
                text: "•"
            }
            Label {
                color: root.theme.textTertiary
                font.pixelSize: 12
                text: `${root.appController.setCount} 组训练`
            }
            Rectangle {
                Layout.preferredHeight: 1
                Layout.preferredWidth: 30
                color: root.theme.borderStrong
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.minimumHeight: 22
        }

        PrimaryButton {
            Layout.fillWidth: true
            text: "开始训练"
            theme: root.theme
            variant: "primary"
            onClicked: root.appController.startSession()
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            color: root.theme.textTertiary
            font.pixelSize: 11
            text: "按 Space 也可以开始"
        }
    }

    DurationDialog {
        id: workDialog

        allowZero: false
        theme: root.theme
        title: "训练时间"
        onDurationAccepted: seconds => root.appController.setWorkSeconds(seconds)
    }

    DurationDialog {
        id: restDialog

        allowZero: true
        theme: root.theme
        title: "休息时间"
        onDurationAccepted: seconds => root.appController.setRestSeconds(seconds)
    }

    NumberPickerDialog {
        id: setDialog

        theme: root.theme
        onValueAccepted: value => root.appController.setSetCount(value)
    }
}
