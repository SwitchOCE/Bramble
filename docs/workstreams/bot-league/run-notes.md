# Bot league: referee's run notes

The referee keeps these so the owner or a later session can see where the league stands without
asking. Newest status first. The plan is [brief.md](brief.md) (approved 18 Nov 2026).

## Status

Phase 0 started 18 Nov 2026, about 14:15. **At the owner stop** (18 Nov, about 17:45): the port
matches GDScript on every check, the harness passes its gates, and the hand-over is
[phase0-handover.md](phase0-handover.md). Not frozen or tagged yet: three questions from the
scope review and the clock pick wait for the owner. The teams are not started.

## The pin

- `dev` at **`c0d7db795bcb63ff38de8a5da941f96fb00aeba3`** (merge of PR 149, 18 Nov 2026). PR 128
  (Hit becomes Ambush) is not in it.
- Branch `league/engine` was cut from that commit. All league code lives in `tools/league/`.
- Godot 4.7.2, Rust 1.100.0 (pinned in `tools/versions.env`).

## Phase 0 milestones

| Milestone | State |
|---|---|
| Skeleton (ids, mechanic trait, serializer, random streams) | **done** 14:55 (`e608d642`): 1,000/1,000 record starting hashes match; JSON, Rng and sort match Godot on test cases |
| Combat | **done** 15:21 (`de374e27`, branch `league/p0-combat`): 20,000/20,000 stand-in fights match the full state byte for byte; a planted Attack change was caught by 8,870 |
| Recruit | **done** 15:30 (`4325d7cd`): 500/500 stand-in games replay, every checkpoint, action result and fight payload; planted refresh-cost bug caught at turn 1 |
| Mechanics per tribe | **all five done** 16:11. Each alone: 300/300 games and 20,000+ fights match; a planted bug in each tribe caught (mouse, pigeon, badger, locust, thorn) |
| Records match, GDScript to Rust (1,000 games) | **1,000/1,000 match**, 45,900 checkpoints (16:15, `1d7c6225`, `tools/league/proof/replay_all.sh`) |
| Records match, Rust to GDScript (50 games) | **50/50 replay in GDScript** (`league match` flow vs random, 25 seeds both colours): 773 turns, 2,319 checkpoints, 0 Godot errors |
| Fights match (100,000 mutated fights) | **100,000/100,000 match**, full state string compared (3.1 GB) |
| Planted bugs caught | **caught by every check**: Attack on `lone-hawthorn` changed 4,012 of 10,000 fights; refresh cost +1 failed 1,000/1,000 replays at turn 1; Rust records with the plant rejected by GDScript at turn 1 |
| Speed-up measured | before the speed pass: whole game ~6.4×, late fight ~15×. **After it** (`bff62ad5`): **whole game ~13×** (GD 1.92 s, Rust 0.147 s), **late fight ~40×** (`_fight` only, GD 13.6 ms, Rust 0.33 ms). Load 3-5 from other work. All proofs rerun on the merged code: [proof/SPEED.md](../../../tools/league/proof/SPEED.md) and `/home/alex/league/proof/recheck-final/` (all PASS) |
| Harness built | **built** 16:08 (`3b73a737`). Selfcheck on all tribes: 1,000/1,000 games equal the GDScript records (909,806 actions). Cheat crates caught; clock-out works (stand-in content) |
| Decision log (owner's ask, 18 Nov) | **added** (`4a24abe1`): `decisions.jsonl.gz`, every legal action at every decision with its card, and the pick; one line per record `act` (tested) |
| Clock figures | **measured** on all tribes: a late `Sim` fight 0.61 ms CPU; about 110 decisions per seat a game. 250 ms: 2.3 ms a decision, 6.3 min a match on 4 cores. 1 s: 9 ms a decision, 23 min a match on 4 cores (bots that use their whole clock) |
| A/A, TribeBot vs TribeBot (1,000 games) | **gap +0.061 ± 0.108**, inside ±0.11; red 4.531, blue 4.469; seat placements 4.41-4.61; 0 clock-outs, faults, panics or refusals |
| Gates (runtime, scope review) | runtime: `scripts/check.sh` **all steps passed** (`src/` unchanged since the pin); cheat crates (unsafe, static/atomics, include of the other team) **fail** `check-crate`, the clean crate passes; on all tribes, busy, panic and fault bots fall back on all 80 of their seats and every game finishes. **Scope review 1** (`c0d7db79..d25dbbd8`): 0 cut, 1 simplify (README, done), 3 ask (for the owner). Scope review 2 on the later commits: running |

## Where things are

- Reference records from the GDScript engine: `/home/alex/league/records/gd/c0..c2/` (seeds
  1-1000, FlowBot and RandomBot seats, made by `scripts/records.sh`).
- Porting rules for workers: [tools/league/PORTING.md](../../../tools/league/PORTING.md).

## Log

- 18 Nov, 17:45: speed pass merged; full recheck PASS on it. Planted refresh check redone as `proof/plant_refresh.sh` with logs (the first scripted try failed for the wrong reason, a missing repo path, and was fixed to require the planted reason). Decision log added at the owner's ask. Clock figures measured. check-crate now bans memory addresses; the harness refuses a root without card data. Owner stop written.
- 18 Nov, 17:10: `scripts/check.sh` passed. Gate bots on all tribes: busy 80/80 clock-outs, panic 80/80, fault 80/80, games finish. Busy (SimpleBot after the clock-out) beat TribeBot by 0.5 in 20 games; a 400-game SimpleBot vs TribeBot match says that was noise (TribeBot ahead, +0.18 ± 0.15).
- 18 Nov, 16:50: Rust→GD 50/50, fights 100,000/100,000, planted bugs caught, selfcheck 1,000/1,000, speed measured, A/A within the bar. `scripts/check.sh` and the speed pass running.
- 18 Nov, 16:15: all tribes merged; 1,000 GDScript games replay in Rust with every hash matching. 100,000-fight check running.
- 18 Nov, 15:25: integration branch `league/p0-core` (combat + recruit) pushed; tribe workers and harness started on it. The Codex bridge allows 5 workers at once, so the harness went to an Opus sub-agent.
- 18 Nov, 14:58: skeleton merged; combat and recruit workers started in parallel.
- 18 Nov, 14:15: pinned `dev`, made `league/engine`, started the 1,000 GDScript reference games
  (3 processes).

## Rulings and calls made without the owner

- **Planted bug on the starting hash.** The skeleton worker found that a changed card Attack can't
  change the *starting* hash: no units exist yet and the hash leaves out the card library. A
  changed card tier does change it. So planted Attack bugs are checked on later checkpoints and
  fights, where units exist. Nothing about the hash was changed to make it catch more.
- **Clock-out fallback is SimpleBot.** The brief says "a simple baseline bot"; SimpleBot is the
  simplest ported one.
- **"A bot that sleeps past its clock" is tested as a busy bot.** The clock is CPU time (brief
  5b.4.5), so a sleeping bot uses no clock. The gate bot burns CPU instead.
- **A hung bot call aborts the match** (exit 3, past the clock + 5 s CPU or 60 s wall). A thread
  can't be stopped safely, so the baseline can't take over a call that never returns.
- **check-crate allows only `league-api` as a dependency**, and bans memory addresses (`{:p}`,
  raw pointers) as a channel between seats.
- **Harness details** the harness agent chose: typed `Action`s, `report` as (card, value) pairs,
  past fight payloads renumbered by the engine as in GDScript, main tribe ties broken by stats.
  All written in `tools/league/league/README.md` and `LOGS.md`.
- **Models:** Codex workers ran gpt-6.1-sol as instructed (gpt-6.2 exists; not used). The
  bridge allows 5 workers at once, so the harness went to an Opus sub-agent.
- **The decision log is gzipped** at the end of each match (40× smaller, about 40 MB a match).
