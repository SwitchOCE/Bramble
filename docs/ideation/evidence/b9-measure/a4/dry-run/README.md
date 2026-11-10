# Build 9 A4 measurement

**DRY RUN ONLY: plumbing verification, not balance evidence.**

Source: `91d8b7268059016342c62d0e9d51420a059c8928`. Both presets use matched lobby seeds and the a35_run1 roster.

## Method and assumptions (C8)

B and provisional C came from log-linear fits to realized engine R12 medians on the frozen run-1 cross-arm cohorts; integer/fractional values snap upward and card limits apply. C targets 1,800. Endpoints, shared scaling and Soup changed, so the old fits are estimates. This run measures the merged content and never refits.

All totals are active pre-Start-of-Combat A+H. R12 uses surviving seats; growth R8-R14 uses the same R14-surviving seats with positive R8 totals, per-seat sixth-root ratios. Early/late growth similarly fixes survivors at each window end. R15/R12 divides medians of identical R15 survivors. Quantiles interpolate at (n-1)q. Survival counts and cohort n remain visible.

R14 and R15 order-of-magnitude reads use each line's identical R15-surviving cohort, and compare the best line median with the unweighted median of the other line medians. The trigger is >=10x. Missing cohorts are explicitly incomplete.

Field fights reuse tools/sim/field_fights.gd on complete captured states and blind placer layouts at R10/R12/R14. A seeded representative is sampled uniformly within each surviving committed line. One board per line gives equal line weight, excludes own-line opponents, and runs every cross-line pair in both orientations: at most 22 fights per line per round, below the 40 cap. Draws count half. This small first read has one board per line; it cannot estimate within-line board variation. Missing lines are recorded. Its 80%-at-both-R12/R14 dominance flag is a proxy, not proof of outcomes for every player choice.

The three v3 extreme misses are (1) a tribe's best line outside an order of magnitude of the others, (2) one line winning whatever the player chooses, and (3) runaway snowballs in most lobbies. For (3), the predeclared diagnostic proxy is a >=10x R14 lead over the runner-up that eventually wins, in >50% of lobbies with two positive R14 boards. R8-leader win rate is reported beside it. These proxies require judgment; a dry run evaluates no deciding bar.

Libraries use the same native captures via recapture_field.sh --reuse-captures --strength top4; no additional lobby or balance arm is needed. Source commit and capture hashes are sealed.

## Preset B

| Committed line | R12 A+H p10 / median / p90 | R8-R14 growth x/round p10 / median / p90 | Growth n | R15 ÷ R12 (n) | Alive R12 |
|---|---:|---:|---:|---:|---:|
| birds_homecoming | 3,046.000 / 3,046.000 / 3,046.000 | 1.669 / 1.669 / 1.669 | 1 | 2.275 (1) | 1/1 (100.0%) |
| birds_tempo | 1,328.000 / 1,328.000 / 1,328.000 | 1.833 / 1.833 / 1.833 | 1 | 6.334 (1) | 1/1 (100.0%) |
| bog_court | 2,405.000 / 2,405.000 / 2,405.000 | 1.855 / 1.855 / 1.855 | 1 | 8.036 (1) | 1/1 (100.0%) |
| bog_swamp | 852.000 / 852.000 / 852.000 | — | 0 | — | 1/1 (100.0%) |
| fairies_court | 601.000 / 601.000 / 601.000 | 1.726 / 1.726 / 1.726 | 1 | — | 1/2 (50.0%) |
| fairies_ring | 174.000 / 174.000 / 174.000 | — | 0 | — | 1/2 (50.0%) |
| hedgerow_parish | 358.000 / 358.000 / 358.000 | — | 0 | — | 1/2 (50.0%) |
| hedgerow_supper | 1,397.200 / 2,578.000 / 3,758.800 | 1.736 / 1.736 / 1.736 | 1 | 2.048 (1) | 2/2 (100.0%) |
| hunters_open_season | — | — | 0 | — | 0/1 (0.0%) |
| hunters_pack | 1,112.000 / 1,112.000 / 1,112.000 | 1.849 / 1.849 / 1.849 | 1 | 10.053 (1) | 1/1 (100.0%) |
| oozes_engine | 1,043.000 / 1,043.000 / 1,043.000 | 1.588 / 1.588 / 1.588 | 1 | — | 1/1 (100.0%) |
| oozes_tempo | 3,559.000 / 3,559.000 / 3,559.000 | 1.732 / 1.732 / 1.732 | 1 | 3.663 (1) | 1/1 (100.0%) |


Growth >=1.3 all lines: False; engine R12 target band: False (B band reported; C band 1,350-3,600 decides only on the full run).

| Line | R6-R11 growth p10 / median / p90 (n) | R11-R15 growth p10 / median / p90 (n) |
|---|---:|---:|
| birds_homecoming | 1.99 / 1.99 / 1.99 (1) | 1.42 / 1.42 / 1.42 (1) |
| birds_tempo | 1.52 / 1.52 / 1.52 (1) | 1.92 / 1.92 / 1.92 (1) |
| bog_court | 1.77 / 1.77 / 1.77 (1) | 2.22 / 2.22 / 2.22 (1) |
| bog_swamp | 1.74 / 1.74 / 1.74 (1) | — (0) |
| fairies_court | 1.15 / 1.15 / 1.15 (1) | — (0) |
| fairies_ring | 1.21 / 1.22 / 1.23 (2) | — (0) |
| hedgerow_parish | 1.45 / 1.45 / 1.45 (1) | — (0) |
| hedgerow_supper | 1.57 / 1.71 / 1.85 (2) | 1.47 / 1.47 / 1.47 (1) |
| hunters_open_season | 1.35 / 1.35 / 1.35 (1) | — (0) |
| hunters_pack | 1.65 / 1.65 / 1.65 (1) | 1.82 / 1.82 / 1.82 (1) |
| oozes_engine | 1.42 / 1.42 / 1.42 (1) | — (0) |
| oozes_tempo | 2.02 / 2.02 / 2.02 (1) | 1.42 / 1.42 / 1.42 (1) |

### R6-R11 active totals, p10 / median / p90 [share alive]

| Line | R6 | R7 | R8 | R9 | R10 | R11 |
|---|---:|---:|---:|---:|---:|---:|
| birds_homecoming | 54 / 54 / 54 [100%] | 68 / 68 / 68 [100%] | 313 / 313 / 313 [100%] | 192 / 192 / 192 [100%] | 112 / 112 / 112 [100%] | 1,693 / 1,693 / 1,693 [100%] |
| birds_tempo | 77 / 77 / 77 [100%] | 81 / 81 / 81 [100%] | 209 / 209 / 209 [100%] | 123 / 123 / 123 [100%] | 583 / 583 / 583 [100%] | 625 / 625 / 625 [100%] |
| bog_court | 46 / 46 / 46 [100%] | 108 / 108 / 108 [100%] | 114 / 114 / 114 [100%] | 137 / 137 / 137 [100%] | 306 / 306 / 306 [100%] | 791 / 791 / 791 [100%] |
| bog_swamp | 52 / 52 / 52 [100%] | 75 / 75 / 75 [100%] | 124 / 124 / 124 [100%] | 227 / 227 / 227 [100%] | 385 / 385 / 385 [100%] | 820 / 820 / 820 [100%] |
| fairies_court | 32 / 70 / 108 [100%] | 78 / 112 / 146 [100%] | 67 / 113 / 159 [100%] | 88 / 166 / 244 [100%] | 279 / 279 / 279 [50%] | 241 / 241 / 241 [50%] |
| fairies_ring | 61 / 62 / 63 [100%] | 90 / 92 / 94 [100%] | 94 / 94 / 94 [100%] | 107 / 120 / 133 [100%] | 114 / 134 / 154 [100%] | 161 / 168 / 175 [100%] |
| hedgerow_parish | 48 / 49 / 50 [100%] | 62 / 68 / 74 [100%] | 66 / 84 / 103 [100%] | 89 / 164 / 239 [100%] | 99 / 184 / 269 [100%] | 324 / 324 / 324 [50%] |
| hedgerow_supper | 55 / 64 / 74 [100%] | 86 / 90 / 93 [100%] | 148 / 154 / 160 [100%] | 246 / 335 / 424 [100%] | 362 / 572 / 781 [100%] | 594 / 1,129 / 1,664 [100%] |
| hunters_open_season | 47 / 47 / 47 [100%] | 57 / 57 / 57 [100%] | 57 / 57 / 57 [100%] | 68 / 68 / 68 [100%] | 120 / 120 / 120 [100%] | 212 / 212 / 212 [100%] |
| hunters_pack | 83 / 83 / 83 [100%] | 113 / 113 / 113 [100%] | 120 / 120 / 120 [100%] | 139 / 139 / 139 [100%] | 153 / 153 / 153 [100%] | 1,021 / 1,021 / 1,021 [100%] |
| oozes_engine | 163 / 163 / 163 [100%] | 236 / 236 / 236 [100%] | 344 / 344 / 344 [100%] | 467 / 467 / 467 [100%] | 651 / 651 / 651 [100%] | 953 / 953 / 953 [100%] |
| oozes_tempo | 95 / 95 / 95 [100%] | 170 / 170 / 170 [100%] | 328 / 328 / 328 [100%] | 833 / 833 / 833 [100%] | 1,903 / 1,903 / 1,903 [100%] | 3,199 / 3,199 / 3,199 [100%] |

### R11-R15 active totals, p10 / median / p90 [share alive]

| Line | R11 | R12 | R13 | R14 | R15 |
|---|---:|---:|---:|---:|---:|
| birds_homecoming | 1,693 / 1,693 / 1,693 [100%] | 3,046 / 3,046 / 3,046 [100%] | 3,046 / 3,046 / 3,046 [100%] | 6,771 / 6,771 / 6,771 [100%] | 6,931 / 6,931 / 6,931 [100%] |
| birds_tempo | 625 / 625 / 625 [100%] | 1,328 / 1,328 / 1,328 [100%] | 1,253 / 1,253 / 1,253 [100%] | 7,916 / 7,916 / 7,916 [100%] | 8,411 / 8,411 / 8,411 [100%] |
| bog_court | 791 / 791 / 791 [100%] | 2,405 / 2,405 / 2,405 [100%] | 3,072 / 3,072 / 3,072 [100%] | 4,644 / 4,644 / 4,644 [100%] | 19,327 / 19,327 / 19,327 [100%] |
| bog_swamp | 820 / 820 / 820 [100%] | 852 / 852 / 852 [100%] | 1,626 / 1,626 / 1,626 [100%] | — [0%] | — [0%] |
| fairies_court | 241 / 241 / 241 [50%] | 601 / 601 / 601 [50%] | 1,511 / 1,511 / 1,511 [50%] | 4,499 / 4,499 / 4,499 [50%] | — [0%] |
| fairies_ring | 161 / 168 / 175 [100%] | 174 / 174 / 174 [50%] | — [0%] | — [0%] | — [0%] |
| hedgerow_parish | 324 / 324 / 324 [50%] | 358 / 358 / 358 [50%] | — [0%] | — [0%] | — [0%] |
| hedgerow_supper | 594 / 1,129 / 1,664 [100%] | 1,397 / 2,578 / 3,759 [100%] | 2,056 / 2,542 / 3,029 [100%] | 4,400 / 4,400 / 4,400 [50%] | 8,301 / 8,301 / 8,301 [50%] |
| hunters_open_season | 212 / 212 / 212 [100%] | — [0%] | — [0%] | — [0%] | — [0%] |
| hunters_pack | 1,021 / 1,021 / 1,021 [100%] | 1,112 / 1,112 / 1,112 [100%] | 3,887 / 3,887 / 3,887 [100%] | 4,791 / 4,791 / 4,791 [100%] | 11,179 / 11,179 / 11,179 [100%] |
| oozes_engine | 953 / 953 / 953 [100%] | 1,043 / 1,043 / 1,043 [100%] | 1,220 / 1,220 / 1,220 [100%] | 5,524 / 5,524 / 5,524 [100%] | — [0%] |
| oozes_tempo | 3,199 / 3,199 / 3,199 [100%] | 3,559 / 3,559 / 3,559 [100%] | 6,002 / 6,002 / 6,002 [100%] | 8,854 / 8,854 / 8,854 [100%] | 13,038 / 13,038 / 13,038 [100%] |

### Field first read

| Line | R10 | R12 | R14 |
|---|---:|---:|---:|
| birds_homecoming | 0.0% | 80.0% | 100.0% |
| birds_tempo | 63.6% | 50.0% | 57.1% |
| bog_court | 72.7% | 80.0% | 64.3% |
| bog_swamp | 45.5% | 40.0% | missing |
| fairies_court | 54.5% | 20.0% | 28.6% |
| fairies_ring | 18.2% | 0.0% | missing |
| hedgerow_parish | 36.4% | 10.0% | missing |
| hedgerow_supper | 81.8% | 80.0% | 0.0% |
| hunters_open_season | 9.1% | missing | missing |
| hunters_pack | 27.3% | 55.0% | 35.7% |
| oozes_engine | 90.9% | 35.0% | 28.6% |
| oozes_tempo | 100.0% | 100.0% | 85.7% |

Order-of-magnitude: `{"14": {"line": "line_oozes_tempo", "ratio": 1.8480484241285744, "fires_10x": false, "line_medians": {"line_oozes_tempo": 8854, "line_hunters_pack": 4791, "line_hedgerow_supper": 4400, "line_bog_court": 4644, "line_birds_homecoming": 6771, "line_birds_tempo": 7916}, "tribe_best_medians": {"oozes": 8854, "hunters": 4791, "hedgerow": 4400, "bog": 4644, "birds": 7916}, "tribe_ratios": {"oozes": 1.8768415474297828, "hunters": 0.7628980891719745, "hedgerow": 0.6925316754544739, "bog": 0.7309357047296765, "birds": 1.6780074191838898}, "cohort_n": {"line_fairies_court": 0, "line_fairies_ring": 0, "line_oozes_tempo": 1, "line_hedgerow_parish": 0, "line_hunters_open_season": 0, "line_hunters_pack": 1, "line_hedgerow_supper": 1, "line_oozes_engine": 0, "line_bog_court": 1, "line_birds_homecoming": 1, "line_bog_swamp": 0, "line_birds_tempo": 1}, "complete": false}, "15": {"line": "line_bog_court", "ratio": 2.297824277731542, "fires_10x": false, "line_medians": {"line_oozes_tempo": 13038, "line_hunters_pack": 11179, "line_hedgerow_supper": 8301, "line_bog_court": 19327, "line_birds_homecoming": 6931, "line_birds_tempo": 8411}, "tribe_best_medians": {"oozes": 13038, "hunters": 11179, "hedgerow": 8301, "bog": 19327, "birds": 8411}, "tribe_ratios": {"oozes": 1.3310872894333843, "hunters": 1.0423795981164623, "hedgerow": 0.6855514721063716, "bog": 1.9731495661051557, "birds": 0.6946359995044803}, "cohort_n": {"line_fairies_court": 0, "line_fairies_ring": 0, "line_oozes_tempo": 1, "line_hedgerow_parish": 0, "line_hunters_open_season": 0, "line_hunters_pack": 1, "line_hedgerow_supper": 1, "line_oozes_engine": 0, "line_bog_court": 1, "line_birds_homecoming": 1, "line_bog_swamp": 0, "line_birds_tempo": 1}, "complete": false}}`.

Extreme diagnostics: `{"outside_order_of_magnitude": null, "one_line_wins_regardless_proxy": null, "runaway_snowballs_in_most_lobbies_proxy": false}`.

R8 leader wins: 0.0; runaway proxy: 0.0.

Missing field lines: `{"10": [], "12": ["line_hunters_open_season"], "14": ["line_bog_swamp", "line_fairies_ring", "line_hedgerow_parish", "line_hunters_open_season"]}`.

Captured active-unit stat-ceiling hits: 0; per-line R6-R15 survival, low-tail and >10x p90 flags, and every cap hit are in report.json.

## Preset C

| Committed line | R12 A+H p10 / median / p90 | R8-R14 growth x/round p10 / median / p90 | Growth n | R15 ÷ R12 (n) | Alive R12 |
|---|---:|---:|---:|---:|---:|
| birds_homecoming | 394.000 / 394.000 / 394.000 | 1.361 / 1.361 / 1.361 | 1 | 9.683 (1) | 1/1 (100.0%) |
| birds_tempo | 11,953.000 / 11,953.000 / 11,953.000 | 1.955 / 1.955 / 1.955 | 1 | 1.098 (1) | 1/1 (100.0%) |
| bog_court | 911.000 / 911.000 / 911.000 | 1.359 / 1.359 / 1.359 | 1 | — | 1/1 (100.0%) |
| bog_swamp | 926.000 / 926.000 / 926.000 | — | 0 | — | 1/1 (100.0%) |
| fairies_court | 1,318.100 / 3,610.500 / 5,902.900 | 1.973 / 2.040 / 2.108 | 2 | 15.632 (2) | 2/2 (100.0%) |
| fairies_ring | 2,490.500 / 2,584.500 / 2,678.500 | 1.898 / 2.143 / 2.388 | 2 | 13.957 (2) | 2/2 (100.0%) |
| hedgerow_parish | — | — | 0 | — | 0/2 (0.0%) |
| hedgerow_supper | 700.000 / 700.000 / 700.000 | — | 0 | — | 1/2 (50.0%) |
| hunters_open_season | — | — | 0 | — | 0/1 (0.0%) |
| hunters_pack | 7,185.000 / 7,185.000 / 7,185.000 | 2.272 / 2.272 / 2.272 | 1 | 10.603 (1) | 1/1 (100.0%) |
| oozes_engine | 23,057.000 / 23,057.000 / 23,057.000 | 2.465 / 2.465 / 2.465 | 1 | 13.561 (1) | 1/1 (100.0%) |
| oozes_tempo | 3,831.000 / 3,831.000 / 3,831.000 | — | 0 | — | 1/1 (100.0%) |


Growth >=1.3 all lines: False; engine R12 target band: False (B band reported; C band 1,350-3,600 decides only on the full run).

| Line | R6-R11 growth p10 / median / p90 (n) | R11-R15 growth p10 / median / p90 (n) |
|---|---:|---:|
| birds_homecoming | 1.14 / 1.14 / 1.14 (1) | 1.82 / 1.82 / 1.82 (1) |
| birds_tempo | 1.05 / 1.05 / 1.05 (1) | 2.89 / 2.89 / 2.89 (1) |
| bog_court | 1.54 / 1.54 / 1.54 (1) | — (0) |
| bog_swamp | 1.49 / 1.49 / 1.49 (1) | — (0) |
| fairies_court | 1.75 / 1.79 / 1.83 (2) | 2.31 / 2.49 / 2.67 (2) |
| fairies_ring | 1.56 / 1.62 / 1.67 (2) | 2.27 / 2.36 / 2.46 (2) |
| hedgerow_parish | 1.27 / 1.27 / 1.27 (1) | — (0) |
| hedgerow_supper | 1.53 / 1.62 / 1.72 (2) | — (0) |
| hunters_open_season | — (0) | — (0) |
| hunters_pack | 1.36 / 1.36 / 1.36 (1) | 3.42 / 3.42 / 3.42 (1) |
| oozes_engine | 2.15 / 2.15 / 2.15 (1) | 2.65 / 2.65 / 2.65 (1) |
| oozes_tempo | 2.31 / 2.31 / 2.31 (1) | — (0) |

### R6-R11 active totals, p10 / median / p90 [share alive]

| Line | R6 | R7 | R8 | R9 | R10 | R11 |
|---|---:|---:|---:|---:|---:|---:|
| birds_homecoming | 180 / 180 / 180 [100%] | 201 / 201 / 201 [100%] | 501 / 501 / 501 [100%] | 354 / 354 / 354 [100%] | 891 / 891 / 891 [100%] | 347 / 347 / 347 [100%] |
| birds_tempo | 151 / 151 / 151 [100%] | 119 / 119 / 119 [100%] | 345 / 345 / 345 [100%] | 132 / 132 / 132 [100%] | 3,537 / 3,537 / 3,537 [100%] | 189 / 189 / 189 [100%] |
| bog_court | 76 / 76 / 76 [100%] | 214 / 214 / 214 [100%] | 294 / 294 / 294 [100%] | 491 / 491 / 491 [100%] | 620 / 620 / 620 [100%] | 668 / 668 / 668 [100%] |
| bog_swamp | 84 / 84 / 84 [100%] | 101 / 101 / 101 [100%] | 178 / 178 / 178 [100%] | 248 / 248 / 248 [100%] | 363 / 363 / 363 [100%] | 607 / 607 / 607 [100%] |
| fairies_court | 46 / 110 / 173 [100%] | 125 / 185 / 245 [100%] | 215 / 246 / 276 [100%] | 619 / 1,953 / 3,287 [100%] | 974 / 2,464 / 3,953 [100%] | 866 / 1,824 / 2,782 [100%] |
| fairies_ring | 96 / 106 / 116 [100%] | 128 / 145 / 162 [100%] | 126 / 184 / 241 [100%] | 184 / 274 / 365 [100%] | 693 / 886 / 1,079 [100%] | 907 / 1,213 / 1,519 [100%] |
| hedgerow_parish | 42 / 60 / 77 [100%] | 99 / 108 / 116 [100%] | 56 / 90 / 124 [100%] | 77 / 132 / 186 [100%] | 242 / 242 / 242 [50%] | 263 / 263 / 263 [50%] |
| hedgerow_supper | 50 / 53 / 56 [100%] | 97 / 118 / 140 [100%] | 117 / 140 / 162 [100%] | 181 / 240 / 300 [100%] | 227 / 286 / 346 [100%] | 471 / 615 / 759 [100%] |
| hunters_open_season | 34 / 34 / 34 [100%] | 34 / 34 / 34 [100%] | 51 / 51 / 51 [100%] | 88 / 88 / 88 [100%] | 393 / 393 / 393 [100%] | — [0%] |
| hunters_pack | 120 / 120 / 120 [100%] | 170 / 170 / 170 [100%] | 251 / 251 / 251 [100%] | 268 / 268 / 268 [100%] | 351 / 351 / 351 [100%] | 560 / 560 / 560 [100%] |
| oozes_engine | 138 / 138 / 138 [100%] | 160 / 160 / 160 [100%] | 380 / 380 / 380 [100%] | 1,079 / 1,079 / 1,079 [100%] | 2,124 / 2,124 / 2,124 [100%] | 6,306 / 6,306 / 6,306 [100%] |
| oozes_tempo | 53 / 53 / 53 [100%] | 76 / 76 / 76 [100%] | 108 / 108 / 108 [100%] | 147 / 147 / 147 [100%] | 2,947 / 2,947 / 2,947 [100%] | 3,506 / 3,506 / 3,506 [100%] |

### R11-R15 active totals, p10 / median / p90 [share alive]

| Line | R11 | R12 | R13 | R14 | R15 |
|---|---:|---:|---:|---:|---:|
| birds_homecoming | 347 / 347 / 347 [100%] | 394 / 394 / 394 [100%] | 2,756 / 2,756 / 2,756 [100%] | 3,179 / 3,179 / 3,179 [100%] | 3,815 / 3,815 / 3,815 [100%] |
| birds_tempo | 189 / 189 / 189 [100%] | 11,953 / 11,953 / 11,953 [100%] | 11,591 / 11,591 / 11,591 [100%] | 19,285 / 19,285 / 19,285 [100%] | 13,120 / 13,120 / 13,120 [100%] |
| bog_court | 668 / 668 / 668 [100%] | 911 / 911 / 911 [100%] | 1,108 / 1,108 / 1,108 [100%] | 1,853 / 1,853 / 1,853 [100%] | — [0%] |
| bog_swamp | 607 / 607 / 607 [100%] | 926 / 926 / 926 [100%] | 1,722 / 1,722 / 1,722 [100%] | — [0%] | — [0%] |
| fairies_court | 866 / 1,824 / 2,782 [100%] | 1,318 / 3,610 / 5,903 [100%] | 12,603 / 13,791 / 14,979 [100%] | 16,210 / 17,469 / 18,728 [100%] | 38,610 / 56,440 / 74,270 [100%] |
| fairies_ring | 907 / 1,213 / 1,519 [100%] | 2,490 / 2,584 / 2,678 [100%] | 3,618 / 5,960 / 8,302 [100%] | 11,238 / 16,993 / 22,748 [100%] | 32,548 / 36,072 / 39,596 [100%] |
| hedgerow_parish | 263 / 263 / 263 [50%] | — [0%] | — [0%] | — [0%] | — [0%] |
| hedgerow_supper | 471 / 615 / 759 [100%] | 700 / 700 / 700 [50%] | — [0%] | — [0%] | — [0%] |
| hunters_open_season | — [0%] | — [0%] | — [0%] | — [0%] | — [0%] |
| hunters_pack | 560 / 560 / 560 [100%] | 7,185 / 7,185 / 7,185 [100%] | 24,009 / 24,009 / 24,009 [100%] | 34,508 / 34,508 / 34,508 [100%] | 76,185 / 76,185 / 76,185 [100%] |
| oozes_engine | 6,306 / 6,306 / 6,306 [100%] | 23,057 / 23,057 / 23,057 [100%] | 23,057 / 23,057 / 23,057 [100%] | 85,303 / 85,303 / 85,303 [100%] | 312,679 / 312,679 / 312,679 [100%] |
| oozes_tempo | 3,506 / 3,506 / 3,506 [100%] | 3,831 / 3,831 / 3,831 [100%] | 29,321 / 29,321 / 29,321 [100%] | — [0%] | — [0%] |

### Field first read

| Line | R10 | R12 | R14 |
|---|---:|---:|---:|
| birds_homecoming | 63.6% | 0.0% | 16.7% |
| birds_tempo | 81.8% | 72.2% | 50.0% |
| bog_court | 54.5% | 33.3% | 0.0% |
| bog_swamp | 27.3% | 22.2% | missing |
| fairies_court | 100.0% | 88.9% | 66.7% |
| fairies_ring | 40.9% | 44.4% | 33.3% |
| hedgerow_parish | 9.1% | missing | missing |
| hedgerow_supper | 0.0% | 11.1% | missing |
| hunters_open_season | 18.2% | missing | missing |
| hunters_pack | 40.9% | 72.2% | 83.3% |
| oozes_engine | 81.8% | 100.0% | 100.0% |
| oozes_tempo | 81.8% | 55.6% | missing |

Order-of-magnitude: `{"14": {"line": "line_oozes_engine", "ratio": 4.883107218501345, "fires_10x": false, "line_medians": {"line_fairies_court": 17469.0, "line_fairies_ring": 16993.0, "line_hunters_pack": 34508, "line_oozes_engine": 85303, "line_birds_homecoming": 3179, "line_birds_tempo": 19285}, "tribe_best_medians": {"fairies": 17469.0, "hunters": 34508, "oozes": 85303, "birds": 19285}, "tribe_ratios": {"fairies": 0.5062304393184189, "hunters": 1.7893699766658024, "oozes": 4.423282343790511, "birds": 0.5588559174684131}, "cohort_n": {"line_fairies_court": 2, "line_fairies_ring": 2, "line_oozes_tempo": 0, "line_hedgerow_parish": 0, "line_hunters_open_season": 0, "line_hunters_pack": 1, "line_hedgerow_supper": 0, "line_oozes_engine": 1, "line_bog_court": 0, "line_birds_homecoming": 1, "line_bog_swamp": 0, "line_birds_tempo": 1}, "complete": false}, "15": {"line": "line_oozes_engine", "ratio": 8.668191394987803, "fires_10x": false, "line_medians": {"line_fairies_court": 56440.0, "line_fairies_ring": 36072.0, "line_hunters_pack": 76185, "line_oozes_engine": 312679, "line_birds_homecoming": 3815, "line_birds_tempo": 13120}, "tribe_best_medians": {"fairies": 56440.0, "hunters": 76185, "oozes": 312679, "birds": 13120}, "tribe_ratios": {"fairies": 0.7408282470302553, "hunters": 1.3498405386250887, "oozes": 5.540024805102764, "birds": 0.17221237776465184}, "cohort_n": {"line_fairies_court": 2, "line_fairies_ring": 2, "line_oozes_tempo": 0, "line_hedgerow_parish": 0, "line_hunters_open_season": 0, "line_hunters_pack": 1, "line_hedgerow_supper": 0, "line_oozes_engine": 1, "line_bog_court": 0, "line_birds_homecoming": 1, "line_bog_swamp": 0, "line_birds_tempo": 1}, "complete": false}}`.

Extreme diagnostics: `{"outside_order_of_magnitude": null, "one_line_wins_regardless_proxy": null, "runaway_snowballs_in_most_lobbies_proxy": false}`.

R8 leader wins: 0.5; runaway proxy: 0.0.

Missing field lines: `{"10": [], "12": ["line_hedgerow_parish", "line_hunters_open_season"], "14": ["line_bog_swamp", "line_hedgerow_parish", "line_hedgerow_supper", "line_hunters_open_season", "line_oozes_tempo"]}`.

Captured active-unit stat-ceiling hits: 0; per-line R6-R15 survival, low-tail and >10x p90 flags, and every cap hit are in report.json.
