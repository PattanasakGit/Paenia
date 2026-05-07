#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$HOME/Applications"
APP_NAME="Workbench Theme Studio.app"

"$ROOT/scripts/build.sh"

mkdir -p "$APP_DIR"
ditto "$ROOT/build/$APP_NAME" "$APP_DIR/$APP_NAME"
mkdir -p "$HOME/Library/Application Support/Workbench Theme Studio"
cp "$ROOT/src/workbench-theme-generator.mjs" "$HOME/Library/Application Support/Workbench Theme Studio/workbench-theme-generator.mjs"

echo "Installed app: $APP_DIR/$APP_NAME"
echo "Installed generator: $HOME/Library/Application Support/Workbench Theme Studio/workbench-theme-generator.mjs"
