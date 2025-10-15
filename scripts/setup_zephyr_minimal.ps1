#Requires -Version 7
$ErrorActionPreference = "Stop"
function Info($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$WS = Join-Path $HOME ".pico-sdk\zephyr_workspace"
$Venv = Join-Path $WS "venv"
$Py = Join-Path $Venv "Scripts\python.exe"
$Pip = Join-Path $Venv "Scripts\pip.exe"
$West = Join-Path $Venv "Scripts\west.exe"

# Ensure Python exist
if (-not (Get-Command python -ErrorAction SilentlyContinue)) { throw "Python is required (install via winget: winget install Python.Python.3.11)" }

# --- Host tools via winget: CMake, gperf, dtc ---
function Info($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }

$env:Path += ";C:\Program Files\7-Zip;C:\Program Files\CMake\bin"

function Refresh-EnvPath {
    # Make newly-installed winget apps visible to this session
    $u = [Environment]::GetEnvironmentVariable('Path', 'User')
    $m = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if ($u -and $m) { $env:Path = "$u;$m" }
    elseif ($m) { $env:Path = $m }
    elseif ($u) { $env:Path = $u }
}

function Ensure-Winget {
    $wg = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wg) {
        Warn "winget not found. Install winget (App Installer from Microsoft Store) or install tools manually."
        return $false
    }
    return $true
}

function Test-Exe([string]$Exe) {
    return [bool](Get-Command $Exe -ErrorAction SilentlyContinue)
}

function Ensure-WingetPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Exe,      # e.g. cmake.exe
        [Parameter(Mandatory = $true)][string]$Name      # friendly name for logs
    )
    if (Test-Exe $Exe) {
        Info "$Name already available: $((Get-Command $Exe).Source)"
        return
    }
    if (-not (Ensure-Winget)) { return }
    Info "Installing $Name via winget ($Id)… [Please accept UAC prompt if shown.]"
    try {
        winget install -e --id $Id --silent --accept-source-agreements --accept-package-agreements | Out-Null
    }
    catch {
        Warn "winget install failed for $Name ($Id): $_"
    }
    Refresh-EnvPath
    if (Test-Exe $Exe) { Info "$Name ready: $((Get-Command $Exe).Source)" }
    else { Warn "$Name not found on PATH after install. Try a new terminal." }
}

# Install/ensure the three tools
Ensure-WingetPackage -Id 'Git.git'              -Exe 'git.exe'      -Name 'Git'
Ensure-WingetPackage -Id 'Kitware.CMake'        -Exe 'cmake.exe'    -Name 'CMake'
Ensure-WingetPackage -Id 'oss-winget.dtc'       -Exe 'dtc.exe'      -Name 'Device Tree Compiler (dtc)'
Ensure-WingetPackage -Id '7zip.7zip'            -Exe '7z.exe'       -Name '7-Zip'
Ensure-WingetPackage -Id 'JernejSimoncic.Wget'  -Exe 'wget.exe'     -Name 'Wget'
Ensure-WingetPackage -Id 'Ninja-build.Ninja'    -Exe 'ninja.exe'    -Name 'Ninja'

New-Item -ItemType Directory -Force -Path $WS | Out-Null

if (-not (Test-Path $Py)) {
    Info "Creating venv at $Venv"
    python -m venv $Venv
}
else {
    Info "Existing venv found at $Venv"
}

& $Pip -q install --upgrade pip | Out-Null
& $Pip -q install west pyelftools | Out-Null

# Copy manifest into workspace/manifest
$ManifestDst = Join-Path $WS "manifest"
New-Item -ItemType Directory -Force -Path $ManifestDst | Out-Null
if (Test-Path (Join-Path $RepoRoot "manifest\west.yml")) {
    Copy-Item -Recurse -Force (Join-Path $RepoRoot "manifest\*") $ManifestDst
}
elseif (Test-Path (Join-Path $RepoRoot "west.yml")) {
    Copy-Item -Force (Join-Path $RepoRoot "west.yml") (Join-Path $ManifestDst "west.yml")
}
else {
    Warn "No manifest found (expected manifest\west.yml or west.yml)"
}

Push-Location $WS
try {
    if (-not (Test-Path ".west")) {
        Info "Initializing West workspace (local manifest: manifest)"
        & $West init -l manifest
    }
    else {
        Info "West workspace already initialized."
    }

    & $West update
    & $West zephyr-export
    & $West packages pip --install
    try { & $West blobs fetch hal_infineon } catch { }

    # Minimal toolchain
    $SdkDir = Join-Path $WS "zephyr-sdk"
    $args = @("sdk", "install", "-t", "arm-zephyr-eabi", "-d", $SdkDir)
    if ($env:GITHUB_TOKEN) { $args += @("--personal-access-token", $env:GITHUB_TOKEN) }
    & $West @args
}
finally { Pop-Location }

Info "Minimal Zephyr workspace ready at: $WS"
