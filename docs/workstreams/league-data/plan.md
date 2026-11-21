# League data: build plan

Approved by the owner, 21 Nov 2026: "Approve the plan. I recommend I agree with the recommendation. You can go forward". It replaced a five-step plan after a `/plan-interrogate` check found most of that plan's analysis tooling already exists. The Ghost Build Orchestrator builds it; each step passes the two gates (tests and runtime proof, then a scope review) before it merges to `dev`.

## Goal

A match keeps only what balance decisions need, tens of MB at most while its data is in use, and a couple of MB per build once the build is old (README.md's keep list). Replays and ghosts work exactly as today.

## Steps

1. **A prune script, run by the referee after each match.** It takes a match folder and its kind (climb or stopping test, balance reading, field cut, old build) and leaves exactly what README.md's table keeps. For a balance-reading match it gzips (`gzip -n`) what is kept, and trims the decision log to the chosen move at each decision, dropping the list of legal moves. For an old build it writes the findings folder (at most 2 MB) as CSV from the existing `tools/league/analysis` reports (`cards.py`, `tribes.py`). The referee brief calls it after every match. **Proof:** run on a copy of a real match for each kind; list what is left and its size; the trimmed decision log still gives the same `cards.py` and `tribes.py` output. **Checkpoint for the owner:** `du -sh /data/*` and one old build's folder.
2. **Stop writing the bots' reasoning log and the duplicate Discover log.** `league match` and `league ghost-match` stop writing `reports.jsonl` and `discovers.jsonl` by default; a flag turns them back on for a team debugging its bot. The bot's value for each offered card moves into `shops.jsonl`. `match_data.py`, `cards.py` and `tribes.py` read the new form, and Discover picks come from `decisions`. Check the teams' own tools (red's `practice_table.py` reads `reports.jsonl`) and tell the teams. Lands before the third run starts. **Proof:** `cards.py` and `tribes.py` on a 200-game match give the same results before and after.
3. **Field meanings in `tools/league/league/LOGS.md`:** add the ones the trial had to guess (`deaths` vs `killed` in fight results, and any other gaps).

The replay record is not changed, so ghosts, replays and the rules fingerprint are untouched.

## Put off until the balance session asks for something the Python reports can't answer

- A DuckDB analysis file (the trial's pick when a database is needed: see `trial/duckdb/REPORT.md` for its traps).
- Trigger counts per mechanic in fights (summarise from `bramble-events`).
- zstd for long-term archives at large scale (gzip is within 8 MB per 1,000 games and needs no new Rust dependency).
- A shared shop id across shops and decisions.
