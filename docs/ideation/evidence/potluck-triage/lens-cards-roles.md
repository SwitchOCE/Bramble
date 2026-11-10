# Pot Luck triage: cards and roles lens

Data: docs/ideation/evidence/wave2b/oozes-final.jsonl (32 lobbies, preset B). Paper: docs/ideation/content/pass3/oozes-pass3-model.py, run at r = 1/8 (preset B Soup share).
Scripts (this folder): presence.py, split.py, engine_sets.py, paper_p.py, paper_ablate.py. persist.py was written but did not run (the temp volume ran out of quota).

## 1. Which Pot Luck pieces are on the board (pre_start `cards`, % of surviving seats)

| card | R6 | R8 | R10 | R12 | R14 | seats that ever had it | first round |
|---|---|---|---|---|---|---|---|
| Stone Soup (T2) | 22 | 38 | 39 | 39 | 25 | 12/32 | 5.5 |
| Dishwater Nell (T2) | 16 | 16 | 16 | 22 | 50 | 6/32 | 5 |
| Moss Ooze (T2) | 6 | 12 | 13 | 13 | 17 | 5/32 | 7 |
| Bubble and Squeak (T3) | 16 | 22 | 26 | 22 | 17 | 11/32 | 7 |
| Sixpenny Pie (T3) | 6 | 16 | 16 | 22 | 42 | 7/32 | 8 |
| Mr Syllabub (T4) | 0 | 16 | 19 | 13 | 8 | 10/32 | 8.5 |
| Elder Ooze (T5) | 0 | 6 | 23 | 39 | 50 | 20/32 | 11.5 |
| Hasty Pudding (T5) | 0 | 6 | 16 | 17 | 17 | 8/32 | 10 |
| Granny Stir-Up (T6) | 0 | 3 | 16 | 30 | 67 | 13/32 | 12 |
| Cut-and-Come-Again (T6) | 0 | 0 | 6 | 30 | 50 | 14/32 | 12 |
| Wee Wobbly (T1) | 62 | 66 | 65 | 65 | 58 | | |
| Mrs Posset (T1) | 50 | 56 | 58 | 57 | 25 | | |
| Little Dollop (T1) | 50 | 44 | 35 | 30 | 25 | | |
| Frumenty (T4) | 0 | 25 | 35 | 43 | 33 | | |

n = 32 / 32 / 31 / 23 / 12. Mean Oozes on board 2.8 / 4.1 / 5.0 / 5.4 / 5.7.

Joint engine (Soup, Nell and a Digest pot: Bubble, Dollop or Frumenty) on board: 3% at R6-R12 (1 seat), 17% at R14. Seats with none of Soup, Nell or Elder: 66% R6, 50% R8, 45% R10, 26% R12.
The engine line is similar on the T2 pieces (Soup ever 12/32, Nell 13/32), but has Elder 45% at R10 and Granny 54% at R12.

## 2. What makes Pot Luck grow (paper ablation, line P, r = 1/8, board only, no Bellies)

| variant | R8 | R12 | R14 | x/round R8-14 |
|---|---|---|---|---|
| full P (as written) | 134 | 983 | 2,239 | 1.598 |
| no Elder | 134 | 560 | 1,237 | 1.448 |
| no Soup | 96 | 372 | 671 | 1.381 |
| no Nell | 131 | 511 | 994 | 1.402 |
| no Soup, no Nell | 99 | 248 | 542 | 1.327 |
| Elder at R12 instead of R9 | 134 | 563 | 1,837 | 1.546 |
| Soup R8, Nell + Bubble R9 | 108 | 664 | 1,673 | 1.578 |
| bot-like: Soup R8, Nell R12, no Bubble, Elder R11 | 108 | 399 | 1,089 | 1.469 |
| no Slice / no Figgy | 134 | 983 / 975 | 2,239 / 2,231 | 1.598 / 1.594 |

Realised: R8 88, R12 200, R14 337, x1.251. Paper reserves (the Belly gold sink) are 96 stats at R12 and never grow.

## 3. Card presence vs size (Pot Luck, median active stats)

| R12 | with | without |
|---|---|---|
| Stone Soup | 251 (n9) | 189.5 (n14) |
| Elder | 249 (n9) | 183.5 (n14) |
| Bubble | 272 (n5) | 192 (n18) |
| Moss | 144 (n3) | 239.5 (n20) |
| Sixpenny Pie | 147 (n5) | 239.5 (n18) |
| Granny | 197 (n7) | 239.5 (n16) |

R14: Soup 883 (n3) vs 310 (n9); Nell 456.5 (n6) vs 330 (n6); Pie 201 (n5) vs 385 (n7). Small n: read for direction.

## 4. Role check (B dials)

| card | role in Pot Luck | window | permanent growth? | finding |
|---|---|---|---|---|
| Stone Soup T2 2/3, shop +1/8 of biggest Ooze | engine | R3-6 | yes, at buy time | carries the line; on board in 39% at R12 |
| Dishwater Nell T2 2/3, free meal to adjacent biggest Ooze | engine | R5-6 | yes | carries the line; 6/32 seats ever |
| Moss T2 2/4, released units gain Shield | fight hold | R7+ | no | 5/32 seats; boards with it are smaller |
| Bubble and Squeak T3 3/4, Belly 1, Digest, split | the pot | R5-8 | yes, 1 meal/turn | 11/32 seats; Frumenty/Dollop stand in |
| Sixpenny Pie T3 2/5, Belly 2, gold per unit out on death | gold + spare lives | R5-8 | no (gold next turn, at most 2) | trap on a growth bar; 7/32 seats |
| Wee Wobbly T1 1/4, Belly 1, releases after surviving a hit | early wall | R1-5, sold late | no | still on 65% of R12 boards |
| Mrs Posset T1 2/1, Belly 1, killer loses half | answer | R2-5, late sometimes | no | 57% of R12 boards |
| Mr Syllabub T4 3/6, released units' Start of Combat fires | fight combo | R12+ with Hasty/Granny inside | no | |
| Elder T5 4/8, other Oozes gain half each non-Ooze meal of the biggest | payoff | R9-11 | yes | first seen median R11.5; needs the pot to be the biggest Ooze |
| Hasty T5 3/9 | answer + gain | R10+ | small | |
| Granny T6 4/8, Cleave, gathers touching Oozes' Attack | fight payoff | R12+ | no | fight only; invisible on a pre-combat bar |
| Cut-and-Come-Again T6 | free Slice | R12+ | yes if eaten | Pot Luck's policy plays the Slice as a body, never eats it |

Competition at T1-T2 (other tribes, same tier): Little Nip 2/2 and Wick 2/2 (permanent two thirds / one third of a kill), Sable 2/3 and Mistress Russet 3/3, Hob-in-the-Hearth 2/5, Old Moth Annis 2/4, Mrs Clover 2/4. Pot Luck's T1 holders (Wobbly 1/4, Posset 2/1) do no growth after R5, against Hunters' T1s that keep growing.

## 5. Verdicts

- Pot Luck has no payoff of its own that turns reserves into permanent stats. Its permanent growth is the engine line's engine (Soup, Nell, a pot, Elder) without Aspic, the second stomach or eaten Slices. The Belly cards (Pie, Wobbly, Posset), Moss, Syllabub and Granny add only fight value or a little gold. Kept, major.
- The growth depends on two T2 cards and one T5 card with no backup. Paper without Soup and Nell is x1.327 and 248 at R12, close to the realised x1.251 and 200. In play, the full trio is on board in 1/32 seats through R12. Kept, major.
- Payoffs come late: Elder first seen median R11.5 (on 6% of boards at R8, 23% at R10), Granny and Cut-and-Come-Again at R12. Paper puts Elder at R9; moving it to R12 halves R12 (983 to 563). Kept, major.
- The Sixpenny Pie is a trap for this measure and probably for the line: no growth, at most 2 gold, and boards holding it are smaller (R12 147 vs 239.5, R14 201 vs 385; small n). Kept, minor.
- Wee Wobbly and Mrs Posset as late reserve holders: on 65% and 57% of R12 boards, against a design role that ends around R5. Each takes a slot from a growing body. Open, because it could be the policy ("Fill front Bellies (Pie, Wobbly, Posset)") rather than the cards.
- Moss and Granny fail the bar but not their role: their value is in the fight, which a pre-combat stats bar cannot see. Open as a measurement point.
