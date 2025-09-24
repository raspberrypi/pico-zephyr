#Requires -Version 7
$ErrorActionPreference = "Stop"
function Info($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }

$winget = (Get-Command winget -ErrorAction SilentlyContinue)
if ($winget) {
    Info "Installing Visual Studio Code with winget (user scope)..."
    winget install --id Microsoft.VisualStudioCode -e --scope user --accept-source-agreements --accept-package-agreements | Out-Null
}
else {
    Warn "winget not found; install VS Code manually from https://code.visualstudio.com/ or add winget."
}

# Try to locate 'code' CLI
$code = Get-Command code -ErrorAction SilentlyContinue
if (-not $code) {
    $maybe = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"
    if (Test-Path $maybe) { $code = Get-Item $maybe }
}
if (-not $code) { throw "VS Code CLI 'code' not on PATH; restart terminal or install VS Code." }

Info "Installing Raspberry Pi Pico extension..."
& $code --install-extension raspberry-pi.raspberry-pi-pico --force | Out-Null
Info "VS Code setup done."
