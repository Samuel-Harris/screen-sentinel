# 09. Trim the desktop app to a screen-only recorder

## Why

The fork runs on one Mac for one person. A tray status, a first-run
permission flow and a window for looking back at captured screens make the
recorder usable without a terminal. Upstream's app already has all three, and
`apps/screenpipe-app-tauri` is MIT at the base commit. They come wrapped in
audio, accounts, a paywall, pipes, a chat agent, an updater and telemetry.
Trim the app. Do not write a new one.

This only has to work on the owner's own machine. There is no installer,
no distribution, and no first-run check on a fresh user.

## Process model

**State in 0.4.15.** The engine runs inside the app as a library, not as a
sidecar (`src-tauri/Cargo.toml` lines 128-149; `externalBin` is empty in
`tauri.conf.json`). `ServerCore` holds the database and HTTP server for the
app's lifetime (`src-tauri/src/server_core.rs`). `CaptureSession` holds
capture and can be toggled (`src-tauri/src/capture_session.rs`). Autostart
uses `tauri-plugin-autostart` with a LaunchAgent (`src-tauri/src/main.rs`
lines 868-869).

**Wanted.** Keep this model. Quitting the app stops recording. The app starts
at login.

## Keep

Paths are under `apps/screenpipe-app-tauri/`.

| Surface | Where at the base commit | Keep | Remove |
| --- | --- | --- | --- |
| Tray | `src-tauri/src/tray.rs` lines 580-853 | Recording status, toggle recording, pause 5/15/30/60 min, per-monitor items, HD recording timers, "Fix permissions", Settings, Quit | Chat, audio-device toggles, plan label, "Upgrade to Business", "Update now", HD "until call ends", Feedback, Book call, Skip onboarding |
| Timeline and search | `components/rewind/*`, the Search window | Scrubbing captured frames, search over screen text | The overlay panel (`tauri_nspanel`, `src-tauri/src/window/show.rs` line 31) and the `overlayMode` setting (`src-tauri/src/store.rs` line 662). Daily summary and AI presets |
| Settings | `app/settings/page.tsx` lines 81-94, 233-261 | Display, General, Recording (screen settings only), Privacy, Storage, Usage | Shortcuts, AI models, Notifications, Speakers, Team, Account, Referral |
| Onboarding | `stepOrder` in `app/onboarding/page.tsx` line 117, `app/permission-recovery` | Permissions, EngineStartup, the permission-recovery window | Login, ConnectApps, PickPipe |

Timeline and search open in an ordinary resizable window from the tray. The
app registers no global shortcuts.

Onboarding asks for Screen Recording and Accessibility only, as 01 requires.
`src-tauri/src/permissions.rs` also requests Microphone (line 85) and Input
Monitoring (line 331). Remove the Microphone request. If text and input
capture turn out to need Input Monitoring, record that in this file and in
01 instead of quietly keeping the prompt.

## Remove

Delete each of these outright. Turning them off with a setting does not count.

| Area | Where at the base commit |
| --- | --- |
| Paid entitlement gate | `require_app_entitlement` (`src-tauri/src/recording.rs` line 74, enforced at 399, 587, 965), the `app-entitlement-required` event (`src-tauri/src/main.rs` lines 1431-1434), `components/app-entitlement-gate.tsx` |
| Updater | `tauri-plugin-updater` (`main.rs` line 860), `src-tauri/src/updates.rs`, `update-banner.tsx`, the endpoints in `tauri.beta.conf.json` and `tauri.enterprise.conf.json` |
| Telemetry | Sentry (hardcoded DSN at `main.rs` lines 508-511, `tauri-plugin-sentry`, `@sentry/react`), PostHog (`src-tauri/src/analytics.rs`, `app/providers.tsx` line 128), the attribution call to screenpi.pe. At the base commit all of it is on unless `analyticsEnabled` is false (`main.rs` lines 502-504) |
| Global shortcuts | `src-tauri/src/shortcuts.rs`, the shortcut-reminder window |
| Chat agent, pipes, memories, meeting notes, connections, notifications | `src-tauri/src/pi.rs`, the Home sidebar items (`app/home/page.tsx` lines 864-869), the Chat and notification-panel windows |
| Bundled `bun` | `tauri.macos.conf.json` line 13. Its callers are in `pi.rs`, so drop it with the chat agent unless something kept still calls it |

`tauri-plugin-permission-flow` is a git dependency on
`github.com/divanshu-go/permission-flow` at `d7376a1b`. It is outside the
`screenpipe/*` pinning rule in the README, but vendor it the same way or
remove it.

## Signing

`scripts/build_macos.sh` lines 15-16 sign with upstream's personal Apple
Development certificate. No `tauri*.json` sets `signingIdentity`. Sign with
your own certificate and the bundle identifier from 02, so Screen
Recording and Accessibility grants survive every rebuild. Without that, a
rebuild silently drops the Screen Recording grant and the unattended day
below fails.

## Done when

- Launched at login and left for 8 hours, including at least one sleep/wake
  cycle, the app never exits or restarts, the tray shows recording
  throughout, and the timeline window shows frames across the whole period.
  During active use there is no gap longer than 03's frozen-stream window.
- The tray status comes from the same state as `/health`. 03's
  fault-injection test changes what the tray shows.
- `nettop -p <pid>` or Little Snitch shows no outbound connections during one
  hour with the timeline open and every settings section visited.
- Rebuilding and reinstalling the app keeps the Screen Recording and
  Accessibility grants.
- No login, paywall, upgrade, chat, pipe, audio or meeting UI can be reached
  from the tray, the windows or settings.
- `cargo tree` for the app lists no Sentry, PostHog, updater, audio, sync,
  team or connect crate.
