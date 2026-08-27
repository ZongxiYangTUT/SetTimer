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

    property bool deleteRevealed: false
    readonly property real deleteActionWidth: 76
    readonly property real revealThreshold: deleteActionWidth * 0.4

    Accessible.description: recordCompleted ? "训练已完成，向左滑动可显示删除按钮" : `训练中断，完成 ${recordCompletedSets}，向左滑动可显示删除按钮`
    Accessible.name: `${recordTimeLabel}，${recordSummary}，总计 ${recordElapsedText}`
    clip: true
    implicitHeight: 72
    objectName: "historyRecordCard"

    Item {
        id: deleteAction

        Accessible.name: "删除这条训练记录"
        Accessible.role: Accessible.Button
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.top: parent.top
        objectName: "historyDeleteButton"
        width: root.deleteActionWidth

        Rectangle {
            anchors.fill: parent
            color: root.theme.danger
            radius: 13

            LineIcon {
                anchors.centerIn: parent
                color: root.theme.text
                height: 22
                name: "trash"
                strokeWidth: 2
                width: 22
            }
        }

        TapHandler {
            onTapped: root.deleteRequested()
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
            xAxis.maximum: 0
            xAxis.minimum: -root.deleteActionWidth * 1.15
            yAxis.enabled: false

            onActiveChanged: {
                if (active) {
                    settleAnimation.stop();
                    return;
                }
                root.deleteRevealed = foreground.x <= -root.revealThreshold;
                settleAnimation.to = root.deleteRevealed ? -root.deleteActionWidth : 0;
                settleAnimation.restart();
            }
        }

        TapHandler {
            enabled: root.deleteRevealed
            onTapped: {
                root.deleteRevealed = false;
                settleAnimation.to = 0;
                settleAnimation.restart();
            }
        }
    }

    NumberAnimation {
        id: settleAnimation

        duration: 160
        easing.type: Easing.OutCubic
        property: "x"
        target: foreground
    }
}
