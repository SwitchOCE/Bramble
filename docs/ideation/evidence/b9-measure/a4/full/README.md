# Build 9 A4 measurement

In short, the scale problem is not fully fixed on B or C. B still falls short for Fairy Ring (R12 median 471) and Hunters Open Season (585), below its 675 lower bound; the other four engine lines are in B's intended band. C overshoots for Hunters Open Season (4,463) and Oozes Engine (18,322), above its 3,600 upper bound; the other four engine lines are in C's band. All twelve lines on both presets pass the ×1.3 growth bar. B triggers none of the three extreme diagnostics. C triggers the late scale-outlier and field-dominance diagnostics; its runaway proxy is 13/64 lobbies, below most. The field read samples one board per line. These misses are recorded without another fit.


| Read | B | C |
|---|---|---|
| R12 engine band | 4/6; Fairy Ring and Hunters Open Season low | **Fail, 4/6**; Hunters Open Season and Oozes Engine high |
| R8–R14 median growth, identical seats | **Pass 12/12**, minimum 1.396× | **Pass 12/12**, minimum 1.795× |
| Best-line ÷ median other lines, R14 / R15 | 3.707× / 5.887× | 5.981× / **10.520×**, Ooze engine at R15 |
| ≥80% field points at both R12/R14 | None | **Bog Court, 90.9% / 90.9%** |
| Runaway proxy, most means >50% | 6/64, 9.4%; does not fire | 13/64, 20.3%; does not fire |
| Active-unit ceiling observations | 0 | 368 repeated unit/round snapshots; details in report JSON |

C's sampled Bog Court trajectory is seed 2911045, seat 4: active A+H 389,796 at R12 and 872,448
at R14. Its field-dominance flag therefore comes from a realized high roll, well above the line's
R12 median 2,037. The flag stands under this predeclared small first read; one sampled board per
line cannot establish dominance across the line's population. Six C lines have R12 p90 above 10×
median, listed in the audit below. C's scale and late order-of-magnitude misses also stand independently
of that field sample.

Final merged-source A4; no refit.

Source: `31aa42734872f93c81c313490c9f85188b536265`. Both presets use matched lobby seeds and the a35_run1 roster.

## Method and assumptions (C8)

B and provisional C came from log-linear fits to realized engine R12 medians on the frozen run-1 cross-arm cohorts; integer/fractional values snap upward and card limits apply. C targets 1,800. Endpoints, shared scaling and Soup changed, so the old fits are estimates. This run measures the merged content and never refits.

All totals are active pre-Start-of-Combat A+H. R12 uses surviving seats; growth R8-R14 uses the same R14-surviving seats with positive R8 totals, per-seat sixth-root ratios. Early/late growth similarly fixes survivors at each window end. R15/R12 divides medians of identical R15 survivors. Quantiles interpolate at (n-1)q. Survival counts and cohort n remain visible.

R14 and R15 order-of-magnitude reads use each line's identical R15-surviving cohort, and compare the best line median with the unweighted median of the other line medians. The trigger is >=10x. Missing cohorts are explicitly incomplete.

Field fights reuse tools/sim/field_fights.gd on complete captured states and blind placer layouts at R10/R12/R14. A seeded representative is sampled uniformly within each surviving committed line. One board per line gives equal line weight, excludes own-line opponents, and runs every cross-line pair in both orientations: at most 22 fights per line per round, below the 40 cap. Draws count half. This small first read has one board per line; it cannot estimate within-line board variation. Missing lines are recorded. Its 80%-at-both-R12/R14 dominance flag is a proxy, not proof of outcomes for every player choice.

The three v3 extreme misses are (1) a tribe's best line outside an order of magnitude of the others, (2) one line winning whatever the player chooses, and (3) runaway snowballs in most lobbies. For (3), the diagnostic measures a >=10x lead over the runner-up by the eventual winner at R14, or at the final pre-fight round for games ending before R14. All completed lobbies are in the denominator; a positive leader against a zero runner-up qualifies. An extreme miss requires this in >50% of all completed lobbies. R8-leader win rate is reported beside it. These proxies require judgment; a dry run evaluates no deciding bar.

Libraries use the same native captures via recapture_field.sh --reuse-captures --strength top4; no additional lobby or balance arm is needed. Source commit and capture hashes are sealed.

## Preset B

| Committed line | R12 A+H p10 / median / p90 | R8-R14 growth x/round p10 / median / p90 | Growth n | R15 ÷ R12 (n) | Alive R12 |
|---|---:|---:|---:|---:|---:|
| birds_homecoming | 417.800 / 769.000 / 2,178.200 | 1.452 / 1.672 / 1.970 | 23 | 2.474 (21) | 37/42 (88.1%) |
| birds_tempo | 342.800 / 628.000 / 1,107.800 | 1.374 / 1.561 / 1.759 | 20 | 4.010 (16) | 35/42 (83.3%) |
| bog_court | 278.400 / 677.000 / 1,121.100 | 1.400 / 1.610 / 1.770 | 15 | 5.698 (15) | 28/42 (66.7%) |
| bog_swamp | 340.000 / 782.000 / 1,638.000 | 1.454 / 1.608 / 1.800 | 19 | 5.100 (15) | 31/42 (73.8%) |
| fairies_court | 310.100 / 964.000 / 3,204.800 | 1.554 / 1.948 / 2.511 | 17 | 7.250 (13) | 34/43 (79.1%) |
| fairies_ring | 261.600 / 471.000 / 1,369.200 | 1.342 / 1.629 / 1.842 | 21 | 11.615 (18) | 37/43 (86.0%) |
| hedgerow_parish | 317.000 / 1,187.000 / 8,721.000 | 1.578 / 1.857 / 2.634 | 22 | 13.017 (20) | 31/43 (72.1%) |
| hedgerow_supper | 251.600 / 798.000 / 3,429.000 | 1.441 / 1.682 / 2.088 | 16 | 5.211 (14) | 33/43 (76.7%) |
| hunters_open_season | 144.700 / 585.000 / 1,236.700 | 1.322 / 1.537 / 1.973 | 12 | 6.099 (9) | 30/43 (69.8%) |
| hunters_pack | 275.500 / 656.500 / 1,997.700 | 1.321 / 1.704 / 2.040 | 17 | 9.409 (14) | 30/43 (69.8%) |
| oozes_engine | 629.100 / 958.000 / 2,769.300 | 1.275 / 1.496 / 1.931 | 36 | 3.153 (35) | 42/43 (97.7%) |
| oozes_tempo | 582.100 / 971.000 / 2,311.500 | 1.237 / 1.396 / 1.709 | 38 | 3.197 (36) | 42/43 (97.7%) |


Growth >=1.3 all lines: True; engine R12 target band: False (B band reported; C band 1,350-3,600 decides only on the full run).

| Line | R6-R11 growth p10 / median / p90 (n) | R11-R15 growth p10 / median / p90 (n) |
|---|---:|---:|
| birds_homecoming | 1.26 / 1.46 / 1.80 (40) | 1.25 / 1.59 / 2.07 (21) |
| birds_tempo | 1.32 / 1.56 / 1.74 (41) | 1.35 / 1.60 / 1.85 (16) |
| bog_court | 1.34 / 1.50 / 1.72 (38) | 1.49 / 1.81 / 2.12 (15) |
| bog_swamp | 1.32 / 1.45 / 1.70 (38) | 1.25 / 1.73 / 2.21 (15) |
| fairies_court | 1.19 / 1.46 / 1.79 (40) | 1.60 / 1.91 / 2.79 (13) |
| fairies_ring | 1.24 / 1.45 / 1.67 (43) | 1.48 / 1.98 / 2.18 (18) |
| hedgerow_parish | 1.30 / 1.58 / 2.14 (37) | 1.73 / 2.07 / 3.04 (20) |
| hedgerow_supper | 1.28 / 1.49 / 2.02 (39) | 1.43 / 1.66 / 2.29 (14) |
| hunters_open_season | 1.24 / 1.42 / 1.75 (39) | 1.40 / 1.62 / 2.13 (9) |
| hunters_pack | 1.26 / 1.43 / 1.78 (36) | 1.37 / 1.82 / 2.55 (14) |
| oozes_engine | 1.31 / 1.55 / 1.92 (42) | 1.25 / 1.42 / 2.07 (35) |
| oozes_tempo | 1.26 / 1.48 / 1.71 (43) | 1.25 / 1.42 / 1.94 (36) |

### R6-R11 active totals, p10 / median / p90 [share alive]

| Line | R6 | R7 | R8 | R9 | R10 | R11 |
|---|---:|---:|---:|---:|---:|---:|
| birds_homecoming | 36 / 60 / 87 [100%] | 53 / 81 / 119 [100%] | 63 / 118 / 204 [100%] | 109 / 170 / 281 [100%] | 145 / 306 / 565 [100%] | 175 / 432 / 979 [95%] |
| birds_tempo | 35 / 50 / 73 [100%] | 48 / 74 / 132 [100%] | 63 / 124 / 199 [100%] | 98 / 161 / 336 [100%] | 139 / 328 / 546 [100%] | 201 / 436 / 718 [98%] |
| bog_court | 32 / 46 / 69 [100%] | 45 / 69 / 119 [100%] | 73 / 102 / 170 [100%] | 91 / 134 / 224 [100%] | 121 / 202 / 436 [100%] | 214 / 420 / 662 [90%] |
| bog_swamp | 36 / 52 / 82 [100%] | 52 / 70 / 127 [100%] | 62 / 102 / 174 [100%] | 82 / 130 / 262 [100%] | 114 / 234 / 443 [98%] | 190 / 376 / 702 [90%] |
| fairies_court | 39 / 59 / 89 [100%] | 54 / 84 / 149 [100%] | 55 / 94 / 231 [100%] | 80 / 150 / 327 [100%] | 92 / 218 / 402 [95%] | 109 / 443 / 1,201 [93%] |
| fairies_ring | 33 / 57 / 83 [100%] | 44 / 83 / 149 [100%] | 58 / 117 / 220 [100%] | 88 / 150 / 259 [100%] | 117 / 230 / 546 [100%] | 196 / 356 / 865 [100%] |
| hedgerow_parish | 32 / 45 / 84 [100%] | 49 / 78 / 191 [100%] | 58 / 112 / 346 [100%] | 75 / 215 / 538 [100%] | 98 / 290 / 1,095 [100%] | 159 / 501 / 2,960 [86%] |
| hedgerow_supper | 37 / 53 / 89 [100%] | 48 / 74 / 120 [100%] | 67 / 130 / 213 [100%] | 97 / 197 / 471 [100%] | 126 / 260 / 885 [98%] | 165 / 467 / 1,808 [91%] |
| hunters_open_season | 38 / 55 / 90 [100%] | 52 / 76 / 112 [100%] | 68 / 100 / 166 [100%] | 88 / 148 / 247 [100%] | 126 / 225 / 345 [100%] | 185 / 436 / 847 [91%] |
| hunters_pack | 33 / 52 / 85 [100%] | 55 / 86 / 134 [100%] | 59 / 114 / 190 [100%] | 85 / 144 / 292 [100%] | 147 / 240 / 598 [100%] | 182 / 364 / 928 [84%] |
| oozes_engine | 48 / 90 / 183 [100%] | 69 / 148 / 301 [100%] | 108 / 269 / 446 [100%] | 156 / 354 / 753 [100%] | 212 / 514 / 1,008 [100%] | 459 / 745 / 1,879 [98%] |
| oozes_tempo | 47 / 131 / 207 [100%] | 59 / 158 / 326 [100%] | 97 / 294 / 551 [100%] | 144 / 344 / 822 [100%] | 230 / 526 / 1,186 [100%] | 326 / 752 / 1,592 [100%] |

### R11-R15 active totals, p10 / median / p90 [share alive]

| Line | R11 | R12 | R13 | R14 | R15 |
|---|---:|---:|---:|---:|---:|
| birds_homecoming | 175 / 432 / 979 [95%] | 418 / 769 / 2,178 [88%] | 436 / 1,232 / 3,555 [81%] | 1,302 / 2,343 / 7,158 [55%] | 1,677 / 3,290 / 11,096 [50%] |
| birds_tempo | 201 / 436 / 718 [98%] | 343 / 628 / 1,108 [83%] | 605 / 1,224 / 2,113 [74%] | 1,214 / 1,915 / 4,399 [48%] | 1,254 / 3,266 / 6,744 [38%] |
| bog_court | 214 / 420 / 662 [90%] | 278 / 677 / 1,121 [67%] | 874 / 1,502 / 2,134 [43%] | 1,595 / 2,261 / 4,655 [36%] | 2,773 / 4,450 / 7,066 [36%] |
| bog_swamp | 190 / 376 / 702 [90%] | 340 / 782 / 1,638 [74%] | 668 / 1,380 / 2,838 [62%] | 1,344 / 2,086 / 4,356 [45%] | 1,304 / 4,121 / 12,146 [36%] |
| fairies_court | 109 / 443 / 1,201 [93%] | 310 / 964 / 3,205 [79%] | 884 / 3,170 / 9,913 [60%] | 2,006 / 8,681 / 19,406 [40%] | 3,602 / 14,109 / 56,571 [30%] |
| fairies_ring | 196 / 356 / 865 [100%] | 262 / 471 / 1,369 [86%] | 418 / 828 / 4,642 [65%] | 945 / 2,959 / 6,893 [49%] | 1,572 / 7,276 / 17,925 [42%] |
| hedgerow_parish | 159 / 501 / 2,960 [86%] | 317 / 1,187 / 8,721 [72%] | 644 / 2,652 / 22,523 [65%] | 1,157 / 5,034 / 65,283 [51%] | 5,236 / 26,196 / 242,739 [47%] |
| hedgerow_supper | 165 / 467 / 1,808 [91%] | 252 / 798 / 3,429 [77%] | 325 / 1,637 / 6,100 [58%] | 1,090 / 4,932 / 16,078 [37%] | 1,817 / 8,861 / 52,055 [33%] |
| hunters_open_season | 185 / 436 / 847 [91%] | 145 / 585 / 1,237 [70%] | 458 / 953 / 4,127 [49%] | 771 / 2,080 / 9,333 [28%] | 3,404 / 5,696 / 14,803 [21%] |
| hunters_pack | 182 / 364 / 928 [84%] | 276 / 656 / 1,998 [70%] | 551 / 1,680 / 4,818 [51%] | 980 / 3,401 / 10,648 [40%] | 1,145 / 8,360 / 19,807 [33%] |
| oozes_engine | 459 / 745 / 1,879 [98%] | 629 / 958 / 2,769 [98%] | 797 / 1,600 / 7,872 [93%] | 1,102 / 2,528 / 21,268 [84%] | 1,443 / 4,055 / 33,911 [81%] |
| oozes_tempo | 326 / 752 / 1,592 [100%] | 582 / 971 / 2,312 [98%] | 800 / 1,645 / 4,562 [95%] | 1,016 / 2,279 / 7,462 [88%] | 1,558 / 3,244 / 15,153 [84%] |

### Field first read

| Line | R10 | R12 | R14 |
|---|---:|---:|---:|
| birds_homecoming | 77.3% | 0.0% | 27.3% |
| birds_tempo | 54.5% | 45.5% | 54.5% |
| bog_court | 0.0% | 36.4% | 22.7% |
| bog_swamp | 22.7% | 31.8% | 9.1% |
| fairies_court | 54.5% | 9.1% | 81.8% |
| fairies_ring | 22.7% | 54.5% | 45.5% |
| hedgerow_parish | 9.1% | 77.3% | 90.9% |
| hedgerow_supper | 54.5% | 86.4% | 72.7% |
| hunters_open_season | 36.4% | 72.7% | 18.2% |
| hunters_pack | 100.0% | 18.2% | 100.0% |
| oozes_engine | 90.9% | 77.3% | 13.6% |
| oozes_tempo | 77.3% | 90.9% | 63.6% |

Order-of-magnitude: `{"14": {"line": "line_fairies_court", "ratio": 3.7066769587032034, "fires_10x": false, "line_medians": {"line_fairies_court": 9604, "line_fairies_ring": 3062.5, "line_oozes_tempo": 2279.0, "line_hedgerow_parish": 8053.0, "line_hunters_open_season": 3191, "line_hunters_pack": 4042.5, "line_hedgerow_supper": 5461.0, "line_oozes_engine": 2563, "line_bog_court": 2261, "line_birds_homecoming": 2457, "line_bog_swamp": 2591, "line_birds_tempo": 1986.0}, "tribe_best_medians": {"fairies": 9604, "oozes": 2563, "hedgerow": 8053.0, "hunters": 4042.5, "bog": 2591, "birds": 2457}, "tribe_ratios": {"fairies": 3.7066769587032034, "oozes": 0.6340136054421769, "hedgerow": 3.108066383635662, "hunters": 1.5602084137398688, "bog": 0.6409400123685838, "birds": 0.6077922077922078}, "cohort_n": {"line_fairies_court": 13, "line_fairies_ring": 18, "line_oozes_tempo": 36, "line_hedgerow_parish": 20, "line_hunters_open_season": 9, "line_hunters_pack": 14, "line_hedgerow_supper": 14, "line_oozes_engine": 35, "line_bog_court": 15, "line_birds_homecoming": 21, "line_bog_swamp": 15, "line_birds_tempo": 16}, "complete": true}, "15": {"line": "line_hedgerow_parish", "ratio": 5.88685393258427, "fires_10x": false, "line_medians": {"line_fairies_court": 14109, "line_fairies_ring": 7276.5, "line_oozes_tempo": 3244.5, "line_hedgerow_parish": 26196.5, "line_hunters_open_season": 5696, "line_hunters_pack": 8360.0, "line_hedgerow_supper": 8861.0, "line_oozes_engine": 4055, "line_bog_court": 4450, "line_birds_homecoming": 3290, "line_bog_swamp": 4121, "line_birds_tempo": 3266.0}, "tribe_best_medians": {"fairies": 14109, "oozes": 4055, "hedgerow": 26196.5, "hunters": 8360.0, "bog": 4450, "birds": 3290}, "tribe_ratios": {"fairies": 3.170561797752809, "oozes": 0.48504784688995217, "hedgerow": 5.88685393258427, "hunters": 1.8786516853932584, "bog": 0.5322966507177034, "birds": 0.39354066985645936}, "cohort_n": {"line_fairies_court": 13, "line_fairies_ring": 18, "line_oozes_tempo": 36, "line_hedgerow_parish": 20, "line_hunters_open_season": 9, "line_hunters_pack": 14, "line_hedgerow_supper": 14, "line_oozes_engine": 35, "line_bog_court": 15, "line_birds_homecoming": 21, "line_bog_swamp": 15, "line_birds_tempo": 16}, "complete": true}}`.

Extreme diagnostics: `{"outside_order_of_magnitude": false, "one_line_wins_regardless_proxy": false, "runaway_snowballs_in_most_lobbies_proxy": false}`.

R8 leader wins: 0.28125; runaway proxy: 0.09375.

Missing field lines: `{"10": [], "12": [], "14": []}`.

Captured active-unit stat-ceiling hits: 0; per-line R6-R15 survival, low-tail and >10x p90 flags, and every cap hit are in report.json.

## Preset C

| Committed line | R12 A+H p10 / median / p90 | R8-R14 growth x/round p10 / median / p90 | Growth n | R15 ÷ R12 (n) | Alive R12 |
|---|---:|---:|---:|---:|---:|
| birds_homecoming | 643.900 / 2,879.000 / 11,344.400 | 1.529 / 1.837 / 2.155 | 20 | 4.945 (18) | 32/42 (76.2%) |
| birds_tempo | 666.000 / 1,667.000 / 5,657.400 | 1.523 / 1.870 / 2.716 | 18 | 3.913 (17) | 37/42 (88.1%) |
| bog_court | 841.000 / 2,037.000 / 27,643.500 | 1.436 / 1.889 / 2.341 | 14 | 8.301 (14) | 28/42 (66.7%) |
| bog_swamp | 749.300 / 2,221.500 / 16,181.200 | 1.619 / 2.018 / 3.267 | 17 | 9.699 (13) | 30/42 (71.4%) |
| fairies_court | 371.600 / 2,888.500 / 6,684.600 | 1.551 / 1.960 / 2.447 | 16 | 8.663 (15) | 30/43 (69.8%) |
| fairies_ring | 468.800 / 1,770.000 / 11,384.400 | 1.474 / 1.795 / 2.454 | 27 | 6.238 (21) | 37/43 (86.0%) |
| hedgerow_parish | 838.200 / 2,701.000 / 13,848.600 | 1.524 / 2.216 / 2.609 | 14 | 28.687 (13) | 25/43 (58.1%) |
| hedgerow_supper | 468.900 / 3,026.000 / 104,801.700 | 1.624 / 2.083 / 3.541 | 17 | 12.778 (15) | 28/43 (65.1%) |
| hunters_open_season | 751.600 / 4,463.000 / 73,856.800 | 1.628 / 2.673 / 9.435 | 15 | 30.249 (13) | 29/43 (67.4%) |
| hunters_pack | 463.200 / 2,591.000 / 4,181,237.600 | 1.468 / 2.272 / 13.611 | 15 | 13.991 (12) | 30/43 (69.8%) |
| oozes_engine | 1,146.600 / 18,322.000 / 2,742,479,066.600 | 1.398 / 2.388 / 5.050 | 39 | 15.784 (38) | 42/43 (97.7%) |
| oozes_tempo | 1,602.200 / 9,036.500 / 96,631,045.500 | 1.412 / 2.010 / 5.947 | 36 | 7.745 (34) | 42/43 (97.7%) |


Growth >=1.3 all lines: True; engine R12 target band: False (B band reported; C band 1,350-3,600 decides only on the full run).

| Line | R6-R11 growth p10 / median / p90 (n) | R11-R15 growth p10 / median / p90 (n) |
|---|---:|---:|
| birds_homecoming | 1.30 / 1.68 / 2.05 (39) | 1.47 / 1.73 / 2.17 (18) |
| birds_tempo | 1.39 / 1.72 / 2.24 (41) | 1.37 / 1.67 / 2.63 (17) |
| bog_court | 1.45 / 1.66 / 3.68 (34) | 1.60 / 1.87 / 2.60 (14) |
| bog_swamp | 1.40 / 1.65 / 2.26 (38) | 1.72 / 2.19 / 7.43 (13) |
| fairies_court | 1.23 / 1.66 / 1.92 (41) | 1.45 / 1.95 / 2.73 (15) |
| fairies_ring | 1.37 / 1.65 / 2.23 (40) | 1.45 / 1.82 / 2.28 (21) |
| hedgerow_parish | 1.38 / 1.73 / 2.38 (34) | 1.68 / 2.45 / 2.96 (13) |
| hedgerow_supper | 1.29 / 1.81 / 2.83 (35) | 1.57 / 2.34 / 3.45 (15) |
| hunters_open_season | 1.41 / 1.83 / 3.23 (33) | 1.77 / 2.30 / 17.54 (13) |
| hunters_pack | 1.39 / 1.71 / 3.43 (35) | 1.50 / 2.41 / 6.01 (12) |
| oozes_engine | 1.29 / 1.92 / 9.41 (43) | 1.17 / 2.31 / 4.84 (38) |
| oozes_tempo | 1.37 / 2.05 / 9.70 (42) | 1.18 / 1.84 / 3.92 (34) |

### R6-R11 active totals, p10 / median / p90 [share alive]

| Line | R6 | R7 | R8 | R9 | R10 | R11 |
|---|---:|---:|---:|---:|---:|---:|
| birds_homecoming | 42 / 80 / 139 [100%] | 58 / 94 / 223 [100%] | 70 / 143 / 867 [100%] | 118 / 243 / 971 [100%] | 173 / 423 / 2,686 [100%] | 316 / 1,330 / 5,765 [93%] |
| birds_tempo | 38 / 62 / 135 [100%] | 51 / 108 / 179 [100%] | 74 / 175 / 361 [100%] | 102 / 251 / 611 [100%] | 224 / 581 / 2,178 [100%] | 319 / 1,034 / 2,664 [98%] |
| bog_court | 32 / 51 / 112 [100%] | 51 / 88 / 210 [100%] | 76 / 153 / 310 [100%] | 108 / 227 / 618 [100%] | 229 / 445 / 1,207 [98%] | 433 / 1,060 / 32,357 [81%] |
| bog_swamp | 35 / 58 / 110 [100%] | 58 / 100 / 201 [100%] | 66 / 121 / 290 [100%] | 82 / 150 / 675 [100%] | 177 / 402 / 1,333 [98%] | 378 / 912 / 2,927 [90%] |
| fairies_court | 33 / 71 / 124 [100%] | 56 / 107 / 254 [100%] | 78 / 177 / 377 [100%] | 92 / 248 / 693 [100%] | 142 / 484 / 2,082 [100%] | 172 / 692 / 3,021 [95%] |
| fairies_ring | 31 / 75 / 136 [100%] | 47 / 124 / 209 [100%] | 73 / 178 / 405 [100%] | 113 / 257 / 666 [100%] | 204 / 467 / 1,502 [98%] | 345 / 1,076 / 3,843 [93%] |
| hedgerow_parish | 29 / 51 / 132 [100%] | 55 / 100 / 213 [100%] | 64 / 144 / 561 [100%] | 87 / 188 / 1,063 [100%] | 132 / 311 / 3,194 [95%] | 290 / 794 / 4,507 [79%] |
| hedgerow_supper | 38 / 61 / 129 [100%] | 42 / 85 / 265 [100%] | 68 / 150 / 632 [100%] | 106 / 320 / 1,765 [100%] | 118 / 495 / 4,179 [100%] | 253 / 1,298 / 19,290 [81%] |
| hunters_open_season | 34 / 58 / 103 [100%] | 50 / 104 / 202 [100%] | 63 / 135 / 405 [100%] | 89 / 201 / 603 [100%] | 158 / 388 / 3,001 [100%] | 560 / 1,338 / 15,307 [77%] |
| hunters_pack | 30 / 48 / 91 [100%] | 49 / 99 / 176 [100%] | 70 / 126 / 310 [100%] | 97 / 188 / 840 [100%] | 166 / 376 / 3,583 [98%] | 291 / 795 / 24,156 [81%] |
| oozes_engine | 53 / 198 / 6,053 [100%] | 106 / 479 / 43,454 [100%] | 133 / 529 / 248,548 [100%] | 267 / 1,796 / 570,042 [100%] | 357 / 3,265 / 1,159,770 [100%] | 560 / 6,798 / 17,631,135 [100%] |
| oozes_tempo | 53 / 231 / 4,413 [100%] | 88 / 1,120 / 11,776 [100%] | 157 / 1,750 / 46,165 [100%] | 186 / 2,235 / 225,786 [100%] | 597 / 3,747 / 2,595,414 [100%] | 847 / 6,824 / 90,894,566 [98%] |

### R11-R15 active totals, p10 / median / p90 [share alive]

| Line | R11 | R12 | R13 | R14 | R15 |
|---|---:|---:|---:|---:|---:|
| birds_homecoming | 316 / 1,330 / 5,765 [93%] | 644 / 2,879 / 11,344 [76%] | 1,392 / 6,036 / 22,589 [64%] | 2,683 / 11,108 / 27,143 [48%] | 5,896 / 17,062 / 38,328 [43%] |
| birds_tempo | 319 / 1,034 / 2,664 [98%] | 666 / 1,667 / 5,657 [88%] | 1,333 / 3,504 / 14,390 [67%] | 2,111 / 8,046 / 31,983 [43%] | 2,524 / 11,053 / 64,237 [40%] |
| bog_court | 433 / 1,060 / 32,357 [81%] | 841 / 2,037 / 27,644 [67%] | 1,370 / 5,748 / 39,619 [38%] | 2,355 / 11,565 / 87,001 [33%] | 9,044 / 19,822 / 113,902 [33%] |
| bog_swamp | 378 / 912 / 2,927 [90%] | 749 / 2,222 / 16,181 [71%] | 1,814 / 4,056 / 31,262 [55%] | 3,671 / 10,985 / 292,830 [40%] | 9,877 / 33,017 / 17,597,677 [31%] |
| fairies_court | 172 / 692 / 3,021 [95%] | 372 / 2,888 / 6,685 [70%] | 1,253 / 5,362 / 15,276 [49%] | 3,834 / 11,148 / 57,544 [37%] | 5,701 / 28,372 / 77,589 [35%] |
| fairies_ring | 345 / 1,076 / 3,843 [93%] | 469 / 1,770 / 11,384 [86%] | 1,034 / 3,357 / 12,547 [72%] | 1,622 / 8,264 / 81,884 [63%] | 3,503 / 15,390 / 84,248 [49%] |
| hedgerow_parish | 290 / 794 / 4,507 [79%] | 838 / 2,701 / 13,849 [58%] | 1,061 / 6,535 / 76,411 [47%] | 2,304 / 45,268 / 264,552 [33%] | 9,122 / 126,222 / 1,007,936 [30%] |
| hedgerow_supper | 253 / 1,298 / 19,290 [81%] | 469 / 3,026 / 104,802 [65%] | 655 / 10,984 / 454,891 [51%] | 8,067 / 30,043 / 2,742,629 [40%] | 13,684 / 85,205 / 14,110,038 [35%] |
| hunters_open_season | 560 / 1,338 / 15,307 [77%] | 752 / 4,463 / 73,857 [67%] | 3,405 / 16,115 / 111,768 [49%] | 16,113 / 80,773 / 369,098,763 [35%] | 46,566 / 218,243 / 468,279,405 [30%] |
| hunters_pack | 291 / 795 / 24,156 [81%] | 463 / 2,591 / 4,181,238 [70%] | 910 / 6,145 / 4,196,733 [51%] | 1,719 / 22,505 / 1,587,889,168 [35%] | 8,473 / 82,540 / 81,369,620 [28%] |
| oozes_engine | 560 / 6,798 / 17,631,135 [100%] | 1,147 / 18,322 / 2,742,479,067 [98%] | 2,859 / 27,334 / 4,015,771,759 [95%] | 6,805 / 65,157 / 4,555,364,402 [91%] | 10,714 / 347,354 / 6,604,211,441 [88%] |
| oozes_tempo | 847 / 6,824 / 90,894,566 [98%] | 1,602 / 9,036 / 96,631,045 [98%] | 3,796 / 21,657 / 1,191,480,189 [93%] | 7,506 / 84,946 / 7,538,198,449 [84%] | 9,623 / 101,414 / 8,853,451,316 [79%] |

### Field first read

| Line | R10 | R12 | R14 |
|---|---:|---:|---:|
| birds_homecoming | 63.6% | 27.3% | 36.4% |
| birds_tempo | 36.4% | 18.2% | 22.7% |
| bog_court | 0.0% | 90.9% | 90.9% |
| bog_swamp | 45.5% | 81.8% | 9.1% |
| fairies_court | 18.2% | 50.0% | 0.0% |
| fairies_ring | 72.7% | 59.1% | 22.7% |
| hedgerow_parish | 9.1% | 54.5% | 54.5% |
| hedgerow_supper | 63.6% | 72.7% | 63.6% |
| hunters_open_season | 72.7% | 9.1% | 45.5% |
| hunters_pack | 27.3% | 0.0% | 100.0% |
| oozes_engine | 90.9% | 36.4% | 81.8% |
| oozes_tempo | 100.0% | 100.0% | 72.7% |

Order-of-magnitude: `{"14": {"line": "line_hunters_open_season", "ratio": 5.980650835532102, "fires_10x": false, "line_medians": {"line_fairies_court": 11378, "line_fairies_ring": 9522, "line_oozes_tempo": 84946.5, "line_hedgerow_parish": 48406, "line_hunters_open_season": 102000, "line_hunters_pack": 28506.5, "line_hedgerow_supper": 42489, "line_oozes_engine": 75230.0, "line_bog_court": 11565.0, "line_birds_homecoming": 11108.0, "line_bog_swamp": 17055, "line_birds_tempo": 8265}, "tribe_best_medians": {"fairies": 11378, "oozes": 84946.5, "hedgerow": 48406, "hunters": 102000, "bog": 17055, "birds": 11108.0}, "tribe_ratios": {"fairies": 0.23505350576374828, "oozes": 4.980738786279684, "hedgerow": 2.8382292582820288, "hunters": 5.980650835532102, "bog": 0.3523323554931207, "birds": 0.22947568483245878}, "cohort_n": {"line_fairies_court": 15, "line_fairies_ring": 21, "line_oozes_tempo": 34, "line_hedgerow_parish": 13, "line_hunters_open_season": 13, "line_hunters_pack": 12, "line_hedgerow_supper": 15, "line_oozes_engine": 38, "line_bog_court": 14, "line_birds_homecoming": 18, "line_bog_swamp": 13, "line_birds_tempo": 17}, "complete": true}, "15": {"line": "line_oozes_engine", "ratio": 10.520444013689918, "fires_10x": true, "line_medians": {"line_fairies_court": 28372, "line_fairies_ring": 15390, "line_oozes_tempo": 101414.0, "line_hedgerow_parish": 126222, "line_hunters_open_season": 218243, "line_hunters_pack": 82539.5, "line_hedgerow_supper": 85205, "line_oozes_engine": 347353.5, "line_bog_court": 19822.0, "line_birds_homecoming": 17061.5, "line_bog_swamp": 33017, "line_birds_tempo": 11053}, "tribe_best_medians": {"fairies": 28372, "oozes": 347353.5, "hedgerow": 126222, "hunters": 218243, "bog": 33017, "birds": 17061.5}, "tribe_ratios": {"fairies": 0.22477856475099428, "oozes": 10.520444013689918, "hedgerow": 3.8229396977314716, "hunters": 6.610019081079444, "bog": 0.2615788055964887, "birds": 0.13517057248340225}, "cohort_n": {"line_fairies_court": 15, "line_fairies_ring": 21, "line_oozes_tempo": 34, "line_hedgerow_parish": 13, "line_hunters_open_season": 13, "line_hunters_pack": 12, "line_hedgerow_supper": 15, "line_oozes_engine": 38, "line_bog_court": 14, "line_birds_homecoming": 18, "line_bog_swamp": 13, "line_birds_tempo": 17}, "complete": true}}`.

Extreme diagnostics: `{"outside_order_of_magnitude": true, "one_line_wins_regardless_proxy": true, "runaway_snowballs_in_most_lobbies_proxy": false}`.

R8 leader wins: 0.53125; runaway proxy: 0.203125.

Missing field lines: `{"10": [], "12": [], "14": []}`.

Captured active-unit stat-ceiling hits: 368; per-line R6-R15 survival, low-tail and >10x p90 flags, and every cap hit are in report.json.

## Decision detail and audit

B: growth medians range 1.396–1.948×/round; minimum oozes_tempo. Best-line/other-lines median: R14 3.707×, R15 5.887×; all twelve line cohorts represented. Runaway proxy 6/64 lobbies; R8-leader win rate 28.1%.

R12 p10 below 0.25× median: hunters_open_season; p90 above 10× median: none. Stat-ceiling hits: 0.

Throwaway B checkpoint library: `/home/alex/code/Bramble-ideation-b9measure/build/b9-a4/final/B/checkpoint-B.json.gz`; SHA-256 `dfe8bf567fc656deef58cecff619c24b4d323741ce6bd3bd1d8d6ef258cd1106`. 256 complete top-four trajectories, 12 lines; Godot load/session creation passed.

C: growth medians range 1.795–2.673×/round; minimum fairies_ring. Best-line/other-lines median: R14 5.981×, R15 10.520×; all twelve line cohorts represented. Runaway proxy 13/64 lobbies; R8-leader win rate 53.1%.

R12 p10 below 0.25× median: birds_homecoming, fairies_court, hedgerow_supper, hunters_open_season, hunters_pack, oozes_engine, oozes_tempo; p90 above 10× median: bog_court, hedgerow_supper, hunters_open_season, hunters_pack, oozes_engine, oozes_tempo. Stat-ceiling hits: 368.

Throwaway C checkpoint library: `/home/alex/code/Bramble-ideation-b9measure/build/b9-a4/final/C/checkpoint-C.json.gz`; SHA-256 `653ff6b506ac6cfded2128da96e45c2c3a95359cdafd24339a0e1fcd4b26940a`. 256 complete top-four trajectories, 12 lines; Godot load/session creation passed.

The three v3 extremes are a tribe's best line outside an order of magnitude of the others; a line winning whatever the player chooses; and runaway snowballs in most lobbies. The first is read from late same-seat cohorts, the second through DM2's ≥80% points at both R12/R14, and the third through the predeclared ≥10× R14 leader/eventual-winner proxy in >50% of all completed lobbies (using the final pre-fight round when ending before R14). The last two are diagnostic proxies rather than proofs about every player choice. No line is missing from the final field rounds.

Full line-lobby compact records, summaries, sampled fields and pair results are archived beside this README; `report.json.gz` and `receipt.json` preserve all values and hashes. Raw captures, local runner logs and checkpoint bundles remain under `build/b9-a4/final/`. No Actions sims or extra balance arms ran. The source stayed at 31aa4273 throughout capture and library creation.

Reproduce every report cell from the checked-in compact records (no Godot):

```sh
PYTHONPATH=tools/sim:. python3 - <<'PY_REPRO'
from pathlib import Path
import b9_a4_report
from evidence_io import read_json
p = Path('docs/ideation/evidence/b9-measure/a4/full')
assert b9_a4_report.report(p, read_json(p / 'manifest.json')) == read_json(p / 'report.json.gz')
print('All report cells reproduced')
PY_REPRO
```

## Validation

All 128 requested seeds/preset lobbies completed with no drops. Both 396-fight matrices use complete
coverage and at most 22 fights per line per round. Both top4 bundles pass native Godot validation
and session creation. Every line-report cell and field-matrix cell reproduces from the archived inputs.
`scripts/check.sh --docs-only --base 31aa4273` passed: 202 Python tests, Ruff, shellcheck, content,
gdformat --check, gdlint and documentation checks. No Godot test suite was rerun for these evidence-only
changes; the orchestrator owns the merged-source cloud gate. See `validation.log`.

## Review revalidation

The fixed validator (`2a89e251`) accepts every native and compact trajectory: B 512 seats / 7,448 seat-rounds, C 512 / 7,253. Captured rounds exactly match each seat's declared played rounds. No seeds are rejected, so no A4 seeds were rerun. See `revalidation.json`. The report JSON was regenerated with this validator.

The snowball definition is settled: measure whether the eventual winner has a ≥10× pre-fight size lead over the runner-up at R14, or at the final round for a game ending before R14. A positive leader against a zero runner-up qualifies. Divide by **all completed lobbies**; an extreme miss is strictly more than half. This measures a large size lead that converts to victory, rather than player agency. There are no early-ending games in the original B/C samples; counts remain B 6/64 and C 13/64.
