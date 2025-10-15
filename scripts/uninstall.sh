#!/usr/bin/env bash
# Re-exec with bash if not already
if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_lib.sh"

# Defaults
OCD_VERSION="0.12.0+dev"
REMOVE_VSCODE=0
PURGE_CODE_REPO=0
REMOVE_ALL_OPENOCD=0
KEEP_WORKSPACE=0
YES=0

usage() {
  cat <<EOF
Usage: $0 [options]

Remove artifacts created by setup.sh

Actions (defaults in brackets):
  --ocd-version V       OpenOCD version dir to remove [${OCD_VERSION}]
  --all-openocd         Remove ALL OpenOCD under ~/.pico-sdk/openocd
  --keep-workspace      Keep ~/.pico-sdk/zephyr_workspace (don't delete it)
  --remove-vscode       apt remove 'code' and uninstall pico extension
  --purge-code-repo     ALSO remove Microsoft VS Code repo list + key
  -y, --yes             Do not prompt (non-interactive)
  -h, --help            Show this help

Notes:
- Zephyr workspace path: ~/.pico-sdk/zephyr_workspace
- OpenOCD path:         ~/.pico-sdk/openocd/<version>
EOF
}

# Parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --ocd-version) [ $# -ge 2 ] || { err "--ocd-version needs a value"; exit 2; }
                   OCD_VERSION="$2"; shift 2 ;;
    --all-openocd) REMOVE_ALL_OPENOCD=1; shift ;;
    --keep-workspace) KEEP_WORKSPACE=1; shift ;;
    --remove-vscode) REMOVE_VSCODE=1; shift ;;
    --purge-code-repo) PURGE_CODE_REPO=1; shift ;;
    -y|--yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 2 ;;
  esac
done

confirm() {
  # $1 message
  if [ "$YES" -eq 1 ]; then return 0; fi
  printf "%s [y/N]: " "$1"
  read -r ans || ans=""
  case "$ans" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

safe_rm_dir() {
  # $1 path, $2 description
  local target="$1" label="${2:-}"
  [ -z "$target" ] && return 0
  # only allow deleting under HOME to be extra safe
  case "$target" in
    "$HOME"/*|"$HOME"/.pico-sdk/*) ;;
    *) warn "Refusing to delete path outside \$HOME: $target ($label)"; return 0 ;;
  esac
  if [ -d "$target" ]; then
    info "Removing $label: $target"
    rm -rf --one-file-system "$target"
  else
    info "Nothing to remove for $label (not found): $target"
  fi
}

# 1) Remove Zephyr workspace
WS_DIR="$(zephyr_ws_dir)"
if [ "$KEEP_WORKSPACE" -eq 1 ]; then
  info "Keeping Zephyr workspace (requested): $WS_DIR"
else
  if confirm "Delete Zephyr workspace at $WS_DIR?"; then
    safe_rm_dir "$WS_DIR" "Zephyr workspace"
  else
    warn "Keeping Zephyr workspace."
  fi
fi

# 2) Remove OpenOCD under ~/.pico-sdk/openocd
OPENOCD_ROOT="$HOME/.pico-sdk/openocd"
if [ "$REMOVE_ALL_OPENOCD" -eq 1 ]; then
  if confirm "Delete ALL OpenOCD under $OPENOCD_ROOT?"; then
    safe_rm_dir "$OPENOCD_ROOT" "OpenOCD (all versions)"
  else
    warn "Keeping all OpenOCD."
  fi
else
  OCD_DIR="$OPENOCD_ROOT/$OCD_VERSION"
  if confirm "Delete OpenOCD version at $OCD_DIR?"; then
    safe_rm_dir "$OCD_DIR" "OpenOCD ($OCD_VERSION)"
    # Clean empty parent if it became empty
    if [ -d "$OPENOCD_ROOT" ] && [ -z "$(ls -A "$OPENOCD_ROOT")" ]; then
      safe_rm_dir "$OPENOCD_ROOT" "OpenOCD root (empty)"
    fi
  else
    warn "Keeping OpenOCD $OCD_VERSION."
  fi
fi

# 3) VS Code + Pico extension (optional)
if [ "$REMOVE_VSCODE" -eq 1 ]; then
  # Uninstall the Pico extension (best-effort)
  if command -v code >/dev/null 2>&1; then
    info "Uninstalling VS Code Pico extension..."
    if code --uninstall-extension raspberry-pi.raspberry-pi-pico >/dev/null 2>&1; then
      info "Extension removed."
    else
      warn "Couldn't uninstall extension (maybe not installed)."
    fi
  else
    warn "'code' not found; skipping extension removal."
  fi

  # Remove the code package
  if command -v apt >/dev/null 2>&1; then
    info "Removing VS Code package 'code' via apt..."
    sudo apt -y remove code || warn "Failed to remove code (is it installed?)"
    # Optional: autoremove residual deps
    sudo apt -y autoremove || true
  else
    warn "apt not available; please remove VS Code manually if desired."
  fi

  # Purge the Microsoft repo on request (non-RPi OS setups)
  if [ "$PURGE_CODE_REPO" -eq 1 ]; then
    if [ -f /etc/apt/sources.list.d/vscode.list ]; then
      info "Removing /etc/apt/sources.list.d/vscode.list"
      sudo rm -f /etc/apt/sources.list.d/vscode.list
      # refresh package metadata after repo change
      if command -v apt >/dev/null 2>&1; then sudo apt update -y || true; fi
    else
      info "vscode.list not present; nothing to remove."
    fi
    if [ -f /etc/apt/trusted.gpg.d/microsoft.gpg ]; then
      info "Removing /etc/apt/trusted.gpg.d/microsoft.gpg"
      sudo rm -f /etc/apt/trusted.gpg.d/microsoft.gpg || true
    fi
  fi
else
  info "Skipping VS Code removal (no --remove-vscode)."
fi

echo
info "✅ Uninstall complete."
echo "What was removed:"
[ "$KEEP_WORKSPACE" -eq 1 ] || echo " - Zephyr workspace: $WS_DIR"
if [ "$REMOVE_ALL_OPENOCD" -eq 1 ]; then
  echo " - OpenOCD: $OPENOCD_ROOT (all)"
else
  echo " - OpenOCD: $OPENOCD_ROOT/$OCD_VERSION"
fi
if [ "$REMOVE_VSCODE" -eq 1 ]; then
  echo " - VS Code 'raspberry-pi.raspberry-pi-pico' extension"
  echo " - VS Code package 'code' (apt)"
  [ "$PURGE_CODE_REPO" -eq 1 ] && echo " - Microsoft VS Code repo + key"
fi
