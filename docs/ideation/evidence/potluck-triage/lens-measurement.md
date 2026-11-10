# Lens: measurement. Is Pot Luck's x1.251 real or an artefact?

Data: `docs/ideation/evidence/wave2b/oozes-final.jsonl` and `oozes-before-pot-fix.jsonl` (32 lobbies each, same seeds), in `/home/alex/code/Bramble-ideation-balance` (ideation/wave2b, a2f4295f). Growth = (stat R_b / stat R_a)^(1/(b-a)). Bootstrap: 5,000 resamples of lobbies, percentile 95%.

Scripts (same folder): `measure.py` (all variants, bootstrap, run 1 vs final), `extra.py` (dead-ranked-lowest medians, mean and geometric mean), `runs_diff.py` (per-lobby comparison of the two runs). Full output: `measure.out`.

## Verdict

The shortfall is real, not something the measurement made up. Every variant puts Pot Luck below x1.3, and every variant that counts eliminated seats puts it lower still. The two lines' 95% intervals overlap, and Pot Luck's R8-R14 interval reaches past 1.3 (top 1.353). On its own the bar result is a lean, not a proof. But the paired engine-minus-Pot-Luck difference over the same lobbies is above zero at R8-R14 (0.003 to 0.210), and the paper predicts about x1.5 for Pot Luck. So the gap is with the design, not with the bar.

## Growth by variant (final run)

| Variant | Engine | Pot Luck |
|---|---|---|
| Reported: median of survivors R8->R14, active | 1.369 (n32->21) | 1.251 (n32->12) |
| Median of survivors R8->R12 | 1.317 | 1.228 |
| Median of survivors R8->R13 | 1.360 | 1.232 |
| Median of survivors R8->R10 / R10->R12 | 1.330 / 1.304 | 1.197 / 1.260 |
| Paired per seat, alive at R14 (median) | 1.332 (n21) | 1.230 (n12) |
| Paired per seat, alive at R12 | 1.306 (n26) | 1.225 (n23) |
| Paired per seat, alive at R13 | 1.317 (n22) | 1.232 (n18) |
| R14-survivor cohort only, medians | 1.344 (R8 97 -> R14 572) | 1.222 (R8 101 -> R14 337) |
| Last observation carried forward to R14, all 32 seats | 1.277 (per-seat 1.289) | 1.165 (per-seat 1.171) |
| Median of all 32, eliminated ranked lowest, R8->R12 | 1.307 | 1.194 |
| Same, R8->R13 | 1.274 | 1.129 |
| Same, R14 | 1.269 | median seat is eliminated (20 of 32 dead) |
| Mean of survivors R8->R14 / geometric mean | 1.352 / 1.353 | 1.297 / 1.273 |
| **Including Bellies**, median of survivors R8->R14 | 1.348 | 1.252 |
| Including Bellies, R8->R12 | 1.315 | 1.258 |
| Including Bellies, paired alive at R14 | 1.324 | 1.216 |
| Including Bellies, LOCF all seats | 1.270 | 1.178 |

Medians by round, active (incl. Bellies), alive n:

| Round | Engine | Pot Luck |
|---|---|---|
| R8 | 87 (95.5) n32 | 88 (99) n32 |
| R10 | 154 (164) n31 | 126 (158) n31 |
| R12 | 262 (285.5) n26 | 200 (248) n23 |
| R13 | 405 (419.5) n22 | 249.5 (306.5) n18 |
| R14 | 572 (572) n21 | 337 (381) n12 |
| Median Belly stats R12 / R14 | 16 / 29 | 32 / 48 |

## Hypotheses

**(a) Survivor bias makes Pot Luck look slow. Ruled out.** If it did, the seats Pot Luck kept would grow faster than the eliminated ones, and counting dead seats would raise the figure. It does the opposite. Only survivors: 1.230 paired, 1.222 for the R14 cohort. All 32 seats: 1.165-1.171 with last observation carried forward. With eliminated seats ranked lowest, Pot Luck's median seat is dead by R14. The R8-R12 window, where 23 of 32 are still alive, gives 1.228. Survivor selection inflates both lines and hides part of Pot Luck's gap. The x1.251 is, if anything, flattering.

**(b) Leaving out Bellies understates Pot Luck. Ruled out as the cause of failing the bar; minor on level.** Pot Luck holds about twice the engine's Belly stats (R12 median 32 vs 16). Counting them lifts its R12 level from 200 to 248 and its R8-R12 growth from 1.228 to 1.258. Its R8-R14 growth stays at 1.252, because the Bellies are already counted at R8 (99 vs 88). Including Bellies, engine-minus-Pot Luck R12 narrows from 62 to 37.5, and Pot Luck still fails x1.3 in every variant.

**(c) The difference is noise at n=32. Partly kept.** Survivor-median R8->R14 95% intervals: engine 1.284-1.403, Pot Luck 1.147-1.353. They overlap, and Pot Luck's interval reaches past 1.3. R8->R12: engine 1.275-1.394, Pot Luck 1.184-1.335. Including Bellies R8->R14: Pot Luck 1.153-1.326. Paired over surviving seats, Pot Luck's interval is 1.131-1.272, and carrying all seats forward gives 1.124-1.226. Both of those sit wholly under 1.3. Paired difference over the same lobbies (engine minus Pot Luck): R8->R14 +0.003 to +0.210 (just above zero), R8->R12 -0.026 to +0.179 (crosses zero). In short: the reported survivor-median figure can't settle the pass/fail on its own, but the survivor-robust views can, and they agree Pot Luck is below 1.3. Whether Pot Luck is slower than engine at R8-R12 is not settled at this sample size.

**(d) The paper itself predicts Pot Luck under x1.3. Ruled out.** `oozes-pass3.md` line 510, board totals with insides: P = 64 / 209 / 924 / 2,695 at R6 / R9 / R12 / R15. That is x1.64 a round R9->R12, x1.43 R12->R15, and x1.53 R9->R15. Line B: x1.55, x1.64, x1.59. Line 378 (× target means) gives P 1.26× at R8 and 1.04× at R15. Against target means interpolated geometrically from 53/194/759/2,600, that is about 159 -> 2,704, or x1.50 a round R8->R15. The paper expects Pot Luck to slow late (R12->R15 x1.43 vs B's x1.64) but stay well above 1.3, and to lead the carry at R12 (924 vs 835). The bots realise 0.63 of the paper at R8 (99 / ~159, with Bellies) and 0.27 at R12 (248 / 924). Most of the shortfall opens after R8, between R8 and R12.

**(e) The bot fixes changed Pot Luck. Kept for play, ruled out for the figure.** Same seeds in both runs. The fixes changed 18 of 32 Pot Luck lobbies (first divergence R4-R14, mostly R7-R9). The aggregates barely moved: R8->R14 x1.254 -> x1.251; R12 median 200 -> 200 (n23 both); R14 341.5 -> 337 (n12 both); paired R14 1.231 -> 1.230; bootstrap 1.184-1.331 -> 1.147-1.353. The engine moved more (x1.325 -> x1.369, R14 470 -> 572; 15 of 32 lobbies changed). So the Bubbles/Frumenty burial fix did not lift Pot Luck's growth.

## Side observations (for other lenses; not tested here)

- The measured Pot Luck board isn't the paper's R12 board. Of 23 R12 survivors, these cards appear: Wee Wobbly 15, Posset 13, Frumenty 10, Soup 9, Elder 9, Granny 7, Pie 5, Bubble 5, Nell 5, Moss 3. The paper board is Pie, Granny, Moss, Elder, Soup, Bubble, Nell.
- Pot Luck's R12 median largest share is 0.415, against the paper's pot at 31%.
