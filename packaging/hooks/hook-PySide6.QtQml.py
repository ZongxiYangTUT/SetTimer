"""Collect only the QML modules used by SetTimer.

PyInstaller's stock QtQml hook bundles every QML module shipped by PySide6,
including WebEngine and 3D.  SetTimer only imports QtQml and the QtQuick modules
listed below.
"""

from PyInstaller.utils.hooks.qt import add_qt6_dependencies, pyside6_library_info

hiddenimports, binaries, datas = add_qt6_dependencies(__file__)
qml_binaries, qml_datas = pyside6_library_info.collect_qtqml_files()

_QML_ROOT = "PySide6/qml/"
_REQUIRED_MODULES = {
    "QtCore",
    "QtQml",
    "QtQml/Models",
    "QtQml/WorkerScript",
    "QtQuick",
    "QtQuick/Controls",
    "QtQuick/Controls/Basic",
    "QtQuick/Controls/Basic/impl",
    "QtQuick/Controls/impl",
    "QtQuick/Layouts",
    "QtQuick/Shapes",
    "QtQuick/Templates",
    "QtQuick/Window",
}


def _is_required(entry: tuple[str, str]) -> bool:
    destination = entry[1].replace("\\", "/")
    if not destination.startswith(_QML_ROOT):
        return False
    module = destination.removeprefix(_QML_ROOT)
    return module in _REQUIRED_MODULES


binaries += [entry for entry in qml_binaries if _is_required(entry)]
datas += [entry for entry in qml_datas if _is_required(entry)]
