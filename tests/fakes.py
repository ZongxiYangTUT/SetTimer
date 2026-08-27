from __future__ import annotations

from settimer.services.history import SessionRecord
from settimer.services.settings import AppSettings


class FakeClock:
    def __init__(self, initial: float = 0.0) -> None:
        self._now = initial

    def now(self) -> float:
        return self._now

    def advance(self, seconds: float) -> None:
        if seconds < 0:
            raise ValueError("fake clock cannot move backwards")
        self._now += seconds


class MemorySettingsStore:
    def __init__(self, settings: AppSettings | None = None) -> None:
        self.settings = settings or AppSettings()
        self.save_count = 0

    def load(self) -> AppSettings:
        return self.settings

    def save(self, settings: AppSettings) -> bool:
        self.settings = settings
        self.save_count += 1
        return True


class MemoryHistoryStore:
    def __init__(self, records: tuple[SessionRecord, ...] = ()) -> None:
        self.records = records
        self.save_count = 0

    def load(self) -> tuple[SessionRecord, ...]:
        return self.records

    def save(self, records: tuple[SessionRecord, ...]) -> bool:
        self.records = records
        self.save_count += 1
        return True


class FakeSpeech:
    def __init__(self) -> None:
        self.messages: list[str] = []
        self.stop_count = 0

    def speak(self, text: str) -> None:
        self.messages.append(text)

    def stop(self) -> None:
        self.stop_count += 1


class FakeAudio:
    def __init__(self) -> None:
        self.ticks: list[int] = []
        self.phase_changes = 0
        self.completions = 0

    def play_tick(self, seconds: int) -> None:
        self.ticks.append(seconds)

    def play_phase_change(self) -> None:
        self.phase_changes += 1

    def play_completion(self) -> None:
        self.completions += 1


class FakePowerInhibitor:
    def __init__(self) -> None:
        self.active = False
        self.acquire_count = 0
        self.release_count = 0

    def acquire(self) -> None:
        self.active = True
        self.acquire_count += 1

    def release(self) -> None:
        if self.active:
            self.release_count += 1
        self.active = False
