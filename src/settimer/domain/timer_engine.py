from __future__ import annotations

from settimer.domain.clock import Clock
from settimer.domain.events import (
    CountdownThresholdReached,
    PhaseCompleted,
    PhaseStarted,
    SessionCompleted,
    SessionPaused,
    SessionReset,
    SessionResumed,
    SessionStarted,
    TimerEvent,
)
from settimer.domain.models import ACTIVE_PHASES, SessionConfig, TimerPhase, TimerSnapshot


class InvalidTimerTransition(RuntimeError):
    """Raised when a command is not legal in the current explicit state."""


class TimerEngine:
    """Deterministic interval timer driven exclusively by a monotonic clock."""

    def __init__(self, clock: Clock) -> None:
        self._clock = clock
        self._config: SessionConfig | None = None
        self._phase = TimerPhase.IDLE
        self._paused_phase: TimerPhase | None = None
        self._current_set = 1
        self._phase_started_at = 0.0
        self._deadline = 0.0
        self._phase_duration = 0.0
        self._paused_remaining = 0.0
        self._paused_at = 0.0
        self._session_started_at = 0.0
        self._completed_at = 0.0
        self._total_paused = 0.0
        self._emitted_thresholds: set[int] = set()

    @property
    def phase(self) -> TimerPhase:
        return self._phase

    def start(self, config: SessionConfig) -> list[TimerEvent]:
        if self._phase not in {TimerPhase.IDLE, TimerPhase.COMPLETED}:
            raise InvalidTimerTransition(f"cannot start from {self._phase.value}")

        now = self._clock.now()
        self._config = config
        self._current_set = 1
        self._paused_phase = None
        self._paused_remaining = 0.0
        self._paused_at = 0.0
        self._session_started_at = now
        self._completed_at = 0.0
        self._total_paused = 0.0

        if config.preparation_duration > 0:
            phase = TimerPhase.PREPARING
            duration = config.preparation_duration
        else:
            phase = TimerPhase.WORK
            duration = config.work_duration
        self._enter_phase(phase, duration, now)
        return [
            SessionStarted(config),
            PhaseStarted(phase, self._current_set, duration),
        ]

    def update(self) -> list[TimerEvent]:
        if self._phase not in ACTIVE_PHASES:
            return []

        now = self._clock.now()
        events: list[TimerEvent] = []
        transition_count = 0

        while self._phase in ACTIVE_PHASES and now >= self._deadline:
            events.extend(self._countdown_events(0.0))
            boundary = self._deadline
            completed_phase = self._phase
            events.append(PhaseCompleted(completed_phase, self._current_set))
            transition_count += 1
            if transition_count > 2 * self._required_config().set_count + 2:
                raise RuntimeError("timer transition safety limit exceeded")

            if completed_phase is TimerPhase.PREPARING:
                self._enter_phase(
                    TimerPhase.WORK,
                    self._required_config().work_duration,
                    boundary,
                )
                events.append(
                    PhaseStarted(
                        TimerPhase.WORK,
                        self._current_set,
                        self._required_config().work_duration,
                    )
                )
                continue

            if completed_phase is TimerPhase.WORK:
                if self._current_set >= self._required_config().set_count:
                    self._phase = TimerPhase.COMPLETED
                    self._paused_phase = None
                    self._phase_started_at = boundary
                    self._deadline = boundary
                    self._phase_duration = 0.0
                    self._completed_at = boundary
                    events.append(
                        SessionCompleted(
                            self._required_config().set_count,
                            self._elapsed(boundary),
                        )
                    )
                    break

                if self._required_config().rest_duration > 0:
                    self._enter_phase(
                        TimerPhase.REST,
                        self._required_config().rest_duration,
                        boundary,
                    )
                    events.append(
                        PhaseStarted(
                            TimerPhase.REST,
                            self._current_set,
                            self._required_config().rest_duration,
                        )
                    )
                else:
                    self._current_set += 1
                    self._enter_phase(
                        TimerPhase.WORK,
                        self._required_config().work_duration,
                        boundary,
                    )
                    events.append(
                        PhaseStarted(
                            TimerPhase.WORK,
                            self._current_set,
                            self._required_config().work_duration,
                        )
                    )
                continue

            self._current_set += 1
            self._enter_phase(
                TimerPhase.WORK,
                self._required_config().work_duration,
                boundary,
            )
            events.append(
                PhaseStarted(
                    TimerPhase.WORK,
                    self._current_set,
                    self._required_config().work_duration,
                )
            )

        if self._phase in ACTIVE_PHASES:
            events.extend(self._countdown_events(max(0.0, self._deadline - now)))
        return events

    def pause(self) -> list[TimerEvent]:
        events = self.update()
        if self._phase not in {TimerPhase.WORK, TimerPhase.REST}:
            raise InvalidTimerTransition(f"cannot pause from {self._phase.value}")

        now = self._clock.now()
        self._paused_remaining = max(0.0, self._deadline - now)
        self._paused_phase = self._phase
        self._paused_at = now
        self._phase = TimerPhase.PAUSED
        events.append(
            SessionPaused(
                self._paused_phase,
                self._current_set,
                self._paused_remaining,
            )
        )
        return events

    def resume(self) -> list[TimerEvent]:
        if self._phase is not TimerPhase.PAUSED or self._paused_phase is None:
            raise InvalidTimerTransition(f"cannot resume from {self._phase.value}")

        now = self._clock.now()
        resumed_phase = self._paused_phase
        self._total_paused += max(0.0, now - self._paused_at)
        elapsed_in_phase = self._phase_duration - self._paused_remaining
        self._phase_started_at = now - elapsed_in_phase
        self._deadline = now + self._paused_remaining
        self._phase = resumed_phase
        self._paused_phase = None
        self._paused_at = 0.0
        return [SessionResumed(resumed_phase, self._current_set, self._paused_remaining)]

    def reset(self) -> list[TimerEvent]:
        if self._phase is TimerPhase.IDLE:
            return []
        self._config = None
        self._phase = TimerPhase.IDLE
        self._paused_phase = None
        self._current_set = 1
        self._phase_started_at = 0.0
        self._deadline = 0.0
        self._phase_duration = 0.0
        self._paused_remaining = 0.0
        self._paused_at = 0.0
        self._session_started_at = 0.0
        self._completed_at = 0.0
        self._total_paused = 0.0
        self._emitted_thresholds.clear()
        return [SessionReset()]

    def snapshot(self) -> TimerSnapshot:
        now = self._clock.now()
        if self._phase is TimerPhase.PAUSED:
            active_phase = self._paused_phase
            remaining = self._paused_remaining
        elif self._phase in ACTIVE_PHASES:
            active_phase = self._phase
            remaining = max(0.0, self._deadline - now)
        else:
            active_phase = None
            remaining = 0.0

        progress = (
            min(1.0, max(0.0, remaining / self._phase_duration))
            if self._phase_duration > 0
            else 0.0
        )
        return TimerSnapshot(
            phase=self._phase,
            active_phase=active_phase,
            current_set=self._current_set,
            total_sets=self._config.set_count if self._config is not None else 0,
            remaining=remaining,
            phase_duration=self._phase_duration,
            total_remaining=self._total_remaining(remaining, active_phase),
            elapsed=self._elapsed(now),
            progress=progress,
        )

    def _enter_phase(self, phase: TimerPhase, duration: float, started_at: float) -> None:
        if phase not in ACTIVE_PHASES:
            raise ValueError(f"{phase.value} is not an active phase")
        self._phase = phase
        self._paused_phase = None
        self._phase_started_at = started_at
        self._phase_duration = duration
        self._deadline = started_at + duration
        self._paused_remaining = 0.0
        self._emitted_thresholds.clear()

    def _countdown_events(self, remaining: float) -> list[TimerEvent]:
        events: list[TimerEvent] = []
        for threshold in self._required_config().countdown_thresholds:
            if remaining <= threshold and threshold not in self._emitted_thresholds:
                self._emitted_thresholds.add(threshold)
                events.append(
                    CountdownThresholdReached(
                        self._phase,
                        self._current_set,
                        threshold,
                    )
                )
        return events

    def _total_remaining(
        self,
        current_remaining: float,
        active_phase: TimerPhase | None,
    ) -> float:
        if active_phase is None or self._config is None:
            return 0.0
        future_sets = self._config.set_count - self._current_set
        if active_phase is TimerPhase.PREPARING:
            return (
                current_remaining
                + self._config.work_duration * self._config.set_count
                + self._config.rest_duration * (self._config.set_count - 1)
            )
        if active_phase is TimerPhase.WORK:
            return current_remaining + future_sets * (
                self._config.work_duration + self._config.rest_duration
            )
        return (
            current_remaining
            + future_sets * self._config.work_duration
            + max(0, future_sets - 1) * self._config.rest_duration
        )

    def _elapsed(self, now: float) -> float:
        if self._phase is TimerPhase.IDLE:
            return 0.0
        end = self._completed_at if self._phase is TimerPhase.COMPLETED else now
        active_pause = (
            max(0.0, now - self._paused_at) if self._phase is TimerPhase.PAUSED else 0.0
        )
        return max(
            0.0,
            end - self._session_started_at - self._total_paused - active_pause,
        )

    def _required_config(self) -> SessionConfig:
        if self._config is None:
            raise RuntimeError("timer has no active session configuration")
        return self._config
