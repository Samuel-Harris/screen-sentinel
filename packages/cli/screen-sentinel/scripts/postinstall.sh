#!/bin/sh
# postinstall script — ensures runtime dependencies are present
# Runs automatically after `npm install screen-sentinel` or `bunx screen-sentinel`

set -e

check_ffmpeg() {
    if command -v ffmpeg >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

install_ffmpeg_macos() {
    arch=$(uname -m)
    if [ "$arch" = "arm64" ]; then
        FFMPEG_URL="https://ffmpeg.martin-riedl.de/redirect/latest/macos/arm64/release/ffmpeg.zip"
    else
        FFMPEG_URL="https://ffmpeg.martin-riedl.de/redirect/latest/macos/amd64/release/ffmpeg.zip"
    fi

    echo "Screen Sentinel: downloading ffmpeg..."
    TMP_DIR=$(mktemp -d)
    if curl -sL "$FFMPEG_URL" -o "$TMP_DIR/ffmpeg.zip"; then
        cd "$TMP_DIR"
        unzip -q ffmpeg.zip
        mkdir -p "$HOME/.local/bin"
        mv ffmpeg "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/ffmpeg"
        xattr -d com.apple.quarantine "$HOME/.local/bin/ffmpeg" 2>/dev/null || true
        cd - >/dev/null
        rm -rf "$TMP_DIR"
        echo "Screen Sentinel: ffmpeg installed to ~/.local/bin/ffmpeg"
    else
        echo "Screen Sentinel: warning: failed to download ffmpeg"
        echo "Screen Sentinel: install it manually: brew install ffmpeg"
    fi
}

install_ffmpeg_linux() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "Screen Sentinel: installing ffmpeg via apt..."
        sudo apt-get install -qq -y ffmpeg 2>/dev/null || echo "Screen Sentinel: warning: failed to install ffmpeg (try: sudo apt install ffmpeg)"
    elif command -v dnf >/dev/null 2>&1; then
        echo "Screen Sentinel: installing ffmpeg via dnf..."
        sudo dnf install -q -y ffmpeg 2>/dev/null || echo "Screen Sentinel: warning: failed to install ffmpeg (try: sudo dnf install ffmpeg)"
    elif command -v pacman >/dev/null 2>&1; then
        echo "Screen Sentinel: installing ffmpeg via pacman..."
        sudo pacman -S --noconfirm --quiet ffmpeg 2>/dev/null || echo "Screen Sentinel: warning: failed to install ffmpeg (try: sudo pacman -S ffmpeg)"
    else
        echo "Screen Sentinel: warning: ffmpeg not found. install it manually."
    fi
}

install_linux_deps() {
    # Check for libasound
    if ! ldconfig -p 2>/dev/null | grep -q "libasound.so.2"; then
        if command -v apt-get >/dev/null 2>&1; then
            echo "Screen Sentinel: installing libasound2-dev..."
            sudo apt-get install -qq -y libasound2-dev 2>/dev/null || true
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -q -y alsa-lib 2>/dev/null || true
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm --quiet alsa-lib 2>/dev/null || true
        fi
    fi
}

# Remove macOS quarantine from the binary
remove_quarantine() {
    if [ "$(uname)" = "Darwin" ]; then
        # Find the platform package binary
        SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
        PKG_DIR=$(dirname "$SCRIPT_DIR")
        NODE_MODULES=$(dirname "$PKG_DIR")
        for pkg in "@screen-sentinel/cli-darwin-arm64" "@screen-sentinel/cli-darwin-x64"; do
            BIN="$NODE_MODULES/$pkg/bin/screen-sentinel"
            if [ -f "$BIN" ]; then
                xattr -d com.apple.quarantine "$BIN" 2>/dev/null || true
            fi
        done
    fi
}

# Main
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

if ! check_ffmpeg; then
    case "$OS" in
        darwin) install_ffmpeg_macos ;;
        linux) install_ffmpeg_linux ;;
    esac
fi

if [ "$OS" = "linux" ]; then
    install_linux_deps
fi

remove_quarantine

sanitize_json_fallback() {
    printf '%s' "$1" | LC_ALL=C tr -c 'A-Za-z0-9._:-' '_'
}

build_posthog_payload() {
    if command -v node >/dev/null 2>&1; then
        SCREEN_SENTINEL_POSTHOG_OS="$OS" SCREEN_SENTINEL_POSTHOG_ARCH="$(uname -m)" node <<'NODE'
const { hostname } = require("node:os");

function firstEnv(names) {
  for (const name of names) {
    const value = process.env[name];
    if (typeof value === "string" && value.trim()) {
      return value.trim();
    }
  }
  return undefined;
}

function supportTelemetryContext() {
  const context = {};
  const supportId = firstEnv(["SCREEN_SENTINEL_SUPPORT_ID", "SCREEN_SENTINEL_TELEMETRY_ID"]);
  const customerId = firstEnv([
    "SCREEN_SENTINEL_CUSTOMER_ID",
    "SCREEN_SENTINEL_ORG_ID",
    "SCREEN_SENTINEL_TELEMETRY_CUSTOMER_ID",
  ]);
  const deploymentId = firstEnv([
    "SCREEN_SENTINEL_DEPLOYMENT_ID",
    "SCREEN_SENTINEL_TELEMETRY_DEPLOYMENT_ID",
  ]);
  const embedder = firstEnv([
    "SCREEN_SENTINEL_EMBEDDER",
    "SCREEN_SENTINEL_HOST_APP",
    "SCREEN_SENTINEL_TELEMETRY_HOST_APP",
  ]);
  const embedderVersion = firstEnv([
    "SCREEN_SENTINEL_EMBEDDER_VERSION",
    "SCREEN_SENTINEL_HOST_VERSION",
    "SCREEN_SENTINEL_TELEMETRY_HOST_VERSION",
  ]);

  if (supportId) context.screen_sentinel_support_id = supportId;
  if (customerId) context.screen_sentinel_customer_id = customerId;
  if (deploymentId) context.screen_sentinel_deployment_id = deploymentId;
  if (embedder) context.screen_sentinel_embedder = embedder;
  if (embedderVersion) context.screen_sentinel_embedder_version = embedderVersion;
  return context;
}

const supportContext = supportTelemetryContext();
const properties = {
  distinct_id:
    firstEnv(["SCREEN_SENTINEL_ANALYTICS_ID", "SCREEN_SENTINEL_SUPPORT_ID", "SCREEN_SENTINEL_TELEMETRY_ID"]) ||
    hostname(),
  os: process.env.SCREEN_SENTINEL_POSTHOG_OS || "",
  arch: process.env.SCREEN_SENTINEL_POSTHOG_ARCH || "",
  ...supportContext,
};

if (Object.keys(supportContext).length > 0) {
  properties.$set = supportContext;
}

process.stdout.write(
  JSON.stringify({
    api_key: "phc_z7FZXE8vmXtdTQ78LMy3j1BQWW4zP6PGDUP46rgcdnb",
    event: "cli_install_npm",
    properties,
  }),
);
NODE
        return
    fi

    # Minimal fallback for direct shell runs where Node is unavailable.
    printf '%s' "{\"api_key\":\"phc_z7FZXE8vmXtdTQ78LMy3j1BQWW4zP6PGDUP46rgcdnb\",\"event\":\"cli_install_npm\",\"properties\":{\"distinct_id\":\"$(sanitize_json_fallback "$(hostname)")\",\"os\":\"$(sanitize_json_fallback "$OS")\",\"arch\":\"$(sanitize_json_fallback "$(uname -m)")\"}}}"
}

POSTHOG_PAYLOAD=$(build_posthog_payload 2>/dev/null || true)

# PostHog install tracking (non-blocking)
if [ -n "$POSTHOG_PAYLOAD" ]; then
    curl -sL -X POST https://us.i.posthog.com/capture/ \
        -H "Content-Type: application/json" \
        -d "$POSTHOG_PAYLOAD" >/dev/null 2>&1 || true
fi

echo "Screen Sentinel: ready! run: screen-sentinel status"
