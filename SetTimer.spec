# -*- mode: python ; coding: utf-8 -*-

from pathlib import Path
import tomllib

import PySide6
from PyInstaller.utils.hooks import collect_data_files, collect_dynamic_libs
from PyInstaller.utils.win32.versioninfo import (
    FixedFileInfo,
    StringFileInfo,
    StringStruct,
    StringTable,
    VarFileInfo,
    VarStruct,
    VSVersionInfo,
)


project = tomllib.loads(Path("pyproject.toml").read_text(encoding="utf-8"))
app_version = project["project"]["version"]
version_parts = tuple(int(part) for part in app_version.split("."))
version_quad = (*version_parts, *(0 for _ in range(4 - len(version_parts))))
version_info = VSVersionInfo(
    ffi=FixedFileInfo(
        filevers=version_quad,
        prodvers=version_quad,
        mask=0x3F,
        flags=0,
        OS=0x40004,
        fileType=0x1,
        subtype=0,
        date=(0, 0),
    ),
    kids=[
        StringFileInfo(
            [
                StringTable(
                    "040904B0",
                    [
                        StringStruct("CompanyName", "ZongxiYangTUT"),
                        StringStruct("FileDescription", "SetTimer 间歇训练计时器"),
                        StringStruct("FileVersion", app_version),
                        StringStruct("InternalName", "SetTimer"),
                        StringStruct("LegalCopyright", "Copyright (c) 2026 ZongxiYangTUT"),
                        StringStruct("OriginalFilename", "SetTimer.exe"),
                        StringStruct("ProductName", "SetTimer"),
                        StringStruct("ProductVersion", app_version),
                    ],
                )
            ]
        ),
        VarFileInfo([VarStruct("Translation", [1033, 1200])]),
    ],
)


datas = collect_data_files(
    "settimer",
    includes=["assets/*", "ui/*.qml", "ui/components/*.qml"],
)

pyside_directory = Path(PySide6.__file__).resolve().parent
sherpa_binaries = collect_dynamic_libs("sherpa_onnx")

analysis = Analysis(
    ["src/settimer/main.py"],
    pathex=["src"],
    binaries=sherpa_binaries,
    datas=datas,
    hiddenimports=[
        "PySide6.QtTextToSpeech",
        "PySide6.QtMultimedia",
        "PySide6.QtDBus",
        "sherpa_onnx",
        "sherpa_onnx.lib._sherpa_onnx",
    ],
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
    version=version_info,
)
collection = COLLECT(
    executable,
    analysis.binaries,
    analysis.datas,
    strip=False,
    upx=False,
    name="SetTimer",
)
