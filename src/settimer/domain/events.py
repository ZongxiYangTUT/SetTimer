from __future__ import annotations

from dataclasses import dataclass

from settimer.domain.models import SessionConfig, TimerPhase


@dataclass(frozen=True, slots=True)
class SessionStarted:
    config: SessionConfig


@dataclass(frozen=True, slots=True)
class PhaseStarted:
    phase: TimerPhase
    set_number: int
    duration: float


@dataclass(frozen=True, slots=True)
class CountdownThresholdReached:
    phase: TimerPhase
    set_number: int
    seconds: int


@dataclass(frozen=True, slots=True)
class PhaseCompleted:
    phase: TimerPhase
    set_number: int


@dataclass(frozen=True, slots=True)
class SessionPaused:
    phase: TimerPhase
    set_number: int
    remaining: float


@dataclass(frozen=True, slots=True)
class SessionResumed:
    phase: TimerPhase
    set_number: int
    remaining: float


@dataclass(frozen=True, slots=True)
class SessionCompleted:
    set_count: int
    elapsed: float


@dataclass(frozen=True, slots=True)
class SessionReset:
    pass


TimerEvent = (
    SessionStarted
    | PhaseStarted
    | CountdownThresholdReached
    | PhaseCompleted
    | SessionPaused
    | SessionResumed
    | SessionCompleted
    | SessionReset
)
