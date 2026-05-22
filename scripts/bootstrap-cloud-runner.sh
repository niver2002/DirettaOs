#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/niver2002/DirettaOs.git}"
REPO_DIR="${REPO_DIR:-$HOME/work/DirettaOs}"
SYNC_ASSET_DIR="${SYNC_ASSET_DIR:-$HOME/syncdisk/diretta-assets}"
SDK_ARCHIVE="${SDK_ARCHIVE:-$SYNC_ASSET_DIR/DirettaHostSDK_149_6.tar.zst}"
SDK_DIR="${SDK_DIR:-$HOME/audio/DirettaHostSDK_149}"
GH_REPO="${GH_REPO:-niver2002/DirettaOs}"
RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner-direttaos}"
RUNNER_NAME="${RUNNER_NAME:-$(hostname)-diretta-builder}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,x64,diretta-builder}"

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
error() { printf '[ERR] %s\n' "$*" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    error "Missing command: $1"
    exit 1
  }
}

copy_with_progress() {
  local source="$1"
  local target="$2"

  if command -v rsync >/dev/null 2>&1; then
    info "Copying $(basename "$source") to $(dirname "$target")"
    rsync -ah --info=progress2 "$source" "$target"
  else
    warn "rsync not available; using cp without progress"
    cp "$source" "$target"
  fi
}

require_cmd git
require_cmd bash
require_cmd tar

mkdir -p "$(dirname "$REPO_DIR")"
if [ -d "$REPO_DIR/.git" ]; then
  info "Repository already exists at $REPO_DIR; pulling latest main"
  git -C "$REPO_DIR" pull --ff-only
else
  info "Cloning $REPO_URL to $REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
fi

mkdir -p "$HOME/audio"
if [ ! -d "$SDK_DIR/Host" ] || [ ! -d "$SDK_DIR/lib" ]; then
  if [ -f "$SDK_ARCHIVE" ]; then
    info "Extracting SDK archive from $SDK_ARCHIVE"
    tar --zstd -xf "$SDK_ARCHIVE" -C "$HOME/audio"
  else
    local_sdk_download="$HOME/Downloads/DirettaHostSDK_149_6.tar.zst"
    if [ -f "$local_sdk_download" ]; then
      mkdir -p "$SYNC_ASSET_DIR"
      copy_with_progress "$local_sdk_download" "$SYNC_ASSET_DIR/"
      SDK_ARCHIVE="$SYNC_ASSET_DIR/DirettaHostSDK_149_6.tar.zst"
      info "Extracting SDK archive from $SDK_ARCHIVE"
      tar --zstd -xf "$SDK_ARCHIVE" -C "$HOME/audio"
    else
      warn "SDK archive not found at $SDK_ARCHIVE or $local_sdk_download"
    fi
  fi
fi

if [ ! -d "$SDK_DIR/Host" ] || [ ! -d "$SDK_DIR/lib" ]; then
  error "Expected SDK layout not found at $SDK_DIR"
  exit 1
fi

cd "$REPO_DIR"
chmod +x scripts/setup-runner.sh

export GH_REPO
export RUNNER_DIR
export RUNNER_NAME
export RUNNER_LABELS
export SDK_DIR
export SDK_ARCHIVE
export SYNC_ASSET_DIR

info "Running DirettaOs runner setup"
exec ./scripts/setup-runner.sh
