#Requires -Version 7
param(
    [switch]$Full,
    [switch]$NoVSCode,
    [switch]$NoOpenOCD,
    [string]$SdkRelease = "v2.2.0-2",
    [string]$OpenOcdVersion = "0.12.0+dev"
)
$ErrorActionPreference = "Stop"

function Info($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err ($m) { Write-Host "[ERR ] $m" -ForegroundColor Red }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$WS = Join-Path $HOME ".pico-sdk\zephyr_workspace"

Info "Pico + Zephyr setup starting..."
Info "Repo: $RepoRoot"
Info "Workspace: $WS"

if (-not $NoVSCode) {
    & (Join-Path $ScriptDir "vscode_setup.ps1")
}
else {
    Warn "Skipping VS Code install (--NoVSCode)"
}

if ($Full) {
    & (Join-Path $ScriptDir "setup_zephyr_full.ps1")
}
else {
    & (Join-Path $ScriptDir "setup_zephyr_minimal.ps1")
}

if (-not $NoOpenOCD) {
    & (Join-Path $ScriptDir "setup_openocd_windows.ps1") -SdkRelease $SdkRelease -OpenOcdVersion $OpenOcdVersion
}
else {
    Warn "Skipping OpenOCD install (--NoOpenOCD)"
}

# Summary
$West = Join-Path $WS "venv\Scripts\west.exe"
$Ocd = Join-Path $HOME ".pico-sdk\openocd\$OpenOcdVersion\openocd"
if (-not (Test-Path $Ocd)) { $Ocd = "" }

""
Info "✅ Setup complete."
"Workspace:   $WS"
if (Test-Path $West) { "West:        $West" }
if (Test-Path (Join-Path $WS "zephyr-sdk")) { "Zephyr SDK:  $WS\zephyr-sdk" }
if ($Ocd) { "OpenOCD:     $Ocd" }

""
"How to build (artifacts in <project>\build):"
"  scripts\build.ps1 -Board rpi_pico"
"  scripts\build.ps1 -Board rpi_pico/rp2040/w"
"  scripts\build.ps1 -Board rpi_pico2/rp2350a/m33/w -App blinky -SnippetName usb_serial_port"
