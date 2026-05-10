# Paenia

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
- **Update hint** — shortly after launch, the app quietly asks GitHub for the latest release; if it is newer than your build, a Thai dialog offers the download link (or you can silence that release tag). You can also run **Settings → About → ตรวจสอบอัปเดต** anytime.

## Installed Locations

```text
~/Applications/Paenia.app
~/Library/Application Support/Paenia/theme.json
```

## Build & Install

```sh
./scripts/build.sh      # build into build/Paenia.app
./scripts/install.sh    # build + copy into ~/Applications and seed theme.json
./scripts/make_dmg.sh   # build + create build/Paenia-<version>-macos.dmg (includes Applications alias)
```

The DMG is **not** code-signed or notarized. First-time open: right-click `Paenia.app` → **Open**, or allow under **System Settings → Privacy & Security**.

To expose the same `.dmg` on **PaeniaWeb**, set `githubRepo` / `releaseTag` / `dmgFileName` / checksum in `PaeniaWeb/lib/download.ts`, or override with `NEXT_PUBLIC_PAENIA_DMG_URL` — see `PaeniaWeb/.env.example`.

### Publish the `.dmg` on GitHub

1. Commit and push the Paenia repo, then create a **tag** matching `releaseTag` (e.g. `v0.0.95`).
2. **Releases → Draft a release** → choose that tag → upload `build/Paenia-<version>-macos.dmg` from `./scripts/make_dmg.sh`.
3. Publish the release. The site link is `https://github.com/<owner>/<repo>/releases/download/<tag>/<dmgFileName>`.
4. If the DMG bytes change, run `shasum -a 256` on the new file and update `PaeniaWeb/lib/download.ts` (`sha256`, and `fileSize` if needed).

The installer only seeds `theme.json` if it does not already exist; existing user state is preserved across reinstalls.

## Open

```sh
open "$HOME/Applications/Paenia.app"
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
