#!/bin/bash
set -e

TARGET_DIR=$(cd src-tauri && cargo metadata --format-version 1 --no-deps | bun -e 'console.log(JSON.parse(await Bun.stdin.text()).target_directory)')
BUNDLE_DIR="$TARGET_DIR/release/bundle"

# Clean up any existing bundle
rm -rf "$BUNDLE_DIR"

# Build without signing
bun tauri build --no-sign

# Strip extended attributes from all files in the bundle
APP_PATH="$BUNDLE_DIR/macos/Screen Sentinel - Development.app"
xattr -cr "$APP_PATH"

# Sign the app manually
IDENTITY="Apple Development: Louis Beaumont (NJ372MT773)"
codesign --force --deep --sign "$IDENTITY" "$APP_PATH"

echo "Build completed successfully!"
