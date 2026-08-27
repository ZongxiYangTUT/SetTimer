from __future__ import annotations

import json
import logging
import os
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Protocol, cast

from PySide6.QtCore import QStandardPaths

logger = logging.getLogger(__name__)

_HISTORY_LIMIT = 200


@dataclass(frozen=True, slots=True)
class SessionRecord:
    started_at: datetime
    work_seconds: int
    rest_seconds: int
    set_count: int
    completed_sets: int
    elapsed_seconds: int
    completed: bool

    def to_json(self) -> dict[str, object]:
        return {
            "started_at": self.started_at.isoformat(),
            "work_seconds": self.work_seconds,
            "rest_seconds": self.rest_seconds,
            "set_count": self.set_count,
            "completed_sets": self.completed_sets,
            "elapsed_seconds": self.elapsed_seconds,
            "completed": self.completed,
        }

    @classmethod
    def from_json(cls, value: object) -> SessionRecord | None:
        if not isinstance(value, dict):
            return None
        raw = cast(dict[object, object], value)
        try:
            started_at_raw = raw["started_at"]
            if not isinstance(started_at_raw, str):
                return None
            started_at = datetime.fromisoformat(started_at_raw)
            if started_at.tzinfo is None:
                return None
            work_seconds = _validated_int(raw["work_seconds"], 1, 3_599)
            rest_seconds = _validated_int(raw["rest_seconds"], 0, 3_599)
            set_count = _validated_int(raw["set_count"], 1, 99)
            completed_sets = _validated_int(raw["completed_sets"], 0, set_count)
            elapsed_seconds = _validated_int(raw["elapsed_seconds"], 0, 30 * 24 * 3_600)
            completed = raw["completed"]
            if not isinstance(completed, bool):
                return None
        except (KeyError, TypeError, ValueError):
            return None
        return cls(
            started_at=started_at,
            work_seconds=work_seconds,
            rest_seconds=rest_seconds,
            set_count=set_count,
            completed_sets=completed_sets,
            elapsed_seconds=elapsed_seconds,
            completed=completed,
        )


class HistoryStore(Protocol):
    def load(self) -> tuple[SessionRecord, ...]: ...

    def save(self, records: tuple[SessionRecord, ...]) -> bool: ...


class JsonHistoryStore:
    def __init__(self, path: Path | None = None) -> None:
        self._path = path or self._default_path()

    def load(self) -> tuple[SessionRecord, ...]:
        if not self._path.exists():
            return ()
        try:
            raw_data = cast(object, json.loads(self._path.read_text(encoding="utf-8")))
        except (OSError, json.JSONDecodeError):
            logger.warning("history_load_failed path=%s", self._path, exc_info=True)
            return ()
        if not isinstance(raw_data, list):
            logger.warning("history_load_failed invalid root path=%s", self._path)
            return ()
        records: list[SessionRecord] = []
        for item in cast(list[object], raw_data):
            record = SessionRecord.from_json(item)
            if record is None:
                logger.warning("history_record_invalid path=%s", self._path)
                continue
            records.append(record)
        records.sort(key=lambda record: record.started_at, reverse=True)
        return tuple(records[:_HISTORY_LIMIT])

    def save(self, records: tuple[SessionRecord, ...]) -> bool:
        payload = [record.to_json() for record in records[:_HISTORY_LIMIT]]
        temporary_path = self._path.with_suffix(f"{self._path.suffix}.tmp")
        try:
            self._path.parent.mkdir(parents=True, exist_ok=True)
            temporary_path.write_text(
                json.dumps(payload, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
            os.replace(temporary_path, self._path)
        except OSError:
            logger.warning("history_save_failed path=%s", self._path, exc_info=True)
            return False
        return True

    @staticmethod
    def _default_path() -> Path:
        data_directory = QStandardPaths.writableLocation(
            QStandardPaths.StandardLocation.AppDataLocation
        )
        return Path(data_directory) / "history.json"


def _validated_int(value: object, minimum: int, maximum: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise TypeError("history integer field has invalid type")
    if not minimum <= value <= maximum:
        raise ValueError("history integer field is out of range")
    return value
