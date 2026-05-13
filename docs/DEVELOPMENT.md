# Development Guide

## Build

```sh
./scripts/build.sh
```

Compiles four Swift sources together (`UpdateCheck.swift`, `CursorThemeCustomizer.swift`, `ThemeCore.swift`, `Views.swift`) and bundles `theme.json`, `Info.plist`, and the icon. Output:

```text
build/Paenia.app
```

`scripts/build.sh` pins the Swift deployment target to macOS 13.0 (`-target <arch>-apple-macos13.0`) so the Mach-O minimum OS matches `LSMinimumSystemVersion` in `Info.plist` instead of inheriting the latest SDK default.

Current beta bundle version: `0.0.96-beta`.

### Disk image (`scripts/make_dmg.sh`)

Builds the app, renders `640×360` `background.png` (Swift + AppKit), stages `Paenia.app`, `Applications` alias, and `.background/`. Creates a **UDRW** image, **mounts** it, runs **AppleScript** (Finder) to apply the background picture (via POSIX path), icon positions, and window bounds, then **converts** to **UDZO** `build/Paenia-<version>-macos.dmg`.

## Install

```sh
./scripts/install.sh
```

Builds, ditto's the app to `~/Applications/`. Seeds `theme.json` into `~/Library/Application Support/Paenia/` only if missing, so existing user state is preserved across reinstalls.

## Run

```sh
open "$HOME/Applications/Paenia.app"
```

The Swift binary is the only runtime — there is no Node.js step, no daemon, no helper.

## Update checks (GitHub)

`UpdateCheck.swift` calls `GET https://api.github.com/repos/PattanasakGit/Paenia/releases/latest` with a `User-Agent` of `Paenia/<version> (macOS)`.

- **After launch:** `ThemeModel.scheduleSilentUpdateCheck()` waits ~1.6s, then fetches; if the release tag is newer than `CFBundleShortVersionString` and the user has not silenced that tag (`UserDefaults` key `PaeniaUpdateSkippedReleaseTag`), `ContentView` shows a Thai `confirmationDialog` with download / dismiss / “don’t remind for this tag”.
- **Settings → About → อัปเดต → ตรวจสอบอัปเดต:** `UpdateCheck.manualCheck()` runs the same fetch but **ignores** the skip preference so a newer release is always offered; if already up to date or the request fails, an `alert` explains.

The app does not install updates — it only opens the `.dmg` or release page URL.

## Verify Bundle

```sh
plutil -p "$HOME/Applications/Paenia.app/Contents/Info.plist"
file "$HOME/Applications/Paenia.app/Contents/Resources/AppIcon.icns"
ls   "$HOME/Applications/Paenia.app/Contents/Resources/theme.json"
```

Expected:

- `CFBundleIconFile => AppIcon`
- `AppIcon.icns` reports `Mac OS X icon`
- `theme.json` exists in Resources

## Key Implementation Areas

### Source of Truth

`~/Library/Application Support/Paenia/theme.json` holds the complete theme — palette, ui template, overrides, token rules, target overrides, custom targets, user presets. The app updates it atomically before applying to any editor.

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
- Settings → Backups → Restore Original → Settings closes first, then the destructive confirmation sheet appears.
- Switch from a dark to a light preset → entire app UI flips light, text stays readable.
- Settings → About → ตรวจสอบอัปเดต → expect up-to-date alert, update dialog when a newer GitHub release exists, or failure alert when offline / API error.
