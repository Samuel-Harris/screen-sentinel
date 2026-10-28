# 03. Database resilience

## Why

The recorder writes continuously to SQLite in WAL mode (write-ahead log:
writes go to a side file first, and a checkpoint folds them into the main
database). Upstream's public changelog describes four ways this went wrong
after June. Each one silently stops recording or corrupts the database.

## Failures to handle

### A. Checkpoint corruption under load

Upstream: "an inline WAL auto-checkpoint on the committing connection could
copy a WAL frame to the wrong main-DB page under heavy concurrent load,
clobbering the SQLite header", producing "file is not a database".

**State in 0.4.15.** This path is present. `crates/screenpipe-db/src/db.rs`
line 320 sets `wal_autocheckpoint = 4000` on the pool connections. Line 372
runs a startup `wal_checkpoint(TRUNCATE)`. Around line 8665 a background
task runs `wal_checkpoint(TRUNCATE)` every 5 minutes. So inline and
background checkpoints both run.

**Wanted.** Only one owner checkpoints: a single background maintainer.
Inline auto-checkpoint is off on every writing connection. WAL size has a
hard cap, and the maintainer escalates from passive to restart to truncate
checkpoints as the WAL nears the cap.

### B. WAL-index desync after sleep/wake

Upstream: "after macOS sleep/wake, SQLite's WAL-index could desync and leave
every write failing with code 522". Code 522 is `SQLITE_IOERR_SHORT_READ` on
the shared-memory (`-shm`) mapping.

**State in 0.4.15.** No 522-specific recovery found. A sleep/wake monitor
exists (`crates/screenpipe-engine/src/sleep_monitor.rs`) and sets a
`RECENTLY_WOKE` flag, but nothing ties it to the database.

**Wanted.** When writes fail with an I/O error on the WAL index, close every
connection to the database, so SQLite can rebuild the shared-memory mapping,
then reopen and resume, all in-process. Any other connection holding the
file, such as a secrets store, must close too.

### C. Write queue wedge

Upstream: "if disk I/O stalled long enough that the database write queue
saturated, capture could appear 'Running' ... while persisting nothing for an
hour or more".

**Wanted.** A watchdog that fires when capture is still attempting frames
but no row has been written for more than two minutes. It restarts the
capture and write pipeline, with a five-minute cooldown and a circuit breaker
that stops retrying a database that is truly malformed.

### D. Hostname change lock

Upstream mentions "macOS hostname-change DB lock wedge" as fixed in
September. It gives no public detail.

**Wanted.** Reproduce it first: change the hostname with
`sudo scutil --set HostName` while recording, then watch for writes failing
or blocking. Write this one only if the reproduction shows a problem.

## Done when

- A load test with concurrent writers and readers over several GB of data
  never produces "file is not a database", and the WAL stays under its cap.
- 20 forced sleep/wake cycles (`pmset sleepnow`, then wake) end with writes
  succeeding within one minute of each wake, with no manual restart.
- Blocking writes artificially, for example by holding an exclusive lock
  from a test harness, triggers one restart after two minutes, then
  backs off.
- The hostname-change reproduction is recorded with its result, whether or
  not a fix was needed.
