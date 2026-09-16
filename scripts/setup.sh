#!/usr/bin/env bash
set -euo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="$LAB_ROOT/.tools"
SUITE_DIR="$TOOLS_DIR/oss-cad-suite"
ARCHIVE="$TOOLS_DIR/oss-cad-suite.tgz"
RELEASE="2026-09-15"
RELEASE_STAMP="20260915"

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)
    PLATFORM="darwin-arm64"
    ;;
  Darwin-x86_64)
    PLATFORM="darwin-x64"
    ;;
  Linux-x86_64)
    PLATFORM="linux-x64"
    ;;
  Linux-aarch64|Linux-arm64)
    PLATFORM="linux-arm64"
    ;;
  *)
    echo "Unsupported platform: $(uname -s) $(uname -m)" >&2
    echo "Windows users should run scripts/setup-windows.ps1 from PowerShell." >&2
    exit 1
    ;;
esac

ASSET="oss-cad-suite-$PLATFORM-$RELEASE_STAMP.tgz"
URL="https://github.com/YosysHQ/oss-cad-suite-build/releases/download/$RELEASE/$ASSET"

for prerequisite in curl tar python3 make; do
  if ! command -v "$prerequisite" >/dev/null 2>&1; then
    echo "Missing prerequisite: $prerequisite" >&2
    echo "On WSL/Ubuntu run: sudo apt-get install -y curl make python3 python3-venv" >&2
    exit 1
  fi
done

mkdir -p "$TOOLS_DIR"
if [[ ! -x "$SUITE_DIR/bin/iverilog" ]]; then
  echo "Downloading OSS CAD Suite for $PLATFORM ($RELEASE)..."
  curl --fail --location --retry 3 --output "$ARCHIVE" "$URL"
  tar -xzf "$ARCHIVE" -C "$TOOLS_DIR"
  rm -f "$ARCHIVE"
fi

if command -v uv >/dev/null 2>&1; then
  if [[ ! -x "$LAB_ROOT/.venv/bin/python" ]]; then
    uv venv --python python3 "$LAB_ROOT/.venv"
  fi
  uv pip install --python "$LAB_ROOT/.venv/bin/python" \
    -r "$LAB_ROOT/requirements-dev.txt"
else
  if [[ ! -x "$LAB_ROOT/.venv/bin/python" ]]; then
    python3 -m venv "$LAB_ROOT/.venv"
  fi
  "$LAB_ROOT/.venv/bin/python" -m pip install \
    -r "$LAB_ROOT/requirements-dev.txt"
fi

echo "Setup complete. Run: make doctor && make test"
