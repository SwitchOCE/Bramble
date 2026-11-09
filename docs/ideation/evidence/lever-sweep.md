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
