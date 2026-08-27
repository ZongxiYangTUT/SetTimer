from __future__ import annotations

import logging
from dataclasses import dataclass
from enum import Enum
from typing import Protocol

from PySide6.QtCore import QSettings

logger = logging.getLogger(__name__)


class ThemePreference(str, Enum):
    SYSTEM = "system"
    LIGHT = "light"
    DARK = "dark"


@dataclass(frozen=True, slots=True)
class AppSettings:
    work_seconds: int = 60
    rest_seconds: int = 90
    set_count: int = 5
    preparation_seconds: int = 3
    resume_countdown: bool = True
    countdown_enabled: bool = True
    voice_enabled: bool = True
    voice_id: str = "kokoro:3"
    sound_enabled: bool = True
    theme: ThemePreference = ThemePreference.DARK
    always_on_top: bool = False


class SettingsStore(Protocol):
    def load(self) -> AppSettings: ...

    def save(self, settings: AppSettings) -> bool: ...


class QtSettingsStore:
    """Typed boundary around Qt's platform-native settings storage."""

    def __init__(self, settings: QSettings | None = None) -> None:
        self._settings = settings or QSettings("SetTimer", "SetTimer")

    def load(self) -> AppSettings:
        defaults = AppSettings()
        return AppSettings(
            work_seconds=self._read_int("session/work_seconds", defaults.work_seconds, 1, 3599),
            rest_seconds=self._read_int("session/rest_seconds", defaults.rest_seconds, 0, 3599),
            set_count=self._read_int("session/set_count", defaults.set_count, 1, 99),
            preparation_seconds=self._read_choice(
                "timer/preparation_seconds",
                defaults.preparation_seconds,
                {0, 3, 5},
            ),
            resume_countdown=self._read_bool(
                "timer/resume_countdown",
                defaults.resume_countdown,
            ),
            countdown_enabled=self._read_bool(
                "timer/countdown_enabled",
                defaults.countdown_enabled,
            ),
            voice_enabled=self._read_bool("audio/voice_enabled", defaults.voice_enabled),
            voice_id=self._read_voice_id(defaults.voice_id),
            sound_enabled=self._read_bool("audio/sound_enabled", defaults.sound_enabled),
            theme=self._read_theme(defaults.theme),
            always_on_top=self._read_bool("window/always_on_top", defaults.always_on_top),
        )

    def save(self, settings: AppSettings) -> bool:
        values: tuple[tuple[str, object], ...] = (
            ("session/work_seconds", settings.work_seconds),
            ("session/rest_seconds", settings.rest_seconds),
            ("session/set_count", settings.set_count),
            ("timer/preparation_seconds", settings.preparation_seconds),
            ("timer/resume_countdown", settings.resume_countdown),
            ("timer/countdown_enabled", settings.countdown_enabled),
            ("audio/voice_enabled", settings.voice_enabled),
            ("audio/voice_id", settings.voice_id),
            ("audio/sound_enabled", settings.sound_enabled),
            ("appearance/theme", settings.theme.value),
            ("window/always_on_top", settings.always_on_top),
        )
        for key, value in values:
            self._settings.setValue(key, value)
        self._settings.sync()
        if self._settings.status() is not QSettings.Status.NoError:
            logger.warning("settings_save_failed status=%s", self._settings.status().name)
            return False
        return True

    def _read_int(self, key: str, default: int, minimum: int, maximum: int) -> int:
        raw: object = self._settings.value(key, default)
        if isinstance(raw, bool):
            return default
        try:
            parsed = int(raw)  # type: ignore[arg-type]
        except (TypeError, ValueError):
            logger.warning("settings_value_invalid key=%s value=%r", key, raw)
            return default
        return parsed if minimum <= parsed <= maximum else default

    def _read_choice(self, key: str, default: int, choices: set[int]) -> int:
        value = self._read_int(key, default, min(choices), max(choices))
        return value if value in choices else default

    def _read_bool(self, key: str, default: bool) -> bool:
        raw: object = self._settings.value(key, default)
        if isinstance(raw, bool):
            return raw
        if isinstance(raw, str):
            normalized = raw.strip().casefold()
            if normalized in {"true", "1", "yes", "on"}:
                return True
            if normalized in {"false", "0", "no", "off"}:
                return False
        logger.warning("settings_value_invalid key=%s value=%r", key, raw)
        return default

    def _read_theme(self, default: ThemePreference) -> ThemePreference:
        raw: object = self._settings.value("appearance/theme", default.value)
        try:
            return ThemePreference(str(raw))
        except ValueError:
            logger.warning("settings_value_invalid key=appearance/theme value=%r", raw)
            return default

    def _read_voice_id(self, default: str) -> str:
        raw: object = self._settings.value("audio/voice_id", default)
        value = str(raw).strip()
        if value == "system:default":
            return value
        prefix, separator, speaker = value.partition(":")
        if prefix == "kokoro" and separator and speaker.isdecimal():
            speaker_id = int(speaker)
            if 3 <= speaker_id <= 102:
                return value
        logger.warning("settings_value_invalid key=audio/voice_id value=%r", raw)
        return default
