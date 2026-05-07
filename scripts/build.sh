#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/Cursor Theme Customizer.app"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -parse-as-library \
  "$ROOT/src/CursorThemeCustomizer.swift" \
  -o "$APP/Contents/MacOS/Cursor Theme Customizer"

cp "$ROOT/src/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$ROOT/assets/AppIcon.png" "$APP/Contents/Resources/AppIcon.png"

echo "Built: $APP"

