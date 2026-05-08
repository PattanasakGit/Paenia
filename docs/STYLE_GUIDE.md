# User Style Preferences

## Visual Style

- Native macOS, SwiftUI only.
- Pastel-tinted, minimal chrome that follows the loaded preset.
- Dark-by-default; flips to light automatically when a light preset is loaded.
- Beautiful, practical UI over raw utility UI.
- Avoid cramped layouts.
- Avoid Tkinter-style forms.
- Avoid invisible labels or unlabeled icon-only buttons. Toolbar buttons must show **icon + Thai label**.
- Use clear hierarchy and grouped sections.

## Color Preferences

- Variable-driven palette: edit one base (`accent`, `bg0`, ...) and every key that references it updates.
- Detailed overrides should be possible without breaking the base palette.
- App chrome uses dynamic `theme.success` / `theme.danger` / `theme.accent` etc. driven by the loaded preset, never hard-coded greens/reds.

## UX Preferences

- Sidebar must look polished, scroll when small, with consistent menu widths.
- Mode toggle (Palette / Detailed) sits at the **bottom** of the sidebar with icons + short Thai labels.
- Preset section sits **above** Categories — preset is the higher-level intent.
- Color names must be visible. Each color must explain what part of the editor it affects.
- Group settings so the user can quickly find the right place.
- Include real setting keys for AI/dev precision.
- Apply must always go through a confirmation modal then a result modal.
- Destructive actions (delete backup, restore, remove custom target, remove preset) need a confirmation sheet, not a silent action.
- Every interactive control has a Thai `.help(...)` tooltip.

## Current UI Structure

- `Palette` mode: edits the `colors` map in `theme.json`.
- `Detailed` mode: edits individual `workbench.colorCustomizations` keys via `uiOverrides`.

Detailed groups:
- Surfaces
- Sidebar & Activity
- Tabs & Title Bar
- Borders & Focus
- Lists, Menus & Selection
- Inputs & Widgets
- Editor Details
- Buttons & Toolbar
- Git Decorations
- Scrollbar
- Terminal
- Status Bar
- Links, Chat & Notices
- Other Workbench Colors

## Toolbar

```text
[🎨 Brand mark] [Cursor ▾]   [📥 สำรอง] [↻ รีโหลด] [📁 เปิดโฟลเดอร์] [▦ พรีวิว] [⚙ ตั้งค่า]   [✓ Apply]
```

Each button shows icon + Thai label inline. Apply is a borderedProminent capsule on the right, theme-tinted.
