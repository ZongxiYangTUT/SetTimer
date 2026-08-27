pragma ComponentBehavior: Bound

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
        anchors.margins: 22
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 48

            IconButton {
                accessibleName: "返回"
                fillColor: "transparent"
                iconColor: root.theme.text
                iconName: "back"
                implicitHeight: 40
                implicitWidth: 40
                outlined: false
                theme: root.theme
                onClicked: root.appController.closeHistory()
            }
            Label {
                Layout.fillWidth: true
                color: root.theme.text
                font.pixelSize: 20
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                text: "历史记录"
            }
            Item {
                implicitWidth: 40
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 84
            Layout.topMargin: 18
            border.color: root.theme.border
            border.width: 1
            color: root.theme.surface
            radius: 14

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        color: root.theme.textSecondary
                        font.pixelSize: 11
                        text: "本周训练"
                    }
                    Label {
                        color: root.theme.accent
                        font.pixelSize: 25
                        font.weight: Font.Bold
                        text: `${root.appController.historyWeeklyCount} 次`
                    }
                }

                Rectangle {
                    Layout.preferredHeight: 42
                    Layout.preferredWidth: 1
                    color: root.theme.border
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        color: root.theme.textSecondary
                        font.pixelSize: 11
                        text: "总计时间"
                    }
                    Label {
                        color: root.theme.text
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        text: root.appController.historyWeeklyElapsedText
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.topMargin: 10

            ListView {
                id: historyList

                anchors.fill: parent
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                model: root.appController.historyModel
                spacing: 8

                section.criteria: ViewSection.FullString
                section.property: "sectionLabel"
                section.delegate: Label {
                    required property string section

                    color: root.theme.textSecondary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    height: 30
                    leftPadding: 2
                    text: section
                    verticalAlignment: Text.AlignBottom
                    width: historyList.width
                }

                delegate: Rectangle {
                    id: recordCard

                    required property bool completed
                    required property string completedSets
                    required property string elapsedText
                    required property string summary
                    required property string timeLabel

                    Accessible.description: completed ? "训练已完成" : `训练中断，完成 ${completedSets}`
                    Accessible.name: `${timeLabel}，${summary}，总计 ${elapsedText}`
                    border.color: root.theme.border
                    border.width: 1
                    color: root.theme.surface
                    height: 72
                    radius: 13
                    width: historyList.width

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
                                text: recordCard.timeLabel
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
                                text: recordCard.elapsedText
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
                                text: recordCard.summary
                            }

                            Rectangle {
                                Layout.preferredHeight: 24
                                Layout.preferredWidth: 24
                                color: recordCard.completed ? root.theme.accentSoft : root.theme.pauseSoft
                                radius: 12

                                LineIcon {
                                    anchors.centerIn: parent
                                    color: recordCard.completed ? root.theme.accent : root.theme.pause
                                    height: 14
                                    name: recordCard.completed ? "check" : "warning"
                                    strokeWidth: 2.2
                                    width: 14
                                }
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    id: historyScrollBar

                    background: Item {}
                    contentItem: Rectangle {
                        color: root.theme.borderStrong
                        implicitWidth: 4
                        opacity: historyScrollBar.active ? 0.9 : 0.55
                        radius: width / 2
                    }
                    implicitWidth: 6
                    policy: ScrollBar.AsNeeded
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 12
                visible: root.appController.historyRecordCount === 0

                LineIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.theme.textTertiary
                    height: 32
                    name: "history"
                    width: 32
                }
                Label {
                    color: root.theme.textTertiary
                    font.pixelSize: 13
                    text: "暂无训练记录"
                }
            }
        }
    }
}
