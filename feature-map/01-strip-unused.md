# 01. Strip what the fork does not use

## Why

The fork records the screen on one Mac for agents to query. Everything else
adds build time, permission prompts, attack surface and network traffic from
an employer machine, with nothing to show for it.

## Remove

| Area | Where it lives at the base commit | Notes |
| --- | --- | --- |
| Audio capture and transcription | `crates/screenpipe-audio`, `crates/screenpipe-audio-eval` | `screenpipe-engine` depends on `screenpipe-audio` unconditionally (`crates/screenpipe-engine/Cargo.toml` line 20), and its default features are `qwen3-asr`, `parakeet` and `redact-onnx-cpu`. This is real surgery on the engine, not a flag |
| Meetings and speakers | `crates/screenpipe-meeting-eval`, `crates/screenpipe-engine/src/meeting_telemetry.rs`, meeting routes and tables | Keep existing migrations so old databases still open; stop writing to those tables |
| Team memory and sync | `crates/screenpipe-team-memory`, `crates/screenpipe-sync`, the `cloud-sync` feature on `screenpipe-core` | |
| Desktop app | `apps/screenpipe-app-tauri` | |
| Enterprise code | `ee/` | Different licence. Delete in the first commit |
| Hosted AI and integrations | `packages/ai-gateway`, `crates/screenpipe-connect` | `screenpipe-connect` is a direct engine dependency (line 28) |
| Telemetry | `crates/screenpipe-engine/src/analytics.rs` (PostHog), `crates/screenpipe-engine/src/telemetry_context.rs`, the `sentry` dependency | `server.rs` line 415 calls `analytics::track_api_usage` on every API request |
| MCP tools for removed areas | `packages/screenpipe-mcp` (MIT, version 0.18.10 at the base commit) | Drop `list-audio-devices`, the meeting tools, the speaker tools and the `team-*` tools |

## Keep

- `screenpipe-a11y`, `screenpipe-screen`, `screenpipe-capture`,
  `screenpipe-engine`, `screenpipe-db`, `screenpipe-events`,
  `screenpipe-config` and `screenpipe-core` (without `cloud-sync`).
- The REST API for search, elements, frames, activity summary and raw SQL.
- `packages/cli` and `packages/screenpipe-mcp`, renamed.

## Undecided

These are not on the removal list, so they stay until you choose otherwise:

- `screenpipe-redact` and `screenpipe-rfdetr-mlx`, the on-device PII
  redaction for text and images. It is useful on an employer machine, but
  costs CPU and model downloads.
- `screenpipe-vault` and `screenpipe-secrets`, which are direct engine
  dependencies.
- `screenpipe-apple-intelligence`, an optional feature that is off by
  default.

## Done when

- `cargo tree` for the engine binary lists no audio, meeting, sync, team,
  connect, PostHog or Sentry crate.
- A first run on a fresh macOS user asks for Screen Recording and
  Accessibility only, never Microphone.
- `nettop -p <pid>` or Little Snitch shows no outbound connections during
  one hour of recording, model downloads included.
- An existing 0.4.15 database still opens, and `/search` returns its screen
  rows.
- The MCP server lists only the tools that still have a backing route.
