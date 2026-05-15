#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

grep -q 'requestOriginalRestoreFromPreferences' "$ROOT/src/CursorThemeCustomizer.swift"
grep -q 'model.requestOriginalRestoreFromPreferences(info)' "$ROOT/src/Views.swift"
grep -q 'MACOS_DEPLOYMENT_TARGET="13.0"' "$ROOT/scripts/build.sh"
grep -q 'apple-macos$MACOS_DEPLOYMENT_TARGET' "$ROOT/scripts/build.sh"
grep -q -- '-target "$SWIFT_TARGET"' "$ROOT/scripts/build.sh"
grep -q 'ComprehensiveIDEPreview(model: model)' "$ROOT/src/Views.swift"
grep -q 'SectionDynamicPreview(model: model)' "$ROOT/src/Views.swift"
grep -q 'struct SectionDynamicPreview' "$ROOT/src/Views.swift"
grep -q 'let contrastBorder = c("contrastBorder"' "$ROOT/src/Views.swift"
grep -q 'terminalPanel(' "$ROOT/src/Views.swift"
grep -q 'let terminalBg = c("terminal.background"' "$ROOT/src/Views.swift"
grep -q 'Color(nsColor: contrastBorder).opacity(0.06)' "$ROOT/src/Views.swift"
grep -q 'LinearGradient(' "$ROOT/src/Views.swift"
grep -q 'Color(nsColor: synAccent).opacity(0.09)' "$ROOT/src/Views.swift"
grep -q 'section("SECTION PREVIEW · \\(currentCategory.title)")' "$ROOT/src/Views.swift"
grep -q 'section("PALETTE")' "$ROOT/src/Views.swift"
grep -q 'widget.border".*opacity(0.18)' "$ROOT/src/Views.swift"
grep -q 'editorWidget.border".*opacity(0.20)' "$ROOT/src/Views.swift"
