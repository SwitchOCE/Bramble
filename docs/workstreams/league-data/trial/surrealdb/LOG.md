# LOG — SurrealDB trial
13:00:43 start; read BRIEF.md
13:01:08 step0 done: inspected sample (records/*.jsonl ops header/start/act/fight_boards/finish; games.jsonl per-seat rounds+fights; shops.jsonl.gz offers/bought; decisions.jsonl.gz legal/chosen; reports.jsonl bot values)
13:01:09 step1 start: install SurrealDB
13:01:54 downloaded surreal v4.0.1 release tgz (88.8MB) from GitHub; .txt checksum URL 404 (dead end), verified sha256 via GitHub API asset digest instead: match
13:01:54 found built-in 'surreal mcp' subcommand in --help
13:02:34 docs: surrealdb.com/llms.txt (200, has 'markdown for agents' + '.md' on every page) and docs/llms.txt index (104KB) — helpful; it flags 4.0 removed RocksDB
13:02:34 docs: fetched MCP pages (embedded MCP, agent-skills, agents/claude-code). Note docs say 'surreal db mcp' but binary command is 'surreal mcp' — mismatch
13:03:46 docs: no SurrealKV compression setting anywhere in env vars / start docs / llms-full.txt (only RocksDB had one, removed in 4.0). Cloned surrealdb/agent-skills (surrealql skill) into docs/
13:04:16 venv: pip install surrealdb -> SDK 3.0.0 (server is 4.0.1); agent-skills surrealdb-python SKILL.md still says 'rocksdb:database' (outdated for 4.0)
13:04:34 ERROR: SDK 3.0 db.query() returns a lazy SyncQueryBuilder; nothing sent unless .execute()/.rows(). Skill & docs examples (db.query(...) directly) don't show this. Looked up builder in installed package source
13:05:00 archive_raw: 200 records loaded as string field in 5.2s; sha256 check 200/200 match
13:05:11 dead end (mine): 'pkill -f <path>' matched my own shell and killed the tool call (exit 144); server still got SIGTERM and shut down cleanly. Switched to pid files
13:05:11 archive_raw on disk: 112.1MB while running (before flush), 78.5MB after clean shutdown (vlog 78.49MB = values stored uncompressed)
13:06:41 archive_zstd: app-side zstd-19 bytes field; load 71s (compression dominates), verify 200/200; disk 36.7MB running -> 3.11MB after shutdown
13:06:41 step4 start: file compression benchmarks (per file, 1 thread each)
13:09:24 step3b start: analysis layer load
13:09:47 step2 MCP: chose built-in MCP of the surreal binary (HTTP /mcp on running server). Rejected: hosted mcp.surrealdb.com (Cloud only, needs sign-in) and the stdio 'surreal mcp' (embedded, would need the store's LOCK held by the server). Older separate repo surrealdb/surrealmcp is superseded per docs. Nothing extra to install
13:09:47 MCP: curl POST /mcp tools/list -> 'Unexpected message, expect initialize request' => endpoint is live; wrote mcp/mcp-config.json (http + Basic auth + surreal-ns/db headers)
13:10:50 query draft: '<float> golden' -> ERR 'Could not cast into float using input false' (bool->number casts not allowed); using count(golden) instead
13:11:08 query draft gotcha: int/int is integer division in SurrealQL 4 (7/2=3); need <float>. Also my loader holds sub-2000 batches till the end, so seat/game looked empty mid-load (my bug, harmless)
13:11:29 doc lookup: clauses/group.md — non-aggregate fields in GROUP BY are collected into arrays (4.0 rule); math::percentile is not an aggregate, so collect then compute in outer SELECT
13:12:35 step3b done: analysis layer loaded in 171s (970K rows, 10 tables) + card library 112 rows; disk while running 437MB
13:12:35 step5 start: run queries.surql x3
13:13:10 step5: queries done; medians Q1 2491ms Q2 71 Q3 119 Q4 194 Q5 180 Q6 27; checked vs Python: Q1 per-card offered/bought (104 cards) + sentry by round, Q2 all 86 cards, Q5 fight count/mean deaths/top kills: all match. Compare script first read wrong result index (LET returns null, I filtered them) - my bug
13:13:10 step2b: headless claude -p with mcp/mcp-config.json --strict-mcp-config, haiku
13:13:24 headless run OK: 3 turns, 6.0s, $0.0057; answer (gleaner 1497 @4.23, blackthorn-sapling 1162 @4.88, orchard-stripper 1116 @3.36) matches Python
13:13:46 headless run 2 (no schema hints): 6 turns, 8.4s, found seat table via list/info + COMMENTs, answer matches Q3
13:14:13 step4b: analysis store after shutdown 318.6MB (one 318.6MB sst); zstd -3 of that sst = 94.9MB => SurrealKV stores uncompressed. Board snapshots are 36.7MB as compact JSON. Loading a no-boards variant to split the size
13:14:37 (logged late) step4 file compression done ~13:09: per-file totals gzip-6 4.53MB, zstd-3 4.62MB, zstd-19 3.06MB, xz-6 3.22MB; see compress_bench.txt. Fetch one game (raw store): 4.3ms median, identical
13:16:25 step4b done: no-boards analysis store 282.4MB after shutdown (load 111s) => boards ~36MB; offers (722K rows) dominate
13:16:32 REPORT.md written; all servers stopped; total folder 1.1GB
