import QtQuick

QtObject {
    required property bool dark

    readonly property color background: dark ? "#111512" : "#f4f3ef"
    readonly property color backgroundSoft: dark ? "#171c18" : "#eeede8"
    readonly property color surface: dark ? "#1c211d" : "#fbfbf9"
    readonly property color surfaceStrong: dark ? "#242a25" : "#ffffff"
    readonly property color text: dark ? "#f3f7f4" : "#18201c"
    readonly property color textSecondary: dark ? "#a0aaa3" : "#68706b"
    readonly property color textTertiary: dark ? "#707a73" : "#979d99"
    readonly property color border: dark ? "#2d352f" : "#e2e5e2"
    readonly property color borderStrong: dark ? "#3b453e" : "#d3d8d4"
    readonly property color accent: dark ? "#69d58a" : "#328854"
    readonly property color accentInk: dark ? "#102218" : "#f7fff9"
    readonly property color accentSoft: dark ? "#203a29" : "#dff2e5"
    readonly property color rest: dark ? "#75acd4" : "#3d729b"
    readonly property color restSoft: dark ? "#1c303f" : "#e1edf5"
    readonly property color danger: dark ? "#ff7770" : "#cf4d47"
    readonly property color dangerSoft: dark ? "#412724" : "#f9e6e4"
    readonly property color track: dark ? "#29312b" : "#e3e6e3"
    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 16
    readonly property int radiusXLarge: 24
    readonly property int durationFast: 120
    readonly property int durationNormal: 220
    readonly property int durationSlow: 400

    function phaseColor(phase: string): color {
        return phase === "rest" ? rest : accent;
    }
}
