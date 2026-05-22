#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERR]${NC} $*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { error "Missing command: $1"; exit 1; }
}

download_file() {
  local url="$1"
  local output="$2"

  info "Downloading $(basename "$output")"
  curl -fL --progress-bar -o "$output" "$url"
  local size
  size="$(du -h "$output" | cut -f1)"
  success "Downloaded $(basename "$output") (${size})"
}

RUNNER_VERSION="2.328.0"
RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner-direttaos}"
RUNNER_NAME="${RUNNER_NAME:-$(hostname)-diretta-builder}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,x64,diretta-builder}"
GH_REPO="${GH_REPO:-niver2002/DirettaOs}"
SDK_DIR="${SDK_DIR:-$HOME/audio/DirettaHostSDK_149}"
SDK_ARCHIVE="${SDK_ARCHIVE:-${SYNC_ASSET_DIR:-$HOME/syncdisk/diretta-assets}/DirettaHostSDK_149_6.tar.zst}"

info "DirettaOs self-hosted runner setup"

require_cmd curl
require_cmd tar
require_cmd sudo

if [ -f /etc/debian_version ]; then
  info "Installing Ubuntu/Debian dependencies"
  sudo apt-get update
  sudo apt-get install -y git curl tar jq build-essential zstd \
    libavformat-dev libavcodec-dev libavutil-dev libswresample-dev \
    libupnp-dev ethtool pkg-config
elif [ -f /etc/arch-release ]; then
  info "Installing Arch dependencies"
  sudo pacman -Sy --noconfirm --needed git curl tar jq base-devel zstd \
    ffmpeg libupnp ethtool pkgconf
else
  warn "Unknown distro. Install git curl tar jq build-essential/libupnp/ffmpeg deps manually if needed."
fi

mkdir -p "$HOME/audio"
if [ ! -d "$SDK_DIR/lib" ] || [ ! -d "$SDK_DIR/Host" ]; then
  if [ -f "$SDK_ARCHIVE" ]; then
    info "Extracting SDK archive from $SDK_ARCHIVE to $HOME/audio"
    tar --zstd -xf "$SDK_ARCHIVE" -C "$HOME/audio"
  else
    warn "SDK archive not found at $SDK_ARCHIVE"
  fi
fi

if [ -d "$SDK_DIR/lib" ] && [ -d "$SDK_DIR/Host" ]; then
  success "Detected SDK at ${SDK_DIR}"
else
  warn "SDK layout not found at ${SDK_DIR}. Builds will fail until DIRETTA_SDK_PATH points to a valid SDK."
fi

if [ -z "${RUNNER_TOKEN:-}" ] && command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    info "Requesting runner registration token via GitHub CLI"
    RUNNER_TOKEN="$(gh api --method POST "repos/${GH_REPO}/actions/runners/registration-token" --jq .token 2>/dev/null || true)"
  fi
fi

echo
if [ -z "${RUNNER_TOKEN:-}" ]; then
  echo "Get a runner registration token from:"
  echo "  https://github.com/${GH_REPO}/settings/actions/runners/new"
  echo
  read -r -p "Paste RUNNER_TOKEN: " RUNNER_TOKEN
fi

if [ -z "${RUNNER_TOKEN:-}" ]; then
  error "RUNNER_TOKEN is required"
  exit 1
fi

mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

if [ ! -f ./config.sh ]; then
  info "Downloading GitHub Actions runner v${RUNNER_VERSION}"
  download_file \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    "actions-runner.tar.gz"
  tar xzf actions-runner.tar.gz
  rm -f actions-runner.tar.gz
fi

if [ -f .runner ]; then
  warn "Runner already configured in $RUNNER_DIR"
else
  info "Configuring runner for ${GH_REPO}"
  ./config.sh \
    --url "https://github.com/${GH_REPO}" \
    --token "$RUNNER_TOKEN" \
    --name "$RUNNER_NAME" \
    --labels "$RUNNER_LABELS" \
    --work _work \
    --replace
fi

mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/github-runner-direttaos.service" <<EOF
[Unit]
Description=GitHub Actions Runner for ${GH_REPO}
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${RUNNER_DIR}
Environment=DIRETTA_SDK_PATH=${SDK_DIR}
ExecStart=${RUNNER_DIR}/run.sh
Restart=always
RestartSec=10
KillSignal=SIGTERM
TimeoutStopSec=30

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload || true
systemctl --user enable github-runner-direttaos.service || true

cat > "$HOME/start-runner-direttaos.sh" <<EOF
#!/usr/bin/env bash
export DIRETTA_SDK_PATH="${SDK_DIR}"
cd "${RUNNER_DIR}"
exec ./run.sh
EOF
chmod +x "$HOME/start-runner-direttaos.sh"

cat > "$HOME/start-runner-direttaos-bg.sh" <<EOF
#!/usr/bin/env bash
export DIRETTA_SDK_PATH="${SDK_DIR}"
cd "${RUNNER_DIR}"
nohup ./run.sh > "$HOME/runner-direttaos.log" 2>&1 &
echo "Runner started. Log: $HOME/runner-direttaos.log"
EOF
chmod +x "$HOME/start-runner-direttaos-bg.sh"

cat > "$HOME/runner-direttaos-status.sh" <<'EOF'
#!/usr/bin/env bash
if pgrep -f "Runner.Listener" >/dev/null; then
  echo "RUNNING pid=$(pgrep -f Runner.Listener | paste -sd, -)"
else
  echo "STOPPED"
fi
EOF
chmod +x "$HOME/runner-direttaos-status.sh"

success "Runner setup complete"
echo
echo "Foreground start: $HOME/start-runner-direttaos.sh"
echo "Background start: $HOME/start-runner-direttaos-bg.sh"
echo "Status:           $HOME/runner-direttaos-status.sh"
echo "Service:          systemctl --user start github-runner-direttaos.service"
