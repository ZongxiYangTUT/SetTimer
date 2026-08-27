from __future__ import annotations

import hashlib
import logging
import os
import re
import sys
import threading
import wave
from array import array
from collections.abc import Callable, Iterable
from dataclasses import dataclass
from importlib import import_module
from pathlib import Path
from typing import Any, Protocol, cast

from PySide6.QtCore import (
    QBuffer,
    QByteArray,
    QIODeviceBase,
    QLocale,
    QObject,
    QStandardPaths,
    QTimer,
    Signal,
    Slot,
)
from PySide6.QtMultimedia import QAudioFormat, QAudioSink, QMediaDevices
from PySide6.QtTextToSpeech import QTextToSpeech, QVoice

logger = logging.getLogger(__name__)

KOKORO_MODEL_DIRECTORY = "kokoro-int8-multi-lang-v1_1"
KOKORO_REQUIRED_FILES = (
    "model.int8.onnx",
    "voices.bin",
    "tokens.txt",
    "lexicon-us-en.txt",
    "lexicon-zh.txt",
    "espeak-ng-data",
    "phone-zh.fst",
    "date-zh.fst",
    "number-zh.fst",
)
KOKORO_DEFAULT_VOICE_ID = "kokoro:3"
SYSTEM_VOICE_ID = "system:default"
VOICE_PREVIEW_TEXT = "第一组开始，准备训练。"  # noqa: RUF001 - Chinese punctuation
_ARABIC_NUMBER_PATTERN = re.compile(r"\d+")
_CHINESE_WHITESPACE_PATTERN = re.compile(r"(?<=[\u3400-\u9fff])\s+(?=[\u3400-\u9fff])")
_CHINESE_DIGITS = "零一二三四五六七八九"
_CHINESE_SMALL_UNITS = ("", "十", "百", "千")


@dataclass(frozen=True, slots=True)
class SpeechVoice:
    identifier: str
    label: str


class SpeechPort(Protocol):
    def speak(self, text: str) -> None: ...

    def stop(self) -> None: ...

    def voice_options(self) -> tuple[SpeechVoice, ...]: ...

    def selected_voice_id(self) -> str: ...

    def select_voice(self, identifier: str) -> bool: ...

    def preview(self, identifier: str) -> None: ...

    def shutdown(self) -> None: ...


def default_kokoro_model_directory() -> Path:
    data_root = Path(
        QStandardPaths.writableLocation(QStandardPaths.StandardLocation.GenericDataLocation)
    )
    return data_root / "SetTimer" / "voices" / KOKORO_MODEL_DIRECTORY


def kokoro_model_is_complete(model_directory: Path) -> bool:
    return all((model_directory / name).exists() for name in KOKORO_REQUIRED_FILES)


def kokoro_voice_options() -> tuple[SpeechVoice, ...]:
    female = tuple(
        SpeechVoice(f"kokoro:{speaker_id}", f"女声 {speaker_id - 2:02d}")
        for speaker_id in range(3, 58)
    )
    male = tuple(
        SpeechVoice(f"kokoro:{speaker_id}", f"男声 {speaker_id - 57:02d}")
        for speaker_id in range(58, 103)
    )
    return female + male


def _system_voice_identifier(voice: QVoice) -> str:
    fingerprint = f"{voice.name()}\0{voice.locale().name()}".casefold().encode()
    digest = hashlib.sha256(fingerprint).hexdigest()[:16]
    return f"system:{digest}"


def _integer_to_chinese(value: int) -> str:
    if value == 0:
        return _CHINESE_DIGITS[0]
    if value >= 10_000:
        return "".join(_CHINESE_DIGITS[int(digit)] for digit in str(value))

    digits = str(value)
    result: list[str] = []
    zero_pending = False
    for index, digit_text in enumerate(digits):
        digit = int(digit_text)
        unit_index = len(digits) - index - 1
        if digit == 0:
            if result and any(character != "0" for character in digits[index + 1 :]):
                zero_pending = True
            continue
        if zero_pending:
            result.append(_CHINESE_DIGITS[0])
            zero_pending = False
        if not (digit == 1 and unit_index == 1 and not result):
            result.append(_CHINESE_DIGITS[digit])
        result.append(_CHINESE_SMALL_UNITS[unit_index])
    return "".join(result)


def _normalize_kokoro_text(text: str) -> str:
    normalized = _ARABIC_NUMBER_PATTERN.sub(
        lambda match: _integer_to_chinese(int(match.group())),
        text,
    )
    return _CHINESE_WHITESPACE_PATTERN.sub("", normalized)


def _default_speech_cache_directory() -> Path:
    cache_root = Path(
        QStandardPaths.writableLocation(QStandardPaths.StandardLocation.CacheLocation)
    )
    return cache_root / "speech"


def _cache_path(cache_directory: Path, text: str, speaker_id: int) -> Path:
    digest = hashlib.sha256(f"kokoro-v1.1-int8-zh2\0{speaker_id}\0{text}".encode()).hexdigest()
    return cache_directory / f"{digest}.wav"


class _GeneratedAudio(Protocol):
    @property
    def samples(self) -> Iterable[float]: ...

    @property
    def sample_rate(self) -> int: ...


class _OfflineTtsEngine(Protocol):
    def generate(self, *, text: str, sid: int, speed: float) -> _GeneratedAudio: ...


class _KokoroSynthesizer:
    def __init__(self, model_directory: Path) -> None:
        self._engine = _create_kokoro_engine(model_directory)

    def synthesize(self, text: str, speaker_id: int, output_path: Path) -> None:
        audio = self._engine.generate(text=text, sid=speaker_id, speed=1.0)
        _write_pcm_wave(output_path, audio.samples, audio.sample_rate)


def _create_kokoro_engine(model_directory: Path) -> _OfflineTtsEngine:
    # sherpa-onnx has no type stubs. Keep the dynamic dependency boundary in
    # this one factory and expose only the typed protocol above.
    module = cast(Any, import_module("sherpa_onnx"))
    config = module.OfflineTtsConfig(
        model=module.OfflineTtsModelConfig(
            kokoro=module.OfflineTtsKokoroModelConfig(
                model=str(model_directory / "model.int8.onnx"),
                voices=str(model_directory / "voices.bin"),
                tokens=str(model_directory / "tokens.txt"),
                data_dir=str(model_directory / "espeak-ng-data"),
                lexicon=",".join(
                    (
                        str(model_directory / "lexicon-us-en.txt"),
                        str(model_directory / "lexicon-zh.txt"),
                    )
                ),
            ),
            num_threads=max(1, min(4, os.cpu_count() or 1)),
            debug=False,
        ),
        rule_fsts=",".join(
            str(model_directory / name)
            for name in ("phone-zh.fst", "date-zh.fst", "number-zh.fst")
        ),
    )
    if not config.validate():
        raise RuntimeError("Kokoro model configuration is invalid")
    return cast(_OfflineTtsEngine, module.OfflineTts(config))


def _write_pcm_wave(output_path: Path, samples: Iterable[float], sample_rate: int) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = output_path.with_suffix(".wav.tmp")
    pcm = array(
        "h",
        (round(max(-1.0, min(1.0, float(sample))) * 32_767) for sample in samples),
    )
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(temporary_path), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(sample_rate)
        stream.writeframes(pcm.tobytes())
    temporary_path.replace(output_path)


@dataclass(frozen=True, slots=True)
class _SpeechRequest:
    token: int
    text: str
    speaker_id: int
    output_path: Path


class _KokoroWorker:
    def __init__(
        self,
        model_directory: Path,
        on_ready: Callable[[int, str, Path], None],
        on_failed: Callable[[int, str, str], None],
        synthesizer_factory: Callable[[Path], _KokoroSynthesizer] = _KokoroSynthesizer,
    ) -> None:
        self._model_directory = model_directory
        self._on_ready = on_ready
        self._on_failed = on_failed
        self._synthesizer_factory = synthesizer_factory
        self._condition = threading.Condition()
        self._pending: _SpeechRequest | None = None
        self._closed = False
        self._thread = threading.Thread(
            target=self._run,
            name="SetTimer-Kokoro",
            daemon=True,
        )
        self._thread.start()

    def submit(self, request: _SpeechRequest) -> None:
        with self._condition:
            if self._closed:
                return
            self._pending = request
            self._condition.notify()

    def cancel_pending(self) -> None:
        with self._condition:
            self._pending = None

    def shutdown(self) -> None:
        with self._condition:
            self._closed = True
            self._pending = None
            self._condition.notify()
        self._thread.join(timeout=3.0)

    def _run(self) -> None:
        synthesizer: _KokoroSynthesizer | None = None
        while True:
            with self._condition:
                while not self._closed and self._pending is None:
                    self._condition.wait()
                if self._closed:
                    return
                request = self._pending
                self._pending = None
            if request is None:
                continue
            try:
                if not request.output_path.exists():
                    if synthesizer is None:
                        synthesizer = self._synthesizer_factory(self._model_directory)
                    synthesizer.synthesize(
                        request.text,
                        request.speaker_id,
                        request.output_path,
                    )
                with self._condition:
                    if self._closed:
                        return
                self._on_ready(request.token, request.text, request.output_path)
            except Exception as error:
                # This is the optional third-party runtime boundary. Preserve the
                # timer and report the failure so the desktop service can fall back.
                logger.warning("kokoro_synthesis_failed message=%s", error)
                with self._condition:
                    if self._closed:
                        return
                self._on_failed(request.token, request.text, str(error))


class _SpeechSignals(QObject):
    ready = Signal(int, str, str)
    failed = Signal(int, str, str)


class DesktopSpeechService(QObject):
    """Use an optional local Kokoro model with Windows speech as fallback."""

    def __init__(
        self,
        parent: QObject | None = None,
        *,
        model_directory: Path | None = None,
        cache_directory: Path | None = None,
    ) -> None:
        super().__init__(parent)
        self._system_engine = self._create_system_engine()
        self._system_voices: dict[str, QVoice] = {}
        self._default_system_voice_id = SYSTEM_VOICE_ID
        system_voice_options = self._load_system_voices()
        self._request_token = 0
        self._selected_voice_id = SYSTEM_VOICE_ID
        self._sink: QAudioSink | None = None
        self._buffer: QBuffer | None = None
        self._playback_token = 0
        self._closed = False
        self._signals = _SpeechSignals(self)
        self._signals.ready.connect(self._on_kokoro_ready)
        self._signals.failed.connect(self._on_kokoro_failed)

        resolved_model_directory = model_directory or default_kokoro_model_directory()
        resolved_cache_directory = cache_directory or _default_speech_cache_directory()
        self._worker: _KokoroWorker | None = None
        if kokoro_model_is_complete(resolved_model_directory) and _sherpa_onnx_available():
            resolved_cache_directory.mkdir(parents=True, exist_ok=True)
            self._voices = system_voice_options + kokoro_voice_options()
            self._selected_voice_id = KOKORO_DEFAULT_VOICE_ID
            self._worker = _KokoroWorker(
                resolved_model_directory,
                lambda token, text, path: self._signals.ready.emit(token, text, str(path)),
                lambda token, text, message: self._signals.failed.emit(token, text, message),
            )
            self._cache_directory = resolved_cache_directory
            logger.info("kokoro_ready model=%s", resolved_model_directory)
        else:
            self._voices = system_voice_options or (SpeechVoice(SYSTEM_VOICE_ID, "系统语音"),)
            self._selected_voice_id = self._default_system_voice_id
            self._cache_directory = resolved_cache_directory
            logger.info("kokoro_unavailable using Windows speech")

    def speak(self, text: str) -> None:
        self._speak_with_voice(text, self._selected_voice_id)

    def stop(self) -> None:
        self._request_token += 1
        if self._worker is not None:
            self._worker.cancel_pending()
        if self._system_engine is not None:
            self._system_engine.stop()
        self._release_playback()

    def voice_options(self) -> tuple[SpeechVoice, ...]:
        return self._voices

    def selected_voice_id(self) -> str:
        return self._selected_voice_id

    def select_voice(self, identifier: str) -> bool:
        resolved_identifier = self._resolve_voice_identifier(identifier)
        if not any(voice.identifier == resolved_identifier for voice in self._voices):
            return False
        self._selected_voice_id = resolved_identifier
        return True

    def preview(self, identifier: str) -> None:
        resolved_identifier = self._resolve_voice_identifier(identifier)
        if any(voice.identifier == resolved_identifier for voice in self._voices):
            self._speak_with_voice(VOICE_PREVIEW_TEXT, resolved_identifier)

    def shutdown(self) -> None:
        if self._closed:
            return
        self.stop()
        self._closed = True
        if self._worker is not None:
            self._worker.shutdown()

    def _speak_with_voice(self, text: str, identifier: str) -> None:
        normalized = text.strip()
        if self._closed or not normalized:
            return
        self.stop()
        token = self._request_token
        if identifier.startswith("kokoro:") and self._worker is not None:
            try:
                speaker_id = int(identifier.partition(":")[2])
            except ValueError:
                self._say_with_system(normalized, self._default_system_voice_id)
                return
            kokoro_text = _normalize_kokoro_text(normalized)
            self._worker.submit(
                _SpeechRequest(
                    token=token,
                    text=kokoro_text,
                    speaker_id=speaker_id,
                    output_path=_cache_path(
                        self._cache_directory,
                        kokoro_text,
                        speaker_id,
                    ),
                )
            )
            return
        self._say_with_system(normalized, identifier)

    @Slot(int, str, str)
    def _on_kokoro_ready(self, token: int, text: str, path: str) -> None:
        if self._closed or token != self._request_token:
            return
        if not self._play_wave(Path(path), token):
            self._say_with_system(text, self._default_system_voice_id)

    @Slot(int, str, str)
    def _on_kokoro_failed(self, token: int, text: str, _message: str) -> None:
        if self._closed or token != self._request_token:
            return
        self._say_with_system(text, self._default_system_voice_id)

    def _play_wave(self, path: Path, token: int) -> bool:
        try:
            with wave.open(str(path), "rb") as stream:
                channel_count = stream.getnchannels()
                sample_width = stream.getsampwidth()
                sample_rate = stream.getframerate()
                frame_count = stream.getnframes()
                audio_bytes = stream.readframes(frame_count)
        except (OSError, wave.Error) as error:
            logger.warning("speech_cache_read_failed path=%s message=%s", path, error)
            return False
        if channel_count != 1 or sample_width != 2 or sample_rate <= 0:
            logger.warning("speech_cache_format_unsupported path=%s", path)
            return False

        device = QMediaDevices.defaultAudioOutput()
        if device.isNull():
            logger.warning("speech_audio_unavailable no default output device")
            return False
        audio_format = QAudioFormat()
        audio_format.setSampleRate(sample_rate)
        audio_format.setChannelCount(channel_count)
        audio_format.setSampleFormat(QAudioFormat.SampleFormat.Int16)
        if not device.isFormatSupported(audio_format):
            logger.warning("speech_audio_format_unsupported sample_rate=%s", sample_rate)
            return False

        buffer = QBuffer(self)
        buffer.setData(QByteArray(audio_bytes))
        if not buffer.open(QIODeviceBase.OpenModeFlag.ReadOnly):
            logger.warning("speech_audio_buffer_open_failed")
            return False
        sink = QAudioSink(device, audio_format, self)
        sink.setVolume(1.0)
        self._sink = sink
        self._buffer = buffer
        self._playback_token = token
        sink.start(buffer)
        duration_ms = round(frame_count * 1_000 / sample_rate)
        QTimer.singleShot(duration_ms + 250, lambda: self._release_playback(token))
        return True

    def _release_playback(self, token: int | None = None) -> None:
        if token is not None and token != self._playback_token:
            return
        sink = self._sink
        buffer = self._buffer
        self._sink = None
        self._buffer = None
        self._playback_token = 0
        if sink is not None:
            sink.stop()
            sink.deleteLater()
        if buffer is not None:
            buffer.close()
            buffer.deleteLater()

    def _say_with_system(self, text: str, identifier: str) -> None:
        if self._system_engine is None:
            logger.warning("speech_unavailable no Windows speech engine")
            return
        voice = self._system_voices.get(identifier)
        if voice is not None:
            self._system_engine.setVoice(voice)
        self._system_engine.stop()
        self._system_engine.say(text)

    def _load_system_voices(self) -> tuple[SpeechVoice, ...]:
        if self._system_engine is None:
            return ()
        current_voice = self._system_engine.voice()
        current_fingerprint = (current_voice.name(), current_voice.locale().name())
        options: list[SpeechVoice] = []
        for voice in self._system_engine.availableVoices():
            identifier = _system_voice_identifier(voice)
            if identifier in self._system_voices:
                continue
            self._system_voices[identifier] = voice
            name = voice.name().strip() or f"语音 {len(options) + 1}"
            options.append(SpeechVoice(identifier, f"系统 · {name}"))
            if (voice.name(), voice.locale().name()) == current_fingerprint:
                self._default_system_voice_id = identifier
        if options and self._default_system_voice_id == SYSTEM_VOICE_ID:
            self._default_system_voice_id = options[0].identifier
        return tuple(options)

    def _resolve_voice_identifier(self, identifier: str) -> str:
        if identifier == SYSTEM_VOICE_ID:
            return self._default_system_voice_id
        return identifier

    def _create_system_engine(self) -> QTextToSpeech | None:
        engines = QTextToSpeech.availableEngines()
        if not engines:
            logger.warning("speech_unavailable no Qt text-to-speech engine detected")
            return None
        engine = QTextToSpeech(self)
        if engine.state() is QTextToSpeech.State.Error:
            logger.warning("speech_unavailable message=%s", engine.errorString())
            engine.deleteLater()
            return None
        engine.setLocale(QLocale(QLocale.Language.Chinese, QLocale.Country.China))
        engine.setRate(-0.1)
        engine.errorOccurred.connect(self._on_system_error)
        logger.info("system_speech_ready engine=%s", engine.engine())
        return engine

    @Slot(QTextToSpeech.ErrorReason, str)
    def _on_system_error(self, reason: QTextToSpeech.ErrorReason, message: str) -> None:
        logger.warning("speech_failed reason=%s message=%s", reason.name, message)


def _sherpa_onnx_available() -> bool:
    try:
        import_module("sherpa_onnx")
    except (ImportError, OSError) as error:
        logger.warning("kokoro_runtime_unavailable message=%s", error)
        return False
    return True
