# 04. Pull request CI in ten minutes

## Why

Agents open most pull requests here, and an agent waiting on CI burns tokens
while it polls and re-runs checks. A pull request waits a median of 55 minutes
for its last check today. The repo is public, so GitHub-hosted minutes cost
nothing. The cost is the wait.

Do it after 03, because it selects work with the Nx project graph that 03
builds. Do it before 05, so every later stage merges through the fast gate.

## State on `main` at `2e253787a`

Measured on 2026-11-22:

- `.github/workflows/` holds 24 workflows. Rust tests (`ci.yml`) and E2E
  (`e2e-test.yml`) each run on Linux, Windows and macOS.
  `windows-integration-test.yml` adds a fourth Windows job.
- `style.yml` (clippy, format, dependency checks, Knip) runs on every push and
  every pull request, with no path filter.
- `release-app.yml` and `release-cli.yml` run on every push to `main` and
  build only when the commit message asks for a release. `sdk.yml`,
  `sdk-release.yml`, `release-mcp.yml`, `release-browser-extension.yml` and
  `release-enterprise.yml` are further release workflows.
- Scheduled runs: `e2e-macos.yml` on hosted macOS every 4 hours,
  `benchmark.yml` daily, `close-inactive.yml` daily and `sentry-cleanup.yml`
  weekly.
- `benchmark.yml` and `release-app.yml` target the self-hosted labels
  `macos-test` and `windows-desktop-test`. The repo has no registered
  self-hosted runners (`gh api repos/{owner}/{repo}/actions/runners` returns
  `total_count: 0`).
- No single check says whether a pull request passed.

Wait times over the 123 pull request head commits from 1 to 22 November
(`gh api .../actions/runs?event=pull_request`):

| Measure | Minutes |
| --- | --- |
| First check start to last check finish, median | 55 |
| `E2E Tests` workflow, median | 30 |
| `Rust CI` workflow, median | 29 |
| `CI` (the `nx affected` workflow on the `nx-scratch/*` branches), median of 19 runs | 50 |

By job (PR #72's baseline), `test-macos` averages 19 minutes and
`macOS E2E Tests` averages 16. Those two jobs take about 70% of all macOS
minutes.

## Behaviour wanted

1. One workflow, `.github/workflows/ci.yml`, triggered only by pull
   requests. Delete every other workflow, including every release workflow
   and every scheduled one. Nothing runs on push to `main`.
2. One job named `CI passed` needs every other job. It fails when any of
   them failed or was cancelled. It passes when the others passed or were
   skipped because the change did not affect them. A ruleset on `main`
   requires `CI passed` and no other check.
3. Every job chooses its work with `nx affected` against the pull request's
   base. A newer push to the same pull request cancels the older run.
4. macOS is the only platform the product supports, so it is the only
   platform CI tests. No job runs on Windows. Checks that do not depend on
   the platform, such as formatting, TypeScript typechecks and unit tests of
   crates that build on Linux, run on Linux, which allows more jobs at once.
5. Split tests across a matrix of runners so the slowest path from push to
   `CI passed` fits in ten minutes.
6. Use only GitHub's free standard hosted runners. No larger runners, no
   self-hosted runners and no Nx Cloud. The GitHub Actions cache may hold
   build and Nx task caches.
7. Break large crates and packages into smaller Nx projects, so that
   `nx affected` selects less work. Follow the decomposition rules of the
   `monorepo-init` skill: layered libraries, dependencies that point one
   way, and one module moved at a time while the old code keeps working.
   Keep the `apps/`, `crates/` and `packages/` layout, bun and the Nx
   targets. Do not add a justfile, CODEOWNERS or nested `AGENTS.md` files.
8. A CI job enforces the project boundaries through Nx `depConstraints`, or
   an equivalent that covers the Rust projects. It reports a forbidden
   dependency with its file and line.
9. A slow test that covers little, or covers only Windows or Linux code
   paths, may be deleted. Each pull request that deletes a test lists it
   with the reason.

## Done when

- `.github/workflows/` contains exactly `ci.yml`, and it has no `push` or
  `schedule` trigger.
- No job in `ci.yml` runs on a Windows runner.
- The ruleset on `main` requires only `CI passed`. A pull request with one
  failing job cannot merge. A pull request whose jobs were all skipped as
  unaffected can merge.
- Three probe pull requests each change one line in the database crate,
  which affects every project including the macOS E2E tests. With warm
  caches and no other pull request's CI running, each reaches a finished
  `CI passed` within ten minutes of the push.
- A pull request that changes only `feature-map/` runs no build or test job.
- A pull request that adds a dependency the boundaries forbid fails the
  boundary job with a file-and-line error.

## Decisions

| Decision | Door | Decided by | Why | Lost |
| --- | --- | --- | --- | --- |
| Cut wait time, not billed minutes | Two-way | Developer | The repo stays public, so hosted minutes are free. Agent tokens spent waiting are the real cost | Optimise PR #72's billed-minute estimate |
| One PR-only workflow with one required `CI passed` check | Two-way | Developer | A required check on pull requests already proves `main` passed, so push runs repeat work | Keep push-to-`main` CI |
| macOS is the only platform tested | Two-way | Developer | The product records one Mac (01) | Keep Linux or all three |
| Delete every release workflow | One-way | Developer | The fork does not publish releases | Keep them, or trigger them by hand |
| No scheduled CI | Two-way | Developer | Pull request CI is the only gate | A nightly full run |
| At most ten minutes from push to `CI passed` on a change that affects every project, with warm caches | Two-way | Developer | Small pull requests are then fast because `nx affected` skips their unaffected projects | Median of real pull requests, or ten minutes from a cold cache |
| Broad crate split following `monorepo-init`'s decomposition and boundary rules | One-way | Developer | Finer projects let `nx affected` skip more work | Nx projects only, or splits only where measured |
| Free standard runners only; Linux for platform-neutral checks; deleting low-value slow tests is allowed | Two-way | Developer | Speed must not cost money | Paid larger runners, keeping every test |
| GitHub Actions cache allowed, Nx Cloud not | Two-way | Spec writer | Today's workflows already use the GitHub cache. 03 rules out Nx Cloud | Remote Nx caching |
| Insert this as 04 and renumber 04 to 12 | Two-way | Developer | File numbers follow the order of work | A number after 12 |

## Questions for the planner

- GitHub's free plan limits how many macOS jobs run at once
  (unverified: 5 per account). Several agent pull requests at once can turn
  a wide macOS matrix into queue time. Size the matrix against the real
  limit.
- Clippy on Linux does not compile `#[cfg(target_os = "macos")]` code.
  Decide which lints must run on macOS.
- The closed Nx pull requests #31 to #42 and the `nx-scratch/*` branches
  hold earlier work on `nx affected` CI and module boundaries (#39). Their
  `affected-macos` job averaged 17 minutes over 29 runs. Start from their
  findings.
- E2E is the longest macOS job. Find out whether it can reuse the build from
  the test jobs or be split, before sharding it.
- Check the project `release` skill and any docs that name the deleted
  workflows, and update or delete them with the workflows.
