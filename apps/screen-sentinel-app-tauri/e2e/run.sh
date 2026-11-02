#!/usr/bin/env bash
# Screen Sentinel — AI that knows everything you've seen
# https://github.com/Samuel-Harris/screen-sentinel
# Build Screen Sentinel (debug, no bundle) then run cross-platform E2E tests.
# Run from app root: ./e2e/run.sh   or from e2e: ./run.sh
set -e
APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_ROOT"
echo "Building Screen Sentinel (debug, no bundle, with e2e webdriver)..."
# NEXT_PUBLIC_SCREEN_SENTINEL_E2E bypasses the billing gate by default so the suite
# exercises real features; the dedicated entitlement-gate spec re-enables it.
NEXT_PUBLIC_SCREEN_SENTINEL_E2E=true bun tauri build --no-sign --debug --verbose --no-bundle -- --features e2e
echo "Running E2E..."
bun run test:e2e
