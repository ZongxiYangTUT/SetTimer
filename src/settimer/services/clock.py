from __future__ import annotations

import time


class SystemMonotonicClock:
    def now(self) -> float:
        return time.monotonic()
