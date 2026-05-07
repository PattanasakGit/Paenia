# AI Development Instructions

This project is for continuing development of the Cursor Theme Customizer app.

## Safety

- Do not modify Cursor SQLite databases.
- If database inspection is ever needed, use read-only `SELECT` only.
- Do not run database functions/procedures without asking first.
- Do not delete user backups.
- Do not use destructive git commands unless the user explicitly asks.
- Preserve existing user settings and create backups before writing to Cursor user files.

## Editing Rules

- Prefer small, focused changes.
- Keep source code ASCII unless the existing text intentionally uses Thai labels.
- Use `apply_patch` for manual edits.
- Keep docs updated when changing build/install behavior.
- Do not hand-edit generated `settings.json` if the generator can do it.

## UX Direction

The user prefers:

- Native macOS, not Tkinter.
- Minimal Glass style.
- Clean, polished, spacious UI.
- Clear grouping in sidebar.
- Readable labels that explain what color is being edited.
- Detailed control over individual theme settings.
- Strong visual hierarchy.
- Sidebar items with consistent width and scrolling behavior.
- App icon applied everywhere: app bundle, Dock, Stage Manager.

## Architecture Rule

Keep the theme generator as the source of truth:

- `colors`: base palette variables.
- `ui`: generated workbench colors.
- `uiOverrides`: direct per-setting overrides written by the app.
- `tokenRules`: editor syntax colors.

The app should not fight the generator. It should edit inputs to the generator.

