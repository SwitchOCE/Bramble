## Average place

| Pool | Rules | Arm | Games | Avg place | SE | vs shuffled (95% CI) | Top 4 |
|---|---|---|---:|---:|---:|---:|---:|
| a | - | heuristic | 1000 | 3.067 | 0.061 | +0.111 (+0.005 to +0.217) | 72% |
| a | - | search | 1000 | 3.039 | 0.062 | +0.139 (+0.028 to +0.250) | 73% |
| a | - | shuffled | 1000 | 3.178 | 0.065 |  | 68% |
| a | back_row_half | heuristic | 1000 | 3.287 | 0.062 | +0.980 (+0.860 to +1.100) | 68% |
| a | back_row_half | search | 1000 | 3.365 | 0.063 | +0.902 (+0.787 to +1.017) | 66% |
| a | back_row_half | shuffled | 1000 | 4.267 | 0.061 |  | 46% |
| b | - | heuristic | 1000 | 3.141 | 0.061 | +0.680 (+0.559 to +0.801) | 70% |
| b | - | oracle | 1000 | 2.293 | 0.055 | +1.528 (+1.400 to +1.656) | 83% |
| b | - | scout | 1000 | 2.743 | 0.060 | +1.078 (+0.952 to +1.204) | 75% |
| b | - | search | 1000 | 3.053 | 0.062 | +0.768 (+0.644 to +0.892) | 70% |
| b | - | shuffled | 1000 | 3.821 | 0.064 |  | 55% |
| b | across_targeting | heuristic | 1000 | 3.104 | 0.062 | +0.767 (+0.644 to +0.890) | 70% |
| b | across_targeting | scout | 1000 | 2.667 | 0.060 | +1.204 (+1.080 to +1.328) | 77% |
| b | across_targeting | search | 1000 | 3.015 | 0.062 | +0.856 (+0.736 to +0.976) | 70% |
| b | across_targeting | shuffled | 1000 | 3.871 | 0.064 |  | 53% |
| b | back_row_half | heuristic | 1000 | 3.303 | 0.062 | +1.000 (+0.877 to +1.123) | 67% |
| b | back_row_half | search | 1000 | 3.121 | 0.062 | +1.182 (+1.054 to +1.310) | 70% |
| b | back_row_half | shuffled | 1000 | 4.303 | 0.061 |  | 44% |

## Fights by stage

| Pool | Rules | Stage | Arm | Fights | Win rate (tie = half) | SE | Units | Full board | Pos. units |
|---|---|---|---|---:|---:|---:|---:|---:|---:|
| a | - | early (rounds 1-4) | heuristic | 4000 | 44.5% | 0.7 | 2.0 | 0% | 0.0 |
| a | - | early (rounds 1-4) | search | 4000 | 44.5% | 0.7 | 2.0 | 0% | 0.0 |
| a | - | early (rounds 1-4) | shuffled | 4000 | 43.4% | 0.7 | 2.0 | 0% | 0.0 |
| a | - | late (rounds 9+) | heuristic | 3923 | 66.7% | 0.7 | 7.0 | 100% | 0.0 |
| a | - | late (rounds 9+) | search | 3691 | 67.4% | 0.7 | 7.0 | 100% | 0.0 |
| a | - | late (rounds 9+) | shuffled | 3648 | 67.5% | 0.7 | 7.0 | 100% | 0.0 |
| a | - | mid (rounds 5-8) | heuristic | 3975 | 60.6% | 0.7 | 6.4 | 71% | 0.0 |
| a | - | mid (rounds 5-8) | search | 3977 | 60.6% | 0.7 | 6.4 | 71% | 0.0 |
| a | - | mid (rounds 5-8) | shuffled | 3973 | 57.0% | 0.8 | 6.4 | 71% | 0.0 |
| a | back_row_half | early (rounds 1-4) | heuristic | 4000 | 43.9% | 0.7 | 2.0 | 0% | 0.0 |
| a | back_row_half | early (rounds 1-4) | search | 4000 | 43.1% | 0.7 | 2.0 | 0% | 0.0 |
| a | back_row_half | early (rounds 1-4) | shuffled | 4000 | 37.3% | 0.7 | 2.0 | 0% | 0.0 |
| a | back_row_half | late (rounds 9+) | heuristic | 2814 | 64.9% | 0.9 | 7.0 | 100% | 0.0 |
| a | back_row_half | late (rounds 9+) | search | 2747 | 65.0% | 0.9 | 7.0 | 100% | 0.0 |
| a | back_row_half | late (rounds 9+) | shuffled | 2019 | 56.8% | 1.1 | 7.0 | 100% | 0.0 |
| a | back_row_half | mid (rounds 5-8) | heuristic | 3976 | 60.3% | 0.8 | 6.4 | 71% | 0.0 |
| a | back_row_half | mid (rounds 5-8) | search | 3960 | 57.9% | 0.8 | 6.4 | 71% | 0.0 |
| a | back_row_half | mid (rounds 5-8) | shuffled | 3914 | 50.0% | 0.8 | 6.4 | 71% | 0.0 |
| b | - | early (rounds 1-4) | heuristic | 4000 | 44.3% | 0.7 | 2.0 | 0% | 0.5 |
| b | - | early (rounds 1-4) | oracle | 4000 | 49.5% | 0.7 | 2.0 | 0% | 0.5 |
| b | - | early (rounds 1-4) | scout | 4000 | 45.3% | 0.7 | 2.0 | 0% | 0.5 |
| b | - | early (rounds 1-4) | search | 4000 | 44.5% | 0.7 | 2.0 | 0% | 0.5 |
| b | - | early (rounds 1-4) | shuffled | 4000 | 42.8% | 0.7 | 2.0 | 0% | 0.5 |
| b | - | late (rounds 9+) | heuristic | 3427 | 66.4% | 0.8 | 7.0 | 100% | 2.5 |
| b | - | late (rounds 9+) | oracle | 3932 | 75.7% | 0.7 | 7.0 | 100% | 2.5 |
| b | - | late (rounds 9+) | scout | 3609 | 71.1% | 0.7 | 7.0 | 100% | 2.5 |
| b | - | late (rounds 9+) | search | 3322 | 68.3% | 0.8 | 7.0 | 100% | 2.5 |
| b | - | late (rounds 9+) | shuffled | 2681 | 62.0% | 0.9 | 7.0 | 100% | 2.4 |
| b | - | mid (rounds 5-8) | heuristic | 3980 | 59.9% | 0.8 | 6.4 | 72% | 1.8 |
| b | - | mid (rounds 5-8) | oracle | 3993 | 68.5% | 0.7 | 6.4 | 72% | 1.8 |
| b | - | mid (rounds 5-8) | scout | 3983 | 63.3% | 0.7 | 6.4 | 72% | 1.8 |
| b | - | mid (rounds 5-8) | search | 3985 | 59.8% | 0.8 | 6.4 | 72% | 1.8 |
| b | - | mid (rounds 5-8) | shuffled | 3952 | 50.6% | 0.8 | 6.4 | 72% | 1.8 |
| b | across_targeting | early (rounds 1-4) | heuristic | 4000 | 44.1% | 0.7 | 2.0 | 0% | 0.5 |
| b | across_targeting | early (rounds 1-4) | scout | 4000 | 45.1% | 0.7 | 2.0 | 0% | 0.5 |
| b | across_targeting | early (rounds 1-4) | search | 4000 | 44.4% | 0.7 | 2.0 | 0% | 0.5 |
| b | across_targeting | early (rounds 1-4) | shuffled | 4000 | 42.5% | 0.7 | 2.0 | 0% | 0.5 |
| b | across_targeting | late (rounds 9+) | heuristic | 3422 | 66.9% | 0.8 | 7.0 | 100% | 2.4 |
| b | across_targeting | late (rounds 9+) | scout | 3621 | 71.9% | 0.7 | 7.0 | 100% | 2.5 |
| b | across_targeting | late (rounds 9+) | search | 3378 | 68.2% | 0.8 | 7.0 | 100% | 2.5 |
| b | across_targeting | late (rounds 9+) | shuffled | 2727 | 60.9% | 0.9 | 7.0 | 100% | 2.5 |
| b | across_targeting | mid (rounds 5-8) | heuristic | 3974 | 60.2% | 0.8 | 6.4 | 72% | 1.8 |
| b | across_targeting | mid (rounds 5-8) | scout | 3984 | 63.6% | 0.7 | 6.4 | 72% | 1.8 |
| b | across_targeting | mid (rounds 5-8) | search | 3979 | 59.7% | 0.8 | 6.4 | 72% | 1.8 |
| b | across_targeting | mid (rounds 5-8) | shuffled | 3958 | 50.7% | 0.8 | 6.4 | 72% | 1.8 |
| b | back_row_half | early (rounds 1-4) | heuristic | 4000 | 44.1% | 0.7 | 2.0 | 0% | 0.5 |
| b | back_row_half | early (rounds 1-4) | search | 4000 | 43.7% | 0.7 | 2.0 | 0% | 0.5 |
| b | back_row_half | early (rounds 1-4) | shuffled | 4000 | 38.6% | 0.7 | 2.0 | 0% | 0.5 |
| b | back_row_half | late (rounds 9+) | heuristic | 2781 | 64.7% | 0.9 | 7.0 | 100% | 2.4 |
| b | back_row_half | late (rounds 9+) | search | 2867 | 67.7% | 0.9 | 7.0 | 100% | 2.5 |
| b | back_row_half | late (rounds 9+) | shuffled | 1937 | 58.4% | 1.1 | 7.0 | 100% | 2.4 |
| b | back_row_half | mid (rounds 5-8) | heuristic | 3972 | 59.4% | 0.8 | 6.4 | 72% | 1.8 |
| b | back_row_half | mid (rounds 5-8) | search | 3972 | 61.4% | 0.8 | 6.4 | 72% | 1.8 |
| b | back_row_half | mid (rounds 5-8) | shuffled | 3912 | 48.9% | 0.8 | 6.4 | 71% | 1.8 |

## Same board, real opponent: win rate of each way of arranging it

| Pool | Rules | Slice | Boards | Random layout | Worst of 10 | Best of 10 | Heuristic | Search (old boards) | Search (scouted) | Search (real board) | Contested |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| a | - | early (rounds 1-4) | 400 | 45.5% | 42.5% | 48.8% | 46.1% | 46.0% | nan% | 47.9% | 30% |
| a | - | late (rounds 9+) | 348 | 61.8% | 45.5% | 77.6% | 62.1% | 66.5% | nan% | 74.8% | 52% |
| a | - | mid (rounds 5-8) | 386 | 54.8% | 42.4% | 68.3% | 60.0% | 59.8% | nan% | 65.8% | 38% |
| a | - | units < 7 | 520 | 48.0% | 42.6% | 53.4% | 49.3% | 49.3% | nan% | 52.2% | 32% |
| a | - | units = 7 | 614 | 58.5% | 44.0% | 73.4% | 61.2% | 63.5% | nan% | 70.8% | 45% |
| b | - | early (rounds 1-4) | 600 | 43.9% | 38.7% | 49.9% | 44.9% | 45.1% | 45.5% | 50.3% | 31% |
| b | - | late (rounds 9+) | 468 | 57.0% | 38.2% | 74.8% | 63.0% | 65.0% | 68.8% | 74.1% | 50% |
| b | - | mid (rounds 5-8) | 573 | 51.7% | 36.9% | 69.4% | 60.7% | 61.9% | 65.2% | 69.9% | 42% |
| b | - | units < 7 | 773 | 45.9% | 38.5% | 54.3% | 48.4% | 48.6% | 49.8% | 54.5% | 33% |
| b | - | units = 7 | 868 | 54.3% | 37.4% | 72.3% | 62.0% | 63.9% | 67.3% | 72.3% | 47% |
