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
| Skeleton (ids, mechanic trait, serializer, random streams) | not started |
| Combat | not started |
| Recruit | not started |
| Mechanics per tribe (badger, locust, mouse, pigeon, thorn) | not started |
| Records match, GDScript to Rust (1,000 games) | reference records being made |
| Records match, Rust to GDScript (50 games) | not started |
| Fights match (100,000 mutated fights) | not started |
| Planted bugs caught | not started |
| Speed-up measured | not started |
| Harness built | not started |
| Gates (runtime, scope review) | not started |

## Where things are

- Reference records from the GDScript engine: `/home/alex/league/records/gd/c0..c2/` (seeds
  1-1000, FlowBot and RandomBot seats, made by `scripts/records.sh`).
- Porting rules for workers: [tools/league/PORTING.md](../../../tools/league/PORTING.md).

## Log

- 18 Nov, 14:15: pinned `dev`, made `league/engine`, started the 1,000 GDScript reference games
  (3 processes).

## Rulings and calls made without the owner

(none yet)
