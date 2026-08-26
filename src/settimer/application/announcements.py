from __future__ import annotations

import math

from settimer.application.formatting import format_spoken_duration
from settimer.domain.events import (
    CountdownThresholdReached,
    PhaseStarted,
    SessionCompleted,
    TimerEvent,
)
from settimer.domain.models import TimerPhase, TimerSnapshot
from settimer.services.audio import AudioPort
from settimer.services.settings import AppSettings
from settimer.services.speech import SpeechPort


class AnnouncementCoordinator:
    """Translate semantic timer events into optional desktop audio behavior."""

    def __init__(self, speech: SpeechPort, audio: AudioPort) -> None:
        self._speech = speech
        self._audio = audio

    def handle(
        self,
        events: list[TimerEvent],
        snapshot: TimerSnapshot,
        settings: AppSettings,
        muted: bool,
    ) -> None:
        if muted or not events:
            return

        if any(isinstance(event, SessionCompleted) for event in events):
            if settings.sound_enabled:
                self._audio.play_completion()
            if settings.voice_enabled:
                self._speech.speak("训练完成。")
            return

        phase_events = [event for event in events if isinstance(event, PhaseStarted)]
        current_phase_event = next(
            (
                event
                for event in reversed(phase_events)
                if event.phase is snapshot.active_phase
                and event.set_number == snapshot.current_set
            ),
            None,
        )
        if current_phase_event is not None:
            self._announce_phase(current_phase_event, settings)
            return

        remaining_second = math.ceil(snapshot.remaining)
        threshold_event = next(
            (
                event
                for event in reversed(events)
                if isinstance(event, CountdownThresholdReached)
                and event.phase is snapshot.active_phase
                and event.set_number == snapshot.current_set
                and event.seconds == remaining_second
            ),
            None,
        )
        if threshold_event is None:
            return
        if settings.sound_enabled:
            self._audio.play_tick(threshold_event.seconds)
        if settings.voice_enabled and threshold_event.phase is not TimerPhase.PREPARING:
            self._speech.speak(str(threshold_event.seconds))

    def stop(self) -> None:
        self._speech.stop()

    def _announce_phase(self, event: PhaseStarted, settings: AppSettings) -> None:
        if event.phase is TimerPhase.PREPARING:
            return
        if settings.sound_enabled:
            self._audio.play_phase_change()
        if not settings.voice_enabled:
            return
        if event.phase is TimerPhase.REST:
            self._speech.speak(
                f"第 {event.set_number} 组结束，休息"  # noqa: RUF001 - Chinese punctuation
                f"{format_spoken_duration(settings.rest_seconds)}。"
            )
            return
        if event.set_number == 1:
            self._speech.speak("第 1 组开始。")
            return
        prefix = "最后一组。" if event.set_number == settings.set_count else ""
        self._speech.speak(
            f"{prefix}休息结束，第 {event.set_number} 组开始。"  # noqa: RUF001
        )
