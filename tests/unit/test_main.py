from __future__ import annotations

import unittest
from collections.abc import Callable
from pathlib import Path
from typing import ClassVar, cast
from unittest.mock import patch

from PySide6.QtGui import QGuiApplication

from settimer import main as main_module


class FakeSignal:
    def __init__(self) -> None:
        self.callbacks: list[Callable[[], None]] = []

    def connect(self, callback: Callable[[], None]) -> None:
        self.callbacks.append(callback)


class FakeApplication:
    last_instance: FakeApplication | None = None

    def __init__(self, _arguments: list[str]) -> None:
        self.aboutToQuit = FakeSignal()
        self.window_icon: object | None = None
        FakeApplication.last_instance = self

    def setWindowIcon(self, icon: object) -> None:
        self.window_icon = icon

    def exec(self) -> int:
        return 27

    def quit(self) -> None:
        pass


class FakeController:
    last_instance: FakeController | None = None

    def __init__(self) -> None:
        self.shutdown_count = 0
        FakeController.last_instance = self

    def shutdown(self) -> None:
        self.shutdown_count += 1


class FakeEngine:
    should_load = True
    last_instance: FakeEngine | None = None

    def __init__(self) -> None:
        self.import_paths: list[str] = []
        self.initial_properties: dict[str, object] = {}
        self.loaded_url: object | None = None
        FakeEngine.last_instance = self

    def addImportPath(self, path: str) -> None:
        self.import_paths.append(path)

    def setInitialProperties(self, properties: dict[str, object]) -> None:
        self.initial_properties = properties

    def load(self, url: object) -> None:
        self.loaded_url = url

    def rootObjects(self) -> list[object]:
        return [object()] if self.should_load else []


class FakeCoreApplication:
    organization = ""
    application = ""
    version = ""

    @classmethod
    def setOrganizationName(cls, value: str) -> None:
        cls.organization = value

    @classmethod
    def setApplicationName(cls, value: str) -> None:
        cls.application = value

    @classmethod
    def setApplicationVersion(cls, value: str) -> None:
        cls.version = value


class FakeQuickStyle:
    style = ""

    @classmethod
    def setStyle(cls, value: str) -> None:
        cls.style = value


def fake_icon(path: str) -> str:
    return path


class FakeFont:
    def __init__(self) -> None:
        self.selected_families: list[str] = []

    def families(self) -> list[str]:
        return ["System Sans"]

    def setFamilies(self, families: list[str]) -> None:
        self.selected_families = families


class FakeGuiApplication:
    def __init__(self) -> None:
        self.application_font = FakeFont()
        self.installed_font: FakeFont | None = None

    def font(self) -> FakeFont:
        return self.application_font

    def setFont(self, font: FakeFont) -> None:
        self.installed_font = font


class FakeFontDatabase:
    font_id = 4
    families: ClassVar[list[str]] = ["Noto Sans SC"]

    @classmethod
    def addApplicationFont(cls, _path: str) -> int:
        return cls.font_id

    @classmethod
    def applicationFontFamilies(cls, _font_id: int) -> list[str]:
        return cls.families


class MainTests(unittest.TestCase):
    def setUp(self) -> None:
        FakeEngine.should_load = True
        FakeEngine.last_instance = None
        FakeApplication.last_instance = None
        FakeController.last_instance = None
        FakeFontDatabase.font_id = 4
        FakeFontDatabase.families = ["Noto Sans SC"]

    def test_main_wires_and_runs_the_desktop_application(self) -> None:
        with (
            patch.object(main_module, "QCoreApplication", FakeCoreApplication),
            patch.object(main_module, "QQuickStyle", FakeQuickStyle),
            patch.object(main_module, "QApplication", FakeApplication),
            patch.object(main_module, "AppController", FakeController),
            patch.object(main_module, "QQmlApplicationEngine", FakeEngine),
            patch.object(main_module, "QIcon", fake_icon),
            patch.object(main_module, "_install_application_font"),
        ):
            result = main_module.main()

        self.assertEqual(result, 27)
        self.assertEqual(FakeCoreApplication.organization, "SetTimer")
        self.assertEqual(FakeQuickStyle.style, "Basic")
        engine = FakeEngine.last_instance
        application = FakeApplication.last_instance
        assert engine is not None
        assert application is not None
        self.assertIn("backend", engine.initial_properties)
        self.assertEqual(len(application.aboutToQuit.callbacks), 1)

    def test_main_returns_failure_when_qml_cannot_load(self) -> None:
        FakeEngine.should_load = False
        with (
            patch.object(main_module, "QCoreApplication", FakeCoreApplication),
            patch.object(main_module, "QQuickStyle", FakeQuickStyle),
            patch.object(main_module, "QApplication", FakeApplication),
            patch.object(main_module, "AppController", FakeController),
            patch.object(main_module, "QQmlApplicationEngine", FakeEngine),
            patch.object(main_module, "QIcon", fake_icon),
            patch.object(main_module, "_install_application_font"),
        ):
            result = main_module.main()

        self.assertEqual(result, 1)
        controller = FakeController.last_instance
        assert controller is not None
        self.assertEqual(controller.shutdown_count, 1)

    def test_startup_check_quits_after_qml_loads(self) -> None:
        with (
            patch.dict("os.environ", {"SETTIMER_STARTUP_CHECK": "1"}, clear=False),
            patch.object(main_module, "QCoreApplication", FakeCoreApplication),
            patch.object(main_module, "QQuickStyle", FakeQuickStyle),
            patch.object(main_module, "QApplication", FakeApplication),
            patch.object(main_module, "AppController", FakeController),
            patch.object(main_module, "QQmlApplicationEngine", FakeEngine),
            patch.object(main_module, "QIcon", fake_icon),
            patch.object(main_module, "_install_application_font"),
            patch.object(main_module.QTimer, "singleShot") as single_shot,
        ):
            result = main_module.main()

        self.assertEqual(result, 27)
        application = FakeApplication.last_instance
        assert application is not None
        single_shot.assert_called_once_with(0, application.quit)

    def test_application_font_installation_handles_success_and_failures(self) -> None:
        application = FakeGuiApplication()
        typed_application = cast(QGuiApplication, cast(object, application))
        with patch.object(main_module, "QFontDatabase", FakeFontDatabase):
            main_module._install_application_font(  # pyright: ignore[reportPrivateUsage]
                typed_application, Path("assets")
            )
            self.assertEqual(
                application.application_font.selected_families,
                ["Noto Sans SC", "System Sans"],
            )
            self.assertIs(application.installed_font, application.application_font)

            FakeFontDatabase.font_id = -1
            main_module._install_application_font(  # pyright: ignore[reportPrivateUsage]
                typed_application, Path("assets")
            )
            FakeFontDatabase.font_id = 4
            FakeFontDatabase.families = []
            main_module._install_application_font(  # pyright: ignore[reportPrivateUsage]
                typed_application, Path("assets")
            )


if __name__ == "__main__":
    unittest.main()
