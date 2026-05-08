# Workbench Theme Studio

Native macOS app for editing VS Code-family editor theme colors with a live preview, organized presets, and a safe apply pipeline.

The app can edit:

- `~/Library/Application Support/Code/User/settings.json`
- `~/Library/Application Support/Cursor/User/settings.json`
- `~/Library/Application Support/Antigravity/User/settings.json`
- `~/Library/Application Support/Trae/User/settings.json`
- other VS Code-family `User/settings.json` locations
- any custom path the user adds (with validation)

## Architecture

- **`theme.json`** is the single source of truth — palette, ui template, overrides, token rules, target customisation, user presets.
- **Pure Swift engine** (`ThemeCore.swift`) renders the document into each editor's `settings.json`. No Node.js / external runtime required.
- **App chrome follows the loaded theme** — switching to a light preset flips the whole UI to a light color scheme.

```text
SwiftUI App ──edit──▶ theme.json ──ThemeApplier──▶ each target's settings.json
```

## Highlights

- **78 themed presets** grouped Dark / Light, with mini editor preview per card
- **Save your own preset** from the current palette and reload it anytime
- **Live IDE preview** in the inspector — uses real workbench colors from disk
- **Per-target apply rules** — Cursor gets the full theme + Glass tint; other editors only get color customizations so their existing theme stays intact
- **Brace-balanced settings.json patcher** — refuses to write a structurally broken file
- **Backup-on-success** — every apply snapshots the file first; failed writes discard their snapshot, last 15 backups are retained per editor automatically
- **Custom targets + path overrides** — pick any settings.json with 3-tier path validation
- **Apply confirmation + result modal** — confirm targets before writing, success/partial/failure feedback after
- **Thai tooltips and toolbar labels** — every button has a short label and a Thai description on hover

## Installed Locations

```text
~/Applications/Workbench Theme Studio.app
~/Library/Application Support/Workbench Theme Studio/theme.json
```

## Build & Install

```sh
./scripts/build.sh      # build into build/Workbench Theme Studio.app
./scripts/install.sh    # build + copy into ~/Applications and seed theme.json
```

The installer only seeds `theme.json` if it does not already exist; existing user state is preserved across reinstalls.

## Open

```sh
open "$HOME/Applications/Workbench Theme Studio.app"
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘S` | Apply (opens confirmation sheet) |
| `⌘B` | Backup current targets |
| `⌘R` | Reload theme.json + target settings.json |
| `⌘,` | Preferences |
| `⌥⌘I` | Toggle inspector pane |

## Important Rule

Do not write directly to Cursor's SQLite state DB. Cursor stores runtime theme state in:

```text
~/Library/Application Support/Cursor/User/globalStorage/state.vscdb
```

Database access should be read-only unless explicitly approved.
