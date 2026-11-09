# Power budget and costing: tables behind the reader's findings (9 Nov 2026)

Read-only. Scripts in `scratchpad/fundamentals/scripts/`. Lobby data: `/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/free_choice_plain.{rounds,players,cards}.csv`. The hidden `.0.` files named in the brief no longer exist; the run finished (400 seeds, 400 complete 8-seat lobbies, 3,200 seats, 48,773 round rows; `free-choice.log`). Rows with missing fields dropped (none were).

## A. Lobby: board size by round (all seats, `lobby.py`)

| Round | Median board SP | p90 | Max | Median SP per unit | Median tier | What the method assumes |
|---|---|---|---|---|---|---|
| 3 | 19 | 24 | 32 | 5.3 | 2 | T2 opens turn 2, mean unit 5 |
| 6 | 52 | 63 | 89 | 7.6 | 3 | T4 opens turn 6, mean unit 7.2 |
| 9 | 92 | 113 | 163 | 13.5 | 4 | T6 opens turn 9, mean unit 10.4 |
| 12 | 133 | 163 | 226 | 19.7 | 5 | model board 118 at turn 12 (B3) |
| 14 | 155 | 194 | 256 | 23.4 | 5 | |
| 16 | 174 | 225 | 318 | 26.8 | 6 | |
| 18 | 200 | 262 | 396 | 31.0 | 6 | |
| 20 | 220 | 289 | 422 | 34.4 | 6 | |

Final boards by place: 1st median 242 SP (p90 312, max 486) on 7 units; 8th 112. Winners last 19.5 rounds; median elimination 14-16.

## B. Tier clock: assumed vs measured (`tierreach.py`)

| | T2 | T3 | T4 | T5 | T6 |
|---|---|---|---|---|---|
| Method, standard econ (power-budget.md:119) | 2 | 4 | 6 | 8 | 9 |
| Bots, all seats, median first round | 3 | 6 | 9 | 12 | 14 (49% ever reach) |
| Bots, winners | 3 | 6 | 9 | 12 | 14 |

## C. Printed body vs the board it joins (round the tier opens, measured)

| Tier | V(t) | Round it opens | Median unit on board then | V(t) / board unit | Method's "mean unit at that turn" (power-budget.md:120) |
|---|---|---|---|---|---|
| 3 | 8 | 6 | 7.6 | 1.05 | 6.3 |
| 4 | 10 | 9 | 13.5 | 0.74 | 7.2 |
| 5 | 12 | 12 | 19.7 | 0.61 | 9.4 |
| 6 | 14 | 14 | 23.4 | 0.60 | 10.4 |

Mean Attack per unit (`atk.py`): R9 5.9, R12 8.7, R14 10.7 against A(t) 4.0 / 4.9 / 6.1 (power-budget.md:114). Attack share 0.36-0.46, against the 45-50% default.

## D. Final boards: printed vs delivered (`printed.py`)

Printed = sum of card A+H on the final board, doubled for goldens.

| Place | Printed SP | Final SP | Delivered by text | Final / printed | Goldens on board |
|---|---|---|---|---|---|
| 1 | 113.5 | 242 | 131 | 2.19 | 3.58 |
| 4 | 76.5 | 153 | 76 | 2.04 | 1.71 |
| 8 | 57 | 112 | 53 | 1.92 | 1.05 |

Winners' lead over 8th: printed +56.5 (goldens and higher tiers), text +78. Text delivers about 131 SP over 19.5 rounds, about 7 SP a round for the whole board.

## E. Board growth per gold (`sink.py`)

Round-to-round board SP gain, all seats; gold spent includes tier-ups.

| Round | 4 | 6 | 8 | 10 | 12 | 14 | 16 | 18 | 20 |
|---|---|---|---|---|---|---|---|---|---|
| Mean SP gain | 11.3 | 9.7 | 15.7 | 14.9 | 11.1 | 8.4 | 9.6 | 10.3 | 9.3 |
| Gold spent | 7.3 | 9.7 | 13.2 | 12.8 | 11.3 | 11.9 | 11.6 | 11.2 | 11.1 |
| SP per gold | 1.54 | 1.00 | 1.18 | 1.16 | 0.98 | 0.71 | 0.83 | 0.92 | 0.83 |

Growth is flat at about 10-15 SP a round all game: no acceleration. The method's late sink is 2.0 SP a gold (power-budget.md:358-360), valid 1.8-2.5. Shipped pass 2 stat spells: Pinch of Dust 2/gold, Elderflower 3, Spore Cloud 2, Boundary Stone 3, Bread/Stand Behind Me about 2-4 on two units, Harvest Supper about 3.3 now, Last Orders 1, Beltane Bonfire about 2 (4 units). Median about 2, several at 1.

## F. Concentration in Bramble's combat (toy vanilla sim, `conc_sim*.py`)

Rulebook 9.2, 9.4.2, 9.4.5 (no summons), 9.5.1, 9.5.5, 9.6. Text-free units. 3,000-4,000 paired fights a cell, common random numbers. Random boards: unit size uniform 0.6-1.4 × mean, Attack share 0.35-0.65, hitters in front.

1. **Owner's example** (3 × 10/11 against 5 × 10/10): the 3-unit side wins 100% of fights, with 3 in front or 2 in front and 1 behind. Confirmed under our rules.
2. **Same total on fewer units** (squeeze 7 units' SP onto 5) against 7 even: +0.28 / +0.20 / +0.23 / +0.25 win rate at mean unit 6 / 10 / 20 / 60 SP. Onto 6 units: −0.16 / +0.12 / +0.11 / +0.12.
3. **Same total, one carry** (others shrink): carry share 0.20 (even is 0.14): F1 +0.11, B1 +0.02 to +0.03. Share 0.30: F1 −0.09 to −0.11, B1 −0.20. Share 0.50: F1 −0.18, B1 −0.27. A single carry holding 30%+ of a board loses to an even board of equal total.
4. **Adding SP on top** (+20% of the board): spread over 7 units +0.41, all on the biggest unit +0.35, on F1 +0.34 (mean unit 10). Ratio one-unit/spread 0.85-0.86 at every scale. A Dozey-size +8/+8 on F1 at mean unit 9: +0.40 against +0.44 spread.
5. **Scale invariance**: win rate per added SP × board SP = 1.98 / 2.04 / 2.04 / 2.10 at boards of 42 / 70 / 140 / 420. Matches the review's K = 1.9-2.1 (power-budget-review.md:139). Vanilla fights don't care about the absolute number; only ratios matter.

Reading: in vanilla fights concentration pays in unit count (fewer, bigger bodies), not as one carry among small units. The owner's "always" needs his own exception: it holds with no scam units and is strongest with units that keep their stats (cleave, damage reduction, shields, self-scaling). A +X buff is worth about the same spread or concentrated (the method's 0.9 for one chosen target, power-budget.md:296, matches 0.85-0.86). What the method misses is the second-order part: text that scales with a unit's own stats, flat answers that fall off against big units, and the slot limit.

## G. Payoff per turn: Battlegrounds tier 4-6 against Bramble pass 2

Assumptions, Battlegrounds: standard clock T4/T5/T6 on turns 6/8/10; a committed board of 5 tribe units; about 12 gold spent, 3 plays, 2 Battlecries and 2 Tavern spells a turn (the method's own R07 count, power-budget.md:311), plus 1 Spellcraft per Spellcraft unit. Bramble: costing-3 and pass2-costing firing rates. "Permanent" = kept between fights. All [estimate].

| Battlegrounds card (patch 37.0.0) | T | Body | Permanent SP a turn | Concentrated? |
|---|---|---|---|---|
| Gunpowder Courier: per 5 gold, Pirates +3/+1 | 4 | 2/5 | 2.4 × 4 × 5 = **48** | spread |
| Flaming Enforcer: EOT consume top-Health shop unit | 4 | 4/5 | **12** (25 with shop buffs) | one unit |
| Parasitic Fleshling: EOT left-most +2/+2, improves | 4 | 4/6 | **4-12** | one unit |
| Kalecgos: per Battlecry, Dragons +2/+2 | 5 | 4/12 | 2 × 4 × 5 = **40** (80 with Brann) | spread |
| Insatiable Ur'zul: per Demon played, consume a shop unit | 5 | 4/6 | 2 × 11 = **22** | one unit |
| Mysterious K'Thir: EOT discard spells, +7/+7 each | 5 | 7/7 | 2 × 14 = **28** | one unit |
| Felfire Conjurer: EOT spells give +1/+1 more this game | 5 | 6/5 | 4k on turn k; **12** mean over 5 turns, rising | spread, kept after sale |
| Utility Drone: EOT +4/+5 per Magnetization | 6 | 4/5 | about 6 × 9 = **54** | spread |
| Forsaken Weaver: per spell, Undead +3 Attack this game | 6 | 3/8 | 2 × 3 × 6 = **36** | spread, future units too |
| Torrential Ruiner: per spell on a Naga, minions +2/+3 | 6 | 6/3 | 4 × 5 × 7 = **140** | spread |
| *(reference)* Tyrael: Activate (1) set a minion to 50/50 | 6 | 10/10 | about 70-90 per gold | one unit |

Median **32 SP a turn**, range 4-140. Median printed body 11. Each delivers about 3× its own body every turn.

| Bramble card (pass 2) | T | Body | Permanent SP a turn | Combat-only SP a fight | Concentrated? |
|---|---|---|---|---|---|
| Mrs Mallow: EOT smallest unit +1/+1 | 4 | 3/5 | **2** | 0 | anti-concentration |
| The Cuckoo: EOT away Birds beside +2/+2 | 4 | 3/6 | **4-8** (on Birds not fighting) | 0 | spread |
| Charcoal Burner: burn up to 6 gold, behind +1/+1 per 2 | 4 | 4/6 | **9** for 6 gold (1.5 SP a gold) | 0 | 1-2 units |
| Beadle Warrenby: after an Acorn, Pass +1/+1, once a turn | 4 | 2/4 | **about 1.5-2** | 0 | one unit |
| Goodman Hayward: after a Stash, touching Hedgerow +1/+1 | 5 | 4/7 | 0.35 × 5 × 2 = **3.5** | 0 | spread |
| Tiddy Mun: twice a fight, attacked unit +1/+1 | 5 | 3/6 | **4** | 0 | spread |
| Grizel: pack kill, attackers +1 Attack | 5 | 5/6 | **2.4** | 0 | spread |
| Mother Goose: homecoming, Birds +1/+1 | 5 | 4/7 | 10 a trip ÷ 3 = **3.3** | Nests strike 2 | spread |
| Squire Lollop: SoC touching +1/+1 (+2/+2 at 7) | 6 | 6/8 | **0** | 14-28 | spread |
| The Laird of the Sett: Takes, Hunters +1/+1 this fight | 6 | 3/5 | **0** | up to about 26 | spread |

Median **about 3 SP a turn** permanent (0-9). Median printed body 10. Each delivers about 0.3× its body a turn. Battlegrounds' median is about **10×** ours per card per turn.

What the method would say about Battlegrounds' cards: Kalecgos at 40 SP a turn costs c(5) 2.6 × 40 = 104 SP against V(5) = 12 (+770%), and is 10× over the Tier 5 growth cap of 3.8 (power-budget.md:125, 743). Every Battlegrounds card in the table except Fleshling is over its cap by 3-35×.

## H. The method's verdicts on pass 2 point one way

pass2-costing.md:7-17, ten cut items. Seven are permanent growth over the per-tier caps (Lollop "+24 SP a turn … six times the cap", Mallow, Beadle, Stone Soup, Elder Ooze, Ranocchio, Stork's loop) and one is recurring gold over its cap (Pie). Each fix is "once a turn/fight", a smaller number, or moving the effect to combat-only. Pass 1 did the same: Standing Committee +408% "quadratic" to +1 Attack; Queen of Elfland +350% "geometric" to conservation; Tiddy Mun "20 SP of permanent growth a fight" to twice a fight; Mast "compounding" to one Acorn (costing-1.md:27-28, 49; costing-3.md:77). The method never flags a payoff as too small for the late game; it has no test for that.

## I. Rough pricing check of a concentration case (Alderman Dozey, pass 2 text)

2/5, double at 3 turns in slot (up to +8/+8), Acorn feeding +1/+1 per 2 gold, permanent cap +12/+12 (rulebook.md:768). Fed to the cap and doubled: about 2+12+8 / 5+12+8 = 22/25 at most, typically 10-18 Attack on round 7-10 boards where the median unit is 9-16 SP. Costing-1 priced the double as E06 "≥ 7" and called it +75% (costing-1.md:22). In the lobby, final boards holding Dozey place 4.90 against 4.46 for other boards that reached Tier 3 (`cards_impact.py`; confounded by when it's bought, so read it as no sign of dominance in bot play).
