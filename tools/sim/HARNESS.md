# Scale measurement harness

Track A of `docs/ideation/plan-scale-rework.md`. Combat capture, line profiles and real
all-line lobbies are implemented. Field fights, damage replay, planted-card checks and
the baseline are still to follow. Profile implementation is distinct from passing the
strength check below.

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
- `after_start_effects`: a second active-unit snapshot after all Start of Combat effects,
  before the first attack (or before combat ends if those effects clear a board). This
  includes hero buffs and Lollop, but also enemy effects, so it must be reported separately
  from the initial board's stats. The tools-only `CaptureCombat` subclass observes the
  existing phase boundary; replay uses ordinary `Combat` and verifies identical events.
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

## Line policies and tuning

`line_profiles.json` defines two committed profiles per tribe, plus `line_fast`. Each
entry has an ordered card priority list, a five-step climb schedule, a save threshold
and ending round, a committed tribe, an engine flag and priority/tribe weights. The
base strategy supplies Hard's existing spell, hero and row preferences. These are
initial scripted lines, not a claim to elite human play.

`LineBrain` inherits Hard's legal recruit actions and live text/economy logic. It fixes
the build, follows the declared climb rounds and uses the engine flag for an economy
opening and saving. Placements use Hard's blind rule placer. No field opponent can
influence the captured layout. A specifically requested tribe absent from a lobby
falls back to `line_fast`; that fallback is visible in the logged resolved line.

`BenchSuites.REGISTRY` contains every profile and two family aliases. `suite=lines`
deals seven tempo/engine seats through the normal available-tribe build deal, plus
one shared fast-tier seat, shuffling seat order by seed. Existing neutral builds can
also resolve to the shared line. Real pool depletion, hero offers, combat, permanent
carries, damage and eliminations all use `GameSession`.

An alternate JSON table can be supplied with `lines=/absolute/path/profiles.json`.
Capture snapshots log the resolved profile id. `suite=line_tune candidate=<id>` tests
one focus seat against seven line seats. The tuner uses a private candidate alias, so
changing its knobs leaves all opponents' original profiles intact.

```sh
timeout 1200 python3 tools/sim/tune_lines.py \
  --out build/sim/harness-lines/tuning --trials 2 --games-per-trial 2 \
  --validation-games 2 --run
```

The command writes its plan before starting Godot. It sources `/opt/bramble/env.sh`
for each invocation, runs sequentially in a 3 GB systemd scope and puts a timeout on
each job. Without `--run` it only writes the plan. That example allocates 20 lobbies
per tribe (two profiles each), ten for the shared profile, 130 total. Training and
validation samples use disjoint, monotonically allocated seed ranges. The objective
is focus-seat mean placement. Reports retain training gains, held-out gains, intervals,
fallback counts, time and every candidate's exact knob table. At two games per arm,
held-out intervals are explicitly exploratory, not a strength gate.
`--resume` reuses complete profile reports only after checking the declared plan,
original/selected profile data and seed ranges. Incomplete profiles are run again.

The first complete sweep used those 130 lobbies, seeds 31001–31130, and 427.6 seconds
of active job time. Mean training gain was +1.077 places across the 13 profiles;
held-out gain was -0.154 places. By tribe (mean across its two profiles):

| Tribe | Training gain | Held-out gain |
|---|---:|---:|
| Birds | +3.00 | +1.50 |
| Bog folk | +0.25 | -2.25 |
| Fairies | +2.25 | -3.25 |
| Hedgerow folk | +1.00 | +1.50 |
| Hunters | +0.50 | 0.00 |
| Oozes | 0.00 | +1.75 |
| Shared | 0.00 | -0.50 |

The tiny validation samples do not establish improvement. Full per-profile samples,
wide intervals and chosen knobs are in `evidence/line-tuning.json`; the selected
table is retained as `line_profiles.tuned.json`. The default table remains separate.
The shared profile selected its original revised settings, so its fresh head-to-head
also evaluates the default revised shared line.

## Head-to-head strength check

Use the existing `suite=head_to_head candidate=<line> incumbent=hard` bench suite,
then run `python3 tools/sim/check_lines.py <prefix>.players.csv --out <result>.json`.
The checker requires complete swapped legs and a positive lower 95% Student-t bound
on mean placement gain, with the two legs clustered by independent seed. It returns
nonzero if the line fails. The legacy bench strategy-by-strategy report assumes
unchanged strategy labels; use this checker when comparing a new line to Hard.

The initial `line_fast` pilot was pre-sized at 12 seeds / 24 lobbies (21001–21012),
took 213.5 seconds and **failed**: mean gain -0.021 places, 95% interval
[-0.665, +0.623], despite winning 15 of the 24 lobbies. Its exact profile and result
are retained in `evidence/line-fast-pilot.json`. The revised shared profile focuses
its priority bonus on the known tier-six payoff instead of retaining unrelated aura
cards. Its evaluation must use fresh seeds after tuning.

That fresh check used the predeclared 12 seeds / 24 lobbies (41001–41012), took
208.7 seconds and also **failed the strength gate**: mean gain +0.396 places, 95%
interval [-0.384, +1.175], 14 wins against Hard's ten. The plan is retained in
`evidence/line-head-plan.json`, the result in `evidence/line-fast-fresh.json`.
Both pilot and fresh `.players.csv` files are retained beside those reports; the
statistical check can be repeated directly from them without Godot.
The point estimate improved, but the sample does not establish superiority. A larger
pre-sized evaluation or a stronger candidate is required before claiming known
answer (b); field fights and the baseline have not started at this checkpoint.

`tests/core/test_line_policies.gd` checks the profile roster, card ids, independence
from Hard's knowledge, eligible tribe assignments and a complete live line lobby.
`python3 -m unittest discover -s tests/sim` checks the statistical checker against
planted positive/null placement data, rejects incomplete/duplicate legs, and checks
that knob generation leaves the reference profiles untouched.
