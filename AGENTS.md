# AI Development Instructions

This project is the Paenia app. Continue development from here.

## Safety

- Do not modify Cursor SQLite databases.
- If database inspection is ever needed, use read-only `SELECT` only.
- Do not run database functions/procedures without asking first.
- Do not delete user backups unless the user explicitly asks.
- Do not use destructive git commands unless the user explicitly asks.
- Always go through `ThemeApplier` to write `settings.json` — it has a brace-balance gate that prevents writing broken files.
- Backups are snapshot **before** each successful write; failed writes discard their just-created snapshot. Do not break this contract.

## Editing Rules

- Prefer small, focused changes.
- Keep source code ASCII unless the existing text intentionally uses Thai labels.
- Keep docs updated when changing build/install behavior.
- Do not hand-edit `settings.json` if the Swift applier can do it.

## UX Direction

The user prefers:

- Native macOS — SwiftUI only, no Tkinter or Electron.
- Minimal, pastel chrome that follows the loaded theme.
- Sidebar with categories + grouped presets, mode toggle pinned to the bottom.
- Toolbar buttons must show **icon + Thai label** (not icon-only) so users know what each does at a glance.
- Every interactive control has a Thai `.help(...)` tooltip.
- Apply is destructive-ish — always go through a confirmation modal then a result modal (success / partial / failure).
- App icon applied everywhere: app bundle, Dock, Stage Manager.

## Architecture Rule

`theme.json` is the single source of truth.

- `colors`: base palette variables.
- `ui`: workbench-key references in the form `"$varName"` or `"$varNameAA"` (alpha suffix), or literal hex.
- `uiOverrides`: direct overrides written by the app; wins over `ui` at render time.
- `tokenRules`: editor syntax colors (TextMate scopes).
- `themeSettings`: top-level scalar keys (`workbench.colorTheme`, `glass.theme.*`).
- `targetCustomization`: built-in path overrides and user-added custom targets.
- `userPresets`: user-saved palette snapshots.

The Swift `ThemeApplier` (in `src/ThemeCore.swift`) renders `theme.json` to each target's `settings.json`. No external runtime is used.

### Per-target apply rules

- Cursor (`id == "cursor"`): writes `workbench.colorTheme`, all `glass.theme.*`, `workbench.colorCustomizations`, `editor.tokenColorCustomizations`.
- Everyone else: writes only `workbench.colorCustomizations` and `editor.tokenColorCustomizations`. Any `glass.theme.*` keys are removed if present, so user's chosen `workbench.colorTheme` is preserved.
