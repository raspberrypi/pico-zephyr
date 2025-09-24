#!/usr/bin/env bash
set -Eeuo pipefail

# --------------------------- Config ---------------------------
PICOTOOL_VERSION="2.2.0-a4"
PICOTOOL_SDK_RELEASE="${PICOTOOL_SDK_RELEASE:-v2.2.0-2}"
PICOTOOL_BASE_URL="${PICOTOOL_BASE_URL:-https://github.com/raspberrypi/pico-sdk-tools/releases/download/${PICOTOOL_SDK_RELEASE}}"

INSTALL_ROOT="${HOME}/.pico-sdk/picotool"
INSTALL_DIR="${INSTALL_ROOT}/${PICOTOOL_VERSION}"
PICOTOOL_BIN="${INSTALL_DIR}/picotool"

ZEPHYR_WS="${HOME}/.pico-sdk/zephyr_workspace"
WEST_BIN="${ZEPHYR_WS}/venv/bin/west"

# ---------------------- Defaults & helpers --------------------
REPO_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROJECT="app"      # default project dir in this repo
TOOL="picotool"    # default flasher
WEST_DEBUG=0
ELF_OVERRIDE=""

log() { printf '[%s] %s\n' "$1" "$2"; }
info(){ log INFO "$1"; }
warn(){ log WARN "$1"; }
err() { log ERR  "$1" >&2; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -p, --project <dir>   Project folder in this repo (default: app)
      --west            Use west instead of picotool
      --west-debug      Use west debug (GDB/OpenOCD) instead of flash
      --elf <file>      Explicit zephyr.elf path to flash
  -h, --help            Show help

Environment:
  PICOTOOL_SDK_RELEASE  Tag under pico-sdk-tools (default: ${PICOTOOL_SDK_RELEASE})
  PICOTOOL_BASE_URL     Override full base URL (if mirroring)
EOF
}

# portable absolute-path function
abspath() {
  if command -v python3 >/dev/null 2>&1; then
    # pass arg as argv[1], and put the here-doc redirection at the end
    python3 - "$1" <<'PY'
import os, sys
print(os.path.abspath(sys.argv[1]))
PY
  elif command -v perl >/dev/null 2>&1; then
    perl -MCwd=abs_path -e 'print abs_path(shift)' "$1"
  else
    # POSIX fallback without attaching text after ')'
    dir=$(dirname -- "$1")
    base=$(basename -- "$1")
    ( cd -- "$dir" && printf '%s/%s\n' "$(pwd -P)" "$base" )
  fi
}

# ------------------------- Arg parsing ------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--project) PROJECT="$2"; shift 2;;
    --west) TOOL="west"; shift;;
    --west-debug) TOOL="west"; WEST_DEBUG=1; shift;;
    --elf) ELF_OVERRIDE="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) err "Unknown option: $1"; usage; exit 2;;
  esac
done

PROJECT_DIR_ABS="$(abspath "${REPO_ROOT}/${PROJECT}")"
# prefer per-project build/, else repo-level build/
if [[ -d "${PROJECT_DIR_ABS}/build" ]]; then
  BUILD_DIR_ABS="$(abspath "${PROJECT_DIR_ABS}/build")"
else
  BUILD_DIR_ABS="$(abspath "${REPO_ROOT}/build")"
fi
ELF_PATH="${ELF_OVERRIDE:-${BUILD_DIR_ABS}/zephyr/zephyr.elf}"

info "Repo    : ${REPO_ROOT}"
info "Project : ${PROJECT_DIR_ABS}"
info "Build   : ${BUILD_DIR_ABS}"
info "Mode    : ${TOOL}${WEST_DEBUG:+ (debug)}"

# ---------------------- Download picotool ---------------------
need_tools() {
  local ok=0
  for t in "$@"; do
    if ! command -v "$t" >/dev/null 2>&1; then
      warn "Missing tool: $t"
      ok=1
    fi
  done
  return $ok
}

dl() {  # curl preferred, wget fallback
  local url="$1" out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --progress-bar -o "$out" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress -O "$out" "$url"
  else
    err "Need curl or wget to download $url"; return 1
  fi
}

ensure_picotool() {
  if [[ -x "$PICOTOOL_BIN" ]]; then
    info "picotool present: $PICOTOOL_BIN"
    return
  fi
  info "Installing picotool ${PICOTOOL_VERSION} → ${INSTALL_DIR}"
  mkdir -p "$INSTALL_DIR"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  local os arch asset url
  os="$(uname -s)"; arch="$(uname -m)"
  case "$os" in
    Linux)
      case "$arch" in
        x86_64|amd64) asset="picotool-${PICOTOOL_VERSION}-x86_64-lin.tar.gz" ;;
        aarch64|arm64) asset="picotool-${PICOTOOL_VERSION}-aarch64-lin.tar.gz" ;;
        *) err "Unsupported Linux arch: ${arch}"; exit 1 ;;
      esac
      ;;
    Darwin) asset="picotool-${PICOTOOL_VERSION}-mac.zip" ;;
    *) err "Unsupported OS: ${os}"; exit 1 ;;
  esac

  url="${PICOTOOL_BASE_URL}/${asset}"
  info "Downloading ${url}"
  dl "$url" "${tmpdir}/${asset}"

  info "Extracting ${asset}"
  case "$asset" in
    *.tar.gz)
      need_tools tar >/dev/null && tar -C "$tmpdir" -xzf "${tmpdir}/${asset}" || { err "tar required"; exit 1; }
      ;;
    *.zip)
      if command -v unzip >/dev/null 2>&1; then unzip -q "${tmpdir}/${asset}" -d "$tmpdir"
      elif command -v ditto >/dev/null 2>&1; then ditto -xk "${tmpdir}/${asset}" "$tmpdir"
      else err "Need unzip or ditto to extract ${asset}"; exit 1
      fi
      ;;
  esac

  local found
  found="$(find "$tmpdir" -type f -name 'picotool' -perm -111 | head -n1 || true)"
  [[ -n "$found" ]] || { err "picotool binary not found in archive"; exit 1; }
  cp "$found" "$PICOTOOL_BIN"
  chmod +x "$PICOTOOL_BIN"
  info "Installed picotool → $PICOTOOL_BIN"
}

# -------------------------- Actions --------------------------
flash_with_picotool() {
  ensure_picotool
  if [[ ! -f "$ELF_PATH" ]]; then
    err "Build artifact not found: ${ELF_PATH}"
    echo
    echo "Build it first, e.g.:"
    echo "  scripts/build.sh -p ${PROJECT} -b rpi_pico"
    echo "or with west:"
    echo "  ${WEST_BIN:-west} build -b rpi_pico -d ${BUILD_DIR_ABS} ${PROJECT_DIR_ABS}"
    exit 2
  fi
  info "Flashing with picotool → ${ELF_PATH}"
  "$PICOTOOL_BIN" load "$ELF_PATH" -fx
}

flash_with_west() {
  local west="${WEST_BIN}"
  [[ -x "$west" ]] || west="$(command -v west || true)"
  [[ -x "$west" ]] || { err "west not found (expected ${WEST_BIN}); set up your Zephyr venv"; exit 1; }

  if [[ ! -d "$BUILD_DIR_ABS" ]]; then
    err "Build directory not found: ${BUILD_DIR_ABS}"
    echo
    echo "Configure/build first:"
    echo "  $west build -b rpi_pico -d ${BUILD_DIR_ABS} ${PROJECT_DIR_ABS}"
    exit 2
  fi

  # IMPORTANT: run inside the zephyr workspace and use ABSOLUTE paths
  pushd "$ZEPHYR_WS" >/dev/null || { err "Zephyr workspace not found: ${ZEPHYR_WS}"; exit 1; }
  if [[ "$WEST_DEBUG" -eq 1 ]]; then
    info "Starting west debug (cwd=${ZEPHYR_WS}, -d ${BUILD_DIR_ABS})"
    "$west" debug -d "${BUILD_DIR_ABS}"
  else
    info "Flashing with west (cwd=${ZEPHYR_WS}, -d ${BUILD_DIR_ABS})"
    "$west" flash -d "${BUILD_DIR_ABS}"
  fi
  popd >/dev/null
}

case "$TOOL" in
  picotool) flash_with_picotool ;;
  west)     flash_with_west ;;
esac
