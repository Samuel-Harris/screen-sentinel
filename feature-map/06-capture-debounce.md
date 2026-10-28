# 06. A shared debounce floor for typing and clipboard triggers

## Why

Each capture is a screenshot, an accessibility walk, optional OCR and a
database write. When every keystroke or clipboard change triggers one, CPU
and disk climb while you type, and the database fills with near-duplicate
frames that the review then has to wade through.

Upstream's public changelog describes the problem: key-press, typing-pause
and clipboard triggers "used to bypass the capture debounce, chaining a
screenshot + tree walk + OCR + DB write on every keystroke". The fix gives
them "a 1.5s debounce floor" shared with the other triggers, "cutting
redundant captures by ~90% during typing bursts while still capturing the end
of every burst".

## State in 0.4.15

Unverified. Measure before changing anything.
`crates/screenpipe-engine/src/event_driven_capture.rs` has:

- `min_capture_interval_ms`, default 200 (line 299), and a debounce check
  (line 338);
- `KeyPress`, `TypingPause` and `Clipboard` triggers (lines 76 to 84);
- comments that `TypingPause` is "already burst-end-debounced at
  `text_timeout_ms`" (line 376), and that dedup is bypassed after 30 s
  without a write (line 648).

So some debouncing exists. Whether key and clipboard triggers skip it is
not clear from reading the code.

## Behaviour wanted

1. Typing, key-press and clipboard triggers share one debounce floor with
   every other trigger. The default is 1.5 s, configurable.
2. Triggers that arrive inside the floor merge into the next capture instead
   of each starting one.
3. The final state at the end of every typing burst is always captured,
   once.
4. Click, app-switch and window-focus triggers keep their current latency.

## Done when

- **Measure first.** Type continuously for 60 s in Cursor, then in Slack,
  and count the frames written in that window. If 0.4.15 already writes at
  most one frame per 1.5 s and captures each burst end, mark this feature
  as not needed and stop.
- **Otherwise,** after the change the same test writes at most 41 frames per
  60 s of typing, about one per 1.5 s, and the final text of every burst
  appears in search.
- App-switch-to-capture latency is unchanged, within 10%.
