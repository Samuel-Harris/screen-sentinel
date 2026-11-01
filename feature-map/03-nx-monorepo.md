# 03. One Nx task graph over the whole repo

## Why

Every later stage ends in checks that build and test Rust and TypeScript
together. Today no single command does that. An agent has to know which
crate, package and lockfile a change touches, and CI repeats that knowledge
in many separate workflows. Nx gives one command to build, test and lint the
tree, and runs only what a change affects.

Do it after 01 and 02, so it lands on the smaller, renamed tree. Do it before
04, so the verify skill launches the app through the same targets that CI
runs.

## State in 0.4.15

Measured at the base commit:

- The root `Cargo.toml` is a workspace over `crates/*`. It excludes
  `apps/screenpipe-app-tauri/src-tauri`, which has its own `Cargo.lock`. The
  app depends on the engine crates by path, so two lockfiles can resolve the
  same dependency to different versions.
- There is no root `package.json`. Six JS packages stand alone:
  `apps/screenpipe-app-tauri` and five under `packages/`. Four have their own
  `bun.lock`, and `packages/cli` and `packages/e2e` have none.
- `.github/workflows/` holds 24 workflows. Each one installs and runs its own
  commands.
- `lefthook.yml` runs `cargo fmt` and `cargo clippy`, with a shell script
  that works out which crates a commit touched.
- No build system sits over both languages. Nothing caches task results.

## Behaviour wanted

1. Nx at the repo root. Every Rust crate and JS package that 01 keeps is an
   Nx project, with the `build`, `test` and `lint` targets that apply to it.
2. The project graph includes the edges between Rust and TypeScript. A change
   to an engine crate marks the app as affected.
3. One Cargo workspace that includes the app's `src-tauri` crate, with one
   `Cargo.lock`. Merging the lockfiles must not move any pinned
   `github.com/screenpipe/*` revision (see the README). If a version conflict
   makes one workspace impossible, record the conflict in this file and keep
   two lockfiles.
4. One root `package.json` with bun workspaces over every JS package, and one
   root `bun.lock`.
5. CI and the pre-commit hook call Nx. Pull requests run
   `nx affected -t build test lint` against `main`. Release workflows keep
   working.
6. Keep the `apps/`, `crates/` and `packages/` layout. Moving directories
   breaks every path that later stages cite, for no gain.
7. `CLAUDE.md` and `AGENTS.md` name the Nx commands as the way to build and
   test.

Leave out Nx Cloud and remote caching. They send task data off the machine,
and 11 wants no outbound connections.

## Done when

- On a fresh clone with the Rust toolchain installed, `bun install` and then
  `bunx nx run-many -t build test lint` pass, with no other setup.
- `git ls-files | grep -E '(^|/)(Cargo|bun)\.lock$'` prints exactly
  `Cargo.lock` and `bun.lock`, unless this file records a conflict under
  item 3.
- After a change to one file in the database crate, `nx show projects
  --affected` lists that crate, the engine and the app. After a change to
  only the MCP package, it lists only that package.
- A pull request that changes only `feature-map/` runs no build or test
  target in CI.
- The revisions of every `github.com/screenpipe/*` dependency in
  `Cargo.lock` match the base commit.
- With the network off, a second `nx run-many -t build` takes its results
  from the local cache.
