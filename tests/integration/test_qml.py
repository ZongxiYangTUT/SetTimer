from __future__ import annotations

import os
import unittest
from importlib import resources
from pathlib import Path

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

from PySide6.QtCore import QCoreApplication, QEvent, QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication

from settimer.application.controller import AppController
from tests.fakes import (
    FakeAudio,
    FakeClock,
    FakePowerInhibitor,
    FakeSpeech,
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


if __name__ == "__main__":
    unittest.main()
