#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/_lib.sh"

VERSION="${1:-0.12.0+dev}"
RELEASE="${2:-v2.2.0-2}"
PKG="openocd-${VERSION}-aarch64-lin.tar.gz"
URL="https://github.com/raspberrypi/pico-sdk-tools/releases/download/${RELEASE}/${PKG}"

OUT_DIR="$HOME/.pico-sdk/openocd/${VERSION}"

info "Preparing OpenOCD for Linux (${VERSION}, aarch64)"
ensure_pkg wget tar libhidapi-hidraw0

mkdir -p "$OUT_DIR"
cd "$(dirname "$0")"

if [ ! -f "$PKG" ]; then
  info "Downloading $URL"
  wget -q --show-progress "$URL"
else
  info "Using cached $PKG"
fi

info "Extracting to $OUT_DIR"
tar xzf "$PKG" -C "$OUT_DIR" --strip-components=0

# Normalize name + .exe shim for build portability
if [ -d "$OUT_DIR/openocd-${VERSION}" ] && [ ! -d "$OUT_DIR/openocd" ]; then
  mv "$OUT_DIR/openocd-${VERSION}" "$OUT_DIR/openocd"
fi

if [ ! -e "$OUT_DIR/openocd.exe" ]; then
  ln -s "$OUT_DIR/openocd" "$OUT_DIR/openocd.exe"
fi

info "OpenOCD installed at: $OUT_DIR"
