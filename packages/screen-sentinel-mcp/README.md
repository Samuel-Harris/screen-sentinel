# Screen Sentinel MCP Server

<a href="https://www.pulsemcp.com/servers/screen-sentinel-screen-sentinel"><img src="https://www.pulsemcp.com/badge/top-pick/screen-sentinel-screen-sentinel" width="400" alt="PulseMCP Badge"></a>

<br/>

https://github.com/user-attachments/assets/7466a689-7703-4f0b-b3e1-b1cb9ed70cff

MCP server for Screen Sentinel - search your screen recordings and control your computer with AI.

## Installation

### Option 1: NPX (Recommended)

The easiest way to use screen-sentinel-mcp is with npx. Edit your Claude Desktop config:

- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%AppData%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "screen-sentinel": {
      "command": "npx",
      "args": ["-y", "screen-sentinel-mcp"]
    }
  }
}
```

### Option 2: HTTP Server (Remote / Network Access)

The MCP server can run over HTTP using the [Streamable HTTP transport](https://modelcontextprotocol.io/specification/2025-03-26/basic/transports#streamable-http), allowing remote MCP clients to connect over the network instead of stdio. This is ideal when your AI assistant (e.g., OpenClaw) runs on a different machine than Screen Sentinel.

```bash
# loopback only (default)
npx -y screen-sentinel-mcp --http --port 3131

# expose to your LAN with bearer auth
npx -y screen-sentinel-mcp --http --listen-on-lan --api-key $(openssl rand -hex 16)

# or from source — must build first so dist/ exists
bun install && bun run build
bun run start:http -- --port 3131
```

> Tip: `npx screen-sentinel-mcp-http` (without `--http`) does **not** work —
> npm resolves by package name, and there is no `screen-sentinel-mcp-http`
> package. The HTTP server ships as a transport inside the
> `screen-sentinel-mcp` package; use `--http` as shown above, or invoke the
> bin directly with `npx -p screen-sentinel-mcp screen-sentinel-mcp-http`.

The server exposes:
- **MCP endpoint**: `http://localhost:3131/mcp` — Streamable HTTP transport (POST for requests, GET for SSE stream)
- **Health check**: `http://localhost:3131/health` — always unauthenticated, for monitors

**Options:**
| Flag | Description | Default |
|------|-------------|---------|
| `--port` | Port for the MCP HTTP server | `3131` |
| `--screen-sentinel-port` | Port where Screen Sentinel API is running | `3130` |
| `--listen-on-lan` | Bind `0.0.0.0` so other devices on the LAN can connect. Requires `--api-key`. | off (binds `127.0.0.1`) |
| `--api-key <secret>` | Bearer token required for non-loopback requests (`Authorization: Bearer <secret>`). Loopback always allowed. | none |

**Connecting a remote MCP client:**

Point any MCP client that supports HTTP transport at the `/mcp` endpoint:

```json
{
  "mcpServers": {
    "screen-sentinel": {
      "url": "http://<your-ip>:3131/mcp",
      "headers": {
        "Authorization": "Bearer <your-secret>"
      }
    }
  }
}
```

If your machines are on different networks, expose port 3131 via Tailscale, SSH tunnel, or similar — see the [OpenClaw integration guide](https://docs.screenpi.pe/openclaw) for detailed examples.

> **Note:** The HTTP server currently exposes `search_content` only. The stdio server has the full tool set (export-video, activity-summary, search-elements, frame-context). We're working on bringing HTTP to full parity.

### Option 3: From Source

Clone and build from source:

```bash
git clone https://github.com/Samuel-Harris/screen-sentinel
cd screen-sentinel/packages/screen-sentinel-mcp
bun install
bun run build
```

Then configure Claude Desktop:

```json
{
  "mcpServers": {
    "screen-sentinel": {
      "command": "node",
      "args": ["/absolute/path/to/screen-sentinel-mcp/dist/index.js"]
    }
  }
}
```

**Note:** Restart Claude Desktop after making changes.

## Testing

Test with MCP Inspector:

```bash
npx @modelcontextprotocol/inspector npx screen-sentinel-mcp
```

## Transport Modes

| Mode | Command | Use Case |
|------|---------|----------|
| **stdio** (default) | `npx screen-sentinel-mcp` | Claude Desktop, local MCP clients |
| **HTTP** | `npx screen-sentinel-mcp --http` | Remote clients, network access, OpenClaw on VPS |

## Available Tools

### search-content
Search through recorded content with content type filtering:
- `all` — OCR + Accessibility (default)
- `ocr` — Screen text from screenshots
- `input` — User actions (clicks, keystrokes, clipboard, app switches)
- `accessibility` — Accessibility tree text
- Time range and app/window filtering
- Pagination support

### export-video
Export screen recordings as video files:
- Specify time range with start/end times
- Renders a real-time MP4 and returns the file path

### activity-summary
Get a lightweight compressed activity overview for a time range:
- App usage with active minutes and frame counts
- Recent accessibility texts

### search-elements
Search structured UI elements (accessibility tree nodes and OCR text blocks):
- Filter by source, role, app, time range
- Much lighter than search-content for targeted UI lookups

### frame-context
Get accessibility text, parsed tree nodes, and extracted URLs for a specific frame.

## Example Queries in Claude

- "Search for any mentions of 'rust' in my screen recordings"
- "Show me what was on my screen in VSCode yesterday"
- "Export a video of my screen from 2-3pm today"
- "What did I type in Slack today?" (uses content_type=input)
- "What did I copy to clipboard recently?" (uses content_type=input)
- "Show me accessibility text from Chrome" (uses content_type=accessibility)

## Requirements

- Screen Sentinel must be running on localhost:3130
- Node.js >= 18.0.0

## Notes

- All timestamps are handled in UTC
- Results are formatted for readability in Claude's interface
- macOS automation features require accessibility permissions

## Privacy Policy

The Screen Sentinel MCP server is a local-only bridge between Claude and your
local Screen Sentinel instance. It does not collect, transmit, or store any
data on its own.

### What this MCP server does
When Claude invokes a tool (`search-content`, `activity-summary`, etc.)
the MCP server forwards the request to `http://localhost:3130` — the
Screen Sentinel daemon running on your machine — and returns the response.
That's the entire data path.

### Data collection
**None by this MCP server.** No analytics, no telemetry, no usage tracking.

### Data usage
Tool calls are passed straight through to your local Screen Sentinel daemon
and the results stream back to Claude. The MCP server doesn't keep
anything.

### Data storage
Nothing is stored by the MCP server itself. Recordings, OCR text,
and UI events are stored by the Screen Sentinel app in a
SQLite database under `~/.screen-sentinel/` on your device. Retention is
whatever you configure inside the Screen Sentinel app — typically you
control it via the storage settings panel.

### Third-party sharing
None. The MCP server only talks to `localhost:3130`. It does not
contact Anthropic, Screen Sentinel's servers, or any other external service.

### Retention
The MCP server has no persistent state. The data your Screen Sentinel app
captures is retained according to your Screen Sentinel storage configuration
and is deletable at any time (`rm -rf ~/.screen-sentinel` removes everything).

### Source code
The Screen Sentinel MCP server is MIT-licensed and the entire source is
public at <https://github.com/Samuel-Harris/screen-sentinel/tree/main/packages/screen-sentinel-mcp>.
Every line is auditable.

### Contact
Questions or concerns: open an issue at
<https://github.com/Samuel-Harris/screen-sentinel/issues> or reach out via
<https://screenpi.pe>.
