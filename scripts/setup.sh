#!/usr/bin/env bash
# One-shot setup for Pico + Zephyr on Linux/RPi OS.
# - Creates Zephyr workspace at ~/.pico-sdk/zephyr_workspace
# - Installs Zephyr SDK (minimal by default)
# - Installs OpenOCD into ~/.pico-sdk/openocd/0.12.0+dev
# - Optionally installs VS Code (RPi OS uses default repo; others use MS repo)
#
# Flags:
#   --full           Use full Zephyr SDK/toolchains (default: minimal/arm-only)
#   --no-vscode      Skip VS Code install
#   --no-openocd     Skip OpenOCD install
#   --sdk-release X  Pico SDK tools tag for OpenOCD (default: v2.2.0-2)
#   --ocd-version V  OpenOCD version dir (default: 0.12.0+dev)
#   -h|--help        Show help
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# Load shared helpers
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_lib.sh"

USE_FULL=0
DO_VSCODE=1
DO_OPENOCD=1
SDK_RELEASE="v2.2.0-2"
OCD_VERSION="0.12.0+dev"

usage() {
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
}

while (( "$#" )); do
  case "$1" in
    --full) USE_FULL=1; shift ;;
    --no-vscode) DO_VSCODE=0; shift ;;
    --no-openocd) DO_OPENOCD=0; shift ;;
    --sdk-release) SDK_RELEASE="${2:-}"; shift 2 ;;
    --ocd-version) OCD_VERSION="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown flag: $1"; usage; exit 2 ;;
  esac
done

info "Pico + Zephyr setup starting…"
info "Repo: $REPO_ROOT"
info "Workspace: $(zephyr_ws_dir)"

# --- Ensure apt metadata is refreshed ONCE for this whole flow ---
if command -v apt >/dev/null 2>&1; then
  apt_update_once   # sets APT_UPDATED=1
fi

# --- VS Code (safe to run on any Linux; script itself detects RPi OS) ---
if [ "$DO_VSCODE" -eq 1 ]; then
  info "Step 1/3: VS Code"
  bash "$SCRIPT_DIR/vscode_setup.sh"
else
  warn "Skipping VS Code install (--no-vscode)."
fi

# --- Zephyr workspace + SDK ---
info "Step 2/3: Zephyr workspace"
if [ "$USE_FULL" -eq 1 ]; then
  bash "$SCRIPT_DIR/setup_zephyr_full.sh"
else
  bash "$SCRIPT_DIR/setup_zephyr_minimal.sh"
fi

# --- OpenOCD install ---
if [ "$DO_OPENOCD" -eq 1 ]; then
  info "Step 3/3: OpenOCD ($OCD_VERSION from $SDK_RELEASE)"
  # Best-effort: only install the aarch64 Linux build automatically (Raspberry Pi 5)
  if [ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "aarch64" ]; then
    bash "$SCRIPT_DIR/setup_openocd_linux.sh" "$OCD_VERSION" "$SDK_RELEASE"
  else
    warn "This helper auto-installs the aarch64 Linux build only."
    warn "For Windows, run:  pwsh -File scripts/setup_openocd_windows.ps1 -SdkRelease $SDK_RELEASE -OpenOcdVersion $OCD_VERSION"
    warn "For other Linux archs, install OpenOCD suitable for your platform."
  fi
else
  warn "Skipping OpenOCD install (--no-openocd)."
fi

# --- Summary & next steps ---
WS_DIR="$(zephyr_ws_dir)"
echo
info "✅ Setup complete."
echo "Workspace:   $WS_DIR"
[ -x "$(ws_west)" ] && echo "West:        $(ws_west)"
[ -d "$WS_DIR/zephyr-sdk" ] && echo "Zephyr SDK:  $WS_DIR/zephyr-sdk"
[ -d "$HOME/.pico-sdk/openocd/$OCD_VERSION/openocd" ] && echo "OpenOCD:     $HOME/.pico-sdk/openocd/$OCD_VERSION/openocd"

cat <<'TXT'

──────────────────────────────────────────────────────────────────────────────
How to build with scripts/build.sh
──────────────────────────────────────────────────────────────────────────────
• Artifacts go into your project's own ./build directory (matches VS Code tasks).
• The shared Zephyr workspace lives in ~/.pico-sdk/zephyr_workspace.
• OpenOCD is auto-discovered in ~/.pico-sdk/openocd/<version>.

Basic usage:
  ./scripts/build.sh -b rpi_pico
  ./scripts/build.sh -b rpi_pico/rp2040/w
  ./scripts/build.sh -b rpi_pico2/rp2350a/m33/w -a samples/blinky

Options:
  -b <board>     Board name (e.g., rpi_pico2/rp2350a/m33/w)
  -a <app_dir>   App path (default: app). Can be absolute or relative to repo.
  -s             Add snippet 'usb_serial_port'
  -- clean       Remove <app>/build before building

Examples matching your tasks.json:
  # Build using Zephyr workspace as CWD, project build dir as -d:
  ./scripts/build.sh -b rpi_pico2/rp2350a/m33/w -a . -- clean

  # Flash from VS Code task (or manually):
  cd ~/.pico-sdk/zephyr_workspace
  ~/.pico-sdk/zephyr_workspace/venv/bin/west flash --build-dir "<project>/build"

OpenOCD discovery:
  The build sets (when found):
    -DOPENOCD=<root>/openocd|openocd.exe
    -DOPENOCD_DEFAULT_PATH=<root>/openocd/scripts or <root>/scripts

If not found, the build proceeds and relies on your environment/board defaults.
TXT
