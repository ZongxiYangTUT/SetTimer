from __future__ import annotations

import unittest

from settimer.application.formatting import (
    format_clock,
    format_duration,
    format_estimate,
    format_spoken_duration,
)


class FormattingTests(unittest.TestCase):
    def test_clock_uses_ceiling_and_tabular_shape(self) -> None:
        self.assertEqual(format_clock(59.01), "01:00")
        self.assertEqual(format_clock(3_723), "01:02:03")

    def test_human_duration_omits_empty_units(self) -> None:
        self.assertEqual(format_duration(90), "1 分 30 秒")
        self.assertEqual(format_duration(120), "2 分钟")
        self.assertEqual(format_spoken_duration(90), "1分钟30秒")

    def test_estimate_rounds_up_minutes(self) -> None:
        self.assertEqual(format_estimate(59), "约 59 秒")
        self.assertEqual(format_estimate(61), "约 2 分钟")


if __name__ == "__main__":
    unittest.main()
