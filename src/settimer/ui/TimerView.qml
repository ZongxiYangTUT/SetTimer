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
    readonly property string phaseIcon: {
        if (appController.resumeCount > 0)
            return "play";
        if (appController.paused)
            return "pause";
        if (appController.preparing)
            return "hourglass";
        return appController.phaseKey === "rest" ? "rest" : "activity";
    }

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

            RowLayout {
                spacing: 8

                IconButton {
                    accessibleName: root.appController.muted ? "恢复声音" : "静音"
                    fillColor: root.appController.muted ? root.theme.accentSoft : root.theme.surface
                    iconColor: root.appController.muted ? root.theme.accent : root.theme.textSecondary
                    iconName: root.appController.muted ? "volume-off" : "volume"
                    implicitHeight: 40
                    implicitWidth: 40
                    theme: root.theme
                    onClicked: root.appController.toggleMuted()
                }

                IconButton {
                    accessibleName: "全屏"
                    iconName: "expand"
                    implicitHeight: 40
                    implicitWidth: 40
                    theme: root.theme
                    onClicked: root.fullscreenRequested()
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
            iconName: root.phaseIcon
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
            spacing: 7

            LineIcon {
                Layout.preferredHeight: 16
                Layout.preferredWidth: 16
                color: root.theme.textTertiary
                name: "clock"
            }
            Label {
                color: root.theme.textSecondary
                font.pixelSize: 12
                font.weight: Font.DemiBold
                text: root.appController.totalRemainingText
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 17
            spacing: 18

            IconButton {
                accessibleName: root.appController.resumeCount > 0 ? "取消继续" : root.appController.paused ? "继续" : "暂停"
                enabled: root.appController.canPause
                fillColor: root.phaseColor
                iconColor: root.theme.accentInk
                iconName: root.appController.resumeCount > 0 ? "close" : root.appController.paused ? "play" : "pause"
                implicitHeight: 68
                implicitWidth: 68
                outlined: false
                theme: root.theme
                onClicked: root.appController.pauseOrResume()
            }

            IconButton {
                accessibleName: "结束训练"
                fillColor: root.theme.surface
                iconColor: root.theme.danger
                iconName: "stop"
                implicitHeight: 54
                implicitWidth: 54
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
        height: 232
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

                LineIcon {
                    anchors.centerIn: parent
                    color: root.theme.danger
                    height: 24
                    name: "stop"
                    width: 24
                }
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                color: root.theme.text
                font.pixelSize: 20
                font.weight: Font.DemiBold
                text: "结束本次训练？"
            }
            Item {
                Layout.fillHeight: true
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                PrimaryButton {
                    Layout.fillWidth: true
                    iconName: "close"
                    text: "取消"
                    theme: root.theme
                    onClicked: stopDialog.close()
                }
                PrimaryButton {
                    Layout.fillWidth: true
                    iconName: "stop"
                    text: "结束"
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
