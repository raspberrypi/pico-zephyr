#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/_lib.sh"

info "Updating system packages..."
sudo apt update -y
sudo apt upgrade -y

info "Installing minimal Zephyr dependencies..."
ensure_pkg cmake gperf ccache dfu-util libsdl2-dev \
    python3-venv python3-pip git xz-utils file

WS_DIR="$(zephyr_ws_dir)"
mkdir -p "$WS_DIR"

# Create venv (venv -> virtualenv fallback)
create_ws_venv

# Upgrade pip + install Python deps into the workspace venv
"$(ws_pip)" -q install --upgrade pip
"$(ws_pip)" -q install west pyelftools

# Place manifest into workspace/manifest
copy_manifest_into_ws

# West init (idempotent)
cd "$WS_DIR"
if [ ! -d ".west" ]; then
  need_cmd "$(ws_west)"
  info "Initializing West workspace (local manifest: manifest)"
  "$(ws_west)" init -l manifest
else
  info "West workspace already initialized."
fi

info "Updating West projects..."
"$(ws_west)" update

info "Exporting Zephyr CMake package..."
"$(ws_west)" zephyr-export

info "Installing Python deps for West packages..."
"$(ws_west)" packages pip --install

info "Fetching Zephyr binary blobs (hal_infineon)..."
"$(ws_west)" blobs fetch hal_infineon || true

# Install only the ARM toolchain, colocated in the workspace
SDK_DIR="$WS_DIR/zephyr-sdk"
GHTOKEN_ARGS=()
[ -n "${GITHUB_TOKEN:-}" ] && GHTOKEN_ARGS=(--personal-access-token "$GITHUB_TOKEN")

info "Installing Zephyr SDK (arm-zephyr-eabi) into $SDK_DIR"
"$(ws_west)" sdk install -t arm-zephyr-eabi -d "$SDK_DIR" "${GHTOKEN_ARGS[@]}"

info "Minimal Zephyr workspace ready at: $WS_DIR"
