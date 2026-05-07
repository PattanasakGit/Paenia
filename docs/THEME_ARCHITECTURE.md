# Theme Architecture

## Data Flow

```text
SwiftUI App
  edits base colors and uiOverrides
    -> workbench-theme-generator.mjs
      generates workbench.colorCustomizations for selected target settings paths
      generates editor.tokenColorCustomizations
        -> settings.json
          -> Cursor UI after reload/apply
```

## Generator Sections

### `themeSettings`

Cursor and Glass theme settings.

### `colors`

Base semantic color variables. These are the main theme controls.

Examples:

- `bg0`
- `bg1`
- `fg0`
- `accent`
- `accentSoft`
- `green`
- `red`
- `purple`
- `overlayLow`

### `ui`

Maps Cursor/VS Code workbench color keys to base colors.

Examples:

- `editor.background`
- `sideBar.background`
- `tab.activeBackground`
- `gitDecoration.modifiedResourceForeground`
- `scrollbarSlider.background`

### `uiOverrides`

Direct user overrides. This is where the app stores detailed edits.

This lets the user change one setting without changing the whole palette.

### `tokenRules`

TextMate token colors for editor syntax highlighting.

## Future Work

- Add detailed token color editor.
- Add search/filter for detailed keys.
- Add export/import presets.
- Add preview screenshot comparison.
- Add richer app icon generation workflow.
