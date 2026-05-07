# Troubleshooting Log

## Tkinter Alpha Color Crash

Error:

```text
_tkinter.TclError: invalid color name "#FFFFFF00"
```

Cause:

Tkinter labels cannot use 8-digit hex colors with alpha.

Resolution:

Moved away from Tkinter. Native SwiftUI app handles display better.

## Poor Tkinter UX

Symptoms:

- Labels were not visible.
- Pick buttons floated without context.
- Layout broke visually.
- User said UX/UI was unusable.

Resolution:

Rebuilt as native SwiftUI macOS app with grouped navigation, labels, swatches, and glass styling.

## Sidebar Overflow

Symptoms:

- Sidebar content pierced through when window was resized smaller.
- Menu card widths were inconsistent.

Cause:

Sidebar was a fixed `VStack` without enough scroll behavior and consistent max width.

Resolution:

- Sidebar is wrapped in `ScrollView`.
- Glass cards use `frame(maxWidth: .infinity, alignment: .leading)`.
- Navigation column has min/ideal width.

## App Icon Not Showing In Dock / Stage Manager

Cause:

The app bundle needed `CFBundleIconFile` and a valid `.icns` resource.

Resolution:

- `Info.plist` sets `CFBundleIconFile` to `AppIcon`.
- Bundle includes `Contents/Resources/AppIcon.icns`.
- Installed app is registered by opening/reinstalling the bundle.

## Backup Collision

Error:

```text
couldn't be copied to "User" because an item with the same name already exists
```

Cause:

Backups used ISO timestamp precision to seconds. Multiple apply clicks in the same second produced the same backup name.

Resolution:

`uniqueBackupURL` appends a numeric suffix when a backup path already exists.

## Node Generator Failed From GUI

Error:

```text
Apply failed: node generator failed
```

Cause:

The app launched from macOS GUI did not inherit shell PATH. User's Node was installed through `nvm` at:

```text
~/.nvm/versions/node/v23.1.0/bin/node
```

Resolution:

The app now searches:

- `~/.volta/bin/node`
- `/opt/homebrew/bin/node`
- `/usr/local/bin/node`
- `/usr/bin/node`
- `~/.nvm/versions/node/*/bin/node`
- fallback `/usr/bin/env node`

The app also captures stdout/stderr and shows generator error output.

## Cursor Glass Theme Cache

Symptom:

Colors in `settings.json` changed but Cursor did not immediately show them.

Cause:

Cursor/Glass may store runtime theme state in:

```text
~/Library/Application Support/Cursor/User/globalStorage/state.vscdb
```

Resolution:

Do not write DB directly. Ask the user to run `Developer: Reload Window` in Cursor if needed.

