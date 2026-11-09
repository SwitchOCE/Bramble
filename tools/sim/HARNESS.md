# Scale measurement harness

Track A of `docs/ideation/plan-scale-rework.md`. Capture, profiles, mixed lobbies and
weighted field fights, metrics, offline damage replay and planted-card checks are
implemented and verified. The fixed 500-lobby baseline is complete; see
`docs/ideation/evidence/harness-baseline.md`.

## What decides checkpoint 1

Per the owner's note 09i, the local `ideation/main` plan's **“What decides
checkpoint 1”** section and the orchestrator's **“Harness follow-up 2: calls”**
entry in `docs/ideation/DECISIONS.md`, only two criteria decide checkpoint 1:

1. **Logged progress moments:** every reward-lens tester names a moment where
   they felt stronger, checked against the game log. Most say the preset they
   prefer feels like progress.
2. **Pre-start median growth:** the lobby median grows **×1.3 or more per round
   from R8 to R14**, on the end-of-recruit board before Start of Combat effects.

Growth and size for this decision read pre-start; post-start measurements are
reported beside them. A high total never fails a preset by itself. Tail size,
concentration, the designed carry/even comparison, snowballs, comebacks,
winner-to-runner-up ratios, game length, uncertain-fight share, tier-up strength,
card/tribe spread and strong-field rival size are reported, not pass/fail criteria.
An extreme tribe outlier, a line that wins whatever the player chooses, or runaway
snowballs in most lobbies prompts triage of the outlier dial; it does not add a
third checkpoint criterion.

Software correctness and harness known-answer tests still check measurement
integrity. Their pass/fail labels, and historical diagnostic flags below, do not
decide whether a gameplay preset passes checkpoint 1. In particular, the legacy
curvature ratio's 1.25 diagnostic bound is distinct from the checkpoint's ×1.3
per-round median-growth criterion.

The **“losses with no agency” measure and playtest tally are withdrawn**, not
deferred to a later turn. The remaining deferred work is the wave-1 line-table
loader, real-card designed setups, and a general strength-plan format when step 5
needs it. None of that work is started by this documentation change.

## Strength gate and attribution correction

The orchestrator previously relaxed (b) to including Hard in the field. That was
not an owner decision, and taking a maximum that includes Hard proves no strength.
Known answer (b) again requires a predeclared, fresh-seed head-to-head whose lower
95% seed-cluster confidence bound on placement gain is positive against
`hard_field`. Both sides use blind rule placement. Field rank is descriptive;
`hard_floor_passes` is now null and cannot open a sweep gate.

The historical losses below compared blind lines with scouting/search Hard.
They are confounded and support no claim about commitment or engines in today's
pool. The earlier "finding about the pool" interpretation is withdrawn. The fresh
preselected hedgerow confirmation passes, while the frozen equal-placement
mixture rerun fails; the completed results are below. Neither result identifies
card content as the causal explanation.
The completed best-policy lever-build comparisons support general reads.
Losing engine/tribe-line observations remain lower bounds from weak play, not
adverse content findings. Script strength is not a checkpoint-1 gameplay criterion.

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

## Committed profiles; knob tuning retired

`line_profiles.committed.json` is the default table. Version 1 and the tuned table
are archived in `evidence/line_profiles.v1.json` and `evidence/line_profiles.tuned.json`.
The tuner itself is archived as `evidence/tune_lines.retired.py`; it is not an active
workflow. Its feasible-budget validation was noise (+1.077 training places,
-0.154 held out, two validation games per arm), so it established no improvement.
No more knob tuning or sample extensions based on observed wins are allowed.

Profiles remain editable per-tribe priorities, climb schedules, save thresholds,
commitment and retained engine pieces over Hard's legal recruit actions. Field
lobbies retain two Hard anchors, two tempo, three engine and one shared-fast seat.
The historical tribal-only head composition is separately registered as
`tribal_mixture`: four tempo, three engine and one shared fast, with no Hard anchor.
Alternative tables require explicit `lines=<path>` and a frozen content hash.

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
6, 8, 10, 12, 14 and 16. Equal, availability-capped quotas include every represented line. Each board's weight is its line's population fraction divided by that
line's selected count, so rare lines forced into the sample do not distort the field.
The source capture hashes, population counts, quotas and weights are saved.

`field_fights.gd` runs every unordered pair in both orientations, eight independent
replicates per orientation by default. Six 64-board fields cost 193,536 fights, about
968 seconds at the prior 5 ms estimate. Same-unit slots, Rings, held contents, nests,
counters, side rules, tiers and hero effects are copied directly from captured sides.
No random or opponent-adapted layout is introduced. `field.py report` requires complete
round robins, reports each board's weighted field point rate, line-by-line matrix,
population weights and descriptive Hard comparisons; neither is a strength gate. A draw earns half a point for field ranking;
winner probability is conditional on a decisive fight, so all-draw pairs are not
labelled uncertain. Pair probabilities include Wilson intervals and raw counts.

The integration smoke sample is fixed before running: eight mixed lobbies (71001–71008),
16-board fields at rounds 6 and 8, two replicates per orientation (960 fights).
It checks integration, not balance. The later baseline keeps the planned 500 lobbies
and 64-board/six-round/eight-replicate field design.

## Metrics

`metrics.py <captures...> --players <players.csv...> --field <field-report.json>
--out <metrics.json> --markdown <report.md>` writes the complete machine-readable
metrics plus a shareable Markdown report. The checkpoint-1 growth and size series
must use each seat's pre-start, end-of-recruit board; the post-start series and
start-effect delta are reported beside it. Historical `metrics.py` outputs used
post–Start of Combat snapshots, including opponent-dependent changes: those
post-start numbers must not be relabelled as pre-start checkpoint evidence.
Active stats include Eggs; Belly/away/hand/doorstep reserves are reported
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
not a balance veto. The curvature diagnostic reports relative linear-fit error
and late/early growth increments on round 6–16 medians. Its known-answer control
distinguishes a 15%-per-round compounding curve; neither curvature flag nor rare
highrolls adds a checkpoint-1 pass/fail requirement.

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


## Historical planted engine check; original null arm invalid

The original null arm planted nothing. Its byte identity is historical evidence
only and does not establish a real-null-card check. The real 1/1 reference/null
protocol and exact-arm replays replace that gate below.

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
weighted point rate. The historical harness-sensitivity checks required 75% lobby
wins, all eight tails, and 80% field point rate. All passed under that historical
protocol (`evidence/planted-result.json`); these are not gameplay preset criteria.

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


## Fixed baseline execution

`evidence/baseline-plan.json` freezes 500 seeds (81001–81500), the committed
profile table, content hash and source commit before execution. Mixed-lobby
comparisons are unpaired. The 500 independent seeds target roughly ±4.4 percentage
points for a worst-case 95% outcome-rate interval; the report uses seed-cluster
bootstrap intervals. The field design is 64 boards at each of six rounds, eight
replicates per orientation (193,536 fights). Pair-level Wilson intervals make
the finite 16-trial precision visible. No interim outcomes change this plan.

Raw sequential shards live under `build/sim/harness-baseline/`;
`evidence/baseline-progress.json` records completed seed ranges, timings and hashes.
Resume remaining seeds with the frozen code/content/profile inputs, then sample
all captures together. Final baseline metrics and the evidence Markdown are written
after all 500 lobbies and all six fields complete.

The full baseline keeps the median linear finding (R²=0.9989) but disproves the literal
zero-tail prediction: 11/35,564 R6-16 board-rounds (0.031%), from seven seats in
seven lobbies, reached twice their round median. The historical strict no-2x
diagnostic was therefore false at 500 lobbies. The report and tail audit retain
those exceptions. Tail frequency is reported and does not pass or fail a preset.


## Orchestrator ruling and mechanics integration

The orchestrator accepts known answer (d): 11/35,564 R6-16 snapshots at twice the median
(0.031%) is a flat shape. The measured strict zero-tail diagnostic remains false
in the immutable baseline data; it is not a checkpoint-1 criterion. The current
pre-start (d) interpretation and interval are recorded below.

After the orchestrator merged shared mechanics in `eb571ba`, capture and reserves read the
session's private overlaid library. Standalone field fights and re-fights restore
the same overlay from captured config once and reuse it. Replay also defensively
normalizes an unconfigured library. Missing lever keys in older version-1 captures
retain inert defaults, so the original capped baseline remains reproducible.
The regression checks a 21-Attack uncapped Bridge Toad (4 Attack through the raw
capped library), exact event replay, field composition, selected lever presence
and reuse of the configured library. Full gate: 1,677 tests, 28,859 assertions.


## Review measurement contract

The current decision contract reads growth and size on the pre-start board and
reports post-start beside it. Historical reports that used post-start board size
and concentration retain their phase labels; `pre_start_stats` and
`start_effect_delta` expose the distinction. Missing post snapshots are explicitly
counted as fallback, never silently called post-start data. The legacy curvature
diagnostic uses relative linear RMSE <=0.05 and late/early growth increments within
25% for its flat flag. It is a measurement diagnostic, not a gameplay preset bar.
Tail shares and concentration remain descriptive.

Fields sample equally by line (availability-capped); population weights restore
real frequencies. Seeded two-way board bootstrap intervals resample each selected
board jointly across every opponent result. Selected counts and low-N warnings
are reported; extra combat trials cannot manufacture board-sample precision.
Lines are ranked by lobby placement with whole-seed bootstrap intervals.
Designed-only fields take complete board/slot/rule/hero/config inputs and explicit
line weights, separately from lobby fields; no missing hidden state is guessed.

JSON is the canonical metrics format. Redundant CSV metric/matrix/board exports
were removed; Markdown remains the human report. Historical baseline values and
field counts are unchanged. A real null now means an actual 1/1 with empty text
and mechanics, compared against an identical reference body. Definition IDs are
normalized only for cross-arm comparison; both arms must replay their own exact
raw events. Adding a body to an empty board is not a null intervention.

The fixed planted dose ladder (+1,+4,+16,+64 per turn) ran both forced-after-recruit
and real-shop-pool versions. Adoption and retention read actual units, not a
selected pool flag. Controlled cause-specific upset readers distinguish
answer/targeting, placement and RNG; event presence alone is not causal attribution.
These validate the evidence readers and add no checkpoint-1 gameplay criteria.


The earlier 32-board screening proposal is withdrawn after review. New screening
uses 64 equally stratified boards; even four or five boards per line is low N,
and the board-cluster intervals flag that limitation. More fight repetitions do
not fix a small board sample. Cause-specific counterfactual readers and the
separate lever-build comparisons have since completed. Their historical execution
conditions do not add checkpoint-1 gameplay criteria.


## Fresh blind confirmation results

The preselected best line and independent hedgerow confirmation are the same
predeclared hypothesis: `line_hedgerow_tempo` versus `hard_field`, seeds
110001–110080, 160 swapped-leg lobbies. It passes: +0.890625 places, 95%
seed-cluster Student-t CI [+0.651152,+1.130098], 141/160 lobby wins. This is one
independent confirmation, not two successes. Current-pool best-line (b) is passed.

The separately frozen original tribal mixture (4 tempo, 3 engine, 1 fast, no
Hard candidate anchor), seeds 112001–112080, fails: -0.509375 places, 95% CI
[-0.728265,-0.290485]. Both sides use blind rule placement. It wins 94/160
lobbies, but the prespecified metric is average placement gain; winner count
cannot replace it after results. The mixture is weaker on that metric under
this protocol. No causal claim about the pool is restored.

The reporting-label failure and a final queued-lock timeout were excluded before
valid results; the same frozen seeds were rerun, without policy changes or sample
extension. The final ten seeds used a harness-specific execution guard, retaining
one harness Godot with a 3 GB scope and timeout. The bookkeeping repair passed
the full gate (1,683 tests, 28,930 assertions). All complete samples validate.

Per the instruction to report on failure, execution stops before the shop-pool
doses, upset reader, caps screening, lever-build gate and protected sweeps.
The separate lever-build gate remains absent. Full results and all seed gains
are in `evidence/best-hedgerow-blind-result.json` and
`evidence/frozen-mixture-blind-result.json`.

The orchestrator accepts current-pool known-answer (b) and directs continuation:
the mixture's 94/160 first-place finishes plus worse mean placement describe high
variance, not plain weakness. Per-line first-place/top-four rates and seed-cluster
intervals were added from existing CSVs without any new simulation. The mixture
does not block the shop doses or screening; the separate lever-build gate remains.


## Follow-up: curvature phase, uncertainty and constructed setups

The orchestrator's current known-answer (d) call reads **pre-start**: **1.188
[1.125, 1.258] against 1.25**, a **borderline pass** recorded with its interval.
The interval crosses the diagnostic limit, so it is not a confident separation.
Post-start is reported beside it: **1.44 [1.37, 1.56]**. Using all 500 original seeds and 35,564 R6–16
board-rounds, 2,000 deterministic whole-seed bootstrap draws (seed 14519) give:

| Phase | Relative linear RMSE (95% interval) | Late/early growth ratio (95% interval) | Historical diagnostic flag |
|---|---|---|---|
| Pre-start, decision phase | 0.01289 [0.01119, 0.01678] | 1.1875 [1.1250, 1.2581] | true; borderline (d) pass |
| Post-start, reported alongside | 0.03028 [0.02637, 0.03482] | 1.4412 [1.3714, 1.5588] | false; descriptive only |

The pre-start interval crosses the unchanged 1.25 ratio limit. The post-start
point is outside that diagnostic ratio range while relative RMSE is <=0.05. These are
conditional surviving-board median curves; survival and opponent Start of Combat
effects can bend them. Neither reading proves within-player compounding.
`evidence/baseline-curvature.json` records medians, bootstrap details and original
capture hashes. Tests now fail independently when either curvature bar is dropped.

The real null is tested against the same three harness-sensitivity checks as the
engine: 0/8 round-six tails, 1/8 lobby wins and 45.13% field points are below their
thresholds; the engine exceeds all three. These are checks on the harness's
ability to detect a planted fault, not checkpoint-1 criteria. They replace the historical empty-null pass;
`evidence/real-null-dominance-result.json` is current. Weak engines and a
do-something card falsely labelled null are explicit failing fixtures.

The three exact historical run drivers are committed under `evidence/drivers/`,
with original hashes and API/version notes. Full dose detail is now
`evidence/review-run-progress.json.gz`; its compact JSON summary retains hashes
and calibration. Forced +1/+4/+16/+64 plants gave R6 medians 56/94.5/228.5/803.5
against population medians 46/48/48.5/45. The engine-dial step reads this as
dose-to-size calibration, not a dose-effect ranking from eight-lobby cells.

`line_tune` and the unused local sweep executor/CLI are deleted.
`sweep_shards.py` is the sole active sweep runner; `lever_sweep.py` retains shared
validation, analysis and report helpers only. Archived driver bytes reproduce
their recorded revisions and are not current execution entrypoints.

The orchestrator's follow-up decision opens general reads when the best line
passes both builds. Mixture losses do not block engine or tribe reads: losing
line observations are labelled lower bounds from weak play, never adverse
content results. See `evidence/lever-read-qualifications.json`. Designed neutral
boards with native keyword/answer mechanics are the second evidence source.

## Designed setup workflow and first field

`designed_setups.py` writes complete `field.py` designed inputs from round,
Attack+Health total, body count, carry/even distribution, native keyword grants
and an existing biggest-enemy or configurable percent answer. The first frozen
field covers R9/R12/R15 at typical and 1.4x totals; the API also supports R6.
All supports and the printed 3/3 answer consume the declared stat budget.

The first 192,000 fights completed in 975.7 seconds. Pair rates have conservative
95% Hoeffding intervals over 64 independent seeds; the two orientations share one
seed cluster. These intervals describe exact fixed setups and combat RNG, not a
population of player boards. Layouts are fixed and blind; keyword copies/gold
costs are not matched. All setups and per-seed trials are committed with hashes.

The owner-ratio analogue (three 500/500s versus one 2,100/2,100) has carry wins
100% [83%,100%] without an answer and 25% [8%,42%] when wide adds one 3/3
biggest-enemy answer. The actual 2.1B/2.1B request exceeds the engine's unchanged
1B-per-stat clamp; separate boundary inputs record requested and realized values.
See `docs/ideation/evidence/harness-followup.md` and `designed-screen.md` there
for all equal-total cells, qualifications, commands and field provenance.

## V3 concentration comparison: reported, not deciding

Per `docs/ideation/DECISIONS.md`, **“Harness follow-up 2: calls”** on local
`ideation/main`, the v3 definition is pinned before a run:

- Both boards have equal pre-start total stats.
- The carry has exactly one holder-keyword copy: Shield, Damage Reduction or Cleave.
- The even board holds exactly one biggest-enemy answer: the strongest a player
  could hold at R12 in the pool being measured, at that preset's values.
- Report the no-answer arm alongside it for context.

This is a descriptive concentration comparison, not a checkpoint-1 pass/fail bar.
The first 192,000-fight field did not predeclare a gameplay bar and does not pass
or fail one retrospectively. No v3 run is made by recording this definition.
