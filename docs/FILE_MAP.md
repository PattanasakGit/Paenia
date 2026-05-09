# File Map

## Source

```text
src/CursorThemeCustomizer.swift
```

ThemeModel (state container), `EditorTarget` + detection, `ThemePreset` catalogue (78 presets), `PathValidator`, app entry point. Inherited filename from project's earlier identity; kept stable to avoid disturbing build/install scripts.

```text
src/ThemeCore.swift
```

Pure-Swift theme engine — `ThemeDocument` Codable model with backward-compat decoder, `OrderedStringMap`, `ColorResolver`, `ThemeApplier` (with brace-balance gate and per-target `ApplyOptions`), `SettingsPatcher`, `JSONKeyOrder`, `ThemeDocumentSerializer`, `TargetCustomization`, `UserPresetSpec`.

```text
src/Views.swift
```

All SwiftUI views — `ContentView`, toolbar, sidebar, mode picker, preset picker + popover, color rows, IDE preview, palette grid, inspector, status bar, preferences sheet, custom-target editor, validator banner, save-preset sheet, backup management, restore/delete confirm sheets, apply confirmation + result sheets.

```text
src/theme.json
```

Default theme document shipped in the app bundle and seeded into Application Support on first install.

```text
src/Info.plist
```

macOS app bundle metadata. Includes `CFBundleIconFile = AppIcon`.

## Scripts

```text
scripts/build.sh
```

Compiles `src/CursorThemeCustomizer.swift`, `src/ThemeCore.swift`, `src/Views.swift` together with `swiftc -O -parse-as-library`. Copies `Info.plist`, `theme.json`, and the icon into the app bundle.

```text
scripts/install.sh
```

Builds + ditto's the app to `~/Applications/`. Seeds `theme.json` only if missing.

```text
scripts/make_icon.py
scripts/png_to_icns.py
```

Icon generation helpers.

## Assets

```text
assets/AppIcon.icns
assets/AppIcon.png
assets/icon-source.png
```

## Runtime Files

```text
~/Applications/Paenia.app
~/Library/Application Support/Paenia/theme.json
~/Library/Application Support/<target>/User/settings.json
~/Library/Application Support/<target>/User/settings.json.backup-<timestamp>[-N]
```

The app reads/writes `theme.json` and renders the workbench/token blocks into each target's `settings.json`. Up to 15 timestamped backups are retained per source file (auto-pruned).
