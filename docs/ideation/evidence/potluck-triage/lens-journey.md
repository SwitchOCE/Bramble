# Lens: journey and tempo (Pot Luck = line_oozes_tempo)

Data: `docs/ideation/evidence/wave2b/oozes-final.jsonl` (32 lobbies, branch ideation/wave2b at a2f4295f). Scripts in this folder: `journey.py` (full output `journey_out.txt`; run on the first run: `journey_before.txt`), `route_overlap.py`, `tiers.py`. All run with `python3 -I`. Stats are active Attack+Health before Start of Combat, survivors only, unless "incl." (with Bellies). "Tier" is the highest card tier on board, a lower bound on shop tier. Hard seats are grouped by their build's tribe.

## Verdicts

| # | Hypothesis | Verdict | Weight |
|---|---|---|---|
| 1 | Pot Luck dies early, before its engine comes online | ruled out | - |
| 2 | Pot Luck falls behind from R9 and keeps falling (growth, mid-late) | kept | major |
| 3 | The R8->R14 ratio is dragged down by deaths (tempo), not by survivors' growth | ruled out | - |
| 4 | The paper route's board rarely forms on the bot's board | kept (cause open) | unknown |
| 5 | Pot Luck tiers slower than the engine line | kept | minor |
| 6 | Bellies hide the growth (measurement) | ruled out | - |
| 7 | The two bot fixes moved Pot Luck | ruled out | - |

1. **Early death: ruled out.** No Pot Luck seat dies before R9. R1-6 boards are level with or above the engine line and the Hard field (R6: 48.5 / 46.5 / 52.5; incl. 55 / 53 / 55). Paired by lobby, the PL/engine ratio at R6 is 1.02, with PL ahead in 16 of 32.
2. **Falls behind from R9: kept, major.** Against the Hard-field median, Pot Luck is 0.85x at R8, 0.69x at R9, 0.59x at R12 and 0.44x at R14. The engine line holds about 0.75x throughout (0.84 / 0.75 / 0.78 / 0.75). The R8->R9 step is the first break: the median moves 88 -> 93.5 (+6%) against +17% for the engine and +31% for the Hard field. The per-seat median step is 1.18 against 1.26 and 1.29. Paired PL/engine ratio: 1.02 at R6, 0.94 at R8, 0.91 at R10, 0.84 at R12 (PL ahead in 16, 14, 9, 5 lobbies).
3. **Deaths drive the ratio: ruled out.** Survivorship flatters Pot Luck. Seats alive at R14 (n=12) had an R8 median of 101; seats that died before R14 had 65.5. On the fixed R14 cohort the ratio is **1.222** (reported 1.251), and the median per-seat ratio is 1.230. The engine's fixed cohort is 1.344 (per-seat 1.332). R8->R12 on the larger cohort: 1.225 PL against 1.306 engine. The gap is slow growth among survivors. The extra deaths follow from it: dead by R12 44% / 31% / 30% (PL / engine / Hard), and by R14 69% / 47% / 52%.
4. **The route's board rarely forms: kept, cause open.** The paper R12 board has 7 cards (Pie, Granny, Moss, Elder, Soup, Bubble as the pot, Nell). At R12 the median Pot Luck board holds 2 of them (distribution 0:2, 1:6, 2:8, 3:7; no board holds 4 or more). Share of alive seats at R12 with each card: Soup 39%, Elder 39%, Granny 30%, Bubble 22%, Nell 22%, Pie 22%, Moss 13%. Through R10-12 the board is mostly tier-1 Belly units: Wobbly 65%, Posset 58%, Dollop 33%, Little Nip 37% of seat-rounds. Aunt Aspic, which the route excludes, appears on 7 of 32 boards at R9 and 4 of 23 at R12. The two Granny cards on the median R12 board (`journey_out.txt`, example boards) show duplicates being held. This lens can't tell whether the cause is shop access or the line's policy.
5. **Slower tiering: kept, minor.** Share of boards with a tier-6 card: R10 32% / 42% / 27%, R11 37% / 59% / 43%, R12 61% / 77% / 65% (PL / engine / Hard). Pot Luck lags the engine but tiers in step with the Hard field, so this explains some of the gap to the engine and none of the gap to the field.
6. **Bellies hide growth: ruled out.** Including Bellies, the same R14 cohort goes 111.5 -> 381, a ratio of 1.227 against 1.222 active. Bellies add 15-25% to the level and nothing to the growth.
7. **The bot fixes moved Pot Luck: ruled out.** Before the fixes: fixed-cohort ratio 1.242, per-seat 1.231, dead by R14 78%, top-4 22%. After: 1.222, 1.230, 69%, 31%. The engine moved 1.301 -> 1.344 on its cohort.

## Per round (median active, incl. Bellies, alive count)

| R | PL alive | PL act | PL incl | EN alive | EN act | EN incl | Hard alive | Hard act | Hard-Oozes act |
|---|---|---|---|---|---|---|---|---|---|
| 3 | 32 | 15 | 17.5 | 32 | 13.5 | 14 | 100% | 16 | 16.5 |
| 6 | 32 | 48.5 | 55 | 32 | 46.5 | 53 | 100% | 52.5 | 55 |
| 8 | 32 | 88 | 99 | 32 | 87 | 95.5 | 100% | 103.5 | 89 |
| 9 | 32 | 93.5 | 116.5 | 32 | 102 | 120.5 | 100% | 135.5 | 114.5 |
| 10 | 31 | 126 | 158 | 31 | 154 | 164 | 100% | 178.5 | 148 |
| 11 | 27 | 166 | 194 | 29 | 200 | 212 | 96% | 257 | 186.5 |
| 12 | 23 | 200 | 248 | 26 | 262 | 285.5 | 86% | 337 | 246 |
| 13 | 18 | 249.5 | 306.5 | 22 | 405 | 419.5 | 70% | 510 | 341 |
| 14 | 12 | 337 | 381 | 21 | 572 | 572 | 56% | 766 | 510 |

Buckets (median active / incl. / board size / max card tier):

| group | R1-3 | R4-6 | R7-9 | R10-12 | R13-16 |
|---|---|---|---|---|---|
| Pot Luck | 8 / 8 / 2 / 1 | 32 / 37 / 4.5 / 2 | 72.5 / 91.5 / 6 / 3 | 163 / 191 / 7 / 5 | 366 / 391.5 / 7 / 6 |
| Engine | 5 / 5 / 1 / 1 | 34.5 / 36.5 / 4 / 2 | 82.5 / 91 / 6 / 4 | 199 / 210.5 / 7 / 6 | 490 / 538 / 7 / 6 |
| Hard, all | 5 / 5 / 1 / 1 | 38 / 40 / 5 / 2 | 100.5 / 104 / 7 / 4 | 238 / 240 / 7 / 5 | 789 / 794.5 / 7 / 6 |

## Elimination and placement (ties in last round share the average place)

| group | n | median last round | dead by R10 | by R12 | by R14 | mean place | top 4 | 1st (shared) |
|---|---|---|---|---|---|---|---|---|
| Pot Luck | 32 | 13 | 16% | 44% | 69% | 5.30 | 31% | 12% |
| Engine | 32 | 15 | 9% | 31% | 47% | 4.47 | 56% | 16% |
| Hard, all | 192 | 14 | 4% | 30% | 52% | 4.37 | 49% | 29% |
| Hard Oozes builds | 28 | 13 | 0% | 32% | 75% | 5.23 | 21% | 11% |
| Hard Hedgerow | 18 | 12.5 | 6% | 50% | 72% | 5.22 | 28% | 11% |
| Hard Bog | 23 | 18 | 4% | 17% | 17% | 2.76 | 83% | 65% |

"Dead by Rn" means absent from round n+1. Last round seen: PL R9:1 R10:4 R11:4 R12:5 R13:6 R14:2 R15+:10; engine R9:1 R10:2 R11:3 R12:4 R13:1 R14:4 R15+:17. Paired by lobby, the engine outlives Pot Luck in 19 of 32 lobbies, ties in 2 and dies first in 11.

## Benchmark boards (active: p10 low roll / median / p90 high roll; incl. median)

| R | Pot Luck | Engine | Hard all | Hard Oozes | Bog | Fairies | Hunters |
|---|---|---|---|---|---|---|---|
| 6 | 32 / 48.5 / 61 (55) | 32 / 46.5 / 58 (53) | 38 / 52.5 / 82 | 40 / 55 / 73 | 41 / 50 / 69 | 37 / 50 / 105 | 37 / 48.5 / 70 |
| 9 | 61 / 93.5 / 151 (116.5) | 71 / 102 / 155 (120.5) | 85 / 135.5 / 222 | 80 / 114.5 / 168 | 101 / 156 / 187 | 78 / 143 / 239 | 101 / 131.5 / 190 |
| 12 | 143 / 200 / 361 (248) | 180 / 262 / 400 (285.5) | 185 / 337 / 614 | 166 / 246 / 422 | 327 / 426.5 / 599 | 143 / 460 / 1264 | 282 / 357.5 / 470 |

Pot Luck's R12 high roll (p90 361, max 393) sits near the Hard-field median and below 0.45x of the 900 target. Its paper boards are 64 / 209 / 924 incl. at R6 / R9 / R12. Realized incl. medians are 55 / 116.5 / 248: 0.86x, 0.56x and 0.27x of paper. The shortfall opens at R9.

Example Pot Luck boards (seat nearest the percentile):
- R6 average (50): Earwig Mother, Wobbly, Posset, Soup, Soup, Dollop.
- R9 average (94, 31 inside): Pie, Granny, Wobbly, Aspic, Aspic, Frumenty, Moss.
- R12 low (143): Wobbly, Old Isegrim, Cut-and-Come-Again, Dollop, Moss.
- R12 average (200, 48 inside): Wobbly, Granny, Pie, Granny, Nell, Aspic, Nell.
- R12 high (375): Nell, Cut x2, Syllabub, Elder, Dollop, Nell.

None of these example boards holds Bubble and Squeak, the route's pot.

## Scripts
- `journey.py [jsonl]`: per-round medians, buckets, card presence, elimination and placement, cohort decomposition, paired lobbies, benchmark boards, route checkpoints.
- `route_overlap.py <jsonl>`: paper-board cards present per board at R9 and R12, Aspic count, duplicate Granny.
- `tiers.py`: highest card tier on board by round; per-seat R8->R9 step.
