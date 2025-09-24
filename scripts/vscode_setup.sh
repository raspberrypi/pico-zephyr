#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/_lib.sh"

info "Installing Microsoft Visual Studio Code and the Raspberry Pi Pico extension."

ensure_pkg wget gpg apt-transport-https

if is_rpi_os; then
  info "Detected Raspberry Pi OS via /etc/rpi-issue. Using default repositories for VS Code."
  ensure_pkg code
else
  info "Non-Raspberry Pi OS detected. Ensuring Microsoft repo is configured for VS Code."
  
  # Only add repo if 'code' is not already available
  if ! apt-cache policy code 2>/dev/null | grep -q 'Candidate:'; then
    ensure_pkg wget gpg apt-transport-https
    if ! [ -f /etc/apt/trusted.gpg.d/microsoft.gpg ]; then
      wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg >/dev/null
    fi
    if ! [ -f /etc/apt/sources.list.d/vscode.list ]; then
      echo "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
      # Repo just added; refresh once
      export APT_UPDATED=0
    fi
  fi
  ensure_pkg code
fi

need_cmd code
code --install-extension raspberry-pi.raspberry-pi-pico --force

info "Microsoft Visual Studio Code setup done."
