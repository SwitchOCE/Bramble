# Bench: latest run

Written by `tools/sim/bench.sh`; reproduce with the same command and seed. Bars come from `docs/ideation/PLAN.md`; TOO CLOSE means the bar sits inside the measurement's 95% margin. A strategy's result measures the bot as well as the game. Bot-or-game reading: `bench-reading.md`.

## Skill ladder: one bot among seven

**PASS** Hard among Naive: top 4 100.0% (bar 85.0%), wins 100.0% (bar 45.0%).

**FAIL** Hard among Normal: average place 3.73 (bar 3.5).

**TOO CLOSE** Hard among the varied Normal lobby a player meets: average place 3.49 (bar 3.5).

**PASS** Normal among Easy: average place 2.77 (a ladder needs it under 4.5).

| One of | Among seven | Games | Avg place (95%) | Win (95%) | Top 4 (95%) |
|---|---|---:|---:|---:|---:|
| hard | naive | 500 | 1.00 ± 0.00 | 100.0% ± 0.0% | 100.0% ± 0.0% |
| hard | easy | 300 | 1.97 ± 0.21 | 69.7% ± 5.2% | 88.3% ± 3.6% |
| hard | normal, picking freely | 500 | 3.73 ± 0.21 | 25.6% ± 3.8% | 62.8% ± 4.2% |
| hard | normal, the varied lobby a player meets | 500 | 3.49 ± 0.20 | 27.8% ± 3.9% | 67.4% ± 4.1% |
| hard | hard, the varied lobby a player meets | 500 | 3.83 ± 0.20 | 22.0% ± 3.6% | 61.8% ± 4.3% |
| normal | easy | 500 | 2.77 ± 0.19 | 40.2% ± 4.3% | 78.0% ± 3.6% |
| easy | naive | 300 | 1.00 ± 0.00 | 100.0% ± 0.0% | 100.0% ± 0.0% |

## Builds per seat, unpinned and varied bots

The build a seat followed when the game ended. Lobby seats are dealt theirs; unpinned bots choose.

| Suite | Seat | Build | Seats | Share | Win | Avg place |
|---|---|---|---:|---:|---:|---:|
| hard_normal | the one bot | fairies_hag | 487 | 97.4% | 25.9% | 3.72 |
| hard_normal | the one bot | hedgerow_treasury | 9 | 1.8% | 11.1% | 3.78 |
| hard_normal | the one bot | hedgerow_parish | 4 | 0.8% | 25.0% | 4.75 |
| hard_normal | the seven | hedgerow_parish | 1067 | 30.5% | 14.2% | 4.38 |
| hard_normal | the seven | hedgerow_treasury | 877 | 25.1% | 3.6% | 5.40 |
| hard_normal | the seven | fairies_rings | 790 | 22.6% | 9.9% | 4.21 |
| hard_normal | the seven | fairies_hag | 615 | 17.6% | 17.9% | 3.91 |
| hard_normal | the seven | fairies_rainbow | 143 | 4.1% | 0.7% | 6.62 |
| hard_normal | the seven | fairies_help | 8 | 0.2% | 0.0% | 5.50 |
| hard_lobby_normal | the one bot | fairies_hag | 486 | 97.2% | 28.0% | 3.47 |
| hard_lobby_normal | the one bot | hedgerow_parish | 8 | 1.6% | 25.0% | 3.75 |
| hard_lobby_normal | the one bot | hedgerow_treasury | 6 | 1.2% | 16.7% | 5.00 |
| hard_lobby_normal | the seven | fairies_hag | 446 | 12.7% | 16.6% | 4.07 |
| hard_lobby_normal | the seven | fairies_rainbow | 441 | 12.6% | 2.0% | 6.02 |
| hard_lobby_normal | the seven | hedgerow_parish | 441 | 12.6% | 13.4% | 4.26 |
| hard_lobby_normal | the seven | neutrals_economy | 437 | 12.5% | 3.2% | 5.77 |
| hard_lobby_normal | the seven | neutrals_low_roll | 437 | 12.5% | 23.8% | 3.51 |
| hard_lobby_normal | the seven | fairies_rings | 437 | 12.5% | 10.1% | 4.02 |
| hard_lobby_normal | the seven | fairies_help | 434 | 12.4% | 8.8% | 4.43 |
| hard_lobby_normal | the seven | hedgerow_treasury | 427 | 12.2% | 4.4% | 5.10 |
| hard_lobby_hard | the one bot | fairies_hag | 482 | 96.4% | 22.6% | 3.82 |
| hard_lobby_hard | the one bot | hedgerow_treasury | 9 | 1.8% | 0.0% | 4.78 |
| hard_lobby_hard | the one bot | hedgerow_parish | 9 | 1.8% | 11.1% | 3.44 |
| hard_lobby_hard | the seven | fairies_hag | 446 | 12.7% | 22.4% | 3.73 |
| hard_lobby_hard | the seven | fairies_rainbow | 441 | 12.6% | 1.6% | 6.01 |
| hard_lobby_hard | the seven | hedgerow_parish | 441 | 12.6% | 13.6% | 4.05 |
| hard_lobby_hard | the seven | neutrals_economy | 437 | 12.5% | 3.4% | 5.86 |
| hard_lobby_hard | the seven | neutrals_low_roll | 437 | 12.5% | 23.6% | 3.51 |
| hard_lobby_hard | the seven | fairies_rings | 437 | 12.5% | 11.7% | 3.81 |
| hard_lobby_hard | the seven | fairies_help | 434 | 12.4% | 7.6% | 4.62 |
| hard_lobby_hard | the seven | hedgerow_treasury | 427 | 12.2% | 4.9% | 5.20 |
| place_search | the one bot | fairies_hag | 477 | 95.4% | 10.9% | 4.48 |
| place_search | the one bot | hedgerow_treasury | 17 | 3.4% | 5.9% | 5.06 |
| place_search | the one bot | hedgerow_parish | 5 | 1.0% | 0.0% | 4.20 |
| place_search | the one bot | fairies_rainbow | 1 | 0.2% | 0.0% | 7.00 |
| place_search | the seven | fairies_hag | 3341 | 95.5% | 13.2% | 4.49 |
| place_search | the seven | hedgerow_treasury | 124 | 3.5% | 3.2% | 4.67 |
| place_search | the seven | hedgerow_parish | 29 | 0.8% | 6.9% | 4.52 |
| place_search | the seven | fairies_rainbow | 6 | 0.2% | 0.0% | 7.17 |

## Win spread: pinned Hard bots in mixed lobbies

**TOO CLOSE** Bar: at least 5 strategies at 6-25% wins, none above 25%, 2000+ games. Measured: 4 inside, 1 above, 2000 games.

| Strategy | Seats | Win (95%) | Top 4 (95%) | Avg place | Tier 6 turn | Final units | In bar |
|---|---:|---:|---:|---:|---:|---:|---|
| fairies_hag | 2000 | 23.5% ± 1.9% | 66.1% ± 2.1% | 3.60 | 14.5 | 6.8 | yes |
| fairies_help | 2000 | 9.7% ± 1.3% | 52.2% ± 2.2% | 4.40 | 14.4 | 6.7 | yes |
| fairies_rainbow | 2000 | 2.6% ± 0.7% | 23.4% ± 1.9% | 5.90 | 12.6 | 6.8 | NO |
| fairies_rings | 2000 | 13.6% ± 1.5% | 64.0% ± 2.1% | 3.90 | 14.5 | 5.7 | yes |
| hedgerow_parish | 2000 | 17.8% ± 1.7% | 60.0% ± 2.1% | 3.92 | 14.2 | 6.9 | yes |
| hedgerow_treasury | 2000 | 3.5% ± 0.8% | 40.6% ± 2.2% | 5.11 | 12.5 | 6.8 | NO |
| neutrals_economy | 2000 | 3.0% ± 0.8% | 26.9% ± 1.9% | 5.70 | 11.6 | 6.9 | NO |
| neutrals_low_roll | 2000 | 26.4% ± 1.9% | 66.8% ± 2.1% | 3.48 | 17.1 | 6.8 | NO |

## Are the strategies different boards?

Overlap is the weighted Jaccard of two strategies' final boards: each card counts by the share of boards it's on, 0 means no card in common, 1 the same boards. A strategy is marked distinct if its overlap with every other is under 0.6, a limit chosen by hand.

| Strategy | Closest | Overlap | Distinct? |
|---|---|---:|---|
| fairies_hag | fairies_rings | 0.61 | NO |
| fairies_help | fairies_rainbow | 0.63 | NO |
| fairies_rainbow | fairies_help | 0.63 | NO |
| fairies_rings | fairies_hag | 0.61 | NO |
| hedgerow_parish | hedgerow_treasury | 0.60 | yes |
| hedgerow_treasury | hedgerow_parish | 0.60 | yes |
| neutrals_economy | neutrals_low_roll | 0.39 | yes |
| neutrals_low_roll | fairies_rainbow | 0.61 | NO |

Top 10 cards by final boards, of 16000 seats. Staple of: strategies with the card on at least 50.0% of their final boards, of 8.

| Card | Boards | Share | Staple of | Lowest strategy | Highest strategy |
|---|---:|---:|---:|---:|---:|
| alderman_dozey | 13245 | 82.8% | 8 | 70.4% | 96.2% |
| will_o_the_wisp | 8924 | 55.8% | 6 | 0.4% | 86.1% |
| old_moth_annis | 6277 | 39.2% | 2 | 6.5% | 88.8% |
| belladonna | 5785 | 36.2% | 3 | 0.7% | 67.5% |
| hedge_witch | 5672 | 35.4% | 1 | 2.2% | 95.5% |
| mrs_sorrel | 4739 | 29.6% | 1 | 3.7% | 85.6% |
| sleeping_partner | 4240 | 26.5% | 2 | 2.6% | 85.6% |
| pill_bug | 4162 | 26.0% | 1 | 2.1% | 52.2% |
| honorary_treasurer | 3825 | 23.9% | 2 | 0.2% | 91.8% |
| sally_spore | 3795 | 23.7% | 1 | 1.6% | 74.0% |

## Does the bench catch a bad bot?

**PASS** A strategy that never climbs and fields 3 units won 0.0%, average place 7.86 (best other: 3.04, worst other: 5.22); the spread table would mark it NO.

## Does placing matter with everyone scouting?

**PASS** One Hard bot among 7 Hard bots (all searching on the scouted board): searching beats shuffled by 0.91 of a place (95% CI ±0.19, 500 seeds; bar 0.5).

With 200 fights a turn, which no phone can afford, search beats Hard's budget by 0.03 (±0.34, 100 seeds): what a bigger budget or faster fights could buy.

Searching beats the placing rule by 0.05 (±0.16, 500 seeds). The position test measured +0.40 for a lone scout; this one has everyone scouting.

No scouting, one seat among 7 who scout: seeing the board is worth 0.14 of a place to the seat that has it (±0.21, 500 seeds).

No scouting for anyone: placing by rule beats shuffled by 0.84 (±0.20, 500 seeds), against 0.91 (±0.19) with everyone scouting. The difference is what the rule adds to placing.

Game length, everyone scouts: 14.5 rounds.

Game length, nobody scouts: 15.2 rounds.

| Arm | Avg place (95%) | Win | Top 4 |
|---|---:|---:|---:|
| search 200 | 4.16 ± 0.41 | 13.0% | 56.0% |
| search | 4.50 ± 0.20 | 10.6% | 49.0% |
| rule | 4.55 ± 0.20 | 11.4% | 49.6% |
| shuffled | 5.41 ± 0.17 | 3.0% | 31.8% |

## Pace and economy

Tier 6: 3037 of 16000 seats reach it, on average turn 13.6, earliest 10 (target: turn 8 at the earliest for economy); 16.3 units bought by then.

Game length: 14.9 rounds on average, longest 23.

Acorns per fight, across all seats: 0.110.

| Turn | Seats alive | Tier | Units | Avg unit (target 13/13 by turn 12) | Bank at start | Spent | Paid refreshes | Larder held |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 16000 | 1.0 | 1.1 | 1.6/2.4 | 3.0 | 3.0 | 0.0 | 0.0 |
| 2 | 16000 | 1.0 | 2.1 | 1.9/2.8 | 4.0 | 4.0 | 0.0 | 0.0 |
| 3 | 16000 | 1.3 | 3.4 | 2.1/3.1 | 5.7 | 5.7 | 0.0 | 0.2 |
| 4 | 16000 | 2.0 | 4.7 | 2.2/3.3 | 6.7 | 6.8 | 0.0 | 0.3 |
| 5 | 16000 | 2.2 | 6.0 | 2.4/3.7 | 7.6 | 7.4 | 0.1 | 0.6 |
| 6 | 16000 | 2.5 | 6.5 | 3.0/4.6 | 9.0 | 9.3 | 0.5 | 0.9 |
| 7 | 15894 | 2.9 | 6.7 | 3.9/5.9 | 10.7 | 11.5 | 1.1 | 0.9 |
| 8 | 15012 | 3.3 | 6.7 | 5.3/7.7 | 12.1 | 13.5 | 1.9 | 1.0 |
| 9 | 13180 | 3.7 | 6.7 | 6.9/9.8 | 12.3 | 12.4 | 1.9 | 0.9 |
| 10 | 11176 | 4.1 | 6.7 | 8.9/12.5 | 12.2 | 12.5 | 2.2 | 0.7 |
| 11 | 9152 | 4.3 | 6.6 | 11.2/15.3 | 11.9 | 11.8 | 2.4 | 0.6 |
| 12 | 7300 | 4.6 | 6.6 | 13.4/18.0 | 11.9 | 11.5 | 2.2 | 0.5 |
| 13 | 5670 | 5.0 | 6.6 | 15.6/20.5 | 11.8 | 11.4 | 2.0 | 0.4 |
| 14 | 4122 | 5.3 | 6.6 | 17.7/23.0 | 11.6 | 11.3 | 2.3 | 0.4 |
| 15 | 2620 | 5.7 | 6.5 | 19.7/25.1 | 11.5 | 11.0 | 1.7 | 0.4 |
| 16 | 1359 | 5.8 | 6.6 | 21.5/27.1 | 11.4 | 11.2 | 2.5 | 0.4 |
| 17 | 550 | 5.8 | 6.5 | 23.7/29.4 | 11.3 | 10.9 | 2.7 | 0.5 |
| 18 | 222 | 6.0 | 6.5 | 25.9/31.8 | 11.4 | 11.4 | 2.7 | 0.6 |
| 19 | 69 | 6.0 | 6.6 | 26.6/32.9 | 11.1 | 11.0 | 2.8 | 0.6 |
| 20 | 18 | 6.0 | 6.4 | 27.9/34.6 | 11.2 | 10.8 | 2.9 | 0.1 |
| 21 | 8 | 6.0 | 6.5 | 30.3/35.7 | 10.9 | 9.4 | 1.9 | 0.1 |
| 22 | 4 | 6.0 | 6.8 | 30.3/34.1 | 12.2 | 13.2 | 4.0 | 0.2 |
| 23 | 2 | 6.0 | 6.5 | 35.2/40.6 | 10.5 | 8.0 | 2.5 | 0.0 |

Shops seen in a long turn (owner's aim: about 20-30 at a big bank). By rule is every coin on refreshes; observed is what Hard bots did with about that much.

| Bank | Shops by rule | Observed turns | Shops observed |
|---:|---:|---:|---:|
| 12 | 13 | 80309 | 2.8 |
| 30 | 22 | 12 | 5.9 |
| 60 | 31 | 0 | none |

## Cards and heroes in the mixed lobbies

Share of final boards with the card, and the win rate of those boards. Later cards sit on survivors' boards, so read each against its tier's average. Overall win rate per seat: 12.5%.

| Card | Tier | On final boards | Win when on it (95%) | Tier average | Lift |
|---|---:|---:|---:|---:|---:|
| hedge_witch | 1 | 35.4% | 18.6% ± 1.0% | 10.3% | +8.4 |
| queen_of_elfland | 6 | 10.1% | 33.1% ± 2.3% | 26.8% | +6.3 |
| belladonna | 5 | 36.2% | 23.6% ± 1.1% | 19.4% | +4.3 |
| mrs_sorrel | 2 | 29.6% | 13.3% ± 1.0% | 9.7% | +3.6 |
| alderman_dozey | 3 | 82.8% | 13.9% ± 0.6% | 12.0% | +1.9 |
| old_moth_annis | 2 | 39.2% | 11.4% ± 0.8% | 9.7% | +1.7 |
| will_o_the_wisp | 4 | 55.8% | 14.1% ± 0.7% | 12.7% | +1.5 |
| mrs_burdock | 1 | 9.6% | 10.3% ± 1.5% | 10.3% | +0.1 |
| sally_spore | 2 | 23.7% | 9.5% ± 0.9% | 9.7% | -0.2 |
| nan_toadstool | 1 | 17.9% | 9.9% ± 1.1% | 10.3% | -0.4 |
| sleeping_partner | 1 | 26.5% | 9.3% ± 0.9% | 10.3% | -0.9 |
| standing_committee | 5 | 17.6% | 18.1% ± 1.4% | 19.4% | -1.3 |
| mr_crumb | 1 | 17.5% | 8.9% ± 1.1% | 10.3% | -1.4 |
| cricket_busker | 2 | 9.9% | 7.3% ± 1.3% | 9.7% | -2.4 |
| lamp_moth | 1 | 1.3% | 7.8% ± 3.7% | 10.3% | -2.5 |
| honorary_treasurer | 4 | 23.9% | 9.2% ± 0.9% | 12.7% | -3.4 |
| old_mother_mast | 6 | 15.0% | 22.5% ± 1.7% | 26.8% | -4.2 |
| pill_bug | 1 | 26.0% | 5.7% ± 0.7% | 10.3% | -4.6 |
| hob_in_the_hearth | 2 | 19.7% | 4.9% ± 0.8% | 9.7% | -4.7 |
| turnip_scarecrow | 2 | 6.1% | 3.0% ± 1.1% | 9.7% | -6.7 |
| earwig_mother | 2 | 1.8% | 2.4% ± 1.7% | 9.7% | -7.3 |
| kit | 1 | 0.6% | 2.2% ± 3.0% | 10.3% | -8.1 |
| ballooning_spider | 3 | 11.8% | 3.2% ± 0.8% | 12.0% | -8.8 |
| rainbow_chaser | 1 | 12.8% | 1.4% ± 0.5% | 10.3% | -8.9 |
| sexton_beetle | 3 | 5.8% | 2.5% ± 1.0% | 12.0% | -9.5 |
| charcoal_burner | 5 | 9.1% | 4.8% ± 1.1% | 19.4% | -14.6 |

| Hero | Picked when offered | Games | Win (95%) | Avg place |
|---|---:|---:|---:|---:|
| little_king_wren | 67.1% | 3576 | 20.0% ± 1.3% | 3.84 |
| pipkin | 19.5% | 1049 | 14.8% ± 2.1% | 4.20 |
| old_mother_mousewife | 76.2% | 4056 | 14.6% ± 1.1% | 4.10 |
| hob_mumblecrust | 16.4% | 878 | 11.6% ± 2.1% | 4.69 |
| brother_bracken | 23.0% | 1222 | 7.9% ± 1.5% | 4.04 |
| dame_hoolet | 47.1% | 2531 | 7.1% ± 1.0% | 5.12 |
| dame_farthing | 32.9% | 1746 | 6.0% ± 1.1% | 5.78 |
| march_hare | 17.7% | 942 | 5.7% ± 1.5% | 5.46 |

## Time per bot turn

Measured here, while other bench shards ran. Phone-speed core assumed 3 times slower (an assumption: no device was tested). The limit is 7 bots in about 1 s.

A whole lobby's turn, all Hard: mean 241 ms, 95th percentile 504 ms, worst 707 ms here; on the assumed phone core mean 0.72 s, 95th percentile 1.51 s.

| Level | Turns | Mean ms | 95th pct ms | Worst ms | 7 bots on a phone, mean |
|---|---:|---:|---:|---:|---:|
| naive | 36210 | 0.9 | 2.2 | 4.0 | 0.02 s |
| easy | 38551 | 1.7 | 4.1 | 10.8 | 0.04 s |
| normal | 46940 | 3.1 | 7.6 | 17.8 | 0.07 s |
| hard | 239663 | 38.7 | 85.5 | 163.1 | 0.81 s |

## What ran on what code

**This report mixes commits.** Compare suites from different commits with care.

| Suite | Games | Commit |
|---|---:|---|
| blind_alone | 500 | 3dd08a6 |
| blind_lobby | 500 | 3dd08a6 |
| blind_shuffled | 500 | 3dd08a6 |
| easy_naive | 300 | 38f2fa1 |
| hard_easy | 300 | 38f2fa1 |
| hard_lobby_hard | 500 | 3dd08a6 |
| hard_lobby_normal | 500 | 3dd08a6 |
| hard_naive | 500 | 38f2fa1 |
| hard_normal | 500 | 3dd08a6 |
| normal_easy | 500 | 38f2fa1 |
| place_big | 100 | 38f2fa1 |
| place_rule | 500 | 38f2fa1 |
| place_search | 500 | 3dd08a6 |
| place_shuffled | 500 | 3dd08a6 |
| plant | 300 | 38f2fa1 |
| spread | 2000 | 38f2fa1 |

