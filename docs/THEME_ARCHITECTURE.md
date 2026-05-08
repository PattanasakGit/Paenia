# Theme Architecture

## Data Flow

```text
SwiftUI App
  edits colors, uiOverrides, presets, target customisation
    -> ThemeDocumentSerializer writes theme.json (atomic)
      -> ThemeApplier renders settings.json for each selected target
        (per-target rules; brace-balance gate; backup-on-success)
          -> Editor UI updates after reload
```

There is no Node.js runtime. The applier is pure Swift.

## theme.json Sections

### `version`

Schema version. Currently `1`.

### `themeSettings`

Top-level scalar keys written into the editor's `settings.json`.

- `workbench.colorTheme` — written **only for Cursor**.
- `glass.theme.detectColorScheme`, `glass.theme.settingsId`, `glass.theme.darkSettingsId`, `glass.theme.customTintHue`, `glass.theme.customTintIntensity` — Cursor only.

For non-Cursor targets these keys are skipped, and any leftover `glass.theme.*` from older versions is removed on the next apply.

### `colors`

Base semantic palette.

Examples: `bg0`..`bg4`, `fg0`..`fg2`, `accent`, `accentSoft`, `border`, `blue`, `green`, `red`, `purple`, `transparent`, `overlayLow`..`overlayActive`.

### `ui`

Maps each workbench color key to a palette reference or literal hex.

- `"$varName"` → `colors[varName]`
- `"$varNameAA"` → first 7 chars of `colors[varName]` + 2-char hex alpha suffix. Example: `"tab.activeBorder": "$accent33"` resolves to `"#FF4FD833"`.
- Any value not starting with `$` is treated as literal hex.

### `uiOverrides`

Direct per-key overrides written by the app. Wins over `ui` at render time.

### `tokenRules`

TextMate scopes for `editor.tokenColorCustomizations`.

```json
{ "scope": ["string"], "foreground": "$green", "fontStyle": "" }
```

### `targetCustomization`

```json
{
  "pathOverrides": { "trae": "/custom/path/User/settings.json" },
  "custom": [
    { "id": "custom-xxxxxxxx", "name": "My Editor", "settingsPath": "..." }
  ]
}
```

### `userPresets`

User-saved palette snapshots.

```json
{
  "id": "user-xxxxxxxx",
  "name": "My Sunset",
  "createdAt": "2026-05-08T15:30:00Z",
  "colors": { "bg0": "#1F1014", ... }
}
```

## Render Pipeline (Swift)

`ThemeApplier` in `src/ThemeCore.swift`:

1. `validate()` — every resolved color must be `#RRGGBB` or `#RRGGBBAA`.
2. `renderWorkbenchPairs()` — flatten `ui` then layer `uiOverrides`, resolving every reference.
3. `renderTokenBlock()` — serialize `tokenRules` with resolved foregrounds.
4. `apply(toSettingsAt:options:)`:
   - Read existing `settings.json`.
   - Filter `themeSettings` by `ApplyOptions` (Cursor full / others none).
   - Strip orphan `glass.theme.*` keys for non-Cursor targets.
   - Replace top-level `workbench.colorCustomizations` and `editor.tokenColorCustomizations` blocks using a brace-balanced parser.
   - Run `SettingsPatcher.hasBalancedBrackets` on the result; refuse to write if unbalanced.
   - Atomic write.

## Settings.json Patcher

`SettingsPatcher.upsertObjectBlock` does NOT use a naive regex. It walks the file character-by-character, tracking string state and brace depth, so it correctly handles nested objects (e.g. `editor.tokenColorCustomizations` contains `textMateRules` which contains `{ "scope":..., "settings": {...} }`).

For each apply:

1. Locate every existing top-level entry for the target key (loop until none left).
2. Remove each entry plus its trailing comma + newline cleanly.
3. Insert the freshly rendered block at the top of the object.
4. Validate brace/bracket balance.

This makes the patcher idempotent and safely cleans up legacy corrupted files.

## Backup Strategy

- `ThemeModel.backupRetentionLimit = 15` per source file.
- Each apply takes a per-file snapshot **before** writing. If the write fails (e.g. brace balance gate trips), the snapshot is **deleted** so the backup list only contains successful states.
- `pruneBackups(forSettingsAt:keep:)` deletes oldest backups beyond the cap, sorted by `contentModificationDate` newest-first.
- A "Prune now" button in Preferences > Backup Management can clean up legacy backups beyond the cap immediately.

## Path Validator

`PathValidator.validate(_ path:)` returns `.ok`, `.warning(reason)`, or `.blocked(reason)`.

- Block: `/System/`, `/usr/`, `/private/var/`, `/Library/`, `/bin/`, `/sbin/`, `*.app/`, `*.bundle/`, `*.framework/`.
- Warn: not `.json`/`.jsonc`, parse fails, file > 1MB, no `workbench.*` keys, file does not exist, path doesn't end with `User/settings.json`.
- OK: everything else.

UI rejects blocked paths and asks the user to confirm warnings.

## Key Order Preservation

JSON dictionaries are unordered, so `theme.json` keeps a meaningful source order through:

- `OrderedStringMap` for `colors`, `ui`, `uiOverrides`.
- `JSONKeyOrder` — raw text scanner that recovers key order after Codable decode.
- `ThemeDocumentSerializer` — emits the file in stored order.
