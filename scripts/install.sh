#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
USER_DIR="$HOME/Library/Application Support/Cursor/User"
APP_NAME="Cursor Theme Customizer.app"

"$ROOT/scripts/build.sh"

ditto "$ROOT/build/$APP_NAME" "$USER_DIR/$APP_NAME"
cp "$ROOT/src/cursor-minimal-dark-theme.mjs" "$USER_DIR/cursor-minimal-dark-theme.mjs"

echo "Installed app: $USER_DIR/$APP_NAME"
echo "Installed generator: $USER_DIR/cursor-minimal-dark-theme.mjs"

