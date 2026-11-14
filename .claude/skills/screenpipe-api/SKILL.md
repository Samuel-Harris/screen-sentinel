---
name: screenpipe-api
description: Query the user's screen recordings, UI elements, and usage analytics via the local Screenpipe REST API at localhost:3030. Use when the user asks about their screen activity, apps, productivity, or media export.
---

# Screenpipe API

Local REST API at `http://localhost:3030`. Full reference: `GET /openapi.json`.

## Authentication

**ALL requests require authentication.** Add the auth header to every curl call:

```bash
curl -H "Authorization: Bearer $SCREENPIPE_LOCAL_API_KEY" "http://localhost:3030/..."
```

The `$SCREENPIPE_LOCAL_API_KEY` env var is already set in your environment. Without it you get 403. The only exception is `/health` (no auth needed).

## Context Window Protection

API responses can be large. Always write curl output to a file first (`curl ... -o /tmp/sp_result.json`), check size (`wc -c /tmp/sp_result.json`), and if over 5KB read only the first 50-100 lines. Extract what you need with `jq`. NEVER dump full large responses into context.

---

## 1. Search — `GET /search`

```bash
curl -H "Authorization: Bearer $SCREENPIPE_LOCAL_API_KEY" "http://localhost:3030/search?q=QUERY&content_type=all&limit=10&start_time=1h%20ago"
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | No | Keywords. |
| `content_type` | string | No | `all` (default), `accessibility`, `input`, `ocr`, `memory`. Screen text is primarily captured via the OS accessibility tree (`accessibility`); OCR is a fallback for apps without accessibility support (games, remote desktops). Use `all` unless you need a specific modality. |
| `limit` | integer | No | Max 1-20. Default: 10 |
| `offset` | integer | No | Pagination. Default: 0 |
| `start_time` | ISO 8601 or relative | **Yes** | Accepts `2024-01-15T10:00:00Z` or `16h ago`, `2d ago`, `30m ago` |
| `end_time` | ISO 8601 or relative | No | Defaults to now. Accepts `now`, `1h ago` |
| `app_name` | string | No | e.g. "Google Chrome", "Slack", "zoom.us" |
| `window_name` | string | No | Window title substring |
| `focused` | boolean | No | Only focused windows |
| `tags` | string | No | Comma-separated; return only items carrying ALL of them (e.g. `person:ada,project:atlas`). Works for screen and, with `content_type=memory`, memories. See Tags below. |
| `max_content_length` | integer | No | Truncate each result's text (middle-truncation) |

### Progressive Disclosure

Don't jump to heavy `/search` calls. Escalate:

| Step | Endpoint | When |
|------|----------|------|
| 0 | `GET /memories?q=...` | **Always query first/in parallel** — highest signal, lowest cost |
| 1 | `GET /activity-summary?start_time=...&end_time=...` | Broad questions ("what was I doing?", "which apps?") |
| 2 | `GET /search?...` | Need specific content |
| 3 | `GET /elements?...` or `GET /frames/{id}/context` | UI structure, buttons, links |
| 4 | `GET /frames/{frame_id}` (PNG) | Visual context needed |

Decision tree:
- "What was I doing?" → Step 1 only
- "How long on X?" → Step 1 (`/activity-summary` → `total_active_minutes` for the whole range, plus per-app/window `minutes`)
- "Which apps today?" → Step 1 (do NOT use frame counts or raw SQLite)
- "What button did I click?" → Step 3 (`/elements` with role=AXButton)
- "Show me what I saw" → Step 2 (find frame_id) → Step 4

### Tags — linking people, projects, topics

Tags are a shared label layer across screen and memories under one string namespace. Use namespaced tags: `person:ada`, `project:atlas`, `topic:pricing`. Two items sharing a tag are connected.

- Add to a frame: `POST /tags/vision/{frame_id}` body `{"tags":["person:ada"]}`.
- Add to a memory: include `tags` in `POST /memories` (or `PUT /memories/{id}`).
- Retrieve by tag: `GET /search?tags=person:ada&start_time=30d%20ago` (screen), or add `content_type=memory` for memories. Multiple tags AND together; matching is exact, not substring.

Frames are pruned by retention, so for a durable link tag a memory (memories also carry `created_at` and a `frame_id` back to the moment). To pull everything about a person across time: one call for captures (`content_type=all&tags=person:ada`) plus one for facts (`content_type=memory&tags=person:ada`).

### Critical Rules

1. **ALWAYS include `start_time`** — queries without time bounds WILL timeout
2. **Start with 1-2 hour ranges** — expand only if no results
3. **Use `app_name`** when user mentions a specific app
4. **Keep `limit` low** (5-10) initially
5. **"recent"** = 30 min. **"today"** = since midnight. **"yesterday"** = yesterday's range
6. If timeout, narrow the time range

### Response Format

```json
{
  "data": [
    {"type": "OCR", "content": {"frame_id": 12345, "text": "...", "timestamp": "...", "app_name": "Chrome", "window_name": "..."}},
    {"type": "UI", "content": {"id": 999, "text": "Clicked 'Submit'", "timestamp": "...", "app_name": "Safari"}}
  ],
  "pagination": {"limit": 10, "offset": 0, "total": 42}
}
```

> **Note**: The `"OCR"` type label is used for all screen text results, including text captured via the accessibility tree. Most screen text comes from accessibility, not OCR.

---

## 2. Activity Summary — `GET /activity-summary`

```bash
curl -H "Authorization: Bearer $SCREENPIPE_LOCAL_API_KEY" "http://localhost:3030/activity-summary?start_time=1h%20ago&end_time=now"
```

Returns a rich overview with:
- **total_active_minutes**: authoritative total active screen time for the whole range (every app, idle gaps excluded). Use this as the grand total / denominator. Do NOT sum `windows[].minutes` (capped at 30) and do NOT open `db.sqlite` to recompute durations — this field already is the answer.
- **apps**: per-app `minutes` (active time), first/last seen
- **windows**: every distinct window/tab with title, `browser_url`, and `minutes` spent — the most valuable field for *what* the user worked on (top 30 by time)
- **key_texts**: one representative text snippet per window context (user input fields prioritized over static page text)

This is usually enough to answer "what was I doing?" without further searches. Only drill into `/search` if you need verbatim quotes or specific content.

> **Building an automation?** Same rule: call this endpoint for time math. The numbers are computed server-side from frame timestamps — never recompute durations from raw frames, and never ask an LLM to sum minutes (it will drift). Let the model label activities; let this endpoint own the durations.

---

## 3. Elements — `GET /elements`

Lightweight FTS search across UI elements (~100-500 bytes each vs 5-20KB from `/search`).

```bash
curl -H "Authorization: Bearer $SCREENPIPE_LOCAL_API_KEY" "http://localhost:3030/elements?q=Submit&start_time=1h%20ago&limit=10"
```

Parameters: `q`, `frame_id`, `source` (`accessibility`|`ocr`), `role`, `start_time`, `end_time`, `app_name`, `limit`, `offset`.

### Frame Context — `GET /frames/{id}/context`

Returns accessibility text, parsed nodes, and extracted URLs for a frame.

```bash
curl -H "Authorization: Bearer $SCREENPIPE_LOCAL_API_KEY" "http://localhost:3030/frames/6789/context"
```

### Common Roles (platform-specific)

Roles are **not normalized** across platforms. Use the correct format for the user's OS:

| Concept | macOS | Windows | Linux |
|---------|-------|---------|-------|
| Button | `AXButton` | `Button` | `Button` |
| Static text | `AXStaticText` | `Text` | `Label` |
| Link | `AXLink` | `Hyperlink` | `Link` |
| Text field | `AXTextField` | `Edit` | `Entry` |
| Text area | `AXTextArea` | `Document` | `Text` |
| Menu item | `AXMenuItem` | `MenuItem` | `MenuItem` |
| Checkbox | `AXCheckBox` | `CheckBox` | `CheckBox` |
| Group | `AXGroup` | `Group` | `Group` |
| Web area | `AXWebArea` | `Pane` | `DocumentWeb` |
| Heading | `AXHeading` | `Header` | `Heading` |
| Tab | `AXTab` | `TabItem` | `Tab` |
| List item | `AXRow` | `ListItem` | `ListItem` |

OCR-only roles (fallback when accessibility unavailable): `line`, `word`, `block`, `paragraph`, `page`

---

## 4. Frames (Screenshots) — `GET /frames/{frame_id}`

```bash
curl -o /tmp/frame.png "http://localhost:3030/frames/12345"
```

Returns raw PNG. **Never fetch more than 2-3 frames per query** (~1000-2000 tokens each).

---

## 5. Media Export — `POST /export`

Renders a real-time MP4 (screen frames at their true timestamps). The clip's duration matches the wall-clock span you ask for — it is NOT a sped-up timelapse.

```bash
curl -X POST http://localhost:3030/export \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SCREENPIPE_LOCAL_API_KEY" \
  -d '{"start": "5m ago", "end": "now"}'
```

Fields: `start` + `end` (ISO 8601 or relative like `"2h ago"`, `"now"`; `end` defaults to now). Optional `output_path` writes the MP4 to a specific absolute path (e.g. `~/Downloads/clip.mp4`); otherwise it lands in the data dir's `exports/` folder.

Returns `{"output_path": "...", "frame_count": N, "duration_secs": N, "file_size_bytes": N}`. Show `output_path` as an inline code block for playback. Long ranges can take a few minutes.

---

## 6. Raw SQL — `POST /raw_sql`

```bash
curl -X POST http://localhost:3030/raw_sql \
  -H "Content-Type: application/json" \
  -d '{"query": "SELECT ... LIMIT 100"}'
```

**Rules**: Every SELECT needs LIMIT. Always filter by time. Read-only. Use `datetime('now', '-24 hours')` for time math.

**WARNING**: Do NOT use frame counts for time estimates — frames are event-driven, not fixed-interval. Use `/activity-summary` for screen time.

### Schema

| Table | Key Columns | Time Column |
|-------|-------------|-------------|
| `frames` | `app_name`, `window_name`, `browser_url`, `focused` | `timestamp` |
| `ocr_text` | `text`, `app_name`, `window_name` | join via `frame_id` |
| `elements` | `source`, `role`, `text`, `bounds_*` | join via `frame_id` |
| `ui_events` | `event_type`, `app_name`, `window_title`, `browser_url` | `timestamp` |
| `accessibility` | `app_name`, `window_name`, `text_content`, `browser_url` | `timestamp` |
| `memories` | `content`, `source`, `tags`, `importance` | `created_at` |

### Example Queries

```sql
-- Most used apps (last 24h)
SELECT app_name, COUNT(*) as frames FROM frames
WHERE timestamp > datetime('now', '-24 hours') AND app_name IS NOT NULL
GROUP BY app_name ORDER BY frames DESC LIMIT 20

-- Most visited domains
SELECT CASE WHEN INSTR(SUBSTR(browser_url, INSTR(browser_url, '://') + 3), '/') > 0
  THEN SUBSTR(SUBSTR(browser_url, INSTR(browser_url, '://') + 3), 1, INSTR(SUBSTR(browser_url, INSTR(browser_url, '://') + 3), '/') - 1)
  ELSE SUBSTR(browser_url, INSTR(browser_url, '://') + 3) END as domain,
COUNT(*) as visits FROM frames
WHERE timestamp > datetime('now', '-24 hours') AND browser_url IS NOT NULL
GROUP BY domain ORDER BY visits DESC LIMIT 20

-- Context switches per hour
SELECT strftime('%H:00', timestamp) as hour, COUNT(*) as switches
FROM ui_events WHERE event_type = 'app_switch' AND timestamp > datetime('now', '-24 hours')
GROUP BY hour ORDER BY hour LIMIT 24
```

Common patterns: `GROUP BY date(timestamp)` (daily), `GROUP BY strftime('%H:00', timestamp)` (hourly), `HAVING frames > 5` (filter noise).

---

## 7. Memories — High-Signal Persistent Knowledge

**Memories are the highest-signal data source in screenpipe.** They contain curated facts, user preferences, decisions, and project context — distilled from hours of screen data. Always check memories when answering questions or building context.

### When to Query Memories

**Query memories FIRST (before or alongside `/search`)** when:
- The user asks about preferences, decisions, or past context
- You need background on a project, person, or workflow
- You're generating a summary, recommendation, or action plan
- You're unsure about user preferences or past decisions
- Any task where historical context would improve the output

**Rule: If you're calling `/search`, also call `/memories` in parallel.** Memories provide the "why" behind the raw screen data. Search gives you what happened; memories tell you what matters.

### API

```bash
# Search memories (FTS) — do this often!
curl -H "Authorization: Bearer $SCREENPIPE_LOCAL_API_KEY" "http://localhost:3030/memories?q=preference&limit=20"

# List recent memories (high importance first)
curl -H "Authorization: Bearer $SCREENPIPE_LOCAL_API_KEY" "http://localhost:3030/memories?min_importance=0.5&limit=20"

# Filter by source or tags
curl -H "Authorization: Bearer $SCREENPIPE_LOCAL_API_KEY" "http://localhost:3030/memories?source=user&tags=project&limit=20"

# Create a memory
curl -X POST http://localhost:3030/memories \
  -H "Content-Type: application/json" \
  -d '{"content": "User prefers dark mode", "source": "user", "tags": ["preference", "ui"], "importance": 0.7}'

# Update a memory
curl -X PUT http://localhost:3030/memories/1 \
  -H "Content-Type: application/json" \
  -d '{"content": "User prefers dark mode in all apps", "importance": 0.8}'

# Delete a memory
curl -X DELETE http://localhost:3030/memories/1
```

Parameters for `GET /memories`: `q` (FTS search), `source`, `tags`, `min_importance`, `start_time`, `end_time`, `limit`, `offset`.

Memories also appear in `/search?content_type=memory`.

### Creating Memories

When you learn something important about the user (preferences, decisions, project context), store it as a memory. Use `importance` 0.0-1.0 to rank signal. Only store genuinely useful long-lived facts, not transient observations.

---

## 8. Notifications — `POST http://localhost:11435/notify`

Send a notification to the screenpipe desktop UI. This uses the Tauri sidecar server (port 11435), **not** the main API (port 3030).

The notification body supports **markdown**: `**bold**`, `` `inline code` ``, and `[link text](url)`. Links can be web URLs, file paths, or screenpipe deeplinks.

```bash
# Simple notification
curl -X POST http://localhost:11435/notify \
  -H "Content-Type: application/json" \
  -d '{"title": "3 new voice memos", "body": "found recordings from today"}'

# Markdown body with links
curl -X POST http://localhost:11435/notify \
  -H "Content-Type: application/json" \
  -d '{"title": "Meeting summary", "body": "**Q3 Planning** notes saved\n\nopen [meeting notes](~/Documents/notes/q3.md) or view [recording](screenpipe://timeline)"}'

# Link to a local file (absolute path or ~ path)
curl -X POST http://localhost:11435/notify \
  -H "Content-Type: application/json" \
  -d '{"title": "Export complete", "body": "saved to [report.csv](~/Downloads/report.csv)"}'

# With action buttons
# Use `type: "link"` for external URLs and `type: "deeplink"` for
# screenpipe:// in-app routes. `type: "dismiss"` closes the notification.
curl -X POST http://localhost:11435/notify \
  -H "Content-Type: application/json" \
  -d '{"title": "Meeting summary", "body": "**Q3 Planning**\n- Budget approved", "actions": [{"id": "view", "label": "view", "type": "deeplink", "url": "screenpipe://timeline"}, {"id": "skip", "label": "skip", "type": "dismiss"}]}'

# External URL action (opens in browser)
curl -X POST http://localhost:11435/notify \
  -H "Content-Type: application/json" \
  -d '{"title": "PR ready for review", "body": "nice work", "actions": [{"id": "open", "label": "open pr", "type": "link", "url": "https://github.com/screenpipe/screenpipe/pull/1234"}]}'

# Custom auto-dismiss (5 seconds)
curl -X POST http://localhost:11435/notify \
  -H "Content-Type: application/json" \
  -d '{"title": "Saved", "body": "Note saved", "timeout": 5000}'
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | **Yes** | Notification title |
| `body` | string | **Yes** | Markdown body (`**bold**`, `` `code` ``, `[text](url)`) |
| `type` | string | No | Category (default "pipe") |
| `timeout` | integer | No | Auto-dismiss in ms (default 20000) |
| `autoDismissMs` | integer | No | Alias for timeout |
| `actions` | array | No | Action buttons |

**Supported link types in body markdown:**
- Web URLs: `[docs](https://docs.screenpi.pe)` — opens in browser
- File paths: `[notes](~/notes/file.md)` or `[log](/var/log/app.log)` — opens in default app
- Deeplinks: `[timeline](screenpipe://timeline)` — navigates within screenpipe

Returns `{"success": true, "message": "Notification sent successfully"}`.

---

## 9. Other Endpoints

```bash
curl http://localhost:3030/health              # Health check
curl http://localhost:3030/vision/list          # Monitors
```

---

## Deep Links

Reference specific moments with clickable links:

```markdown
[10:30 AM — Chrome](screenpipe://frame/12345)           # screen text results (use frame_id)
```

Only use IDs/timestamps from actual search results. Never fabricate.

## Showing Videos

Show `file_path` from search results as inline code for playable video:
```
`/Users/name/.screenpipe/data/monitor_1_2024-01-15_10-30-00.mp4`
```
