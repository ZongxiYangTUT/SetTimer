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

    readonly property bool pausedState: appController.paused || appController.resumeCount > 0
    readonly property color phaseColor: pausedState ? theme.pause : theme.phaseColor(appController.phaseKey)
    readonly property color phaseSoftColor: pausedState ? theme.pauseSoft : (appController.phaseKey === "rest" ? theme.restSoft : theme.accentSoft)
    readonly property string stateText: {
        if (appController.resumeCount > 0)
            return "即将继续 (RESUME)";
        if (appController.paused)
            return "已暂停 (PAUSED)";
        if (appController.preparing)
            return "准备中 (READY)";
        if (appController.phaseKey === "rest")
            return "休息中 (REST)";
        return "训练中 (WORK)";
    }

    function requestStop(): void {
        appController.stopSession();
    }

    Rectangle {
        anchors.fill: parent
        color: root.pausedState ? "#252525" : root.theme.background

        Behavior on color {
            ColorAnimation {
                duration: root.theme.durationNormal
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 26
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42

            IconButton {
                accessibleName: root.appController.muted ? "恢复声音" : "静音"
                fillColor: "transparent"
                iconColor: root.appController.muted ? root.phaseColor : root.theme.textSecondary
                iconName: root.appController.muted ? "volume-off" : "volume"
                implicitHeight: 38
                implicitWidth: 38
                outlined: false
                theme: root.theme
                onClicked: root.appController.toggleMuted()
            }

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                accessibleName: "全屏"
                fillColor: "transparent"
                iconColor: root.theme.textSecondary
                iconName: "expand"
                implicitHeight: 38
                implicitWidth: 38
                outlined: false
                theme: root.theme
                onClicked: root.fullscreenRequested()
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 27
            Layout.preferredWidth: stateRow.implicitWidth + 22
            Layout.topMargin: 12
            color: root.phaseSoftColor
            radius: height / 2

            Row {
                id: stateRow

                anchors.centerIn: parent
                spacing: 7

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.phaseColor
                    height: 7
                    radius: 4
                    width: 7
                }
                Label {
                    color: root.phaseColor
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    text: root.stateText
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            color: root.theme.textSecondary
            font.pixelSize: 14
            font.weight: Font.DemiBold
            text: root.appController.preparing ? "即将开始" : `第 ${root.appController.currentSet} / ${root.appController.sessionSetCount} 组`
        }

        Item {
            Layout.fillHeight: true
            Layout.minimumHeight: 14
        }

        TimerRing {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumHeight: 360
            Layout.maximumWidth: 360
            Layout.preferredHeight: Math.min(332, root.height * 0.46)
            Layout.preferredWidth: Layout.preferredHeight
            paused: root.pausedState
            phaseColor: root.phaseColor
            progress: root.appController.progress
            theme: root.theme
            timeText: root.appController.remainingText
        }

        Item {
            Layout.fillHeight: true
            Layout.minimumHeight: 18
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 8
            spacing: 34

            HoldIconButton {
                accessibleName: "长按结束训练"
                fillColor: root.pausedState ? "#3a3a3c" : root.theme.surface
                iconColor: root.theme.text
                iconName: "stop"
                implicitHeight: 58
                implicitWidth: 58
                objectName: "stopHoldButton"
                theme: root.theme
                onHeld: root.appController.stopSession()
            }

            IconButton {
                accessibleName: root.appController.resumeCount > 0 ? "取消继续" : root.appController.paused ? "继续" : "暂停"
                enabled: root.appController.canPause
                fillColor: root.theme.text
                iconColor: root.theme.background
                iconName: root.appController.resumeCount > 0 ? "close" : root.appController.paused ? "play" : "pause"
                implicitHeight: 68
                implicitWidth: 68
                outlined: false
                theme: root.theme
                onClicked: root.appController.pauseOrResume()
            }
        }
    }
}
