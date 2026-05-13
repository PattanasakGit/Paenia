#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

grep -q 'requestOriginalRestoreFromPreferences' "$ROOT/src/CursorThemeCustomizer.swift"
grep -q 'model.requestOriginalRestoreFromPreferences(info)' "$ROOT/src/Views.swift"
grep -q 'MACOS_DEPLOYMENT_TARGET="13.0"' "$ROOT/scripts/build.sh"
grep -q 'apple-macos$MACOS_DEPLOYMENT_TARGET' "$ROOT/scripts/build.sh"
grep -q -- '-target "$SWIFT_TARGET"' "$ROOT/scripts/build.sh"
