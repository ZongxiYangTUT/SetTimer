from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class TimerPhase(str, Enum):
    IDLE = "idle"
    PREPARING = "preparing"
    WORK = "work"
    REST = "rest"
    PAUSED = "paused"
    COMPLETED = "completed"


ACTIVE_PHASES = frozenset({TimerPhase.PREPARING, TimerPhase.WORK, TimerPhase.REST})


@dataclass(frozen=True, slots=True)
class SessionConfig:
    work_duration: float
    rest_duration: float
    set_count: int
    preparation_duration: float = 3.0
    countdown_thresholds: tuple[int, ...] = (3, 2, 1)

    def __post_init__(self) -> None:
        if self.work_duration <= 0:
            raise ValueError("work_duration must be greater than zero")
        if self.rest_duration < 0:
            raise ValueError("rest_duration cannot be negative")
        if self.set_count < 1:
            raise ValueError("set_count must be at least one")
        if self.preparation_duration < 0:
            raise ValueError("preparation_duration cannot be negative")
        if any(threshold <= 0 for threshold in self.countdown_thresholds):
            raise ValueError("countdown thresholds must be positive")
        normalized = tuple(sorted(set(self.countdown_thresholds), reverse=True))
        object.__setattr__(self, "countdown_thresholds", normalized)


@dataclass(frozen=True, slots=True)
class TimerSnapshot:
    phase: TimerPhase
    active_phase: TimerPhase | None
    current_set: int
    total_sets: int
    remaining: float
    phase_duration: float
    total_remaining: float
    elapsed: float
    progress: float
