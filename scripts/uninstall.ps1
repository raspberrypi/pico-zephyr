#Requires -Version 7
param(
    [string]$OcdVersion = "0.12.0+dev",
    [switch]$AllOpenOcd,
    [switch]$KeepWorkspace,
    [switch]$RemoveVSCode,
    [switch]$Yes
)
$ErrorActionPreference = "Stop"
function Info($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }

$WS = Join-Path $HOME ".pico-sdk\zephyr_workspace"
$OpenOcdRoot = Join-Path $HOME ".pico-sdk\openocd"

function Confirm([string]$msg) {
    if ($Yes) { return $true }
    $r = Read-Host "$msg [y/N]"
    return @("y", "Y", "yes", "YES") -contains $r
}
function SafeRemoveDir([string]$path, [string]$label) {
    if (-not $path.StartsWith($HOME, [System.StringComparison]::OrdinalIgnoreCase)) {
        Warn "Refusing to delete outside HOME: $path ($label)"; return
    }
    if (Test-Path $path) {
        Info "Removing $label\: $path"
        Remove-Item -Recurse -Force -LiteralPath $path
    }
    else {
        Info "Nothing to remove for $label\: $path"
    }
}

# 1) Workspace
if ($KeepWorkspace) {
    Info "Keeping Zephyr workspace: $WS"
}
else {
    if (Confirm "Delete Zephyr workspace at ${WS}?") { SafeRemoveDir $WS "Zephyr workspace" }
    else { Warn "Keeping Zephyr workspace." }
}

# 2) OpenOCD
if ($AllOpenOcd) {
    if (Confirm "Delete ALL OpenOCD under $OpenOcdRoot?") { SafeRemoveDir $OpenOcdRoot "OpenOCD (all versions)" }
    else { Warn "Keeping all OpenOCD versions." }
}
else {
    $vDir = Join-Path $OpenOcdRoot $OcdVersion
    if (Confirm "Delete OpenOCD $OcdVersion at $vDir?") { SafeRemoveDir $vDir "OpenOCD ($OcdVersion)" }
    else { Warn "Keeping OpenOCD $OcdVersion." }
}

# 3) VS Code
if ($RemoveVSCode) {
    $code = (Get-Command code -ErrorAction SilentlyContinue)
    if ($code) {
        Info "Uninstalling Pico extension..."
        try { & code --uninstall-extension raspberry-pi.raspberry-pi-pico | Out-Null } catch {}
    }
    $winget = (Get-Command winget -ErrorAction SilentlyContinue)
    if ($winget) {
        Info "Uninstalling Visual Studio Code via winget..."
        try { winget uninstall --id Microsoft.VisualStudioCode -e --silent | Out-Null } catch { Warn "winget uninstall failed: $_" }
    }
    else {
        Warn "winget not found; uninstall VS Code manually from Apps & features."
    }
}
else {
    Info "Skipping VS Code removal (no -RemoveVSCode)."
}

""
Info "✅ Uninstall complete."
