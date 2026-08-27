pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import ".."

Item {
    id: root

    required property Theme theme
    property int itemCount: 1
    property string label: ""
    property string mode: "duration"
    property int selectedIndex: 0
    property int startSeconds: 0
    property int stepSeconds: 1
    signal valueSelected(int value)

    property alias currentIndex: picker.currentIndex
    readonly property bool ready: picker.ready

    function clockText(seconds: int): string {
        const normalized = Math.max(0, seconds);
        const minutes = Math.floor(normalized / 60);
        const finalSeconds = normalized % 60;
        return `${minutes.toString().padStart(2, "0")}:${finalSeconds.toString().padStart(2, "0")}`;
    }

    function displayValue(index: int): string {
        if (mode === "sets")
            return (index + 1).toString();
        return clockText(startSeconds + index * stepSeconds);
    }

    function selectedValue(index: int): int {
        if (mode === "sets")
            return index + 1;
        return startSeconds + index * stepSeconds;
    }

    implicitHeight: 164

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        color: root.theme.textSecondary
        font.pixelSize: 11
        font.weight: Font.Medium
        text: root.label
    }

    Rectangle {
        anchors.fill: picker
        anchors.topMargin: picker.height / 2 - 17
        anchors.bottomMargin: picker.height / 2 - 17
        color: root.theme.surfaceStrong
        radius: 6
    }

    Tumbler {
        id: picker

        property bool ready: false

        Accessible.name: `${root.label}，滚动设置`
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 27
        currentIndex: root.selectedIndex
        model: root.itemCount
        visibleItemCount: 5
        wrap: false

        delegate: Text {
            required property int index
            required property int modelData
            readonly property bool centered: Math.abs(Tumbler.displacement) < 0.01

            color: centered ? root.theme.text : root.theme.textTertiary
            font.family: "Consolas"
            font.pixelSize: centered ? 20 : 13
            font.weight: centered ? Font.Bold : Font.Normal
            horizontalAlignment: Text.AlignHCenter
            opacity: 1.0 - Math.min(0.7, Math.abs(Tumbler.displacement) * 0.3)
            text: root.displayValue(index)
            verticalAlignment: Text.AlignVCenter
        }

        Component.onCompleted: ready = true
        onCurrentIndexChanged: {
            if (ready)
                root.valueSelected(root.selectedValue(currentIndex));
        }
    }

    Rectangle {
        anchors.fill: parent
        border.color: picker.moving ? root.theme.borderStrong : root.theme.border
        border.width: 1
        color: "transparent"
        radius: 9
    }
}
