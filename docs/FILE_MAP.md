# File Map

## Project Files

```text
src/CursorThemeCustomizer.swift
```

Main SwiftUI native macOS app. Contains UI, model, parsing, backup, apply, and Node detection.

```text
src/cursor-minimal-dark-theme.mjs
```

Theme generator. Writes generated color blocks into Cursor `settings.json`.

```text
src/Info.plist
```

macOS app bundle metadata. Includes `CFBundleIconFile = AppIcon`.

```text
scripts/build.sh
```

Builds app bundle into `build/Cursor Theme Customizer.app`.

```text
scripts/install.sh
```

Installs app and generator into Cursor User folder.

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

## Cursor Runtime Files

```text
~/Library/Application Support/Cursor/User/settings.json
```

Cursor user settings. The generator replaces these blocks:

- `workbench.colorCustomizations`
- `editor.tokenColorCustomizations`

```text
~/Library/Application Support/Cursor/User/cursor-minimal-dark-theme.mjs
```

Installed generator used by the app.

```text
~/Library/Application Support/Cursor/User/Cursor Theme Customizer.app
```

Installed native app.

