# SQLite trial — report

## 1. Result in three lines

- SQLite worked end to end in about 17 minutes of wall time with 7 dead ends, none blocking: all 200 replay records came back byte-for-byte, and five of the six questions were answered in full, with Q5 partly. Two answers were checked against plain Python and matched.
- The best archive is app-level zstd -19 with a trained dictionary, stored as BLOBs in SQLite: **14.5 KB per game** (raw is 392 KB, a 27x cut). One game comes back in about 1 ms. SQLite itself has no free built-in table compression.
- The weak part is the row-level analysis layer: 259–544 KB per game, which is bigger than the compressed archive. Full-scan queries take 1 ms–1.1 s now, but at 100,000 games they would take minutes, so per-league summary tables are needed. The "official" MCP server is archived and crashed on start until I pinned `mcp<2`.

## 2. Setup

| Step (from LOG.md) | Wall time | Failed attempts |
|---|---|---|
| 0 Inspect sample formats | ~3 min (overlaps step 1) | 0 |
| 1 Install: SQLite CLI 3.54.1 release zip (sha3 checked) into `bin/`; sqlite-zstd v0.3.5 release `.so` into `ext/`; `uv venv` + `mcp-server-sqlite` into `venv/` | 13:01–13:04, ~3 min | 1 (no `llms.txt`) |
| 3a Load analysis layer (`scripts/load_analysis.py`, `schema.sql`) | 13:04–13:07, ~3 min; one load takes 46 s | 1 (first load was 197 MB, see 8) |
| 3b+4 Archive DBs + compression benchmark | 13:07–13:13, ~6 min (zstd -19 alone takes 90–130 s) | 2 (Python's SQLite can't load sqlite-zstd; CLI `writefile` "unsafe use") |
| 5 Queries, timings, Python checks, fetch one record | 13:13–13:16, ~2.5 min | 2 (my percentile SQL bug; ghost boards `player=-1`) |
| 2 MCP server + headless agent | 13:16–13:17, ~1 min | 1 (server crash, mcp 2.x) |
| 6 Lean variant for scale estimate | <1 min | 0 |

- **Nothing to install for basic use:** Python 3.14's stdlib has `sqlite3` (SQLite 3.46.1) and `compression.zstd`. The CLI download was only for `median()`, `dbstat`, `.archive`/sqlar, `writefile` and loading sqlite-zstd.
- **Docs used:** sqlite.org/download.html (version and checksum). Web search to find the MCP server and compression options. The sqlite-zstd README that ships with the release. The MCP server's own `server.py` source, which showed its tools and SELECT-only check. Most of what I needed was already known; the docs were mainly for versions.
- **Agent files:** sqlite.org has no `llms.txt` (404). I found no official agent skill or docs MCP for SQLite.

## 3. MCP server

- **Picked:** `mcp-server-sqlite` 2025.4.25 on PyPI, the Model Context Protocol team's reference server. It is the only official option, but it is **archived** (moved to modelcontextprotocol/servers-archived), so it gets no new releases. Third-party options exist: a Rust crate `mcp-server-sqlite` 1.0.0, an npm `mcp-sqlite`, and a Docker-published one. I picked the archived reference server because it is the closest thing to official, and it is small enough to read in full.
- **Install:** into `venv/`. It is registered only in `/data/dbtest/sqlite/mcp.json` and points at `analysis.db`, which I made read-only (`chmod a-w`) because the server also exposes `write_query` and `create_table`.
- **First headless run failed silently:** the agent replied "I don't see any sqlite MCP tools", with exit code 0. The server crashes on start with `AttributeError: 'Server' object has no attribute 'list_resources'`. Its `mcp` dependency is unpinned, and uv installed mcp 2.3.0, which broke the API. Fix: `uv pip install "mcp<2"` (gives 1.30.0).
- **Second run worked** (`claude -p … --mcp-config mcp.json --strict-mcp-config --model claude-haiku-5-5 --tools "" --allowedTools mcp__sqlite__read_query,… --no-session-persistence`): 6 turns, 9.3 s, $0.003. Its answer: regimental-sergeant-major is on 111 final boards with an average place of 1.82, which matches my own query. Along the way the agent found that `read_query` **rejects queries starting with `WITH`** (CTEs) and rewrote its query as a subquery. Output is in `mcp_run.json`.

## 4. Sizes

200 replay records. 1 KB = 1,000 bytes, so the two size columns hold the same number. Times are for all 200 games on 1 thread.

| Method | KB / game | MB / 1,000 games | Compress | Decompress |
|---|---|---|---|---|
| Raw `.jsonl` | 392.3 | 392.3 | – | – |
| gzip -6 (per file) | 22.7 | 22.7 | 2.8 s | 0.8 s |
| zstd -3 (per file) | 23.1 | 23.1 | 3.6 s | 3.8 s (mostly 200 process starts) |
| zstd -19 (per file) | 15.3 | 15.3 | 130 s | 2.3 s |
| xz -6 (per file) | 16.1 | 16.1 | 21.6 s | 2.6 s |
| **In SQLite, default** (BLOB, no compression; SQLite has none built in) | 393.6 | 393.6 | 3.6 s write | 1.3 s read |
| In SQLite, built-in sqlar (`sqlite3 -A`, zlib) | 23.1 | 23.1 | 3.9 s | 1.0 s |
| In SQLite, sqlite-zstd extension, level 19 (third party, transparent) | 16.8 | 16.8 | 96 s | 0.08 s |
| In SQLite, app-level zstd -19 BLOBs | 16.5 | 16.5 | 90 s | 0.8 s |
| **In SQLite, best: app-level zstd -19 + trained 110 KB dictionary** | **14.5** | **14.5** | 79 s + 4.6 s training | 0.9 s |
| *(not per-game:* all 200 in one zstd -19 `--long` stream*)* | 10.7 | 10.7 | 127 s | – |
| **Analysis layer, as built** (`analysis.db`, includes 47 MB of refight snapshots) | 543.6 | 543.6 | load 46 s | – |
| Analysis layer, lean (no snapshots; card ids as integers) | 258.9 | 258.9 | +4 s | – |
| Lean analysis file, zstd -3 (for cold storage) | 62.0 | 62.0 | 0.4 s | – |

Every in-SQLite archive was checked: 200/200 records matched the original files' sha256. Game 137 was also fetched back and compared with `cmp`: identical. Fetching one record (median of 3) took 0.8 ms raw, 1.0 ms with zstd, and 1.2 ms with zstd + dictionary.

In the as-built analysis layer, the space goes to: refight snapshots 47 MB, shop offers 22 MB (722k rows), chosen bot actions 14 MB (436k rows), fight kills 5 MB, board units 4 MB plus a 3 MB index.

## 5. Queries

Analysis tables: `seats`, `seat_rounds`, `seat_round_tribes`, `seat_round_counters`, `board_units` (round 0 is the final board), `shops` + `shop_offers` (with the bot's value attached), `actions` (every chosen bot action), `discovers`, `fights`, `fight_kills`, `fight_summons`, `fight_snapshots`, `cards`, `card_tribes`. SQL is in `scripts/queries.py`; results are in `results/*.tsv`.

| Question | Answered | Median ms (of 3) | Checked against Python |
|---|---|---|---|
| Q1 buy rate per card by round / by buyer tribe; sold; bot value | yes | 841 / 1,112 / 836 | yes, exact (offers, buys, sells) |
| Q2 final boards: share, place with vs without, golden | yes | 41 | yes (all 86 cards match; 2 rows differ only in how .0625 rounds) |
| Q3 tribe average place, share of final boards, place by round reached | yes | 14 / 1 | no |
| Q4 board attack/health median + spread per round; tribe counters | yes (counters exist only for Locust and the Thorn heap) | 73 / 130 | yes (round 8 median 135) |
| Q5 kills by source, deaths per fight, mechanic uses | partly | 7 / 166 / 363 | yes (deaths per fight, all 22 rounds) |
| Q6 50 full boards at round 8 | yes | 2 (stored snapshots); 155 cut from the zstd archive | no |

How hard each one was to write:
- **Q1:** easy, one join and a group-by. The catch: shop rows and bot-value rows have no shared key, so they only line up by file order (I checked all 103,692). An offer counts once per shop view, so a frozen or unchanged card counts again. Buyer tribe = the seat's final `main_tribe`; the round's leading tribe is also stored.
- **Q2:** medium. "Place without the card" needs a total-minus trick.
- **Q3:** easy. "Round reached" is my reading: the round the seat died in, or "won".
- **Q4:** the hardest. Python's SQLite 3.46 has no `median()` (the 3.54 CLI does), so percentiles are window functions. My first try with `percent_rank()` returned NULL for one-row groups; `cume_dist()` fixed it.
- **Q5:** easy once flattened. The sample records kills by unit and origin (start/summon/reserve), deaths, attacks, a total trigger count, summons by source, and the bot's chosen actions. It does **not** record which mechanic or keyword fired in a fight (only a total trigger count) or damage by source, and `renown` is empty in this sample.
- **Q6:** trivial. Snapshots of ghost opponents carry `player = -1` and must be filtered out.

## 6. Scale guess for 100,000 games

Method: 100,000 games is 500 times the sample. Sizes and full-scan query times grow linearly, because each query is a full-scan GROUP BY whose number of groups (cards × rounds × tribes) does not grow with games. The Q4 percentiles sort, so they grow a little faster. Measured on 1 thread.

- **Archive** (zstd -19 + dictionary in SQLite): **about 1.45 GB**. With zstd -3 or gzip instead: about 2.3 GB at almost no CPU. Raw would be 39 GB. zstd -19 costs about 0.4 s of CPU per game, compared with about 10 s of CPU to play a game.
- **Analysis layer at row level:** 26 GB lean, 54 GB as built, with about 360M shop-offer rows and 220M action rows. That is likely larger than the page cache.
- **Query time:**
  - Q1: 7–9 min each.
  - Q1c and Q5c: 3–7 min.
  - Q5b, Q4b and Q4a: 0.5–1.5 min.
  - Q2: about 20 s.
  - Q3 and Q5a: seconds.
  - Q6 stays in milliseconds (indexed), or about 155 ms when cut from the archive.
- **What would fix the slow ones:** per-league summary tables (card × round × tribe counts and value sums, built at load time) would answer Q1–Q5 in milliseconds at any scale, in a few MB. Row-level tables would then be kept only for recent leagues.

## 7. Pros and cons for this project

**Pros**
- Nothing to install for basic use: Python's stdlib has SQLite and zstd.
- One file per database; easy to copy, back up and sync.
- Byte-exact archive is trivial (BLOB + sha256), and the best per-game size I found (14.5 KB) came from SQLite holding zstd + dictionary blobs.
- One game's record comes back in about 1 ms, which suits replays and cutting ghosts.
- Plain SQL answered every question the data supports. The Python checks matched.

**Cons**
- No built-in compression for tables. The row-level analysis layer is 18–37 times the size of the compressed archive.
- Queries run on one thread, and full scans grow linearly, so you must design summary tables.
- Two SQLite versions in play: Python's 3.46 lacks `median()` and cannot load sqlite-zstd (`version mismatch 3046001 < 3049001`), while the 3.54 CLI can.
- Schema traps cost a reload. A `WITHOUT ROWID` table with 1.7–4 KB rows doubled the size, and an unused index added 16 MB.
- The official MCP server is archived, broke on install, rejects CTEs, and exposes write tools.

## 8. What an agent would struggle with next time, and what would fix it

1. **The MCP server breaks out of the box,** and the agent's only sign is "no tools" with exit code 0. Fix: a pinned requirements file (`mcp-server-sqlite==2025.4.25`, `mcp<2`) and a line in a skill. Better: a 40-line read-only MCP server of our own that accepts `WITH` and opens the DB `mode=ro`.
2. **The Python vs CLI SQLite version split** (no `median()`, can't load extensions). Fix: a doc line saying "use `bin/sqlite3` 3.54, or a newer SQLite build for Python". Or skip sqlite-zstd and keep compression at the app level, which was smaller anyway.
3. **No join key between `shops.jsonl` and `reports.jsonl`** (they only line up by order). Fix: the match writer should write a shop id in both.
4. **Field meanings had to be guessed:**
   - `deaths` vs `killed` in fight results
   - `origin` values (start/summon/reserve)
   - shop `reason` values (turn_start/refresh/changed)
   - ghost `player = -1`
   - `heaps` as counts

   Fix: a schema doc next to `matchrun.rs`.
5. **Storage traps** (`WITHOUT ROWID` for big rows, needless indexes). Fix: a ready loader. `scripts/load_analysis.py`, `queries.py` and `load_archive.py` here could become a repo tool, with summary tables added.
6. **sqlite-zstd quirks** (`PRAGMA trusted_schema=ON` to read through `writefile`, warnings about WAL and auto_vacuum). Fix: avoid the extension, since app-level zstd + dictionary was smaller.

## 9. Disk report

Everything is in `/data/dbtest/sqlite/`: 345 MB in total after I deleted 3 × 78 MB of extracted verification copies.

| What | Size | Can go? |
|---|---|---|
| `analysis.db` (read-only, chmod a-w) | 104 MB | yes after the debrief (rebuild in 46 s) |
| `archive_raw.db` | 76 MB | yes |
| `uv-cache/` | 53 MB | yes now |
| `analysis_lean.db` | 50 MB | yes after the debrief |
| `comp/` (external compressed copies, fetched record, checksums) | 19 MB | yes |
| `venv/` (MCP server) | 11 MB | yes after the debrief |
| `bin/` (sqlite CLI tools) | 8.2 MB | yes after the debrief |
| `dl/` (downloaded zip and tarball) | 5.2 MB | yes now |
| `archive_sqlitezstd3.db`, `archive_sqlitezstd19.db`, `archive_sqlar.db`, `archive_zstd19.db` | 5.1 + 3.3 + 4.5 + 3.2 MB | yes |
| `ext/` (sqlite-zstd) | 2.4 MB | yes |
| `archive_zstd19dict.db` (best archive) | 2.8 MB | keep until the debrief |
| `scripts/`, `results/`, `LOG.md`, `REPORT.md`, `mcp.json`, `mcp_run.json` | <0.3 MB | keep |

Outside my folder: nothing that I know of. The headless `claude -p` run used `--no-session-persistence`, but I can't rule out that the CLI touched its own caches under the home directory. `uv` had its cache and Python install directories set inside my folder.
