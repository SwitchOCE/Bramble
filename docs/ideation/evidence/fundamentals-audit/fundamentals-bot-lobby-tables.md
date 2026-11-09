# Bramble fundamentals: pace, fights, Health, win spread, stat curve (bot-lobby reader)

Data: /home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/free_choice_plain.{players,rounds,cards}.csv. 400 complete 8-player lobbies (seeds 1-400), 3,200 players, 48,773 player-rounds, code c50f6c8 (progress.json stage complete). All rows complete; rows per player = rounds column for all 3,200.
Comparison: docs/ideation/evidence/damage-v05/B.*.jsonl.gz (200 Hard lobbies, same damage rule, older pool; real charges and Health), baseline-step2/free-choice.players.csv.gz (400 lobbies, pre-pass-2 pool).
Scripts (python3 -I): common.py, a1_pace.py, a2_hp.py, a2b_calib.py, a3_wins.py, a4_curve.py, a5_cards.py, a6_printed.py, a7_compare.py, a8_cond.py, a9_validate.py in this folder. Chart data: chart_stat_curve.json. Model parameters: model.json.

Board stats in rounds.csv = sum of attack+health of the recruit board after the round's fight (bench.gd:317-349, 382-393). They exclude Start of Combat and in-combat buffs (e.g. Squire Lollop, Old Isegrim, Brother Bracken).

# Part A. Pace, stat curve, spread, fights by place
## 1. Board stats by round (all living players; board recorded after the round's fight)

| round | alive | units med | 7 units | tier med | stats p25 | stats med | stats p75 | per-unit med | winners n | winners stats med | winners per-unit | top-4 stats med | attack med | health med |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 3200 | 0.00 | 0% | 1.00 | 0.00 | 0.00 | 5.00 | 5.00 | 400 | 0.00 | 5.00 | 0.00 | 0.00 | 0.00 |
| 2 | 3200 | 2.00 | 0% | 1.00 | 5.00 | 9.00 | 10.0 | 5.00 | 400 | 9.00 | 5.00 | 9.00 | 3.00 | 6.00 |
| 3 | 3200 | 3.00 | 0% | 2.00 | 16.0 | 19.0 | 21.0 | 5.33 | 400 | 19.0 | 5.67 | 19.0 | 7.00 | 12.0 |
| 4 | 3200 | 5.00 | 3% | 2.00 | 27.0 | 30.0 | 33.0 | 5.80 | 400 | 31.0 | 6.00 | 30.0 | 11.0 | 19.0 |
| 5 | 3200 | 7.00 | 67% | 2.00 | 38.0 | 42.0 | 46.0 | 6.43 | 400 | 44.0 | 6.82 | 43.0 | 15.0 | 27.0 |
| 6 | 3200 | 7.00 | 85% | 3.00 | 46.0 | 52.0 | 57.0 | 7.57 | 400 | 56.0 | 8.29 | 54.0 | 20.0 | 32.0 |
| 7 | 3200 | 7.00 | 88% | 3.00 | 58.0 | 64.0 | 72.0 | 9.43 | 400 | 71.0 | 10.6 | 67.0 | 26.0 | 39.0 |
| 8 | 3200 | 7.00 | 88% | 3.00 | 71.0 | 80.0 | 89.0 | 11.7 | 400 | 89.0 | 13.1 | 84.0 | 33.0 | 47.0 |
| 9 | 3200 | 7.00 | 88% | 4.00 | 82.0 | 92.0 | 103.0 | 13.5 | 400 | 105.0 | 15.4 | 96.0 | 39.0 | 53.0 |
| 10 | 3196 | 7.00 | 88% | 4.00 | 94.0 | 107.0 | 119.0 | 15.7 | 400 | 121.0 | 17.9 | 113.0 | 45.0 | 61.0 |
| 11 | 3141 | 7 | 87% | 4 | 108.0 | 121 | 134.0 | 17.9 | 400 | 136.0 | 20.1 | 127.0 | 52 | 69 |
| 12 | 2869 | 7 | 86% | 5 | 118.0 | 133 | 148.0 | 19.7 | 400 | 149.0 | 22.0 | 137.0 | 58 | 75 |
| 13 | 2415 | 7 | 83% | 5 | 128.0 | 145 | 161.0 | 21.6 | 400 | 162.0 | 23.9 | 148 | 63 | 81 |
| 14 | 1874 | 7.00 | 76% | 5.00 | 136.0 | 155.0 | 174.0 | 23.4 | 400 | 172.0 | 25.7 | 156.0 | 68.0 | 86.0 |
| 15 | 1549 | 7 | 73% | 6 | 141.0 | 162 | 186.0 | 25.0 | 400 | 182.0 | 27.3 | 162 | 72 | 90 |
| 16 | 1383 | 7 | 69% | 6 | 146.0 | 174 | 200.0 | 26.8 | 400 | 196.0 | 29.2 | 174 | 77 | 95 |
| 17 | 1171 | 7 | 67% | 6 | 157.0 | 187 | 217.0 | 29.0 | 398 | 206.0 | 31.1 | 187 | 84 | 102 |
| 18 | 951 | 7 | 67% | 6 | 167.0 | 200 | 234.0 | 31.0 | 378 | 221.0 | 32.8 | 200 | 90 | 109 |
| 19 | 722 | 7.00 | 67% | 6.00 | 180.0 | 213.0 | 248.0 | 33.2 | 324 | 232.5 | 34.7 | 213.0 | 97.0 | 115.0 |
| 20 | 428 | 7.00 | 66% | 6.00 | 190.0 | 220.0 | 255.2 | 34.4 | 200 | 239.0 | 35.4 | 220.0 | 101.0 | 118.0 |
| 21 | 196 | 7.00 | 63% | 6.00 | 196.5 | 234.0 | 272.5 | 35.9 | 95 | 253 | 36.9 | 234.0 | 104.5 | 124.0 |
| 22 | 70 | 7.00 | 67% | 6.00 | 203.5 | 242.5 | 288.2 | 37.4 | 34 | 270.0 | 38.6 | 242.5 | 110.5 | 132.5 |
| 23 | 8 | 7.00 | 88% | 6.00 | 208.8 | 287.5 | 333.5 | 41.1 | 4 | 343.0 | 49.0 | 287.5 | 126.5 | 161.0 |


## 2. Final board (last recorded round) by place

| place | n | rounds mean | rounds med | final stats p25 | final stats med | p75 | per-unit med | units | tier6 turn (reached) | reached T6 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 400 | 19.6 | 19.5 | 204.8 | 242.0 | 275.0 | 35.9 | 6.63 | 14.1 | 100% |
| 2 | 400 | 19.6 | 19.5 | 167.0 | 199.0 | 235.0 | 32.6 | 6.11 | 14.3 | 100% |
| 3 | 400 | 17.5 | 17.0 | 140.8 | 169.5 | 199.0 | 27.1 | 6.25 | 14.5 | 99% |
| 4 | 400 | 15.4 | 16.0 | 135.8 | 153.0 | 173.0 | 23.1 | 6.59 | 14.7 | 77% |
| 5 | 400 | 13.6 | 14.0 | 133.0 | 147.0 | 161.2 | 21.1 | 6.87 | 14.1 | 15% |
| 6 | 400 | 12.9 | 13.0 | 126.0 | 138.0 | 151.0 | 19.8 | 6.95 | 13.5 | 2% |
| 7 | 400 | 12.1 | 12.0 | 114.0 | 126.5 | 139.0 | 18.1 | 6.97 | nan | 0% |
| 8 | 400 | 11.2 | 11.0 | 99.0 | 112.0 | 126.0 | 16.0 | 7.00 | nan | 0% |


## 3. Spread of boards inside one lobby, by round (median over lobbies)

ratio = player's stats / lobby median that round, living players only.

| round | lobbies | max/median | min/median | max/min | top/second | CV (sd/mean) | IQR/median | max-min (abs) |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 95 | 2.00 | 0.00 | 5.00 | 1.00 | 1.00 | 2.00 | 5 |
| 2 | 400 | 1.33 | 0.53 | 2.40 | 1.10 | 0.30 | 0.39 | 7.00 |
| 3 | 400 | 1.27 | 0.74 | 1.75 | 1.09 | 0.18 | 0.21 | 10.0 |
| 4 | 400 | 1.21 | 0.79 | 1.56 | 1.07 | 0.14 | 0.17 | 13.0 |
| 5 | 400 | 1.21 | 0.81 | 1.52 | 1.07 | 0.13 | 0.15 | 17.0 |
| 6 | 400 | 1.24 | 0.81 | 1.55 | 1.07 | 0.14 | 0.17 | 23.0 |
| 7 | 400 | 1.25 | 0.81 | 1.57 | 1.07 | 0.15 | 0.18 | 30.0 |
| 8 | 400 | 1.22 | 0.81 | 1.53 | 1.06 | 0.14 | 0.17 | 34.0 |
| 9 | 400 | 1.24 | 0.80 | 1.57 | 1.07 | 0.15 | 0.18 | 41.0 |
| 10 | 400 | 1.25 | 0.79 | 1.61 | 1.07 | 0.15 | 0.18 | 50.0 |
| 11 | 400 | 1.22 | 0.79 | 1.57 | 1.07 | 0.14 | 0.18 | 54.0 |
| 12 | 400 | 1.22 | 0.79 | 1.56 | 1.07 | 0.14 | 0.17 | 59.0 |
| 13 | 400 | 1.20 | 0.80 | 1.53 | 1.08 | 0.14 | 0.16 | 61.0 |
| 14 | 400 | 1.20 | 0.80 | 1.51 | 1.10 | 0.15 | 0.17 | 64.0 |
| 15 | 398 | 1.18 | 0.80 | 1.50 | 1.12 | 0.16 | 0.18 | 66.0 |
| 16 | 379 | 1.18 | 0.80 | 1.52 | 1.14 | 0.17 | 0.19 | 71 |
| 17 | 310 | 1.16 | 0.80 | 1.52 | 1.14 | 0.17 | 0.19 | 74.5 |
| 18 | 190 | 1.18 | 0.81 | 1.49 | 1.17 | 0.17 | 0.20 | 74.5 |
| 19 | 74 | 1.15 | 0.82 | 1.43 | 1.15 | 0.15 | 0.17 | 74.5 |
| 20 | 28 | 1.16 | 0.81 | 1.50 | 1.16 | 0.17 | 0.19 | 94.0 |
| 21 | 6 | 1.44 | 0.87 | 1.73 | 1.44 | 0.23 | 0.30 | 120.0 |
| 22 | 2 | 1.75 | 0.76 | 2.30 | 1.75 | 0.36 | 0.50 | 204.0 |


## 4. Fights by final place

| place | rounds | wins | losses | ties | win rate W/(W+L) mean | p10 | p90 | min losses | max losses |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 19.6 | 14.1 | 5.02 | 0.45 | 0.74 | 0.60 | 0.89 | 0 | 10 |
| 2 | 19.6 | 12.4 | 6.67 | 0.49 | 0.65 | 0.50 | 0.78 | 3 | 11 |
| 3 | 17.5 | 10.3 | 6.74 | 0.40 | 0.60 | 0.47 | 0.75 | 3 | 12 |
| 4 | 15.4 | 7.53 | 7.42 | 0.47 | 0.50 | 0.38 | 0.65 | 4 | 12 |
| 5 | 13.6 | 5.94 | 7.22 | 0.46 | 0.45 | 0.31 | 0.58 | 3 | 11 |
| 6 | 12.9 | 4.62 | 7.83 | 0.45 | 0.37 | 0.23 | 0.50 | 5 | 11 |
| 7 | 12.1 | 3.60 | 8.07 | 0.45 | 0.30 | 0.17 | 0.46 | 5 | 11 |
| 8 | 11.2 | 2.17 | 8.58 | 0.49 | 0.20 | 0.09 | 0.33 | 5 | 11 |


## 5. Wins in rounds 1-6 against final place

| wins R1-6 | players | share | mean place | top 4 | 1st | 7th-8th |
|---:|---:|---:|---:|---:|---:|---:|
| 0 | 216 | 6.8% | 6.00 | 21% | 7.4% | 54% |
| 1 | 530 | 16.6% | 5.48 | 32% | 7.2% | 42% |
| 2 | 727 | 22.7% | 4.93 | 40% | 11.3% | 31% |
| 3 | 686 | 21.4% | 4.40 | 51% | 13.0% | 20% |
| 4 | 517 | 16.2% | 3.94 | 59% | 18.0% | 16% |
| 5 | 385 | 12.0% | 3.03 | 83% | 15.8% | 4% |
| 6 | 139 | 4.3% | 2.85 | 88% | 15.1% | 2% |


## 6. Early (R1-6) and middle (R7-12) wins together: mean place (n)

| R1-6 wins \ R7-12 wins | 0-1 | 2-3 | 4 | 5-6 |
|---:|---:|---:|---:|---:|
| 0-1 | 7.60 (273) | 5.28 (312) | 3.45 (92) | 2.38 (69) |
| 2-3 | 7.22 (308) | 4.85 (642) | 3.15 (248) | 2.23 (215) |
| 4 | 6.62 (100) | 4.45 (185) | 2.72 (86) | 2.16 (146) |
| 5-6 | 6.12 (24) | 3.79 (121) | 3.08 (99) | 2.33 (280) |


## 7. Elimination round by place (last recorded round)

| place | min | p25 | median | p75 | max |
|---:|---:|---:|---:|---:|---:|
| 1 | 16 | 19.0 | 19.5 | 20.0 | 23 |
| 2 | 16 | 19.0 | 19.5 | 20.0 | 23 |
| 3 | 14 | 17.0 | 17.0 | 18.0 | 22 |
| 4 | 12 | 15.0 | 16.0 | 16.0 | 18 |
| 5 | 12 | 13.0 | 14.0 | 14.0 | 16 |
| 6 | 11 | 12.0 | 13.0 | 13.0 | 14 |
| 7 | 11 | 12.0 | 12.0 | 13.0 | 14 |
| 8 | 9 | 11.0 | 11.0 | 12.0 | 13 |

First elimination round per lobby: median 11.0, p25 11.0, p75 12.0. Game length (winner rounds) median 19.5, mean 19.58.

# Part B. Health: damage per loss (arm B), calibration, paths
## A. Arm B by final place: losses and what they cost

| place | losses | base taken | survivor dmg taken | total | survivors per loss | overkill | used Last Stand |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 5.38 | 21.6 | 7.87 | 29.4 | 1.46 | 0.00 | 26% |
| 2 | 7.66 | 49.5 | 11.8 | 61.4 | 1.54 | 13.7 | 95% |
| 3 | 7.63 | 48.4 | 11.9 | 60.4 | 1.56 | 13.4 | 88% |
| 4 | 7.21 | 42.8 | 12.3 | 55.1 | 1.71 | 10.8 | 55% |
| 5 | 7.17 | 35.1 | 11.9 | 47.0 | 1.66 | 7.00 | 0% |
| 6 | 7.50 | 33.5 | 13.1 | 46.6 | 1.74 | 6.59 | 0% |
| 7 | 7.66 | 31.4 | 14.6 | 46.0 | 1.90 | 5.98 | 0% |
| 8 | 8.30 | 27.6 | 17.1 | 44.7 | 2.06 | 4.70 | 0% |


## B. Pass 2 by final place: base taken (exact) and survivor damage implied

Places 5-8 die with 5+ alive, so Last Stand cannot fire: total taken = 40 + overkill. Overkill taken from arm B by place.

| place | losses | base taken | survivor dmg if arm B rates | survivor dmg implied (40+overkill-base) | implied survivors per loss | Last Stand certain (base alone >=40 before last loss) |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 5.02 | 22.2 | 8.34 | nan | nan | 11% |
| 2 | 6.67 | 49.8 | 11.2 | nan | nan | 30% |
| 3 | 6.74 | 48.8 | 11.6 | nan | nan | 25% |
| 4 | 7.42 | 44.5 | 12.8 | nan | nan | 16% |
| 5 | 7.22 | 32.7 | 12.4 | 14.3 | 1.98 | 0% |
| 6 | 7.83 | 31.0 | 13.5 | 15.6 | 1.99 | 0% |
| 7 | 8.07 | 28.3 | 14.0 | 17.7 | 2.19 | 0% |
| 8 | 8.58 | 24.5 | 14.9 | 20.2 | 2.35 | 0% |

Implied scale on arm B survivor rates, places 5-8: 1.23

## 1. Damage per loss by round, damage-v05 arm B (200 Hard lobbies, older card pool, same damage rule)

Survivors = enemy starting survivors (the 'performance' part). Each loss is one charge to a real hero.

| round | losses | base | survivors mean | survivors med | survivors p90 | damage mean | survivor share |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 462 | 0 | 0.97 | 1.00 | 1.00 | 0.97 | 100% |
| 2 | 799 | 0 | 1.14 | 1 | 2.00 | 1.14 | 100% |
| 3 | 800 | 0 | 1.34 | 1.00 | 3.00 | 1.34 | 100% |
| 4 | 799 | 1 | 1.62 | 1 | 3.00 | 2.62 | 52% |
| 5 | 800 | 1 | 1.87 | 2.00 | 4.00 | 2.87 | 55% |
| 6 | 800 | 2 | 1.90 | 2.00 | 4.00 | 3.90 | 43% |
| 7 | 800 | 2 | 1.95 | 2.00 | 4.00 | 3.95 | 43% |
| 8 | 800 | 3 | 1.78 | 2.00 | 4.00 | 4.78 | 33% |
| 9 | 800 | 4 | 1.86 | 2.00 | 4.00 | 5.86 | 28% |
| 10 | 800 | 5 | 1.91 | 2.00 | 4.00 | 6.91 | 25% |
| 11 | 794 | 7 | 1.94 | 2.00 | 4.00 | 8.94 | 20% |
| 12 | 728 | 9 | 1.85 | 2.00 | 4.00 | 10.9 | 16% |
| 13 | 623 | 11 | 1.80 | 2 | 4.00 | 12.8 | 13% |
| 14 | 482 | 13 | 1.82 | 2.00 | 4.00 | 14.8 | 12% |
| 15 | 365 | 13 | 1.72 | 2 | 4.00 | 14.7 | 11% |
| 16 | 314 | 13 | 1.92 | 2.00 | 4.00 | 14.9 | 12% |
| 17 | 245 | 13 | 1.73 | 2 | 3.60 | 14.7 | 11% |
| 18 | 194 | 13 | 1.76 | 2.00 | 3.00 | 14.8 | 11% |
| 19 | 151 | 13 | 1.66 | 2 | 3.00 | 14.7 | 11% |
| 20 | 94 | 13 | 1.64 | 1.00 | 3.00 | 14.6 | 11% |
| 21 | 37 | 13 | 1.38 | 1 | 3.40 | 14.4 | 9% |
| 22 | 8 | 13 | 1.00 | 0.50 | 2.60 | 14.0 | 6% |
| 23 | 2 | 13 | 1.00 | 1.00 | 1.00 | 14.0 | 7% |

Ghost fights (arm B): 723; live player won 664, tied 0, ghost won 59 (8.2%).
Last Stand saves used (arm B): 527 in 200 lobbies (2.63 per lobby).
Killing blows: 1400; Health before the blow median 4; overkill (damage - health before) mean 8.9, median 10.


## 2. Median Health at end of round, by final place (arm B)

| round | place 1 | place 2 | place 3 | place 4 | place 5 | place 6 | place 7 | place 8 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 40 | 40 | 40 | 40 | 40 | 40 | 40 | 40 |
| 2 | 39 | 39 | 39 | 39 | 39 | 39 | 39 | 39 |
| 3 | 39 | 39 | 39 | 39 | 39 | 39 | 39 | 39 |
| 4 | 37 | 38 | 37 | 38 | 38 | 37 | 38 | 37 |
| 5 | 36 | 37 | 37 | 36 | 36 | 36 | 36 | 34 |
| 6 | 35 | 35 | 35 | 35 | 35 | 34 | 33 | 31 |
| 7 | 33 | 34 | 34 | 33 | 32 | 33 | 31 | 28 |
| 8 | 32 | 31 | 32 | 31 | 31 | 29 | 27 | 24 |
| 9 | 31 | 29 | 30 | 29 | 28 | 26 | 24 | 18 |
| 10 | 29 | 27 | 28 | 26 | 24 | 21 | 19 | 11 |
| 11 | 28 | 25 | 24 | 24 | 20 | 17 | 12 | 4 |
| 12 | 25 | 22 | 21 | 18 | 14 | 9 | 4 | -4 |
| 13 | 23 | 20 | 18 | 13 | 7 | -2 | -7 | -10 |
| 14 | 20 | 15 | 12 | 5 | -5 | -9 | - | - |
| 15 | 19 | 11 | 5 | 1 | -10 | - | - | - |
| 16 | 16 | 8 | 1 | -14 | - | - | - | - |
| 17 | 15 | 1 | 1 | -14 | - | - | - | - |
| 18 | 13 | 1 | -13 | - | - | - | - | - |
| 19 | 8 | 1 | -12 | - | - | - | - | - |
| 20 | 3 | -13 | - | - | - | - | - | - |
| 21 | 1 | -13 | - | - | - | - | - | - |
| 22 | - | - | - | - | - | - | - | - |

Losses over the game by place (arm B): 1: 5.3, 2: 7.7, 3: 7.6, 4: 7.2, 5: 7.2, 6: 7.5, 7: 7.7, 8: 8.3


## 3. Pass 2 lobbies: base damage taken and what survivors must have added

Base damage is known exactly from the loss rounds. Health is not logged, so survivor damage is inferred: an eliminated hero took at least 40 in total.

| place | losses | losses from R4 (base>0) | base taken mean | base med | survivor damage needed (40-base) | per charged loss | last fight a loss |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 5.02 | 3.79 | 22.2 | 22.0 | nan | nan | 0% |
| 2 | 6.67 | 5.67 | 49.8 | 51.0 | -9.78 | -1.73 | 100% |
| 3 | 6.74 | 5.75 | 48.8 | 50.0 | -8.77 | -1.52 | 100% |
| 4 | 7.42 | 6.17 | 44.5 | 46.0 | -4.52 | -0.73 | 100% |
| 5 | 7.22 | 5.88 | 32.7 | 33.0 | 7.31 | 1.24 | 100% |
| 6 | 7.83 | 6.45 | 31.0 | 31.0 | 8.96 | 1.39 | 100% |
| 7 | 8.07 | 6.64 | 28.3 | 28.0 | 11.7 | 1.76 | 100% |
| 8 | 8.58 | 7.02 | 24.5 | 24.0 | 15.5 | 2.21 | 100% |

Eliminated players: survivor damage at least 0.37 per charged loss (mean of per-player lower bounds).


## 4. Pass 2: when losses happen, by final place (mean losses in each band)

| place | R1-3 | R4-6 | R7-9 | R10-12 | R13-15 | R16-23 |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1.23 | 1.14 | 0.93 | 0.64 | 0.52 | 0.56 |
| 2 | 1.00 | 0.97 | 0.79 | 0.69 | 0.75 | 2.47 |
| 3 | 0.98 | 0.94 | 0.94 | 0.84 | 1.32 | 1.71 |
| 4 | 1.25 | 1.30 | 1.19 | 1.27 | 1.78 | 0.63 |
| 5 | 1.34 | 1.52 | 1.55 | 1.52 | 1.28 | 0.01 |
| 6 | 1.38 | 1.81 | 1.91 | 1.92 | 0.81 | 0.00 |
| 7 | 1.43 | 1.94 | 2.12 | 2.31 | 0.28 | 0.00 |
| 8 | 1.56 | 2.38 | 2.58 | 2.02 | 0.04 | 0.00 |


Calibration (a2b): arm B survivors-per-loss curve scaled by 1.23, fitted on pass 2 places 5-8 (no Last Stand), overkill by place from arm B.
With that scale, winners' modelled damage taken: median 33.8, p90 52.6, share above 39: 38% (Last Stand can cover one).


## 5. Model: expected Health lost per loss by round (base + scaled survivors)

| round | base | survivors (model) | loss costs | cumulative if lose every round | Health left |
|---:|---:|---:|---:|---:|---:|
| 1 | 0 | 1.20 | 1.20 | 1.20 | 38.8 |
| 2 | 0 | 1.41 | 1.41 | 2.61 | 37.4 |
| 3 | 0 | 1.65 | 1.65 | 4.26 | 35.7 |
| 4 | 1 | 2.00 | 3.00 | 7.26 | 32.7 |
| 5 | 1 | 2.31 | 3.31 | 10.6 | 29.4 |
| 6 | 2 | 2.34 | 4.34 | 14.9 | 25.1 |
| 7 | 2 | 2.40 | 4.40 | 19.3 | 20.7 |
| 8 | 3 | 2.20 | 5.20 | 24.5 | 15.5 |
| 9 | 4 | 2.30 | 6.30 | 30.8 | 9.20 |
| 10 | 5 | 2.36 | 7.36 | 38.2 | 1.84 |
| 11 | 7 | 2.40 | 9.40 | 47.6 | -7.55 |
| 12 | 9 | 2.28 | 11.3 | 58.8 | -18.8 |
| 13 | 11 | 2.22 | 13.2 | 72.1 | -32.1 |
| 14 | 13 | 2.25 | 15.2 | 87.3 | -47.3 |
| 15 | 13 | 2.13 | 15.1 | 102.4 | -62.4 |
| 16 | 13 | 2.37 | 15.4 | 117.8 | -77.8 |
| 17 | 13 | 2.13 | 15.1 | 132.9 | -92.9 |
| 18 | 13 | 2.17 | 15.2 | 148.1 | -108.1 |
| 19 | 13 | 2.05 | 15.1 | 163.2 | -123.2 |
| 20 | 13 | 2.02 | 15.0 | 178.2 | -138.2 |
| 21 | 13 | 1.70 | 14.7 | 192.9 | -152.9 |
| 22 | 13 | 1.23 | 14.2 | 207.1 | -167.1 |


## 6. Paths: when do you die? (expected-value model; Monte Carlo with arm B survivor draws in brackets)

| path | dies in round | losses by then | Monte Carlo |
|---:|---:|---:|---:|
| lose every round from R1 | 11 | 11 | 100% die; R11.0; 11.0 losses |
| lose every round from R4 | 11 | 8 | 100% die; R11.0; 8.0 losses |
| win R1-6, then lose every round (mid-game slump) | 12 | 6 | 100% die; R12.0; 6.0 losses |
| win R1-9, then lose every round | 13 | 4 | 100% die; R13.0; 4.0 losses |
| win R1-12, then lose every round | 15 | 3 | 100% die; R15.0; 3.0 losses |
| lose R1-6, win R7-12, then lose every round | 14 | 8 | 100% die; R14.0; 8.0 losses |
| lose R1-8, then win R9-14, then lose every round | 16 | 10 | 100% die; R16.0; 10.0 losses |
| alternate W/L from R1 | 14 | 7 | 100% die; R14.0; 7.0 losses |
| alternate L/W from R1 | 15 | 8 | 100% die; R15.0; 8.0 losses |
| win 2 of 3 (WWL repeating) | 18 | 6 | 100% die; R18.0; 6.0 losses |
| lose 2 of 3 (LLW repeating) | 13 | 9 | 100% die; R13.0; 9.0 losses |


## 7. How many more losses you can afford, by Health and round the losing starts

| losing streak starts at round | from 40 Health | from 30 | from 20 | from 10 |
|---:|---:|---:|---:|---:|
| 7 | 6 | 5 | 4 | 3 |
| 10 | 4 | 4 | 3 | 2 |
| 12 | 4 | 3 | 2 | 1 |
| 14 | 3 | 2 | 2 | 1 |
| 16 | 3 | 2 | 2 | 1 |

Read: the number is the loss that knocks you out (e.g. 3 = you survive 2).


## 8. Health left after rounds 1-6, by losses taken in rounds 1-6 (model; losses placed at random rounds)

| losses in R1-6 | Health left mean | worst placement | best placement |
|---:|---:|---:|---:|
| 0 | 40.0 | 40 | 40 |
| 1 | 37.5 | 35.7 | 38.8 |
| 2 | 35.0 | 32.4 | 37.4 |
| 3 | 32.5 | 29.4 | 35.7 |
| 4 | 30.1 | 27.7 | 32.7 |
| 5 | 27.6 | 26.3 | 29.4 |
| 6 | 25.1 | 25.1 | 25.1 |

## Model check: replay each player's real results through the Health model

Predicted death = first round modelled Health <= 0 (places 5-8: no Last Stand; places 2-4: one save allowed once 4 or fewer are alive, which we approximate as rounds after the 5th-place exit).

| place | players | predicted round exact | within 1 | mean error (pred-actual) | model says still alive at end |
|---:|---:|---:|---:|---:|---:|
| 1 | 400 | 0% | 20% | -3.86 | 356 |
| 2 | 400 | 77% | 90% | -0.52 | 12 |
| 3 | 400 | 77% | 86% | -0.49 | 25 |
| 4 | 400 | 75% | 88% | -0.46 | 15 |
| 5 | 400 | 85% | 94% | -0.23 | 29 |
| 6 | 400 | 83% | 95% | -0.21 | 33 |
| 7 | 400 | 88% | 99% | -0.14 | 47 |
| 8 | 400 | 89% | 99% | -0.12 | 124 |

# Part C. Win spread, streaks, ties, ghosts
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

## Early wins (R1-6) against final place, split by board size at R6 (stats / lobby median): mean place (n)

| R1-6 wins \ R6 size | <0.95 | 0.95-1.05 | >=1.05 |
|---:|---:|---:|---:|
| 0-2 | 6.00 (606) | 5.24 (489) | 4.19 (378) |
| 3-4 | 5.04 (284) | 4.48 (387) | 3.55 (532) |
| 5-6 | 3.09 (200) | 3.03 (129) | 2.84 (195) |


## Does a result predict the next one? P(win in round r | result in r-1), decided fights, rounds 3+

After a win: 60.3% win. After a loss: 41.0% win.


## Early Spoils: wins in rounds 1-4 (1 gold each next turn) against place

| wins R1-4 | players | mean place | top 4 |
|---:|---:|---:|---:|
| 0 | 475 | 5.20 | 35% |
| 1 | 893 | 4.94 | 41% |
| 2 | 934 | 4.56 | 48% |
| 3 | 684 | 3.74 | 67% |
| 4 | 214 | 3.27 | 76% |

Round 1: 67% of players field no unit (spent: [(1, 2154)]).

# Part D. Stat curve shape and persistence
## 1. Shape of the median board-stats curve (fits on rounds 5-16; 5 = first full board, 16 = last round all winners are present)

| series | model | fit | R^2 | max error |
|---:|---:|---:|---:|---:|
| everyone alive | linear | -19.4 + 12.38 r | 0.99 | 4.68 |
| everyone alive | quadratic | -41.1 + 17.00 r + -0.220 r^2 | 1.00 | 3.55 |
| everyone alive | exponential | 26.7 * 1.135^r | 0.92 | 28.8 |
| everyone alive | power | 5.73 * r^1.25 | 0.99 | 10.5 |
| eventual winners | linear | -24.2 + 14.07 r | 0.99 | 5.38 |
| eventual winners | quadratic | -54.5 + 20.55 r + -0.308 r^2 | 1.00 | 3.48 |
| eventual winners | exponential | 28.4 * 1.140^r | 0.91 | 34.3 |
| eventual winners | power | 5.75 * r^1.30 | 0.98 | 13.5 |

Winners, rounds 8-19 only (income is flat at 10 from round 8):

| series | model | fit | R^2 | max error |
|---:|---:|---:|---:|---:|
| winners R8-19 | linear | -6.9 + 12.68 r | 1.00 | 5.55 |
| winners R8-19 | quadratic | -39.8 + 17.90 r + -0.193 r^2 | 1.00 | 3.18 |
| winners R8-19 | exponential | 52.2 * 1.086^r | 0.97 | 15.6 |
| winners R8-19 | power | 10.08 * r^1.07 | 0.99 | 4.58 |


## 2. Growth per round: median stats, increment, and growth rate

| round | all med | all + | all % | winners med | winners + | winners % | 5th-8th med | 5th-8th + | 5th-8th % |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 2 | 9.00 | - | - | 9.00 | - | - | 9.00 | - | - |
| 3 | 19.0 | 10.0 | 111% | 19.0 | 10.0 | 111% | 18.0 | 9.00 | 100% |
| 4 | 30.0 | 11.0 | 58% | 31.0 | 12.0 | 63% | 29.0 | 11.0 | 61% |
| 5 | 42.0 | 12.0 | 40% | 44.0 | 13.0 | 42% | 41.0 | 12.0 | 41% |
| 6 | 52.0 | 10.0 | 24% | 56.0 | 12.0 | 27% | 50.0 | 9.00 | 22% |
| 7 | 64.0 | 12.0 | 23% | 71.0 | 15.0 | 27% | 62.0 | 12.0 | 24% |
| 8 | 80.0 | 16.0 | 25% | 89.0 | 18.0 | 25% | 77.0 | 15.0 | 24% |
| 9 | 92.0 | 12.0 | 15% | 105.0 | 16.0 | 18% | 87.0 | 10.0 | 13% |
| 10 | 107.0 | 15.0 | 16% | 121.0 | 16.0 | 15% | 102.0 | 15.0 | 17% |
| 11 | 121 | 14.0 | 13% | 136.0 | 15.0 | 12% | 116 | 14.0 | 14% |
| 12 | 133 | 12 | 10% | 149.0 | 13.0 | 10% | 130 | 14 | 12% |
| 13 | 145 | 12 | 9% | 162.0 | 13.0 | 9% | 141.0 | 11.0 | 8% |
| 14 | 155.0 | 10.0 | 7% | 172.0 | 10.0 | 6% | 154.0 | 13.0 | 9% |
| 15 | 162 | 7.00 | 5% | 182.0 | 10.0 | 6% | 158.0 | 4.00 | 3% |
| 16 | 174 | 12 | 7% | 196.0 | 14.0 | 8% | - | - | - |
| 17 | 187 | 13 | 7% | 206.0 | 10.0 | 5% | - | - | - |
| 18 | 200 | 13 | 7% | 221.0 | 15.0 | 7% | - | - | - |
| 19 | 213.0 | 13.0 | 6% | 232.5 | 11.5 | 5% | - | - | - |
| 20 | 220.0 | 7.00 | 3% | 239.0 | 6.50 | 3% | - | - | - |
| 21 | 234.0 | 14.0 | 6% | 253 | 14.0 | 6% | - | - | - |
| 22 | 242.5 | 8.50 | 4% | 270.0 | 17.0 | 7% | - | - | - |


## 3. Same-player growth per round (median of each player's own increase from the previous round)

| round | players | median + | p10 | p90 | winners median + |
|---:|---:|---:|---:|---:|---:|
| 2 | 3200 | 5.00 | 4.00 | 10.0 | 5.00 |
| 3 | 3200 | 10.0 | 6.00 | 14.0 | 11.0 |
| 4 | 3200 | 12.0 | 6.00 | 16.0 | 12.0 |
| 5 | 3200 | 12.0 | 6.00 | 18.0 | 14.0 |
| 6 | 3200 | 9.00 | 2.00 | 18.0 | 12.0 |
| 7 | 3200 | 12.0 | 6.00 | 22.0 | 15.0 |
| 8 | 3200 | 15.0 | 7.00 | 25.0 | 17.0 |
| 9 | 3200 | 11.0 | 4.00 | 22.0 | 14.0 |
| 10 | 3196 | 14.0 | 4.50 | 26.0 | 17.0 |
| 11 | 3141 | 13 | 3.00 | 25.0 | 14.0 |
| 12 | 2869 | 10 | 0.00 | 23.0 | 11.0 |
| 13 | 2415 | 10 | 1.00 | 22.0 | 11.5 |
| 14 | 1874 | 7.00 | 0.00 | 22.0 | 8.00 |
| 15 | 1549 | 6 | -2.00 | 21.0 | 10.0 |
| 16 | 1383 | 8 | -2.00 | 25.0 | 12.0 |
| 17 | 1171 | 10 | -2.00 | 26.0 | 13.0 |
| 18 | 951 | 10 | -4.00 | 28.0 | 12.0 |
| 19 | 722 | 10.0 | -2.00 | 28.0 | 10.0 |
| 20 | 428 | 8.00 | -4.00 | 26.3 | 10.0 |
| 21 | 196 | 8.00 | -3.00 | 28.0 | 16 |
| 22 | 70 | 8.00 | 0.00 | 31.3 | 11.0 |


## 4. Board stats per gold spent so far (all alive): does a gold buy more stats later?

| round | players | stats per gold spent (median) | gold spent that round (mean) |
|---:|---:|---:|---:|
| 2 | 3200 | 1.25 | 5.59 |
| 3 | 3200 | 1.29 | 7.24 |
| 4 | 3200 | 1.38 | 7.33 |
| 5 | 3200 | 1.41 | 8.28 |
| 6 | 3200 | 1.31 | 9.68 |
| 7 | 3200 | 1.25 | 11.9 |
| 8 | 3200 | 1.23 | 13.2 |
| 9 | 3200 | 1.19 | 12.4 |
| 10 | 3196 | 1.18 | 12.8 |
| 11 | 3141 | 1.19 | 11.6 |
| 12 | 2869 | 1.18 | 11.3 |
| 13 | 2415 | 1.15 | 11.9 |
| 14 | 1874 | 1.13 | 11.9 |
| 15 | 1549 | 1.09 | 11.7 |
| 16 | 1383 | 1.08 | 11.6 |
| 17 | 1171 | 1.08 | 11.4 |
| 18 | 951 | 1.09 | 11.2 |
| 19 | 722 | 1.09 | 11.1 |
| 20 | 428 | 1.07 | 11.1 |
| 21 | 196 | 1.07 | 10.9 |
| 22 | 70 | 1.05 | 11.3 |


## 5. Does a lead persist? Correlation of a player's stats/lobby-median at round a with round b

| rounds | players | correlation |
|---:|---:|---:|
| R4 -> R6 | 3200 | 0.44 |
| R6 -> R8 | 3200 | 0.66 |
| R6 -> R10 | 3196 | 0.52 |
| R8 -> R10 | 3196 | 0.76 |
| R8 -> R12 | 2869 | 0.62 |
| R10 -> R12 | 2869 | 0.80 |
| R6 -> R12 | 2869 | 0.42 |
| R4 -> R12 | 2869 | 0.20 |

Place by stats/lobby-median at round 8 (all 3,200 alive):

| R8 stats / median | players | mean place | top 4 | 1st |
|---:|---:|---:|---:|---:|
| 0.00-0.85 | 427 | 5.63 | 35% | 3% |
| 0.85-0.95 | 642 | 5.45 | 32% | 4% |
| 0.95-1.05 | 1065 | 4.60 | 47% | 11% |
| 1.05-1.15 | 553 | 3.76 | 63% | 18% |
| 1.15-5.00 | 513 | 2.97 | 77% | 29% |


Eventual winner's board vs its lobby median, by round: R4 1.02, R6 1.07, R8 1.10, R10 1.12, R12 1.10, R14 1.09, R16 1.08
Eventual winner was the biggest board in its lobby: R4 20%, R6 26%, R8 28%, R10 35%, R12 36%, R14 46%

## Final boards: printed bodies (golden doubled) versus stats gained in play

printed = sum of printed attack+health on the final board, doubled for goldens. gained = actual final stats - printed (all buffs: tribe bonus, spells, effects, Acorns).

| place | printed med | gained med | gained share med | goldens mean | mean unit tier |
|---:|---:|---:|---:|---:|---:|
| 1 | 113.5 | 131.0 | 54% | 3.58 | 4.69 |
| 2 | 95.0 | 103.5 | 54% | 2.87 | 4.49 |
| 3 | 84.0 | 86.0 | 51% | 2.12 | 4.30 |
| 4 | 76.5 | 76.0 | 51% | 1.71 | 4.09 |
| 5 | 71.0 | 76.0 | 52% | 1.62 | 3.70 |
| 6 | 66.0 | 70.0 | 51% | 1.53 | 3.44 |
| 7 | 62.0 | 64.0 | 51% | 1.34 | 3.18 |
| 8 | 57.0 | 53.0 | 48% | 1.05 | 3.06 |

# Part E. Cards on winning boards
## 1. Cards on winning final boards (400 winners; 3200 final boards in all)

Share = boards with at least one copy. Lift = share of winner boards / share of all final boards. Final boards of 1st and 2nd are late-game boards, so high-tier cards lift by construction: compare within a tier.

| card | tier | tribe | printed | on winner boards | on all final boards | lift | golden copies on winner boards |
|---:|---:|---:|---:|---:|---:|---:|---:|
| Squire Lollop, Lord of the Manor | 6 | Hedgerow folk | 6/8 | 52% | 18% | 2.90 | 175 |
| Old Isegrim | 6 | Hunters | 6/8 | 48% | 23% | 2.09 | 148 |
| Little Nip | 1 | Hunters | 2/3 | 36% | 24% | 1.48 | 68 |
| Queen of Elfland | 6 | Fairies | 8/8 | 34% | 20% | 1.69 | 99 |
| The Standing Committee | 5 | Hedgerow folk | 5/7 | 29% | 21% | 1.40 | 86 |
| Old Mother Mast | 6 | Hedgerow folk | 6/8 | 28% | 14% | 1.99 | 77 |
| Grizel | 5 | Hunters | 5/6 | 27% | 18% | 1.50 | 63 |
| The Peat King | 6 | Bog folk | 5/9 | 27% | 15% | 1.82 | 80 |
| Old Lutra | 3 | Hunters | 3/4 | 24% | 13% | 1.87 | 44 |
| Whirligig Beetle | 6 | neutral | 6/8 | 20% | 11% | 1.83 | 43 |
| The Lantern Man | 6 | Bog folk | 4/8 | 13% | 8% | 1.68 | 44 |
| Madame Ermeline | 4 | Hunters | 3/6 | 11% | 17% | 0.66 | 26 |
| Wee Wobbly | 1 | Oozes | 1/4 | 11% | 22% | 0.49 | 21 |
| Granny Stir-Up | 6 | Oozes | 4/8 | 10% | 5% | 1.89 | 20 |
| The Seven Whistlers | 6 | Birds | 5/7 | 9% | 7% | 1.21 | 18 |
| The Lodger | 3 | Hunters | 4/4 | 8% | 15% | 0.53 | 12 |
| The Laird of the Sett | 6 | Hunters | 3/5 | 8% | 3% | 2.35 | 20 |
| Elder Ooze | 5 | Oozes | 3/7 | 7% | 5% | 1.35 | 12 |
| Bubble and Squeak | 3 | Oozes | 3/4 | 7% | 14% | 0.52 | 14 |
| Lady Belladonna | 5 | Fairies | 4/8 | 7% | 9% | 0.78 | 23 |
| Goodman Hayward | 5 | Hedgerow folk | 4/7 | 7% | 8% | 0.91 | 15 |
| Mother Goose | 5 | Birds | 4/7 | 6% | 8% | 0.72 | 13 |
| Figgy Duff | 4 | Oozes | 3/5 | 6% | 8% | 0.70 | 4 |
| The Prima Donna | 5 | Bog folk | 2/8 | 6% | 7% | 0.85 | 19 |
| Alderman Dozey | 3 | Hedgerow folk | 2/5 | 6% | 9% | 0.63 | 9 |
| Mag Pye | 4 | Birds | 3/6 | 5% | 13% | 0.42 | 14 |
| Mrs Stork | 4 | Birds | 3/6 | 5% | 13% | 0.39 | 12 |
| The Prince Restored | 4 | Bog folk | 6/7 | 5% | 4% | 1.32 | 7 |
| Stone Soup | 2 | Oozes | 1/3 | 5% | 7% | 0.70 | 8 |
| Tiddy Mun | 5 | Bog folk | 3/6 | 4% | 3% | 1.23 | 14 |


## 2. Highest and lowest lift within each tier (cards on 40+ final boards)

| tier | cards | mean lift | top 3 | bottom 2 |
|---:|---:|---:|---:|---:|
| 1 | 10 | 0.51 | Little Nip 1.48; Little Dollop 0.70; Young Pretender 0.62 | Bridge Toad 0.10; Mrs Dunnock 0.16 |
| 2 | 14 | 0.32 | Stone Soup 0.70; The Peat Cutter 0.51; The Toll-Bard 0.44 | Mistress Russet 0.14; Mrs Clover, Midwife 0.14 |
| 3 | 14 | 0.53 | Old Lutra 1.87; The Sixpenny Pie 1.13; Alderman Dozey 0.63 | Sergeant-at-Conkers 0.00; The Natterjack Chorus 0.10 |
| 4 | 17 | 0.48 | The Prince Restored 1.32; Mrs Mallow, Feeding Them Up 0.76; Figgy Duff 0.70 | Charcoal Burner 0.00; His Highness, Allegedly 0.07 |
| 5 | 12 | 0.93 | Grizel 1.50; The Standing Committee 1.40; Elder Ooze 1.35 | Reel-Mistress 0.47; The Great Lump 0.53 |
| 6 | 11 | 1.85 | Squire Lollop, Lord of the Manor 2.90; The Laird of the Sett 2.35; Old Isegrim 2.09 | The Gabble Ratchet 0.93; The Seven Whistlers 1.21 |


## 3. Winner boards: tier mix, goldens, tribe count

Units by tier on winner boards: T1 10%, T2 4%, T3 10%, T4 9%, T5 17%, T6 50%
Golden units per winner board: mean 3.58, median 4; boards with 0 goldens 1%.
Winners' final tribe label: Hunters 124, no_tribe 109, Hedgerow folk 71, Bog folk 43, Oozes 26, Birds 18, Fairies 9


## 4. Caps on permanent growth among slice units

Slice units with a permanent_buff_cap field: 2 of 119.
Bridge Toad (T1) 3; Alderman Dozey (T3) 12

# Part F. Older benches
## Older bench comparison: final boards by place

| bench | place | n | rounds | final stats med | per-unit med | units |
|---:|---:|---:|---:|---:|---:|---:|
| baseline-step2 (pre-pass-2 pool) | 1 | 400 | 19.4 | 213.5 | 30.8 | 6.81 |
| baseline-step2 (pre-pass-2 pool) | 2 | 400 | 19.4 | 189.0 | 27.9 | 6.75 |
| baseline-step2 (pre-pass-2 pool) | 3 | 400 | 17.5 | 168.5 | 25.1 | 6.71 |
| baseline-step2 (pre-pass-2 pool) | 4 | 400 | 15.5 | 145.5 | 21.6 | 6.70 |
| baseline-step2 (pre-pass-2 pool) | 5 | 400 | 14.0 | 135.0 | 20.0 | 6.72 |
| baseline-step2 (pre-pass-2 pool) | 6 | 400 | 13.4 | 127.0 | 19.2 | 6.65 |
| baseline-step2 (pre-pass-2 pool) | 7 | 400 | 12.7 | 118.0 | 17.8 | 6.60 |
| baseline-step2 (pre-pass-2 pool) | 8 | 400 | 11.8 | 107.5 | 16.1 | 6.74 |
| pass 2 follow-up | 1 | 400 | 19.6 | 242.0 | 35.9 | 6.63 |
| pass 2 follow-up | 2 | 400 | 19.6 | 199.0 | 32.6 | 6.11 |
| pass 2 follow-up | 3 | 400 | 17.5 | 169.5 | 27.1 | 6.25 |
| pass 2 follow-up | 4 | 400 | 15.4 | 153.0 | 23.1 | 6.59 |
| pass 2 follow-up | 5 | 400 | 13.6 | 147.0 | 21.1 | 6.87 |
| pass 2 follow-up | 6 | 400 | 12.9 | 138.0 | 19.8 | 6.95 |
| pass 2 follow-up | 7 | 400 | 12.1 | 126.5 | 18.1 | 6.97 |
| pass 2 follow-up | 8 | 400 | 11.2 | 112.0 | 16.0 | 7.00 |

baseline-step2: lobbies 400; first elimination median 12.0; game length median 19.0.
damage-v05 arm B: lobbies 200; first elimination median 12.0; game length median 19.0; ghost won 8.2%.
baseline-step2 provenance: GameConfig.full_game(): arm B default, feedback5 merged
