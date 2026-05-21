#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="/etc/pearl"
CONFIG_FILE="$CONFIG_DIR/pearl.env"
BIN_DIR="/usr/local/bin"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo bash install.sh"
  exit 1
fi

mkdir -p "$CONFIG_DIR" /opt/pearl /var/log/pearl /var/run/pearl

if [ ! -f "$CONFIG_FILE" ]; then
  if [ -f "$ROOT_DIR/config.env" ]; then
    install -m 0600 "$ROOT_DIR/config.env" "$CONFIG_FILE"
  else
    install -m 0600 "$ROOT_DIR/config.env.example" "$CONFIG_FILE"
  fi
  echo "Created $CONFIG_FILE"
else
  echo "Keeping existing $CONFIG_FILE"
fi

# shellcheck disable=SC1090
. "$CONFIG_FILE"

INSTALL_DIR="${INSTALL_DIR:-/opt/pearl}"
MINER_URL="${MINER_URL:-https://pearl.alphapool.tech/downloads/alpha-miner}"
mkdir -p "$INSTALL_DIR"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing command: $1"
    echo "Install it first, then rerun install.sh."
    exit 1
  }
}

need_cmd bash
need_cmd ssh
need_cmd nvidia-smi

if command -v curl >/dev/null 2>&1; then
  curl -fL --retry 3 --connect-timeout 20 -o "$INSTALL_DIR/alpha-miner" "$MINER_URL"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$INSTALL_DIR/alpha-miner" "$MINER_URL"
else
  echo "Missing curl/wget for downloading alpha-miner."
  exit 1
fi
chmod 0755 "$INSTALL_DIR/alpha-miner"

for script in "$ROOT_DIR"/bin/pearl-*; do
  install -m 0755 "$script" "$BIN_DIR/$(basename "$script")"
done

echo
echo "Installed Pearl scripts."
echo
echo "Next:"
echo "  pearl-up"
echo "  pearl-status"
echo
echo "Config:"
echo "  $CONFIG_FILE"
