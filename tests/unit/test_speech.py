from __future__ import annotations

import tempfile
import unittest
import wave
from pathlib import Path

from settimer.services import speech


class SpeechServiceTests(unittest.TestCase):
    def test_kokoro_catalog_contains_chinese_female_and_male_voices(self) -> None:
        voices = speech.kokoro_voice_options()

        self.assertEqual(len(voices), 100)
        self.assertEqual(voices[0].identifier, "kokoro:3")
        self.assertEqual(voices[0].label, "女声 01")
        self.assertEqual(voices[54].label, "女声 55")
        self.assertEqual(voices[55].identifier, "kokoro:58")
        self.assertEqual(voices[-1].label, "男声 45")

    def test_model_validation_requires_every_runtime_asset(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            model_directory = Path(temporary_directory)
            self.assertFalse(speech.kokoro_model_is_complete(model_directory))

            for name in speech.KOKORO_REQUIRED_FILES:
                path = model_directory / name
                if "." in name:
                    path.touch()
                else:
                    path.mkdir()

            self.assertTrue(speech.kokoro_model_is_complete(model_directory))

    def test_cache_path_is_stable_and_separates_speakers(self) -> None:
        cache_directory = Path("cache")
        first = speech._cache_path(  # pyright: ignore[reportPrivateUsage]
            cache_directory, "训练完成。", 3
        )
        repeated = speech._cache_path(  # pyright: ignore[reportPrivateUsage]
            cache_directory, "训练完成。", 3
        )
        another_voice = speech._cache_path(  # pyright: ignore[reportPrivateUsage]
            cache_directory, "训练完成。", 4
        )

        self.assertEqual(first, repeated)
        self.assertNotEqual(first, another_voice)
        self.assertEqual(first.parent, cache_directory)

    def test_kokoro_text_uses_chinese_number_words(self) -> None:
        normalize = speech._normalize_kokoro_text  # pyright: ignore[reportPrivateUsage]

        self.assertEqual(normalize("第 1 组开始。"), "第一组开始。")
        self.assertEqual(normalize("休息15秒。"), "休息十五秒。")
        self.assertEqual(normalize("倒计时 3、2、1。"), "倒计时三、二、一。")
        self.assertEqual(
            normalize("第 21 组，休息101秒。"),  # noqa: RUF001
            "第二十一组，休息一百零一秒。",  # noqa: RUF001
        )

    def test_pcm_writer_produces_a_valid_mono_wave(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            output_path = Path(temporary_directory) / "preview.wav"

            speech._write_pcm_wave(  # pyright: ignore[reportPrivateUsage]
                output_path,
                [-1.5, -0.5, 0.0, 0.5, 1.5],
                24_000,
            )

            with wave.open(str(output_path), "rb") as stream:
                self.assertEqual(stream.getnchannels(), 1)
                self.assertEqual(stream.getsampwidth(), 2)
                self.assertEqual(stream.getframerate(), 24_000)
                self.assertEqual(stream.getnframes(), 5)


if __name__ == "__main__":
    unittest.main()
