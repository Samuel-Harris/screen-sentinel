---
name: screen-sentinel-cli
description: Manage Screen Sentinel pipes (scheduled AI automations) and connections (Telegram, Slack, Discord, etc.) via the CLI. Use when the user asks to create, list, enable, disable, run, or debug pipes, or manage service connections from the command line.
---

# Screen Sentinel CLI

Use `bun x screen-sentinel@latest` to run CLI commands. No separate install needed.

**IMPORTANT**: Always run `bun x` commands from a clean temp directory to avoid node_modules conflicts:
```bash
cd "$(mktemp -d)" && bun x screen-sentinel@latest <command>
```

## Shell

- **All platforms** → `bash` (on Windows, the bundled git-portable bash is used automatically)

---

## Pipe Management

Pipes are markdown-based AI automations that run on schedule. Each pipe lives at `~/.screen-sentinel/pipes/<name>/pipe.md`.

### Commands

```bash
bun x screen-sentinel@latest pipe list                    # List all pipes (compact table)
bun x screen-sentinel@latest pipe enable <name>           # Enable a pipe
bun x screen-sentinel@latest pipe disable <name>          # Disable a pipe
bun x screen-sentinel@latest pipe run <name>              # Run once immediately (for testing)
bun x screen-sentinel@latest pipe logs <name>             # View execution logs
bun x screen-sentinel@latest pipe install <url-or-path>   # Install from GitHub or local path
bun x screen-sentinel@latest pipe delete <name>           # Delete a pipe
bun x screen-sentinel@latest pipe models list             # View AI model presets
```

### Creating a Pipe

Create `~/.screen-sentinel/pipes/<name>/pipe.md` with YAML frontmatter + prompt:

```markdown
---
schedule: every 30m
enabled: true
preset: ["Primary", "Fallback"]
---

Your prompt instructions here. The AI agent executes this on schedule.

## What to do

1. Query screen-sentinel search API for recent activity
2. Process results
3. Output summary / send notification
```

**Schedule syntax**: `every 30m`, `every 1h`, `every day at 9am`, `every monday at 9am`, or cron: `*/30 * * * *`, `0 9 * * *`

**Config fields**: `schedule`, `enabled` (bool), `preset` (string or array — e.g. `"Oai"` or `["Primary", "Fallback"]`), `history` (bool — include previous output as context)

Screen Sentinel prepends a context header with time range, timezone, OS, and API URL before each execution. No template variables needed.

After creating:
```bash
bun x screen-sentinel@latest pipe install ~/.screen-sentinel/pipes/my-pipe
bun x screen-sentinel@latest pipe enable my-pipe
bun x screen-sentinel@latest pipe run my-pipe   # test immediately
```

### Editing Config

Edit frontmatter in `~/.screen-sentinel/pipes/<name>/pipe.md` directly, or use the API:

```bash
curl -X POST http://localhost:3130/pipes/<name>/config \
  -H "Content-Type: application/json" \
  -d '{"config": {"schedule": "every 1h", "enabled": true}}'
```

### Rules

1. Use `pipe list` (not `--json`) — table output is compact
2. Never dump full pipe JSON — can be 15MB+
3. Check logs first when debugging: `pipe logs <name>`
4. Use `pipe run <name>` to test before waiting for schedule

---

## Connection Management

Manage integrations (Telegram, Slack, Discord, Email, Todoist, Teams) from the CLI.

### Commands

```bash
bun x screen-sentinel@latest connection list              # List all connections + status
bun x screen-sentinel@latest connection list --json       # JSON output
bun x screen-sentinel@latest connection get <id>          # Show saved credentials
bun x screen-sentinel@latest connection get <id> --json   # JSON output
bun x screen-sentinel@latest connection set <id> key=val  # Save credentials
bun x screen-sentinel@latest connection test <id>         # Test a connection
bun x screen-sentinel@latest connection remove <id>       # Remove credentials
```

### Examples

```bash
# Set up Telegram
bun x screen-sentinel@latest connection set telegram bot_token=123456:ABC-DEF chat_id=5776185278

# Set up Slack webhook
bun x screen-sentinel@latest connection set slack webhook_url=https://hooks.slack.com/services/...

# Verify it works
bun x screen-sentinel@latest connection test telegram

# Check what's connected
bun x screen-sentinel@latest connection list
```

Connection IDs: `telegram`, `slack`, `discord`, `email`, `todoist`, `teams`, `google-calendar`, `apple-intelligence`, `openclaw`

Credentials are stored locally at `~/.screen-sentinel/connections.json`.

**Per-integration details**: don't guess API shapes from this skill. Run `connection list` or `connection get <id>` — each entry includes a self-describing `description` with credential fields, endpoints, and example bodies. Only fetch the integration you need.

## Publishing pipes to the store

```bash
screen-sentinel pipe publish <pipe-name>
```

Reads `~/.screen-sentinel/pipes/<pipe-name>/pipe.md`, extracts title/description/icon/category from YAML frontmatter, and publishes to the Screen Sentinel pipe store. Requires auth (SCREEN_SENTINEL_API_KEY env var or `~/.screen-sentinel/auth.json`).
