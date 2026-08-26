from __future__ import annotations

from typing import Protocol


class Clock(Protocol):
    """Monotonic time source used by the timer domain."""

    def now(self) -> float:
        """Return a monotonically increasing time in seconds."""
        ...
