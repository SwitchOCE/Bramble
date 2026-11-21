# League data: build plan (proposal, for `/plan-interrogate` and the owner)

The direction is approved (README.md). This plan is how it gets built. The Ghost Build Orchestrator builds it; each step passes the two gates (tests and runtime proof, then a scope review) before it merges to `dev`.

## Goal

A 1,000-game match keeps tens of MB at most while its data is in use, and a couple of MB per build once the build is old. Balance questions are one DuckDB query each. Replays and ghosts work exactly as today.

## Steps

1. **Compress at match end, stop the reasoning log.** `league match` and `league ghost-match` zstd each game's record (`records/game-N.jsonl.zst`) and `games.jsonl`, and stop writing `reports.jsonl` and `discovers.jsonl` by default (a flag turns them back on for a team debugging its bot). The bot's value for each offered card moves into `shops.jsonl`. Every reader of these files (`bramble-ghosts cut`, `check_ghost_match.py`, `replay_match.sh`, `smoke_final_bots.sh`, `current_async_field.sh`, `tools/league/analysis/*`) reads the compressed form. **Proof:** a 200-game match before and after gives the same `summary.json` and `analysis.json`, the same cut ghost IDs, and records that replay byte-identical after decompressing; size per game is reported.
2. **Join key and format doc.** Each shop view gets an id written in both `shops.jsonl` and `decisions.jsonl`. A one-page `tools/league/league/FORMAT.md` says what every output file and field means (including `deaths` vs `killed`, `origin`, shop `reason`, ghost `player = -1`). **Proof:** a test that every shop id in decisions exists in shops.
3. **Per-mechanic counts in fights.** Fight results count each mechanic's triggers by name, not only a total. Only the Rust match writer's log changes; the rules and the GDScript proof don't. **Proof:** the full Rust proof still passes; a test fight with a known mechanic shows its count.
4. **DuckDB analysis and the findings folder.** A tool under `tools/league/analysis/duckdb/` loads a match folder into a DuckDB file (attached with `STORAGE_VERSION 'latest'`) with the tables Balance Orchestrator 2 asked for, and writes the per-build findings folder: per-card × round × tribe and per-tribe tables as CSV, at most 2 MB. A short note in the folder covers the traps the trial found (compression off by default, dialect slips, the MCP package's DuckDB pin). **Proof:** on a 200-game match, two answers checked against a plain Python count; findings folder size reported.
5. **The keep list, applied by the referee.** A `prune` script takes a match folder and its kind (climb, reading, field, old build) and leaves exactly what README.md's table keeps. The referee brief calls it after each match. **Proof:** run on a copy of a real match for each kind; list what's left and its size.

Steps 1 and 5 matter most for the third run's disk; 2–4 for analysis. Step 5 needs no engine change and can go first.

## Not in this plan

- No online store, server, or document database (SurrealDB stays a later option for the ghost server).
- No change to the replay record's content, so ghosts, replays and the rules fingerprint are untouched.
