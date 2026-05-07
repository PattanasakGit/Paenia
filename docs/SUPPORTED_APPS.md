# Supported Apps

Workbench Theme Studio targets editors that use VS Code-compatible `User/settings.json` files and support `workbench.colorCustomizations`.

## Built-In Targets

| App | macOS settings path | Status |
| --- | --- | --- |
| Visual Studio Code | `~/Library/Application Support/Code/User/settings.json` | Official VS Code behavior |
| Cursor | `~/Library/Application Support/Cursor/User/settings.json` | Confirmed on this machine |
| Antigravity | `~/Library/Application Support/Antigravity/User/settings.json` | Confirmed folder/app on this machine |
| Trae | `~/Library/Application Support/Trae/User/settings.json` | Confirmed folder/app on this machine |
| Windsurf | `~/Library/Application Support/Windsurf/User/settings.json` | VS Code-family expected path |
| VSCodium | `~/Library/Application Support/VSCodium/User/settings.json` | VS Code-family expected path |
| Kiro | `~/Library/Application Support/Kiro/User/settings.json` | VS Code-family expected path |
| Positron | `~/Library/Application Support/Positron/User/settings.json` | VS Code-family expected path |
| Code - OSS | `~/Library/Application Support/Code - OSS/User/settings.json` | VS Code-family expected path |

## Local Detection On 2026-05-07

Installed apps found in `/Applications`:

- `Visual Studio Code.app`
- `Cursor.app`
- `Antigravity.app`
- `Trae.app`

Config folders found in `~/Library/Application Support`:

- `Code`
- `Cursor`
- `Antigravity`
- `Trae`

## Source Notes

- VS Code documents `settings.json` and `workbench.colorCustomizations` as standard user settings.
- Windsurf, Kiro, and related AI editors document VS Code settings/import compatibility.
- Antigravity and Trae use VS Code-family app support folder patterns on this machine.

