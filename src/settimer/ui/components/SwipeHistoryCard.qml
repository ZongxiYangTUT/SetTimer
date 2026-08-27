import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Item {
    id: root

    required property Theme theme
    property bool recordCompleted: true
    property string recordCompletedSets: "0 / 0"
    property string recordElapsedText: "00:00"
    property string recordSummary: ""
    property string recordTimeLabel: ""
    signal deleteRequested

    property bool pendingDelete: false
    readonly property real deleteThreshold: Math.min(96, width * 0.24)

    Accessible.description: recordCompleted ? "训练已完成，向右滑动可删除" : `训练中断，完成 ${recordCompletedSets}，向右滑动可删除`
    Accessible.name: `${recordTimeLabel}，${recordSummary}，总计 ${recordElapsedText}`
    clip: true
    implicitHeight: 72
    objectName: "historyRecordCard"

    Rectangle {
        anchors.fill: parent
        color: root.theme.danger
        radius: 13

        LineIcon {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            color: root.theme.text
            height: 22
            name: "trash"
            strokeWidth: 2
            width: 22
        }
    }

    Rectangle {
        id: foreground

        border.color: root.theme.border
        border.width: 1
        color: root.theme.surface
        height: parent.height
        radius: 13
        width: parent.width

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 2

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    color: root.theme.textSecondary
                    font.pixelSize: 11
                    text: root.recordTimeLabel
                }
                Label {
                    color: root.theme.textTertiary
                    font.pixelSize: 10
                    text: "总计"
                }
                Label {
                    color: root.theme.text
                    font.family: "Consolas"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    text: root.recordElapsedText
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    color: root.theme.text
                    elide: Text.ElideRight
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    text: root.recordSummary
                }

                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 24
                    color: root.recordCompleted ? root.theme.accentSoft : root.theme.pauseSoft
                    radius: 12

                    LineIcon {
                        anchors.centerIn: parent
                        color: root.recordCompleted ? root.theme.accent : root.theme.pause
                        height: 14
                        name: root.recordCompleted ? "check" : "warning"
                        strokeWidth: 2.2
                        width: 14
                    }
                }
            }
        }

        DragHandler {
            id: swipeHandler

            target: foreground
            xAxis.maximum: root.width * 0.38
            xAxis.minimum: 0
            yAxis.enabled: false

            onActiveChanged: {
                if (active)
                    return;
                root.pendingDelete = foreground.x >= root.deleteThreshold;
                settleAnimation.to = root.pendingDelete ? root.width : 0;
                settleAnimation.restart();
            }
        }
    }

    NumberAnimation {
        id: settleAnimation

        duration: root.pendingDelete ? 180 : 160
        easing.type: Easing.OutCubic
        property: "x"
        target: foreground
        onFinished: {
            if (root.pendingDelete)
                root.deleteRequested();
        }
    }
}
