from __future__ import annotations

import logging
import math
from array import array
from typing import Protocol

from PySide6.QtCore import QBuffer, QByteArray, QIODeviceBase, QObject, QTimer
from PySide6.QtMultimedia import QAudioFormat, QAudioSink, QMediaDevices
from PySide6.QtWidgets import QApplication

logger = logging.getLogger(__name__)


class AudioPort(Protocol):
    def play_tick(self, seconds: int) -> None: ...

    def play_phase_change(self) -> None: ...

    def play_completion(self) -> None: ...


class QtAudioService(QObject):
    """Generate short in-memory tones without external media assets."""

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._players: list[tuple[QAudioSink, QBuffer]] = []

    def play_tick(self, seconds: int) -> None:
        self._play_tone(700.0 + (3 - min(3, seconds)) * 70.0, 90)

    def play_phase_change(self) -> None:
        self._play_tone(640.0, 120)

    def play_completion(self) -> None:
        self._play_tone(620.0, 120)
        QTimer.singleShot(150, lambda: self._play_tone(790.0, 140))
        QTimer.singleShot(320, lambda: self._play_tone(940.0, 180))

    def _play_tone(self, frequency: float, duration_ms: int) -> None:
        device = QMediaDevices.defaultAudioOutput()
        if device.isNull():
            logger.warning("audio_unavailable no default output device")
            QApplication.beep()
            return

        audio_format = QAudioFormat()
        audio_format.setSampleRate(44_100)
        audio_format.setChannelCount(1)
        audio_format.setSampleFormat(QAudioFormat.SampleFormat.Int16)
        if not device.isFormatSupported(audio_format):
            logger.warning("audio_format_unsupported falling back to system beep")
            QApplication.beep()
            return

        sample_count = round(audio_format.sampleRate() * duration_ms / 1_000)
        fade_samples = max(1, round(audio_format.sampleRate() * 0.012))
        samples = array("h")
        for index in range(sample_count):
            fade_in = min(1.0, index / fade_samples)
            fade_out = min(1.0, (sample_count - index) / fade_samples)
            envelope = min(fade_in, fade_out)
            value = math.sin(2.0 * math.pi * frequency * index / audio_format.sampleRate())
            samples.append(round(4_500 * envelope * value))

        buffer = QBuffer(self)
        buffer.setData(QByteArray(samples.tobytes()))
        if not buffer.open(QIODeviceBase.OpenModeFlag.ReadOnly):
            logger.warning("audio_buffer_open_failed")
            return
        sink = QAudioSink(device, audio_format, self)
        sink.setVolume(0.8)
        player = (sink, buffer)
        self._players.append(player)
        sink.start(buffer)
        QTimer.singleShot(duration_ms + 250, lambda: self._release_player(player))

    def _release_player(self, player: tuple[QAudioSink, QBuffer]) -> None:
        if player not in self._players:
            return
        sink, buffer = player
        sink.stop()
        buffer.close()
        self._players.remove(player)
        sink.deleteLater()
        buffer.deleteLater()
