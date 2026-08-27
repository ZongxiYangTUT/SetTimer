# -*- mode: python ; coding: utf-8 -*-

from pathlib import Path

import PySide6
from PyInstaller.utils.hooks import collect_data_files


datas = collect_data_files(
    "settimer",
    includes=["assets/*", "ui/*.qml", "ui/components/*.qml"],
)

pyside_directory = Path(PySide6.__file__).resolve().parent

analysis = Analysis(
    ["src/settimer/main.py"],
    pathex=["src"],
    binaries=[],
    datas=datas,
    hiddenimports=["PySide6.QtTextToSpeech", "PySide6.QtMultimedia", "PySide6.QtDBus"],
    hookspath=["packaging/hooks"],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        "PySide6.QtWebEngineCore",
        "PySide6.QtWebEngineQuick",
        "PySide6.QtWebEngineWidgets",
    ],
    noarchive=False,
    optimize=1,
)

# Qt 6 links to Windows' system ICU by the generic name icuuc.dll.  A build
# environment can put an unrelated versioned ICU on PATH; PyInstaller may then
# bundle it under the generic name, shadow System32 and breaking QtCore imports.
# Preserve a future ICU shipped by PySide itself, but reject unrelated copies.
analysis.binaries = [
    binary
    for binary in analysis.binaries
    if not (
        (
            Path(binary[0]).name.lower() == "icuuc.dll"
            or Path(binary[0]).name.lower().startswith("icudt")
        )
        and not Path(binary[1]).resolve().is_relative_to(pyside_directory)
    )
]
pyz = PYZ(analysis.pure)

executable = EXE(
    pyz,
    analysis.scripts,
    [],
    exclude_binaries=True,
    name="SetTimer",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,
    icon="src/settimer/assets/icon.ico",
)
collection = COLLECT(
    executable,
    analysis.binaries,
    analysis.datas,
    strip=False,
    upx=False,
    name="SetTimer",
)
