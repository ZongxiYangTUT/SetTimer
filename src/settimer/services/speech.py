from __future__ import annotations

import logging
from typing import Protocol

from PySide6.QtCore import QLocale
from PySide6.QtTextToSpeech import QTextToSpeech

logger = logging.getLogger(__name__)


class SpeechPort(Protocol):
    def speak(self, text: str) -> None: ...

    def stop(self) -> None: ...


class QtSpeechService:
    def __init__(self) -> None:
        self._engine: QTextToSpeech | None = None
        engines = QTextToSpeech.availableEngines()
        if not engines:
            logger.warning("speech_unavailable no Qt text-to-speech engine detected")
            return

        engine = QTextToSpeech()
        if engine.state() is QTextToSpeech.State.Error:
            logger.warning("speech_unavailable message=%s", engine.errorString())
            return
        engine.setLocale(QLocale(QLocale.Language.Chinese, QLocale.Country.China))
        engine.setRate(-0.1)
        engine.errorOccurred.connect(self._on_error)
        self._engine = engine
        logger.info("speech_ready engine=%s", engine.engine())

    def speak(self, text: str) -> None:
        if self._engine is None or not text.strip():
            return
        self._engine.stop()
        self._engine.say(text)

    def stop(self) -> None:
        if self._engine is not None:
            self._engine.stop()

    def _on_error(self, reason: QTextToSpeech.ErrorReason, message: str) -> None:
        logger.warning("speech_failed reason=%s message=%s", reason.name, message)
