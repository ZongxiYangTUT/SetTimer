from __future__ import annotations

import logging
import math
from dataclasses import replace
from enum import IntEnum

from PySide6.QtCore import Property, QObject, Qt, QTimer, Signal, Slot
from PySide6.QtGui import QGuiApplication

from settimer.application.announcements import AnnouncementCoordinator
from settimer.application.formatting import (
    format_clock,
    format_duration,
    format_estimate,
)
from settimer.domain.clock import Clock
from settimer.domain.events import (
    PhaseCompleted,
    PhaseStarted,
    SessionCompleted,
    SessionPaused,
    SessionReset,
    SessionResumed,
    SessionStarted,
    TimerEvent,
)
from settimer.domain.models import SessionConfig, TimerPhase, TimerSnapshot
from settimer.domain.timer_engine import InvalidTimerTransition, TimerEngine
from settimer.services.audio import AudioPort, QtAudioService
from settimer.services.clock import SystemMonotonicClock
from settimer.services.power import PowerInhibitor, create_power_inhibitor
from settimer.services.settings import (
    AppSettings,
    QtSettingsStore,
    SettingsStore,
    ThemePreference,
)
from settimer.services.speech import QtSpeechService, SpeechPort

logger = logging.getLogger(__name__)


class Screen(IntEnum):
    HOME = 0
    SETTINGS = 1
    TIMER = 2
    COMPLETE = 3


class AppController(QObject):
    state_changed = Signal()
    settings_changed = Signal()
    screen_changed = Signal()
    resume_countdown_changed = Signal()
    muted_changed = Signal()

    def __init__(
        self,
        *,
        clock: Clock | None = None,
        settings_store: SettingsStore | None = None,
        speech: SpeechPort | None = None,
        audio: AudioPort | None = None,
        power: PowerInhibitor | None = None,
        auto_start_updates: bool = True,
        parent: QObject | None = None,
    ) -> None:
        super().__init__(parent)
        self._clock = clock or SystemMonotonicClock()
        self._engine = TimerEngine(self._clock)
        self._settings_store = settings_store or QtSettingsStore()
        self._settings = self._settings_store.load()
        speech_service = speech or QtSpeechService()
        audio_service = audio or QtAudioService(self)
        self._announcements = AnnouncementCoordinator(speech_service, audio_service)
        self._power = power or create_power_inhibitor()
        self._screen = Screen.HOME
        self._muted = False
        self._resume_deadline: float | None = None
        self._resume_count = 0
        self._snapshot = TimerSnapshot(
            phase=TimerPhase.IDLE,
            active_phase=None,
            current_set=1,
            total_sets=0,
            remaining=0.0,
            phase_duration=0.0,
            total_remaining=0.0,
            elapsed=0.0,
            progress=0.0,
        )

        self._update_timer = QTimer(self)
        self._update_timer.setInterval(33)
        self._update_timer.setTimerType(Qt.TimerType.PreciseTimer)
        self._update_timer.timeout.connect(self.refresh)
        if auto_start_updates:
            self._update_timer.start()

        application = QGuiApplication.instance()
        if isinstance(application, QGuiApplication):
            application.styleHints().colorSchemeChanged.connect(
                self._on_system_color_scheme_changed
            )

    @Property(int, notify=screen_changed)
    def screen(self) -> int:
        return int(self._screen)

    @Property(str, notify=state_changed)
    def phase_key(self) -> str:
        active_phase = self._snapshot.active_phase
        return active_phase.value if active_phase is not None else self._snapshot.phase.value

    @Property(str, notify=state_changed)
    def phase_label(self) -> str:
        if self._resume_count > 0:
            return "继续"
        if self._snapshot.phase is TimerPhase.PAUSED:
            return "已暂停"
        labels = {
            TimerPhase.IDLE: "准备开始",
            TimerPhase.PREPARING: "准备",
            TimerPhase.WORK: "训练",
            TimerPhase.REST: "休息",
            TimerPhase.COMPLETED: "已完成",
        }
        return labels.get(self._snapshot.phase, "")

    @Property(str, notify=state_changed)
    def phase_detail(self) -> str:
        if self._resume_count > 0:
            return "准备回到训练"
        if self._snapshot.phase is TimerPhase.PAUSED:
            return "计时已暂停"
        details = {
            TimerPhase.PREPARING: "深呼吸，准备就位",  # noqa: RUF001
            TimerPhase.WORK: "保持节奏",
            TimerPhase.REST: "放松呼吸",
        }
        active_phase = self._snapshot.active_phase
        return details.get(active_phase, "") if active_phase is not None else ""

    @Property(str, notify=state_changed)
    def remaining_text(self) -> str:
        return (
            str(self._resume_count)
            if self._resume_count > 0
            else format_clock(self._snapshot.remaining)
        )

    @Property(str, notify=state_changed)
    def total_remaining_text(self) -> str:
        return format_clock(self._snapshot.total_remaining)

    @Property(str, notify=state_changed)
    def elapsed_text(self) -> str:
        return format_clock(self._snapshot.elapsed)

    @Property(float, notify=state_changed)
    def progress(self) -> float:
        return self._snapshot.progress

    @Property(int, notify=state_changed)
    def current_set(self) -> int:
        return self._snapshot.current_set

    @Property(int, notify=state_changed)
    def session_set_count(self) -> int:
        return self._snapshot.total_sets

    @Property(bool, notify=state_changed)
    def paused(self) -> bool:
        return self._snapshot.phase is TimerPhase.PAUSED

    @Property(bool, notify=state_changed)
    def preparing(self) -> bool:
        return self._snapshot.active_phase is TimerPhase.PREPARING

    @Property(bool, notify=state_changed)
    def can_pause(self) -> bool:
        return self._snapshot.phase in {TimerPhase.WORK, TimerPhase.REST, TimerPhase.PAUSED}

    @Property(int, notify=resume_countdown_changed)
    def resume_count(self) -> int:
        return self._resume_count

    @Property(bool, notify=muted_changed)
    def muted(self) -> bool:
        return self._muted

    @Property(int, notify=settings_changed)
    def work_seconds(self) -> int:
        return self._settings.work_seconds

    @Property(int, notify=settings_changed)
    def rest_seconds(self) -> int:
        return self._settings.rest_seconds

    @Property(int, notify=settings_changed)
    def set_count(self) -> int:
        return self._settings.set_count

    @Property(int, notify=settings_changed)
    def preparation_seconds(self) -> int:
        return self._settings.preparation_seconds

    @Property(bool, notify=settings_changed)
    def resume_countdown_enabled(self) -> bool:
        return self._settings.resume_countdown

    @Property(bool, notify=settings_changed)
    def countdown_enabled(self) -> bool:
        return self._settings.countdown_enabled

    @Property(bool, notify=settings_changed)
    def voice_enabled(self) -> bool:
        return self._settings.voice_enabled

    @Property(bool, notify=settings_changed)
    def sound_enabled(self) -> bool:
        return self._settings.sound_enabled

    @Property(str, notify=settings_changed)
    def theme(self) -> str:
        return self._settings.theme.value

    @Property(bool, notify=settings_changed)
    def dark_mode(self) -> bool:
        if self._settings.theme is ThemePreference.DARK:
            return True
        if self._settings.theme is ThemePreference.LIGHT:
            return False
        application = QGuiApplication.instance()
        return bool(
            isinstance(application, QGuiApplication)
            and application.styleHints().colorScheme() is Qt.ColorScheme.Dark
        )

    @Property(bool, notify=settings_changed)
    def always_on_top(self) -> bool:
        return self._settings.always_on_top

    @Property(str, notify=settings_changed)
    def work_duration_label(self) -> str:
        return format_duration(self._settings.work_seconds)

    @Property(str, notify=settings_changed)
    def rest_duration_label(self) -> str:
        return format_duration(self._settings.rest_seconds)

    @Property(str, notify=settings_changed)
    def session_estimate(self) -> str:
        total = (
            self._settings.preparation_seconds
            + self._settings.work_seconds * self._settings.set_count
            + self._settings.rest_seconds * max(0, self._settings.set_count - 1)
        )
        return format_estimate(total)

    @Slot()
    def open_settings(self) -> None:
        if self._screen is Screen.HOME:
            self._set_screen(Screen.SETTINGS)

    @Slot()
    def close_settings(self) -> None:
        if self._screen is Screen.SETTINGS:
            self._set_screen(Screen.HOME)

    @Slot()
    def start_session(self) -> None:
        if self._screen not in {Screen.HOME, Screen.COMPLETE}:
            return
        thresholds = (3, 2, 1) if self._settings.countdown_enabled else ()
        config = SessionConfig(
            work_duration=float(self._settings.work_seconds),
            rest_duration=float(self._settings.rest_seconds),
            set_count=self._settings.set_count,
            preparation_duration=float(self._settings.preparation_seconds),
            countdown_thresholds=thresholds,
        )
        events = self._engine.start(config)
        self._resume_deadline = None
        self._set_resume_count(0)
        self._power.acquire()
        self._set_screen(Screen.TIMER)
        self._consume(events)

    @Slot()
    def pause_or_resume(self) -> None:
        if self._resume_deadline is not None:
            self._resume_deadline = None
            self._set_resume_count(0)
            return
        try:
            if self._engine.phase is TimerPhase.PAUSED:
                if self._settings.resume_countdown:
                    self._resume_deadline = self._clock.now() + 3.0
                    self._set_resume_count(3)
                    return
                events = self._engine.resume()
            else:
                events = self._engine.pause()
        except InvalidTimerTransition:
            logger.warning(
                "timer_command_rejected command=pause_or_resume phase=%s", self.phase_key
            )
            return
        self._consume(events)

    @Slot()
    def stop_session(self) -> None:
        events = self._engine.reset()
        self._resume_deadline = None
        self._set_resume_count(0)
        self._announcements.stop()
        self._power.release()
        self._consume(events)
        self._set_screen(Screen.HOME)

    @Slot()
    def complete_session(self) -> None:
        self.stop_session()

    @Slot()
    def toggle_muted(self) -> None:
        self._muted = not self._muted
        if self._muted:
            self._announcements.stop()
        self.muted_changed.emit()

    @Slot(int)
    def set_work_seconds(self, seconds: int) -> None:
        self._store_settings(replace(self._settings, work_seconds=min(3599, max(1, seconds))))

    @Slot(int)
    def set_rest_seconds(self, seconds: int) -> None:
        self._store_settings(replace(self._settings, rest_seconds=min(3599, max(0, seconds))))

    @Slot(int)
    def set_set_count(self, count: int) -> None:
        self._store_settings(replace(self._settings, set_count=min(99, max(1, count))))

    @Slot(int)
    def set_preparation_seconds(self, seconds: int) -> None:
        normalized = seconds if seconds in {0, 3, 5} else 3
        self._store_settings(replace(self._settings, preparation_seconds=normalized))

    @Slot(bool)
    def set_resume_countdown_enabled(self, enabled: bool) -> None:
        self._store_settings(replace(self._settings, resume_countdown=enabled))

    @Slot(bool)
    def set_countdown_enabled(self, enabled: bool) -> None:
        self._store_settings(replace(self._settings, countdown_enabled=enabled))

    @Slot(bool)
    def set_voice_enabled(self, enabled: bool) -> None:
        self._store_settings(replace(self._settings, voice_enabled=enabled))

    @Slot(bool)
    def set_sound_enabled(self, enabled: bool) -> None:
        self._store_settings(replace(self._settings, sound_enabled=enabled))

    @Slot(str)
    def set_theme(self, theme: str) -> None:
        try:
            preference = ThemePreference(theme)
        except ValueError:
            logger.warning("theme_change_rejected value=%s", theme)
            return
        self._store_settings(replace(self._settings, theme=preference))

    @Slot(bool)
    def set_always_on_top(self, enabled: bool) -> None:
        self._store_settings(replace(self._settings, always_on_top=enabled))

    @Slot()
    def refresh(self) -> None:
        events: list[TimerEvent] = []
        if self._resume_deadline is not None:
            remaining = self._resume_deadline - self._clock.now()
            if remaining <= 0:
                self._resume_deadline = None
                self._set_resume_count(0)
                try:
                    events.extend(self._engine.resume())
                except InvalidTimerTransition:
                    logger.warning("timer_command_rejected command=delayed_resume")
            else:
                self._set_resume_count(math.ceil(remaining))
        events.extend(self._engine.update())
        self._consume(events)

    def shutdown(self) -> None:
        self._update_timer.stop()
        self._announcements.stop()
        self._power.release()

    def _consume(self, events: list[TimerEvent]) -> None:
        self._snapshot = self._engine.snapshot()
        if events:
            self._log_events(events)
            self._announcements.handle(events, self._snapshot, self._settings, self._muted)
        if any(isinstance(event, SessionCompleted) for event in events):
            self._power.release()
            self._set_screen(Screen.COMPLETE)
        self.state_changed.emit()

    def _store_settings(self, settings: AppSettings) -> None:
        self._settings = settings
        if not self._settings_store.save(settings):
            logger.warning("settings_save_failed changes remain active for this run")
        self.settings_changed.emit()

    def _set_screen(self, screen: Screen) -> None:
        if screen is self._screen:
            return
        self._screen = screen
        self.screen_changed.emit()

    def _set_resume_count(self, count: int) -> None:
        if count == self._resume_count:
            return
        self._resume_count = count
        self.resume_countdown_changed.emit()
        self.state_changed.emit()

    def _on_system_color_scheme_changed(self, _scheme: Qt.ColorScheme) -> None:
        if self._settings.theme is ThemePreference.SYSTEM:
            self.settings_changed.emit()

    @staticmethod
    def _log_events(events: list[TimerEvent]) -> None:
        for event in events:
            if isinstance(event, SessionStarted):
                logger.info("session_started sets=%s", event.config.set_count)
            elif isinstance(event, PhaseStarted):
                logger.info(
                    "phase_started phase=%s set=%s", event.phase.value, event.set_number
                )
            elif isinstance(event, PhaseCompleted):
                logger.info(
                    "phase_completed phase=%s set=%s", event.phase.value, event.set_number
                )
            elif isinstance(event, SessionPaused):
                logger.info("session_paused phase=%s", event.phase.value)
            elif isinstance(event, SessionResumed):
                logger.info("session_resumed phase=%s", event.phase.value)
            elif isinstance(event, SessionCompleted):
                logger.info("session_completed sets=%s", event.set_count)
            elif isinstance(event, SessionReset):
                logger.info("session_reset")
