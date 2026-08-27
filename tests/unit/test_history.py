from __future__ import annotations

import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

from settimer.application.history_model import (
    HistoryListModel,
    HistoryRole,
    format_weekly_elapsed,
    weekly_records,
)
from settimer.services.history import JsonHistoryStore, SessionRecord


class HistoryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.now = datetime(2026, 8, 27, 14, 30, tzinfo=timezone.utc)

    def test_json_store_round_trips_and_skips_invalid_records(self) -> None:
        record = self._record(self.now, completed=True)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "history.json"
            store = JsonHistoryStore(path)
            self.assertTrue(store.save((record,)))
            self.assertEqual(store.load(), (record,))

            path.write_text('[{"started_at": "bad"}]', encoding="utf-8")
            self.assertEqual(store.load(), ())

    def test_model_groups_records_and_exposes_semantic_roles(self) -> None:
        today = self._record(self.now.replace(hour=9), completed=True)
        yesterday = self._record(self.now - timedelta(days=1), completed=False)
        model = HistoryListModel((today, yesterday), lambda: self.now)

        today_index = model.index(0)
        yesterday_index = model.index(1)
        self.assertEqual(model.data(today_index, HistoryRole.SECTION_LABEL), "今天")
        self.assertEqual(model.data(today_index, HistoryRole.TIME_LABEL), "09:30")
        self.assertEqual(
            model.data(today_index, HistoryRole.SUMMARY),
            "5组 \N{MULTIPLICATION SIGN} 3:00 训练 + 1:00 休息",
        )
        self.assertEqual(model.data(yesterday_index, HistoryRole.SECTION_LABEL), "昨天")
        self.assertFalse(model.data(yesterday_index, HistoryRole.COMPLETED))

    def test_weekly_summary_counts_only_completed_sessions(self) -> None:
        completed = self._record(self.now, completed=True)
        interrupted = self._record(self.now - timedelta(days=1), completed=False)
        older = self._record(self.now - timedelta(days=14), completed=True)

        records = weekly_records((completed, interrupted, older), self.now)
        self.assertEqual(records, (completed,))
        self.assertEqual(format_weekly_elapsed(4_320), "1 小时 12 分")

    def _record(self, started_at: datetime, *, completed: bool) -> SessionRecord:
        return SessionRecord(
            started_at=started_at,
            work_seconds=180,
            rest_seconds=60,
            set_count=5,
            completed_sets=5 if completed else 2,
            elapsed_seconds=1_200,
            completed=completed,
        )


if __name__ == "__main__":
    unittest.main()
