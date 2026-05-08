#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$HOME/Applications"
APP_NAME="Workbench Theme Studio.app"
STUDIO_DIR="$HOME/Library/Application Support/Workbench Theme Studio"

"$ROOT/scripts/build.sh"

mkdir -p "$APP_DIR"
ditto "$ROOT/build/$APP_NAME" "$APP_DIR/$APP_NAME"

mkdir -p "$STUDIO_DIR"
if [ ! -f "$STUDIO_DIR/theme.json" ]; then
  cp "$ROOT/src/theme.json" "$STUDIO_DIR/theme.json"
  echo "Seeded theme.json: $STUDIO_DIR/theme.json"
else
  echo "Existing theme.json preserved: $STUDIO_DIR/theme.json"
fi

echo "Installed app: $APP_DIR/$APP_NAME"
