#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$HOME/Applications"
APP_NAME="Paenia.app"
STUDIO_DIR="$HOME/Library/Application Support/Paenia"
LEGACY_STUDIO_DIR="$HOME/Library/Application Support/Workbench Theme Studio"
LEGACY_APP="$APP_DIR/Workbench Theme Studio.app"

"$ROOT/scripts/build.sh"

# Remove pre-rebrand installed bundle so users don't end up with two copies.
[ -d "$LEGACY_APP" ] && rm -rf "$LEGACY_APP"

mkdir -p "$APP_DIR"
ditto "$ROOT/build/$APP_NAME" "$APP_DIR/$APP_NAME"

# Migrate the user's data folder if upgrading from the old branding.
if [ -d "$LEGACY_STUDIO_DIR" ] && [ ! -d "$STUDIO_DIR" ]; then
  mv "$LEGACY_STUDIO_DIR" "$STUDIO_DIR"
  echo "Migrated user data: $LEGACY_STUDIO_DIR -> $STUDIO_DIR"
fi

mkdir -p "$STUDIO_DIR"
if [ ! -f "$STUDIO_DIR/theme.json" ]; then
  cp "$ROOT/src/theme.json" "$STUDIO_DIR/theme.json"
  echo "Seeded theme.json: $STUDIO_DIR/theme.json"
else
  echo "Existing theme.json preserved: $STUDIO_DIR/theme.json"
fi

echo "Installed app: $APP_DIR/$APP_NAME"
