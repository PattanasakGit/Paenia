# Requirements

## System

- macOS 13 or newer.
- Xcode Command Line Tools or Xcode with `swiftc`.
- No Node.js dependency. No npm packages.

## Files

The app expects:

```text
~/Library/Application Support/<target>/User/settings.json
~/Library/Application Support/Paenia/theme.json
```

The app installs to:

```text
~/Applications/Paenia.app
```

## Functional Requirements

- Edit base palette colors and per-key overrides through native UI.
- Render `workbench.colorCustomizations` and `editor.tokenColorCustomizations` from `ui` + `uiOverrides`.
- Resolve `$varName` and `$varNameAA` references against the palette.
- Filter writes per target — only Cursor receives `glass.theme.*` and `workbench.colorTheme`.
- Brace-balance check before any settings.json write — refuse to write structurally broken files.
- Snapshot settings.json before each successful write; discard the snapshot if the write fails.
- Cap retained backups at 15 per source file (auto-prune oldest).
- Validate user-provided custom paths in 3 tiers (block / warn / ok).
- Save current palette as a named user preset; restore at any time.
- Confirm before Apply (modal) and show success / partial / failure result modal.
- Restore from any backup with confirmation modal.
- Preserve existing user state across reinstalls.

## Non-Functional Requirements

- Native macOS app, SwiftUI, no external runtime.
- App chrome adopts the loaded preset colors but flips light/dark color scheme automatically so contrast stays correct.
- Sidebar must scroll when the window is small.
- Sidebar menu widths must be consistent.
- Every interactive control has a Thai `.help(...)` tooltip.
- Toolbar buttons must show icon + short Thai label.
- App icon must be included in bundle resources.
- Atomic writes for `theme.json` and target `settings.json`.
- `theme.json` key order must be preserved on read and re-write.
