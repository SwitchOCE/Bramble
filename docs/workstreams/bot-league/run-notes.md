# Bot league: referee's run notes

The referee keeps these so the owner or a later session can see where the league stands without
asking. Newest status first. The plan is [brief.md](brief.md) (approved 18 Nov 2026).

## Status

Phase 0 started 18 Nov 2026, about 14:15. Nothing frozen yet. The teams are not started; that
needs the owner's word.

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
| Records match, Rust to GDScript (50 games) | not started |
| Fights match (100,000 mutated fights) | 100,000 cases made and run in GDScript (33 ms a fight); Rust side waits for the tribes |
| Planted bugs caught | not started |
| Speed-up measured | not started |
| Harness built | **built** 16:08 (`3b73a737`): baseline bots replay 500 stand-in games byte for byte; cheat crates caught; clock-out works. All-tribe checks next |
| Gates (runtime, scope review) | not started |

## Where things are

- Reference records from the GDScript engine: `/home/alex/league/records/gd/c0..c2/` (seeds
  1-1000, FlowBot and RandomBot seats, made by `scripts/records.sh`).
- Porting rules for workers: [tools/league/PORTING.md](../../../tools/league/PORTING.md).

## Log

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
