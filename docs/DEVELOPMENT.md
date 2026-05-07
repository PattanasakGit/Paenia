# Development Guide

## Build App

```sh
./scripts/build.sh
```

Output:

```text
build/Cursor Theme Customizer.app
```

## Install App And Generator

```sh
./scripts/install.sh
```

This copies:

```text
build/Cursor Theme Customizer.app
  -> ~/Library/Application Support/Cursor/User/Cursor Theme Customizer.app

src/cursor-minimal-dark-theme.mjs
  -> ~/Library/Application Support/Cursor/User/cursor-minimal-dark-theme.mjs
```

## Run Generator Manually

```sh
node "$HOME/Library/Application Support/Cursor/User/cursor-minimal-dark-theme.mjs"
```

## Verify App Bundle

```sh
plutil -p "$HOME/Library/Application Support/Cursor/User/Cursor Theme Customizer.app/Contents/Info.plist"
file "$HOME/Library/Application Support/Cursor/User/Cursor Theme Customizer.app/Contents/Resources/AppIcon.icns"
```

Expected:

- `CFBundleIconFile => AppIcon`
- `AppIcon.icns` reports `Mac OS X icon`

## Key Implementation Areas

### Base Palette

Defined in `colors` inside generator and mirrored by the Swift app.

### Detailed Colors

The app reads the generated `workbench.colorCustomizations` block from `settings.json`, groups keys by prefix, and lets users override individual values.

Overrides are written into:

```js
const uiOverrides = {
  "terminal.background": "#141D2D",
};
```

The generator applies them here:

```js
Object.entries({ ...ui, ...uiOverrides })
```

### Backup

Backups are created before apply. Existing backup names are not overwritten.

### Node Detection

The app cannot assume shell PATH. Keep explicit Node detection for GUI launch contexts.

