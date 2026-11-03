---
id: recurring-gold
group: plays
size: big
headline: Re-price cards that give you gold every turn
source: design/tribes-and-budget:docs/design/review-queue.md#B5
option: Re-price, with the per-tier limits
option: Re-price, without limits
option: Keep it strict on purpose
suggested: Re-price, with the per-tier limits
---
Some cards give you gold every turn ("start of turn: gain 1 gold"); others give it once ("when you play this, gain 1 gold"). Our first pricing rule charges the every-turn kind far too much, somewhere between one and a half and ten times what it's worth in our model. Under that rule, every such card would end up as a 1/1 at tier 3 or higher, which in practice means they'd barely exist. One-off gold, on the other hand, is priced about right.

The reason is that gold is worth most early, when it buys you shop upgrades, and very little late, and the old rule assumed the opposite.

We suggested pricing gold from a table per tier instead, with a few limits on gold that comes with no strings attached: none every turn at tiers 1 and 2, up to 1 a turn at tiers 3 and 4, up to 2 a turn from tier 5. One-off gold would be up to 2 at a time at tiers 1 and 2, and 1 from tier 3.

**What we need from you:** re-price as suggested? Or keep gold cards strict on purpose, to hold economy decks down?

**Why it matters:** it decides whether "gold every turn" cards are a real part of the game, and at which tiers. You've said you want strong economy effects and that every tribe should have some.

## Detail

- **The finding (first review, B5):** the v0 rule (50% of gold value over H turns) is 1.5–10× too strict for "+1 gold each turn" and puts every such card at Tier 3+ on a 1/1. One-off gold is about right or slightly cheap; it pays back by turn 6–9.
- **The proposal (budget draft v1, B5):** price gold on units from the per-tier table (power-budget 2.2 and 4.1), read at a late sink of 2.0 stat points per gold. No unconditional recurring gold at Tiers 1–2, +1 a turn at Tiers 3–4, +2 from Tier 5. One-off gold at most 2 per trigger at Tiers 1–2 and 1 from Tier 3.
- **Why these limits:** at Tier 1, recurring gold beats a plain unit from a sink of about 1.9; at Tier 2 a 1/1 is 21% over at 2.0. Battlegrounds prints no recurring gold on Tier 1–2 minions now, and its 2–4-gold-a-turn minions each stayed in the pool only 4–18 months.
- **Condition:** valid while late gold buys 1.8–2.5 stat points per gold, which ties it to what late gold buys (the next card) and to spell prices.
- **"No strings attached"** is our plain word for "unconditional". Gold tied to a condition is priced by how often the condition holds.
- **Your direction:** "we do want to have really powerful economy effects, because those things are fun … without having it lead to unbounded economic effects" (2 Nov); every tribe should have some economy (2 Nov read-through); and economy archetypes "tend to just be the best at high-level play", so you liked tying economy to specific actions (2 Nov read-through).

**The original question (review queue, B5):**
> "Re-price recurring economy? The current rule over-charges recurring gold by about 1.5–10×."

Sources: `design/tribes-and-budget`: `docs/design/review-queue.md`, `docs/design/power-budget-review.md` sections 1.4 and 4.5, `docs/design/power-budget.md` sections 4.1 and 10 (B5), owner notes `2026-11-02-pre-development-design-pass.md` and `2026-11-02h-checkpoint-read-through.md`.
