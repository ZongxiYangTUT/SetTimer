from __future__ import annotations

import os
import re
import unittest
from importlib import resources
from pathlib import Path
from typing import cast

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

from PySide6.QtCore import QCoreApplication, QEvent, QObject, QPoint, QPointF, Qt, QUrl
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

    def test_visible_labels_do_not_include_english_explanations(self) -> None:
        ui_directory = Path(str(resources.files("settimer") / "ui"))
        english_explanation = re.compile(r'"[^"\n]*\([A-Za-z][A-Za-z /_-]*\)[^"\n]*"')

        for qml_path in ui_directory.rglob("*.qml"):
            source = qml_path.read_text(encoding="utf-8")
            self.assertIsNone(
                english_explanation.search(source),
                f"界面仍包含英文括注: {qml_path}",
            )

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
            set_picker = cast(QObject, window.findChild(QObject, "setPicker"))
            set_picker.setProperty("currentIndex", 6)
            rest_picker = cast(QObject, window.findChild(QObject, "restPicker"))
            rest_picker.setProperty("currentIndex", 4)
            self.application.processEvents()
            self.assertEqual(controller.work_seconds, 150)
            self.assertEqual(controller.set_count, 7)
            self.assertEqual(controller.rest_seconds, 60)

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
            controller.open_history()
            QTest.qWait(80)
            history_list = cast(
                QQuickItem,
                window.findChild(QQuickItem, "historyList"),
            )
            history_scroll_bar = cast(
                QQuickItem,
                window.findChild(QQuickItem, "historyScrollBar"),
            )
            self.assertFalse(history_scroll_bar.isVisible())
            history_card = next(
                item
                for item in history_list.childItems()[0].childItems()
                if item.objectName() == "historyRecordCard"
            )
            history_center = history_card.mapToItem(
                window.contentItem(),
                QPointF(history_card.width() / 2, history_card.height() / 2),
            ).toPoint()
            QTest.mousePress(
                window,
                Qt.MouseButton.LeftButton,
                Qt.KeyboardModifier.NoModifier,
                history_center,
            )
            QTest.mouseMove(window, history_center + QPoint(-140, 0), 40)
            QTest.mouseRelease(
                window,
                Qt.MouseButton.LeftButton,
                Qt.KeyboardModifier.NoModifier,
                history_center + QPoint(-140, 0),
            )
            QTest.qWait(220)
            self.assertEqual(controller.history_record_count, 1)

            delete_button = cast(
                QQuickItem,
                history_card.findChild(QQuickItem, "historyDeleteButton"),
            )
            delete_center = delete_button.mapToItem(
                window.contentItem(),
                QPointF(delete_button.width() / 2, delete_button.height() / 2),
            ).toPoint()
            QTest.mouseClick(
                window,
                Qt.MouseButton.LeftButton,
                Qt.KeyboardModifier.NoModifier,
                delete_center,
            )
            QTest.qWait(80)
            self.assertEqual(controller.history_record_count, 0)
            window.setProperty("visible", False)
        finally:
            engine.deleteLater()
            QCoreApplication.sendPostedEvents(None, QEvent.Type.DeferredDelete)
            self.application.processEvents()
            controller.shutdown()


if __name__ == "__main__":
    unittest.main()
