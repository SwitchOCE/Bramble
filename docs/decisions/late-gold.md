---
id: late-gold
group: plays
size: big
headline: Give gold something worth buying late in the game
source: design/tribes-and-budget:docs/design/review-queue.md#B6
option: Spells at flat prices, plus a few gold-spending cards
option: Accept that gold is an early-game thing
option: Something else
suggested: Spells at flat prices, plus a few gold-spending cards
---
Late in a game, once you're at the top shop tier with a full board, extra gold has very little left to buy. Refreshing the shop gets dearer the more you do it in a turn, so in our model late gold buys almost nothing. That quietly makes every gold card an early-game card, however it's priced.

The rules already put a spell in every shop, as Battlegrounds does: one-shot cards you buy with gold, like "give a unit +2/+2". We suggested keeping spell prices flat, so unlike refreshes they never get dearer within a turn. That makes them the natural place for late gold to go. In the model it roughly triples what a late gold is worth. On top of that, there could be a few cards that turn gold into power, like units that grow as you spend gold, or that have an ability you pay to use.

**What we need from you:** do you want late gold to have a use like this? Or are you happy for gold to matter mostly early, and economy cards to be an early-game choice?

**Why it matters:** it decides whether economy builds stay strong right to the end of a game, and it feeds straight into how much gold cards are worth.

## Detail

- **The finding (first review, B6):** with escalating refreshes and no cap, gold after tier 6 is nearly worthless in the model. "Without a late sink (spells, triples, upgrades), economy cards are early-game cards whatever they cost."
- **The proposal (budget draft v1, B6):** Tavern spells at flat prices that never escalate, a spell in every shop (rulebook 6.1.1 already has one), plus spend-counter engines and Activate abilities as optional sinks.
- **Numbers:** with refreshes only, late gold buys 0.5–0.67 stat points per gold; with spells, 1.7–2.0 (bound_packages.csv). "Roughly triples" is our rounding of that. Battlegrounds' Season 14 answer was also sinks: 23 of 273 current minions have Activate abilities.
- **Needs:** rulebook delta 4.2.5 (spell prices fixed for the turn) and guardrail G12, both proposed in economy-bounding §7.
- **Refresh prices:** the first review used the earlier schedule (1, 2, then 3 gold after 10 and 20 refreshes). Your 2 Nov schedule (15 at 1 gold, then +1 every 5, no cap) came later. The budget draft's rules list still names the earlier schedule, and we couldn't confirm which schedule the late-gold figures used.
- **The spell example** ("give a unit +2/+2") is ours, for illustration.

**The original question (review queue, B6):**
> "What should late-game gold buy? In the model, gold is worth almost nothing late."

Sources: `design/tribes-and-budget`: `docs/design/review-queue.md`, `docs/design/power-budget-review.md` section 6, `docs/design/power-budget.md` sections 4.5, 4.6 and 10 (B6), owner note `2026-11-02d-refresh-schedule-and-free-refreshes.md`, `docs/design/rulebook-deltas.md` (4.4.3).
