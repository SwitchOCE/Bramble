# Lever sweep: preparation and measured checkpoints

No engine, economy, doubler, answer or tribe conclusions have been read from a lever sweep.
The full sweep has not started. The review restores a real strength gate; including
Hard in a maximum is not a test. Caps-only screening is permitted but has not run.

The library-pass regression is committed in `0aa053b`. The integrated review gate
passes 1,683 Godot tests and 28,926 assertions; all 57 Python checks pass. Committed
profiles are now default; v1, tuned data and the retired noisy tuner are in evidence.
Fields use equal per-line quotas, population weights and two-way board-cluster
intervals with explicit low-N warnings. Designed-only fields preserve full state.
Post–Start of Combat stats have a reader, and the curvature check rejects the
15%-per-round compounding positive control. JSON is the canonical metrics format.

The prior unequal-placement losses do not establish a finding about the pool.
The baseline placement ranking selects `line_hedgerow_tempo`; an independent
80-seed confirmation against `hard_field` covers both the selected-best claim and
its exploratory result. A separate 80-seed tribal-only mixture rerun is frozen.
See the [fixed confirmation and dose plan](../../../tools/sim/evidence/review-confirmation-plan.json).
No inference is made from incomplete confirmation samples. The protected lever-build
strength gate remains absent and cannot be opened by the field maximum.

The real 1/1 null is compared with an actual stat-identical reference body; it is
not an empty intervention. Both controls occur in captured fight inputs, normalized
results agree, and both arms replay exactly. See [real-null evidence](../../../tools/sim/evidence/real-null-result.json).
The fixed +1/+4/+16/+64 planted dose ladder is checkpointed separately for forced
and real-shop-pool modes. Recruit inventory records acquisition origin and same-IID
retention. Acquisition at fight boundaries is a lower bound, not a shop-offer buy rate.
See [completed experimental stages](../../../tools/sim/evidence/review-run-progress.json).

Remaining before protected reads: finish all dose cells; collect full fresh blind
strength samples; pass the separate lever-build comparison; implement controlled
answer/targeting, placement and RNG counterfactual readers before answer screening.
The resumable controller is implemented and unit-tested, but no full sweep plan
has been prepared or executed while those conditions remain unmet.

## Fresh blind comparison: Best line / independent hedgerow confirmation

`line_hedgerow_tempo` against `hard_field`; exactly 80 fresh independent seeds, 160 seat-swapped lobbies, four candidate and four incumbent seats per lobby. Both use blind rule placement. The two legs control seat roles; shop RNG remains unpaired. There was no interim strength inference, sample extension or policy change.

Mean placement gain **+0.8906**, two-sided 95% seed-cluster Student-t CI **[+0.6512, +1.1301]**. Candidate lobby wins 141/160; incumbent 19/160. The fixed superiority check **passes**. Runtime 367.3s (6.12 min), including job startup.

Hedgerow tempo was selected as the best eligible line by the independent 500-lobby placement ranking. This one predeclared confirmation tests that selection and its prior exploratory claim; it is not two independent successes.

[Full result and all 80 independent seed gains](../../../tools/sim/evidence/best-hedgerow-blind-result.json). The gameplay tree is unchanged from the passed 1,683-test gate; statistical plan and complete CSV validation passed.

### Frozen-mixture bookkeeping repair

The first 10-seed attempt produced player-writer errors because the comparison-kind
lookup omitted `tribal_mixture`. That attempt is excluded and preserved separately.
The repair `87bdb41` changes reporting only, with no gameplay or policy change.
The full gate passes 1,683 tests and 28,930 assertions. The original 80-seed plan,
profile hash and seeds 112001–112080 are unchanged; the complete comparison is rerun.

## Fresh blind comparison: Frozen tribal-only mixture

`tribal_mixture` against `hard_field`; exactly 80 fresh independent seeds, 160 seat-swapped lobbies, four candidate and four incumbent seats per lobby. Both use blind rule placement. The two legs control seat roles; shop RNG remains unpaired. There was no interim strength inference, sample extension or policy change.

Mean placement gain **-0.5094**, two-sided 95% seed-cluster Student-t CI **[-0.7283, -0.2905]**. Candidate lobby wins 94/160; incumbent 66/160. The fixed superiority check **fails**. Runtime 618.4s (10.31 min), including job startup.

Later steps are stopped under the instruction to report on failure. This result concerns the frozen policy under this comparison; it establishes no causal claim about the pool.

[Full result and all 80 independent seed gains](../../../tools/sim/evidence/frozen-mixture-blind-result.json). The gameplay tree is unchanged from the passed 1,683-test gate; statistical plan and complete CSV validation passed.

## Step 1 checkpoint: stop on the mixture failure

The best-line strength criterion passes on today's capped pool. The separately
requested frozen mixture does not: its entire placement-gain interval is below
zero. Although it wins 94 of 160 lobbies, its average placement is worse; the
predeclared placement metric is retained. The strongest-line success is not
used to conceal that mixture result. Neither comparison opens a lever-build
gate or establishes a causal explanation about card content.

No shop-pool dose, upset-split, caps-screening, lever-build strength or protected
sweep work was executed after this failure. Four forced doses remain complete;
their four shop-pool counterparts remain pending.

Execution note: the final mixture chunk's wrapper timed out on a global lock
before Godot started. Its empty output was excluded; only the unchanged final
ten seeds were retried under a harness-specific lock. All valid comparison data
retained the one-harness-Godot limit, 3 GB scope and timeout.

## Orchestrator ruling and outcome profiles

Known-answer test 2 passes: the preselected hedgerow-tempo line beats equal-blind
Hard by +0.890625 places. The mixture result does not block the next steps.
Its 94/160 lobby wins alongside worse mean placement are a high-variance profile,
not a plainly weaker one. The lever-build gate remains the real test of the
engine lines. No sample was extended and these outcome rates use existing data.

### best-hedgerow

| Line | Seats | First place | Top 4 | Seed clusters |
|---|---:|---:|---:|---:|
| hard_field | 640 | 2.97% | 41.41% | 80 |
| line_fast | 96 | 12.50% | 44.79% | 12 |
| line_hedgerow_tempo | 544 | 23.71% | 61.03% | 68 |

Complete seed-cluster intervals are in the linked result JSON; these breakdowns are descriptive.

### frozen-mixture

| Line | Seats | First place | Top 4 | Seed clusters |
|---|---:|---:|---:|---:|
| hard_field | 640 | 10.31% | 54.69% | 80 |
| line_birds_engine | 36 | 0.00% | 19.44% | 29 |
| line_birds_tempo | 41 | 7.32% | 36.59% | 37 |
| line_bog_engine | 33 | 0.00% | 18.18% | 29 |
| line_bog_tempo | 61 | 9.84% | 37.70% | 49 |
| line_fairies_engine | 29 | 10.34% | 27.59% | 26 |
| line_fairies_tempo | 50 | 6.00% | 46.00% | 40 |
| line_fast | 178 | 18.54% | 57.30% | 80 |
| line_hedgerow_engine | 23 | 34.78% | 56.52% | 23 |
| line_hedgerow_tempo | 27 | 59.26% | 74.07% | 27 |
| line_hunters_engine | 38 | 15.79% | 47.37% | 34 |
| line_hunters_tempo | 41 | 7.32% | 48.78% | 34 |
| line_oozes_engine | 39 | 10.26% | 28.21% | 33 |
| line_oozes_tempo | 44 | 20.45% | 54.55% | 40 |

Complete seed-cluster intervals are in the linked result JSON; these breakdowns are descriptive.

## Shop-pool dose ladder: complete

Each dose used its frozen eight fresh lobbies and a real tier-1 pool card, never
force-played. Lines bought and fielded the planted engine at every dose.

| Permanent gain/turn | Bought IIDs | Lobbies with owned card | Seats with owned card | Next-round retention |
|---|---:|---:|---:|---:|
| +1/+1 | 7 | 5/8 | 6/64 | 24/29 (82.8%) |
| +4/+4 | 6 | 4/8 | 5/64 | 81/81 (100.0%) |
| +16/+16 | 3 | 3/8 | 3/64 | 39/39 (100.0%) |
| +64/+64 | 4 | 3/8 | 4/64 | 59/59 (100.0%) |

No created-body acquisition was counted as a purchase. Retention follows the same
IID across owned locations; final observations are censored. These tiny unpaired
cells establish exposure and retention, not dose-specific buy probabilities or
tribe strength: full shop offers are not logged.

[Compact dose summary](../../../tools/sim/evidence/shop-pool-dose-summary.json);
[full forced and pool metrics/provenance](../../../tools/sim/evidence/review-run-progress.json).

## Controlled upset reader: screening complete

The frozen eight-pair, eight-seed, both-orientations diagnostic completed 128
controlled trials / 1,024 fights. Known controls detect a necessary answer, a
placement reversal and an isolated first-attack coin reversal; an answer firing
without changing the winner is a negative control. All 12 Godot controls pass.

| Overlapping flag | Baseline wins flagged / 128 |
|---|---:|
| answer_necessary | 0 |
| placement_necessary | 37 |
| first_attack_coin_necessary | 12 |
| other_rng_sensitive | 27 |
| unexplained | 75 |

These flags overlap and do not partition wins. No lower-stat test is used to
identify a cause. Placement means deterministic combat-layout sensitivity, not
optimal/legal recruit placement (timers are not archived). Joint answer masking
does not identify the winner's own card contribution. The sparse selected-board
bootstrap intervals are wide; these are reader checks, not population frequencies.

[Full diagnostic](../../../tools/sim/evidence/upset-diagnostic-result.json),
[frozen protocol](../../../tools/sim/evidence/upset-diagnostic-plan.json),
[per-trial outcomes](../../../tools/sim/evidence/upset-diagnostic-trials.jsonl.gz).
The full repository gate passes 1,695 tests and 29,016 assertions; the Python
reader and cloud-merge suites pass separately. The lever-build gate remains pending.

## Portable cloud shards and caps screening plan

The frozen [caps plan](../../../tools/sim/evidence/caps-screen-plan.json) and
[sealed manifest](../../../tools/sim/evidence/caps-screen-manifest.json) declare
150 fresh lobbies per configuration before execution: both caps disabled, size
caps alone disabled, and rate limits alone disabled. Seed blocks are
140001–140150, 141001–141150 and 142001–142150. Shop comparisons are unpaired.
Each configuration has three 50-lobby shards followed by six global 64-board
field rounds, with eight fights per orientation per pair. No protected lever
configuration has been run; the lever-build strength gate is still pending.

On a fresh checkout of `ideation/harness` containing this manifest, with the
pinned toolchain installed at `/opt/bramble/env.sh`, run one shard with:

```sh
python3 tools/sim/sweep_shards.py run tools/sim/evidence/caps-screen-manifest.json caps-both/lobbies-000 --out results/caps-both-000
```

Other lobby IDs replace `caps-both` with `caps-size` or `caps-rate`, and replace
`000` with `050` or `100`. Transfer each entire result directory into
`collected-lobbies`. Build the common field inputs only after collecting all
nine lobby shards:

```sh
python3 tools/sim/sweep_shards.py merge-lobbies tools/sim/evidence/caps-screen-manifest.json --results collected-lobbies --out field-inputs
python3 tools/sim/sweep_shards.py run tools/sim/evidence/caps-screen-manifest.json caps-both/field-r06 --inputs field-inputs --out results/caps-both-field-r06
python3 tools/sim/sweep_shards.py merge tools/sim/evidence/caps-screen-manifest.json --inputs field-inputs --results collected-results --out merged-caps
```

Run all six field IDs (`field-r06`, `08`, `10`, `12`, `14`, `16`) for each
configuration, then collect their whole directories together with the lobby
results in `collected-results`. Both merge commands use Python only. Fields are
sampled once from the complete 150-lobby configuration, equally stratified by
line with population weights; partial shard tournaments are not combined.
The final merge rebuilds metrics, offline damage replay and the report, rejecting
missing, duplicate or incompatible artifacts. Every result contains its own
JSON metadata and portable compressed captures with hashes.

Estimated time per 50-lobby shard is 2.2 minutes, plus fresh import (allow 30
seconds) and lock wait. A 64-board field-round shard runs 32,256 fights and takes
about 4.1 minutes plus startup. A complete configuration takes approximately 31
minutes serially before any head comparisons. These estimates use measured local
baseline costs of 2.5 seconds/lobby and 7.6 milliseconds/field fight; cloud timings
must be recorded from results. Each command performs its fresh import and run
under `/tmp/bramble-harness-godot.lock`, `MemoryMax=3G` and a hard timeout, with
only one harness Godot running per machine.

Protected configurations will use the same config × seed manifest protocol
once their real positive lever-build gate exists. Their optional best-line and
mixture comparisons have independent frozen seed chunks; optional upset shards
archive all 1,024 controlled fights. Missing gates fail closed. Cloud submissions
and pushes are left to the operator; this harness only runs the selected shard.

The first `caps-both/lobbies-000` attempt failed: caps-off play reached
`BotBurner.forecast`, which reads a mandatory `most` parameter that the uncapped
library removes. Repeated Godot script errors invalidate the attempt. Its exact
systemd scope was terminated; no shard result was admitted. The
[failed-attempt record](../../../tools/sim/evidence/caps-screen-failed-attempt.json)
keeps the log hash and frozen seeds. Screening is paused for a bot forecast fix
and regression test, followed by the gate and a source-refrozen rerun of the same
seeds. No caps-off conclusions or lever-build strength results exist yet.

### Uncapped-reader fix and resumed protocol

The Burner forecast now treats an absent/zero `most` as unbounded, exactly as the
recruit effect does. The [cap-reader audit](../../../tools/sim/evidence/cap-reader-audit.json)
found no other unsafe removed-field reader. Normal and golden forecasts agree
with actual uncapped burning, and a short all-line lobby with both switches off
passes. The full gate passes **1,697 tests / 29,037 assertions**. Sweep commands
also reject zero-exit Godot script-error logs. Fix commit: `ad96d30`.

The caps manifest is source-refrozen after this runtime fix; configurations,
budgets and seed blocks are unchanged. The failed attempt remains excluded.

The [lever-build strength plan](../../../tools/sim/evidence/lever-build-strength-plan.json)
is frozen before its runs: both combination builds, each comparing
`line_hedgerow_tempo` and the unchanged `tribal_mixture` against blind
`hard_field`, with 80 independent seeds / 160 swapped-seat lobbies per comparison.
Four disjoint fresh ranges start at 150001, 151001, 152001 and 153001. The original
pilot SD 1.227 implies roughly 80% power for +0.396 places and a planned 95%
half-width of 0.273; that does not guarantee a pass. No tuning or sample extension
is permitted. Primary strength requires the preselected best line's lower 95%
seed-cluster bound to be positive on both builds; mixture results remain explicit
separate diagnostics. These gate comparisons run only after caps screening.

All nine screening lobby shards completed cleanly in 1,286.5 seconds including
startup and validation. The global field-input bundle is sealed before the field
runs. For large coordinator merges, use disk-backed temporary storage: this
machine's `/tmp` quota was too small for decompressed captures. The successful
merge used `TMPDIR=$PWD/build/sim/caps-screen-fixed/tmp` after creating that
directory. This changes storage only; the frozen inputs and sample are unchanged.

The first global caps-off field-round shard also passes on a detached fresh
checkout with no prior Godot import cache: **32,256 fights in 211.1 seconds**
including import, validation and output archiving. Its result matches the sealed
manifest and field bundle and is admitted as the actual round-6 screening shard,
not an extra sample. Checkpoint: `21a9b82`. Remaining fields and then the frozen
strength comparisons continue sequentially in the bounded background pipeline.
