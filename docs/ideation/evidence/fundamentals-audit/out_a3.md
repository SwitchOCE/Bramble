Check: lobby-rounds with an even number alive where wins != losses or ties are odd: 0 (expect 0).

## 1. Per-player win rate W/(W+L), all 3,200 players

| win rate | players | share | mean place |
|---:|---:|---:|---:|
| 0-10% | 87 | 2.7% | 7.71 |
| 10-20% | 240 | 7.5% | 7.43 |
| 20-30% | 314 | 9.8% | 6.90 |
| 30-40% | 492 | 15.4% | 6.01 |
| 40-50% | 501 | 15.7% | 4.97 |
| 50-60% | 591 | 18.5% | 3.75 |
| 60-70% | 441 | 13.8% | 2.65 |
| 70-80% | 392 | 12.2% | 1.96 |
| 80-90% | 111 | 3.5% | 1.31 |
| 90-100% | 31 | 1.0% | 1.00 |

All fights pooled: 24291 wins, 23020 losses, 1462 ties: win share of decided 51.34%. Mean of per-player rates 47.6%, median 46.7%, sd 20.3 points.
Coin-flip null with the same fight counts: sd 13.4 points. Observed spread is 1.5x the coin-flip spread.


## 2. Win chance against lobby rank of board stats (rounds with 8 alive)

Rank 1 = biggest board in the lobby that round. 'Stats decide' = the bigger board always wins against a random opponent: (8-rank)/7.

| stat rank | stats decide | R3-5 | R6-8 | R9-11 |
|---:|---:|---:|---:|---:|
| 1 | 100% | 76% | 77% | 79% |
| 2 | 86% | 63% | 64% | 65% |
| 3 | 71% | 56% | 56% | 56% |
| 4 | 57% | 49% | 51% | 51% |
| 5 | 43% | 44% | 41% | 43% |
| 6 | 29% | 43% | 39% | 39% |
| 7 | 14% | 38% | 36% | 31% |
| 8 | 0% | 32% | 36% | 37% |


## 3. Win chance by board size relative to the lobby median (all rounds 4+, all alive counts)

| stats / lobby median | fights | win | tie |
|---:|---:|---:|---:|
| <=0.65 | 444 | 27% | 0% |
| 0.65-0.70 | 525 | 36% | 0% |
| 0.70-0.75 | 975 | 37% | 0% |
| 0.75-0.80 | 1552 | 35% | 0% |
| 0.80-0.85 | 2481 | 36% | 0% |
| 0.85-0.90 | 3065 | 37% | 0% |
| 0.90-0.95 | 4062 | 39% | 0% |
| 0.95-1.00 | 5199 | 43% | 0% |
| 1.00-1.05 | 7809 | 53% | 0% |
| 1.05-1.10 | 3805 | 59% | 0% |
| 1.10-1.15 | 2829 | 64% | 0% |
| 1.15-1.20 | 2095 | 71% | 0% |
| 1.20-1.25 | 1506 | 74% | 0% |
| 1.25-1.30 | 1028 | 79% | 0% |
| 1.30-1.35 | 695 | 84% | 0% |
| 1.35-1.40 | 395 | 83% | 0% |
| 1.40-1.45 | 234 | 91% | 0% |
| 1.45-1.50 | 170 | 87% | 0% |
| >=1.50 | 304 | 94% | 0% |


## 4. Streaks by final place

| place | longest win streak | longest loss streak | max loss streak | final loss streak mean | median |
|---:|---:|---:|---:|---:|---:|
| 1 | 8.09 | 2.44 | 9 | 0.00 | 0.00 |
| 2 | 7.14 | 2.77 | 9 | 1.82 | 2.00 |
| 3 | 5.83 | 2.74 | 9 | 1.81 | 2.00 |
| 4 | 4.18 | 3.29 | 9 | 2.17 | 2.00 |
| 5 | 3.16 | 3.48 | 9 | 1.81 | 2.00 |
| 6 | 2.37 | 4.06 | 9 | 2.20 | 2.00 |
| 7 | 2.04 | 4.83 | 11 | 3.20 | 3.00 |
| 8 | 1.37 | 6.30 | 11 | 5.17 | 5.00 |

Runs test on decided fights (all players): observed 21014 runs, expected 23056 if results were in random order within each player's own record; z = -22.9.
Fewer runs than expected means results cluster into streaks beyond what each player's overall rate explains.
Loss-run lengths (all runs): 1: 5601, 2: 2742, 3: 1314, 4: 645, 5: 330, 6: 213, 7: 129, 8: 94, 9: 54, 10: 30, 11: 4


## 5. Ties by round

| round | player-fights | tie share |
|---:|---:|---:|
| 1 | 3200 | 45.7% |
| 2 | 3200 | 0.0% |
| 3 | 3200 | 0.0% |
| 4 | 3200 | 0.0% |
| 5 | 3200 | 0.0% |
| 6 | 3200 | 0.0% |
| 7 | 3200 | 0.0% |
| 8 | 3200 | 0.0% |
| 9 | 3200 | 0.0% |
| 10 | 3196 | 0.0% |
| 11 | 3141 | 0.0% |
| 12 | 2869 | 0.0% |
| 13 | 2415 | 0.0% |
| 14 | 1874 | 0.0% |
| 15 | 1549 | 0.0% |
| 16 | 1383 | 0.0% |
| 17 | 1171 | 0.0% |
| 18 | 951 | 0.0% |
| 19 | 722 | 0.0% |
| 20 | 428 | 0.0% |
| 21 | 196 | 0.0% |
| 22 | 70 | 0.0% |
| 23 | 8 | 0.0% |

Overall tie share: 3.0% of player-fights.


## 6. Ghost fights (odd number alive)

Ghost fights: 1461 (3.65 per lobby). Live player won 1366 (93.5%), tied 0, ghost won 95 (6.5%).
Ghost board stats / living lobby median: median 0.82, p90 1.04; ghost smaller than every living board in 43% of ghost fights; ghost age (rounds since its owner went out) median 1, max 9.
| alive | ghost fights | ghost stats / median | ghost wins | ties |
|---:|---:|---:|---:|---:|
| 7 | 353 | 0.79 | 3.4% | 0.0% |
| 5 | 291 | 0.89 | 7.9% | 0.0% |
| 3 | 817 | 0.81 | 7.3% | 0.0% |

| ghost stats / median | fights | ghost wins |
|---:|---:|---:|
| 0.0-0.8 | 658 | 1.5% |
| 0.8-0.9 | 344 | 7.0% |
| 0.9-1.0 | 240 | 8.3% |
| 1.0-3.0 | 219 | 18.7% |

For comparison, a living board at 0.8-0.9 of the lobby median wins about the rate in section 3 against live opponents.
