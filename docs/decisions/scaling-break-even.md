---
id: scaling-break-even
group: plays
size: big
headline: When should a card that grows each turn pay for itself?
source: design/tribes-and-budget:docs/design/review-queue.md#B1
option: Turn 12 is right
option: Earlier than turn 12
option: Later than turn 12
suggested: Turn 12 is right
---
Some cards grow every turn: they start weak and get bigger. To price them fairly against a card that's strong straight away, we need a rough target for when the growing card should have paid back what you gave up for it. We suggested about turn 12. Buy one when its tier first shows up in the shop, and by turn 12 it has caught up with the card you could have bought instead; after that it's ahead. We picked turn 12 because we think most of the fights that decide a game land around turns 12 to 16, but that's a judgement: we have no data yet on how long games run.

Our first pricing rule assumed you'd sell a growing card after three to five fights. In practice you don't: one bought early is usually kept 10 to 15 fights, so under that rule early growing cards came out too cheap, and late ones too dear.

**What we need from you:** does turn 12 feel right? Earlier makes growing cards the obvious buy every time, and games snowball. Later makes them a trap most of the time.

**Why it matters:** this one number sets how strong every "gets bigger each turn" card is, across the whole game.

## Detail

**The proposal (budget draft v1, B1).** Break even by turn 12 against a plain unit, bought on the turn its tier opens, at standard economy. The charge is read per tier from the model:

| Tier | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| Stat points charged per stat point gained each turn | 3.9 | 3.7 | 3.5 | 3.1 | 2.6 | 2.6 |
| … per stat point gained each time it fires in combat | 3.0 | 2.8 | 2.5 | 2.1 | 1.6 | 1.6 |

- **Why not the old rule.** v0 charged growth for H fights (3–5), which is fair only if the card is sold after H fights. The model's holds run the other way: 10–15 fights for early growing units, 2–3 for late ones. A tier-2 "+1/+1 each turn" unit bought on turn 3 was about 10.7 hero damage ahead by turn 10 under the old price.
- **Why turn 12.** It is where most decisive fights fall in the model's horizon (a judgement call; no game-length data was found).
- **Risk.** It rests on a one-player model and a hero-damage proxy. The budget draft says to check the numbers in the whole-game bot first (see the card on building that bot).
- **Under the old rule, by tier:** Tiers 1–3 bought early were under-priced (kept 10–15 fights, well ahead by turn 12); Tier 4 about fair; Tiers 5–6 bought on turn 9 over-priced (still behind by turn 12).

**The original question (review queue, B1):**
> "Break-even turn. By which turn should a fairly priced scaling card break even? Suggested: turn 12, with scaling charged for the fights left in the game, not for hold time."

Sources: `design/tribes-and-budget`: `docs/design/review-queue.md`, `docs/design/power-budget-review.md` sections 1, 4 and 5, `docs/design/power-budget.md` sections 3.2 and 10 (B1).
