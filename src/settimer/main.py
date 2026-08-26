from __future__ import annotations

import logging
import sys
from importlib import resources
from pathlib import Path

from PySide6.QtCore import QCoreApplication, QUrl
from PySide6.QtGui import QFontDatabase, QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtWidgets import QApplication

from settimer import __version__
from settimer.application.controller import AppController

logger = logging.getLogger(__name__)


def _configure_logging() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )


def _install_application_font(application: QGuiApplication, assets_directory: Path) -> None:
    font_path = assets_directory / "NotoSansSC-VariableFont_wght.ttf"
    font_id = QFontDatabase.addApplicationFont(str(font_path))
    if font_id < 0:
        logger.warning("font_load_failed path=%s", font_path)
        return
    families = QFontDatabase.applicationFontFamilies(font_id)
    if not families:
        logger.warning("font_load_failed no family returned path=%s", font_path)
        return
    font = application.font()
    font.setFamilies([families[0], *font.families()])
    application.setFont(font)
    logger.info("font_loaded family=%s", families[0])


def main() -> int:
    _configure_logging()
    QCoreApplication.setOrganizationName("SetTimer")
    QCoreApplication.setApplicationName("SetTimer")
    QCoreApplication.setApplicationVersion(__version__)
    QQuickStyle.setStyle("Basic")

    application = QApplication(sys.argv)
    package_directory = Path(str(resources.files("settimer")))
    assets_directory = package_directory / "assets"
    ui_directory = package_directory / "ui"
    _install_application_font(application, assets_directory)
    application.setWindowIcon(QIcon(str(assets_directory / "icon.svg")))

    controller = AppController()
    engine = QQmlApplicationEngine()
    engine.addImportPath(str(ui_directory))
    initial_properties: dict[str, object] = {"backend": controller}
    engine.setInitialProperties(initial_properties)
    engine.load(QUrl.fromLocalFile(str(ui_directory / "Main.qml")))
    if not engine.rootObjects():
        logger.critical("qml_load_failed path=%s", ui_directory / "Main.qml")
        controller.shutdown()
        return 1

    application.aboutToQuit.connect(controller.shutdown)
    logger.info("application_started version=%s", __version__)
    return application.exec()


if __name__ == "__main__":
    raise SystemExit(main())
