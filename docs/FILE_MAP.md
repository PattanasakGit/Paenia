# File Map

## Project Files

```text
src/CursorThemeCustomizer.swift
```

Main SwiftUI native macOS app. Contains UI, model, parsing, backup, apply, and Node detection.

```text
src/workbench-theme-generator.mjs
```

Theme generator. Writes generated color blocks into the selected editor `settings.json`.

```text
src/Info.plist
```

macOS app bundle metadata. Includes `CFBundleIconFile = AppIcon`.

```text
scripts/build.sh
```

Builds app bundle into `build/Workbench Theme Studio.app`.

```text
scripts/install.sh
```

Installs the app into `~/Applications` and the generator into Workbench Theme Studio app support.

```text
scripts/make_icon.py
scripts/png_to_icns.py
```

Icon generation helpers.

```text
assets/AppIcon.icns
assets/AppIcon.png
assets/icon-source.png
```

Current app icon assets.

```text
docs/SUPPORTED_APPS.md
```

Built-in app targets and known macOS settings paths.

## Runtime Files

```text
~/Library/Application Support/<target>/User/settings.json
```

Target editor user settings. The generator replaces these blocks:

- `workbench.colorCustomizations`
- `editor.tokenColorCustomizations`

```text
~/Library/Application Support/Workbench Theme Studio/workbench-theme-generator.mjs
```

Installed generator used by the app.

```text
~/Applications/Workbench Theme Studio.app
```

Installed native app.
