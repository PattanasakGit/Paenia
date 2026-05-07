# Workbench Theme Studio

Native macOS app for editing VS Code-family editor theme colors in a detailed, AI-maintainable way.

The app can edit:

- `~/Library/Application Support/Code/User/settings.json`
- `~/Library/Application Support/Cursor/User/settings.json`
- `~/Library/Application Support/Antigravity/User/settings.json`
- `~/Library/Application Support/Trae/User/settings.json`
- other VS Code-family `User/settings.json` locations

See `docs/SUPPORTED_APPS.md` for the built-in target list and detected local apps.

Main idea:

- Base palette variables live in `colors`.
- Generated Cursor color keys live in `ui`.
- Per-setting manual edits are stored in `uiOverrides`.
- The app writes overrides, then runs the generator to update `settings.json`.

## Current Installed App

Installed app:

```text
~/Applications/Workbench Theme Studio.app
```

Generator:

```text
~/Library/Application Support/Workbench Theme Studio/workbench-theme-generator.mjs
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
open "$HOME/Applications/Workbench Theme Studio.app"
```

## App Features

- Native SwiftUI macOS app.
- Minimal Glass style.
- Sidebar with scrollable grouped navigation.
- Multi-target app selection for VS Code-family editors.
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
