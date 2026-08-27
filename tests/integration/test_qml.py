from __future__ import annotations

import os
import unittest
from importlib import resources
from pathlib import Path
from typing import cast

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

from PySide6.QtCore import QCoreApplication, QEvent, QObject, QPointF, Qt, QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickItem, QQuickWindow
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication

from settimer.application.controller import AppController, Screen
from tests.fakes import (
    FakeAudio,
    FakeClock,
    FakePowerInhibitor,
    FakeSpeech,
    MemoryHistoryStore,
    MemorySettingsStore,
)


class QmlSmokeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.application = QApplication.instance() or QApplication([])

    def test_main_qml_loads_with_the_typed_controller_boundary(self) -> None:
        controller = AppController(
            clock=FakeClock(),
            settings_store=MemorySettingsStore(),
            speech=FakeSpeech(),
            audio=FakeAudio(),
            power=FakePowerInhibitor(),
            history_store=MemoryHistoryStore(),
            auto_start_updates=False,
        )
        engine = QQmlApplicationEngine()
        ui_directory = Path(str(resources.files("settimer") / "ui"))
        engine.addImportPath(str(ui_directory))
        engine.setInitialProperties({"backend": controller})

        try:
            engine.load(QUrl.fromLocalFile(str(ui_directory / "Main.qml")))
            self.application.processEvents()
            roots = engine.rootObjects()
            self.assertEqual(len(roots), 1)
            self.assertEqual(roots[0].property("title"), "SetTimer")
            roots[0].setProperty("visible", False)
        finally:
            engine.deleteLater()
            QCoreApplication.sendPostedEvents(None, QEvent.Type.DeferredDelete)
            self.application.processEvents()
            controller.shutdown()

    def test_home_wheel_and_long_press_stop_are_wired(self) -> None:
        controller = AppController(
            clock=FakeClock(),
            settings_store=MemorySettingsStore(),
            speech=FakeSpeech(),
            audio=FakeAudio(),
            power=FakePowerInhibitor(),
            history_store=MemoryHistoryStore(),
            auto_start_updates=False,
        )
        engine = QQmlApplicationEngine()
        ui_directory = Path(str(resources.files("settimer") / "ui"))
        engine.addImportPath(str(ui_directory))
        engine.setInitialProperties({"backend": controller})

        try:
            engine.load(QUrl.fromLocalFile(str(ui_directory / "Main.qml")))
            self.application.processEvents()
            roots = engine.rootObjects()
            self.assertEqual(len(roots), 1)
            window = cast(QQuickWindow, roots[0])
            self.assertIsInstance(window, QQuickWindow)

            work_picker = cast(QObject, window.findChild(QObject, "workPicker"))
            work_picker.setProperty("currentIndex", 4)
            QTest.qWait(180)
            self.assertEqual(controller.work_seconds, 150)

            controller.start_session()
            QTest.qWait(80)
            stop_button = cast(QQuickItem, window.findChild(QQuickItem, "stopHoldButton"))
            stop_button.setProperty("holdDuration", 500)
            center = stop_button.mapToItem(
                window.contentItem(),
                QPointF(stop_button.width() / 2, stop_button.height() / 2),
            ).toPoint()
            QTest.mousePress(
                window,
                Qt.MouseButton.LeftButton,
                Qt.KeyboardModifier.NoModifier,
                center,
            )
            QTest.qWait(40)
            QTest.mouseRelease(
                window,
                Qt.MouseButton.LeftButton,
                Qt.KeyboardModifier.NoModifier,
                center,
            )
            self.assertEqual(controller.screen, int(Screen.TIMER))

            stop_button.setProperty("holdDuration", 60)
            QTest.mousePress(
                window,
                Qt.MouseButton.LeftButton,
                Qt.KeyboardModifier.NoModifier,
                center,
            )
            QTest.qWait(100)
            self.assertEqual(controller.screen, int(Screen.HOME))
            QTest.mouseRelease(
                window,
                Qt.MouseButton.LeftButton,
                Qt.KeyboardModifier.NoModifier,
                center,
            )
            window.setProperty("visible", False)
        finally:
            engine.deleteLater()
            QCoreApplication.sendPostedEvents(None, QEvent.Type.DeferredDelete)
            self.application.processEvents()
            controller.shutdown()


if __name__ == "__main__":
    unittest.main()
