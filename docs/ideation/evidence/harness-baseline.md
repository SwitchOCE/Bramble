# Scale harness baseline: today's pool

9 November 2026. Track A, measured before the caps-off/engine-dial mechanics build.

Frozen harness commit `1a75499`; 500 eight-seat mixed-line lobbies (4,000 seats), seeds 81001-81500. Every lobby used real combat, damage, pool depletion and heroes. The roster was two Hard tempo, two tribal tempo, three engine and one shared fast-tier seat, shuffled by seed. Neutral deals may also resolve to the shared line.

The six fields contain 64 boards each at rounds 6, 8, 10, 12, 14 and 16, sampled with frozen seed 91407. Every unordered pair fought eight replicates in each orientation: 12,096 pairs and 193,536 fights. Layouts were fixed blind before combat. Reservoir sampling includes every represented line; field weights recover each line's actual frequency among surviving lobby boards. Draws earn half a point for ranking.

Runtime: lobby engines 1242.2s (20.70 min), field engines 1469.749s (24.50 min), total engine time 45.20 min. These are summed instrumented run times; process startup, Python analysis, checkpoints and the repository gate are additional. Godot ran sequentially under a 3 GB scope and a timeout.

Elapsed run window: 51.00 min, from 2026-11-09T05:50:13+00:00 to 2026-11-09T06:41:12.949135+00:00, including startup and checkpoint gaps across turns; post-run analysis and checks are additional.

## Does today's pool show the flat shape?

Today's pool still shows the flat median growth shape: R6-16 median stats have linear R²=0.9989, slope 12.127 stats/round. There are 11 of 35,564 board-round snapshots (0.03%) at or above twice their round's pooled median. Thus the literal historical claim of zero 2x boards fails at this larger sample, while typical growth remains close to a straight line. These exceptions do not establish a common compounding engine, and their rarity is not a balance failure. Board-round observations include repeated seats across rounds. This describes the fixed scripts on today's pool, not the ceiling of expert human play.

The 11 tail snapshots belong to 7 seats in 7 of 500 lobbies (1.40%); the largest ratio is 2.385x. Every tail reconciles to at most seven active bodies; reserves are excluded. The [tail audit](harness-baseline/tails.json) retains their identities and unit stats. The 64-board fields can miss such rare boards; tail counts use the full lobby sample.

## Board size and spread

Attack + Health after initial auras, before opponent-dependent Start of Combat effects. Eggs are active bodies; held, away, hand and doorstep bodies are reserves. Round populations contain living seats only; late-round changes also reflect elimination. Stats describe feel; field fights rank strength. Percentiles use linear interpolation; p99 is descriptive. The 2x comparison pools all lines at the same round.

| Round | Boards | p50 | p90 | p99 | p90/p50 | p99/p50 | Share ≥2x |
|---|---|---|---|---|---|---|---|
| 1 | 4000 | 0.000 | 5.000 | 5.000 | n/a | n/a | n/a |
| 2 | 4000 | 9.000 | 13.000 | 15.000 | 1.444 | 1.667 | 0.03% |
| 3 | 4000 | 16.000 | 21.000 | 25.000 | 1.312 | 1.562 | 0.03% |
| 4 | 4000 | 25.000 | 32.000 | 37.000 | 1.280 | 1.480 | 0.00% |
| 5 | 4000 | 33.000 | 42.000 | 50.000 | 1.273 | 1.515 | 0.00% |
| 6 | 4000 | 41.000 | 55.000 | 65.000 | 1.341 | 1.585 | 0.00% |
| 7 | 4000 | 51.000 | 67.000 | 80.000 | 1.314 | 1.569 | 0.05% |
| 8 | 4000 | 61.000 | 81.000 | 100.000 | 1.328 | 1.639 | 0.03% |
| 9 | 3999 | 73.000 | 96.000 | 118.000 | 1.315 | 1.616 | 0.00% |
| 10 | 3956 | 86.000 | 111.500 | 137.450 | 1.297 | 1.598 | 0.03% |
| 11 | 3741 | 98.000 | 126.000 | 153.000 | 1.286 | 1.561 | 0.03% |
| 12 | 3348 | 110.000 | 141.000 | 169.000 | 1.282 | 1.536 | 0.00% |
| 13 | 2815 | 123.000 | 159.000 | 189.860 | 1.293 | 1.544 | 0.04% |
| 14 | 2204 | 135.000 | 176.000 | 213.970 | 1.304 | 1.585 | 0.05% |
| 15 | 1856 | 148.000 | 195.500 | 236.000 | 1.321 | 1.595 | 0.11% |
| 16 | 1645 | 161.000 | 211.000 | 271.120 | 1.311 | 1.684 | 0.12% |
| 17 | 1318 | 176.000 | 230.000 | 299.830 | 1.307 | 1.704 | 0.08% |
| 18 | 1054 | 187.500 | 247.700 | 328.470 | 1.321 | 1.752 | 0.09% |
| 19 | 705 | 200.000 | 268.600 | 355.000 | 1.343 | 1.775 | 0.43% |
| 20 | 336 | 213.500 | 288.000 | 368.300 | 1.349 | 1.725 | 0.60% |
| 21 | 110 | 225.000 | 295.500 | 364.560 | 1.313 | 1.620 | 0.00% |
| 22 | 28 | 205.000 | 283.900 | 332.690 | 1.385 | 1.623 | 0.00% |
| 23 | 2 | 167.000 | 171.000 | 171.900 | 1.024 | 1.029 | 0.00% |

## Own-board growth per turn

Current active stats minus the same seat's previous-round stats.

| Round | N | p50 | p90 | p99 |
|---|---|---|---|---|
| 1 | 0 | n/a | n/a | n/a |
| 2 | 4000 | 8.000 | 13.000 | 15.000 |
| 3 | 4000 | 7.000 | 12.000 | 16.000 |
| 4 | 4000 | 8.000 | 14.000 | 19.000 |
| 5 | 4000 | 8.000 | 15.000 | 22.000 |
| 6 | 4000 | 8.000 | 16.000 | 24.000 |
| 7 | 4000 | 8.000 | 19.000 | 29.000 |
| 8 | 4000 | 9.000 | 22.000 | 32.010 |
| 9 | 3999 | 12.000 | 25.000 | 38.000 |
| 10 | 3956 | 13.000 | 27.000 | 42.450 |
| 11 | 3741 | 10.000 | 23.000 | 36.000 |
| 12 | 3348 | 9.000 | 24.000 | 40.000 |
| 13 | 2815 | 10.000 | 26.000 | 42.000 |
| 14 | 2204 | 10.000 | 25.000 | 44.000 |
| 15 | 1856 | 10.000 | 26.000 | 55.900 |
| 16 | 1645 | 10.000 | 28.000 | 57.680 |
| 17 | 1318 | 10.000 | 27.300 | 53.000 |
| 18 | 1054 | 8.500 | 28.000 | 54.000 |
| 19 | 705 | 9.000 | 28.000 | 51.000 |
| 20 | 336 | 8.000 | 30.000 | 55.650 |
| 21 | 110 | 6.000 | 26.300 | 56.550 |
| 22 | 28 | 6.000 | 19.300 | 30.220 |
| 23 | 2 | 3.000 | 5.400 | 5.940 |

## Own-board growth ratio

Current / previous own active stats; zero denominators excluded.

| Round | N | p50 | p90 | p99 |
|---|---|---|---|---|
| 1 | 0 | n/a | n/a | n/a |
| 2 | 1149 | 2.000 | 2.667 | 4.000 |
| 3 | 4000 | 1.750 | 2.600 | 4.667 |
| 4 | 4000 | 1.526 | 1.929 | 2.700 |
| 5 | 4000 | 1.318 | 1.750 | 2.286 |
| 6 | 4000 | 1.226 | 1.500 | 1.878 |
| 7 | 4000 | 1.200 | 1.512 | 1.829 |
| 8 | 4000 | 1.169 | 1.451 | 1.875 |
| 9 | 3999 | 1.193 | 1.506 | 2.036 |
| 10 | 3956 | 1.175 | 1.414 | 1.827 |
| 11 | 3741 | 1.111 | 1.281 | 1.481 |
| 12 | 3348 | 1.094 | 1.255 | 1.439 |
| 13 | 2815 | 1.088 | 1.238 | 1.417 |
| 14 | 2204 | 1.077 | 1.209 | 1.370 |
| 15 | 1856 | 1.069 | 1.199 | 1.405 |
| 16 | 1645 | 1.067 | 1.188 | 1.378 |
| 17 | 1318 | 1.059 | 1.162 | 1.347 |
| 18 | 1054 | 1.049 | 1.145 | 1.284 |
| 19 | 705 | 1.045 | 1.147 | 1.263 |
| 20 | 336 | 1.043 | 1.128 | 1.239 |
| 21 | 110 | 1.032 | 1.118 | 1.236 |
| 22 | 28 | 1.028 | 1.073 | 1.120 |
| 23 | 2 | 1.018 | 1.033 | 1.036 |

## Stats per gold by round

Current active stats / cumulative gold spent, including climbs, refreshes and spells.

| Round | N | p50 | p90 | p99 |
|---|---|---|---|---|
| 1 | 4000 | 0.000 | 1.667 | 1.667 |
| 2 | 4000 | 1.250 | 1.429 | 1.571 |
| 3 | 4000 | 1.133 | 1.429 | 1.667 |
| 4 | 4000 | 1.190 | 1.476 | 1.700 |
| 5 | 4000 | 1.121 | 1.400 | 1.656 |
| 6 | 4000 | 1.067 | 1.417 | 1.703 |
| 7 | 4000 | 1.047 | 1.353 | 1.625 |
| 8 | 4000 | 1.000 | 1.305 | 1.633 |
| 9 | 3999 | 0.987 | 1.283 | 1.569 |
| 10 | 3956 | 1.000 | 1.287 | 1.581 |
| 11 | 3741 | 1.000 | 1.270 | 1.523 |
| 12 | 3348 | 1.000 | 1.260 | 1.532 |
| 13 | 2815 | 1.008 | 1.274 | 1.521 |
| 14 | 2204 | 1.016 | 1.305 | 1.570 |
| 15 | 1856 | 1.019 | 1.323 | 1.579 |
| 16 | 1645 | 1.032 | 1.333 | 1.653 |
| 17 | 1318 | 1.046 | 1.341 | 1.713 |
| 18 | 1054 | 1.046 | 1.365 | 1.836 |
| 19 | 705 | 1.049 | 1.399 | 1.900 |
| 20 | 336 | 1.048 | 1.433 | 1.928 |
| 21 | 110 | 1.035 | 1.396 | 1.690 |
| 22 | 28 | 0.974 | 1.264 | 1.346 |
| 23 | 2 | 0.753 | 0.776 | 0.781 |

## Incremental growth per gold

Own-board growth / that turn's gold spent; zero denominators excluded.

| Round | N | p50 | p90 | p99 |
|---|---|---|---|---|
| 1 | 0 | n/a | n/a | n/a |
| 2 | 4000 | 1.286 | 1.667 | 1.667 |
| 3 | 4000 | 1.000 | 1.714 | 2.250 |
| 4 | 4000 | 1.400 | 2.143 | 2.750 |
| 5 | 4000 | 0.909 | 2.000 | 2.750 |
| 6 | 4000 | 0.818 | 2.125 | 3.222 |
| 7 | 3985 | 0.818 | 2.000 | 3.125 |
| 8 | 3995 | 0.714 | 1.818 | 3.000 |
| 9 | 3988 | 0.917 | 2.000 | 3.200 |
| 10 | 3952 | 1.000 | 2.000 | 3.418 |
| 11 | 3738 | 0.818 | 2.000 | 3.500 |
| 12 | 3345 | 0.786 | 2.083 | 3.734 |
| 13 | 2813 | 0.833 | 2.300 | 3.993 |
| 14 | 2200 | 0.833 | 2.231 | 3.800 |
| 15 | 1855 | 0.812 | 2.429 | 4.841 |
| 16 | 1645 | 0.875 | 2.600 | 5.336 |
| 17 | 1317 | 0.846 | 2.400 | 4.453 |
| 18 | 1054 | 0.800 | 2.500 | 5.300 |
| 19 | 705 | 0.800 | 2.800 | 4.992 |
| 20 | 336 | 0.800 | 2.600 | 4.788 |
| 21 | 110 | 0.608 | 2.236 | 4.698 |
| 22 | 28 | 0.633 | 1.690 | 2.608 |
| 23 | 2 | 0.250 | 0.450 | 0.495 |

## Biggest body's share

Largest active body's Attack + Health divided by active board stats.

| Round | N | p50 | p90 | p99 |
|---|---|---|---|---|
| 1 | 4000 | 0.00% | 100.00% | 100.00% |
| 2 | 4000 | 55.56% | 70.00% | 100.00% |
| 3 | 4000 | 41.18% | 55.56% | 70.00% |
| 4 | 4000 | 33.33% | 47.37% | 61.90% |
| 5 | 4000 | 29.17% | 41.67% | 54.06% |
| 6 | 4000 | 27.59% | 40.43% | 52.38% |
| 7 | 4000 | 26.67% | 39.22% | 51.61% |
| 8 | 4000 | 26.17% | 37.78% | 50.98% |
| 9 | 3999 | 25.29% | 35.19% | 46.79% |
| 10 | 3956 | 24.24% | 33.33% | 44.67% |
| 11 | 3741 | 24.27% | 33.33% | 44.92% |
| 12 | 3348 | 24.69% | 33.75% | 45.03% |
| 13 | 2815 | 25.00% | 34.38% | 44.73% |
| 14 | 2204 | 25.29% | 35.29% | 46.85% |
| 15 | 1856 | 25.49% | 35.54% | 46.64% |
| 16 | 1645 | 25.47% | 35.62% | 46.69% |
| 17 | 1318 | 25.29% | 35.91% | 47.64% |
| 18 | 1054 | 24.90% | 36.25% | 48.94% |
| 19 | 705 | 25.13% | 35.86% | 49.98% |
| 20 | 336 | 24.88% | 36.37% | 49.52% |
| 21 | 110 | 26.09% | 37.46% | 43.53% |
| 22 | 28 | 25.83% | 37.37% | 42.53% |
| 23 | 2 | 24.88% | 25.72% | 25.91% |

## Tier-up arrivals against the owner's median unit

The first newly fielded body of each newly unlocked tier is compared with the owner's median active unit before that climb. Arrival can be later than the climb. Printed stats exclude effects; golden printed stats are doubled. Unseen arrivals are excluded.

| Tier | N | Aura p50 | Aura p90 | Aura p99 | Printed p50 | Printed p90 | Printed p99 |
|---|---|---|---|---|---|---|---|
| 2 | 3256 | 1.200 | 2.000 | 2.857 | 1.143 | 1.500 | 2.000 |
| 3 | 3077 | 1.400 | 2.333 | 3.500 | 1.333 | 1.750 | 2.333 |
| 4 | 3250 | 1.556 | 2.400 | 3.775 | 1.333 | 1.800 | 3.000 |
| 5 | 3575 | 1.625 | 2.600 | 4.259 | 1.375 | 2.200 | 3.333 |
| 6 | 2714 | 1.333 | 2.500 | 3.825 | 1.143 | 2.286 | 3.200 |

## Reserve stats

Attack + Health outside the active board, without board auras; absent reserves count as zero.

| Round | Location | N | p50 | p90 | p99 |
|---|---|---|---|---|---|
| 2 | belly | 4000 | 0.000 | 0.000 | 4.000 |
| 3 | away | 4000 | 0.000 | 0.000 | 3.000 |
| 3 | belly | 4000 | 0.000 | 0.000 | 5.000 |
| 4 | away | 4000 | 0.000 | 0.000 | 3.000 |
| 4 | belly | 4000 | 0.000 | 3.000 | 8.000 |
| 4 | hand | 4000 | 0.000 | 0.000 | 0.000 |
| 5 | away | 4000 | 0.000 | 0.000 | 6.000 |
| 5 | belly | 4000 | 0.000 | 5.000 | 11.000 |
| 5 | hand | 4000 | 0.000 | 0.000 | 0.000 |
| 6 | away | 4000 | 0.000 | 0.000 | 7.000 |
| 6 | belly | 4000 | 0.000 | 8.000 | 16.000 |
| 6 | hand | 4000 | 0.000 | 0.000 | 5.000 |
| 7 | away | 4000 | 0.000 | 0.000 | 9.000 |
| 7 | belly | 4000 | 0.000 | 12.000 | 21.010 |
| 7 | hand | 4000 | 0.000 | 0.000 | 7.000 |
| 8 | away | 4000 | 0.000 | 0.000 | 12.000 |
| 8 | belly | 4000 | 0.000 | 15.000 | 29.000 |
| 8 | hand | 4000 | 0.000 | 0.000 | 11.000 |
| 9 | away | 3999 | 0.000 | 0.000 | 18.000 |
| 9 | belly | 3999 | 0.000 | 20.000 | 38.000 |
| 9 | hand | 3999 | 0.000 | 6.000 | 15.020 |
| 10 | away | 3956 | 0.000 | 0.000 | 24.450 |
| 10 | belly | 3956 | 0.000 | 25.000 | 47.450 |
| 10 | hand | 3956 | 0.000 | 9.000 | 21.450 |
| 11 | away | 3741 | 0.000 | 0.000 | 34.000 |
| 11 | belly | 3741 | 0.000 | 28.000 | 57.000 |
| 11 | hand | 3741 | 0.000 | 13.000 | 26.000 |
| 12 | away | 3348 | 0.000 | 0.000 | 42.000 |
| 12 | belly | 3348 | 0.000 | 32.000 | 67.530 |
| 12 | hand | 3348 | 0.000 | 16.000 | 31.000 |
| 13 | away | 2815 | 0.000 | 0.000 | 44.860 |
| 13 | belly | 2815 | 0.000 | 34.000 | 75.860 |
| 13 | hand | 2815 | 0.000 | 18.000 | 37.000 |
| 14 | away | 2204 | 0.000 | 0.000 | 52.000 |
| 14 | belly | 2204 | 0.000 | 36.000 | 86.880 |
| 14 | hand | 2204 | 0.000 | 20.000 | 39.970 |
| 15 | away | 1856 | 0.000 | 0.000 | 53.450 |
| 15 | belly | 1856 | 0.000 | 38.000 | 95.000 |
| 15 | hand | 1856 | 8.000 | 24.000 | 44.000 |
| 16 | away | 1645 | 0.000 | 0.000 | 60.560 |
| 16 | belly | 1645 | 0.000 | 38.000 | 100.120 |
| 16 | hand | 1645 | 12.000 | 27.000 | 46.000 |
| 17 | away | 1318 | 0.000 | 0.000 | 63.660 |
| 17 | belly | 1318 | 0.000 | 40.300 | 110.660 |
| 17 | hand | 1318 | 12.000 | 30.000 | 50.000 |
| 18 | away | 1054 | 0.000 | 0.000 | 72.820 |
| 18 | belly | 1054 | 0.000 | 42.000 | 119.470 |
| 18 | hand | 1054 | 14.000 | 30.000 | 50.000 |
| 19 | away | 705 | 0.000 | 0.000 | 83.600 |
| 19 | belly | 705 | 0.000 | 42.600 | 115.960 |
| 19 | hand | 705 | 14.000 | 34.000 | 56.000 |
| 20 | away | 336 | 0.000 | 0.000 | 72.600 |
| 20 | belly | 336 | 0.000 | 48.500 | 122.600 |
| 20 | hand | 336 | 14.000 | 42.000 | 76.950 |
| 21 | away | 110 | 0.000 | 0.000 | 25.480 |
| 21 | belly | 110 | 0.000 | 50.400 | 144.670 |
| 21 | hand | 110 | 16.500 | 34.200 | 61.820 |
| 22 | belly | 28 | 0.000 | 38.500 | 94.690 |
| 22 | hand | 28 | 18.000 | 41.800 | 65.840 |
| 23 | belly | 2 | 15.000 | 27.000 | 29.700 |
| 23 | hand | 2 | 54.000 | 65.200 | 67.720 |

## Outcomes

Leader ties split credit. Below-median boards are strict comparisons. 95% intervals use 2,000 fixed bootstrap resamples of whole lobby seeds, never individual seats.

| Metric | N | Seed clusters | Rate | 95% CI |
|---|---|---|---|---|
| Round-8 stat leader wins | 500 | 500 | 22.70% | 19.10%-26.40% |
| Round-8 Health leader wins | 500 | 500 | 14.77% | 11.80%-17.80% |
| Below pooled R8 median finishes top 2 | 1981 | 500 | 18.02% | 16.68%-19.38% |
| Below own-lobby R8 median finishes top 2 | 1944 | 500 | 17.95% | 16.49%-19.38% |

First-place game length: N=500; p50=19.000, p90=21.000, p99=22.000; mean=18.992, range=15-23 rounds.

Compare the plan's 14-16 round target with this measured game length; this is the baseline damage configuration, not a tuned replacement.

Rounds 10-14: 6048 unordered field pairs. Winner probability is conditional on a decisive fight; all-draw pairs are excluded from uncertain winners but remain in the denominator. Each pair has 16 trials.

| Metric | Share |
|---|---|
| Pairs with point probability 20-80% | 17.82% |
| Same, weighted by field population | 17.74% |
| Pairs whose entire Wilson 95% interval is inside 20-80% | 5.36% |
| All-draw pairs | 0.00% |

## Weighted field results

Rates are wins plus half draws, excluding self-fights. A board's opponents are weighted by their represented line frequencies. Hard is included as the tempo anchor, so the strongest line being at least as strong as Hard is an inclusion check, not evidence that a tribal script beats Hard.

### Round 6

Strongest sampled line: `line_hedgerow_tempo`. Hard-floor check: pass.

| Line | Selected boards | Population weight | Field point rate |
|---|---|---|---|
| hard | 16 | 25.00% | 62.03% |
| line_birds_engine | 3 | 5.22% | 17.97% |
| line_birds_tempo | 2 | 3.33% | 48.59% |
| line_bog_engine | 3 | 5.15% | 31.11% |
| line_bog_tempo | 2 | 3.35% | 55.83% |
| line_fairies_engine | 4 | 6.70% | 42.21% |
| line_fairies_tempo | 3 | 4.58% | 33.39% |
| line_fast | 15 | 23.18% | 60.93% |
| line_hedgerow_engine | 2 | 3.48% | 47.69% |
| line_hedgerow_tempo | 2 | 2.20% | 77.84% |
| line_hunters_engine | 4 | 5.50% | 46.49% |
| line_hunters_tempo | 2 | 3.45% | 54.61% |
| line_oozes_engine | 4 | 5.35% | 23.89% |
| line_oozes_tempo | 2 | 3.52% | 25.35% |

Matrix key: 1=`hard`; 2=`line_birds_engine`; 3=`line_birds_tempo`; 4=`line_bog_engine`; 5=`line_bog_tempo`; 6=`line_fairies_engine`; 7=`line_fairies_tempo`; 8=`line_fast`; 9=`line_hedgerow_engine`; 10=`line_hedgerow_tempo`; 11=`line_hunters_engine`; 12=`line_hunters_tempo`; 13=`line_oozes_engine`; 14=`line_oozes_tempo`.

| Row vs column | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 50.00% | 89.84% | 66.80% | 78.52% | 63.67% | 68.90% | 84.11% | 50.23% | 63.09% | 35.94% | 61.33% | 60.94% | 87.01% | 85.94% |
| 2 | 10.16% | 50.00% | 12.50% | 34.72% | 2.08% | 26.04% | 20.14% | 10.83% | 27.08% | 2.08% | 27.08% | 4.17% | 38.54% | 35.42% |
| 3 | 33.20% | 87.50% | 50.00% | 60.42% | 23.44% | 51.56% | 75.00% | 40.00% | 50.00% | 9.38% | 54.69% | 26.56% | 90.62% | 93.75% |
| 4 | 21.48% | 65.28% | 39.58% | 50.00% | 18.75% | 41.67% | 34.72% | 18.89% | 45.83% | 5.21% | 39.58% | 12.50% | 58.85% | 54.17% |
| 5 | 36.33% | 97.92% | 76.56% | 81.25% | 50.00% | 64.06% | 78.12% | 45.83% | 50.00% | 9.38% | 53.12% | 51.56% | 89.84% | 90.62% |
| 6 | 31.10% | 73.96% | 48.44% | 58.33% | 35.94% | 50.00% | 56.25% | 33.02% | 38.28% | 5.47% | 49.22% | 35.94% | 64.06% | 70.31% |
| 7 | 15.89% | 79.86% | 25.00% | 65.28% | 21.88% | 43.75% | 50.00% | 19.03% | 35.42% | 6.25% | 44.79% | 34.37% | 72.40% | 58.33% |
| 8 | 49.77% | 89.17% | 60.00% | 81.11% | 54.17% | 66.98% | 80.97% | 50.00% | 59.58% | 35.00% | 61.87% | 57.92% | 84.90% | 88.33% |
| 9 | 36.91% | 72.92% | 50.00% | 54.17% | 50.00% | 61.72% | 64.58% | 40.42% | 50.00% | 18.75% | 43.75% | 43.75% | 65.63% | 71.88% |
| 10 | 64.06% | 97.92% | 90.63% | 94.79% | 90.62% | 94.53% | 93.75% | 65.00% | 81.25% | 50.00% | 70.31% | 95.31% | 96.87% | 100.00% |
| 11 | 38.67% | 72.92% | 45.31% | 60.42% | 46.88% | 50.78% | 55.21% | 38.12% | 56.25% | 29.69% | 50.00% | 38.28% | 62.89% | 58.59% |
| 12 | 39.06% | 95.83% | 73.44% | 87.50% | 48.44% | 64.06% | 65.62% | 42.08% | 56.25% | 4.69% | 61.72% | 50.00% | 82.81% | 71.88% |
| 13 | 12.99% | 61.46% | 9.38% | 41.15% | 10.16% | 35.94% | 27.60% | 15.10% | 34.38% | 3.12% | 37.11% | 17.19% | 50.00% | 35.94% |
| 14 | 14.06% | 64.58% | 6.25% | 45.83% | 9.38% | 29.69% | 41.67% | 11.67% | 28.12% | 0.00% | 41.41% | 28.12% | 64.06% | 50.00% |

### Round 8

Strongest sampled line: `hard`. Hard-floor check: pass.

| Line | Selected boards | Population weight | Field point rate |
|---|---|---|---|
| hard | 16 | 25.00% | 69.98% |
| line_birds_engine | 3 | 5.22% | 14.21% |
| line_birds_tempo | 2 | 3.33% | 20.81% |
| line_bog_engine | 3 | 5.15% | 40.15% |
| line_bog_tempo | 2 | 3.35% | 54.88% |
| line_fairies_engine | 4 | 6.70% | 49.18% |
| line_fairies_tempo | 3 | 4.58% | 39.78% |
| line_fast | 15 | 23.18% | 51.99% |
| line_hedgerow_engine | 2 | 3.48% | 25.41% |
| line_hedgerow_tempo | 2 | 2.20% | 42.20% |
| line_hunters_engine | 4 | 5.50% | 37.64% |
| line_hunters_tempo | 2 | 3.45% | 30.72% |
| line_oozes_engine | 4 | 5.35% | 57.91% |
| line_oozes_tempo | 2 | 3.52% | 55.39% |

Matrix key: 1=`hard`; 2=`line_birds_engine`; 3=`line_birds_tempo`; 4=`line_bog_engine`; 5=`line_bog_tempo`; 6=`line_fairies_engine`; 7=`line_fairies_tempo`; 8=`line_fast`; 9=`line_hedgerow_engine`; 10=`line_hedgerow_tempo`; 11=`line_hunters_engine`; 12=`line_hunters_tempo`; 13=`line_oozes_engine`; 14=`line_oozes_tempo`.

| Row vs column | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 50.00% | 98.31% | 94.34% | 68.23% | 75.59% | 71.09% | 83.46% | 69.95% | 97.07% | 68.95% | 79.49% | 86.13% | 63.09% | 69.53% |
| 2 | 1.69% | 50.00% | 46.88% | 44.44% | 0.00% | 5.21% | 10.42% | 8.61% | 8.33% | 50.00% | 31.25% | 47.92% | 6.25% | 1.04% |
| 3 | 5.66% | 53.13% | 50.00% | 43.75% | 3.12% | 20.31% | 27.08% | 15.42% | 32.81% | 50.00% | 36.72% | 50.00% | 10.16% | 10.94% |
| 4 | 31.77% | 55.56% | 56.25% | 50.00% | 33.33% | 34.37% | 44.44% | 38.33% | 50.00% | 51.04% | 48.96% | 50.00% | 34.90% | 43.75% |
| 5 | 24.41% | 100.00% | 96.88% | 66.67% | 50.00% | 67.19% | 66.67% | 54.38% | 100.00% | 51.56% | 68.75% | 75.00% | 42.97% | 48.44% |
| 6 | 28.91% | 94.79% | 79.69% | 65.62% | 32.81% | 50.00% | 56.25% | 45.73% | 71.88% | 62.50% | 60.55% | 67.19% | 44.14% | 42.19% |
| 7 | 16.54% | 89.58% | 72.92% | 55.56% | 33.33% | 43.75% | 50.00% | 39.03% | 67.71% | 50.00% | 50.52% | 55.21% | 27.60% | 23.96% |
| 8 | 30.05% | 91.39% | 84.58% | 61.67% | 45.63% | 54.27% | 60.97% | 50.00% | 81.46% | 57.08% | 67.40% | 71.67% | 42.19% | 46.04% |
| 9 | 2.93% | 91.67% | 67.19% | 50.00% | 0.00% | 28.12% | 32.29% | 18.54% | 50.00% | 50.00% | 35.94% | 50.00% | 20.31% | 6.25% |
| 10 | 31.05% | 50.00% | 50.00% | 48.96% | 48.44% | 37.50% | 50.00% | 42.92% | 50.00% | 50.00% | 54.69% | 50.00% | 39.84% | 46.88% |
| 11 | 20.51% | 68.75% | 63.28% | 51.04% | 31.25% | 39.45% | 49.48% | 32.60% | 64.06% | 45.31% | 50.00% | 58.59% | 34.38% | 28.91% |
| 12 | 13.87% | 52.08% | 50.00% | 50.00% | 25.00% | 32.81% | 44.79% | 28.33% | 50.00% | 50.00% | 41.41% | 50.00% | 23.44% | 25.00% |
| 13 | 36.91% | 93.75% | 89.84% | 65.10% | 57.03% | 55.86% | 72.40% | 57.81% | 79.69% | 60.16% | 65.62% | 76.56% | 50.00% | 55.47% |
| 14 | 30.47% | 98.96% | 89.06% | 56.25% | 51.56% | 57.81% | 76.04% | 53.96% | 93.75% | 53.12% | 71.09% | 75.00% | 44.53% | 50.00% |

### Round 10

Strongest sampled line: `line_hunters_tempo`. Hard-floor check: pass.

| Line | Selected boards | Population weight | Field point rate |
|---|---|---|---|
| hard | 16 | 25.25% | 59.35% |
| line_birds_engine | 3 | 5.13% | 29.63% |
| line_birds_tempo | 2 | 3.36% | 31.99% |
| line_bog_engine | 3 | 5.06% | 31.28% |
| line_bog_tempo | 2 | 3.39% | 32.58% |
| line_fairies_engine | 4 | 6.60% | 46.34% |
| line_fairies_tempo | 3 | 4.60% | 44.97% |
| line_fast | 15 | 23.38% | 56.93% |
| line_hedgerow_engine | 2 | 3.44% | 71.36% |
| line_hedgerow_tempo | 2 | 2.20% | 44.71% |
| line_hunters_engine | 4 | 5.46% | 50.36% |
| line_hunters_tempo | 2 | 3.49% | 79.84% |
| line_oozes_engine | 4 | 5.16% | 34.31% |
| line_oozes_tempo | 2 | 3.49% | 15.83% |

Matrix key: 1=`hard`; 2=`line_birds_engine`; 3=`line_birds_tempo`; 4=`line_bog_engine`; 5=`line_bog_tempo`; 6=`line_fairies_engine`; 7=`line_fairies_tempo`; 8=`line_fast`; 9=`line_hedgerow_engine`; 10=`line_hedgerow_tempo`; 11=`line_hunters_engine`; 12=`line_hunters_tempo`; 13=`line_oozes_engine`; 14=`line_oozes_tempo`.

| Row vs column | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 50.00% | 77.21% | 77.34% | 81.38% | 76.56% | 62.01% | 64.06% | 52.99% | 37.70% | 65.82% | 59.18% | 25.39% | 75.29% | 89.84% |
| 2 | 22.79% | 50.00% | 43.75% | 36.11% | 33.33% | 30.21% | 35.42% | 27.36% | 30.21% | 32.29% | 29.17% | 14.58% | 36.98% | 41.67% |
| 3 | 22.66% | 56.25% | 50.00% | 50.00% | 50.00% | 32.81% | 29.17% | 28.75% | 18.75% | 34.38% | 27.34% | 6.25% | 49.22% | 54.69% |
| 4 | 18.62% | 63.89% | 50.00% | 50.00% | 38.54% | 40.63% | 36.11% | 24.44% | 9.38% | 37.50% | 29.17% | 0.00% | 43.75% | 87.50% |
| 5 | 23.44% | 66.67% | 50.00% | 61.46% | 50.00% | 40.63% | 39.58% | 19.58% | 6.25% | 46.88% | 15.62% | 0.00% | 48.44% | 96.88% |
| 6 | 37.99% | 69.79% | 67.19% | 59.38% | 59.38% | 50.00% | 53.12% | 39.17% | 28.13% | 53.12% | 42.19% | 26.56% | 61.72% | 71.88% |
| 7 | 35.94% | 64.58% | 70.83% | 63.89% | 60.42% | 46.88% | 50.00% | 39.17% | 26.04% | 35.42% | 44.79% | 22.92% | 61.46% | 67.71% |
| 8 | 47.01% | 72.64% | 71.25% | 75.56% | 80.42% | 60.83% | 60.83% | 50.00% | 34.38% | 60.62% | 59.06% | 27.71% | 73.65% | 93.96% |
| 9 | 62.30% | 69.79% | 81.25% | 90.62% | 93.75% | 71.88% | 73.96% | 65.63% | 50.00% | 78.12% | 85.16% | 53.12% | 82.81% | 100.00% |
| 10 | 34.18% | 67.71% | 65.62% | 62.50% | 53.12% | 46.87% | 64.58% | 39.37% | 21.88% | 50.00% | 32.81% | 9.38% | 69.53% | 76.56% |
| 11 | 40.82% | 70.83% | 72.66% | 70.83% | 84.37% | 57.81% | 55.21% | 40.94% | 14.84% | 67.19% | 50.00% | 3.12% | 69.53% | 91.41% |
| 12 | 74.61% | 85.42% | 93.75% | 100.00% | 100.00% | 73.44% | 77.08% | 72.29% | 46.88% | 90.62% | 96.88% | 50.00% | 98.44% | 100.00% |
| 13 | 24.71% | 63.02% | 50.78% | 56.25% | 51.56% | 38.28% | 38.54% | 26.35% | 17.19% | 30.47% | 30.47% | 1.56% | 50.00% | 78.13% |
| 14 | 10.16% | 58.33% | 45.31% | 12.50% | 3.12% | 28.13% | 32.29% | 6.04% | 0.00% | 23.44% | 8.59% | 0.00% | 21.88% | 50.00% |

### Round 12

Strongest sampled line: `line_hedgerow_tempo`. Hard-floor check: pass.

| Line | Selected boards | Population weight | Field point rate |
|---|---|---|---|
| hard | 18 | 28.46% | 43.04% |
| line_birds_engine | 3 | 3.79% | 28.13% |
| line_birds_tempo | 2 | 3.20% | 47.40% |
| line_bog_engine | 2 | 3.79% | 43.17% |
| line_bog_tempo | 2 | 3.52% | 41.10% |
| line_fairies_engine | 4 | 5.38% | 42.88% |
| line_fairies_tempo | 3 | 4.84% | 49.97% |
| line_fast | 16 | 24.82% | 51.03% |
| line_hedgerow_engine | 2 | 3.43% | 70.88% |
| line_hedgerow_tempo | 2 | 2.33% | 87.95% |
| line_hunters_engine | 3 | 5.29% | 67.70% |
| line_hunters_tempo | 2 | 3.79% | 70.48% |
| line_oozes_engine | 3 | 3.91% | 66.56% |
| line_oozes_tempo | 2 | 3.43% | 39.37% |

Matrix key: 1=`hard`; 2=`line_birds_engine`; 3=`line_birds_tempo`; 4=`line_bog_engine`; 5=`line_bog_tempo`; 6=`line_fairies_engine`; 7=`line_fairies_tempo`; 8=`line_fast`; 9=`line_hedgerow_engine`; 10=`line_hedgerow_tempo`; 11=`line_hunters_engine`; 12=`line_hunters_tempo`; 13=`line_oozes_engine`; 14=`line_oozes_tempo`.

| Row vs column | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 50.00% | 60.65% | 51.91% | 52.08% | 51.56% | 52.78% | 42.48% | 40.67% | 25.35% | 15.10% | 21.99% | 20.66% | 27.66% | 56.08% |
| 2 | 39.35% | 50.00% | 45.83% | 41.67% | 42.71% | 38.54% | 30.56% | 20.57% | 1.04% | 0.00% | 0.69% | 4.17% | 16.67% | 35.42% |
| 3 | 48.09% | 54.17% | 50.00% | 43.75% | 53.12% | 40.62% | 70.83% | 53.32% | 71.88% | 0.00% | 29.17% | 31.25% | 30.21% | 39.06% |
| 4 | 47.92% | 58.33% | 56.25% | 50.00% | 46.88% | 38.28% | 45.83% | 44.73% | 31.25% | 7.81% | 29.17% | 28.12% | 29.17% | 50.00% |
| 5 | 48.44% | 57.29% | 46.88% | 53.12% | 50.00% | 43.75% | 48.96% | 39.26% | 21.87% | 0.00% | 19.79% | 25.00% | 29.17% | 48.44% |
| 6 | 47.22% | 61.46% | 59.37% | 61.72% | 56.25% | 50.00% | 46.35% | 41.50% | 15.62% | 9.38% | 38.02% | 23.44% | 21.88% | 35.94% |
| 7 | 57.52% | 69.44% | 29.17% | 54.17% | 51.04% | 53.65% | 50.00% | 55.21% | 11.46% | 17.71% | 34.72% | 27.08% | 34.72% | 62.50% |
| 8 | 59.33% | 79.43% | 46.68% | 55.27% | 60.74% | 58.50% | 44.79% | 50.00% | 24.61% | 3.91% | 38.54% | 35.55% | 30.47% | 62.50% |
| 9 | 74.65% | 98.96% | 28.12% | 68.75% | 78.12% | 84.38% | 88.54% | 75.39% | 50.00% | 29.69% | 36.46% | 45.31% | 62.50% | 93.75% |
| 10 | 84.90% | 100.00% | 100.00% | 92.19% | 100.00% | 90.63% | 82.29% | 96.09% | 70.31% | 50.00% | 81.25% | 56.25% | 81.25% | 100.00% |
| 11 | 78.01% | 99.31% | 70.83% | 70.83% | 80.21% | 61.98% | 65.28% | 61.46% | 63.54% | 18.75% | 50.00% | 53.12% | 52.08% | 75.00% |
| 12 | 79.34% | 95.83% | 68.75% | 71.88% | 75.00% | 76.56% | 72.92% | 64.45% | 54.69% | 43.75% | 46.87% | 50.00% | 54.17% | 95.31% |
| 13 | 72.34% | 83.33% | 69.79% | 70.83% | 70.83% | 78.13% | 65.28% | 69.53% | 37.50% | 18.75% | 47.92% | 45.83% | 50.00% | 76.04% |
| 14 | 43.92% | 64.58% | 60.94% | 50.00% | 51.56% | 64.06% | 37.50% | 37.50% | 6.25% | 0.00% | 25.00% | 4.69% | 23.96% | 50.00% |

### Round 14

Strongest sampled line: `line_bog_tempo`. Hard-floor check: pass.

| Line | Selected boards | Population weight | Field point rate |
|---|---|---|---|
| hard | 19 | 29.08% | 41.82% |
| line_birds_engine | 1 | 2.22% | 62.85% |
| line_birds_tempo | 1 | 2.27% | 58.74% |
| line_bog_engine | 2 | 2.86% | 53.56% |
| line_bog_tempo | 2 | 3.22% | 76.90% |
| line_fairies_engine | 3 | 4.81% | 14.09% |
| line_fairies_tempo | 3 | 4.49% | 48.22% |
| line_fast | 17 | 26.77% | 57.61% |
| line_hedgerow_engine | 3 | 4.45% | 57.77% |
| line_hedgerow_tempo | 2 | 3.31% | 73.77% |
| line_hunters_engine | 4 | 5.58% | 46.69% |
| line_hunters_tempo | 3 | 4.45% | 58.25% |
| line_oozes_engine | 2 | 3.40% | 36.28% |
| line_oozes_tempo | 2 | 3.09% | 45.17% |

Matrix key: 1=`hard`; 2=`line_birds_engine`; 3=`line_birds_tempo`; 4=`line_bog_engine`; 5=`line_bog_tempo`; 6=`line_fairies_engine`; 7=`line_fairies_tempo`; 8=`line_fast`; 9=`line_hedgerow_engine`; 10=`line_hedgerow_tempo`; 11=`line_hunters_engine`; 12=`line_hunters_tempo`; 13=`line_oozes_engine`; 14=`line_oozes_tempo`.

| Row vs column | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 50.00% | 29.93% | 33.22% | 35.69% | 15.79% | 73.25% | 44.52% | 33.55% | 39.47% | 24.67% | 44.49% | 34.87% | 58.72% | 43.75% |
| 2 | 70.07% | n/a | 75.00% | 68.75% | 0.00% | 100.00% | 70.83% | 64.34% | 33.33% | 15.62% | 54.69% | 39.58% | 84.38% | 81.25% |
| 3 | 66.78% | 25.00% | n/a | 62.50% | 18.75% | 100.00% | 62.50% | 52.21% | 33.33% | 9.38% | 57.81% | 45.83% | 100.00% | 96.88% |
| 4 | 64.31% | 31.25% | 37.50% | 50.00% | 7.81% | 93.75% | 33.33% | 49.08% | 41.67% | 6.25% | 59.38% | 45.83% | 79.69% | 75.00% |
| 5 | 84.21% | 100.00% | 81.25% | 92.19% | 50.00% | 100.00% | 87.50% | 64.89% | 52.08% | 50.00% | 70.31% | 80.21% | 96.88% | 90.62% |
| 6 | 26.75% | 0.00% | 0.00% | 6.25% | 0.00% | 50.00% | 5.56% | 6.00% | 31.94% | 0.00% | 3.13% | 0.00% | 14.58% | 11.46% |
| 7 | 55.48% | 29.17% | 37.50% | 66.67% | 12.50% | 94.44% | 50.00% | 35.78% | 42.36% | 13.54% | 69.27% | 50.00% | 63.54% | 43.75% |
| 8 | 66.45% | 35.66% | 47.79% | 50.92% | 35.11% | 94.00% | 64.22% | 50.00% | 46.45% | 32.54% | 61.58% | 48.90% | 65.26% | 62.87% |
| 9 | 60.53% | 66.67% | 66.67% | 58.33% | 47.92% | 68.06% | 57.64% | 53.55% | 50.00% | 55.21% | 60.94% | 55.56% | 58.33% | 56.25% |
| 10 | 75.33% | 84.38% | 90.62% | 93.75% | 50.00% | 100.00% | 86.46% | 67.46% | 44.79% | 50.00% | 75.78% | 72.92% | 84.38% | 81.25% |
| 11 | 55.51% | 45.31% | 42.19% | 40.63% | 29.69% | 96.88% | 30.73% | 38.42% | 39.06% | 24.22% | 50.00% | 25.52% | 63.28% | 50.78% |
| 12 | 65.13% | 60.42% | 54.17% | 54.17% | 19.79% | 100.00% | 50.00% | 51.10% | 44.44% | 27.08% | 74.48% | 50.00% | 72.92% | 63.54% |
| 13 | 41.28% | 15.62% | 0.00% | 20.31% | 3.12% | 85.42% | 36.46% | 34.74% | 41.67% | 15.62% | 36.72% | 27.08% | 50.00% | 35.94% |
| 14 | 56.25% | 18.75% | 3.12% | 25.00% | 9.38% | 88.54% | 56.25% | 37.13% | 43.75% | 18.75% | 49.22% | 36.46% | 64.06% | 50.00% |

### Round 16

Strongest sampled line: `line_hedgerow_tempo`. Hard-floor check: pass.

| Line | Selected boards | Population weight | Field point rate |
|---|---|---|---|
| hard | 17 | 26.81% | 45.83% |
| line_birds_engine | 1 | 1.70% | 28.91% |
| line_birds_tempo | 1 | 2.01% | 70.61% |
| line_bog_engine | 1 | 2.49% | 14.73% |
| line_bog_tempo | 2 | 2.86% | 52.24% |
| line_fairies_engine | 3 | 4.50% | 44.76% |
| line_fairies_tempo | 3 | 4.07% | 21.06% |
| line_fast | 19 | 29.54% | 58.51% |
| line_hedgerow_engine | 3 | 5.29% | 66.11% |
| line_hedgerow_tempo | 3 | 4.13% | 86.77% |
| line_hunters_engine | 4 | 6.02% | 46.84% |
| line_hunters_tempo | 3 | 4.56% | 35.66% |
| line_oozes_engine | 2 | 3.04% | 43.92% |
| line_oozes_tempo | 2 | 2.98% | 30.87% |

Matrix key: 1=`hard`; 2=`line_birds_engine`; 3=`line_birds_tempo`; 4=`line_bog_engine`; 5=`line_bog_tempo`; 6=`line_fairies_engine`; 7=`line_fairies_tempo`; 8=`line_fast`; 9=`line_hedgerow_engine`; 10=`line_hedgerow_tempo`; 11=`line_hunters_engine`; 12=`line_hunters_tempo`; 13=`line_oozes_engine`; 14=`line_oozes_tempo`.

| Row vs column | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 50.00% | 64.34% | 19.85% | 85.66% | 37.50% | 54.17% | 77.33% | 37.17% | 28.92% | 6.37% | 47.70% | 66.30% | 53.68% | 63.97% |
| 2 | 35.66% | n/a | 12.50% | 93.75% | 18.75% | 33.33% | 70.83% | 16.78% | 0.00% | 0.00% | 31.25% | 31.25% | 25.00% | 78.12% |
| 3 | 80.15% | 87.50% | n/a | 100.00% | 68.75% | 56.25% | 97.92% | 58.88% | 68.75% | 56.25% | 60.94% | 83.33% | 68.75% | 78.12% |
| 4 | 14.34% | 6.25% | 0.00% | n/a | 0.00% | 16.67% | 41.67% | 16.45% | 0.00% | 0.00% | 0.00% | 0.00% | 50.00% | 53.12% |
| 5 | 62.50% | 81.25% | 31.25% | 100.00% | 50.00% | 56.25% | 86.46% | 39.14% | 36.46% | 3.12% | 43.75% | 58.33% | 65.62% | 85.94% |
| 6 | 45.83% | 66.67% | 43.75% | 83.33% | 43.75% | 50.00% | 73.61% | 36.95% | 26.39% | 9.72% | 53.12% | 68.06% | 59.37% | 38.54% |
| 7 | 22.67% | 29.17% | 2.08% | 58.33% | 13.54% | 26.39% | 50.00% | 16.67% | 2.08% | 0.00% | 16.15% | 27.78% | 33.33% | 50.00% |
| 8 | 62.83% | 83.22% | 41.12% | 83.55% | 60.86% | 63.05% | 83.33% | 50.00% | 44.08% | 19.63% | 66.45% | 73.03% | 58.06% | 75.00% |
| 9 | 71.08% | 100.00% | 31.25% | 100.00% | 63.54% | 73.61% | 97.92% | 55.92% | 50.00% | 22.92% | 66.15% | 84.03% | 69.79% | 93.75% |
| 10 | 93.63% | 100.00% | 43.75% | 100.00% | 96.87% | 90.28% | 100.00% | 80.37% | 77.08% | 50.00% | 92.19% | 94.44% | 81.25% | 100.00% |
| 11 | 52.30% | 68.75% | 39.06% | 100.00% | 56.25% | 46.87% | 83.85% | 33.55% | 33.85% | 7.81% | 50.00% | 58.85% | 51.56% | 67.19% |
| 12 | 33.70% | 68.75% | 16.67% | 100.00% | 41.67% | 31.94% | 72.22% | 26.97% | 15.97% | 5.56% | 41.15% | 50.00% | 56.25% | 59.38% |
| 13 | 46.32% | 75.00% | 31.25% | 50.00% | 34.38% | 40.62% | 66.67% | 41.94% | 30.21% | 18.75% | 48.44% | 43.75% | 50.00% | 57.81% |
| 14 | 36.03% | 21.88% | 21.87% | 46.88% | 14.06% | 61.46% | 50.00% | 25.00% | 6.25% | 0.00% | 32.81% | 40.62% | 42.19% | 50.00% |

## Replay and known answers

Offline original-rules replay reproduced all 500 winners and final rounds, with 59,117 exact live Health/Armor checks and no elimination divergence or lost coverage. Alternative damage tables and starting Health use the same logged survivors; after elimination divergence they are fixed-schedule conditional replays, not new lobbies.

The independent planted-engine check won 8/8 lobbies, put all eight R6 boards above twice their lobby median, and scored 97.0% in its weighted field. Null/control outputs matched byte for byte; all 469 planted fights replayed exactly. Thus the harness detects an engine when present. Historical tribal-line losses to Hard are retained in [HARNESS.md](../../../tools/sim/HARNESS.md); no further tuning used these baseline seeds. Head-to-head strength must be rechecked on the later lever build.

Earlier equal-budget exploratory knob tuning used 130 separate lobbies (20 per tribe, ten for the shared line), reporting +1.077 places in training and -0.154 places held out. Two games per validation arm did not establish improvement. This baseline uses the later frozen committed profile table and makes no new tuning-gain claim; per-tribe gains and exact profiles remain in HARNESS.md and its linked evidence.

## Precision, artifacts and reproduction

Samples and budgets were frozen before execution. Shop comparisons are unpaired: a common seed reproduces a whole lobby, not matched shop draws after different actions. Five hundred independent lobbies imply an approximate worst-case ±4.4 percentage-point 95% outcome-rate margin before the cluster bootstrap. Field pairs share boards; pair counts are not independent population samples, and 16 trials give coarse pair probabilities. Matched orientations share a replicate seed; Wilson intervals are descriptive, not calibrated confidence coverage for correlated trials. No significance or human-play optimality claim follows from a line ranking.

All per-line/per-round distributions and every scalar metric: [harness-baseline/metrics.json](harness-baseline/metrics.json) and [flat CSV](harness-baseline/metrics.csv). Within-line summaries separate strategy mix from tails. Every sampled board's weight and field rate: [boards.csv](harness-baseline/boards.csv). All line matrices: [matrices.csv](harness-baseline/matrices.csv). Complete counts, pair probabilities and Wilson intervals: [field report](harness-baseline/field-report.json.gz). Exact selected board inputs: [field.json.gz](harness-baseline/field.json.gz). Raw field counts: [pairs.jsonl.gz](harness-baseline/pairs.jsonl.gz).

The [frozen plan](../../../tools/sim/evidence/baseline-plan.json) records profile/content hashes and the source commit. The [execution ledger](../../../tools/sim/evidence/baseline-progress.json) records shard seeds, timings, source hashes and validation. Raw lobby captures remain in `build/sim/harness-baseline/part*.fights.jsonl` (ignored build output); reproduce them with the frozen commit/profile table and ledger seed ranges.

```sh
python3 tools/sim/field.py sample build/sim/harness-baseline/part*.fights.jsonl \
  --size 64 --rounds 6,8,10,12,14,16 --seed 91407 --out field.json
# Run field_fights.gd sequentially per round under the documented 3 GB scope/timeout.
python3 tools/sim/field.py report field.json pairs.jsonl --out field-report.json
python3 tools/sim/metrics.py build/sim/harness-baseline/part*.fights.jsonl \
  --players build/sim/harness-baseline/part*.players.csv --field field-report.json --out metrics.json
```

Validation: the full repository gate passed on the frozen gameplay tree (1,628 Godot tests, 24,810 assertions). Gameplay, capture, line, field, metric and replay code remain unchanged from that checked revision. The new report code passes Ruff; all 19 Python harness tests pass. All six field jobs exited successfully and their counts were checked. The strict historical zero-2x diagnostic fails as reported above; it is not silently treated as a passing known answer.
