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

At the 9 November 09:52 UTC execution checkpoint, all 450 screening lobbies and 4/18 field-round shards are validated and committed. The bounded background pipeline continues with the remaining fields, metrics merge, and then all four frozen lever-build comparisons. Strength results remain pending; no protected sweep has started. The [execution ledger](../../../tools/sim/evidence/scale-run-execution.json) and [shard checkpoint](../../../tools/sim/evidence/caps-screen-progress.json) record progress.


## Completed caps-off screening

# Lever sweep

Predeclared real-shop, real-pool mixed lobbies; no forced synthetic units. Stats measure feel; placements and repeated blind field fights measure outcomes. Late rounds contain survivors only. No results change budgets, policies or overrides.

Source `b926e0b08a507e7f648c395074d85b2c03beb06d`; fingerprint `45e78b48ac6dac91b9210528d34a6c0d9cb00e816cdeccd2d440f038b38e9b70`.

[Frozen plan](../../../build/sim/caps-screen-fixed/merged/plan.json) · [Input provenance](../../../build/sim/caps-screen-fixed/merged/plan.lock.json) · [Atomic execution checkpoint](../../../build/sim/caps-screen-fixed/merged/status.json)

Controller state: **complete**. Updated 2026-11-09T10:59:47.387964+00:00.

| Configuration | Completed stages | State | Measurements |
|---|---:|---|---|
| caps-both | 11/11 | complete | [Full metrics JSON](../../../build/sim/caps-screen-fixed/merged/stages/caps-both/analysis/metrics.json) |
| caps-size | 11/11 | complete | [Full metrics JSON](../../../build/sim/caps-screen-fixed/merged/stages/caps-size/analysis/metrics.json) |
| caps-rate | 11/11 | complete | [Full metrics JSON](../../../build/sim/caps-screen-fixed/merged/stages/caps-rate/analysis/metrics.json) |

## caps-both

150 independent lobbies, seeds 140001-140150; 64 weighted boards at each of R6/8/10/12/14/16, eight replicates per orientation.

[Complete pooled/within-line metrics and tier arrivals](../../../build/sim/caps-screen-fixed/merged/stages/caps-both/analysis/metrics.json) · [Board point rates, line weights and win matrices](../../../build/sim/caps-screen-fixed/merged/stages/caps-both/analysis/field-report.json) · [Content exposure/adoption](../../../build/sim/caps-screen-fixed/merged/stages/caps-both/analysis/adoption.json)

| Round | Boards | S1 p50 | p90 | p99 | Share >=2x median | Largest-share p50 | Stats/gold p50 | Growth/gold p50 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1200 | 0.000 | 5.000 | 7.000 | n/a | 0.000 | 0.000 | n/a |
| 10 | 1184 | 99.000 | 146.000 | 238.530 | 0.018 | 0.250 | 1.122 | 1.267 |
| 11 | 1098 | 115.000 | 173.000 | 374.240 | 0.029 | 0.250 | 1.158 | 1.077 |
| 12 | 975 | 133.000 | 200.600 | 609.700 | 0.038 | 0.256 | 1.197 | 1.185 |
| 13 | 816 | 152.000 | 235.000 | 1154.800 | 0.054 | 0.262 | 1.233 | 1.200 |
| 14 | 649 | 172.000 | 299.800 | 2209.840 | 0.077 | 0.265 | 1.244 | 1.091 |
| 15 | 549 | 188.000 | 407.400 | 4083.440 | 0.104 | 0.268 | 1.294 | 1.200 |
| 16 | 483 | 209.000 | 526.400 | 8133.100 | 0.114 | 0.266 | 1.312 | 1.273 |
| 17 | 380 | 229.500 | 1403.400 | 17546.140 | 0.137 | 0.271 | 1.343 | 1.400 |
| 18 | 293 | 255.000 | 3192.400 | 35200.080 | 0.147 | 0.271 | 1.358 | 1.333 |
| 19 | 176 | 264.500 | 5550.000 | 34232.500 | 0.153 | 0.281 | 1.365 | 1.317 |
| 2 | 1200 | 10.000 | 14.000 | 19.000 | 0.007 | 0.538 | 1.250 | 1.286 |
| 20 | 82 | 272.000 | 421.900 | 49328.430 | 0.085 | 0.272 | 1.295 | 1.000 |
| 21 | 19 | 292.000 | 3471.600 | 28901.140 | 0.105 | 0.274 | 1.265 | 0.900 |
| 22 | 4 | 344.500 | 44485.600 | 61511.260 | 0.250 | 0.328 | 1.499 | 0.954 |
| 3 | 1200 | 17.000 | 25.000 | 35.000 | 0.015 | 0.409 | 1.143 | 1.111 |
| 4 | 1200 | 26.000 | 37.000 | 53.000 | 0.013 | 0.321 | 1.250 | 1.500 |
| 5 | 1200 | 35.000 | 51.100 | 70.010 | 0.012 | 0.286 | 1.190 | 1.091 |
| 6 | 1200 | 44.000 | 67.000 | 89.000 | 0.014 | 0.276 | 1.139 | 1.000 |
| 7 | 1200 | 55.000 | 81.000 | 106.000 | 0.006 | 0.268 | 1.111 | 0.923 |
| 8 | 1200 | 67.000 | 99.000 | 139.000 | 0.013 | 0.263 | 1.067 | 0.833 |
| 9 | 1200 | 81.000 | 122.000 | 184.090 | 0.015 | 0.253 | 1.074 | 1.000 |

| Tier | Arrivals | Arrival ratio p50/p90/p99 | Printed ratio p50/p90/p99 |
|---|---:|---|---|
| 2 | 967 | 1.250 / 2.000 / 3.200 | 1.111 / 1.500 / 2.000 |
| 3 | 924 | 1.444 / 2.333 / 3.667 | 1.333 / 1.750 / 2.333 |
| 4 | 931 | 1.571 / 2.571 / 4.000 | 1.286 / 1.800 / 3.000 |
| 5 | 1014 | 1.667 / 2.850 / 4.774 | 1.375 / 2.200 / 3.333 |
| 6 | 770 | 1.463 / 2.950 / 4.621 | 1.077 / 2.333 / 3.200 |

| Outcome | Rate / p50 | 95% interval / p90,p99 |
|---|---:|---|
| field_uncertainty_r10_14: all_draw_pair_share | 0.000 | — |
| field_uncertainty_r10_14: pairs | 6048.000 | — |
| field_uncertainty_r10_14: share_20_80 | 0.164 | — |
| field_uncertainty_r10_14: share_ci_wholly_20_80 | 0.046 | — |
| field_uncertainty_r10_14: weighted_share_20_80 | 0.170 | — |
| r8_below_lobby_median_top2 | 0.110 | 0.089 / 0.132 |
| r8_below_pooled_median_top2 | 0.108 | 0.089 / 0.128 |
| r8_health_leader_wins | 0.177 | 0.123 / 0.240 |
| r8_stat_leader_wins | 0.270 | 0.200 / 0.340 |
| Winner final round | 19.000 | 20.000, 21.510 |

R8 tied leaders split credit. Outcome intervals bootstrap whole independent seeds. Comeback rows use below-pooled and below-lobby R8 medians. Pair uncertainty excludes all-draw pairs.

| Lever ID | Active board-rounds | Owned seats/lobbies | Unique IIDs all/bought/created/unknown | Next-round retained/eligible | Final card rows | Unused observed |
|---|---:|---:|---:|---:|---:|---|

Prefer recruit inventory for owned bodies and distinct observed IIDs; IIDs are namespaced by seed and leg. Origin=bought separates bought from created bodies. Legacy combat views have unknown origin and unavailable acquisition counts. Only captured acquisitions are observable; full roll offers are not logged, so no conditional buy rate is estimated.

Same IID in the next consecutive own round's inventory, across any owned location; last observations, gaps and missing inventory are censored. This is body retention, including transformations.

## caps-size

150 independent lobbies, seeds 141001-141150; 64 weighted boards at each of R6/8/10/12/14/16, eight replicates per orientation.

[Complete pooled/within-line metrics and tier arrivals](../../../build/sim/caps-screen-fixed/merged/stages/caps-size/analysis/metrics.json) · [Board point rates, line weights and win matrices](../../../build/sim/caps-screen-fixed/merged/stages/caps-size/analysis/field-report.json) · [Content exposure/adoption](../../../build/sim/caps-screen-fixed/merged/stages/caps-size/analysis/adoption.json)

| Round | Boards | S1 p50 | p90 | p99 | Share >=2x median | Largest-share p50 | Stats/gold p50 | Growth/gold p50 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1200 | 0.000 | 5.000 | 7.000 | n/a | 0.000 | 0.000 | n/a |
| 10 | 1181 | 96.000 | 133.000 | 172.000 | 0.005 | 0.246 | 1.118 | 1.083 |
| 11 | 1108 | 111.000 | 154.300 | 205.510 | 0.004 | 0.247 | 1.121 | 0.923 |
| 12 | 993 | 127.000 | 175.000 | 235.320 | 0.002 | 0.248 | 1.153 | 1.000 |
| 13 | 831 | 143.000 | 204.000 | 263.700 | 0.002 | 0.247 | 1.178 | 1.000 |
| 14 | 641 | 162.000 | 232.000 | 303.800 | 0.003 | 0.253 | 1.217 | 1.000 |
| 15 | 548 | 179.000 | 254.600 | 330.000 | 0.000 | 0.254 | 1.237 | 1.000 |
| 16 | 486 | 192.000 | 280.500 | 352.450 | 0.002 | 0.252 | 1.229 | 0.873 |
| 17 | 403 | 215.000 | 305.800 | 375.820 | 0.000 | 0.249 | 1.297 | 1.200 |
| 18 | 315 | 229.000 | 330.600 | 404.440 | 0.000 | 0.244 | 1.286 | 0.800 |
| 19 | 219 | 238.000 | 350.200 | 439.920 | 0.000 | 0.249 | 1.258 | 0.875 |
| 2 | 1200 | 10.000 | 14.000 | 19.000 | 0.009 | 0.556 | 1.250 | 1.310 |
| 20 | 116 | 246.000 | 349.500 | 436.900 | 0.000 | 0.253 | 1.268 | 1.000 |
| 21 | 46 | 271.000 | 384.500 | 421.300 | 0.000 | 0.253 | 1.292 | 0.899 |
| 22 | 4 | 328.000 | 416.700 | 425.070 | 0.000 | 0.245 | 1.397 | 0.733 |
| 3 | 1200 | 17.000 | 25.100 | 34.000 | 0.016 | 0.400 | 1.148 | 1.111 |
| 4 | 1200 | 26.000 | 37.000 | 53.010 | 0.016 | 0.333 | 1.229 | 1.500 |
| 5 | 1200 | 35.000 | 51.000 | 67.020 | 0.008 | 0.289 | 1.185 | 1.100 |
| 6 | 1200 | 44.000 | 65.100 | 83.010 | 0.002 | 0.275 | 1.132 | 0.920 |
| 7 | 1200 | 55.000 | 79.100 | 101.000 | 0.002 | 0.269 | 1.137 | 1.000 |
| 8 | 1200 | 65.000 | 96.000 | 124.010 | 0.005 | 0.259 | 1.073 | 0.778 |
| 9 | 1200 | 80.000 | 115.000 | 144.010 | 0.003 | 0.253 | 1.081 | 1.000 |

| Tier | Arrivals | Arrival ratio p50/p90/p99 | Printed ratio p50/p90/p99 |
|---|---:|---|---|
| 2 | 947 | 1.250 / 2.000 / 3.090 | 1.111 / 1.500 / 2.000 |
| 3 | 915 | 1.500 / 2.333 / 3.667 | 1.333 / 1.750 / 2.333 |
| 4 | 932 | 1.536 / 2.500 / 4.000 | 1.286 / 1.800 / 2.972 |
| 5 | 1028 | 1.667 / 3.000 / 4.744 | 1.333 / 2.200 / 3.627 |
| 6 | 797 | 1.400 / 2.909 / 5.401 | 1.000 / 2.305 / 4.000 |

| Outcome | Rate / p50 | 95% interval / p90,p99 |
|---|---:|---|
| field_uncertainty_r10_14: all_draw_pair_share | 0.000 | — |
| field_uncertainty_r10_14: pairs | 6048.000 | — |
| field_uncertainty_r10_14: share_20_80 | 0.183 | — |
| field_uncertainty_r10_14: share_ci_wholly_20_80 | 0.053 | — |
| field_uncertainty_r10_14: weighted_share_20_80 | 0.192 | — |
| r8_below_lobby_median_top2 | 0.121 | 0.097 / 0.144 |
| r8_below_pooled_median_top2 | 0.116 | 0.094 / 0.139 |
| r8_health_leader_wins | 0.253 | 0.190 / 0.320 |
| r8_stat_leader_wins | 0.247 | 0.180 / 0.313 |
| Winner final round | 19.000 | 21.000, 21.510 |

R8 tied leaders split credit. Outcome intervals bootstrap whole independent seeds. Comeback rows use below-pooled and below-lobby R8 medians. Pair uncertainty excludes all-draw pairs.

| Lever ID | Active board-rounds | Owned seats/lobbies | Unique IIDs all/bought/created/unknown | Next-round retained/eligible | Final card rows | Unused observed |
|---|---:|---:|---:|---:|---:|---|

Prefer recruit inventory for owned bodies and distinct observed IIDs; IIDs are namespaced by seed and leg. Origin=bought separates bought from created bodies. Legacy combat views have unknown origin and unavailable acquisition counts. Only captured acquisitions are observable; full roll offers are not logged, so no conditional buy rate is estimated.

Same IID in the next consecutive own round's inventory, across any owned location; last observations, gaps and missing inventory are censored. This is body retention, including transformations.

## caps-rate

150 independent lobbies, seeds 142001-142150; 64 weighted boards at each of R6/8/10/12/14/16, eight replicates per orientation.

[Complete pooled/within-line metrics and tier arrivals](../../../build/sim/caps-screen-fixed/merged/stages/caps-rate/analysis/metrics.json) · [Board point rates, line weights and win matrices](../../../build/sim/caps-screen-fixed/merged/stages/caps-rate/analysis/field-report.json) · [Content exposure/adoption](../../../build/sim/caps-screen-fixed/merged/stages/caps-rate/analysis/adoption.json)

| Round | Boards | S1 p50 | p90 | p99 | Share >=2x median | Largest-share p50 | Stats/gold p50 | Growth/gold p50 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1200 | 0.000 | 5.000 | 7.000 | n/a | 0.000 | 0.000 | n/a |
| 10 | 1179 | 97.000 | 139.200 | 180.880 | 0.006 | 0.244 | 1.095 | 1.143 |
| 11 | 1105 | 111.000 | 162.000 | 216.000 | 0.009 | 0.244 | 1.117 | 1.000 |
| 12 | 987 | 129.000 | 182.000 | 261.140 | 0.012 | 0.246 | 1.129 | 0.926 |
| 13 | 821 | 144.000 | 210.000 | 305.200 | 0.015 | 0.248 | 1.152 | 1.077 |
| 14 | 650 | 163.000 | 249.000 | 350.120 | 0.017 | 0.250 | 1.198 | 1.200 |
| 15 | 557 | 181.000 | 271.400 | 356.960 | 0.011 | 0.251 | 1.209 | 1.000 |
| 16 | 495 | 198.000 | 299.600 | 438.600 | 0.012 | 0.249 | 1.248 | 1.091 |
| 17 | 405 | 218.000 | 327.200 | 457.360 | 0.017 | 0.246 | 1.274 | 1.091 |
| 18 | 326 | 232.500 | 348.500 | 483.250 | 0.015 | 0.243 | 1.283 | 0.800 |
| 19 | 203 | 250.000 | 355.800 | 457.600 | 0.005 | 0.250 | 1.295 | 0.947 |
| 2 | 1200 | 10.000 | 14.000 | 20.000 | 0.015 | 0.538 | 1.250 | 1.333 |
| 20 | 101 | 252.000 | 353.000 | 484.000 | 0.010 | 0.258 | 1.241 | 0.818 |
| 21 | 31 | 249.000 | 348.000 | 447.900 | 0.000 | 0.256 | 1.218 | 0.400 |
| 22 | 4 | 311.500 | 336.800 | 340.580 | 0.000 | 0.206 | 1.372 | 1.383 |
| 3 | 1200 | 17.000 | 25.000 | 34.000 | 0.014 | 0.400 | 1.160 | 1.143 |
| 4 | 1200 | 26.000 | 37.000 | 53.000 | 0.013 | 0.320 | 1.250 | 1.500 |
| 5 | 1200 | 35.000 | 51.000 | 69.000 | 0.007 | 0.282 | 1.188 | 1.000 |
| 6 | 1200 | 44.000 | 65.000 | 87.010 | 0.010 | 0.268 | 1.128 | 0.900 |
| 7 | 1200 | 55.000 | 80.000 | 103.010 | 0.002 | 0.259 | 1.117 | 0.917 |
| 8 | 1200 | 66.000 | 97.000 | 121.010 | 0.003 | 0.254 | 1.059 | 0.800 |
| 9 | 1199 | 80.000 | 117.000 | 150.020 | 0.003 | 0.247 | 1.061 | 1.000 |

| Tier | Arrivals | Arrival ratio p50/p90/p99 | Printed ratio p50/p90/p99 |
|---|---:|---|---|
| 2 | 974 | 1.250 / 2.000 / 3.000 | 1.111 / 1.600 / 2.000 |
| 3 | 898 | 1.429 / 2.333 / 4.000 | 1.273 / 1.750 / 2.343 |
| 4 | 929 | 1.571 / 2.500 / 4.536 | 1.286 / 1.800 / 2.975 |
| 5 | 1029 | 1.667 / 2.878 / 4.953 | 1.333 / 2.200 / 3.667 |
| 6 | 796 | 1.434 / 3.000 / 5.000 | 1.000 / 2.182 / 3.500 |

| Outcome | Rate / p50 | 95% interval / p90,p99 |
|---|---:|---|
| field_uncertainty_r10_14: all_draw_pair_share | 0.000 | — |
| field_uncertainty_r10_14: pairs | 6048.000 | — |
| field_uncertainty_r10_14: share_20_80 | 0.169 | — |
| field_uncertainty_r10_14: share_ci_wholly_20_80 | 0.045 | — |
| field_uncertainty_r10_14: weighted_share_20_80 | 0.164 | — |
| r8_below_lobby_median_top2 | 0.138 | 0.114 / 0.163 |
| r8_below_pooled_median_top2 | 0.129 | 0.105 / 0.152 |
| r8_health_leader_wins | 0.150 | 0.100 / 0.203 |
| r8_stat_leader_wins | 0.177 | 0.120 / 0.240 |
| Winner final round | 19.000 | 20.100, 21.510 |

R8 tied leaders split credit. Outcome intervals bootstrap whole independent seeds. Comeback rows use below-pooled and below-lobby R8 medians. Pair uncertainty excludes all-draw pairs.

| Lever ID | Active board-rounds | Owned seats/lobbies | Unique IIDs all/bought/created/unknown | Next-round retained/eligible | Final card rows | Unused observed |
|---|---:|---:|---:|---:|---:|---|

Prefer recruit inventory for owned bodies and distinct observed IIDs; IIDs are namespaced by seed and leg. Origin=bought separates bought from created bodies. Legacy combat views have unknown origin and unavailable acquisition counts. Only captured acquisitions are observable; full roll offers are not logged, so no conditional buy rate is estimated.

Same IID in the next consecutive own round's inventory, across any owned location; last observations, gaps and missing inventory are censored. This is body retention, including transformations.

## Portable cloud shards

Run these commands from a checkout with the frozen simulation/helper bytes. The documented cloud toolchain setup must already have installed Godot 4.7.2, Python and /opt/bramble/env.sh. The runner sources that environment, verifies the Godot version and imports the fresh checkout before its simulation. CLOUD_HARNESS_ROOT may name another checkout; no home-directory variable is reassigned.

```bash
python3 tools/sim/sweep_shards.py plan PLAN.json --out manifest.json
python3 tools/sim/sweep_shards.py run manifest.json caps-both/lobbies-000 --out lobby-shard
python3 tools/sim/sweep_shards.py merge-lobbies manifest.json --results collected-lobbies --out field-inputs
python3 tools/sim/sweep_shards.py run manifest.json caps-both/field-r06 --inputs field-inputs --out field-shard
python3 tools/sim/sweep_shards.py merge manifest.json --inputs field-inputs --results collected-results --out merged
```

Run each frozen lobby ID once, then transfer its whole result directory. merge-lobbies requires every configuration's three 50-seed shards before sampling one global equal-line field per round from all 150 lobbies. Transfer manifest.json and the whole field-inputs directory to each fresh field worker. Run every frozen field/head ID once and collect all result directories, including the original lobby results, for the final merge. Both merge commands are pure Python. Individual seed-shard fields cannot be combined into the required global round robin.

Measured baseline timing basis: 2.5 seconds/lobby and 0.0076 seconds/field fight. A 50-lobby shard is about 2.2 minutes plus any fresh import/lock wait; one 64-board round has 32,256 fights and is about 4.1 minutes plus startup (32 boards: 7,936 fights, about 1 minute). A complete 64-board configuration is about 31 minutes before separate head comparisons; a fresh import may add up to 30 seconds. These are planning estimates, not cloud measurements. Each manifest shard records its estimate and hard timeout; import, lock wait and simulation share that bound. Head estimates are listed per frozen chunk. One Godot process runs at a time per worker under /tmp/bramble-harness-godot.lock, systemd MemoryMax=3G and timeout.

The manifest freezes all lobby seeds, field sampling seed, pair seed derivation in the hashed field driver, and eight replicates per orientation. Result JSON and deterministic gzip captures are portable across absolute checkout paths. Hash/completeness/configuration/profile/gate checks reject missing, duplicate, changed or incompatible artifacts; they do not attest remote execution. Protected runs require the real positive gate file in each checkout, and the final report retains its exact content/hash. Missing gates never count as passes.

