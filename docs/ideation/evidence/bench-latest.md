# Bench: latest run

Written by `tools/sim/bench.sh`; reproduce with the same command and seed. Bars come from `docs/ideation/PLAN.md`; TOO CLOSE means the bar sits inside the measurement's 95% margin. A strategy's result measures the bot as well as the game. Bot-or-game reading: `bench-reading.md`.

## Skill ladder: one bot among seven

**PASS** Hard among Naive: top 4 100.0% (bar 85.0%), wins 100.0% (bar 45.0%).

**TOO CLOSE** Hard among the varied Normal lobby a player meets: average place 3.41 (bar 3.5).

**PASS** Normal among Easy: average place 3.37 (a ladder needs it under 4.5).

| One of | Among seven | Games | Avg place (95%) | Win (95%) | Top 4 (95%) |
|---|---|---:|---:|---:|---:|
| hard | naive | 500 | 1.00 ± 0.00 | 100.0% ± 0.0% | 100.0% ± 0.0% |
| hard | easy | 300 | 2.36 ± 0.22 | 52.3% ± 5.7% | 84.3% ± 4.1% |
| hard | normal, the varied lobby a player meets | 500 | 3.41 ± 0.18 | 23.4% ± 3.7% | 69.8% ± 4.0% |
| normal | easy | 300 | 3.37 ± 0.27 | 35.0% ± 5.4% | 66.0% ± 5.4% |

## Builds per seat, unpinned and varied bots

The build a seat followed when the game ended. Lobby seats are dealt theirs; unpinned bots choose.

| Suite | Seat | Build | Seats | Share | Win | Avg place |
|---|---|---|---:|---:|---:|---:|
| hard_lobby_normal | the one bot | hedgerow_parish | 163 | 32.6% | 23.3% | 3.28 |
| hard_lobby_normal | the one bot | hedgerow_treasury | 127 | 25.4% | 29.9% | 3.73 |
| hard_lobby_normal | the one bot | fairies_rainbow | 108 | 21.6% | 25.0% | 2.83 |
| hard_lobby_normal | the one bot | fairies_hag | 97 | 19.4% | 14.4% | 3.78 |
| hard_lobby_normal | the one bot | fairies_rings | 5 | 1.0% | 0.0% | 4.20 |
| hard_lobby_normal | the seven | neutrals_low_roll | 400 | 11.4% | 6.5% | 4.22 |
| hard_lobby_normal | the seven | neutrals_purse | 399 | 11.4% | 7.3% | 5.85 |
| hard_lobby_normal | the seven | neutrals_economy | 397 | 11.3% | 23.4% | 4.34 |
| hard_lobby_normal | the seven | hedgerow_parish | 396 | 11.3% | 12.1% | 3.98 |
| hard_lobby_normal | the seven | fairies_rings | 395 | 11.3% | 5.3% | 5.33 |
| hard_lobby_normal | the seven | hedgerow_treasury | 381 | 10.9% | 11.8% | 5.22 |
| hard_lobby_normal | the seven | fairies_hag | 380 | 10.9% | 10.3% | 4.23 |
| hard_lobby_normal | the seven | fairies_help | 380 | 10.9% | 8.9% | 5.03 |
| hard_lobby_normal | the seven | fairies_rainbow | 372 | 10.6% | 12.9% | 3.67 |
| place_search | the one bot | hedgerow_parish | 159 | 31.8% | 18.2% | 4.23 |
| place_search | the one bot | hedgerow_treasury | 129 | 25.8% | 14.7% | 5.17 |
| place_search | the one bot | fairies_hag | 105 | 21.0% | 11.4% | 4.36 |
| place_search | the one bot | fairies_rainbow | 104 | 20.8% | 6.7% | 3.76 |
| place_search | the one bot | fairies_rings | 2 | 0.4% | 0.0% | 6.00 |
| place_search | the one bot | fairies_help | 1 | 0.2% | 0.0% | 7.00 |
| place_search | the seven | hedgerow_parish | 1033 | 29.5% | 14.3% | 4.50 |
| place_search | the seven | hedgerow_treasury | 892 | 25.5% | 13.7% | 5.16 |
| place_search | the seven | fairies_hag | 757 | 21.6% | 10.3% | 4.52 |
| place_search | the seven | fairies_rainbow | 754 | 21.5% | 10.7% | 3.70 |
| place_search | the seven | fairies_rings | 58 | 1.7% | 6.9% | 5.24 |
| place_search | the seven | fairies_help | 6 | 0.2% | 0.0% | 6.00 |

## Win spread: pinned Hard bots in mixed lobbies

**TOO CLOSE** Bar: at least 5 strategies at 6-25% wins, none above 25%, 2000+ games. Measured: 8 inside, 0 above, 2000 games.

| Strategy | Seats | Win (95%) | Top 4 (95%) | Avg place | Tier 6 turn | Final units | In bar |
|---|---:|---:|---:|---:|---:|---:|---|
| fairies_hag | 1765 | 9.8% ± 1.4% | 62.7% ± 2.3% | 3.97 | 12.3 | 6.6 | yes |
| fairies_help | 1775 | 7.4% ± 1.2% | 37.2% ± 2.2% | 5.01 | 12.3 | 6.5 | yes |
| fairies_rainbow | 1774 | 12.0% ± 1.5% | 66.2% ± 2.2% | 3.79 | 12.2 | 6.5 | yes |
| fairies_rings | 1790 | 3.9% ± 0.9% | 35.5% ± 2.2% | 5.07 | 12.4 | 5.6 | NO |
| hedgerow_parish | 1779 | 22.4% ± 1.9% | 66.3% ± 2.2% | 3.61 | 14.0 | 6.9 | yes |
| hedgerow_treasury | 1785 | 16.2% ± 1.7% | 39.4% ± 2.3% | 4.88 | 12.2 | 6.9 | yes |
| neutrals_economy | 1777 | 24.6% ± 2.0% | 52.1% ± 2.3% | 4.29 | 11.2 | 6.6 | yes |
| neutrals_low_roll | 1774 | 9.3% ± 1.4% | 60.4% ± 2.3% | 4.07 | 17.1 | 6.9 | yes |
| neutrals_purse | 1781 | 6.9% ± 1.2% | 30.5% ± 2.1% | 5.80 | 11.6 | 6.9 | yes |

## Are the strategies different boards?

Overlap is the weighted Jaccard of two strategies' final boards: each card counts by the share of boards it's on, 0 means no card in common, 1 the same boards. A strategy is marked distinct if its overlap with every other is under 0.6, a limit chosen by hand.

| Strategy | Closest | Overlap | Distinct? |
|---|---|---:|---|
| fairies_hag | fairies_help | 0.47 | yes |
| fairies_help | fairies_rainbow | 0.51 | yes |
| fairies_rainbow | fairies_help | 0.51 | yes |
| fairies_rings | fairies_hag | 0.43 | yes |
| hedgerow_parish | hedgerow_treasury | 0.40 | yes |
| hedgerow_treasury | hedgerow_parish | 0.40 | yes |
| neutrals_economy | neutrals_purse | 0.56 | yes |
| neutrals_low_roll | fairies_help | 0.43 | yes |
| neutrals_purse | neutrals_economy | 0.56 | yes |

Top 10 cards by final boards, of 16000 seats. Staple of: strategies with the card on at least 50.0% of their final boards, of 9.

| Card | Boards | Share | Staple of | Lowest strategy | Highest strategy |
|---|---:|---:|---:|---:|---:|
| belladonna | 7836 | 49.0% | 4 | 15.8% | 81.1% |
| queen_of_elfland | 6511 | 40.7% | 5 | 0.9% | 82.8% |
| will_o_the_wisp | 6314 | 39.5% | 3 | 3.0% | 79.6% |
| standing_committee | 5517 | 34.5% | 1 | 7.2% | 82.5% |
| alderman_dozey | 4512 | 28.2% | 1 | 4.4% | 82.6% |
| honorary_treasurer | 4100 | 25.6% | 1 | 1.4% | 91.7% |
| rainbow_chaser | 3805 | 23.8% | 1 | 0.2% | 92.7% |
| sleeping_partner | 3665 | 22.9% | 2 | 2.9% | 79.7% |
| whirligig_beetle | 3647 | 22.8% | 2 | 1.1% | 66.4% |
| charcoal_burner | 3247 | 20.3% | 2 | 1.5% | 84.2% |

## Does the bench catch a bad bot?

NOT RUN

## Does placing matter with everyone scouting?

**TOO CLOSE** One Hard bot among 7 Hard bots (all searching on the scouted board): searching beats shuffled by 0.57 of a place (95% CI ±0.22, 500 seeds; bar 0.5).

Game length, everyone scouts: 17.9 rounds.

| Arm | Avg place (95%) | Win | Top 4 |
|---|---:|---:|---:|
| search | 4.41 ± 0.20 | 13.4% | 51.6% |
| shuffled | 4.99 ± 0.20 | 7.6% | 40.2% |

## Pace and economy

Tier 6: 10261 of 16000 seats reach it, on average turn 12.5, earliest 9 (target: turn 8 at the earliest for economy); 16.2 units bought by then.

Game length: 17.9 rounds on average, longest 25.

Acorns per fight, across all seats: 0.130.

| Turn | Seats alive | Tier | Units | Avg unit (target 13/13 by turn 12) | Bank at start | Spent | Paid refreshes | Larder held |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 16000 | 1.0 | 1.1 | 1.7/2.5 | 3.0 | 3.0 | 0.0 | 0.0 |
| 2 | 16000 | 1.1 | 2.1 | 2.0/2.8 | 4.0 | 4.0 | 0.0 | 0.0 |
| 3 | 16000 | 1.4 | 3.1 | 2.2/3.1 | 5.7 | 4.7 | 0.0 | 0.3 |
| 4 | 16000 | 2.0 | 4.6 | 2.3/3.3 | 7.5 | 7.1 | 0.0 | 0.4 |
| 5 | 16000 | 2.3 | 5.9 | 2.6/3.7 | 8.2 | 7.8 | 0.1 | 0.7 |
| 6 | 16000 | 2.8 | 6.5 | 3.0/4.3 | 9.5 | 9.0 | 0.3 | 1.2 |
| 7 | 16000 | 3.3 | 6.7 | 3.7/5.3 | 11.3 | 11.4 | 0.9 | 1.6 |
| 8 | 16000 | 3.9 | 6.8 | 4.7/6.5 | 13.1 | 13.9 | 1.2 | 1.7 |
| 9 | 16000 | 4.1 | 6.8 | 5.9/8.1 | 12.8 | 13.5 | 1.8 | 1.9 |
| 10 | 15555 | 4.6 | 6.8 | 7.1/9.7 | 12.8 | 14.0 | 1.7 | 1.7 |
| 11 | 14521 | 4.9 | 6.8 | 8.5/11.3 | 11.8 | 12.6 | 1.7 | 1.7 |
| 12 | 13046 | 5.3 | 6.7 | 9.8/12.9 | 11.6 | 12.2 | 1.4 | 1.7 |
| 13 | 11316 | 5.7 | 6.6 | 11.3/14.8 | 11.4 | 12.0 | 1.5 | 1.8 |
| 14 | 9259 | 5.8 | 6.7 | 13.0/16.7 | 11.2 | 11.9 | 1.8 | 2.2 |
| 15 | 7305 | 5.9 | 6.7 | 15.0/19.2 | 11.1 | 11.9 | 1.9 | 2.8 |
| 16 | 5552 | 5.9 | 6.6 | 17.3/21.9 | 11.1 | 12.1 | 2.2 | 3.8 |
| 17 | 3965 | 5.9 | 6.7 | 19.7/24.6 | 11.1 | 12.2 | 2.2 | 4.5 |
| 18 | 2485 | 6.0 | 6.7 | 22.0/27.2 | 11.1 | 12.5 | 2.2 | 5.4 |
| 19 | 1308 | 6.0 | 6.6 | 24.6/30.1 | 11.0 | 12.4 | 2.3 | 6.0 |
| 20 | 661 | 6.0 | 6.6 | 26.8/32.4 | 11.0 | 12.1 | 2.3 | 6.7 |
| 21 | 285 | 6.0 | 6.5 | 29.6/35.5 | 10.8 | 12.7 | 2.5 | 7.2 |
| 22 | 126 | 6.0 | 6.6 | 31.4/37.4 | 10.8 | 13.5 | 2.7 | 6.1 |
| 23 | 44 | 6.0 | 6.6 | 34.1/40.5 | 10.7 | 14.1 | 2.8 | 6.2 |
| 24 | 8 | 6.0 | 6.6 | 30.5/37.8 | 10.8 | 12.5 | 2.2 | 0.8 |
| 25 | 2 | 6.0 | 6.5 | 40.4/46.2 | 11.5 | 15.0 | 2.5 | 0.0 |

Shops seen in a long turn (owner's aim: about 20-30 at a big bank). By rule is every coin on refreshes; observed is what Hard bots did with about that much.

| Bank | Shops by rule | Observed turns | Shops observed |
|---:|---:|---:|---:|
| 12 | 13 | 123371 | 2.4 |
| 30 | 22 | 59 | 3.6 |
| 60 | 31 | 0 | none |

## Cards and heroes in the mixed lobbies

Share of final boards with the card, and the win rate of those boards. Later cards sit on survivors' boards, so read each against its tier's average. Overall win rate per seat: 12.5%.

| Card | Tier | On final boards | Win when on it (95%) | Tier average | Lift |
|---|---:|---:|---:|---:|---:|
| sexton_beetle | 3 | 4.8% | 25.0% ± 3.1% | 11.4% | +13.6 |
| cricket_busker | 2 | 3.4% | 19.6% ± 3.4% | 6.8% | +12.8 |
| sleeping_partner | 1 | 22.9% | 15.8% ± 1.2% | 8.6% | +7.2 |
| old_mother_mast | 6 | 17.1% | 26.4% ± 1.7% | 19.4% | +7.0 |
| beadle_warrenby | 4 | 13.8% | 16.2% ± 1.5% | 9.4% | +6.8 |
| standing_committee | 5 | 34.5% | 19.0% ± 1.0% | 13.3% | +5.7 |
| alderman_dozey | 3 | 28.2% | 16.1% ± 1.1% | 11.4% | +4.8 |
| mrs_sorrel | 2 | 14.3% | 11.0% ± 1.3% | 6.8% | +4.2 |
| honorary_treasurer | 4 | 25.6% | 12.9% ± 1.0% | 9.4% | +3.5 |
| whirligig_beetle | 6 | 22.8% | 22.0% ± 1.3% | 19.4% | +2.7 |
| charcoal_burner | 5 | 20.3% | 16.0% ± 1.3% | 13.3% | +2.7 |
| rainbow_chaser | 1 | 23.8% | 9.1% ± 0.9% | 8.6% | +0.4 |
| mr_crumb | 1 | 6.6% | 8.9% ± 1.7% | 8.6% | +0.2 |
| dr_urchin | 3 | 14.8% | 11.6% ± 1.3% | 11.4% | +0.2 |
| earwig_mother | 2 | 0.4% | 6.2% ± 5.8% | 6.8% | -0.7 |
| old_moth_annis | 2 | 19.3% | 6.0% ± 0.8% | 6.8% | -0.8 |
| mrs_burdock | 1 | 4.7% | 7.7% ± 1.9% | 8.6% | -0.9 |
| ichneumon_wasp | 4 | 7.0% | 8.1% ± 1.6% | 9.4% | -1.3 |
| kit | 1 | 0.1% | 7.1% ± 13.5% | 8.6% | -1.5 |
| belladonna | 5 | 49.0% | 11.1% ± 0.7% | 13.3% | -2.2 |
| hedge_witch | 1 | 16.5% | 6.3% ± 0.9% | 8.6% | -2.3 |
| changeling | 4 | 12.5% | 7.0% ± 1.1% | 9.4% | -2.4 |
| turnip_scarecrow | 2 | 1.4% | 3.6% ± 2.5% | 6.8% | -3.2 |
| cluricaun | 3 | 14.1% | 8.0% ± 1.1% | 11.4% | -3.3 |
| sally_spore | 2 | 9.7% | 3.2% ± 0.9% | 6.8% | -3.7 |
| will_o_the_wisp | 4 | 39.5% | 5.7% ± 0.6% | 9.4% | -3.7 |
| pill_bug | 1 | 16.0% | 4.9% ± 0.8% | 8.6% | -3.7 |
| money_spider | 2 | 6.2% | 2.8% ± 1.0% | 6.8% | -4.0 |
| queen_of_elfland | 6 | 40.7% | 14.9% ± 0.9% | 19.4% | -4.5 |
| lamp_moth | 1 | 1.4% | 3.5% ± 2.4% | 8.6% | -5.1 |
| sergeant_at_conkers | 3 | 9.6% | 5.9% ± 1.2% | 11.4% | -5.4 |
| ballooning_spider | 3 | 15.1% | 5.9% ± 0.9% | 11.4% | -5.4 |
| hob_in_the_hearth | 2 | 3.4% | 0.2% ± 0.4% | 6.8% | -6.6 |
| nan_toadstool | 1 | 8.6% | 1.8% ± 0.7% | 8.6% | -6.9 |
| reel_mistress | 5 | 17.2% | 5.9% ± 0.9% | 13.3% | -7.4 |
| pennywort_snail | 1 | 0.9% | 0.7% ± 1.4% | 8.6% | -7.9 |
| cradle_fetch | 3 | 2.3% | 2.4% ± 1.5% | 11.4% | -9.0 |
| pipistrelle_echo | 5 | 1.3% | 3.3% ± 2.4% | 13.3% | -10.0 |

| Hero | Picked when offered | Games | Win (95%) | Avg place |
|---|---:|---:|---:|---:|
| march_hare | 10.3% | 547 | 21.6% ± 3.4% | 3.88 |
| old_mother_mousewife | 67.1% | 3568 | 18.2% ± 1.3% | 3.91 |
| pipkin | 12.3% | 659 | 16.8% ± 2.9% | 4.22 |
| little_king_wren | 58.7% | 3128 | 13.9% ± 1.2% | 4.14 |
| dame_farthing | 53.4% | 2836 | 11.6% ± 1.2% | 4.84 |
| dame_hoolet | 38.2% | 2053 | 7.9% ± 1.2% | 5.03 |
| hob_mumblecrust | 32.3% | 1730 | 7.8% ± 1.3% | 4.82 |
| jill_down_the_tree | 11.8% | 626 | 7.3% ± 2.0% | 5.06 |
| brother_bracken | 16.1% | 853 | 1.5% ± 0.8% | 5.44 |

## Time per bot turn

Measured here, while other bench shards ran. Phone-speed core assumed 3 times slower (an assumption: no device was tested). The limit is 7 bots in about 1 s.

A whole lobby's turn, all Hard: mean 231 ms, 95th percentile 480 ms, worst 698 ms here; on the assumed phone core mean 0.69 s, 95th percentile 1.44 s.

| Level | Turns | Mean ms | 95th pct ms | Worst ms | 7 bots on a phone, mean |
|---|---:|---:|---:|---:|---:|
| naive | 45820 | 1.3 | 2.8 | 9.3 | 0.03 s |
| easy | 31470 | 2.6 | 5.0 | 11.0 | 0.06 s |
| normal | 4925 | 4.3 | 9.6 | 22.9 | 0.09 s |
| hard | 294671 | 35.4 | 88.0 | 142.4 | 0.74 s |

## What ran on what code

| Suite | Games | Commit |
|---|---:|---|
| hard_easy | 300 | 1d12de0 |
| hard_lobby_normal | 500 | 1d12de0 |
| hard_naive | 500 | 1d12de0 |
| normal_easy | 300 | 1d12de0 |
| place_search | 500 | 1d12de0 |
| place_shuffled | 500 | 1d12de0 |
| spread | 2000 | 1d12de0 |

