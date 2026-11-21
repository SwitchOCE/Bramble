# SurrealDB trial: report

SurrealDB 4.0.1, one local server per store (`surreal start surrealkv://…`), Python SDK 3.0.0, 2 cores (`taskset -c 4,5`, `SURREAL_RUNTIME_WORKER_THREADS=2`). KB = 1,000 bytes.

## 1. Result in three lines

- It works: all 200 replay records come back byte-for-byte (sha256 200/200), all six questions are answered with SurrealQL, and three were checked against plain Python with no differences. Its built-in MCP server worked first time for a headless Haiku agent.
- It does not compress anything: SurrealKV has no compression setting, so records cost 392.6 KB per game inside it (the same as raw). You get 15.6 KB per game only by zstd-compressing each record yourself before you insert it. The analysis layer costs 1,593 KB per game, about 4 times the raw records it was built from.
- Verdict for Bramble: it is usable for analytics on a few thousand games, but it's the wrong tool for storage. At 100,000 games the analysis layer would be roughly 159 GB and take about a day to load. Keeping the records as zstd files (or zstd bytes inside it) and pre-aggregating the shop data are what would fix that, not SurrealDB settings.

## 2. Setup

| Step | Wall time (from LOG.md) | Failed attempts |
|---|---|---|
| Inspect sample | 13:00:43 → 13:01:08 (0.5 min) | 0 |
| Download release binary, verify checksum | 13:01:09 → 13:01:54 (0.75 min) | 1 (the `.txt` checksum URL returned 404; I used the GitHub API asset digest instead) |
| Find docs and agent files | 13:01:54 → 13:03:46 (2 min) | 0 |
| Python venv + SDK | 13:03:46 → 13:04:16 (0.5 min) | 0 |
| First working load (archive) | 13:04:16 → 13:05:00 (0.75 min) | 1 (SDK 3.0's `db.query()` is lazy and sent nothing, silently apart from a RuntimeWarning) |
| Archive both ways + verify | 13:05:00 → 13:06:41 (1.7 min) | 1 (mine: `pkill -f` matched my own shell) |
| Analysis layer load | 13:09:24 → 13:12:35 (3.2 min; the load itself took 171 s) | 0 |
| Write the six queries | 13:10 → 13:13 (about 3 min, alongside the load) | 3 (bool→float cast refused; integer division; `math::percentile` isn't a GROUP BY aggregate) |
| MCP + headless runs | 13:09:47 → 13:13:46 (about 2 min) | 0 |

Total: about 15 minutes from start to all queries answered and checked. There were 8 failed attempts: 5 from the tool or its docs (checksum URL, lazy SDK, cast, integer division, percentile) and 3 of my own (`pkill`, misreading a half-flushed load, wrong result index in my compare script).

Docs and agent files used:
- `https://surrealdb.com/llms.txt` and `https://surrealdb.com/docs/llms.txt`. **Helpful.** The index states the current version (4.0.1) and lists the 3.x→4.0 breaking changes up front (RocksDB removed, no ordering without `ORDER BY`). Every page is also served as markdown by appending `.md`. That is the best agent support of anything I used.
- `docs/llms-full.txt` (9.5 MB), which I searched with grep for compression settings. There are none for SurrealKV.
- Pages: Embedded MCP, `mcp` CLI, `start` CLI, environment variables, `clauses/group.md` (this is where I found the 4.0 GROUP BY rule I needed), math functions.
- The official agent skills, `github.com/surrealdb/agent-skills` (cloned into `docs/`). **Partly helpful, partly out of date.** The `surrealql` skill's GROUP BY examples are fine. The `surrealdb-python` skill still says `rocksdb:database`, which 4.0 removed, and doesn't show that SDK 3.0's `query()` needs `.execute()`.
- A doc mismatch: the docs write `surreal db mcp` / `surreal db start`, but the 4.0.1 binary's commands are `surreal mcp` / `surreal start`.

## 3. MCP server

- **Which:** the MCP server built into the `surreal` binary (since 3.1), reached over HTTP at `http://127.0.0.1:18603/mcp` on the running server. Config: `mcp/mcp-config.json`, with Basic auth and `surreal-ns`/`surreal-db` headers. Nothing extra to install.
- **Why:** it is official and comes in the same binary. The other two options didn't fit. The hosted `mcp.surrealdb.com` is for SurrealDB Cloud and needs a sign-in. The stdio form (`surreal mcp <path>`) opens its own embedded store and can't share a store that a server already holds. The older separate `surrealdb/surrealmcp` repo is superseded per the docs.
- **Headless run:** `claude -p … --mcp-config mcp/mcp-config.json --strict-mcp-config --model claude-haiku-5-5 --allowedTools mcp__surrealdb`. It worked.
  - Run 1 (`mcp/headless_run.json`): the prompt named the table. It took 3 turns, 6.0 s and $0.006. Its answer was "gleaner 1,497 rows avg place 4.23, blackthorn-sapling 1,162 @ 4.88, orchard-stripper 1,116 @ 3.36", shown with the SurrealQL it ran. That matches Python exactly.
  - Run 2 (`mcp/headless_run2.json`): no schema hints. It took 6 turns and 8.4 s, found the `seat` table by itself (the table COMMENTs help), and answered "Badger best at 2.0 but only 2 players; Briar 3.75 over 92". That matches Q3.

## 4. Sizes

Per-file compression, summed over the 200 records (each game stays separately retrievable).

| Form | Total for 200 games | KB per game | MB per 1,000 games | Compress / decompress, all 200 |
|---|---|---|---|---|
| Raw | 78.47 MB | 392.3 | 392.3 | n/a |
| gzip -6 | 4.53 MB | 22.7 | 22.7 | 2.8 s / 0.36 s |
| zstd -3 | 4.62 MB | 23.1 | 23.1 | 3.0 s / 0.76 s |
| zstd -19 | 3.06 MB | 15.3 | 15.3 | 92 s / 0.86 s |
| xz -6 | 3.22 MB | 16.1 | 16.1 | 17 s / 1.1 s |
| In SurrealDB, default (record as a string field) | 78.52 MB | 392.6 | 392.6 | load 5.2 s |
| In SurrealDB, "best" (app-side zstd -19, stored as `bytes`) | 3.11 MB | 15.6 | 15.6 | load 71 s (all compression) |
| Analysis layer, all 10 tables incl. board snapshots | 318.6 MB | 1,592.9 | 1,592.9 | load 171 s |
| Analysis layer without board snapshots | 282.4 MB | 1,412.2 | 1,412.2 | load 111 s |

Notes:
- SurrealKV has **no compression setting**. RocksDB had one, but 4.0 removed RocksDB. Records over 4 KB go to SurrealKV's value log, stored as-is. The analysis store's single SST file shrinks from 318.6 MB to 94.9 MB with `zstd -3`, which shows it is stored uncompressed too.
- Disk while the server runs is larger, before the flush at a clean shutdown: raw archive 112 MB, zstd archive 36.7 MB, analysis 437 MB.
- Time per run includes starting a process 200 times (one per file). Fetching one game back took 4.3 ms (raw store) or 3.6 ms (zstd store, including decompression), median of 3, identical bytes both times.

## 5. Queries

All in `queries.surql`, run through the Python SDK, median of 3 (`results/query_timing.json`, results in `results/query_results.json`).

| Q | Answered | Median ms | Checked vs Python |
|---|---|---|---|
| 1 Shops: buy rate when offered, by round, by buyer's tribe; sold; bot value | yes | 2,491 | yes: offered/bought for all 104 unit cards, and sentry by round. All equal |
| 2 Final boards: share of boards, avg place with vs without, golden rate | yes | 71 | yes: all 86 cards, all four numbers equal |
| 3 Tribes: avg place, share of final boards, place by round reached | yes | 119 | indirectly (headless agent run 2 matched it) |
| 4 Rounds: median, IQR, sd of board attack/health; tribe counters | yes | 194 | no |
| 5 Fights: deaths per fight, kills by source, mechanic uses | partly | 180 | yes: 10,461 fights, mean deaths 15.9268, top-5 killers equal |
| 6 50 full boards at round 8 | yes | 27 | no |

How hard each was to write:
- **Q1:** Medium. Buy-when-offered needs shop views joined to their buys. I did that in the loader (`offer.bought`). Bot values come from `reports.jsonl`, which lines up with the shop views row by row, and sells from `decisions.jsonl`. "Buyer's tribe" is the most common tribe on their board that round. The `$sold[WHERE card = $parent.card]` lookup is what makes it slow.
- **Q2:** Medium. "Without" needs total minus with, and `int / int` is integer division, so it needs `<float>` casts. Casting a bool to float is refused, so golden counts use `count(golden)`.
- **Q3:** Easy. The unit-tribe share uses a record lookup, `type::record('card', card).tribes`.
- **Q4:** Medium. `math::percentile` isn't an aggregate. You collect the values into an array in GROUP BY (a 4.0 rule) and compute the percentile in an outer SELECT. Recorded counters are `locust_tide`, `locust_hopper_bonus` and heap `thorn_compost`. Badger, Mouse and Pigeon record no counters.
- **Q5:** Easy. The sample records kills per unit, with source for summoned units, and summons, renown events, triggers, attacks and ghost fights. Why only partly: it has no per-keyword or per-ability use counts inside fights (only totals), and no cause of each death.
- **Q6:** Easy. The boards are the full engine state from each record's `fight_boards` op; player `-1` is a ghost.

## 6. Scale guess for 100,000 games (500 × the sample)

Method: everything measured here scales linearly with games. The rows per game are fixed: about 4,850 analysis rows per game, 3,613 of them shop offers. Scans are full scans with no useful index for these GROUP BYs, so query time is roughly proportional to rows. These are extrapolations, not measured at scale.

- **Archive:** about 1.6 GB with zstd -19 per record, or about 2.3 GB at zstd -3, either inside SurrealDB as bytes or as plain files. Uncompressed in SurrealDB it would be 39 GB. zstd -19 costs about 0.46 CPU-s per game, about 13 CPU-hours for 100k games. zstd -3 costs about 0.015 s per game.
- **Analysis layer:** about 159 GB with board snapshots, or about 141 GB without. It would be 485 M rows. Loading at the measured ~5,700 rows/s is about 24 hours.
- **Queries:** Q1 about 21 min, Q4 about 1.6 min, Q5 about 1.5 min, Q3 about 1 min, Q2 about 35 s. Q6 stays at milliseconds (indexed by round, LIMIT 50). Q4 collects every board's stats per round into one in-memory array (about 10 M values per round), which might run out of memory or spill. That is untested.
- To be usable at that size, you would pre-aggregate per game, e.g. offer counts per card × round × tribe instead of one row per offer. Shop-offer rows are 75% of the rows and most of the bytes. Dropping board snapshots saves only 11% (318.6 → 282.4 MB), but they can be cut from the archive on demand anyway.

## 7. Pros and cons for this project

Pros:
- It was the quickest database I could get running: one static binary, no install, no sudo, and the server was up in seconds.
- The MCP server is in the binary, and Haiku used it correctly with no setup beyond a URL and a header. Table `COMMENT`s show up in the agent's schema view, which let it find the right table unaided.
- JSON goes in as it is, so the full nested engine board state (Q6) stores and comes back as one document with no schema work. One query language covers both the documents and the GROUP BY stats.
- Byte-for-byte storage of a record is trivial (string or bytes field).
- The docs are agent-friendly: llms.txt, `.md` on every page, and version notes.

Cons:
- **No compression in storage.** The analysis layer is about 4× the raw records, and the raw archive inside it is the same size as the files. This goes directly against the owner's "without storing far too much information".
- Analytics speed is modest: 2.5 s for Q1 over 722 K rows on 2 cores. Inserts ran at about 5,700 rows/s.
- SurrealQL differs from SQL in ways that cost retries: integer division, no bool→number cast, percentile isn't an aggregate, no ordering without `ORDER BY`, and GROUP BY collects non-aggregated fields into arrays.
- Python SDK 3.0 changed the API (lazy builders), and the official skill hasn't caught up. 4.0 also removed RocksDB, so older answers and blog posts mislead.
- A store can only be opened by one process. The stdio MCP and a server can't share it.

## 8. What an agent would struggle with next time, and what would fix it

- **SDK 3.0's lazy `query()`.** Nothing runs without `.execute()`. Fix: one line in a project helper or skill: "`db.query(sql, vars).execute()` returns one result per statement, including `None` for `LET`".
- **SurrealQL arithmetic and aggregates.** Fix: a short cheat-sheet: use `<float>` before dividing; use `count(bool_field)` for true-counts; for median or percentiles in groups, collect in an inner GROUP BY and compute in an outer SELECT; always use `ORDER BY`.
- **Thinking the database will compress.** It won't. Fix: a doc line saying to compress records (zstd) before inserting, and not to keep big blobs or board snapshots in analysis tables.
- **Docs vs binary command names** (`surreal db mcp` vs `surreal mcp`). Fix: check `surreal --help` first.
- **Stopping the server.** Kill by pid, never by `pkill -f <path>`. Fix: `scripts/start_server.sh` / `stop_server.sh`, which write and use a pid file.
- **A helper script to reuse:** `scripts/load_analysis.py` (sample → 10 tables), `queries.surql` (the six questions), and `scripts/run_queries.py` (median timing).

## 9. Disk report

Everything is in `/data/dbtest/surrealdb/`. Nothing was written outside it, except Claude Code's own session files from the two headless `claude -p` runs, which the harness writes under `~/.claude/projects/`.

| Path | Size | Can go? |
|---|---|---|
| `bin/surreal` | 288 MB | yes, once the trial is over |
| `dl/` (release tgz) | 85 MB | yes, now |
| `venv/` (SDK, zstandard) | 63 MB | yes, once the trial is over |
| `db/archive_raw` | 78.5 MB | yes |
| `db/archive_zstd` | 3.1 MB | yes |
| `db/analysis` | 318.6 MB | yes |
| `db/analysis_noboards` | 282.4 MB | yes |
| `docs/` (llms-full.txt, agent-skills clone, fetched pages) | 11 MB | yes |
| `tmp/` | empty | yes |
| `results/` (query results, Python check, 2 fetched games) | 1.2 MB | keep until the debrief is written |
| `scripts/`, `queries.surql`, `mcp/`, `logs/`, `compress_bench.txt`, `LOG.md`, `REPORT.md` | < 1 MB | keep until the debrief is written |

Total 1.1 GB. No server is left running.
