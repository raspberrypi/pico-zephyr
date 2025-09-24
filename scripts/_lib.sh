#!/usr/bin/env bash
# Library only — do NOT set bash options here.

# Pretty output
info() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

# Accept either PATH command or absolute path
need_cmd() {
  bin="$1"
  if command -v "$bin" >/dev/null 2>&1; then return 0; fi
  if [ -x "$bin" ]; then return 0; fi
  err "Missing required command: $bin"
  exit 1
}

# Run 'apt update' once per process
apt_update_once() {
  if ! command -v apt >/dev/null 2>&1; then
    return 0
  fi
  if [ "${APT_UPDATED:-0}" != "1" ]; then
    sudo apt update -y
    APT_UPDATED=1; export APT_UPDATED
  fi
}

ensure_pkg() {
  if command -v apt >/dev/null 2>&1; then
    apt_update_once
    sudo apt install -y --no-install-recommends "$@"
  else
    warn "apt not available; please install packages manually: $*"
  fi
}

# Absolute path helper
abspath() {
  python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$1"
}

# Detect Raspberry Pi OS
is_rpi_os() { [ -f /etc/rpi-issue ]; }

# Workspace paths
zephyr_ws_dir() { echo "$HOME/.pico-sdk/zephyr_workspace"; }
ws_venv_dir()   { echo "$(zephyr_ws_dir)/venv"; }
ws_venv_bin()   { echo "$(ws_venv_dir)/bin"; }
ws_python()     { echo "$(ws_venv_bin)/python"; }
ws_pip()        { echo "$(ws_venv_bin)/pip"; }
ws_west()       { echo "$(ws_venv_bin)/west"; }

# Create venv (venv -> virtualenv fallback), no brace-groups
create_ws_venv() {
  vdir="$(ws_venv_dir)"
  if [ -x "$(ws_python)" ]; then
    info "Existing Zephyr venv found at $vdir"
    return 0
  fi

  info "Creating Zephyr venv at $vdir"
  if python3 -m venv "$vdir"; then
    return 0
  fi

  warn "Failed to create venv with 'venv'; trying 'virtualenv'..."
  if ! python3 -m virtualenv --version >/dev/null 2>&1; then
    if ! python3 -m pip install --user virtualenv; then
      err "Could not install virtualenv"
      return 1
    fi
  fi
  if ! python3 -m virtualenv "$vdir"; then
    err "virtualenv failed to create $vdir"
    return 1
  fi
}

# Copy manifest from repo into workspace/manifest (no brace-groups)
copy_manifest_into_ws() {
  if [ -n "${REPO_ROOT:-}" ]; then
    repo_root="$REPO_ROOT"
  else
    # Derive repo root relative to this file
    this="${BASH_SOURCE:-$0}"
    this_dir="$(cd "$(dirname "$this")" 2>/dev/null && pwd)"
    if [ -z "$this_dir" ]; then this_dir="$(pwd)"; fi
    repo_root="$(cd "$this_dir/.." && pwd)"
  fi

  manifest_dst="$(zephyr_ws_dir)/manifest"
  mkdir -p "$manifest_dst"

  if [ -f "$repo_root/manifest/west.yml" ]; then
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --delete "$repo_root/manifest/" "$manifest_dst/"
    else
      cp -rf "$repo_root/manifest/." "$manifest_dst/"
    fi
  elif [ -f "$repo_root/west.yml" ]; then
    cp -f "$repo_root/west.yml" "$manifest_dst/west.yml"
  else
    warn "No manifest found (expected manifest/west.yml or west.yml) under $repo_root."
  fi
}
