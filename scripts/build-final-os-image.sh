#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/work/DirettaOs}"
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_DIR/out}"
GH_REPO="${GH_REPO:-niver2002/DirettaOs}"
DIRETTA_SDK_PATH="${DIRETTA_SDK_PATH:-$HOME/audio/DirettaHostSDK_149}"
BASE_IMAGE_PATH="${BASE_IMAGE_PATH:-}"
BOOT_FIRMWARE_DIR="${BOOT_FIRMWARE_DIR:-}"
BOARD_PACK="${BOARD_PACK:-raspberry-pi-5}"
PAYLOAD_MODE="${PAYLOAD_MODE:-diretta-personal-use}"

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
fail() { printf '[ERR] %s\n' "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing command: $1"
}

require_cmd git
require_cmd bash

[ -d "$REPO_DIR/.git" ] || fail "Repository not found at $REPO_DIR"
[ -d "$DIRETTA_SDK_PATH/Host" ] || fail "SDK headers not found at $DIRETTA_SDK_PATH/Host"
[ -d "$DIRETTA_SDK_PATH/lib" ] || fail "SDK libraries not found at $DIRETTA_SDK_PATH/lib"

cd "$REPO_DIR"
info "Updating repository"
git pull --ff-only

chmod +x scripts/build-appliance-image.sh

ARGS=(--board-pack "$BOARD_PACK" --payload-mode "$PAYLOAD_MODE")
if [ -n "$BASE_IMAGE_PATH" ]; then
  ARGS+=(--base-image "$BASE_IMAGE_PATH")
fi
if [ -n "$BOOT_FIRMWARE_DIR" ]; then
  ARGS+=(--boot-firmware-dir "$BOOT_FIRMWARE_DIR")
fi

info "Running appliance image build"
DIRETTA_SDK_PATH="$DIRETTA_SDK_PATH" ./scripts/build-appliance-image.sh "${ARGS[@]}"

LATEST_IMG="$(find "$OUTPUT_DIR/artifacts" -maxdepth 1 -type f -name '*.img' | sort | tail -1 || true)"
if [ -n "$LATEST_IMG" ]; then
  info "Final raw image built: $LATEST_IMG"
else
  warn "No raw .img file was produced. Provide BASE_IMAGE_PATH or BOOT_FIRMWARE_DIR for final image output."
fi

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  info "Uploading artifacts to GitHub workflow run is handled by self-hosted workflow; local build artifacts are left in $OUTPUT_DIR/artifacts"
fi
