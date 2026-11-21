# DuckDB trial: report

DuckDB 1.5.6 (Python package, in `venv/`), MotherDuck MCP server 1.1.1. Machine shared with two other agents, so timings carry noise (one query varied 1.2 s to 2.9 s between runs). Every query ran with 2 threads.

## 1. Result in three lines

- DuckDB works for both layers. All 200 replay records come back byte-for-byte (200/200 sha256 match), and all six questions are answered: four fully, two partly. The three answers I recounted in plain Python match exactly.
- Size: DuckDB's default settings don't compress the records at all (396 KB/game, the same as raw). With `STORAGE_VERSION 'latest'` they take 25 KB/game, close to gzip (23) but behind zstd -19 (15). The analysis layer adds about 53–63 KB/game.
- Setup took about 16 minutes in all, with roughly a dozen small failures, mostly SQL dialect slips and one silent wrong result. Two traps are worth writing down: the MCP server package downgrades DuckDB without saying so, and fetching one game from the smallest archive layout gets slower as the archive grows.

## 2. Setup

| Step | Wall time (log) | Failed attempts | Notes |
|---|---|---|---|
| Install DuckDB (uv venv in folder, cache in folder) | 13:01:20–13:01:33, 13 s | 0 | Installed 2.0.1 |
| Docs and MCP search | ~20 s | 0 | `duckdb.org/llms.txt` exists (3.4 KB of links and loading tips, a little useful); `llms-full.txt` gives 404; I found no DuckDB agent skill or docs MCP. One web search found the MCP server. |
| Install MCP server | 13:01:49–13:02:32, 43 s | 0, but a trap | `mcp-server-motherduck` silently downgraded DuckDB from 2.0.1 to 1.5.6 (it pins the version). I kept 1.5.6 for everything so the server can open the same file. |
| Load analysis layer (`scripts/load_analysis.py`) | 13:03:59–13:06:02, then a rebuild by 13:08:38 | 5 runs. Errors: `json_typeof` and `json_strip_nulls` don't exist (Postgres/SQLite names); implicit aliases `name`, `value`, `type`, `snapshot` rejected (need `AS`) | Load time 28–38 s. DuckDB guessed the nested JSON types well. |
| Load archive (`scripts/load_archive.py`) | 13:06:22–13:07:10, ~50 s | 1 (`json_extract` throws on the empty trailing line) | Found that the default storage stores the records uncompressed |
| Queries (`queries/*.sql`, `scripts/run_queries.py`) | 13:09:19–13:12:16, ~3 min | 0 errors, 1 silent bug: `bot_values.card` came out all NULL (`json->>0` on a JSON string). I caught it reading the results and rebuilt. | |
| MCP and headless run | 13:12:16–13:13:21, ~1 min | 0 | |
| Scale test | 13:13:21–13:16:04, ~3 min | 1 dead end (`ROW_GROUP_SIZE` can't go below 2048) | |

Docs that helped most: `duckdb_settings()` inside DuckDB itself. It showed `storage_compatibility_version = v0.10.2` and `zstd_min_string_length = 4096`, which explained why nothing was being compressed.

## 3. MCP server

- **Which:** `mcp-server-motherduck` 1.1.1 (PyPI; GitHub `motherduckdb/mcp-server-motherduck`). MotherDuck is the company behind DuckDB's cloud offering, and its server is marked official in the MCP Registry. DuckDB itself publishes no MCP server. The `duckdb_mcp` community extension does something else (it makes DuckDB an MCP client). The other servers I found are community-maintained.
- **Config:** `/data/dbtest/duckdb/mcp.json`. It opens `bramble.duckdb`, read-only by default, with `--home-dir` inside my folder, `--init-sql "SET threads=2"`, and max 200 rows.
- **Headless run:** `claude -p … --mcp-config mcp.json --strict-mcp-config --model claude-haiku-5-5` succeeded: 9 turns, 15.5 s, $0.0077. Output is in `mcp_run.jsonl`.
- **What the agent did:** it called `list_tables` and `list_columns` on three tables, then queried. Its first two `execute_query` calls failed because it passed `query` where the server expects `sql`; it corrected itself. It answered "regimental-sergeant-major, average place 1.82 over 111 final boards", which matches my Q2.
- **Side effects:** the server's FastMCP layer makes an HTTP request to pypi.org at startup (an update check) and prints a large banner to stderr.

## 4. Sizes

The 200 replay records. KB per game equals MB per 1,000 games (KB = 1,000 bytes).

| Form | Bytes (200 games) | KB/game = MB per 1,000 games | Time to compress / decompress all 200 |
|---|---|---|---|
| Raw | 78,465,749 | 392.3 | – |
| gzip -6 | 4,532,917 | 22.7 | 3.2 s / 1.3 s |
| zstd -3 | 4,620,579 | 23.1 | 4.1 s / 3.0 s |
| zstd -19 | 3,064,961 | 15.3 | 99 s / 1.4 s |
| xz -6 | 3,217,012 | 16.1 | 50 s / 1.2 s |
| DuckDB default, one row per game | 79,179,776 | 395.9 (not compressed) | load 1.7 s |
| DuckDB default, one row per line | 88,092,672 | 440.5 (not compressed) | load 3.3 s |
| DuckDB best, one row per game (`STORAGE_VERSION 'latest'`, zstd automatic) | 4,993,024 | 25.0 | load 1.9 s / read all 200 0.55 s |
| DuckDB, one row per line, zstd on the line column (`USING COMPRESSION zstd`) | 10,235,904 | 51.2 | load 2.3 s / read all 200 0.75 s |
| Analysis layer, default storage | 13,120,000 | 65.6 | load ~34 s from the sample's JSON |
| Analysis layer, `latest` storage | 12,600,000 | 63.0 | ~38 s |
| Analysis layer at 10× (2,000 games, `latest`) | 104,900,000 | 52.5 | – |

File compression was measured one file per game, single-threaded. The analysis layer started at 93 MB because it held full board snapshots as JSON (56 MB, uncompressed). I removed them: Q6 reads them from the archive instead.

## 5. Queries

Times are the median of 3 runs on 200 games, with 2 threads. The 10× column ran on a 2,000-game copy made by repeating the sample with shifted game numbers.

| Q | Answered | Median ms | At 10× | Checked against Python |
|---|---|---|---|---|
| 1 Shop: buy rate by card × round × tribe; sells; bot value | Yes | 101 (1a) + 58 (1b) | 632 + 602 | Yes (1b: offered, bought and sold for 104 cards, 0 mismatches) |
| 2 Final boards: share, place with/without, golden | Yes | 16 | 54 | Yes (86 cards, 0 mismatches) |
| 3 Tribes: average place, share, place by round reached | Yes | 14 | 23 | No |
| 4 Rounds: attack/health median and spread; tribe counters | Yes | 19 | 78 | No |
| 5 Fights: kills by source, deaths per fight, mechanic uses | Partly | 37 | 119 | Yes (deaths per fight: 10,461 fights, mean 15.93 in both) |
| 6 50 full boards at round 8 | Yes | 175 (per-line archive) / 1,214–2,887 (one row per game) | 693 / 9,256 | No |
| Fetch one game's record | Yes | 3 (per-line) / 58–117 (one row per game) | 18 / 1,133 | Byte-equal to the file |

Partly answered:
- **Q1:** "Offered" counts each time a card shows in a shop view (a turn start, a refresh, or a change after a buy). The bot's value is its shop-report value, so it is recorded only where the bot reported one.
- **Q5:** kills by source card are complete, summoned units included. Mechanic uses are covered only by summons per summoner and shop-phase abilities per mechanic (e.g. `pigeon_lance_corporal` 10,398). Renown gains are kept raw as JSON. Fights record only a total trigger count, not triggers per mechanic.

How hard each was to write:
- **Q1:** medium. Joining the bought indices to the offers needed `list_filter`/`list_contains`. Sells come from the chosen action in `decisions`.
- **Q2:** easy.
- **Q3:** easy. "Share of final boards" needed the card→tribe list from `library.json`.
- **Q4:** easy. `median` and `quantile_cont` are built in. The counters needed a long table because their keys vary by tribe.
- **Q5:** easy once `fight_kills` and `fight_summons` were unnested at load.
- **Q6:** medium. It needs `from_json(..., '["JSON"]')` to unnest the players.

## 6. Scale guess for 100,000 games

Method: I measured 1× and 10× (a duplicated copy), split the 10× file by layer, and scaled linearly ×50. Duplicated data may compress slightly better than real new games would, so I rounded sizes up.

- **Disk, archive:**
  - Raw: 39 GB.
  - zstd -19 files: 1.5 GB.
  - DuckDB, one row per game: about 2.2–2.5 GB.
  - DuckDB, one row per line: about 4–5 GB.
- **Disk, analysis layer:** about 5–6 GB. `bot_values` (one row per card valued in each shop) is the biggest table, then `shop_offers` and `actions`.
- **Queries at 2 threads:**
  - Q2, Q3, Q4 and Q5: about 1–6 s each.
  - Q1: about 30 s each part. These scan 360 M offer rows and 320 M value rows.
  - Q6 on the per-line archive: about 35 s, because it scans every line's `op`. A small refight table or sorting by round would cut that.
  - At 6 threads, divide the scans by about 3.
- **Fetching one game:**
  - Per-line layout: stays at tens of ms, because the games are sorted and DuckDB skips row groups.
  - One row per game: 100,000 rows fit in one 122,880-row group, so each fetch decompresses about the whole archive. Expect around a minute per fetch. That layout is unusable for fetching one game.

## 7. Pros and cons for this project

Pros:
- It reads the match writer's JSON lines directly, nested objects included, with good type guessing. The whole analysis layer is about 150 lines of SQL inside Python, built in ~30 s.
- Every question was one SQL statement with built-in median and quantile functions. The answers matched plain Python exactly.
- It is a single file with no server. The same file serves the Python scripts, the CLI and an MCP agent.
- With `latest` storage, the archive is near gzip size and byte-exact, and SQL can get inside it (Q6).

Cons:
- The defaults are bad for this data. The 2020s-era compression stays off until you set `STORAGE_VERSION 'latest'` at `ATTACH`. Strings under 4,096 bytes never get zstd unless you ask per column. Nothing warns you.
- It loses to plain files on archive size: 25 vs 15 KB/game, the latter being zstd -19 one file per game.
- The archive layout that gives the best size is the one that makes fetching a single game slow at scale.
- Versions: the MCP package pins an older DuckDB. Files written with `latest` storage on a newer DuckDB may not open in the version the MCP server uses.
- Only one process can write to the file at a time. A running league that writes while an agent reads needs care, such as `--ephemeral-connections` or loading after the league ends.

Fit for the owner's goal: keep the archive as zstd -19 files per game (smallest, and fetching a game is just reading a file). Use DuckDB for the analysis layer, loaded after each league from the writer's JSON lines. Add the per-line archive table only if agents need SQL over replay contents.

## 8. What an agent would struggle with next time, and the fix

- **Compression defaults.** A short project note would fix it: "attach with `STORAGE_VERSION 'latest'`; use `USING COMPRESSION zstd` on long JSON text columns; check with `pragma_storage_info`."
- **Dialect slips.** Write `AS` on every alias. The JSON functions are `json_type`, `json_extract_string`, `->>`, and there is no `json_strip_nulls`. `->>` on a JSON string (as opposed to an object) gives NULL silently. A one-page DuckDB cheat sheet in the repo, or a `duckdb` skill, would catch all of these.
- **Silent wrong results.** Any NULL-heavy column should fail the load. A helper script that checks NULL rates and row counts per table after loading would catch it.
- **MCP install pin.** Install the MCP server in its own venv, or install it first and use its DuckDB for everything. Write that in the setup note.
- **MCP parameter name.** Haiku guessed `query` where the server wants `sql`. One line in the agent's brief ("execute_query takes `sql`") saves two calls.
- **Archive layout trade-off.** Not obvious: per-line rows fetch fast, one row per game compresses best. A note with the numbers above prevents the trap.
- **Full board snapshots.** Kept as JSON they are large and uncompressed by default. If refights matter, use a dedicated table with a zstd column, sorted by round.

## 9. Disk report

Everything is in `/data/dbtest/duckdb/` (988 MB total), except one item outside it: the headless `claude -p` run, which the brief requires, made Claude Code's usual session folder `~/.claude/projects/-data-dbtest-duckdb/`. I did not open it. It can go if the transcript isn't wanted.

| Path | Size | Keep? |
|---|---|---|
| `REPORT.md`, `LOG.md`, `scripts/`, `queries/`, `mcp.json`, `mcp_run.jsonl`, `mcp_run.stderr`, `results/`, `results_scale10/`, `comp/results.txt`, `comp/sha_files.txt` | < 1 MB | Keep (evidence) |
| `bramble.duckdb` (analysis + both archive layouts) | 25 MB | Keep for the debrief; the MCP config points at it |
| `analysis.duckdb`, `analysis_latest.duckdb`, `arch_file_latest.duckdb`, `arch_lines_latest_zstd.duckdb` | 13 + 13 + 5 + 10 MB | Can go (they are inside `bramble.duckdb` or are measurement variants) |
| `arch_file_default.duckdb`, `arch_lines_default.duckdb`, `arch_lines_latest.duckdb` | 76 + 85 + 85 MB | Can go (measurement variants) |
| `scale10.duckdb`, `s10_analysis.duckdb`, `s10_records.duckdb`, `s10_lines.duckdb` | 217 + 101 + 43 + 76 MB | Can go (scale test) |
| `comp/gzip6`, `comp/zstd3`, `comp/zstd19`, `comp/xz6` | 17 MB | Can go |
| `venv/` (DuckDB, MCP server) and `.uvcache/` | 146 + 85 MB | `.uvcache` can go; `venv` is needed only to rerun |
| `docs/llms.txt`, `duckhome/` | < 1 MB | Can go |

Sources: [duckdb.org/llms.txt](https://duckdb.org/llms.txt), [motherduckdb/mcp-server-motherduck](https://github.com/motherduckdb/mcp-server-motherduck), [PyPI mcp-server-motherduck](https://pypi.org/project/mcp-server-motherduck), [duckdb_mcp community extension](https://duckdb.org/community_extensions/extensions/duckdb_mcp.html).
