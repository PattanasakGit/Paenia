#!/bin/zsh
set -euo pipefail

# Builds Paenia.app then packages a compressed DMG with a styled Finder window:
# pastel background, drag-hint copy, and icon positions for Paenia.app + Applications.
# Does not code-sign or notarize — users may need to right-click → Open on first launch.
#
# Finder must finish writing .DS_Store before detach; hiding .background with chflags
# breaks the saved background on reopen, so we only use Finder's "invisible" bit.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Paenia.app"
BUILD_APP="$ROOT/build/$APP_NAME"

"$ROOT/scripts/build.sh"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$ROOT/src/Info.plist")"
DMG_NAME="Paenia-${VERSION}-macos.dmg"
OUT="$ROOT/build/$DMG_NAME"
VOLNAME="Paenia ${VERSION}"
RW_DMG="$ROOT/build/.paenia-rw-temp-$$.dmg"

STAGE="$(mktemp -d "${TMPDIR:-/tmp}/paenia-dmg.XXXXXX")"
cleanup() {
  rm -rf "$STAGE"
  rm -f "$RW_DMG"
}
trap cleanup EXIT

ditto "$BUILD_APP" "$STAGE/$APP_NAME"
ln -sf /Applications "$STAGE/Applications"
mkdir -p "$STAGE/.background"

BG_RENDER="$STAGE/.render_bg_bin"
swiftc -O "$ROOT/scripts/render_dmg_background.swift" -o "$BG_RENDER"
"$BG_RENDER" "$STAGE/.background/background.png"
rm -f "$BG_RENDER"

rm -f "$OUT" "$RW_DMG"
hdiutil create \
  -volname "$VOLNAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDRW \
  "$RW_DMG"

# Mount RW image (no -nobrowse so Finder fully tracks the volume).
ATTACH_LINE="$(hdiutil attach -readwrite "$RW_DMG" 2>&1 | grep '/Volumes/' | tail -1 || true)"
MOUNT="$(printf '%s' "$ATTACH_LINE" | sed -E 's/.*[[:space:]](\/Volumes\/.+)$/\1/' | tr -d '\r')"
if [[ -z "$MOUNT" || ! -d "$MOUNT" ]]; then
  echo "make_dmg: failed to mount RW image at $RW_DMG" >&2
  exit 1
fi

BG_ON_VOL="$MOUNT/.background/background.png"

/usr/bin/osascript - "$VOLNAME" "$BG_ON_VOL" <<'APPLESCRIPT'
on run argv
  set volName to item 1 of argv as text
  set bgPosix to item 2 of argv as text
  set bgFile to POSIX file bgPosix
  -- Window geometry (global screen coords, Finder)
  set theXOrigin to 220
  set theYOrigin to 140
  set theWidth to 640
  set theHeight to 360
  set theBottomRightX to theXOrigin + theWidth
  set theBottomRightY to theYOrigin + theHeight

  tell application "Finder"
    tell disk (volName as string)
      open
      tell container window
        set current view to icon view
        set toolbar visible to false
        set statusbar visible to false
        set the bounds to {theXOrigin, theYOrigin, theBottomRightX, theBottomRightY}
      end tell
      set opts to the icon view options of container window
      tell opts
        set arrangement to not arranged
        set icon size to 88
      end tell
      set background picture of opts to bgFile
      tell container window
        set position of item "Paenia.app" to {160, 218}
        set position of item "Applications" to {480, 218}
      end tell
      -- Finder usually commits .DS_Store only after a close/open cycle.
      close
      open
      delay 2
      tell container window
        set toolbar visible to false
        set statusbar visible to false
        set the bounds to {theXOrigin, theYOrigin, theBottomRightX, theBottomRightY}
      end tell
      delay 2
      try
        set visible of folder ".background" of disk (volName as string) to false
      end try
      delay 2
    end tell
  end tell
end run
APPLESCRIPT

open -g "$MOUNT" || true
sleep 2
/usr/bin/osascript - "$VOLNAME" <<'APPLESCRIPT' || true
on run argv
  set volName to item 1 of argv as text
  tell application "Finder"
    tell disk (volName as string)
      update with registering applications
    end tell
  end tell
end run
APPLESCRIPT

# Wait until Finder has written .DS_Store (closing the window too early drops layout on reopen).
for _ in {1..80}; do
  if [[ -f "$MOUNT/.DS_Store" ]]; then
    break
  fi
  sleep 0.5
done
if [[ ! -f "$MOUNT/.DS_Store" ]]; then
  echo "make_dmg: warning: .DS_Store missing — layout may not stick (is Finder allowed to run?)" >&2
fi

/usr/bin/osascript - "$VOLNAME" <<'APPLESCRIPT' || true
on run argv
  set volName to item 1 of argv as text
  tell application "Finder"
    try
      close container window of disk (volName as string)
    end try
  end tell
end run
APPLESCRIPT

sync
hdiutil detach "$MOUNT" || hdiutil detach "$MOUNT" -force

hdiutil convert "$RW_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -ov \
  -o "$OUT"

echo "DMG: $OUT"
echo "SHA-256: $(shasum -a 256 "$OUT" | awk '{print $1}')"
