# 01. Strip what the fork does not use

## Why

The fork records the screen on one Mac for agents to query. Everything else
adds build time, permission prompts, attack surface and network traffic from
an employer machine, with nothing to show for it.

## Remove

| Area | Where it lives at the base commit | Notes |
| --- | --- | --- |
| Audio capture and transcription | `crates/screenpipe-audio`, `crates/screenpipe-audio-eval`, the `audio`, `transcribe` and `retranscribe` routes | `screenpipe-engine` depends on `screenpipe-audio` unconditionally (`crates/screenpipe-engine/Cargo.toml` line 20), and its default features are `qwen3-asr`, `parakeet` and `redact-onnx-cpu`. This is real surgery on the engine, not a flag |
| Meetings and speakers | `crates/screenpipe-meeting-eval`, `crates/screenpipe-engine/src/meeting_telemetry.rs`, the `meetings` and `speakers` routes and tables | Drop those tables. No existing database needs to open |
| Team memory and sync | `crates/screenpipe-team-memory`, `crates/screenpipe-sync`, the `cloud-sync` feature on `screenpipe-core` | |
| Pipes and agents | `crates/screenpipe-core/src/pipes`, `crates/screenpipe-core/src/agents`, the `/pipes` routes, `routes/pipe_store.rs`, the pipe CLI commands | Pipes are scheduled prompts. Agents are the coding CLIs that pipes spawn. Agents that query the fork run outside it |
| Connections | `crates/screenpipe-connect`, `crates/screenpipe-core/src/connections`, the `/connections` routes, the browser-extension bridge | `screenpipe-connect` is a direct engine dependency (line 28). It covers OAuth, calendars, WhatsApp, MCP server configs and mDNS |
| Memory sync | `crates/screenpipe-core/src/memories/sync.rs`, `crates/screenpipe-core/src/memories/external_sync.rs`, `POST /memories/sync-external`, the memory sync columns | Memories stay (see Keep). Cross-device sync goes, and so does the digest that writes into Claude Code's `CLAUDE.md` and Codex's `AGENTS.md` |
| Enterprise code | `ee/` | Different licence. Delete in the first commit |
| Hosted AI | `packages/ai-gateway`, `crates/screenpipe-engine/src/routes/cloud_proxy.rs` | |
| Apple Intelligence | `crates/screenpipe-apple-intelligence`, the `apple-intelligence` feature on the engine and the app, `crates/screenpipe-engine/src/apple_intelligence_api.rs` | It serves a local OpenAI-compatible LLM at `/ai/chat/completions`. Its only callers are the app's chat, daily summary, suggestions and connection card, and pipes, all removed here or in 11 |
| Telemetry | `crates/screenpipe-engine/src/analytics.rs` (PostHog), `crates/screenpipe-engine/src/telemetry_context.rs`, the `sentry` dependency | `server.rs` line 415 calls `analytics::track_api_usage` on every API request |
| MCP tools for removed areas | `packages/screenpipe-mcp` (MIT, version 0.18.10 at the base commit) | Drop `list-audio-devices`, the meeting tools, the speaker tools and the `team-*` tools |

## Keep

- `screenpipe-a11y`, `screenpipe-screen`, `screenpipe-capture`,
  `screenpipe-engine`, `screenpipe-db`, `screenpipe-events`,
  `screenpipe-config` and `screenpipe-core` (without `cloud-sync`).
- The REST API for search, elements, frames, activity summary and raw SQL.
- Memories as a local store: the table, the `/memories` CRUD and tag
  routes, and the `update-memory` MCP tool. Agents write memories. The
  recorder never does.
- `screenpipe-redact` and `screenpipe-rfdetr-mlx`, both tiers. The regex
  scrub (`use_pii_removal`) stays on by default. The ML text and image
  workers stay off by default and download their models only when the
  user turns them on.
- `screenpipe-vault` and `screenpipe-secrets`, unchanged. Vault crypto
  encrypts the settings store for the engine and the app, and the vault
  lock encrypts the data directory at rest. The secret store holds the
  local API auth key (`crates/screenpipe-engine/src/auth_key.rs`).
- `packages/cli` and `packages/screenpipe-mcp`, renamed in 02.
- `apps/screenpipe-app-tauri`. 01 edits it only as far as it needs to
  compile and launch without the removed crates. The real trim is 11.

## Done when

- `cargo tree` for the engine binary and for the app lists no audio,
  meeting, sync, team, connect, Apple Intelligence, PostHog or Sentry
  crate.
- The source tree has no `pipes`, `agents` or `connections` module, and no
  `/pipes`, `/connections`, `/ai`, `/v1/chat/completions` or
  `/memories/sync-external` route.
- No `Info.plist` contains `NSMicrophoneUsageDescription`, no entitlements
  file grants audio input, and the built engine and app binaries do not
  link `cpal` or an audio-capture framework. This check runs in CI.
- `nettop -p <pid>` or Little Snitch shows no outbound connections during
  one hour of recording with default settings. The only allowed exception
  is a model download the user starts by turning on ML redaction.
- The app builds and launches, and recording starts from the tray.
- The MCP server lists only the tools that still have a backing route.
