import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property color color: "#000000"
    property string name: ""
    property real strokeWidth: 1.8

    readonly property string pathData: {
        switch (name) {
        case "activity":
            return "M3 12h4l2-5 4 10 2-5h6";
        case "back":
            return "M15 18l-6-6 6-6";
        case "bell":
            return "M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9 M10 21h4";
        case "check":
            return "M5 12l4 4L19 6";
        case "clock":
            return "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z M12 7v5l3 2";
        case "close":
            return "M6 6l12 12 M18 6L6 18";
        case "expand":
            return "M8 3H3v5 M16 3h5v5 M8 21H3v-5 M16 21h5v-5";
        case "hourglass":
            return "M6 3h12 M6 21h12 M8 3v4l4 5-4 5v4 M16 3v4l-4 5 4 5v4";
        case "history":
            return "M3 12a9 9 0 1 0 3-6.7 M3 3v6h6 M12 7v5l3 2";
        case "history-rounded":
            return "M12 21q-3.15 0-5.575-1.912T3.275 14.2q-.1-.375.15-.687t.675-.363q.4-.05.725.15t.45.6q.6 2.25 2.475 3.675T12 19q2.925 0 4.963-2.037T19 12t-2.037-4.962T12 5q-1.725 0-3.225.8T6.25 8H8q.425 0 .713.288T9 9t-.288.713T8 10H4q-.425 0-.712-.288T3 9V5q0-.425.288-.712T4 4t.713.288T5 5v1.35q1.275-1.6 3.113-2.475T12 3q1.875 0 3.513.713t2.85 1.924t1.925 2.85T21 12t-.712 3.513t-1.925 2.85t-2.85 1.925T12 21m1-9.4 2.5 2.5q.275.275.275.7t-.275.7-.7.275-.7-.275l-2.8-2.8q-.15-.15-.225-.337T11 11.975V8q0-.425.288-.712T12 7t.713.288T13 8z";
        case "microphone":
            return "M12 3a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3z M5 11v1a7 7 0 0 0 14 0v-1 M12 19v3 M8 22h8";
        case "pause":
            return "M9 5v14 M15 5v14";
        case "pin":
            return "M8 3h8l-1 6 3 3H6l3-3-1-6z M12 12v9";
        case "play":
            return "M8 5l11 7-11 7z";
        case "restart":
            return "M4 11a8 8 0 1 1 2 6 M4 11V5 M4 11h6";
        case "rest":
            return "M5 8h12v5a5 5 0 0 1-5 5h-2a5 5 0 0 1-5-5V8z M17 10h2a2 2 0 0 1 0 4h-2 M8 3v2 M12 3v2";
        case "sets":
            return "M12 3L3 8l9 5 9-5-9-5z M3 12l9 5 9-5 M3 16l9 5 9-5";
        case "settings":
            return "M12.2 2h-.4a2 2 0 0 0-2 2v.2a2 2 0 0 1-1 1.7l-.4.3a2 2 0 0 1-2 0L6 6a2 2 0 0 0-2.7.7l-.2.4a2 2 0 0 0 .7 2.7l.4.2a2 2 0 0 1 1 1.7v.6a2 2 0 0 1-1 1.7l-.4.2a2 2 0 0 0-.7 2.7l.2.4A2 2 0 0 0 6 18l.4-.2a2 2 0 0 1 2 0l.4.3a2 2 0 0 1 1 1.7v.2a2 2 0 0 0 2 2h.4a2 2 0 0 0 2-2v-.2a2 2 0 0 1 1-1.7l.4-.3a2 2 0 0 1 2 0l.4.2a2 2 0 0 0 2.7-.7l.2-.4a2 2 0 0 0-.7-2.7l-.4-.2a2 2 0 0 1-1-1.7v-.6a2 2 0 0 1 1-1.7l.4-.2a2 2 0 0 0 .7-2.7l-.2-.4A2 2 0 0 0 18 6l-.4.2a2 2 0 0 1-2 0l-.4-.3a2 2 0 0 1-1-1.7V4a2 2 0 0 0-2-2z M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z";
        case "settings-sharp":
            return "M9 12a3 3 0 1 0 6 0 3 3 0 1 0-6 0 M14.5 2h-5v2.398a7.992 7.992 0 0 0-2.831 1.637l-2.08-1.2-2.5 4.33 2.078 1.2a8.034 8.034 0 0 0 0 3.27l-2.077 1.2 2.5 4.33 2.079-1.2a7.992 7.992 0 0 0 2.83 1.637V22h5v-2.398a7.992 7.992 0 0 0 2.832-1.637l2.08 1.2 2.5-4.33-2.078-1.2a8.039 8.039 0 0 0 0-3.27l2.077-1.2-2.5-4.33-2.079 1.2A7.992 7.992 0 0 0 14.5 4.398V2Z";
        case "stop":
            return "M7 7h10v10H7z";
        case "theme":
            return "M12 4a8 8 0 1 0 8 8 6 6 0 0 1-8-8z";
        case "trash":
            return "M4 7h16 M9 7V4h6v3 M6 7l1 14h10l1-14 M10 11v6 M14 11v6";
        case "volume":
            return "M11 5L6 9H2v6h4l5 4V5z M15 9a4 4 0 0 1 0 6 M17 6a8 8 0 0 1 0 12";
        case "volume-off":
            return "M11 5L6 9H2v6h4l5 4V5z M16 9l6 6 M22 9l-6 6";
        case "warning":
            return "M12 8v5 M12 17h.01 M10.3 4.6L2.5 18a2 2 0 0 0 1.7 3h15.6a2 2 0 0 0 1.7-3L13.7 4.6a2 2 0 0 0-3.4 0z";
        default:
            return "";
        }
    }

    implicitHeight: 24
    implicitWidth: 24

    Shape {
        anchors.centerIn: parent
        height: 24
        scale: Math.min(root.width, root.height) / 24
        width: 24

        ShapePath {
            capStyle: ShapePath.RoundCap
            fillColor: root.name === "history-rounded" ? root.color : "transparent"
            joinStyle: root.name === "settings-sharp" ? ShapePath.MiterJoin : ShapePath.RoundJoin
            strokeColor: root.name === "history-rounded" ? "transparent" : root.color
            strokeWidth: root.name === "settings-sharp" ? 1.5 : root.strokeWidth

            PathSvg {
                path: root.pathData
            }
        }
    }
}
