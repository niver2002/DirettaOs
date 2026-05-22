#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REF_DIR="$ROOT_DIR/references/DirettaRendererUPnP"
IMAGE_DIR="$ROOT_DIR/image"

BOARD_PACK="raspberry-pi-5"
CHANNEL="stable"
PAYLOAD_MODE="diretta-personal-use"
VERSION="$(date +%Y.%m.%d-%H%M)"
OUTPUT_DIR="$ROOT_DIR/out"
IMAGE_ID=""
ARCH_NAME="${ARCH_NAME:-}"
DIRETTA_SDK_PATH="${DIRETTA_SDK_PATH:-}"

log() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*"
}

fail() {
  printf '[ERR] %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: build-appliance-image.sh [options]

Options:
  --board-pack <name>      Board pack name (default: raspberry-pi-5)
  --channel <name>         Release channel (default: stable)
  --payload-mode <mode>    diretta-personal-use | platform-only (default: diretta-personal-use)
  --version <value>        Build version string
  --output-dir <path>      Output root directory (default: ./out)
  --image-id <value>       Override generated image id
  --arch-name <value>      Override Diretta SDK architecture variant
  --sdk-path <path>        Diretta SDK path (or use DIRETTA_SDK_PATH env)
EOF
}

copy_tree() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a "$src/" "$dst/"
  else
    cp -a "$src/." "$dst/"
  fi
}

resolve_arch_name() {
  case "$BOARD_PACK" in
    raspberry-pi-5|cm5-reference)
      printf 'aarch64-linux-15k16\n'
      ;;
    raspberry-pi-4|cm4-reference)
      printf 'aarch64-linux-15\n'
      ;;
    *)
      fail "Unsupported board pack: $BOARD_PACK"
      ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --board-pack)
      BOARD_PACK="$2"
      shift 2
      ;;
    --channel)
      CHANNEL="$2"
      shift 2
      ;;
    --payload-mode)
      PAYLOAD_MODE="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --image-id)
      IMAGE_ID="$2"
      shift 2
      ;;
    --arch-name)
      ARCH_NAME="$2"
      shift 2
      ;;
    --sdk-path)
      DIRETTA_SDK_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

BOARD_DIR="$IMAGE_DIR/boards/$BOARD_PACK"
[ -d "$BOARD_DIR" ] || fail "Board pack directory not found: $BOARD_DIR"

if [ -z "$ARCH_NAME" ]; then
  ARCH_NAME="$(resolve_arch_name)"
fi

if [ -z "$IMAGE_ID" ]; then
  IMAGE_ID="direttaos-${BOARD_PACK}-${CHANNEL}-${VERSION}"
fi

if [ "$PAYLOAD_MODE" != "diretta-personal-use" ] && [ "$PAYLOAD_MODE" != "platform-only" ]; then
  fail "Unsupported payload mode: $PAYLOAD_MODE"
fi

STAGE_ROOT="$OUTPUT_DIR/stage/$IMAGE_ID"
ROOTFS_DIR="$STAGE_ROOT/rootfs"
ARTIFACT_DIR="$OUTPUT_DIR/artifacts"
METADATA_DIR="$STAGE_ROOT/metadata"
PAYLOAD_INSTALL_PATH="/opt/diretta-renderer-upnp"
APPLIANCE_ROOT="$ROOTFS_DIR/opt/diretta-appliance"
PAYLOAD_ROOT="$ROOTFS_DIR${PAYLOAD_INSTALL_PATH}"

rm -rf "$STAGE_ROOT"
mkdir -p \
  "$ROOTFS_DIR/etc/diretta-appliance" \
  "$ROOTFS_DIR/etc/default" \
  "$ROOTFS_DIR/etc/systemd/system" \
  "$ROOTFS_DIR/usr/share/diretta-appliance" \
  "$APPLIANCE_ROOT" \
  "$ARTIFACT_DIR" \
  "$METADATA_DIR"

log "Preparing base appliance layout for $BOARD_PACK"
copy_tree "$IMAGE_DIR/common/presets" "$ROOTFS_DIR/usr/share/diretta-appliance/presets"
copy_tree "$IMAGE_DIR/onboarding" "$APPLIANCE_ROOT/onboarding"
cp "$IMAGE_DIR/onboarding/diretta-onboarding.service" "$METADATA_DIR/diretta-onboarding.service.source"
cp "$IMAGE_DIR/boards/$BOARD_PACK/README.md" "$METADATA_DIR/board-pack-readme.md"
[ -f "$IMAGE_DIR/boards/$BOARD_PACK/QUALIFICATION.md" ] && cp "$IMAGE_DIR/boards/$BOARD_PACK/QUALIFICATION.md" "$METADATA_DIR/qualification.md"
cp "$IMAGE_DIR/manifests/SCHEMA.md" "$METADATA_DIR/manifest-schema.md"
cp "$IMAGE_DIR/manifests/README.md" "$METADATA_DIR/manifest-readme.md"
cp "$IMAGE_DIR/updates/README.md" "$METADATA_DIR/update-policy.md"

cat > "$ROOTFS_DIR/etc/systemd/system/diretta-onboarding.service" <<EOF
[Unit]
Description=Diretta Appliance Onboarding Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/diretta-appliance/onboarding/onboarding_webui.py \
    --profile /opt/diretta-appliance/onboarding/profiles/diretta_appliance_onboarding.json \
    --port 8088
Restart=on-failure
RestartSec=5
ProtectSystem=strict
ReadWritePaths=/etc/diretta-appliance
ProtectHome=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

printf 'onboarding-required\n' > "$ROOTFS_DIR/etc/diretta-appliance/state"

DIRETTA_ENABLED=false
PAYLOAD_PRESENT=false

if [ "$PAYLOAD_MODE" = "diretta-personal-use" ]; then
  [ -n "$DIRETTA_SDK_PATH" ] || fail "DIRETTA_SDK_PATH is required for payload mode $PAYLOAD_MODE"
  [ -d "$DIRETTA_SDK_PATH/Host" ] || fail "SDK headers not found at $DIRETTA_SDK_PATH/Host"
  [ -d "$DIRETTA_SDK_PATH/lib" ] || fail "SDK libraries not found at $DIRETTA_SDK_PATH/lib"

  log "Building DirettaRendererUPnP for $ARCH_NAME"
  make -C "$REF_DIR" clean >/dev/null
  make -C "$REF_DIR" DIRETTA_SDK_PATH="$DIRETTA_SDK_PATH" ARCH_NAME="$ARCH_NAME"

  [ -f "$REF_DIR/bin/DirettaRendererUPnP" ] || fail "Expected build output not found: $REF_DIR/bin/DirettaRendererUPnP"

  log "Staging runtime payload"
  mkdir -p "$PAYLOAD_ROOT" "$PAYLOAD_ROOT/systemd" "$PAYLOAD_ROOT/webui"
  cp "$REF_DIR/bin/DirettaRendererUPnP" "$PAYLOAD_ROOT/"
  cp "$REF_DIR/systemd/start-renderer.sh" "$PAYLOAD_ROOT/start-renderer.sh"
  copy_tree "$REF_DIR/webui" "$PAYLOAD_ROOT/webui"
  cp "$REF_DIR/systemd/diretta-renderer.conf" "$ROOTFS_DIR/etc/default/diretta-renderer"
  cp "$REF_DIR/systemd/diretta-renderer.service" "$ROOTFS_DIR/etc/systemd/system/diretta-renderer.service"
  cp "$REF_DIR/webui/diretta-renderer-webui.service" "$ROOTFS_DIR/etc/systemd/system/diretta-renderer-webui.service"
  cp "$REF_DIR/systemd/install-systemd.sh" "$METADATA_DIR/install-systemd.sh"
  cp "$REF_DIR/systemd/uninstall-systemd.sh" "$METADATA_DIR/uninstall-systemd.sh"

  DIRETTA_ENABLED=true
  PAYLOAD_PRESENT=true
else
  warn "Building platform-only image without Diretta runtime payload"
fi

cat > "$ROOTFS_DIR/etc/diretta-appliance/image.env" <<EOF
image_id=${IMAGE_ID}
version=${VERSION}
channel=${CHANNEL}
board_pack=${BOARD_PACK}
arch_name=${ARCH_NAME}
payload_mode=${PAYLOAD_MODE}
diretta_enabled=${DIRETTA_ENABLED}
payload_present=${PAYLOAD_PRESENT}
recovery_profile=default
qualification_status=prototype
EOF

cat > "$ROOTFS_DIR/etc/diretta-appliance/payload.env" <<EOF
payload_id=diretta-runtime
payload_mode=${PAYLOAD_MODE}
license_scope=personal-use-only
sdk_supply=predeployed-or-user-provided
sdk_source=official-diretta-channel
authorization_model=official-user-selection-and-authorization
service_name=diretta-renderer
config_path=/etc/default/diretta-renderer
install_path=${PAYLOAD_INSTALL_PATH}
EOF

ROOTFS_ARCHIVE="$ARTIFACT_DIR/${IMAGE_ID}-rootfs.tar.gz"
MANIFEST_ARCHIVE="$ARTIFACT_DIR/${IMAGE_ID}-metadata.tar.gz"

log "Packaging rootfs artifact"
tar -C "$ROOTFS_DIR" -czf "$ROOTFS_ARCHIVE" .
sha256sum "$ROOTFS_ARCHIVE" > "$ROOTFS_ARCHIVE.sha256"

tar -C "$METADATA_DIR" -czf "$MANIFEST_ARCHIVE" .
sha256sum "$MANIFEST_ARCHIVE" > "$MANIFEST_ARCHIVE.sha256"

log "Build complete"
printf 'Rootfs artifact: %s\n' "$ROOTFS_ARCHIVE"
printf 'Metadata artifact: %s\n' "$MANIFEST_ARCHIVE"
