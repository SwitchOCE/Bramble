---
id: tolerance-floor
group: plays
size: small
headline: Allow one stat either way on low-tier cards' budgets?
source: design/tribes-and-budget:docs/design/power-budget.md#5
option: Keep the one-stat leeway
option: Percentages only
suggested: Keep the one-stat leeway
---
You set how far a card may stray from its budget: 15% either way for plain cards, 25% for growing and economy cards. At low tiers that leaves almost no room. A plain tier 1 unit has 5 Attack and Health in total, and 15% of 5 is less than one stat, so the only legal plain tier 1 body would be exactly 5 stats.

So the budget keeps a small floor: a card may always be one stat over or under, if that's more than the percentage. A tier 1 unit can then be anything from 4 to 6 stats.

**What we need from you:** keep that one-stat leeway?

**Why it matters:** it decides whether low-tier cards can have a little variety in their bodies, like a 2/2 or a 3/3 at tier 1, rather than every one adding up to exactly 5.

We'd suggest keeping it. Without it, plain low-tier cards would all be the same size.

## Detail

- **Power-budget 2.3:** "Floor: ±1 SP, whichever is larger [judgement, kept from v0]. At Tiers 1–2 one stat is 14–20% of V(t), so a pure percentage would leave no legal body (question 5)."
- **V(t):** 5 / 7 / 8 / 10 / 12 / 14 SP at Tiers 1–6. At Tier 1, ±15% is ±0.75 SP, so only 5 is legal; with the floor, 4–6. At Tier 2, ±15% is ±1.05, so the floor changes little there.
- **Your bands:** "±15% default, ±25% engines", both directions (2 Nov).
- **Growing and economy cards** (±25%) get ±1.25 SP at Tier 1, so the floor matters mainly for plain cards.
- **The 2/2 and 3/3 examples** are our arithmetic. The suggestion is ours.

**The original question (power-budget §9, question 5):**
> "Tolerance floor: keep "±1 SP, whichever is larger" for low tiers, where one stat is 14–20% of V(t)?"

Source: `design/tribes-and-budget:docs/design/power-budget.md` sections 2.1, 2.3 and 9.
