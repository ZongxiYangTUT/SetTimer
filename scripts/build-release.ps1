param(
    [string]$Version,
    [string]$InnoCompiler
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$setTimerRoot = Split-Path -Parent $PSScriptRoot
$setTimerPython = Join-Path $setTimerRoot ".venv\Scripts\python.exe"
if (-not (Test-Path -LiteralPath $setTimerPython)) {
    throw "Missing .venv. Install requirements-release.txt and the project first."
}

$setTimerProjectVersion = & $setTimerPython -c (
    "import tomllib; " +
    "print(tomllib.load(open('pyproject.toml', 'rb'))['project']['version'])"
)
if ($LASTEXITCODE -ne 0) {
    throw "Unable to read the project version."
}
$setTimerRuntimeVersion = & $setTimerPython -c "import settimer; print(settimer.__version__)"
if ($LASTEXITCODE -ne 0) {
    throw "Unable to read the runtime version."
}
if ($setTimerRuntimeVersion -ne $setTimerProjectVersion) {
    throw (
        "Version mismatch: pyproject.toml=$setTimerProjectVersion, " +
        "settimer.__version__=$setTimerRuntimeVersion"
    )
}
if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = $setTimerProjectVersion
}
if ($Version -ne $setTimerProjectVersion) {
    throw "Requested version $Version does not match project version $setTimerProjectVersion."
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Release version must use MAJOR.MINOR.PATCH."
}
$setTimerVersionQuad = "$Version.0"

& (Join-Path $PSScriptRoot "package.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& (Join-Path $PSScriptRoot "install-kokoro.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$setTimerModelDirectory = Join-Path $env:LOCALAPPDATA (
    "SetTimer\voices\kokoro-int8-multi-lang-v1_1"
)
if (-not (Test-Path -LiteralPath (Join-Path $setTimerModelDirectory "model.int8.onnx"))) {
    throw "Kokoro model is incomplete: $setTimerModelDirectory"
}

$setTimerInnoCandidates = @(
    $InnoCompiler,
    (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 7\ISCC.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe"),
    "C:\Program Files\Inno Setup 7\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 7\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
$setTimerIscc = $setTimerInnoCandidates |
    Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1
if ($null -eq $setTimerIscc) {
    $setTimerCommand = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($null -ne $setTimerCommand) {
        $setTimerIscc = $setTimerCommand.Source
    }
}
if ($null -eq $setTimerIscc) {
    throw "Inno Setup compiler was not found. Install JRSoftware.InnoSetup with winget."
}

$setTimerReleaseDirectory = Join-Path $setTimerRoot "release"
New-Item -ItemType Directory -Force -Path $setTimerReleaseDirectory | Out-Null
$setTimerInstallerName = "SetTimer-$Version-windows-x64-setup.exe"
$setTimerInstallerPath = Join-Path $setTimerReleaseDirectory $setTimerInstallerName
$setTimerChecksumPath = Join-Path $setTimerReleaseDirectory "SHA256SUMS.txt"
if (Test-Path -LiteralPath $setTimerInstallerPath) {
    Remove-Item -LiteralPath $setTimerInstallerPath -Force
}
if (Test-Path -LiteralPath $setTimerChecksumPath) {
    Remove-Item -LiteralPath $setTimerChecksumPath -Force
}

Push-Location $setTimerRoot
try {
    & $setTimerIscc `
        "/DAppVersion=$Version" `
        "/DAppVersionQuad=$setTimerVersionQuad" `
        "/DKokoroModelDirectory=$setTimerModelDirectory" `
        "packaging\windows\SetTimer.iss"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $setTimerInstallerPath)) {
    throw "Inno Setup did not produce the expected installer: $setTimerInstallerPath"
}

& (Join-Path $PSScriptRoot "test-installer.ps1") -InstallerPath $setTimerInstallerPath
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$setTimerHash = Get-FileHash -Algorithm SHA256 -LiteralPath $setTimerInstallerPath
[IO.File]::WriteAllText(
    $setTimerChecksumPath,
    "$($setTimerHash.Hash.ToLowerInvariant())  $setTimerInstallerName`n",
    [Text.UTF8Encoding]::new($false)
)
Write-Output "Release installer: $setTimerInstallerPath"
Write-Output "SHA-256: $($setTimerHash.Hash)"
