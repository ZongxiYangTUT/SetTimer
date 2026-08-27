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

    function steppedClock(seconds: int, offset: int, step: int, minimum: int): string {
        return clockText(Math.max(minimum, seconds + offset * step));
    }

    function steppedSets(offset: int): string {
        return Math.max(1, root.appController.setCount + offset).toString();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 26
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42

            Label {
                color: root.theme.text
                font.pixelSize: 16
                font.weight: Font.Bold
                text: "SETTIMER"
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                Accessible.name: "打开设置"
                Layout.preferredHeight: 22
                Layout.preferredWidth: intervalLabel.implicitWidth + 18
                hoverEnabled: true

                contentItem: Label {
                    id: intervalLabel

                    color: root.theme.textSecondary
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    text: "INTERVALS"
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: root.theme.surface
                    radius: 5
                }
                onClicked: root.appController.openSettings()
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
                label: "组数 (SETS)"
                nextOne: root.steppedSets(1)
                nextTwo: root.steppedSets(2)
                previousOne: root.steppedSets(-1)
                previousTwo: root.steppedSets(-2)
                theme: root.theme
                value: root.steppedSets(0)
                onClicked: {
                    setDialog.selectedValue = root.appController.setCount;
                    setDialog.open();
                }
            }

            PlanPickerColumn {
                Layout.fillWidth: true
                label: "训练 (WORK)"
                nextOne: root.steppedClock(root.appController.workSeconds, 1, 30, 1)
                nextTwo: root.steppedClock(root.appController.workSeconds, 2, 30, 1)
                previousOne: root.steppedClock(root.appController.workSeconds, -1, 30, 1)
                previousTwo: root.steppedClock(root.appController.workSeconds, -2, 30, 1)
                theme: root.theme
                value: root.clockText(root.appController.workSeconds)
                onClicked: {
                    workDialog.durationSeconds = root.appController.workSeconds;
                    workDialog.open();
                }
            }

            PlanPickerColumn {
                Layout.fillWidth: true
                label: "休息 (REST)"
                nextOne: root.steppedClock(root.appController.restSeconds, 1, 15, 0)
                nextTwo: root.steppedClock(root.appController.restSeconds, 2, 15, 0)
                previousOne: root.steppedClock(root.appController.restSeconds, -1, 15, 0)
                previousTwo: root.steppedClock(root.appController.restSeconds, -2, 15, 0)
                theme: root.theme
                value: root.clockText(root.appController.restSeconds)
                onClicked: {
                    restDialog.durationSeconds = root.appController.restSeconds;
                    restDialog.open();
                }
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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 54
            Layout.topMargin: 12
            color: root.theme.surface
            radius: 10

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 12
                spacing: 10

                LineIcon {
                    Layout.preferredHeight: 20
                    Layout.preferredWidth: 20
                    color: root.theme.textSecondary
                    name: "microphone"
                }
                Label {
                    Layout.fillWidth: true
                    color: root.theme.text
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    text: "语音播报 (VOICE)"
                }
                ToggleSwitch {
                    checked: root.appController.voiceEnabled
                    theme: root.theme
                    onClicked: root.appController.setVoiceEnabled(checked)
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
            text: "开始 (START)"
            theme: root.theme
            variant: "inverted"
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
