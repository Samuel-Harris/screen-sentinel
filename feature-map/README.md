# Feature map: an MIT recorder built from screenpipe 0.4.15

This directory describes the features to add to, or remove from, a personal
fork of screenpipe CLI 0.4.15. Each file states the behaviour wanted, what
0.4.15 already does, and how to tell the work is finished. None of them says
how to implement the change.

## Base

| Item | Value |
| --- | --- |
| Upstream commit | [`420e6c0e8a5f00c60e3c048640d6c70a7f180a4f`](https://github.com/screenpipe/screenpipe/tree/420e6c0e8a5f00c60e3c048640d6c70a7f180a4f) ("Bump app to v2.5.28 and CLI to v0.4.15", 2026-06-10 01:58 UTC) |
| Licence at that commit | `LICENSE.md` is MIT; the workspace `Cargo.toml` declares `MIT OR Apache-2.0` |
| Excluded at that commit | `ee/` (Screenpipe Enterprise Edition licence). Delete it in the first commit |
| Licence change upstream | `81e412ff53`, 2026-06-10 13:24 UTC, seven commits later |

Seed the fork with a shallow clone of the upstream commit pushed to a new
private repository, not with GitHub's fork button. A GitHub fork carries the
whole upstream network, including every commit under the commercial licence,
and cannot be made private.

## Clean-room rule

Every feature here exists upstream under the Screenpipe Commercial License.
Rewrite each one from:

- the MIT tree at the base commit;
- public descriptions of behaviour, such as the
  [changelog](https://docs.screenpipe.com/changelog), the docs and the README;
- your own measurements.

Do not read screenpipe source, diffs or pull requests dated after
2026-06-10 13:24 UTC while working on these features, and do not hand them to
an agent that has. Copy this rule into the fork's `AGENTS.md`.

Pinned git dependencies need the same care. `screenpipe/sck-rs` at
`b7f48a12` (2026-05-30) declares `license = "MIT"` in its `Cargo.toml` but
ships no LICENSE file. Do not bump it, or any other `github.com/screenpipe/*`
dependency in `Cargo.lock` (`cpal`, `opf-rs`, `rusty-tesseract`, `whisper-rs`),
past 2026-06-10. Vendor them so the build does not depend on upstream
keeping those revisions.

## Features

| File | Feature | State in 0.4.15 |
| --- | --- | --- |
| [01-strip-unused.md](01-strip-unused.md) | Remove audio, meetings, speakers, team, sync, the desktop app and cloud paths | Present; to remove |
| [02-capture-freeze-recovery.md](02-capture-freeze-recovery.md) | Recover automatically when ScreenCaptureKit stops delivering fresh frames | Missing |
| [03-database-resilience.md](03-database-resilience.md) | Survive sleep/wake, write wedges and heavy-load checkpoints without corruption | Partial |
| [04-token-efficient-api.md](04-token-efficient-api.md) | Columnar and outline response formats for agents | Missing |
| [05-browser-url-from-ax.md](05-browser-url-from-ax.md) | Read browser URLs from the accessibility tree for all Chromium browsers and Electron apps | Partial |
| [06-capture-debounce.md](06-capture-debounce.md) | One shared debounce floor for typing and clipboard triggers | Unverified; measure first |
| [07-electron-ax-walk.md](07-electron-ax-walk.md) | Full accessibility walk inside Electron apps | Present; verify only |

Order of work: 01 first, so later changes land on the smaller tree. Then 02
and 03, because unattended recording is useless without them. Then 05, 04
and 06. Do 07 only if its check fails.

## Out of scope

- Audio capture, transcription and meetings (see 01).
- The desktop app, pipes and the hosted `pi` agent.
- Sync, team memory and cloud AI.
- The screenpipe name and logo. Rename the binary, crate prefixes and data
  directory, so the fork never collides with an official install
  (`~/.screenpipe`, port 3030, LaunchAgent label `screenpipe`).
