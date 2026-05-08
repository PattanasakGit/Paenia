# Development Guide

## Build

```sh
./scripts/build.sh
```

Compiles all three Swift sources together (`CursorThemeCustomizer.swift`, `ThemeCore.swift`, `Views.swift`) and bundles `theme.json`, `Info.plist`, and the icon. Output:

```text
build/Workbench Theme Studio.app
```

## Install

```sh
./scripts/install.sh
```

Builds, ditto's the app to `~/Applications/`. Seeds `theme.json` into `~/Library/Application Support/Workbench Theme Studio/` only if missing, so existing user state is preserved across reinstalls.

## Run

```sh
open "$HOME/Applications/Workbench Theme Studio.app"
```

The Swift binary is the only runtime — there is no Node.js step, no daemon, no helper.

## Verify Bundle

```sh
plutil -p "$HOME/Applications/Workbench Theme Studio.app/Contents/Info.plist"
file "$HOME/Applications/Workbench Theme Studio.app/Contents/Resources/AppIcon.icns"
ls   "$HOME/Applications/Workbench Theme Studio.app/Contents/Resources/theme.json"
```

Expected:

- `CFBundleIconFile => AppIcon`
- `AppIcon.icns` reports `Mac OS X icon`
- `theme.json` exists in Resources

## Key Implementation Areas

### Source of Truth

`~/Library/Application Support/Workbench Theme Studio/theme.json` holds the complete theme — palette, ui template, overrides, token rules, target overrides, custom targets, user presets. The app updates it atomically before applying to any editor.

### Apply Pipeline

1. UI calls `model.requestApply()` → opens `ConfirmApplySheet`.
2. User confirms → `model.confirmAndApply()` runs.
3. `ThemeModel.apply()` rebuilds `theme.json`, validates colors, writes the document, then for each selected target:
   - takes a backup snapshot,
   - calls `ThemeApplier.apply(toSettingsAt:options:)` with target-specific `ApplyOptions`,
   - on success keeps the snapshot and prunes old ones, on failure deletes the snapshot.
4. Result is collected into `ApplyOutcome.success(...)` or `.failure(message:partial:)` and shown in `ApplyResultSheet`.

### Brace-Balanced Patcher

`SettingsPatcher.upsertObjectBlock` walks the file with a string-aware brace counter so it correctly handles nested objects inside the value (e.g. the `textMateRules` array). Removes every existing instance of the key (loop) before inserting the fresh block — defensively cleans up legacy duplicates from older versions.

`SettingsPatcher.hasBalancedBrackets` runs after every render. If braces or brackets aren't balanced (ignoring strings + JSONC comments), the apply throws and nothing is written.

### Per-Target Filtering

Cursor receives full output (`ApplyOptions.cursor`). All other targets receive only color customizations (`ApplyOptions.standard`); `glass.theme.*` keys are removed if present so the user's chosen `workbench.colorTheme` stays untouched.

### Backups

`makeBackup(of:)` produces a single-file snapshot. `apply()` creates one before each target write and discards it on failure. `pruneBackups(forSettingsAt:keep:)` runs after success, sorted newest-first, deleting beyond the 15-file cap.

The toolbar **สำรอง (Backup)** button is an explicit user-requested snapshot — it always keeps the snapshot.

### Theme-Adaptive Chrome

`AppBackground` reads `model.appBg0/Bg1` so the app's gradient follows the loaded preset. `ContentView` applies `.preferredColorScheme(model.appColorScheme)` and `.tint(model.appAccent)` so light themes get a light UI with proper contrast and dark themes stay dark. `ThemeChrome` is injected via Environment so child views consume `theme.accent`, `theme.success`, etc. without each needing model access.

### Backward-Compatible Decoding

`ThemeDocument.init(from:)` and `TargetCustomization.init(from:)` use `decodeIfPresent` with defaults so older `theme.json` files (without `targetCustomization` or `userPresets`) continue to load.

## Manual Testing Checklist

- Apply once over a clean target → `settings.json` produced, balanced JSON, 1 backup created.
- Apply again → still 1 of each block, brackets balanced, second backup created.
- Force a corruption → next apply throws + no write.
- Add a custom target with a system path → blocked with reason.
- Save palette as preset → appears in MY PRESETS section of popover.
- Restore a backup → confirm sheet, then file replaced and target reloaded.
- Switch from a dark to a light preset → entire app UI flips light, text stays readable.
