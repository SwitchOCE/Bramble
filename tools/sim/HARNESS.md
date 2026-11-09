# Scale measurement harness

Track A of `docs/ideation/plan-scale-rework.md`. This file records completed checkpoints;
line policies, field fights, damage replay and the baseline are still to follow.

## Combat capture

`bench.gd capture=on` writes `<out>.fights.jsonl`; `trace=on` also enables it. The capture
observer sits in `GameSession._fight`, after the real combat inputs are assembled through
the live/ghost path and immediately before any session carry, damage or event changes.
It has no cost beyond the validity check when unused.

Each row contains:

- `seed`, `leg`, `suite`, `round`, `players` to identify a lobby fight.
- `input`: version 1, full combat boards (including held specs and counters), slots,
  hero effects, side rules, tiers, player ids, round, damage cap and all config values.
  Both random streams' seeds and states are decimal strings to preserve 64-bit values in JSON.
- `combat_start`: active units' views from the combat-start event, after the initial aura
  calculation and before Start of Combat triggers. Units are labelled `board` or `egg`;
  reserve bodies are labelled `belly`, `away`, `hand`, `doorstep` or `poached_pending`.
  Reserve bodies have no board aura or Ring until they enter. Away birds beside Eggs are
  reserves, not a second active body. Ghosts have fight reserves, not a recruit hand.
- `active_stats` and `largest_share` in each side's snapshot: Attack + Health of active
  bodies, including Eggs, and the largest active body's fraction. Reserves are excluded.
- `result`: the raw in-game combat outcome and permanent carries; `events_sha256` checks
  every event without storing the full event log. Integer-valued JSON floats normalize to
  integers for signatures. `survivors` gives final survivor uids on both sides; `survivor_units` records each
  survivor's tier, Attack, Health and whether it is an own starting body, so alternative
  damage tables need no combat run;
  `damage_performance` gives the v0.5 own-starting-survivor count (summons excluded).
- `outcome`: the session's final outcome, after toll, Early Spoils and Last Stand handling.
  Live snapshots also include pre-damage Health, Armor, Last Stand usage and gold spent.

Exact replay requires the same card library and combat code. Captures preserve inputs,
not a bundled historical rules engine. `refight.gd` verifies raw combat fields and the
complete event signature; session Health/damage bookkeeping is logged separately.

Run sequentially, sourcing the environment before every Godot command:

```sh
source /opt/bramble/env.sh
mkdir -p build/sim/harness-capture
systemd-run --user --scope -p MemoryMax=3G timeout 180 godot --headless \
  -s res://tools/sim/bench.gd -- suite=spread games=2 first_seed=891 \
  capture=on out=build/sim/harness-capture/smoke
systemd-run --user --scope -p MemoryMax=3G timeout 180 godot --headless \
  -s res://tools/sim/refight.gd -- build/sim/harness-capture/smoke.fights.jsonl
```

The smoke sample is fixed at two lobbies before running, for capture integration only;
it makes no statistical claim. Tests in `tests/core/test_fight_capture.gd` check a full
lobby including ghosts, a deliberate hidden-state fixture, JSON transport, detached
snapshots and tampered event signatures.

## Sampling constraint

Comparisons are **unpaired**. A shared seed is a reproducibility key, not matched shop
luck: different buys/refreshes consume the stream and pool differently. Tuning and
evaluation must use disjoint seeds and declare sample sizes before execution. The
planned baseline is 500 all-line lobbies and a 64-board field at each of rounds 6, 8,
10, 12, 14 and 16. At the prior measured costs of 12.5 seconds per Hard lobby and
5 milliseconds per fight, 500 lobbies cost about 104 minutes; six round robins with
two orientations cost 24,192 fights, about 121 seconds before any replication.
The baseline therefore spans clean checkpoints under the 50-minute turn limit.
