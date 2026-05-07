# Requirements

## System

- macOS 13 or newer.
- Xcode Command Line Tools or Xcode with `swiftc`.
- Node.js for running the theme generator.

Node may be installed through:

- `nvm`: `~/.nvm/versions/node/*/bin/node`
- Volta: `~/.volta/bin/node`
- Homebrew Apple Silicon: `/opt/homebrew/bin/node`
- Homebrew Intel: `/usr/local/bin/node`
- System/env fallback: `/usr/bin/env node`

## Cursor Files

The app expects these paths:

```text
~/Library/Application Support/Cursor/User/settings.json
~/Library/Application Support/Workbench Theme Studio/workbench-theme-generator.mjs
```

The app installs to:

```text
~/Applications/Workbench Theme Studio.app
```

## Functional Requirements

- Backup `settings.json` and generator before applying changes.
- Backup names must not collide when apply is clicked multiple times quickly.
- Edit base palette colors.
- Edit detailed workbench color keys.
- Persist direct color edits in `uiOverrides`.
- Generate `workbench.colorCustomizations`.
- Generate `editor.tokenColorCustomizations`.
- Show useful error messages if generator execution fails.
- Detect Node from GUI app context where shell PATH may be missing.

## Non-Functional Requirements

- Native macOS app.
- Minimal Glass visual style.
- Sidebar must scroll when the window is small.
- Sidebar menu widths must be consistent.
- App icon must be included in bundle resources.
- No dependency on npm packages.
