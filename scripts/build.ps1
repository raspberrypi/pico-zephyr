#Requires -Version 7
param(
    [Parameter(Mandatory = $true)][string]$Board,
    [string]$App = "app",
    [switch]$Clean,
    [Alias("Snippet")][string]$SnippetName  # pass e.g. -Snippet usb_serial_port
)
$ErrorActionPreference = "Stop"
function Info($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err ($m) { Write-Host "[ERR ] $m" -ForegroundColor Red }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$WS = Join-Path $HOME ".pico-sdk\zephyr_workspace"
$West = Join-Path $WS "venv\Scripts\west.exe"
if (-not (Test-Path $West)) { throw "West not found at $West. Run scripts\setup.ps1 first." }

# Resolve app path
if (Test-Path $App) { $AppAbs = (Resolve-Path $App).Path }
else { $AppAbs = (Resolve-Path (Join-Path $RepoRoot $App)).Path }
if (-not (Test-Path (Join-Path $AppAbs "CMakeLists.txt"))) { throw "App CMakeLists.txt not found in $AppAbs" }

# OpenOCD detection
$OpenOcdRoot = Join-Path $HOME ".pico-sdk\openocd"
if (-not (Test-Path $OpenOcdRoot)) {
    $cand = (Resolve-Path (Join-Path $RepoRoot "..") -ErrorAction SilentlyContinue)
    if ($cand) { $OpenOcdRoot = (Join-Path $cand.Path "openocd") }
}
$OpenOcdBin = ""; $OpenOcdScripts = ""
if (Test-Path $OpenOcdRoot) {
    $OpenOcdBin = Get-ChildItem -Path $OpenOcdRoot -Recurse -Filter "openocd.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    $OpenOcdScripts = Get-ChildItem -Path $OpenOcdRoot -Recurse -Directory -Filter "scripts" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
}
$CMakeArgs = @()
if ($OpenOcdBin -and $OpenOcdScripts) {
    Info "Auto-detected OpenOCD: $OpenOcdBin"
    $CMakeArgs += @("-DOPENOCD=$OpenOcdBin", "-DOPENOCD_DEFAULT_PATH=$OpenOcdScripts")
}
else {
    Warn "OpenOCD not auto-detected; relying on environment or board defaults."
}

# Snippet handling
$Pristine = "auto"
$SnippetArgs = @()
if ($SnippetName) {
    $SnippetRoot = ""
    if (Test-Path (Join-Path $RepoRoot "snippets")) {
        $SnippetRoot = $RepoRoot
        if (Test-Path (Join-Path $RepoRoot "snippets\$SnippetName\snippet.yml")) {
            Info "Using snippet '$SnippetName' from $RepoRoot\snippets\$SnippetName"
        }
        else {
            Warn "Snippet '$SnippetName' missing: $RepoRoot\snippets\$SnippetName\snippet.yml"
        }
    }
    elseif (Test-Path (Join-Path (Split-Path $AppAbs -Parent) "snippets")) {
        $SnippetRoot = (Split-Path $AppAbs -Parent)
        if (Test-Path (Join-Path $SnippetRoot "snippets\$SnippetName\snippet.yml")) {
            Info "Using snippet '$SnippetName' near app: $SnippetRoot\snippets\$SnippetName"
        }
        else {
            Warn "Snippet '$SnippetName' missing near app: $SnippetRoot\snippets\$SnippetName\snippet.yml"
        }
    }
    else {
        Warn "No snippets directory found; snippet may not resolve."
    }
    if ($SnippetRoot) { $env:SNIPPET_ROOT = $SnippetRoot }
    $SnippetArgs += @("-S", $SnippetName)
    $Pristine = "always"
}

# Build dir inside project
$BuildDir = Join-Path $AppAbs "build"
if ($Clean -and (Test-Path $BuildDir)) {
    Info "Cleaning $BuildDir"
    Remove-Item -Recurse -Force -LiteralPath $BuildDir
}
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

Info "Building $Board from $AppAbs"
Push-Location $WS
try {
    & $West build `
        -d $BuildDir `
        -b $Board `
        $AppAbs `
        -p $Pristine `
        @SnippetArgs `
        -- `
        @CMakeArgs
}
finally {
    Pop-Location
    if ($env:SNIPPET_ROOT) { Remove-Item Env:\SNIPPET_ROOT -ErrorAction SilentlyContinue }
}

# Summary
$UF2 = Join-Path $BuildDir "zephyr\zephyr.uf2"
$ELF = Join-Path $BuildDir "zephyr\zephyr.elf"
Info "Done. Artifacts in: $BuildDir"
if (Test-Path $UF2) { Info "UF2: $UF2" } else { Warn "UF2 not found: $UF2" }
if (Test-Path $ELF) { Info "ELF: $ELF" } else { Warn "ELF not found: $ELF" }

# Print snippet used (check multiple keys)
$Cache = Join-Path $BuildDir "CMakeCache.txt"
if (Test-Path $Cache) {
    $content = Get-Content -Raw -LiteralPath $Cache
    $sn = $null
    if (-not $sn) { $sn = ($content -split "`n" | Where-Object { $_ -match '^SNIPPET:STRING=' }) -replace '^[^=]*=', '' | Select-Object -First 1 }
    if (-not $sn) { $sn = ($content -split "`n" | Where-Object { $_ -match '^CACHED_SNIPPET:STRING=' }) -replace '^[^=]*=', '' | Select-Object -First 1 }
    if ($sn) { Info "CMake reports snippet=$sn" } else { Info "No snippet recorded in CMakeCache." }
}
