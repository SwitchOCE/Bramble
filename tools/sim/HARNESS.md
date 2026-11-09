# Scale measurement harness

Track A of `docs/ideation/plan-scale-rework.md`. Capture, profiles, mixed lobbies and
weighted field fights, metrics, offline damage replay and planted-card checks are
implemented and verified. The fixed 500-lobby baseline is next.

## Current decision: include Hard, preserve the finding

The owner superseded the old superiority gate after the fixed-sample checks below.
Hard is now the tempo anchor alongside tribal and engine lines. Known answer (b) is
**the field's strongest line is at least as strong as Hard**, secured by including
Hard itself under the common blind field-placement rule. No more tuning or
superiority runs on today's pool are required. Ordinary `hard` remains the original
registered brain; `hard_field` changes only its final placement hook to be blind,
retaining Hard's recruit, pressure, hero and purchasing decisions.

The tribal mixture lost 0.735 places to Hard (95% CI [-1.029, -0.441], 100 lobbies).
On today's flat pool, commitment and engine investment losing to tempo is partly a
finding about the pool, not grounds for indefinite script tuning. This does not prove
that every script is optimal. Re-run the fixed-sample comparison on the caps-off,
engine-dial lever build once mechanics has been merged externally. Continued losses
there would implicate the scripts. Historical failed gates below are retained as evidence.

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
Eight replicates per orientation raise the final design to 193,536 field fights.
The eight-lobby mixed smoke measured 2.61 seconds/lobby and 6.69 milliseconds/fight;
on this machine the updated estimate is 22 minutes for lobbies plus 22 minutes
for the fields. The baseline spans clean checkpoints under the 50-minute turn limit.

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
deals two Hard, two tempo, three engine and one shared fast-tier seat, shuffling
seat order by seed. Tribal lines use the available-tribe build deal. Neutral builds can
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

## Fixed-sample confirmation and the tribal mixture

`evidence/line-fast-confirm-plan.json` freezes version 1's shared fast line at the
recorded profile SHA. The 12-seed pilot SD was 1.227 places. Detecting its observed
+0.396-place gain with normal-approximation 80% power at two-sided alpha .05 requires
76 independent seed clusters, rounded up to 80 (160 lobbies, seeds 51001–51080).
The projected 95% half-width is 0.273 places and prior runtime predicts 23.2 minutes.
The run has no sample extension or mid-run policy changes. A power calculation does
not guarantee a positive result.

The completed confirmation **rejected** version one: -0.294 places, 95% interval
[-0.568, -0.020], despite 91 wins to Hard's 69. It took 1,425.2 seconds. The observed
seed SD was 1.231, close to the planning value. The full 160-lobby CSV and result are
retained as `evidence/line-fast-confirm.players.csv` and `line-fast-confirm.json`.
The candidate therefore needs improvement; its earlier positive pilot estimate was
not promoted or extended until it passed.

`size_line_check.py` repeats that calculation from an archived pilot CSV and an
explicit minimum detectable effect, records the profile SHA, and refuses to overwrite
an existing plan. `check_lines.py --plan <plan.json>` rejects incomplete seed sets,
even when their provisional gain is positive. `--profiles <table.json>` adds
exploratory per-line/tribe seat-controlled gains with seed-cluster robust intervals;
these diagnostics do not create additional promotion tests.

`candidate=line_mixture` in the existing head-to-head suite covers the all-line
lobby's exact family roster over each seed's two swapped legs: four tempo, three
engine and one shared fast seat. Each seat receives the normal available-tribe deal
in both legs. This tests the family mixture that will generate the field; a win by
the shared fast line alone does not validate the tribal profiles. The mixture alias
is a composition and is only accepted for head-to-head, not as a single bot.

## Separate committed-line candidate

`line_profiles.committed.json` opts into `CommittedLineBrain` with `policy_version=2`.
It starts from the original untuned priority lists and schedules; it does not use the
two-game sweep's selected knobs. Version 1 and ordinary Hard are preserved.

- Priority bonuses add to Hard's original card bonuses, rather than replacing them.
- From round four with at least three bodies, purchases commit to the declared tribe
  or an explicitly listed splash. Neutral fillers can still fill empty spaces.
- Named `engine_pieces` protect the best on-board copy of each component from ordinary
  replacement and the carrier-retirement bypass. Weaker duplicates can still upgrade.
- A healthy board can climb before its scheduled round when it can pay and still buy
  a body, or when leftover money can climb and the shop offers no worthwhile purchase.
- At low Health, a climb must leave enough money for a body even when scheduled.

These changes address code-level omissions, not tuning choices inferred from small
samples. Fixtures cover prior preservation, commitment, engine retention, affordable
climbs, insufficient cash and the unchanged version-one factory. Version two remains
an unvalidated candidate until its pre-sized mixture check beats Hard. That comparison
is planned for a minimum detectable gain of half a place: the pilot seed SD calls for
48 clusters, rounded to 50 (100 lobbies, fresh seeds 61001–61050), with a projected
95% half-width of 0.349. The shared-line pilot variance is a planning approximation
for the mixture, not a guarantee. No new knob sweep selects this candidate.

## Committed-mixture result

The fixed 50-seed / 100-lobby check (61001–61050) measured -0.735 places, 95% interval [-1.029, -0.441]. The candidate won 54 lobbies; Hard won 46. Active simulation took 825.9 seconds across the two declared shards.

**Did not pass the strength gate.** The sample does not establish superiority. Field fights remain unstarted; another code-driven policy revision is needed before using these lines as the field.

The frozen plan is `evidence/line-mixture-confirm-plan.json`; the complete CSV and result (including per-line/tribe diagnostics) are `line-mixture-confirm.players.csv` and `line-mixture-confirm.json` in the same directory. Profile SHA and full planned seed set were checked before computing the promotion decision.


## Field fights

The current eight-seat generator has two `hard_field`, two tribal-tempo, three engine
and one shared-fast seat, shuffled by seed. Existing neutral deals can also resolve
to the shared line. Every seat fights, takes real damage, consumes pool copies and
uses real heroes. All final placements are chosen blind before real combat; captured
inputs are replayed without any field-adapted rearrangement.

`field.py sample` streams captures, rejects duplicate/non-blind boards and ghosts,
and keeps per-round/per-line reservoirs. It selects exactly 64 boards at rounds
6, 8, 10, 12, 14 and 16. Proportional quotas include every represented line and require
a Hard anchor. Each board's weight is its line's population fraction divided by that
line's selected count, so rare lines forced into the sample do not distort the field.
The source capture hashes, population counts, quotas and weights are saved.

`field_fights.gd` runs every unordered pair in both orientations, eight independent
replicates per orientation by default. Six 64-board fields cost 193,536 fights, about
968 seconds at the prior 5 ms estimate. Same-unit slots, Rings, held contents, nests,
counters, side rules, tiers and hero effects are copied directly from captured sides.
No random or opponent-adapted layout is introduced. `field.py report` requires complete
round robins, reports each board's weighted field point rate, line-by-line matrix,
population weights and the Hard floor. A draw earns half a point for field ranking;
winner probability is conditional on a decisive fight, so all-draw pairs are not
labelled uncertain. Pair probabilities include Wilson intervals and raw counts.

The integration smoke sample is fixed before running: eight mixed lobbies (71001–71008),
16-board fields at rounds 6 and 8, two replicates per orientation (960 fights).
It checks integration, not balance. The later baseline keeps the planned 500 lobbies
and 64-board/six-round/eight-replicate field design.

## Metrics

`metrics.py <captures...> --players <players.csv...> --field <field-report.json>
--out <metrics.json> --markdown <report.md>` writes the complete machine-readable
metrics plus a shareable Markdown report. Own-board growth uses each seat's preceding
combat-start snapshot after initial auras, before opponent-dependent Start of Combat
effects. Active stats include Eggs; Belly/away/hand/doorstep reserves are reported
separately. Ratios exclude a zero denominator. Gold efficiency includes purchases,
refreshes, spells and climbs, with both cumulative stats/gold and incremental
growth/gold. Concentration is the largest active body's share.

Tier-arrival ratios use the player's own median active unit from before the tier-up.
The first newly fielded body of each newly unlocked tier is recorded, including a
body arriving on a later round. Both its printed size and its post-aura size are
reported. This is a board-arrival measure, not a claim that the body was bought in
that round. Unobserved arrivals do not become zeroes.

Round p50/p90/p99, 2x-median shares and growth distributions are reported pooled and
within each named line. Late-round populations are survivors only. p99 is descriptive,
not a balance veto. A historical-shape diagnostic checks a linear fit (R2 >= .95) to
round 6–16 medians and counts boards at twice their round median; it reports what the
data say and does not flatten real highrolls to match the old audit.

Outcome reports distinguish the round-eight **stat** leader from the public Health
leader; tied leaders split credit. Comebacks are top-two finishes among boards below
the pooled round-eight median, with a within-lobby-median version alongside. Confidence
intervals resample whole seed clusters (2,000 fixed bootstrap draws), not seats.
Winner length is the winner's final round. Round 10–14 pair uncertainty is reported
both unweighted and with field population weights. All-draw pairs do not count as
uncertain winners. A stricter share requires the full pair Wilson interval to lie
inside 20–80%, making finite-replicate uncertainty visible.

## Offline damage replay

`replay_damage.py <captures...> --variants <variants.json> --out <replay.json>` runs
entirely in Python. The variant file maps names to config overrides. Examples include
`{"health50":{"starting_health":50}}` or a new `base_damage_by_turn` table and
`survivor_scale`. An original-rules scenario is always included. Starting Health
shifts each seat by the change in base Health, preserving its logged hero offset.
Legacy variants also support survivor tier weights (`tier_damage_by_tier`), the
survivor divisor, damage floors/caps, toll and Last Stand.

Each capture now logs live post-fight Health/Armor and the pre-fight alive count.
Replay computes damage from actual survivors (own starting bodies in v0.5; surviving
tiers excluding Eggs in legacy), verifies original damage and post-fight state,
then re-scores Health and elimination rounds. Observed recruit-phase Health/Armor
changes are carried forward. Two fresh smoke lobbies (72001–72002) reproduced all
228 live post-state observations and both winners exactly. Python known answers
exercise Armor, Last Stand, lower starting Health, slower tables, legacy tier damage,
caps/toll, incomplete rounds and corrupted live state.

This is a **fixed historical schedule replay**, not an unobserved new game. Once an
elimination changes, different future pairings, buys and pool depletion are unknown.
Output records the first divergence and labels later results conditional. A seat
surviving beyond its logged fights loses coverage; multiple survivors at log end
remain unresolved rather than receiving invented wins or game lengths. Original
rules are checked against the complete logged trajectory. Files are streamed one
lobby at a time to keep the 500-lobby replay bounded in memory.


## Planted engine and null checks

`plant_growth=256` registers a test-only, pool-excluded 1/1 body and puts it on
seat zero before recruitment. Its normal End-of-Turn effect permanently adds
256/256 per turn. No card content or combat rules change. `plant_growth=0` is a
literal no-op: it registers no definition and consumes no RNG. Captures archive
the synthetic definition, and both exact re-fight and field fights restore it.

The fixed plan in `evidence/planted-plan.json` used eight control lobbies, eight
null lobbies with identical seeds, and eight broken-engine lobbies. Null outputs
(players, rounds, cards and full fight inputs/results) matched control byte for
byte. The broken seat won 8/8 lobbies; every planted round-six board was at least
twice its own lobby median. A 32-board mixed control/broken round-six field,
two replicates in each orientation (1,984 fights), gave the planted line a 97.0%
weighted point rate. The predeclared gates were 75% lobby wins, all eight tails,
and 80% field point rate. All passed (`evidence/planted-result.json`).

The three lobby arms took 19.5s, 19.8s and 19.2s; field fights took 13.329s.
All 469 captured broken-engine fights replayed exactly in 4.903s. Unit checks
verify pool exclusion, zero intervention, and permanent growth through real
End-of-Turn processing. These establish that the harness detects an engine
when one exists; they do not establish current tribal-script strength on the
future mechanics build.

The independent eight-lobby current-pool smoke (71001–71008) also matched the
historical shape check: R6–16 median linear R²=0.9957, zero boards at twice the
round median (`evidence/flat-shape-smoke.json`). The fixed 500-lobby baseline
will evaluate the same diagnostic at the planned sample size.
