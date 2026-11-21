# League data: what a match keeps, and where

From the League Data Storage session, 21 Nov 2026. The owner approved the recommendations below on 21 Nov: "Okay, I approve your recommendations." The debrief page for the owner is at https://claude.ai/artifact/9ZPVx17TdVDhMq6VjTEuHA.

## The owner's words

On the old league filling the Optiplex: "We need the ability to do standard developer analytics on balance choices and understanding the game state without storing far too much information … The first step is to get rid of anything that has been completely superseded … We should just keep it at most a gigabyte".

On what a match keeps (to the Ghost Build Orchestrator): "The match should only keep whatever we need to make balance decisions. And then, once those decisions have been made and we no longer need it, as soon as a match is outdated and the build that the data was generated for is an old build, we should only keep a very small summary, nothing more than a couple of megabytes, right? Like we don't need comprehensive data, just the high-level findings report".

## What a match keeps

| Match | Keep | Delete |
|---|---|---|
| Climb and stopping-test matches, once decided | `summary.json`, `analysis.json`, a one-line verdict (bot versions, seeds sha, games, mean-place gap, 95% interval, kept or not) | Everything else, at once. If the new version is kept, cut and verify its ghosts first |
| Matches balance reads (named by the balance session), and matches the per-tribe report or rework checks read | Raw files gzipped, until the tuning change merges or the report is written; then only the findings | The raw files after that |
| Matches that make a ghost field | `summary.json` | `records/` and raw logs, once `bramble-ghosts cut` and `verify` pass |
| Any match whose build is old (rules hash no longer on dev) | One folder per build, at most 2 MB: findings report, per-card × round × tribe and per-tribe tables as CSV, stopping-test verdicts | Everything else |

Always: big output goes on `/data`, never `/`; no `reports.jsonl`; the referee deletes as it goes.

## How data is stored (direction approved; the build plan is still to be checked)

- **Archive:** each game's replay record compressed with zstd, one per game, as a file or a blob in one SQLite file: 15–23 KB a game, against 392 KB raw. It is the source of truth; replays, ghosts and any rebuild come from it.
- **Analysis:** DuckDB, loaded after each league, with small summary tables per league.
- **Match writer:** no full reasoning log, but keep the bot's card value; a shared shop id in shops and reports; a format doc beside `matchrun.rs`; per-mechanic trigger counts in fights.
- **SurrealDB:** not for this; a candidate later for the online ghost store.

## Evidence

`trial/` holds the brief, and each agent's report, log and scripts from the 21 Nov trial of SQLite, DuckDB and SurrealDB on a 200-game match with the final bots. The trial's data has been deleted.
