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

            IconButton {
                accessibleName: "设置"
                iconName: "settings"
                outlined: false
                theme: root.theme
                onClicked: root.appController.openSettings()
            }
        }

        Item {
            Layout.preferredHeight: Math.max(42, root.height * 0.08)
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            LineIcon {
                Layout.preferredHeight: 28
                Layout.preferredWidth: 28
                color: root.theme.accent
                name: "activity"
            }
            Label {
                color: root.theme.text
                font.pixelSize: Math.min(32, Math.max(26, root.width * 0.06))
                font.weight: Font.Bold
                text: "训练计划"
            }
        }

        Item {
            Layout.preferredHeight: 30
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
                    iconName: "activity"
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
                    iconName: "rest"
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
                    iconName: "sets"
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
            LineIcon {
                Layout.preferredHeight: 16
                Layout.preferredWidth: 16
                color: root.theme.textTertiary
                name: "clock"
            }
            Label {
                color: root.theme.textTertiary
                font.pixelSize: 12
                text: root.appController.sessionEstimate
            }
            Rectangle {
                Layout.preferredHeight: 14
                Layout.preferredWidth: 1
                color: root.theme.borderStrong
            }
            LineIcon {
                Layout.preferredHeight: 16
                Layout.preferredWidth: 16
                color: root.theme.textTertiary
                name: "sets"
            }
            Label {
                color: root.theme.textTertiary
                font.pixelSize: 12
                text: `${root.appController.setCount} 组`
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
            iconName: "play"
            text: "开始"
            theme: root.theme
            variant: "primary"
            onClicked: root.appController.startSession()
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
