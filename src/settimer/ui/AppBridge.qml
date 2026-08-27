import QtQml

QtObject {
    id: root

    // Python QObject is the single dynamic boundary between QML and the typed controller.
    // qmllint disable prefer-non-var-properties
    required property var backend
    // qmllint enable prefer-non-var-properties

    readonly property int screen: backend.screen
    readonly property string phaseKey: backend.phase_key
    readonly property string phaseLabel: backend.phase_label
    readonly property string remainingText: backend.remaining_text
    readonly property string totalRemainingText: backend.total_remaining_text
    readonly property string elapsedText: backend.elapsed_text
    readonly property real progress: backend.progress
    readonly property int currentSet: backend.current_set
    readonly property int sessionSetCount: backend.session_set_count
    readonly property bool paused: backend.paused
    readonly property bool preparing: backend.preparing
    readonly property bool canPause: backend.can_pause
    readonly property int resumeCount: backend.resume_count
    readonly property bool muted: backend.muted
    readonly property int workSeconds: backend.work_seconds
    readonly property int restSeconds: backend.rest_seconds
    readonly property int setCount: backend.set_count
    readonly property int preparationSeconds: backend.preparation_seconds
    readonly property bool resumeCountdownEnabled: backend.resume_countdown_enabled
    readonly property bool countdownEnabled: backend.countdown_enabled
    readonly property bool voiceEnabled: backend.voice_enabled
    readonly property bool soundEnabled: backend.sound_enabled
    readonly property string themePreference: backend.theme
    readonly property bool darkMode: backend.dark_mode
    readonly property bool alwaysOnTop: backend.always_on_top
    readonly property string workDurationLabel: backend.work_duration_label
    readonly property string restDurationLabel: backend.rest_duration_label
    readonly property string sessionEstimate: backend.session_estimate
    readonly property int historyRecordCount: backend.history_record_count
    readonly property int historyWeeklyCount: backend.history_weekly_count
    readonly property string historyWeeklyElapsedText: backend.history_weekly_elapsed_text
    // qmllint disable prefer-non-var-properties
    readonly property var historyModel: backend.history_model
    // qmllint enable prefer-non-var-properties

    function openSettings(): void {
        backend.open_settings();
    }
    function closeSettings(): void {
        backend.close_settings();
    }
    function openHistory(): void {
        backend.open_history();
    }
    function closeHistory(): void {
        backend.close_history();
    }
    function startSession(): void {
        backend.start_session();
    }
    function pauseOrResume(): void {
        backend.pause_or_resume();
    }
    function stopSession(): void {
        backend.stop_session();
    }
    function completeSession(): void {
        backend.complete_session();
    }
    function toggleMuted(): void {
        backend.toggle_muted();
    }
    function setWorkSeconds(seconds: int): void {
        backend.set_work_seconds(seconds);
    }
    function setRestSeconds(seconds: int): void {
        backend.set_rest_seconds(seconds);
    }
    function setSetCount(count: int): void {
        backend.set_set_count(count);
    }
    function setPreparationSeconds(seconds: int): void {
        backend.set_preparation_seconds(seconds);
    }
    function setResumeCountdownEnabled(enabled: bool): void {
        backend.set_resume_countdown_enabled(enabled);
    }
    function setCountdownEnabled(enabled: bool): void {
        backend.set_countdown_enabled(enabled);
    }
    function setVoiceEnabled(enabled: bool): void {
        backend.set_voice_enabled(enabled);
    }
    function setSoundEnabled(enabled: bool): void {
        backend.set_sound_enabled(enabled);
    }
    function setTheme(preference: string): void {
        backend.set_theme(preference);
    }
    function setAlwaysOnTop(enabled: bool): void {
        backend.set_always_on_top(enabled);
    }
}
