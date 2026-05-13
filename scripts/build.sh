#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/Paenia.app"
MACOS_DEPLOYMENT_TARGET="13.0"
SWIFT_TARGET="${SWIFT_TARGET:-$(uname -m)-apple-macos$MACOS_DEPLOYMENT_TARGET}"

# Clean any pre-rebrand build artifact so we don't ship two bundles.
rm -rf "$ROOT/build/Workbench Theme Studio.app" 2>/dev/null || true

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -parse-as-library \
  -target "$SWIFT_TARGET" \
  "$ROOT/src/UpdateCheck.swift" \
  "$ROOT/src/CursorThemeCustomizer.swift" \
  "$ROOT/src/ThemeCore.swift" \
  "$ROOT/src/Views.swift" \
  -o "$APP/Contents/MacOS/Paenia"

cp "$ROOT/src/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/src/theme.json" "$APP/Contents/Resources/theme.json"
cp "$ROOT/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$ROOT/assets/AppIcon.png" "$APP/Contents/Resources/AppIcon.png"

echo "Built: $APP"
