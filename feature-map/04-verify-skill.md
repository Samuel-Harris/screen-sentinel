# 04. A verify skill that drives the recorder

## Why

The "Done when" checks in 05 to 11 drive the real recorder. They inject
faults and read `/health`, run for a day through sleep and wake, query the
API, and watch the tray and the timeline window. Without a scripted way to
launch and drive the app, each agent writes throwaway scripts, or hands the
check back to the owner. A project verification skill gives every agent one
recipe to launch, check, drive, capture evidence and clean up.

Generate it with `/create-verification-skill` from pstack, which the repo
installs through `apm.yml`. Do it after 02, so the skill uses the new names,
data directory and port. Do it after 03, so it launches the app through the
Nx targets. Do it before 05, so every later stage proves its checks with it.

## State in 0.4.15

- No `verify-*` skill exists under `.claude/skills/` or `.agents/skills/`.
  The `screenpipe-api`, `screenpipe-health` and `screenpipe-logs` skills
  query a running recorder. None of them launches or drives one.
- `packages/e2e` has a test runner with `api`, `cli` and `app` suites, and a
  Tart VM runner in `local/cli.ts`. The app suite runs WebdriverIO specs from
  `apps/screenpipe-app-tauri/e2e/`, seeded by `SCREENPIPE_E2E_SEED`.
- The engine CLI takes `--port` and `--data-dir`
  (`crates/screenpipe-engine/src/cli/mod.rs` lines 329 and 348).
- The owner records on the same Mac, all day. A careless check that binds the
  default port or opens `~/.screen-sentinel` corrupts the record it should
  protect.

## Behaviour wanted

1. A committed skill at `.claude/skills/verify-screen-sentinel/`, with the
   Launch, Doctor, Drive, Evidence, Cleanup and Helpers sections that
   `/create-verification-skill` writes.
2. Launch starts an isolated instance with its own port and data directory,
   through the Nx targets from 03. It is ready when `/health` reports capture
   running, not when the port answers.
3. Doctor refuses to drive an instance on the owner's port or data
   directory.
4. The skill states how the isolated instance gets its Screen Recording and
   Accessibility grants. macOS ties each grant to a signed binary, so use the
   signing setup from 11, or name the one-time grant step.
5. Drive reuses `packages/e2e` and the WebdriverIO specs where they already
   cover a feature, instead of a second harness.
6. A feature map under `features/` with one file per feature that survives 01
   and 11: capture status in `/health`, search over screen text, frames and
   elements, raw SQL, the MCP server, the CLI, and the app's tray, timeline,
   settings and onboarding. Each file names the observable end state that
   proves the feature works.
7. Evidence (the `/health` JSON, database row counts, screenshots and logs)
   goes to one named directory that cleanup keeps.

## Done when

- The generator's proof ran once end to end: launch, doctor, drive one
  feature, capture evidence, clean up. The evidence still exists after the
  cleanup.
- With the owner's recorder running, a pass over every feature-map entry
  leaves it alone. `lsof` shows no handle from the verify instance on
  `~/.screen-sentinel`, and the owner's `/health` shows no restart and no
  capture gap during the pass.
- After cleanup, no process, port or data directory that the pass created
  remains.
- Launch calls Nx targets only. It runs no `cargo` or `bun` command directly.
- A fresh agent given only "use /verify-screen-sentinel to check that search
  returns captured text" returns that evidence with no other setup.
- `/maintain-verification-skill` on `main` returns `clean`.
