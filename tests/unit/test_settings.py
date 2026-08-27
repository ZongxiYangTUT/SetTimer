from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from PySide6.QtCore import QSettings

from settimer.services.settings import (
    AppSettings,
    QtSettingsStore,
    ThemePreference,
)


class QtSettingsStoreTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        path = Path(self.temporary_directory.name) / "settings.ini"
        self.qsettings = QSettings(str(path), QSettings.Format.IniFormat)
        self.store = QtSettingsStore(self.qsettings)

    def tearDown(self) -> None:
        self.qsettings.clear()
        self.temporary_directory.cleanup()

    def test_missing_values_use_defaults(self) -> None:
        self.assertEqual(self.store.load(), AppSettings())

    def test_settings_round_trip(self) -> None:
        expected = AppSettings(
            work_seconds=45,
            rest_seconds=15,
            set_count=8,
            preparation_seconds=5,
            resume_countdown=False,
            countdown_enabled=False,
            voice_enabled=False,
            voice_id="kokoro:42",
            sound_enabled=True,
            theme=ThemePreference.DARK,
            always_on_top=True,
        )

        self.assertTrue(self.store.save(expected))
        self.assertEqual(self.store.load(), expected)

    def test_invalid_values_fall_back_individually(self) -> None:
        self.qsettings.setValue("session/work_seconds", 0)
        self.qsettings.setValue("session/rest_seconds", 4_000)
        self.qsettings.setValue("session/set_count", "many")
        self.qsettings.setValue("timer/preparation_seconds", 4)
        self.qsettings.setValue("audio/voice_enabled", "no")
        self.qsettings.setValue("audio/voice_id", "kokoro:999")
        self.qsettings.setValue("appearance/theme", "neon")

        loaded = self.store.load()

        self.assertEqual(loaded.work_seconds, 60)
        self.assertEqual(loaded.rest_seconds, 90)
        self.assertEqual(loaded.set_count, 5)
        self.assertEqual(loaded.preparation_seconds, 3)
        self.assertFalse(loaded.voice_enabled)
        self.assertEqual(loaded.voice_id, "kokoro:3")
        self.assertEqual(loaded.theme, ThemePreference.DARK)


if __name__ == "__main__":
    unittest.main()
