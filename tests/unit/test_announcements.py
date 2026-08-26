from __future__ import annotations

import unittest

from settimer.application.announcements import AnnouncementCoordinator
from settimer.domain.events import (
    CountdownThresholdReached,
    PhaseStarted,
    SessionCompleted,
    TimerEvent,
)
from settimer.domain.models import TimerPhase, TimerSnapshot
from settimer.services.settings import AppSettings
from tests.fakes import FakeAudio, FakeSpeech


def snapshot(phase: TimerPhase, set_number: int, remaining: float = 10.0) -> TimerSnapshot:
    return TimerSnapshot(
        phase=phase,
        active_phase=phase,
        current_set=set_number,
        total_sets=3,
        remaining=remaining,
        phase_duration=30.0,
        total_remaining=remaining,
        elapsed=0.0,
        progress=remaining / 30.0,
    )


class AnnouncementCoordinatorTests(unittest.TestCase):
    def setUp(self) -> None:
        self.speech = FakeSpeech()
        self.audio = FakeAudio()
        self.coordinator = AnnouncementCoordinator(self.speech, self.audio)
        self.settings = AppSettings(rest_seconds=15, set_count=3)

    def test_announces_only_the_current_phase_after_a_delayed_update(self) -> None:
        events: list[TimerEvent] = [
            PhaseStarted(TimerPhase.REST, 1, 15.0),
            PhaseStarted(TimerPhase.WORK, 2, 60.0),
        ]

        self.coordinator.handle(events, snapshot(TimerPhase.WORK, 2), self.settings, False)

        self.assertEqual(self.audio.phase_changes, 1)
        self.assertEqual(self.speech.messages, ["休息结束，第 2 组开始。"])  # noqa: RUF001

    def test_phase_messages_cover_first_rest_and_last_set(self) -> None:
        cases = (
            (
                PhaseStarted(TimerPhase.WORK, 1, 60.0),
                snapshot(TimerPhase.WORK, 1),
                "第 1 组开始。",
            ),
            (
                PhaseStarted(TimerPhase.REST, 1, 15.0),
                snapshot(TimerPhase.REST, 1),
                "第 1 组结束，休息15秒。",  # noqa: RUF001
            ),
            (
                PhaseStarted(TimerPhase.WORK, 3, 60.0),
                snapshot(TimerPhase.WORK, 3),
                "最后一组。休息结束，第 3 组开始。",  # noqa: RUF001
            ),
        )

        for event, current_snapshot, expected in cases:
            with self.subTest(event=event):
                self.speech.messages.clear()
                self.coordinator.handle([event], current_snapshot, self.settings, False)
                self.assertEqual(self.speech.messages, [expected])

    def test_thresholds_completion_muting_and_disabled_outputs(self) -> None:
        threshold = CountdownThresholdReached(TimerPhase.WORK, 1, 3)
        self.coordinator.handle(
            [threshold], snapshot(TimerPhase.WORK, 1, 2.8), self.settings, False
        )
        self.assertEqual(self.audio.ticks, [3])
        self.assertEqual(self.speech.messages, ["3"])

        self.coordinator.handle(
            [SessionCompleted(set_count=3, elapsed=180.0)],
            snapshot(TimerPhase.COMPLETED, 3, 0.0),
            self.settings,
            False,
        )
        self.assertEqual(self.audio.completions, 1)
        self.assertEqual(self.speech.messages[-1], "训练完成。")

        silent_settings = AppSettings(sound_enabled=False, voice_enabled=False)
        self.coordinator.handle(
            [SessionCompleted(set_count=3, elapsed=180.0)],
            snapshot(TimerPhase.COMPLETED, 3, 0.0),
            silent_settings,
            False,
        )
        self.coordinator.handle(
            [threshold], snapshot(TimerPhase.WORK, 1, 2.8), self.settings, True
        )
        self.coordinator.handle([], snapshot(TimerPhase.WORK, 1), self.settings, False)
        self.assertEqual(self.audio.completions, 1)

        self.coordinator.stop()
        self.assertEqual(self.speech.stop_count, 1)


if __name__ == "__main__":
    unittest.main()
