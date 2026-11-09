# Scale measurement harness

Track A of `docs/ideation/plan-scale-rework.md`. Capture, profiles, mixed lobbies and
weighted field fights, metrics, offline damage replay and planted-card checks are
implemented and verified. The fixed 500-lobby baseline is complete; see
`docs/ideation/evidence/harness-baseline.md`.

## Combat-version boundary: pre-wave-1 evidence

**Provenance rule:** every result above **“Wave-1 line files on the current combat
build”** below is pre-wave-1. Every measurement evidence file not named
`wave1-*` is pre-wave-1 too, regardless of legacy words such as “current”. This
includes line head-to-heads and fresh confirmations, `current-pool-strength-result`,
the upset diagnostic, analogue/boundary fields, the (d) 1.188 reading, and the
damage-replay smoke. Source code, plans and driver programs are not themselves
measurement results. These old results are not comparisons with step 5.

The **fixed baseline, caps screen, lever-build comparisons, first designed field,
and planted engine/real-null results below were measured on pre-wave-1 combat**.
They preserve their original source hashes and outcomes; rebuilding an offline
reader does not make their fights current. **These measurements are not
comparable with step 5's numbers.** This follows the orchestrator's
**“Harness follow-up 3”** calls in `docs/ideation/DECISIONS.md`.

Wave 1 replaced the pass 2 Birds and Fairies in the real game:
`GameConfig.full_game()` sets `pass3_content`, and a pool containing pass 3 cards
turns on `Pass3Combat` timing. Re-fighting an old board on the current library
therefore measures different combat. The new wave-1 line and real-card smoke
results carry their own current-build provenance, separate from these archives.

## What decides checkpoint 1

Per the owner's note 09i, the local `ideation/main` plan's **“What decides
checkpoint 1”** section and the orchestrator's **“Harness follow-up 2: calls”**
entry in `docs/ideation/DECISIONS.md`, only two criteria decide checkpoint 1:

1. **Logged progress moments:** every reward-lens tester names a moment where
   they felt stronger, checked against the game log. Most say the preset they
   prefer feels like progress.
2. **Pre-start median growth:** the lobby median grows **×1.3 or more per round
   from R8 to R14**, on the end-of-recruit board before Start of Combat effects.
   The deciding point estimate is `(median_R14 / median_R8) ** (1/6)`; its
   whole-seed bootstrap 95% interval is reported beside it, not used as an
   additional criterion (orchestrator, **“Harness follow-up 3”**, `DECISIONS.md`).

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
deferred to a later turn. A general strength-plan format remains deferred until
step 5 needs it. The wave-1 line loader and real-card designed inputs are tracked separately below.

## Existing baseline: the deciding growth reader (pre-wave-1)

On the original 500 seeds (81001–81500), the pre-start R8–R14 median is
**61 → 135**, or **×1.1416 per round [1.1402, 1.1461]**. Post-start beside it is
**64 → 157**, or **×1.1613 [1.1559, 1.1638]**. The pre-start point estimate is below
the existing ×1.3 criterion. This historical measurement is **pre-wave-1** and
is not comparable with step 5's measurements; it does not decide whether the
current build passes checkpoint 1, which also needs testers' logged moments.

`metrics.py` now writes `checkpoint_1_growth`, with both R8–R14 series and their
counts. Its deterministic 2,000-draw percentile bootstrap resamples all 500 whole
seeds (bootstrap seed 14531), retaining seats, legs and rounds together. Missing
or nonpositive endpoint medians are unsupported; post-start fallbacks are not
counted as post-start observations. Late medians contain surviving boards, so
this is a population-median curve, not a within-player compounding estimate.
`evidence/baseline-growth-pre-wave1.json` records the exact result and verified
original capture hashes. The synthetic JSONL capture test gives a known ×2
pre-start answer while its post-start series deliberately grows ×3.

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

`line_profiles.committed.json` was the pre-wave-1 default table; the current
default replaces its Birds/Fairies entries with `lines/*.json` (workflow below).
Version 1 and the tuned table are archived in `evidence/line_profiles.v1.json` and `evidence/line_profiles.tuned.json`.
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
retain inert defaults, preserving capped configuration on the original backend.
Exact baseline fight reproduction still requires its pre-wave-1 combat/library.
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
`evidence/real-null-dominance-result.json` is the corrected pre-wave-1 null
result. Weak engines and a do-something card falsely labelled null are explicit failing fixtures.

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


## Follow-up 2 integration and evidence maintenance

The merged wave-1 library is audited per shared native ability: all 16 Bird and
16 Fairy abilities are classified in `evidence/wave1-upset-audit.json`.
UpsetCombat retains its whole-library audit because summons, copies and stolen
text can reach definitions outside the starting board. Current friendly-largest,
positional-enemy and all-enemy effects are preserved; none of the audited wave-1
abilities selects the largest enemy. Unknown native IDs and unknown or missing
wave-1 ability names remain unsupported. This is a masking-integrity check, not
a checkpoint-1 gameplay criterion.

`field_fights.gd` now also accepts `per_seed` as its fourth argument. The default
aggregate mode keeps its original seed formula and output; per-seed mode keeps
the former designed driver's exact seeds and paired-orientation rows.
`designed_fights.gd` is removed. No new v3 concentration run is implied.

Large historical data is stored in `evidence/caps-screen-results.json.gz`,
`evidence/designed-screen-input.json.gz` and
`evidence/designed-screen-result.json.gz`. The original `.json` paths are small
archive pointers with compressed and original-data hashes. `evidence_io.read_json`
and `json_sha` read plain JSON, gzip JSON or a verified pointer; the latter hashes
the original uncompressed bytes. Frozen input/field checksums remain unchanged.

The formerly one-off real-null, baseline-curvature and lever-qualification
analyses are committed in `evidence/drivers/rebuild_followup_evidence.py`; exact
commands and data requirements are in that directory's README. Rebuilding those
artifacts is offline and preserves historical data and interpretation labels.

Merged-tree verification is recorded in `evidence/harness-followup2-verification.json`:
**1,846 tests / 30,367 assertions**, strict full gate under the shared lock and 3G
scope, plus **124 Python harness tests**. The 15 focused UpsetCombat tests pass.
The former and folded loops produce identical bytes on the merged backend for
both per-seed (768 fights) and aggregate (24 fights) fixtures. The pre-wave-1
archive differs in 35 winner-count rows under the merged backend, with unchanged
seeds/identities; both implementations reproduce those merged-backend results.
Historical outcomes remain untouched. No deferred line loader, real-card setups,
general strength-plan format or agency measure was started in this follow-up.

## Wave-1 line files on the current combat build

Default `LinePolicies` loads the sorted `tools/sim/lines/*.json` files. Each
entry declares its tribe and `base_strategy`; the base must exist and match that
tribe. Entries replace the historical profiles only for tribes present in the
files. Bog and Hunters files load through this same path without a code change.
Current Birds and Fairies use
`line_birds_homecoming`, `line_birds_tempo`, `line_fairies_ring` and
`line_fairies_court`; file keys without `line_` also resolve. The former engine
and tempo aliases resolve to their replacements. Explicit
`lines=res://tools/sim/line_profiles.committed.json` opts into the frozen table
for historical reproduction; old sweep plans still select their frozen table.
Current source fingerprints also include the designer JSON files.

The loader separates **rules the bot runs** from **advisory author notes**.
Unknown root keys still fail loudly. Executed nested structures (`climb`,
`switch_to` and flight limits) reject unknown sub-keys and invalid values;
recognized advisory values are opaque JSON, retained verbatim without checking
an invented instruction schema.

| Category | Keys | What runs |
|---|---|---|
| Executed root rules (`BOT_RULE_KEYS`) | `tribe`, `base_strategy`, `engine_flag` / `engine`, `buy_priority` / `priority`, `keep`, `engine_pieces`, `stayer_keep_rank`, `climb` / `climb_schedule`, `switch_to`, `fly_policy`, `save_threshold`, `save_until`, `priority_weight`, `tribe_weight`, `commit_round` | Normalize into the committed Hard profile. The first three `stayer_keep_rank` cards are the fallback retained pieces; the whole rank is not a placement policy. |
| Executed flight rules (`FLY_RULE_KEYS`) | `from_round`, `keep_home_min`, `max_away`, `allowed` | Flight start, home minimum, optional away limit and eligible card list. Ordinary Hard has no added default away cap. |
| Advisory root data (`ADVISORY_KEYS`) | `kind`, `max_copies`, `stayer_cap`, `harvest_supper_rounds`, `save_rule`, `great_lump_seat`, `golden_egg`, `placement`, `buy_only_if`, `place`, `stander_on_carry_slot`, `spells`, `thank`, `save`, `knobs`, `policy_version`, `triples`, `save_rounds`, `hold`, `sell_order`, `sell_first`, `heir`, `pelt_target`, `poach` | Load and retain only. The loader itself selects implementation version 2 for directory profiles; a source `policy_version` is not an override. |
| Advisory flight data (`FLY_ADVISORY_KEYS`) | `who`, `old_tern`, `omen_turn`, `elimination_guard` | Load and retain only; prose does not alter the shared adapters. |

Malformed executed card lists, duplicate cards/canonical names, unknown bases,
invalid flags, incomplete/non-increasing climb schedules and invalid numeric
weights/reserves fail validation. `from_round` must be a positive integer and
`keep_home_min` an integer from 1 to 7. A misspelt `max_away` fails.

Birds' R7 tempo-to-homecoming switch executes. Fairy Court's Annis slot is a
shared adapter selected by the line name `fairies_court`, not an interpreter of
`place` or `placement`. Hard has its own thank logic; the line file's `thank`
schedule is advisory. Shared adapters may make choices resembling other author
notes, but loading those notes neither enforces them nor proves line strength.
Next-climb savings use the shared affordability rule.

Tests exercise schema rejection, explicit historical opt-out, switch/flight
behavior, and a separate real eight-seat, three-round lobby for each of the four
wave-1 lines with all tribes available. These are integration checks, not new
gameplay bars or evidence of line superiority.

## Current-library real-card designed setups: small smoke only

`designed_setups.py real` writes eight explicit recipes: committed Homecoming
Birds and Ring Fairies at R8/R10/R12, plus R12 Granny Pot Luck and the
documented Whistlers Tern swap. Priorities and climb rounds come from the wave-1 line
files. Composition and authored stats/Ring budgets follow the pass-3 model
examples; these are constructed snapshots, not sampled player boards or evidence
that shops attain those states by those rounds. Fairies use real line cards in
place of the model's neutral placeholders. **Granny uses today's pass 2 Ooze
text, with three printed 1/1 Mice inside.** Its smoke rows are pass 2 Oozes;
regeneration and remeasurement wait for W2b, which supplies pass 3 Oozes.

`export_real_designed.gd` resolves the current `full_game` overlaid library and
serializes actual `PlayerState.combat_board()`, `combat_slots()` and
`RecruitRules.fight_rules()`. Bird away/Nest state, Fairy Ring counts/size and
Granny's three explicit held Mouse bodies are preserved. The R12 Homecoming
board has an occupied Nest. The corrected R12 Whistlers setup keeps that Nest,
all three away Birds, both Jays and the tribe bonus, replacing only the Tern.
Whistlers has 10/12 pre-start stats (9/11 plus the +1/+1 tribe bonus). Six
different Birds stand at home, so the omen is inactive. This is the doc
42%→96% ablation, not an all-home omen. Add the R15 everyone-home omen only
once an R15 board exists; none is authored here. Explicit budgets and
substitutions are recorded per recipe.
No card text or combat rule is copied into Python or changed by this generator.

The recorded field at `109d404` used the earlier, incorrect all-home Whistlers
setup. Its three rows marked † below are exploratory omen results, **withdrawn
as evidence for the doc's Tern-swap test**. The corrected input has not had a
new field run. The archived run is **eight boards, eight within-round pairs, eight
independent paired-orientation seeds per pair: 128 fights**, in **1.061 s** of
fight-loop time. Fixed blind layouts have no opponent-specific search. The table
shows strict wins for its left board and conservative 95% Hoeffding intervals;
the two orientations share one seed cluster. No draws occurred.

| Round | Left board | Right board | Left wins / 16 | Rate [95% interval] |
|---|---|---|---:|---|
| 8 | Homecoming | Ring Fairies | 14 | 87.5% [39.5%, 100%] |
| 10 | Homecoming | Ring Fairies | 4 | 25.0% [0%, 73.0%] |
| 12 | Homecoming | Ring Fairies | 2 | 12.5% [0%, 60.5%] |
| 12 | Homecoming | Granny (pass 2 Oozes) | 2 | 12.5% [0%, 60.5%] |
| 12 | Homecoming | Exploratory Whistlers omen† | 2 | 12.5% [0%, 60.5%] |
| 12 | Ring Fairies | Granny (pass 2 Oozes) | 3 | 18.8% [0%, 66.8%] |
| 12 | Ring Fairies | Exploratory Whistlers omen† | 13 | 81.2% [33.2%, 100%] |
| 12 | Granny (pass 2 Oozes) | Exploratory Whistlers omen† | 16 | 100% [52.0%, 100%] |

This demonstrates that current real-card inputs, reserves and wave-1 timing
fight through the harness; the wide conditional intervals and authored states
support no typical-strength or balance conclusion. There are no new gameplay
bars. No large field or new lobby baseline was run.

`evidence/wave1-real-smoke.json` records all counts, intervals, source hashes and
archive hashes. Exact input and paired-seed output bytes are in
`evidence/wave1-real-input.json.gz` and `evidence/wave1-real-pairs.jsonl.gz`.
`evidence/drivers/real_designed_smoke.py` validates complete pair/seed coverage
and rebuilds the small report offline; its README records generation/run commands.
Seven Python recipe tests and two core tests cover all eight current-card boards,
real fights, full input state, line-priority drift, tiers and authored assumptions.

At `109d404`, the full shared-lock, 3G `./scripts/check.sh` gate
passes **1,854 tests / 30,682 assertions**, with no risky/pending tests. The
standalone Python harness suite passes **134 tests**. Focused runs pass the six
wave-1 line tests (167 assertions), five existing line tests (248 assertions)
and two real-card tests (120 assertions).
`evidence/wave1-followup-verification.json` and its compressed gate log record
the command, counts and hashes. All Godot processes ran sequentially from this
worker, with bounded timeouts and the requested locks.

## Review 4: labels, corrected setup and the accounting run

`evidence/wave1-review4-smoke-qualifications.json` attaches the Whistlers
withdrawal and pass 2 Ooze labels to the immutable `109d404` archives. Counts and
original source hashes are retained; they are not a new measurement of the
corrected setup. No additional field is run for this fix-up.

Capture now stores the immutable resolved `starting_line` beside `current_line`
and the original roster's `assigned_line`. Field/metrics readers group scripted
lines by their starting label, including after Tempo switches to Homecoming.
Historical captures without these labels retain their old source-pinned names.
The accounting driver already used `assigned_line` throughout, so no lobbies
were rerun or moved from Tempo to Homecoming. Its result also records each
seat's starting and final lobby line from the CSV's `bot` and `strategy` fields;
final strategies never select the accounting groups.

The fixed wave-1 accounting run and same-dial paper reconciliation are reported
in `docs/ideation/evidence/wave1-accounting.md`, with seed intervals, phase
conversions, starting/final seat labels and the sole R12 0.5–2× criterion. Growth
is labelled preliminary and has no pass/fail role in this step. The plan and
execution source are frozen at `fa95a41`, before this review fix-up.

## Five-tribe shipped/checkpoint control

`wave1_baseline.py` accepts an explicit source tree/commit and preset. It probes
the native five-tribe draw, then seats the four committed wave-1 lines only when
both focus tribes are present, with four blind Hard seats. It freezes the same
eligible seed prefix for shipped caps-on and checkpoint caps-off settings.
`wave1-baseline-method.md` in `docs/ideation/evidence/` records the 320-seed sample,
counting convention, conditioned-population limit and reusable commands. The
combined report is `wave1-shipped-baseline.md` there. Only pre-start growth and
realized committed R12 size decide this triage step; other metrics are reported.
The human comparison uses two provided post-fight review-log examples, explicitly
labelled beside the pre-start script medians. Birds dials remain unchanged.

The user-approved simulation lock is `/tmp/bramble-harness-godot.lock`; imports,
probes and gates use `/tmp/bramble-godot.lock`. All retain a timeout and a 3 GB
systemd scope, with one Godot process at a time from this worker. The baseline
lock-only continuation retained its first 80 accepted shipped lobbies; the
revision and original plans/driver are archived in `evidence/wave1-baseline-lock-*`.

## Wave-1 rebase at a source-pinned commit

`evidence/drivers/wave1-rebase.sh` measures the exact authored B and C presets
of `d5b5b4f8` in separate `git archive` copies under `build/`, with shipped caps
on. Both use the same 320 eligible seeds as the five-tribe shipped control.
The only overrides are `pass3_preset=B` or `C`; resolved rates are captured and
reported rather than inferred from preset names. The separate skilled-Birds
check uses current 2× homecoming values, not this source's C values.

The report is `docs/ideation/evidence/wave1-rebase.md`. Existing pre-start growth
and realized committed R12 medians remain the deciding measurements. The other
statistics, including tribe drift and Bog rewards, introduce no additional bars.

The capture observer records all rounds, including zero-output card-present
seat-fights and real seats paired with ghosts. Successful native Peat King raises
and exact Peat Cutter gold carry operations are attributed to the physical card
and reconciled with session carry. Golden copies count as one instance; borrowed
abilities on other bodies are separate. Starting-board and later-entering card
presence are retained, including native simultaneous-death witnesses. Cutter gold
means credited next-turn gold, not spending or reaching the next turn. The
source-specific scripted check lives as `check_peat_counter.gd.txt` under
`evidence/drivers/` and runs as GDScript only inside the target archive, whose Bog
classes are absent from the current control tree. It checks known rewards,
zeroes, attribution, and unchanged fight results/events/carry and RNG states.

Non-committed assignments come from the native dealt strategy's `needs_tribes`.
Final tribe uses `BenchTribes.classify` on the last fight-start board: a unique
strict majority of non-token occupied slots, goldens once, neutral slots in the
denominator, away Birds and Belly contents excluded. Pinned build IDs can stay
unchanged while board composition changes. Not retaining the assigned majority,
a clear other-tribe majority, and no majority are reported separately; neutral,
multiple-tribe and unknown assignments are separate from the tribal denominator.

`evidence/drivers/finalize-wave1-rebase.py` verifies complete seed coverage,
unchanged source/driver hashes, raw and compressed captures, sufficient analysis
archives, the native counter check, and the passed full gate before writing the
final provenance record. Simulations hold `/tmp/bramble-harness-godot.lock`;
imports, scripted checks and gates hold `/tmp/bramble-godot.lock`. Our gate also
holds the harness lock to keep this worker's Godot processes sequential.

Historical source copies also receive the current line loader, registry, brains
and JSON profiles. Only the line-flight and court hooks are adapted in the
archived `BotPass3`; native Bog logic, BotBrain and the source's Queen/Cluricaun
mechanics are preserved. Each plan embeds the compatibility layer's per-file
before/source/destination hashes. The initial unconfigured-line attempt admitted
zero lobbies and is retained as rejected evidence, not measurement results.
`wave1-rebase-corrected.sh` reuses the native probes only after verifying unchanged
content and draw/config dependencies, then groups imports, the counter check and
all-four-line dispatch checks under one shared-lock acquisition. Actual lobbies
still use the harness lock.


## Per-line banned cards

`wave1_baseline.py prepare --banned-cards PATH.json` accepts a JSON object whose
keys are canonical **starting** line IDs and whose values are arrays of source
unit card IDs, for example:

```json
{"line_birds_tempo": ["mr_redbreast"]}
```

This is a scripted-policy constraint for keystone-removed lowroll trials. It does
not remove cards from the shared pool, alter card text, or change combat rules.
Other seats can buy the same card. The ban stays with its original starting line
through profile switches, including the Birds tempo switch at round seven. The
loader discovers currently available profiles and source cards, so future merged
line files require no named ban cases. Unknown lines, aliases instead of canonical
IDs, missing card IDs, duplicate cards, and malformed mappings fail validation in
Python before invoking Godot; the native entry point also checks the schema.
An omitted mapping preserves existing line and ordinary-bot decisions. Empty
per-line lists are allowed. The baseline's existing four-line roster and lobby
eligibility remain unchanged; providing a ban does not add a seat. A separate
active-roster check in Python preparation, run admission, capture parsing, and the
native invocation rejects every nonempty ban whose starting line is not actually
seated. Future merged measurements must explicitly seat a line before its ban
can apply; recognizing its source profile alone is insufficient.

Normal shop purchases and shop-to-Belly purchases reject banned cards regardless
of value. Discover choices keep their original option indexes while excluding
banned units. A hand containing a banned free grant is guarded before normal hand
play. Ownership audits include the board, hand, recursively held cards, away
birds, doorstep, and pending poached units. Persistent acquisition and play
observation also catches cards bought, swallowed, granted, discovered, summoned,
or tripled and then sold
by native helper paths between audits, including on-buy effects before play.

There is no legal decline/discard API for a forced all-banned choice or an
unavoidable grant. Those cases explicitly invalidate the entire trial. The runner
writes `ban_violation` evidence and exits unsuccessfully; it never silently
discards, resamples, or accepts a contaminated trial. Native specialized helpers
retain the source build's behavior: if one bypasses ordinary policy guards, the
ownership/play audit rejects its result rather than replacing native bot flow.
This rejection is a policy failure, not an outcome to exclude from an otherwise
accepted sample.

Frozen plans and chunk invocation plans retain `banned_cards`. Lobby records
repeat the mapping, every banned seat's all-round diagnostic contains `ban_audit`,
and R8–R14 combat-start captures and compact board analyses retain the same audit.
An accepted audit records the immutable starting line and exact source-ID list,
with empty `owned_banned`, `played_banned`, and `acquired_banned` arrays and an
empty `failure` string.
The Python reader verifies the policy and audit for every captured banned seat,
requires complete all-round seat coverage during execution, and rejects any
`ban_violation`, missing audit, policy mismatch, owned card, acquired card, or
played card. The report and its sufficient analysis archive preserve the frozen
mapping. Historical
source runs already overlay and hash both line brains and the policy loader in
`measurement-compatibility.json`; archived native combat/content and BotBrain
remain source-pinned.
