# Playtest pt5-a: build 7 (b2c3f01), strategy lens

Five full games with `tools/play/play.sh` against the full-strength bot lobby. I didn't read earlier reports first.

| Game | Seed | Hero | Build | Place |
|---|---|---|---|---|
| 1 | 101 | Pipkin | Hunters (Wick, Brock, Toll-Bard, Glutton) | 8 (out R9) |
| 2 | 202 | Mousewife | Bog folk (Gideon, Toad, His Highness) | 6 (R10) |
| 3 | 303 | Hob Mumblecrust | Birds (Jay, Tern, Redbreast, Lump) | 8 (R8) |
| 4 | 404 | Pipkin | Fairies, Rainbow (two Chasers) | 4 (R14) |
| 5 | 505 | Wren | Oozes, Belly (Frumenty+Wasp, golden Posset) | 6 (R11) |

**Verdict: okay.** Not "very good": I wouldn't hand it to a keen player without an apology for the early snowball.

**What's best:** the brick wall with across-slot effects. Scout gives real choices: Changeling, Whirligig, Mire, Nightshade, Hasty Pudding. Belly copies count towards golden. Rainbow repainting, where you sell a unit and replay into its slot, is a neat puzzle.

## Top 5 problems
1. **Rainbow Chaser dominates the early game.** Two T1 Chasers reached 8/9 by round 5 for 6 gold, and I started 6–0. Bot Hoolet's Chaser was 10/11 in round 5 in game 2. It was the only build where I won early fights. *Alone this stops "very good".*
2. **Early losses snowball.** Every loss cost 4–7 from round 1, so three of five games were decided by round 8 with no way back. Last Stand bought one round in game 4, then I took 18. The end is a slow bleed, not a climax. *Alone this stops "very good".*
3. **Mirers attack into enemies and die before their mired target swings.** In game 2, R6, my Toad (1/3) attacked Wick, died, and freed the 8/10 Annis it had mired. Bog folk felt the weakest tribe, with Hunters close behind.
4. **Ring piles are still too strong late.** Bots had single-slot Rings of +6, +8 and +9, making units like Wobbly 19/23 and Posset 17/17 that decided fights.
5. **Text gaps** (see W).

**Builds that felt really different:** all five did. Rainbow and Belly felt the most distinct, Hunters the least: its Pack and quarry chains are hard to steer.

## Lens answers
- **Real decisions most turns?** Yes: tier or buy, placement against Scout, and whether to cash out Chaser. Hero choice matters too: Pipkin's 2-buy limit hurt me, and Hob's borrowing cost 4 HP over 4 turns.
- **Anything dominate?** Rainbow early, Ring stacks late.
- **Satisfying end?** No (problem 2).
- **Small-Bird flights too strong?** No. Mrs Jay's flight gave an Acorn, Redbreast gained +2/+2 from two Nests, and Lump on Tern's Nest was 2/6. That's useful but not dominant. I didn't see Ring piles from my side, only from bots.

**(P)** Game 4, R8: I moved Changeling to F4 across their Honorary Treasurer 9/10. It stole the Treasurer and won the fight. Game 2, R6: placing the Toad in front lost the fight (problem 3).

**(B)** I repainted Rainbow bands by replaying into a vacated slot. I fed a Belly to finish a golden. I moved units each turn to answer Scout. Bot boards in the log mostly keep their order from round to round. I can't see bot code, so this is an inference.

**(W)**
- Queen of Elfland: "Your other Fairies split their stats" is unclear, and its "Teind 1/3" counter is never explained.
- Frumenty doesn't show the text it borrowed.
- The fight log says "parasite", "bogs" and "borrowed attack", which no card uses.
- Young Brock: it took a fight to learn that the units beside it get Brock's across enemy as quarry.
- "X attacks in a Pack with Y" reads backwards when Y is the one with Pack.
