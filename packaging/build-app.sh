#!/usr/bin/env bash
#
# Builds the app in release mode and assembles a distributable .app bundle.
# Usage: ./packaging/build-app.sh [output-dir]   (default output: ./dist)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=app.env
source "$ROOT/packaging/app.env"

OUT_DIR="${1:-$ROOT/dist}"
BUNDLE="$OUT_DIR/$APP_BUNDLE_NAME.app"
RESOURCES_DIR="$ROOT/Sources/$APP_EXECUTABLE/Resources"

echo "==> Building release binary"
swift build -c release --package-path "$ROOT"
BIN_PATH="$(swift build -c release --package-path "$ROOT" --show-bin-path)/$APP_EXECUTABLE"

echo "==> Assembling $BUNDLE"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"
mkdir -p "$BUNDLE/Contents/Resources"

cp "$BIN_PATH" "$BUNDLE/Contents/MacOS/$APP_EXECUTABLE"
cp "$ROOT/packaging/Info.plist" "$BUNDLE/Contents/Info.plist"
cp "$ROOT/packaging/App.entitlements" "$BUNDLE/Contents/entitlements.plist"

if [[ ! -f "$RESOURCES_DIR/Logo.png" ]]; then
  echo "==> Generating AppIcon.png (no Logo.png in Resources)"
  ICON_GEN="$(mktemp -t macshot-icon-gen.XXXXXX)"
  swiftc "$ROOT/packaging/generate-icon.swift" -o "$ICON_GEN" -framework AppKit -framework Foundation
  "$ICON_GEN" "$ROOT/packaging/AppIcon.png"
  rm -f "$ICON_GEN"
  SRC_ICON="$ROOT/packaging/AppIcon.png"
else
  SRC_ICON="$RESOURCES_DIR/Logo.png"
  cp "$SRC_ICON" "$ROOT/packaging/AppIcon.png"
fi

echo "==> Generating AppIcon.icns"
ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size"        "$SRC_ICON" --out "$ICONSET/icon_${size}x${size}.png"   >/dev/null
    sips -z $((size*2)) $((size*2)) "$SRC_ICON" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$BUNDLE/Contents/Resources/AppIcon.icns"

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$BUNDLE" || echo "warning: codesign failed (app will still run locally)"

echo "==> Done: $BUNDLE"
