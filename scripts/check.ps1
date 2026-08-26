Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$setTimerRoot = Split-Path -Parent $PSScriptRoot
$setTimerScripts = Join-Path $setTimerRoot ".venv\Scripts"
$setTimerPython = Join-Path $setTimerScripts "python.exe"
$setTimerRuff = Join-Path $setTimerScripts "ruff.exe"
$setTimerPyright = Join-Path $setTimerScripts "pyright.exe"
$setTimerQmlFormat = Join-Path $setTimerScripts "pyside6-qmlformat.exe"
$setTimerQmlLint = Join-Path $setTimerScripts "pyside6-qmllint.exe"

if (-not (Test-Path -LiteralPath $setTimerPython)) {
    throw "Missing .venv. Create it and install the project with: .venv\Scripts\python -m pip install -e `".[dev]`""
}

Push-Location $setTimerRoot
try {
    & $setTimerRuff format --check src tests packaging
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & $setTimerRuff check src tests packaging
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & $setTimerPyright
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $setTimerQmlFiles = Get-ChildItem "src\settimer\ui" -Recurse -Filter "*.qml" |
        Sort-Object FullName |
        ForEach-Object FullName

    foreach ($setTimerQmlFile in $setTimerQmlFiles) {
        $setTimerTemporaryQml = Join-Path ([IO.Path]::GetTempPath()) (
            "settimer-qmlformat-{0}.qml" -f [guid]::NewGuid()
        )
        try {
            Copy-Item -LiteralPath $setTimerQmlFile -Destination $setTimerTemporaryQml
            & $setTimerQmlFormat --inplace $setTimerTemporaryQml
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            $setTimerFormatted = [IO.File]::ReadAllText($setTimerTemporaryQml).Replace("`r`n", "`n")
            $setTimerSource = [IO.File]::ReadAllText($setTimerQmlFile).Replace("`r`n", "`n")
            if ($setTimerSource -cne $setTimerFormatted) {
                throw "QML formatting check failed: $setTimerQmlFile"
            }
        }
        finally {
            if (Test-Path -LiteralPath $setTimerTemporaryQml) {
                Remove-Item -LiteralPath $setTimerTemporaryQml
            }
        }
    }

    & $setTimerQmlLint -W 0 -I "src\settimer\ui" $setTimerQmlFiles
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & $setTimerPython -m unittest discover -s tests -v
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
}
