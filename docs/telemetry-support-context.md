# Telemetry Support Context

Customers who embed the Screen Sentinel CLI can attach a stable, non-PII support
identity to Screen Sentinel's existing telemetry pipeline. This lets Screen Sentinel support
filter Sentry errors and PostHog events by customer, deployment, or host app.

```bash
export SCREEN_SENTINEL_SUPPORT_ID="spcust_acme_123"
export SCREEN_SENTINEL_CUSTOMER_ID="acme"
export SCREEN_SENTINEL_DEPLOYMENT_ID="prod-laptop-fleet-01"
export SCREEN_SENTINEL_EMBEDDER="acme-agent"
export SCREEN_SENTINEL_EMBEDDER_VERSION="2026.6.4"

npx screen-sentinel record
```

## Environment Variables

| Variable | Purpose |
| --- | --- |
| `SCREEN_SENTINEL_SUPPORT_ID` | Stable support ID for this customer/user/deployment. Used as the CLI PostHog `distinct_id` when `SCREEN_SENTINEL_ANALYTICS_ID` is not set, and attached to Sentry/PostHog as `screen_sentinel_support_id`. |
| `SCREEN_SENTINEL_CUSTOMER_ID` | Customer or organization key, attached as `screen_sentinel_customer_id`. |
| `SCREEN_SENTINEL_DEPLOYMENT_ID` | Fleet, endpoint group, device, or environment key, attached as `screen_sentinel_deployment_id`. |
| `SCREEN_SENTINEL_EMBEDDER` | Name of the app embedding or launching Screen Sentinel, attached as `screen_sentinel_embedder`. |
| `SCREEN_SENTINEL_EMBEDDER_VERSION` | Version of the embedding app, attached as `screen_sentinel_embedder_version`. |

Aliases are also accepted for easier integration with existing deployments:

| Canonical variable | Accepted aliases |
| --- | --- |
| `SCREEN_SENTINEL_SUPPORT_ID` | `SCREEN_SENTINEL_TELEMETRY_ID` |
| `SCREEN_SENTINEL_CUSTOMER_ID` | `SCREEN_SENTINEL_ORG_ID`, `SCREEN_SENTINEL_TELEMETRY_CUSTOMER_ID` |
| `SCREEN_SENTINEL_DEPLOYMENT_ID` | `SCREEN_SENTINEL_TELEMETRY_DEPLOYMENT_ID` |
| `SCREEN_SENTINEL_EMBEDDER` | `SCREEN_SENTINEL_HOST_APP`, `SCREEN_SENTINEL_TELEMETRY_HOST_APP` |
| `SCREEN_SENTINEL_EMBEDDER_VERSION` | `SCREEN_SENTINEL_HOST_VERSION`, `SCREEN_SENTINEL_TELEMETRY_HOST_VERSION` |

`SCREEN_SENTINEL_ANALYTICS_ID` remains the highest-priority explicit PostHog
`distinct_id`. Use it only when you intentionally want to control the exact
person identity. Otherwise prefer `SCREEN_SENTINEL_SUPPORT_ID`.

## Privacy Boundary

These variables should contain opaque IDs, not emails or names. Screen Sentinel
telemetry still follows the normal telemetry settings: `--disable-telemetry`
turns it off, and telemetry does not include screen content, audio, transcripts,
or file contents.

The JavaScript/Swift SDK does not send first-party Screen Sentinel telemetry on its
own. If an SDK host wants Screen Sentinel support correlation, it should set the same
environment variables when launching the Screen Sentinel CLI/engine, and may also add
the same fields to the host application's own Sentry/PostHog reports.
