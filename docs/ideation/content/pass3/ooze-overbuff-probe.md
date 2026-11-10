**Numbers work.** Preset B; identical seeds 2911001–2911032; three successful Actions runs using `--wait`. E=engine, P=Pot Luck; a=today, b=t=3, c≈3×t=3 including capacity/economy.

| Arm/line | R12 active/with Bellies | Growth ×/round | R12 alive | Paid rolls/buys | Leading meal |
|---|---:|---:|---:|---:|---|
| a/E | 352/377 | 1.310 | 28/32 (87.5%) | 91/554 | Dollop |
| a/P | 265/301 | 1.314 | 31/32 (96.9%) | 159/479 | Dollop |
| b/E | 1,205.5/1,213.5 | 1.423 | 30/32 (93.8%) | 97/571 | Stork |
| b/P | 736/747 | 1.380 | 31/32 (96.9%) | 139/495 | Goose |
| c/E | 17,990/18,069 | 2.614 | 31/32 (96.9%) | 150/900 | Ermeline/Stork |
| c/P | 4,204/4,224.5 | 1.589 | 32/32 (100%) | 157/759 | Ermeline/Goose |

Medians are pre-start A+H. Growth=(median R14/median R8)^(1/6), using identical cross-arm cohorts: E26, P23. Rolls/buys total R1–R12.

Net eating credit through R12, including accepted Elder shares and deducting recycled credit:

| Arm/line | Net credit | Active/Belly/sold/dead/cap, % |
|---|---:|---|
| a/E | 7,001 | 94.1/2.8/0.8/2.3/0 |
| a/P | 4,066 | 91.5/7.5/0.9/0.1/0 |
| b/E | 37,253 | 99.5/0/0.2/0.3/0 |
| b/P | 21,493 | 99.9/0/0.1/0/0 |
| c/E | 97.686B | 30.6/0/6.8/0/62.6 |
| c/P | 140.724M | 38.1/0.3/61.6/0/0 |

Pooled across 32 starting seats. Dead=destruction/elimination; combat deaths retain recruit stats. Reserves=0. Cap=stored credit exceeding displayed body size; active attribution is an upper bound. Extreme seats dominate aggregates.

The lever is **parameter**: c clears 900 easily on both lines; b already clears it on engine. Belly exclusion barely changes baseline medians. The bot incompletely follows the costed route: only 8/28 surviving baseline engine boards have Soup, and second-stomach presence is 16/153 R8–R12 seat-rounds. Thus missing engine pieces and bot execution reduce realization, but do not prevent numerical buffs succeeding. The probe also exposed system integer overflow; guards now apply the existing maximum before vector conversion.

[Results/configs](../../evidence/ooze-probe/results.json); per-seat-round CSV: `build/ooze-probe/analysis/seat-rounds.csv`. All 3,279 seat-rounds reconcile; 50 Godot and 16 Python tests pass. Committed locally; probe never merges.
