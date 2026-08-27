pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Dialog {
    id: root

    required property AppBridge appController
    required property Theme theme

    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    dim: true
    height: Math.min(580, Overlay.overlay ? Overlay.overlay.height - 36 : 580)
    modal: true
    padding: 18
    width: Math.min(420, Overlay.overlay ? Overlay.overlay.width - 36 : 420)

    onOpened: {
        const selectedIndex = root.appController.voiceIds.indexOf(root.appController.voiceId);
        if (selectedIndex >= 0)
            voiceList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    background: Rectangle {
        border.color: root.theme.border
        border.width: 1
        color: root.theme.surface
        radius: root.theme.radiusXLarge
    }

    contentItem: ColumnLayout {
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            Item {
                implicitWidth: 40
            }
            Label {
                Layout.fillWidth: true
                color: root.theme.text
                font.pixelSize: 17
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                text: "播报声音"
            }
            IconButton {
                accessibleName: "关闭"
                fillColor: "transparent"
                iconColor: root.theme.textSecondary
                iconName: "close"
                implicitHeight: 40
                implicitWidth: 40
                outlined: false
                theme: root.theme
                onClicked: root.close()
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            border.color: root.theme.border
            border.width: 1
            color: root.theme.backgroundSoft
            radius: root.theme.radiusLarge

            ListView {
                id: voiceList

                objectName: "voiceList"
                anchors.fill: parent
                anchors.margins: 1
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                model: root.appController.voiceNames

                delegate: Item {
                    id: voiceDelegate

                    required property int index
                    required property string modelData
                    readonly property string identifier: root.appController.voiceIds[index]
                    readonly property bool selected: identifier === root.appController.voiceId

                    height: 58
                    width: ListView.view.width

                    AbstractButton {
                        id: selectButton

                        Accessible.name: `选择${voiceDelegate.modelData}`
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: previewButton.left
                        anchors.top: parent.top
                        hoverEnabled: true
                        onClicked: root.appController.setVoiceId(voiceDelegate.identifier)

                        contentItem: RowLayout {
                            spacing: 12

                            LineIcon {
                                color: voiceDelegate.selected ? root.theme.accent : root.theme.textSecondary
                                name: "volume"
                            }
                            Label {
                                Layout.fillWidth: true
                                color: root.theme.text
                                font.pixelSize: 15
                                font.weight: Font.Medium
                                text: voiceDelegate.modelData
                            }
                            LineIcon {
                                color: root.theme.accent
                                name: "check"
                                visible: voiceDelegate.selected
                            }
                        }

                        background: Rectangle {
                            color: voiceDelegate.selected ? root.theme.accentSoft : "transparent"
                            opacity: selectButton.hovered && !selectButton.down ? 0.84 : 1.0
                        }
                    }

                    IconButton {
                        id: previewButton

                        accessibleName: `试听${voiceDelegate.modelData}`
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        fillColor: "transparent"
                        iconColor: root.theme.textSecondary
                        iconName: "play"
                        implicitHeight: 40
                        implicitWidth: 40
                        outlined: false
                        theme: root.theme
                        onClicked: root.appController.previewVoice(voiceDelegate.identifier)
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        color: root.theme.border
                        height: 1
                        visible: voiceDelegate.index + 1 < voiceList.count
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }
    }
}
