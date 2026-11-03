---
id: economy-target
group: plays
size: big
headline: How fast should a gold-focused player reach the top shop tier?
source: design/tribes-and-budget:docs/design/review-queue.md#B2
option: Turn 8 at the earliest
option: Turn 7 is fine for big economy games
option: Slower: turn 9 at the earliest
suggested: Turn 8 at the earliest
---
Some cards give you extra gold. Extra gold mostly buys one thing early on: upgrading your shop sooner, to tier 6, where the strongest units are. So to price gold cards, we need to know how much extra gold a player is meant to get, and how early that should let them reach the top.

In our model, a player who picks up a little extra gold now and then (about one every other turn) reaches tier 6 on turn 9. A player who goes all in on gold reaches it on turn 8. A lucky, all-in economy game that hits big gold cards early reaches it on turn 7.

We suggested pricing cards for the "little extra" player, and letting a committed gold player reach tier 6 on turn 8 at the earliest. Turn 7 shouldn't be possible from gold cards alone.

**What we need from you:** does that feel right? Or do you want big economy games to be able to race to the top even faster, or not quite so fast?

**Why it matters:** it caps how much gold cards can hand out, and sets how quickly the strongest units turn up in a game.

## Detail

**The four economy levels in the model** (extra gold on top of normal income; Bramble rules):

| Level | Extra gold | Tier 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| No econ | none | 2 | 4 | 6 | 8 | 10 |
| Standard | +1 every other turn | 2 | 4 | 6 | 8 | 9 |
| Econ-heavy | +1 from turn 3, +2 from turn 5 | 2 | 4 | 5 | 7 | 8 |
| High-roll | +2, +3, +4 | 2 | 3 | 5 | 6 | 7 |

(Turn on which each tier is reached.)

- **The proposal (budget draft v1, B2):** price against standard. Treat econ-heavy (tier 6 on turn 8) as the ceiling a committed economy build should reach with legal cards. Treat high-roll (tier 6 on turn 7) as out of reach for income units alone.
- **Tested:** boards holding income units at the proposed gold caps (see the card on gold every turn) reach tier 6 on turn 8 or 9. The old caps reached it on turn 7. The run counts the extra gold only, not the bodies the income units cost, so real boards are slower.
- **Economy moves the tier clock, not the crossover:** for a given growing card, the turn it catches up doesn't change with economy level. More economy makes growing cards' leads 15–25% smaller, because the plain alternative improves faster.
- **Risk:** the reference level moves economy results more than any price does. If playtests show most players at econ-heavy, the gold table should be re-run there.
- **Your earlier direction (2 Nov):** you want really powerful economy effects, without unbounded economy. This card is about how fast economy builds ramp, not whether they exist.

**The original question (review queue, B2):**
> "Design-target economy level: no econ, standard, econ-heavy or high-roll?"

Sources: `design/tribes-and-budget`: `docs/design/review-queue.md`, `docs/design/power-budget-review.md` section 1.3, `docs/design/power-budget.md` section 10 (B2), owner note `2026-11-02-pre-development-design-pass.md`.
