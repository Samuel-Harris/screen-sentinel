# 05. Browser URLs from the accessibility tree

## Why

The review needs to know which site or web app you were in, for example
GitHub, Linear or a doc. That has to be cheap enough to run on every capture,
and must not trigger macOS Automation permission prompts on an employer
machine.

## State in 0.4.15

Partial. `extract_browser_url` in `crates/screenpipe-a11y/src/tree/macos.rs`
(lines 159 to 200) tries three tiers in order:

1. `AXDocument` on the focused window, accepted when it starts with
   `http://` or `https://`.
2. For Arc only, AppleScript through `osascript` (`get_arc_url`, line 204).
   This spawns a process, costs about 150 to 200 ms and needs Automation
   permission.
3. A shallow walk, five levels deep, for an `AXTextField` holding a URL-like
   value.

It runs after the tree walk, so it does not count against the walk timeout.

## Behaviour wanted

1. Read the URL from the focused tab's `AXWebArea` (its URL attribute)
   during the walk already in progress. No separate pass.
2. Cover every Chromium-family browser (Chrome, Edge, Brave, Vivaldi, Opera,
   Arc), Safari, and Electron apps that host web content.
3. Remove the AppleScript tier. No `osascript` process, and no Automation
   prompt.
4. Drop non-web schemes (`chrome://`, `arc://`, `edge://`, `about:`,
   `chrome-extension://`) instead of recording them as browsing history.
5. Keep the existing `AXDocument` and text-field tiers as fallbacks, after
   the web-area read.

Upstream reports the per-check cost falling from about 150 to 200 ms to
about 2 ms.

## Done when

- A matrix test across each browser listed (plus Cursor and Slack) records
  the correct URL for a known page in each one.
- `sudo fs_usage` or `ps` during an hour of recording shows no `osascript`
  child process.
- A fresh macOS user is never shown an Automation permission prompt.
- Median URL extraction time per capture is under 10 ms, measured with the
  existing tracing timers.
- No `chrome://` or `arc://` URLs appear in `frames.browser_url`.
