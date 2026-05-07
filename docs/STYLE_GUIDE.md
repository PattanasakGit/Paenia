# User Style Preferences

## Visual Style

- Minimal dark mode.
- Minimal Glass style matching modern macOS.
- Beautiful, practical UI over raw utility UI.
- Avoid cramped layouts.
- Avoid Tkinter-style forms.
- Avoid invisible labels or unlabeled color pickers.
- Use clear hierarchy and grouped sections.

## Color Preferences

The user likes vivid dark themes when requested:

- Cyber violet / neon dark direction.
- Strong accent colors.
- Dark surfaces with readable text.
- Accent should be easy to notice.

The user also wants variable-driven colors:

- One base variable should drive a whole zone.
- Detailed overrides should be possible without breaking the base palette.

## UX Preferences

- Sidebar must look polished.
- Sidebar must scroll when the window is small.
- Sidebar menu item frames should be consistent.
- Color names must be clearly visible.
- Each color must explain what part of Cursor it affects.
- Group settings so the user can quickly find the right place.
- Include real setting keys for AI/dev precision.

## Current UI Structure

- `Base Palette`: edits shared semantic colors.
- `Detailed Colors`: edits individual `workbench.colorCustomizations` keys.
- Detailed groups:
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

