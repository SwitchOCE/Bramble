---
id: growth-caps
group: plays
size: big
headline: A speed limit on how fast cards can grow at each tier
source: design/tribes-and-budget:docs/design/review-queue.md#B4
option: Yes, use these limits
option: Yes, but looser
option: No limits, price each card
suggested: Yes, use these limits
---
Cards that grow every turn are priced by giving them a smaller body. But past a certain speed, that stops working: the card grows so fast that even as a 1/1 it ends up ahead of a normal card. No price can fix it.

So we worked out a rough speed limit for each tier. For example, a card that gains +1/+1 every turn, no strings attached, is too strong below tier 4. A card that gains +1 Health every turn fits from tier 2.

A card over the limit isn't thrown out. It can grow only when something is true ("if you have a Fairy"), stop after a while ("up to 5 times"), or move up a tier.

**What we need from you:** should we use these limits? As with the rest of the budget, designers wouldn't see them; they'd only be used to flag a finished design that breaks one.

**Why it matters:** it decides how fast unconditional growing cards can be at each tier, which is where Battlegrounds' power creep came from.

We'd suggest using them. Without a limit, the fastest growing cards can't be priced at all, and a card over the limit can still keep its idea with a condition, a stopping point or a higher tier.

## Detail

**The proposal (budget draft v1, B4).** Stat points gained per turn, at most:

| Tier | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Grows by itself each turn | 0.8 | 1.3 | 1.7 | 2.5 | 3.8 |
| Grows when it fires in combat (once per fight) | 1.0 | 1.7 | 2.2 | 3.6 | 6.2 |

Tier 6 uses the Tier-5 limit until measured. "+1/+1" is 2 stat points; "+1 Health" is 1.

- **Why:** above these rates even a 1/1 body breaks even with a plain unit by turn 12, so no body price can fix the card (scaling_rate_caps.csv, standard economy).
- **Examples:** unconditional "+1/+1 every turn" fits from Tier 4. "+1 Health every turn" is just over at Tier 1 (1 against 0.8) and fits from Tier 2. These follow from the table.
- **Scope:** applies to self-scaling and "this game" amplifiers, counted at full use. Stat multiply and consume effects are priced once per turn only.
- **Risk:** the limits are set by turn 12. Read by turn 10 they are higher at Tiers 4–5; the ±25% band covers that gap at Tiers 1–4, not at Tier 5.
- **How this fits your rules:** budgets are guidelines (2 Nov), designers are briefed without them, and reviewers flag only against the tier curve and tolerance bands, not unapproved caps (2 Nov). Approving these limits would add them to what reviewers flag against.
- **"Where Battlegrounds' power creep came from"** is from your direction summary: under-priced scaling drove the power creep.

**The original question (review queue, B4):**
> "Growth cap per tier? Suggested about 0.8 / 1.3 / 1.7 / 2.5 / 3.8 stat points a turn at Tiers 1–5."

Sources: `design/tribes-and-budget`: `docs/design/review-queue.md`, `docs/design/power-budget-review.md` section 4.3, `docs/design/power-budget.md` sections 3.2 and 10 (B4), `docs/design/direction-summary.md`, owner notes `2026-11-02f` and `2026-11-02g`.
