# Benchmark boards (plan step 2c)

8 Nov 2026, a fresh cloud agent, on `ideation/main` 74e7bc0. Guesses for triage ("just guesstimate"), not engine results. All 72 boards, with slots, buffs and assumptions, are in `benchmark-boards.json`. Next: fight them round-robin in `tools/sim/`.

## Method

- **Pool.** The full game shops only `set: "slice"` cards (`GameConfig.full_game`, `UnitLibrary._in_set`), so the old-library vanilla units (Fieldfare, Carrion Crow, Buzzard, Old Crane, Marsh Frog…) are left out though they say `pool: true`. **Note:** `triage-audit.md` §3 and §5 count them. In the slice pool Birds have 16 cards (4/4/2/3/1/2) and Hedgerow folk 11 (3/1/3/2/1/1).
- **Economy** (`game_config.gd`, `recruit_rules.gd`): income 3…10, capped at R8, so 12/33/62/92 gold by R3/6/9/12. Units cost 3, sell for 1. Tier up 5/7/8/11/13, 1 cheaper each turn.
- **Curves.** Average: tiers 2/3/4/5/6 on R2/5/7/10/12. High: R4/6/8/10 for tiers 3–6, plus a golden or two; at R3 it's the tier-1 tempo line with four on-plan buys. Low: tiers a turn or two late, core pieces missing, neutrals filling.
- **Spells:** Cordial or Pinch early; Harvest Supper (+1/+1 a cast from tier 3, cap +3/+3) and Stand Behind Me; Spore Cloud and Boundary Stone for Fairies. Low rolls get no Supper until R12.
- **Stats** are recruit-phase, after permanent buffs, Rings and tribe bonus; Start of Combat effects are keywords. Belly contents are under `belly` and count in `stat_total`. Heroes ignored.
- **Placement:** front row takes hits and attacks first, so scalers sit back unless they Mire or Pack; mirers face the biggest enemies; carriers trade in front.
- **Rank:** 1 strongest to 6 weakest among the six boards of the same round and roll, by judgement on stat totals plus mechanics.

## Strength guesses

Rank, with stat total in brackets.

### Round 3

| Tribe | Average | High roll | Low roll | Tier (avg/high/low) |
|---|---|---|---|---|
| Hedgerow folk | 3 (13) | 4 (18) | 6 (9) | 2/1/2 |
| Fairies | 1 (13) | 1 (24) | 3 (10) | 2/1/2 |
| Birds | 6 (10) | 6 (14) | 1 (12) | 2/1/2 |
| Hunters | 2 (12) | 5 (15) | 2 (10) | 2/1/2 |
| Oozes | 4 (14) | 2 (21) | 5 (9) | 2/1/2 |
| Bog folk | 5 (12) | 3 (18) | 4 (9) | 2/1/2 |

### Round 6

| Tribe | Average | High roll | Low roll | Tier (avg/high/low) |
|---|---|---|---|---|
| Hedgerow folk | 5 (37) | 3 (58) | 3 (29) | 3/4/3 |
| Fairies | 1 (62) | 1 (79) | 1 (43) | 3/4/3 |
| Birds | 6 (32) | 6 (42) | 6 (22) | 3/4/3 |
| Hunters | 3 (48) | 4 (55) | 4 (27) | 3/4/3 |
| Oozes | 2 (65) | 2 (92) | 2 (32) | 3/4/3 |
| Bog folk | 4 (40) | 5 (46) | 5 (24) | 3/4/3 |

### Round 9

| Tribe | Average | High roll | Low roll | Tier (avg/high/low) |
|---|---|---|---|---|
| Hedgerow folk | 3 (79) | 4 (106) | 3 (52) | 4/5/4 |
| Fairies | 1 (86) | 1 (123) | 2 (50) | 4/5/4 |
| Birds | 6 (67) | 6 (75) | 6 (45) | 4/5/4 |
| Hunters | 2 (79) | 2 (110) | 1 (57) | 4/5/4 |
| Oozes | 4 (97) | 3 (140) | 4 (52) | 4/5/4 |
| Bog folk | 5 (69) | 5 (86) | 5 (48) | 4/5/4 |

### Round 12

| Tribe | Average | High roll | Low roll | Tier (avg/high/low) |
|---|---|---|---|---|
| Hedgerow folk | 2 (145) | 2 (187) | 5 (94) | 6/6/5 |
| Fairies | 1 (151) | 1 (188) | 4 (89) | 6/6/5 |
| Birds | 6 (97) | 6 (98) | 6 (81) | 6/6/5 |
| Hunters | 3 (132) | 3 (160) | 1 (113) | 6/6/5 |
| Oozes | 4 (155) | 4 (167) | 2 (117) | 6/6/5 |
| Bog folk | 5 (110) | 5 (125) | 3 (99) | 6/6/5 |

**Weakest:** Birds in 11 of 12 cells. The exception, the R3 low roll, is a neutral Pill Bug beside Mrs Jay, which is the owner's point: early Birds lose to the rest of the shop. Hedgerow folk are weakest there. Bog folk are fifth at R3 average and at R9 and R12 (average and high).

## Where each tribe is behind

**Birds, every stage; the high roll barely helps.** R3's line flies a Bird before owning a payoff: a 1/1 Egg, and Redbreast, Redwing and Lump are 1/2s and 1/3s without Nests. At R6 three Nests still give 1–4 Attack bodies. At R12 the high roll (98) is level with the average (97): the T6s are 3/7 and 3/3, and Goose's strike and Whistlers' −1/−1 are the only reach. Needs bigger payoff bodies, an early reason for Nests and a second T5 (plan step 3).

**Bog folk, R3 average and from R9.** The Mire engine is clearest at R6, but its bodies have 1–3 Attack and win by Bitter and chip damage. From R9 a Mire wall in front of a 14/17 Chaser just dies. One T6; Prima Donna is the only reason to reach T5. The low roll holds up mainly through Charcoal Burner.

**Hedgerow folk, R6 average and the low rolls.** Dozey doubles only after three turns in its slot: on R4 (high) the board ranks 3, on R5 (average) 5. One T5 and one T6, so missing either drops it to 5 at R12. Thinnest supply, 11 cards (tally 14).

**Hunters, the R3 high roll only.** Tier-1 tempo is 2-Attack bodies that lose to Wobblies and Nans. From R6 Pack and Pounce make it the steadiest tribe; its low roll ranks 1 at R9 and R12 because it doesn't hang on one carrier. Laird's value is in-fight Takes, which I can't price by hand.

**Oozes, the least certain.** Top stat total in 7 of 12 cells, but I rank them 2–5 because Belly bodies have 1–9 Attack and come out one at a time. If the engine values them more, the audit's "slow middle" is wrong. The T6s are 7–8-stat bodies, so R12 leans on what's inside and on Hasty Pudding.

**Fairies, only the late low roll.** Chaser on R1 gives rank 1 at R3; a golden Chaser is the biggest unit at R6 (18/20) and R9 (25/28). Without it, Rings on Old Moth Annis still rank 1–2 through R9. Rank 1 in 9 of 12 cells: the audit's "over-supplied", tally items 3 and 6.

## Caveats

Ranks lean on my stat assumptions, especially Ring and Pass totals; a one-place gap means little. Bellies, Takes, Mire and Bitter are the weakest guesses and the first things the engine should settle. Charcoal Burner carries several low rolls (Hedgerow, Hunters, Oozes, Bog): tally 11, neutral scaling standing in for tribe power.
