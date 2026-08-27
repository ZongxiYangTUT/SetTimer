from __future__ import annotations

import os
import unittest
from datetime import datetime, timezone

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

from PySide6.QtWidgets import QApplication

from settimer.application.controller import AppController, Screen
from settimer.services.settings import AppSettings, ThemePreference
from tests.fakes import (
    FakeAudio,
    FakeClock,
    FakePowerInhibitor,
    FakeSpeech,
    MemoryHistoryStore,
    MemorySettingsStore,
)


class AppControllerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.application = QApplication.instance() or QApplication([])

    def setUp(self) -> None:
        self.clock = FakeClock()
        self.store = MemorySettingsStore(
            AppSettings(
                work_seconds=2,
                rest_seconds=1,
                set_count=2,
                preparation_seconds=0,
                resume_countdown=True,
                countdown_enabled=False,
                voice_enabled=True,
                sound_enabled=True,
                theme=ThemePreference.LIGHT,
            )
        )
        self.speech = FakeSpeech()
        self.audio = FakeAudio()
        self.power = FakePowerInhibitor()
        self.history = MemoryHistoryStore()
        self.wall_time = datetime(2026, 8, 27, 14, 30, tzinfo=timezone.utc)
        self.controller = AppController(
            clock=self.clock,
            settings_store=self.store,
            speech=self.speech,
            audio=self.audio,
            power=self.power,
            history_store=self.history,
            wall_now=lambda: self.wall_time,
            auto_start_updates=False,
        )

    def tearDown(self) -> None:
        self.controller.shutdown()

    def test_complete_session_flow_without_real_waiting(self) -> None:
        self.controller.start_session()
        self.assertEqual(self.controller.screen, Screen.TIMER)
        self.assertEqual(self.controller.phase_key, "work")
        self.assertTrue(self.power.active)

        self.clock.advance(2)
        self.controller.refresh()
        self.assertEqual(self.controller.phase_key, "rest")

        self.clock.advance(1)
        self.controller.refresh()
        self.assertEqual(self.controller.current_set, 2)
        self.assertEqual(self.controller.phase_key, "work")

        self.clock.advance(2)
        self.controller.refresh()
        self.assertEqual(self.controller.screen, Screen.COMPLETE)
        self.assertFalse(self.power.active)
        self.assertEqual(self.audio.completions, 1)
        self.assertEqual(self.speech.messages[-1], "训练完成。")
        self.assertEqual(len(self.history.records), 1)
        record = self.history.records[0]
        self.assertTrue(record.completed)
        self.assertEqual(record.completed_sets, 2)
        self.assertEqual(record.elapsed_seconds, 5)
        self.controller.delete_history_record(0)
        self.assertEqual(self.controller.history_record_count, 0)
        self.assertEqual(self.history.records, ())
        self.controller.delete_history_record(99)

    def test_resume_countdown_uses_the_injected_monotonic_clock(self) -> None:
        self.store.settings = AppSettings(
            work_seconds=10,
            rest_seconds=0,
            set_count=1,
            preparation_seconds=0,
            resume_countdown=True,
            countdown_enabled=False,
        )
        self.controller.shutdown()
        self.controller = AppController(
            clock=self.clock,
            settings_store=self.store,
            speech=self.speech,
            audio=self.audio,
            power=self.power,
            history_store=self.history,
            wall_now=lambda: self.wall_time,
            auto_start_updates=False,
        )
        self.controller.start_session()
        self.clock.advance(2)
        self.controller.pause_or_resume()
        self.assertTrue(self.controller.paused)

        self.controller.pause_or_resume()
        self.clock.advance(2.9)
        self.controller.refresh()
        self.assertEqual(self.controller.resume_count, 1)
        self.assertTrue(self.controller.paused)

        self.clock.advance(0.1)
        self.controller.refresh()
        self.assertEqual(self.controller.resume_count, 0)
        self.assertFalse(self.controller.paused)
        self.assertEqual(self.controller.remaining_text, "00:08")

    def test_setting_commands_are_typed_and_persisted(self) -> None:
        self.controller.set_work_seconds(0)
        self.controller.set_rest_seconds(4_000)
        self.controller.set_set_count(0)
        self.controller.set_theme("dark")

        self.assertEqual(self.store.settings.work_seconds, 1)
        self.assertEqual(self.store.settings.rest_seconds, 3_599)
        self.assertEqual(self.store.settings.set_count, 1)
        self.assertEqual(self.store.settings.theme, ThemePreference.DARK)
        self.assertEqual(self.store.save_count, 4)

    def test_navigation_pause_mute_and_stop_flow(self) -> None:
        self.controller.open_settings()
        self.assertEqual(self.controller.screen, Screen.SETTINGS)
        self.controller.close_settings()
        self.assertEqual(self.controller.screen, Screen.HOME)
        self.controller.open_history()
        self.assertEqual(self.controller.screen, Screen.HISTORY)
        self.controller.close_history()
        self.assertEqual(self.controller.screen, Screen.HOME)

        self.controller.start_session()
        self.controller.start_session()
        self.controller.pause_or_resume()
        self.assertTrue(self.controller.paused)

        self.controller.toggle_muted()
        self.assertTrue(self.controller.muted)
        self.assertEqual(self.speech.stop_count, 1)
        self.controller.toggle_muted()
        self.assertFalse(self.controller.muted)

        self.controller.stop_session()
        self.assertEqual(self.controller.screen, Screen.HOME)
        self.assertEqual(self.controller.phase_key, "idle")
        self.assertFalse(self.power.active)
        self.assertEqual(len(self.history.records), 1)
        self.assertFalse(self.history.records[0].completed)

        self.controller.pause_or_resume()
        self.assertFalse(self.controller.paused)

    def test_resume_countdown_can_be_cancelled(self) -> None:
        self.controller.start_session()
        self.controller.pause_or_resume()
        self.controller.pause_or_resume()
        self.assertEqual(self.controller.resume_count, 3)

        self.controller.pause_or_resume()

        self.assertEqual(self.controller.resume_count, 0)
        self.assertTrue(self.controller.paused)

    def test_resume_without_countdown_is_immediate(self) -> None:
        self.store.settings = AppSettings(
            work_seconds=10,
            rest_seconds=0,
            set_count=1,
            preparation_seconds=0,
            resume_countdown=False,
        )
        self.controller.shutdown()
        self.controller = AppController(
            clock=self.clock,
            settings_store=self.store,
            speech=self.speech,
            audio=self.audio,
            power=self.power,
            history_store=self.history,
            wall_now=lambda: self.wall_time,
            auto_start_updates=False,
        )
        self.controller.start_session()
        self.controller.pause_or_resume()
        self.controller.pause_or_resume()

        self.assertFalse(self.controller.paused)

    def test_all_setting_commands_normalize_and_persist(self) -> None:
        self.controller.set_preparation_seconds(42)
        self.controller.set_resume_countdown_enabled(False)
        self.controller.set_countdown_enabled(False)
        self.controller.set_voice_enabled(False)
        self.controller.set_sound_enabled(False)
        self.controller.set_always_on_top(True)
        self.controller.set_theme("unknown")

        self.assertEqual(self.store.settings.preparation_seconds, 3)
        self.assertFalse(self.store.settings.resume_countdown)
        self.assertFalse(self.store.settings.countdown_enabled)
        self.assertFalse(self.store.settings.voice_enabled)
        self.assertFalse(self.store.settings.sound_enabled)
        self.assertTrue(self.store.settings.always_on_top)
        self.assertEqual(self.store.settings.theme, ThemePreference.LIGHT)
        self.assertEqual(self.store.save_count, 6)


if __name__ == "__main__":
    unittest.main()
