Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$setTimerVoiceRoot = Join-Path $env:LOCALAPPDATA "SetTimer\voices"
$setTimerModelName = "kokoro-int8-multi-lang-v1_1"
$setTimerModelDirectory = Join-Path $setTimerVoiceRoot $setTimerModelName
$setTimerArchive = Join-Path $setTimerVoiceRoot "$setTimerModelName.tar.bz2"
$setTimerDownload = "$setTimerArchive.download"
$setTimerUrl = (
    "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/" +
    "$setTimerModelName.tar.bz2"
)
$setTimerExpectedSha256 = "a1e94694776049035c4f2c6529f003aaece993c76aae9a78995831c3c4dcafc6"
$setTimerRequiredFiles = @(
    "model.int8.onnx",
    "voices.bin",
    "tokens.txt",
    "lexicon-us-en.txt",
    "lexicon-zh.txt",
    "espeak-ng-data",
    "phone-zh.fst",
    "date-zh.fst",
    "number-zh.fst"
)

function Test-SetTimerModel {
    param([Parameter(Mandatory)][string]$Path)

    foreach ($setTimerRequiredFile in $setTimerRequiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $Path $setTimerRequiredFile))) {
            return $false
        }
    }
    return $true
}

if (Test-SetTimerModel -Path $setTimerModelDirectory) {
    Write-Output "Kokoro is already installed at $setTimerModelDirectory"
    exit 0
}

New-Item -ItemType Directory -Force -Path $setTimerVoiceRoot | Out-Null

if (Test-Path -LiteralPath $setTimerArchive) {
    $setTimerArchiveHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $setTimerArchive).Hash
    if ($setTimerArchiveHash -ine $setTimerExpectedSha256) {
        throw "Existing Kokoro archive has an unexpected SHA-256: $setTimerArchive"
    }
}
else {
    & curl.exe `
        -L `
        --fail `
        --retry 5 `
        --retry-delay 2 `
        --continue-at - `
        --output $setTimerDownload `
        $setTimerUrl
    if ($LASTEXITCODE -ne 0) {
        throw "Kokoro download failed with exit code $LASTEXITCODE"
    }
    $setTimerDownloadHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $setTimerDownload).Hash
    if ($setTimerDownloadHash -ine $setTimerExpectedSha256) {
        throw "Downloaded Kokoro archive failed SHA-256 verification."
    }
    Move-Item -LiteralPath $setTimerDownload -Destination $setTimerArchive
}

$setTimerEntries = @(tar -tf $setTimerArchive)
if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect the Kokoro archive."
}
$setTimerUnsafeEntries = @(
    $setTimerEntries | Where-Object {
        $_ -match '^(?:/|\\|[A-Za-z]:)' -or $_ -match '(^|[\\/])\.\.([\\/]|$)'
    }
)
if ($setTimerUnsafeEntries.Count -gt 0) {
    throw "Kokoro archive contains unsafe paths."
}

if (Test-Path -LiteralPath $setTimerModelDirectory) {
    throw "Incomplete Kokoro directory already exists: $setTimerModelDirectory"
}

$setTimerExtractRoot = Join-Path $setTimerVoiceRoot (".kokoro-extract-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $setTimerExtractRoot | Out-Null
$setTimerResolvedVoiceRoot = [IO.Path]::GetFullPath($setTimerVoiceRoot).TrimEnd('\') + '\'
$setTimerResolvedExtractRoot = [IO.Path]::GetFullPath($setTimerExtractRoot).TrimEnd('\') + '\'
if (-not $setTimerResolvedExtractRoot.StartsWith(
        $setTimerResolvedVoiceRoot,
        [StringComparison]::OrdinalIgnoreCase
    )) {
    throw "Temporary extraction path escaped the SetTimer voice directory."
}
try {
    & tar -xf $setTimerArchive -C $setTimerExtractRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Kokoro extraction failed with exit code $LASTEXITCODE"
    }
    $setTimerExtractedModel = Join-Path $setTimerExtractRoot $setTimerModelName
    if (-not (Test-SetTimerModel -Path $setTimerExtractedModel)) {
        throw "Extracted Kokoro model is incomplete."
    }
    Move-Item -LiteralPath $setTimerExtractedModel -Destination $setTimerModelDirectory
}
finally {
    if (Test-Path -LiteralPath $setTimerExtractRoot) {
        Remove-Item -LiteralPath $setTimerExtractRoot -Recurse -Force
    }
}

Write-Output "Kokoro installed at $setTimerModelDirectory"
