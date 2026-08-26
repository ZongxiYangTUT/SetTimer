from __future__ import annotations

import ctypes
import logging
import sys
from typing import Protocol, cast

from PySide6.QtDBus import QDBusConnection, QDBusInterface, QDBusMessage

logger = logging.getLogger(__name__)


class PowerInhibitor(Protocol):
    def acquire(self) -> None: ...

    def release(self) -> None: ...


class _ExecutionStateFunction(Protocol):
    argtypes: list[object]
    restype: object

    def __call__(self, flags: int, /) -> int: ...


class _Kernel32Library(Protocol):
    SetThreadExecutionState: _ExecutionStateFunction


class _WindowsDllLoader(Protocol):
    kernel32: _Kernel32Library


class NullPowerInhibitor:
    def acquire(self) -> None:
        logger.warning("power_inhibition_unavailable platform=%s", sys.platform)

    def release(self) -> None:
        return


class LinuxPowerInhibitor:
    def __init__(self) -> None:
        connection = QDBusConnection.sessionBus()
        self._interface = QDBusInterface(
            "org.freedesktop.ScreenSaver",
            "/org/freedesktop/ScreenSaver",
            "org.freedesktop.ScreenSaver",
            connection,
        )
        self._cookie: int | None = None

    def acquire(self) -> None:
        if self._cookie is not None:
            return
        if not self._interface.isValid():
            logger.warning("power_inhibition_unavailable screensaver D-Bus service missing")
            return
        reply = self._interface.call("Inhibit", "SetTimer", "训练计时正在进行")
        if reply.type() is QDBusMessage.MessageType.ErrorMessage or not reply.arguments():
            logger.warning("power_inhibition_failed error=%s", reply.errorMessage())
            return
        cookie = reply.arguments()[0]
        if isinstance(cookie, int):
            self._cookie = cookie
            logger.info("power_inhibition_acquired")
        else:
            logger.warning("power_inhibition_failed invalid cookie=%r", cookie)

    def release(self) -> None:
        if self._cookie is None:
            return
        reply = self._interface.call("UnInhibit", self._cookie)
        if reply.type() is QDBusMessage.MessageType.ErrorMessage:
            logger.warning("power_inhibition_release_failed error=%s", reply.errorMessage())
        else:
            logger.info("power_inhibition_released")
        self._cookie = None


class WindowsPowerInhibitor:
    _ES_CONTINUOUS = 0x80000000
    _ES_SYSTEM_REQUIRED = 0x00000001
    _ES_DISPLAY_REQUIRED = 0x00000002

    def __init__(self) -> None:
        loader_name = "windll"
        loader = cast(_WindowsDllLoader, getattr(ctypes, loader_name))
        self._set_execution_state = loader.kernel32.SetThreadExecutionState
        self._set_execution_state.argtypes = [ctypes.c_uint]
        self._set_execution_state.restype = ctypes.c_uint
        self._active = False

    def acquire(self) -> None:
        flags = self._ES_CONTINUOUS | self._ES_SYSTEM_REQUIRED | self._ES_DISPLAY_REQUIRED
        if not self._set_execution_state(flags):
            logger.warning(
                "power_inhibition_failed windows SetThreadExecutionState returned zero"
            )
            return
        self._active = True
        logger.info("power_inhibition_acquired")

    def release(self) -> None:
        if not self._active:
            return
        if not self._set_execution_state(self._ES_CONTINUOUS):
            logger.warning("power_inhibition_release_failed windows API returned zero")
        self._active = False


def create_power_inhibitor() -> PowerInhibitor:
    if sys.platform == "win32":
        return WindowsPowerInhibitor()
    if sys.platform.startswith("linux"):
        return LinuxPowerInhibitor()
    return NullPowerInhibitor()
