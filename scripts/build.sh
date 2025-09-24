#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/_lib.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0") [-b <board>] [-a <app_dir>] [-s] [-- clean]
  -b BOARD   Zephyr board (e.g. rpi_pico, rpi_pico/rp2040/w, rpi_pico2/rp2350a/m33)
  -a APP     Application directory (default: app)
  -s         Enable snippet: usb_serial_port
  -- clean   Clean build directory before building

Examples:
  $(basename "$0") -b rpi_pico
  $(basename "$0") -b rpi_pico2/rp2350a/m33 -a samples/blinky -s

Artifacts: <app>/build
Workspace used (cwd): \$(zephyr_ws_dir)
EOF
}

BOARD=""
APP="app"
USE_USB_SNIPPET=0
DO_CLEAN=0

while (( "$#" )); do
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    -b) BOARD="$2"; shift 2 ;;
    -a) APP="$2"; shift 2 ;;
    -s) USE_USB_SNIPPET=1; shift ;;
    --) shift; break ;;
    clean|--clean) DO_CLEAN=1; shift ;;
    *) err "Unknown arg: $1"; usage; exit 2 ;;
  esac
done

[ -z "$BOARD" ] && { err "Missing -b <board>"; usage; exit 2; }

WS_DIR="$(zephyr_ws_dir)"
[ -d "$WS_DIR/.west" ] || { err "Zephyr workspace not found at $WS_DIR. Run setup_zephyr_minimal.sh first."; exit 1; }

REPO_ROOT="$(abspath "$(dirname "$0")/..")"
if [ -d "$APP" ] || [ -f "$APP/CMakeLists.txt" ]; then
  APP_ABS="$(abspath "$APP")"
else
  APP_ABS="$(abspath "$REPO_ROOT/$APP")"
fi
[ -f "$APP_ABS/CMakeLists.txt" ] || { err "App not found or missing CMakeLists.txt: $APP_ABS"; exit 1; }

WEST="$(ws_west)"; need_cmd "$WEST"

# ---- OpenOCD detection (robust) ----
# Preferred root under ~/.pico-sdk, fallback to ../openocd next to repo
OPENOCD_DIR=""
CAND1="$HOME/.pico-sdk/openocd"
CAND2="$(abspath "$REPO_ROOT/../openocd")"
if [ -d "$CAND1" ]; then OPENOCD_DIR="$CAND1"; elif [ -d "$CAND2" ]; then OPENOCD_DIR="$CAND2"; fi

OPENOCD_BIN=""
OPENOCD_SCRIPTS=""

if [ -n "$OPENOCD_DIR" ]; then
  # Find the first executable named 'openocd' or 'openocd.exe'
  OPENOCD_BIN="$(find "$OPENOCD_DIR" -type f \( -name openocd -o -name openocd.exe \) -perm -111 2>/dev/null | head -n1 || true)"
  # Find the 'scripts' directory (pico packages ship it)
  OPENOCD_SCRIPTS="$(find "$OPENOCD_DIR" -type d -name scripts 2>/dev/null | head -n1 || true)"
fi

CMAKE_ARGS=()
if [ -n "$OPENOCD_BIN" ] && [ -n "$OPENOCD_SCRIPTS" ]; then
  CMAKE_ARGS+=("-DOPENOCD=$OPENOCD_BIN" "-DOPENOCD_DEFAULT_PATH=$OPENOCD_SCRIPTS")
  info "Auto-detected OpenOCD: $OPENOCD_BIN"
else
  warn "OpenOCD not auto-detected; relying on environment or board defaults."
fi

# ---- Snippet handling ----
SNIPPET_ARGS=()
PRISTINE="auto"
SNIPPET_ROOT_ENV=""
if [ "$USE_USB_SNIPPET" -eq 1 ]; then
  SNIPPET_DIR_REPO="$REPO_ROOT/snippets/usb_serial_port"
  SNIPPET_DIR_APP="$APP_ABS/../snippets/usb_serial_port"  # fallback if someone keeps snippets next to app
  if [ -f "$SNIPPET_DIR_REPO/snippet.yml" ]; then
    SNIPPET_ROOT_ENV="$REPO_ROOT"
    info "Using snippet 'usb_serial_port' from: $SNIPPET_DIR_REPO"

    SNIPPET_ARGS+=("-S" "usb_serial_port")
    PRISTINE="always"    # changing snippets requires pristine build
  elif [ -f "$SNIPPET_DIR_APP/snippet.yml" ]; then
    SNIPPET_ROOT_ENV="$(cd "$APP_ABS/.." && pwd)"
    info "Using snippet 'usb_serial_port' from: $SNIPPET_DIR_APP"

    SNIPPET_ARGS+=("-S" "usb_serial_port")
    PRISTINE="always"    # changing snippets requires pristine build
  else
    warn "Snippet 'usb_serial_port' not found under $REPO_ROOT/snippets or $APP_ABS/../snippets"
  fi
fi

# ---- Build dir lives inside the project ----
BUILD_DIR="$APP_ABS/build"
[ "$DO_CLEAN" -eq 1 ] && { info "Cleaning $BUILD_DIR"; rm -rf "$BUILD_DIR"; }
mkdir -p "$BUILD_DIR"

info "Building $BOARD from $APP_ABS"
set -x
cd "$WS_DIR"
SNIPPET_ROOT="$SNIPPET_ROOT_ENV" "$WEST" build \
    -d "$BUILD_DIR" \
    -b "$BOARD" \
    "$APP_ABS" \
    -p "$PRISTINE" \
    "${SNIPPET_ARGS[@]}" \
    -- \
    "${CMAKE_ARGS[@]}"
set +x

info "Done. Artifacts in $BUILD_DIR"

UF2="$BUILD_DIR/zephyr/zephyr.uf2"
ELF="$BUILD_DIR/zephyr/zephyr.elf"

if [ -f "$UF2" ]; then
  info "UF2: $UF2"
else
  warn "UF2 not found at $UF2 (some boards/configs don't produce UF2)."
fi

if [ -f "$ELF" ]; then
  info "ELF: $ELF"
else
  warn "ELF not found at $ELF"
fi

# Report snippet status from the CMake cache (support multiple key names)
CACHE="$BUILD_DIR/CMakeCache.txt"
if [ -f "$CACHE" ]; then
  SNIP_VAL=""
  SNIP_VAL="${SNIP_VAL:-$(sed -n 's/^SNIPPET:STRING=//p'          "$CACHE" | head -n1)}"
  SNIP_VAL="${SNIP_VAL:-$(sed -n 's/^CACHED_SNIPPET:STRING=//p'   "$CACHE" | head -n1)}"

  if [ -n "$SNIP_VAL" ]; then
    info "CMake reports snippet=$SNIP_VAL"
  else
    info "No snippet recorded in CMakeCache."
  fi
fi
