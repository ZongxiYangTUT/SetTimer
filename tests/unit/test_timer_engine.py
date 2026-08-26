from __future__ import annotations

import unittest

from settimer.domain.events import (
    CountdownThresholdReached,
    PhaseCompleted,
    PhaseStarted,
    SessionCompleted,
    SessionPaused,
    SessionReset,
    SessionResumed,
    SessionStarted,
)
from settimer.domain.models import SessionConfig, TimerPhase
from settimer.domain.timer_engine import InvalidTimerTransition, TimerEngine
from tests.fakes import FakeClock


class TimerEngineTests(unittest.TestCase):
    def setUp(self) -> None:
        self.clock = FakeClock()
        self.engine = TimerEngine(self.clock)
        self.config = SessionConfig(
            work_duration=10.0,
            rest_duration=5.0,
            set_count=3,
            preparation_duration=3.0,
            countdown_thresholds=(3, 2, 1),
        )

    def test_session_starts_in_preparation(self) -> None:
        events = self.engine.start(self.config)

        self.assertIsInstance(events[0], SessionStarted)
        self.assertEqual(events[1], PhaseStarted(TimerPhase.PREPARING, 1, 3.0))
        self.assertEqual(self.engine.snapshot().phase, TimerPhase.PREPARING)
        self.assertEqual(self.engine.snapshot().remaining, 3.0)

    def test_exact_preparation_deadline_starts_work(self) -> None:
        self.engine.start(self.config)
        self.clock.advance(3.0)

        events = self.engine.update()

        self.assertIn(PhaseCompleted(TimerPhase.PREPARING, 1), events)
        self.assertIn(PhaseStarted(TimerPhase.WORK, 1, 10.0), events)
        self.assertEqual(self.engine.snapshot().phase, TimerPhase.WORK)
        self.assertEqual(self.engine.snapshot().remaining, 10.0)

    def test_work_to_rest_and_rest_to_work_progress_sets(self) -> None:
        self.engine.start(SessionConfig(10.0, 5.0, 3, 0.0, ()))
        self.clock.advance(10.0)
        work_events = self.engine.update()
        self.assertEqual(
            work_events,
            [
                PhaseCompleted(TimerPhase.WORK, 1),
                PhaseStarted(TimerPhase.REST, 1, 5.0),
            ],
        )

        self.clock.advance(5.0)
        rest_events = self.engine.update()
        self.assertEqual(
            rest_events,
            [
                PhaseCompleted(TimerPhase.REST, 1),
                PhaseStarted(TimerPhase.WORK, 2, 10.0),
            ],
        )
        self.assertEqual(self.engine.snapshot().current_set, 2)

    def test_last_work_phase_completes_without_final_rest(self) -> None:
        self.engine.start(SessionConfig(4.0, 9.0, 1, 0.0, ()))
        self.clock.advance(4.0)

        events = self.engine.update()

        self.assertEqual(events[0], PhaseCompleted(TimerPhase.WORK, 1))
        self.assertEqual(events[1], SessionCompleted(1, 4.0))
        self.assertEqual(self.engine.snapshot().phase, TimerPhase.COMPLETED)

    def test_zero_rest_starts_the_next_set_at_the_same_boundary(self) -> None:
        self.engine.start(SessionConfig(3.0, 0.0, 2, 0.0, ()))
        self.clock.advance(3.0)

        events = self.engine.update()

        self.assertEqual(
            events,
            [
                PhaseCompleted(TimerPhase.WORK, 1),
                PhaseStarted(TimerPhase.WORK, 2, 3.0),
            ],
        )
        self.assertEqual(self.engine.snapshot().remaining, 3.0)

    def test_pause_and_resume_preserve_fractional_remaining_time(self) -> None:
        self.engine.start(SessionConfig(60.0, 10.0, 2, 0.0, ()))
        self.clock.advance(17.4)

        paused_events = self.engine.pause()

        self.assertEqual(paused_events[-1], SessionPaused(TimerPhase.WORK, 1, 42.6))
        self.clock.advance(100.0)
        self.assertAlmostEqual(self.engine.snapshot().remaining, 42.6)

        resumed_events = self.engine.resume()
        self.assertEqual(resumed_events, [SessionResumed(TimerPhase.WORK, 1, 42.6)])
        self.clock.advance(42.5)
        self.assertAlmostEqual(self.engine.snapshot().remaining, 0.1)

    def test_repeated_pause_resume_does_not_accumulate_drift(self) -> None:
        self.engine.start(SessionConfig(10.0, 0.0, 1, 0.0, ()))
        for _ in range(10):
            self.clock.advance(0.25)
            self.engine.pause()
            self.clock.advance(100.0)
            self.engine.resume()

        self.assertAlmostEqual(self.engine.snapshot().remaining, 7.5)
        self.clock.advance(7.5)
        self.assertIsInstance(self.engine.update()[-1], SessionCompleted)

    def test_delayed_update_catches_up_without_extending_deadlines(self) -> None:
        self.engine.start(SessionConfig(10.0, 5.0, 3, 0.0, ()))
        self.clock.advance(26.5)

        events = self.engine.update()

        self.assertEqual(
            events,
            [
                PhaseCompleted(TimerPhase.WORK, 1),
                PhaseStarted(TimerPhase.REST, 1, 5.0),
                PhaseCompleted(TimerPhase.REST, 1),
                PhaseStarted(TimerPhase.WORK, 2, 10.0),
                PhaseCompleted(TimerPhase.WORK, 2),
                PhaseStarted(TimerPhase.REST, 2, 5.0),
            ],
        )
        self.assertEqual(self.engine.snapshot().phase, TimerPhase.REST)
        self.assertAlmostEqual(self.engine.snapshot().remaining, 3.5)

    def test_duplicate_callback_at_deadline_is_idempotent(self) -> None:
        self.engine.start(SessionConfig(2.0, 2.0, 2, 0.0, ()))
        self.clock.advance(2.0)

        first_events = self.engine.update()
        duplicate_events = self.engine.update()

        self.assertEqual(len(first_events), 2)
        self.assertEqual(duplicate_events, [])
        self.assertEqual(self.engine.snapshot().phase, TimerPhase.REST)
        self.assertEqual(self.engine.snapshot().current_set, 1)

    def test_countdown_thresholds_emit_once(self) -> None:
        self.engine.start(SessionConfig(10.0, 0.0, 1, 0.0, (10, 3, 2, 1, 3)))

        initial = self.engine.update()
        duplicate = self.engine.update()
        self.clock.advance(7.1)
        final = self.engine.update()

        self.assertEqual(initial, [CountdownThresholdReached(TimerPhase.WORK, 1, 10)])
        self.assertEqual(duplicate, [])
        self.assertEqual(
            final,
            [CountdownThresholdReached(TimerPhase.WORK, 1, 3)],
        )

    def test_total_remaining_in_each_phase(self) -> None:
        self.engine.start(self.config)
        self.assertEqual(self.engine.snapshot().total_remaining, 43.0)
        self.clock.advance(3.0)
        self.engine.update()
        self.assertEqual(self.engine.snapshot().total_remaining, 40.0)
        self.clock.advance(10.0)
        self.engine.update()
        self.assertEqual(self.engine.snapshot().total_remaining, 30.0)

    def test_reset_is_idempotent_and_returns_to_idle(self) -> None:
        self.engine.start(self.config)
        self.assertEqual(self.engine.reset(), [SessionReset()])
        self.assertEqual(self.engine.reset(), [])
        self.assertEqual(self.engine.snapshot().phase, TimerPhase.IDLE)

    def test_illegal_commands_fail_visibly(self) -> None:
        with self.assertRaises(InvalidTimerTransition):
            self.engine.pause()
        with self.assertRaises(InvalidTimerTransition):
            self.engine.resume()
        self.engine.start(self.config)
        with self.assertRaises(InvalidTimerTransition):
            self.engine.start(self.config)

    def test_invalid_configuration_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            SessionConfig(0.0, 1.0, 1)
        with self.assertRaises(ValueError):
            SessionConfig(1.0, -1.0, 1)
        with self.assertRaises(ValueError):
            SessionConfig(1.0, 1.0, 0)
        with self.assertRaises(ValueError):
            SessionConfig(1.0, 1.0, 1, preparation_duration=-1.0)
        with self.assertRaises(ValueError):
            SessionConfig(1.0, 1.0, 1, countdown_thresholds=(0,))


if __name__ == "__main__":
    unittest.main()
