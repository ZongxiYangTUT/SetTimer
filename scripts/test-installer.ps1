param(
    [Parameter(Mandatory)]
    [string]$InstallerPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$setTimerInstaller = (Resolve-Path -LiteralPath $InstallerPath).Path
$setTimerTestRoot = Join-Path ([IO.Path]::GetTempPath()) (
    "SetTimer-installer-test-" + [guid]::NewGuid()
)
$setTimerResolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
$setTimerResolvedTestRoot = [IO.Path]::GetFullPath($setTimerTestRoot).TrimEnd('\') + '\'
if (-not $setTimerResolvedTestRoot.StartsWith(
        $setTimerResolvedTemp,
        [StringComparison]::OrdinalIgnoreCase
    )) {
    throw "Installer test directory escaped the temporary directory."
}

try {
    $setTimerInstallProcess = Start-Process `
        -FilePath $setTimerInstaller `
        -ArgumentList @(
            "/VERYSILENT",
            "/SUPPRESSMSGBOXES",
            "/NORESTART",
            "/NOICONS",
            "/TYPE=full",
            "/DIR=$setTimerTestRoot"
        ) `
        -WindowStyle Hidden `
        -PassThru `
        -Wait
    if ($setTimerInstallProcess.ExitCode -ne 0) {
        throw "Installer smoke test failed with code $($setTimerInstallProcess.ExitCode)."
    }

    $setTimerInstalledExecutable = Join-Path $setTimerTestRoot "SetTimer.exe"
    if (-not (Test-Path -LiteralPath $setTimerInstalledExecutable)) {
        throw "Installer did not create SetTimer.exe."
    }

    $setTimerHadStartupCheck = Test-Path Env:SETTIMER_STARTUP_CHECK
    $setTimerOriginalStartupCheck = $env:SETTIMER_STARTUP_CHECK
    $env:SETTIMER_STARTUP_CHECK = "1"
    try {
        $setTimerApplicationProcess = Start-Process `
            -FilePath $setTimerInstalledExecutable `
            -WorkingDirectory $setTimerTestRoot `
            -WindowStyle Hidden `
            -PassThru
        try {
            if (-not $setTimerApplicationProcess.WaitForExit(30000)) {
                throw "Installed SetTimer did not complete its startup check within 30 seconds."
            }
            if ($setTimerApplicationProcess.ExitCode -ne 0) {
                throw "Installed SetTimer failed with code $($setTimerApplicationProcess.ExitCode)."
            }
        }
        finally {
            if (-not $setTimerApplicationProcess.HasExited) {
                Stop-Process -Id $setTimerApplicationProcess.Id
                Wait-Process -Id $setTimerApplicationProcess.Id -ErrorAction SilentlyContinue
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

    $setTimerUninstaller = Get-ChildItem `
        -LiteralPath $setTimerTestRoot `
        -Filter "unins*.exe" `
        -File | Select-Object -First 1
    if ($null -eq $setTimerUninstaller) {
        throw "Installer did not create an uninstaller."
    }
    $setTimerUninstallProcess = Start-Process `
        -FilePath $setTimerUninstaller.FullName `
        -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" `
        -WindowStyle Hidden `
        -PassThru `
        -Wait
    if ($setTimerUninstallProcess.ExitCode -ne 0) {
        throw "Uninstaller smoke test failed with code $($setTimerUninstallProcess.ExitCode)."
    }

    Write-Output "Installer install, launch, and uninstall checks passed."
}
finally {
    if (Test-Path -LiteralPath $setTimerTestRoot) {
        Remove-Item -LiteralPath $setTimerTestRoot -Recurse -Force
    }
}
