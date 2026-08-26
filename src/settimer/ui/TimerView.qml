pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Item {
    id: root

    required property AppBridge appController
    required property Theme theme
    signal fullscreenRequested

    function requestStop(): void {
        stopDialog.open();
    }

    readonly property color phaseColor: theme.phaseColor(appController.phaseKey)

    Rectangle {
        anchors.centerIn: parent
        color: root.appController.phaseKey === "rest" ? root.theme.restSoft : root.theme.accentSoft
        height: Math.min(parent.width, parent.height) * 0.82
        opacity: root.theme.dark ? 0.18 : 0.28
        radius: width / 2
        width: height

        Behavior on color {
            ColorAnimation {
                duration: root.theme.durationSlow
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44

            Column {
                spacing: 6

                Label {
                    color: root.theme.textSecondary
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    text: root.appController.preparing ? "即将开始" : `第 ${root.appController.currentSet} / ${root.appController.sessionSetCount} 组`
                }

                Row {
                    spacing: 4
                    visible: !root.appController.preparing

                    Repeater {
                        model: Math.min(root.appController.sessionSetCount, 12)

                        Rectangle {
                            id: setMarker

                            required property int index

                            color: setMarker.index < root.appController.currentSet ? root.phaseColor : root.theme.track
                            height: 3
                            radius: 2
                            width: 13
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            RoundButton {
                id: fullscreenButton

                flat: false
                font.pixelSize: 12
                implicitHeight: 40
                implicitWidth: 52
                text: "全屏"
                onClicked: root.fullscreenRequested()

                contentItem: Text {
                    color: root.theme.textSecondary
                    font: fullscreenButton.font
                    horizontalAlignment: Text.AlignHCenter
                    text: fullscreenButton.text
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    border.color: root.theme.border
                    border.width: 1
                    color: root.theme.surface
                    radius: root.theme.radiusMedium
                }
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.minimumHeight: 8
        }

        TimerRing {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumHeight: 430
            Layout.maximumWidth: 430
            Layout.preferredHeight: Math.min(360, root.height * 0.52)
            Layout.preferredWidth: Layout.preferredHeight
            detailText: root.appController.phaseDetail
            paused: root.appController.paused
            phaseColor: root.phaseColor
            phaseLabel: root.appController.phaseLabel
            progress: root.appController.progress
            theme: root.theme
            timeText: root.appController.remainingText
        }

        Item {
            Layout.fillHeight: true
            Layout.minimumHeight: 8
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 30
            spacing: 8

            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: mutedLabel.implicitWidth + 16
                border.color: root.theme.border
                border.width: 1
                color: root.theme.surface
                radius: 12
                visible: root.appController.muted

                Label {
                    id: mutedLabel

                    anchors.centerIn: parent
                    color: root.theme.textSecondary
                    font.pixelSize: 11
                    text: "静音"
                }
            }
            Label {
                color: root.theme.textTertiary
                font.pixelSize: 12
                text: "剩余总时间"
            }
            Label {
                color: root.theme.textSecondary
                font.pixelSize: 12
                font.weight: Font.DemiBold
                text: root.appController.totalRemainingText
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 17
            spacing: 12

            PrimaryButton {
                Layout.fillWidth: true
                Layout.preferredWidth: 1.45
                enabled: root.appController.canPause
                fillColor: root.phaseColor
                text: root.appController.resumeCount > 0 ? "取消" : root.appController.paused ? "继续" : "暂停"
                theme: root.theme
                variant: "primary"
                onClicked: root.appController.pauseOrResume()
            }

            PrimaryButton {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: "结束"
                theme: root.theme
                onClicked: stopDialog.open()
            }
        }
    }

    Dialog {
        id: stopDialog

        anchors.centerIn: Overlay.overlay
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        dim: true
        height: 260
        modal: true
        padding: 24
        width: Math.min(380, Overlay.overlay ? Overlay.overlay.width - 40 : 380)

        background: Rectangle {
            border.color: root.theme.border
            border.width: 1
            color: root.theme.surface
            radius: 20
        }

        contentItem: ColumnLayout {
            spacing: 10

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 46
                Layout.preferredWidth: 46
                color: root.theme.dangerSoft
                radius: 23

                Label {
                    anchors.centerIn: parent
                    color: root.theme.danger
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    text: "!"
                }
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                color: root.theme.text
                font.pixelSize: 20
                font.weight: Font.DemiBold
                text: "结束本次训练？"
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                color: root.theme.textSecondary
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                text: "当前进度将不会继续，但训练设置会保留。"
                wrapMode: Text.WordWrap
            }
            Item {
                Layout.fillHeight: true
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                PrimaryButton {
                    Layout.fillWidth: true
                    text: "取消"
                    theme: root.theme
                    onClicked: stopDialog.close()
                }
                PrimaryButton {
                    Layout.fillWidth: true
                    text: "结束训练"
                    theme: root.theme
                    variant: "danger"
                    onClicked: {
                        stopDialog.close();
                        root.appController.stopSession();
                    }
                }
            }
        }
    }
}
