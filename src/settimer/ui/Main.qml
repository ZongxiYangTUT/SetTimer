import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root

    // The Python QObject enters QML only once and is wrapped by AppBridge.
    // qmllint disable prefer-non-var-properties
    required property var backend
    // qmllint enable prefer-non-var-properties

    color: theme.background
    flags: Qt.Window | (appController.alwaysOnTop ? Qt.WindowStaysOnTopHint : 0)
    height: 760
    minimumHeight: 640
    minimumWidth: 400
    title: "SetTimer"
    visible: true
    width: 460

    AppBridge {
        id: appController

        backend: root.backend
    }

    Theme {
        id: theme

        dark: true
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: appController.screen

        HomeView {
            appController: appController
            theme: theme
        }
        SettingsView {
            appController: appController
            theme: theme
        }
        TimerView {
            id: timerView

            appController: appController
            theme: theme
            onFullscreenRequested: root.toggleFullscreen()
        }
        CompleteView {
            appController: appController
            theme: theme
        }
    }

    Shortcut {
        sequence: "Space"
        onActivated: {
            if (appController.screen === 0 || appController.screen === 3)
                appController.startSession();
            else if (appController.screen === 2 && appController.canPause)
                appController.pauseOrResume();
        }
    }
    Shortcut {
        sequence: "R"
        onActivated: {
            if (appController.screen === 3)
                appController.startSession();
            else if (appController.screen === 2)
                timerView.requestStop();
        }
    }
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (appController.screen === 1)
                appController.closeSettings();
        }
    }
    Shortcut {
        sequence: "F"
        enabled: appController.screen === 2
        onActivated: root.toggleFullscreen()
    }
    Shortcut {
        sequence: "M"
        onActivated: appController.toggleMuted()
    }

    function toggleFullscreen(): void {
        visibility = visibility === Window.FullScreen ? Window.Windowed : Window.FullScreen;
    }

    Behavior on color {
        ColorAnimation {
            duration: theme.durationNormal
        }
    }
}
