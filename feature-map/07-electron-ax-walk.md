# 07. Full accessibility walk inside Electron apps

## Why

Cursor, VS Code, Slack, Discord, Obsidian and Notion are Electron apps. Their
real content sits deep inside an `AXWebArea`, under seven to nine levels of
`AXGroup` wrappers. A walker with a fixed depth budget spends most of it on
the wrappers and drops editor text, terminal output and chat scrollback.

## State in 0.4.15

Present on macOS. In `crates/screenpipe-a11y/src/tree/macos.rs`, lines 1131
to 1137, the walker resets its depth counter to 0 when it enters an
`AXWebArea`. The comment above it describes this exact truncation. VS Code
terminal handling also raises `max_depth` to 40 (line 482).

Upstream's public changelog lists the same fix twice, once before June and
once on 2026-07-20 ("The depth counter now resets at `AXWebArea`
boundaries"). The later entry is probably a regression fix or covers another
code path. Nothing public says which.

## Work

Verify only. Write a fix only if the check fails, and then only for the case
that failed.

## Check

For each of Cursor, VS Code, Slack and Notion, open a view whose text you
know, then confirm that `/search` for a distinctive string from the deepest
part of the view returns that frame:

- an editor line far down a long file;
- the last line of terminal output;
- an old message in a long channel;
- a nested list item.

Also record `max_depth_reached` and any truncation reason (`node limit` or
`timeout`) for those frames.

## Done when

All four apps return the distinctive string, and no frame from them shows
truncation. If any fails, note which limit it hit (depth, node count or walk
timeout), because each needs a different fix.
