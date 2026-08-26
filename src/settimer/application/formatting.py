from __future__ import annotations

import math


def format_clock(seconds: float) -> str:
    total_seconds = math.ceil(max(0.0, seconds))
    hours, remainder = divmod(total_seconds, 3_600)
    minutes, final_seconds = divmod(remainder, 60)
    if hours:
        return f"{hours:02d}:{minutes:02d}:{final_seconds:02d}"
    return f"{minutes:02d}:{final_seconds:02d}"


def format_duration(seconds: int) -> str:
    minutes, final_seconds = divmod(max(0, seconds), 60)
    if minutes and final_seconds:
        return f"{minutes} 分 {final_seconds} 秒"
    if minutes:
        return f"{minutes} 分钟"
    return f"{final_seconds} 秒"


def format_spoken_duration(seconds: int) -> str:
    minutes, final_seconds = divmod(max(0, seconds), 60)
    pieces: list[str] = []
    if minutes:
        pieces.append(f"{minutes}分钟")
    if final_seconds:
        pieces.append(f"{final_seconds}秒")
    return "".join(pieces) or "0秒"


def format_estimate(seconds: int) -> str:
    if seconds < 60:
        return f"约 {seconds} 秒"
    return f"约 {math.ceil(seconds / 60)} 分钟"
