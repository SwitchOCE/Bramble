# Pot Luck triage: competition and system lens

Data: `docs/ideation/evidence/wave2b/oozes-final.jsonl` (32 lobbies, preset B) in /home/alex/code/Bramble-ideation-balance (ideation/wave2b). No fight records (pairings, winners, damage, end reason) are committed, so fight outcomes are approximated by elimination within 3 rounds and final placement. Scripts: a_share.py, b_survival.py, c_cards.py, d_contention.py, e_pool.py, f_growth.py, g_slots.py in this folder (run with `python3 -I`).

## Headline
Pot Luck almost never assembles its route. At R12, 0 of 23 Pot Luck boards hold Soup + Nell + Bubble together (the paper R12 board has Soup, Nell, Bubble, Moss, Elder, Granny and Pie). Each specific Ooze is offered about once per game (Pot Luck sees 1.17 Ooze offers per round alive). Its board is no more spread than the winners' boards; the copies the other Ooze seats hold don't matter; and the B to C dial change is worth about +0.02 per round.

## (a) Concentration: ruled out
Median largest_share (active stats, before Start of Combat):

| Round | Pot Luck | Engine | Lobby winners | Hard bots |
|---|---|---|---|---|
| R8 | 0.353 | 0.406 | 0.369 | 0.333 |
| R10 | 0.390 | 0.381 | 0.357 | 0.335 |
| R12 | 0.415 | 0.439 | 0.358 | 0.347 |
| R14 | 0.417 | 0.454 | 0.369 | 0.356 |

Death within 3 rounds (R8-13 pooled), by board total including Bellies / lobby median:

| Band | Pot Luck | Engine | Hard |
|---|---|---|---|
| <0.7 | 0.69 (n42) | 0.44 (n34) | 0.57 (n144) |
| 0.7-0.9 | 0.50 (n38) | 0.24 (n42) | 0.49 (n192) |
| 0.9-1.1 | 0.28 (n57) | 0.28 (n58) | 0.28 (n294) |
| 1.1-1.4 | 0.05 (n22) | 0.12 (n26) | 0.10 (n241) |

Logit (n=1397): died3 ~ -2.93·log(rel stats) - 0.96·largest_share + 0.14·PotLuck - 0.42·engine. Going from a share of 0.30 to 0.45 is worth about the same as 5% more stats. At equal size, Pot Luck dies at the hard bots' rate. It loses because it is small: only 26 of 163 Pot Luck observations are above 1.1x the lobby median. Placement: Pot Luck 4.94 mean, top-4 rate 38%, against 4.12 / 62% for the engine and 3.98 / 55% for hard bots.

## (b) Dial B vs C: kept, but minor
- Soup's share is 1/8 at B, already above the paper's default of 1/10. The paper Pot Luck line was modelled at 1/10.
- Observed one-round growth on Pot Luck boards, R8 to R14 transitions, including Bellies:
  - all boards: x1.248 (n143);
  - with Soup: x1.287 (n54);
  - without Soup: x1.225 (n89);
  - Soup + Elder: x1.376 (n12);
  - Elder without Soup: x1.317 (n18);
  - none of Soup, Nell or Elder: x1.211 (n57).
- Modelled per-turn permanent gain from Soup, Nell, Digest and Elder on each actual Pot Luck board (pot = active × largest_share, base meal 8, 2 support buys a turn), as a share of the board:
  - R12: median 0.132 at B, 0.176 at C;
  - R13: median 0.128 at B, 0.172 at C.
- On the paper R12 board (pot 290, total 924, every piece present), the same model gives x1.41 a turn at B and x1.68 at C.
- Scaling the observed increments: C scales Soup's part by 4/3 on the 38% of transitions with Soup, and Elder's part by 1.5 on the 21% with Elder. That adds about +0.02, to roughly x1.27, which is still short of x1.3. The dial matters a lot only once the pieces are on the board.

## (c) System rules
- **Belly exclusion: ruled out.** Bellies hold 12-18% of Pot Luck's stats. Counting them, growth is x1.252 (99 to 381), the same as the active-only x1.251.
- **Survivorship: ruled out.** For seats alive at R14 (n12), per-seat growth is x1.230; the engine's is x1.332 (n21).
- **Board size 7: kept, minor.** From R10 the median Pot Luck board is full (7 units). 36-40% of its slots hold Oozes that only matter in fights (Moss, Granny, Posset, Wobbly, Syllabub, Pie, Figgy); the engine's figure is 19-23%. Wobbly is on 65% of Pot Luck boards at R12 and Posset on 57%, both T1 units. The growth measure can't see what these give.
- **Granny's gather: kept as a measurement fact.** It works only in the fight, so it adds nothing to pre-Start-of-Combat stats. Granny is on 30% of Pot Luck boards at R12 and 67% at R14.
- **"Reserves aren't starting survivors": open for placement, irrelevant to growth.** `replay_starting_belly_survivors` defaults to false (game_config.gd:41), and the wave2b driver doesn't set it.
- **200-attack cap: open, unlikely to matter.** It is `attack_limit` (game_config.gd:80). Without fight records the end reasons can't be counted. A board of about 10 bodies, with Moss on 13-17% of boards, is far from 200 attacks, and the cap can't change the pre-start stats anyway.

## (d) Competition for copies: ruled out
Peak share of a card's pool copies held on all boards in one lobby (R6-14):

| Card | Median | Max |
|---|---|---|
| Soup | 0.07 | 0.27 |
| Nell | 0.07 | 0.20 |
| Moss | 0.07 | 0.20 |
| Bubble | 0.08 | 0.23 |
| Elder | 0.22 | 0.56 |
| Granny | 0.14 | 0.43 |
| Cut-and-Come | 0.21 | 0.57 |

- Same lobby, by R10: does the engine seat or the Pot Luck seat hold each card? The table doesn't show the engine taking cards away from Pot Luck.

  | Card | Both | Engine only | Pot Luck only | Neither |
  |---|---|---|---|---|
  | Soup | 4 | 7 | 8 | 13 |
  | Nell | 3 | 9 | 2 | 18 |
  | Elder | 4 | 10 | 4 | 14 |

- By the number of hard bots playing an Ooze build in the lobby (0/1/2/3; 28 of 192 hard seats in all), Pot Luck's R12 median is 218.5 / 200 / 182 / 239, and its Ooze offers per game are 15.5 / 17 / 13.5 / 20. There is no trend.
- **What does compete is the pool's size.** A five-tribe lobby holds about 96 units. A specific T2 unit is 2.6% of offers at tier 2 or below and 1.3% at tier 6. Pot Luck sees 6.6 unique offers per round alive, 1.17 of them Oozes, so Soup shows up about 1.2 times a game.
- Card presence on Pot Luck boards:

  | Card | R10 | R12 |
  |---|---|---|
  | Soup | 39% | 39% |
  | Nell | 16% | 22% |
  | Elder | 23% | 39% |
  | Moss | 13% | 13% |

- Soup + Nell are together on 2 of 31 boards at R10 and 2 of 23 at R12. Soup + Nell + Bubble: 0 at both.
