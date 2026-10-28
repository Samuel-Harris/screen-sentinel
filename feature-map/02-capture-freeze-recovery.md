# 02. Recover from frozen screen capture

## Why

On macOS, ScreenCaptureKit can stop delivering new frames while the capture
loop and the HTTP server stay up. The recorder reports itself healthy and
records nothing, or keeps storing the same stale frame, until a screen lock
and unlock. For unattended recording, this is the failure that matters most.

Upstream describes three versions of it in its public changelog:

- **Stale frames.** "every screenshot returned the same stale frame silently
  ... (observed: 400+ byte-identical snapshots over 30 minutes while the user
  kept working)".
- **No frames.** "ScreenCaptureKit can stop delivering frames while the
  capture loop and HTTP server stay alive — the classic 'screenpipe says it's
  recording but I have no screenshots for days' symptom".
- **No writes.** "capture could appear 'Running' ... while persisting nothing
  for an hour or more". That one is covered in
  [03-database-resilience.md](03-database-resilience.md).

The 2.7.116 app log on this Mac from 2026-10-26 shows the stall in the wild:
`monitor 5: capture stream frozen — no new frame delivered for ~4s;
invalidating persistent stream to rebuild it`.

## State in 0.4.15

No detection. The base commit has content dedup in
`crates/screenpipe-engine/src/event_driven_capture.rs`, which skips storing a
frame identical to the last one. That dedup makes a frozen stream look like a
quiet screen. Capture goes through `sck-rs` (pinned at `b7f48a12`),
configured in `crates/screenpipe-screen/Cargo.toml` lines 78 to 80.

## Behaviour wanted

1. Per monitor, track whether ScreenCaptureKit is delivering new frames, as
   distinct from whether the pixels changed.
2. Treat a stream as frozen when:
   - no new frame arrives within a bounded window, while user input
     (keyboard, mouse or app switches) shows the user is active; or
   - delivered frames stay byte-identical across captures triggered by
     input that should change the screen, such as an app switch or typing in
     the focused window.
3. When a stream is frozen, rebuild it for that monitor only, in place,
   without restarting the process.
4. Apply a per-monitor cooldown between rebuilds, so a monitor that keeps
   failing cannot thrash.
5. Never treat a truly idle screen (no input, nothing changing) as frozen.
6. Report each detection and rebuild in the log and in `/health`: the
   monitor, the reason, the time and a running count.

## Done when

- A fault-injection test that stops delivering frames, or repeats the last
  frame, while synthetic input continues triggers exactly one rebuild per
  cooldown window, and capture resumes.
- An hour with the screen idle and no input triggers zero rebuilds.
- `/health` shows the last frame time per monitor and the rebuild count.
- Over a 24-hour unattended run with at least one sleep/wake cycle, there is
  no gap longer than the frozen-stream window during active use. Check frame
  timestamps per monitor against input timestamps in `ui_events`.
