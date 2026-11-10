# Lens: bot and line policy (Pot Luck, line_oozes_tempo)

Source data: `docs/ideation/evidence/wave2b/oozes-final.jsonl` (32 lobbies), `oozes-before-pot-fix.jsonl`.
Code read: `tools/sim/lines/oozes.json`, `tools/sim/line_brain.gd`, `tools/sim/committed_line_brain.gd`,
`tools/sim/line_policies.gd`, `src/core/bots/bot_ooze.gd`, `bot_brain.gd`, `bot_held.gd`, `bot_eval.gd`, `bot_placer.gd`,
`content/bots/strategies/oozes_second_helpings.json`. Snapshot `cards` lists active units in slot order without
empty slots, so slot readings use 7-body boards only.

## What runs and what is prose

| Pot Luck rule | Where it runs | Status |
|---|---|---|
| priority list | `LinePolicies.strategy` weight 14*(16-i)/16, then `CommittedLineBrain.configure_line` ADDS the base strategy's unit weights | runs, but not in the written order (below) |
| climb 3/5/7/9/11 | `LineBrain._target_round`; leftover climb disabled | runs; same as engine line |
| never save | `_held_back` returns the shared reserve only | runs |
| engine_pieces (Soup, Nell, Elder, Moss) | `CommittedLineBrain._protected` | runs |
| `placement` (all five lines) | advisory key, not read; a shared adapter `BotOoze.arrange` (selected by strategy id) does: pot -> B2, Nell -> B3, Soup -> B1, Granny -> F2, compact zigzag | adapter matches the text |
| pot = "Bubble and Squeak" | `BotOoze.carry` = biggest Digest Ooze (Dollop, Bubble or Frumenty) | broader than text, fine |
| one non-Ooze meal a turn | `BotOoze.feed` + `meal_gain` in the shop loop; Belly 1 caps one per stomach | runs; frequency not logged |
| front Bellies, biggest last | `BotOoze.best_belly`: front holder with fewest inside; `depth_first` buys straight into Bellies | runs, no size ordering |
| Hasty on a 35% scout | `wants_hasty` raises its value and keeps it empty | runs; "swap for Pie or Moss" is not a swap, and Moss is protected so it can't be swapped out |
| Slice never to the pot | `best_belly`/`hand_belly` return -1 for tempo | runs |
| (not in Pot Luck text) keep a split gap | `BotOoze.max_bodies` caps at 6 bodies when the carry is Bubble and no Granny, for both lines | runs against the text |

## Placement as executed (7-body Pot Luck boards, R8+, 128 boards)

| check | result |
|---|---|
| digest pot at B2 | 107 / 107 |
| Nell adjacent to the B2 pot | 27 / 27 |
| Granny at F2 | 51 / 55 |
| Soup at B1 | 45 / 47 |
| Granny boards with all 7 slots filled (R12-15) | 23 / 29 |

## Effective buy order (line weight + base strategy weight)

| card | written rank | effective weight | effective rank |
|---|---|---|---|
| stone_soup | 1 | 14.0 | 5 |
| moss_ooze | 2 | 19.1 | 3 |
| elder_ooze | 3 | 26.3 | 1 |
| granny_stir_up | 4 | 25.4 | 2 |
| dishwater_nell | 5 | 10.5 | 8 (below Wee Wobbly 12.0, Pie 13.8) |
| bubble_and_squeak | 6 | 16.6 | 4 |
| little_dollop | 13 | 6.5 | 12 |
| aunt_aspic | 16 | 6.9 | 11 |

The engine line is distorted the same way (Cut-and-Come-Again 7th -> 1st, Figgy 8th -> 2nd).

## Route pieces on Pot Luck boards (share of survivors)

| card | R6 | R8 | R10 | R12 | R14 | engine R8 / R12 |
|---|---|---|---|---|---|---|
| any digest pot | 59% | 72% | 81% | 83% | 67% | 88% / 96% |
| Bubble and Squeak | 16% | 22% | 26% | 22% | 17% | 28% / 31% |
| Stone Soup | 22% | 38% | 39% | 39% | 25% | 31% / 23% |
| Dishwater Nell | 16% | 16% | 16% | 22% | 50% | 38% / 42% |
| Moss Ooze | 6% | 12% | 13% | 13% | 17% | 28% / 31% |
| Sixpenny Pie | 6% | 16% | 16% | 22% | 42% | 12% / 0% |
| Elder Ooze | 0% | 6% | 23% | 39% | 50% | 6% / 62% |
| Granny | 0% | 3% | 16% | 30% | 67% | 0% / 54% |
| Hasty | 0% | 6% | 16% | 17% | 17% | 9% / 31% |
| Wee Wobbly | 62% | 66% | 65% | 65% | 58% | 47% / 0% |
| Mrs Posset | 50% | 56% | 58% | 57% | 25% | 34% / 8% |

- Soup+Nell by R8: 2/32 Pot Luck, 4/32 engine. Granny by R12: 8/32; ever: 13/32. No seat of either line had Soup, Nell, Bubble, Moss, Elder and Granny on time.
- Ooze offers seen per round alive: 1.21 Pot Luck, 1.23 engine, 1.15-1.76 Hard bots; total offers per round 7.35 vs 6.8-10.1 for Hard. Pot Luck does not roll less than the field.
- Tier-1 Belly holders (Wobbly, Posset) per board: R10 1.45 / R12 1.30 / R14 0.83 Pot Luck; 0.48 / 0.08 / 0.00 engine. Paper R12 board has none.
- R12 active by holders: 0 -> 375 (n1), 1 -> 240 (n15), 2+ -> 178 (n7).
- R12 active by pot at R8: with 240 (n17), without 183.5 (n6); R14 368 (n7) vs 201 (n5).
- Six-body cap: Pot Luck seat-rounds with Bubble and no Granny had 7 bodies 4/50 times; without Bubble 112/196.
- Tier proxy (highest-tier card on board) at R11, tier >= 5 / 6: Pot Luck 17/27, 10/27; engine 26/29, 17/29. Tier itself is not logged.
- Before vs after the two bot fixes, Pot Luck: R12 200 -> 200, R14 341.5 -> 337, growth x1.254 -> x1.251; pot at R8 66% -> 72%.
- Growth including Bellies is the same as active: Pot Luck x1.252 (99 / 248 / 381), engine x1.348.

## Scripts

All in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/potluck-triage2/`,
run with `python3 -I <script>`: `policy_audit.py` (per-round tables, card presence, slots, six-body cap),
`offers_audit.py` (offers per round, effective weights), `route_audit.py` (route assembly, placement, holders),
`extra_audit.py` (growth with Bellies, tier proxy, before/after), `pot_split.py` (pot and holder splits).
