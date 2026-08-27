Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$setTimerRoot = Split-Path -Parent $PSScriptRoot
$setTimerPython = Join-Path $setTimerRoot ".venv\Scripts\python.exe"

& (Join-Path $PSScriptRoot "check.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Push-Location $setTimerRoot
try {
    $setTimerOriginalPath = $env:PATH
    $setTimerWindowsRoot = [Environment]::GetEnvironmentVariable("SystemRoot")
    if ([string]::IsNullOrWhiteSpace($setTimerWindowsRoot)) {
        throw "SystemRoot is unavailable; cannot create a clean Windows build environment."
    }
    try {
        # Keep unrelated developer tools from supplying same-named DLLs while
        # PyInstaller resolves the application's native dependencies.
        $env:PATH = "$setTimerWindowsRoot\System32;$setTimerWindowsRoot"
        & $setTimerPython -m PyInstaller --clean --noconfirm SetTimer.spec
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    finally {
        $env:PATH = $setTimerOriginalPath
    }

    $setTimerExecutable = Join-Path $setTimerRoot "dist\SetTimer\SetTimer.exe"
    $setTimerDistribution = Split-Path -Parent $setTimerExecutable
    $setTimerHadStartupCheck = Test-Path Env:SETTIMER_STARTUP_CHECK
    $setTimerOriginalStartupCheck = $env:SETTIMER_STARTUP_CHECK
    $env:SETTIMER_STARTUP_CHECK = "1"
    try {
        $setTimerProcess = Start-Process `
            -FilePath $setTimerExecutable `
            -WorkingDirectory $setTimerDistribution `
            -WindowStyle Hidden `
            -PassThru
        try {
            if (-not $setTimerProcess.WaitForExit(30000)) {
                throw "Packaged SetTimer did not complete its startup check within 30 seconds."
            }
            if ($setTimerProcess.ExitCode -ne 0) {
                throw "Packaged SetTimer failed its startup check with code $($setTimerProcess.ExitCode)."
            }
            Write-Output "Packaged executable launch check passed."
        }
        finally {
            if (-not $setTimerProcess.HasExited) {
                Stop-Process -Id $setTimerProcess.Id
                Wait-Process -Id $setTimerProcess.Id -ErrorAction SilentlyContinue
            }
        }
    }
    finally {
        if ($setTimerHadStartupCheck) {
            $env:SETTIMER_STARTUP_CHECK = $setTimerOriginalStartupCheck
        }
        else {
            Remove-Item Env:SETTIMER_STARTUP_CHECK -ErrorAction SilentlyContinue
        }
    }
}
finally {
    Pop-Location
}
