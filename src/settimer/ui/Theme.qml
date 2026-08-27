import QtQuick

QtObject {
    required property bool dark

    // The approved interface is intentionally dark-only. Keep the property on the
    // type boundary so existing controller settings remain source-compatible.
    readonly property color background: "#000000"
    readonly property color backgroundSoft: "#141414"
    readonly property color surface: "#1c1c1e"
    readonly property color surfaceStrong: "#2c2c2e"
    readonly property color text: "#f5f5f7"
    readonly property color textSecondary: "#a1a1a6"
    readonly property color textTertiary: "#646468"
    readonly property color border: "#2c2c2e"
    readonly property color borderStrong: "#3a3a3c"
    readonly property color accent: "#30d158"
    readonly property color accentInk: "#000000"
    readonly property color accentSoft: "#0b2d16"
    readonly property color rest: "#0a84ff"
    readonly property color restSoft: "#082847"
    readonly property color pause: "#ff9f0a"
    readonly property color pauseSoft: "#392608"
    readonly property color danger: "#ff453a"
    readonly property color dangerSoft: "#3a1715"
    readonly property color track: "#29292b"
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
