#!/bin/zsh
set -euo pipefail

# Builds Paenia.app then packages a read-only compressed DMG with a drag-to-Applications layout.
# Does not code-sign or notarize — users may need to right-click → Open on first launch.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Paenia.app"
BUILD_APP="$ROOT/build/$APP_NAME"

"$ROOT/scripts/build.sh"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$ROOT/src/Info.plist")"
DMG_NAME="Paenia-${VERSION}-macos.dmg"
OUT="$ROOT/build/$DMG_NAME"

STAGE="$(mktemp -d "${TMPDIR:-/tmp}/paenia-dmg.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT

ditto "$BUILD_APP" "$STAGE/$APP_NAME"
ln -sf /Applications "$STAGE/Applications"

rm -f "$OUT"
hdiutil create \
  -volname "Paenia ${VERSION}" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$OUT"

echo "DMG: $OUT"
echo "SHA-256: $(shasum -a 256 "$OUT" | awk '{print $1}')"
