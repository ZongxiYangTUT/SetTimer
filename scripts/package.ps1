Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$setTimerRoot = Split-Path -Parent $PSScriptRoot
$setTimerPython = Join-Path $setTimerRoot ".venv\Scripts\python.exe"

& (Join-Path $PSScriptRoot "check.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Push-Location $setTimerRoot
try {
    & $setTimerPython -m PyInstaller --clean --noconfirm SetTimer.spec
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
}
