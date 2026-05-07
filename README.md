# Cursor Theme Customizer

Native macOS app for editing Cursor theme colors in a detailed, AI-maintainable way.

The app edits:

- `~/Library/Application Support/Cursor/User/settings.json`
- `~/Library/Application Support/Cursor/User/cursor-minimal-dark-theme.mjs`

Main idea:

- Base palette variables live in `colors`.
- Generated Cursor color keys live in `ui`.
- Per-setting manual edits are stored in `uiOverrides`.
- The app writes overrides, then runs the generator to update `settings.json`.

## Current Installed App

Installed app:

```text
~/Library/Application Support/Cursor/User/Cursor Theme Customizer.app
```

Launcher:

```text
~/Library/Application Support/Cursor/User/Open Native Cursor Theme Customizer.command
```

## Build

```sh
./scripts/build.sh
```

## Install

```sh
./scripts/install.sh
```

## Open

```sh
open "$HOME/Library/Application Support/Cursor/User/Cursor Theme Customizer.app"
```

## App Features

- Native SwiftUI macOS app.
- Minimal Glass style.
- Sidebar with scrollable grouped navigation.
- Base Palette mode for editing shared variables.
- Detailed Colors mode for editing individual `workbench.colorCustomizations` keys.
- Clear labels, real setting keys, swatches, hex inputs, and color pickers.
- Backup before apply.
- Unique backup file names to avoid copy collisions.
- Node detection for `nvm`, Volta, Homebrew, and system paths.
- App icon bundled as `AppIcon.icns` for Dock and Stage Manager.

## Important Rule

Do not write directly to Cursor's SQLite state DB. Cursor/Glass stores runtime theme state in:

```text
~/Library/Application Support/Cursor/User/globalStorage/state.vscdb
```

Database access should be read-only unless explicitly approved.

