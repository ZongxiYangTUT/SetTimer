from __future__ import annotations

from collections.abc import Callable, Sequence
from datetime import datetime, timedelta
from enum import IntEnum

from PySide6.QtCore import (
    QAbstractListModel,
    QByteArray,
    QModelIndex,
    QPersistentModelIndex,
    Qt,
)

from settimer.application.formatting import format_clock
from settimer.services.history import SessionRecord

_WEEKDAY_LABELS = ("周一", "周二", "周三", "周四", "周五", "周六", "周日")
_INVALID_INDEX = QModelIndex()


class HistoryRole(IntEnum):
    SECTION_LABEL = int(Qt.ItemDataRole.UserRole) + 1
    TIME_LABEL = int(Qt.ItemDataRole.UserRole) + 2
    SUMMARY = int(Qt.ItemDataRole.UserRole) + 3
    ELAPSED_TEXT = int(Qt.ItemDataRole.UserRole) + 4
    COMPLETED = int(Qt.ItemDataRole.UserRole) + 5
    COMPLETED_SETS = int(Qt.ItemDataRole.UserRole) + 6


class HistoryListModel(QAbstractListModel):
    def __init__(
        self,
        records: Sequence[SessionRecord],
        now_provider: Callable[[], datetime],
    ) -> None:
        super().__init__()
        self._records = tuple(records)
        self._now_provider = now_provider

    def rowCount(
        self,
        parent: QModelIndex | QPersistentModelIndex = _INVALID_INDEX,
    ) -> int:
        return 0 if parent.isValid() else len(self._records)

    def data(
        self,
        index: QModelIndex | QPersistentModelIndex,
        role: int = int(Qt.ItemDataRole.DisplayRole),
    ) -> object:
        if not index.isValid() or not 0 <= index.row() < len(self._records):
            return None
        record = self._records[index.row()]
        if role == HistoryRole.SECTION_LABEL:
            return _section_label(record.started_at, self._now_provider())
        if role == HistoryRole.TIME_LABEL:
            return _time_label(record.started_at, self._now_provider())
        if role == HistoryRole.SUMMARY:
            return (
                f"{record.set_count}组 \N{MULTIPLICATION SIGN} "
                f"{_short_clock(record.work_seconds)} 训练"
                f" + {_short_clock(record.rest_seconds)} 休息"
            )
        if role == HistoryRole.ELAPSED_TEXT:
            return format_clock(record.elapsed_seconds)
        if role == HistoryRole.COMPLETED:
            return record.completed
        if role == HistoryRole.COMPLETED_SETS:
            return f"{record.completed_sets} / {record.set_count}"
        return None

    def roleNames(self) -> dict[int, QByteArray]:
        return {
            HistoryRole.SECTION_LABEL: QByteArray(b"sectionLabel"),
            HistoryRole.TIME_LABEL: QByteArray(b"timeLabel"),
            HistoryRole.SUMMARY: QByteArray(b"summary"),
            HistoryRole.ELAPSED_TEXT: QByteArray(b"elapsedText"),
            HistoryRole.COMPLETED: QByteArray(b"completed"),
            HistoryRole.COMPLETED_SETS: QByteArray(b"completedSets"),
        }

    def set_records(self, records: Sequence[SessionRecord]) -> None:
        self.beginResetModel()
        self._records = tuple(records)
        self.endResetModel()


def is_current_week(timestamp: datetime, now: datetime) -> bool:
    timestamp_week = timestamp.astimezone(now.tzinfo).isocalendar()
    now_week = now.isocalendar()
    return timestamp_week.year == now_week.year and timestamp_week.week == now_week.week


def weekly_records(
    records: Sequence[SessionRecord], now: datetime
) -> tuple[SessionRecord, ...]:
    return tuple(
        record
        for record in records
        if record.completed and is_current_week(record.started_at, now)
    )


def format_weekly_elapsed(seconds: int) -> str:
    hours, remainder = divmod(max(0, seconds), 3_600)
    minutes = remainder // 60
    if hours and minutes:
        return f"{hours} 小时 {minutes} 分"
    if hours:
        return f"{hours} 小时"
    return f"{minutes} 分钟"


def _section_label(timestamp: datetime, now: datetime) -> str:
    local_date = timestamp.astimezone(now.tzinfo).date()
    today = now.date()
    if local_date == today:
        return "今天"
    if local_date == today - timedelta(days=1):
        return "昨天"
    if is_current_week(timestamp, now):
        return "本周"
    return "更早"


def _time_label(timestamp: datetime, now: datetime) -> str:
    local = timestamp.astimezone(now.tzinfo)
    if local.date() in {now.date(), now.date() - timedelta(days=1)}:
        return local.strftime("%H:%M")
    return f"{local.month}月{local.day}日 {_WEEKDAY_LABELS[local.weekday()]} · {local:%H:%M}"


def _short_clock(seconds: int) -> str:
    minutes, final_seconds = divmod(max(0, seconds), 60)
    return f"{minutes}:{final_seconds:02d}"
