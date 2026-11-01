# 02. Rename to Screen Sentinel

## Why

The fork must never collide with an official screenpipe install on the same
Mac. It must also never be mistaken for one. The MIT licence covers the
code, not the screenpipe name or logo. Rename right after 01, so the rename
runs over the smaller tree and every later change lands on the new names.

## Names

| Form | Used for |
| --- | --- |
| `screen-sentinel` | Binary, crate and package prefix, MCP server binaries, directory names |
| `screen_sentinel` | Rust identifiers and module paths |
| `SCREEN_SENTINEL_` | Environment variable prefix |
| `Screen Sentinel` | Product name, window titles, tray and menu text |
| `~/.screen-sentinel` | Data directory |
| `screen-sentinel://` | URL scheme |

Also pick, once:

- A reverse-DNS bundle identifier under a domain or name you own. The app,
  its LaunchAgent label and its keychain items use it.
- A default port other than 3030.

## What carries the name at the base commit

Measured over the base tree, before 01 removes anything:

- `git grep -i screenpipe` matches 10,100 lines in 1,312 files.
- 19 crates under `crates/` are named `screenpipe-*`. The engine binary is
  `screenpipe` (`crates/screenpipe-engine/Cargo.toml` lines 189-191).
- npm packages: `@screenpipe/cli-packages` (`packages/cli`),
  `screenpipe-mcp` with binaries `screenpipe-mcp` and `screenpipe-mcp-http`,
  `@screenpipe/browser-extension` and `@screenpipe/e2e`.
- The app: `productName` and `identifier` in every
  `apps/screenpipe-app-tauri/src-tauri/tauri*.json` (`screenpi.pe`,
  `screenpi.pe.dev`, `screenpi.pe.beta`, `screenpi.pe.enterprise`), and the
  deep-link scheme `screenpipe` (`tauri.conf.json` line 55).
- 82 distinct `SCREENPIPE_*` environment variables.
- 88 Rust source files under `crates/` and the app refer to the
  `.screenpipe` data directory.
- The source file header that `CLAUDE.md` requires in every file, and
  `CLAUDE.md`, `README.md`, `translated_readmes/` and `docs/`.

## Keep unchanged

- The copyright notice in `LICENSE.md`. MIT requires it. Add your own line
  below it.
- The names of the vendored `github.com/screenpipe/*` dependencies from the
  README, so where they came from stays traceable.
- Provenance statements, such as "built from screenpipe 0.4.15" with a link
  to the base commit, and this feature map.

## Existing recordings

Nothing moves data from `~/.screenpipe` automatically. To keep 0.4.15
recordings, copy the directory to `~/.screen-sentinel` or point the recorder
at it with `--data-dir`. 01's check that an old database still opens runs
that way.

## Artwork

Replace every screenpipe icon and image with Screen Sentinel artwork. Get
the artwork from wherever you like. This file only requires that none of the
old artwork remains.

| Artwork | Where at the base commit | Wanted |
| --- | --- | --- |
| App icons | `apps/screenpipe-app-tauri/src-tauri/icons/` and its `app/` subdirectory | Replace |
| Icon sets the fork does not build | `icons/ios/`, `icons/android/`, `icons/beta/` | Delete |
| Tray icons | `apps/screenpipe-app-tauri/src-tauri/assets/` and `assets/svg/` | Replace. Must read clearly in light and dark menu bars |
| Web app icons | `apps/screenpipe-app-tauri/public/32x32.png`, `public/128x128.png` | Replace |
| README cover art | Banner and logo, hosted as GitHub attachments (`README.md` lines 2 and 7) | Replace with cover art stored in the repo |
| README screenshots and badges | `README.md` lines 23-40, 48-49 and 74 | Delete |

Third-party logos in `public/images/` are not screenpipe artwork. Most of
them go with 01's removals.

## Done when

- `git grep -il screenpipe` lists only the files named under "Keep
  unchanged". A script holds that allowlist and fails on any other match.
- The built app shows "Screen Sentinel" in Finder, the tray, window titles
  and About. The CLI binary is `screen-sentinel`.
- With an official screenpipe install running on the same Mac, the fork
  starts and records. Neither one reads or writes the other's data
  directory, port, LaunchAgent, keychain items or URL scheme.
- After a first run, `~/.screen-sentinel` holds the database and
  `~/.screenpipe` was neither created nor modified.
- No image file in the tree is byte-identical to a screenpipe image at the
  base commit.
