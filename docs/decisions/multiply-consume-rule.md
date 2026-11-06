---
id: multiply-consume-rule
group: plays
size: big
headline: Limit "double stats" and "eat a unit" cards to once a turn?
source: design/tribes-and-budget:docs/design/power-budget.md#9.9
option: Yes, once a turn and never repeated
option: Allow repeats, but cap them some other way
option: No rule; review each card
suggested: Yes, once a turn and never repeated
---
Most growing cards add a fixed amount, like +1/+1 a turn. Two kinds don't. A card that doubles a unit's stats gains more the bigger the unit already is. A card that eats another unit and takes its stats gains a whole unit's worth each time. Let either fire more than once in a turn, or put it next to a card that makes effects happen again, and the numbers snowball within a single turn: 10, 20, 40, 80. No price holds against that.

So the budget proposes a simple content rule: these effects happen at most once per turn, and nothing can make them happen again. That stops the snowball from repeats and retriggers. It doesn't stop growth over turns: a "double this each turn" card still compounds from one turn to the next, and the per-tier growth limits don't cover it, so in our reading such cards would still need a careful look one by one.

This matters for the Oozes, whom you liked for eating each other, combining and splitting.

**What we need from you:** should that be the rule? Or would you rather allow repeats and limit them another way, or have no rule and judge each card?

**Why it matters:** it decides how wild "double" and "eat" cards can get, and so how far the Ooze kind of play can be pushed.

We'd suggest the rule. It leaves the effects in the game and stops the within-turn snowball, the one pattern pricing can't handle. Ooze designs can still eat other units, just once a turn.

## Detail

- **Power-budget 3.2:** "Stat multiply (E06) and consume (E08) grow geometrically under retriggers (E80, E81) and over turns. v1 prices them only when the text is once per turn and can't be retriggered [judgement]. That is a proposed content rule for the owner (question 9)."
- **Across turns:** v1 prices each use at the target's current stats (E06) or about V(shop tier) (E08). Doubling across turns still compounds, and the growth caps assume a fixed s per turn ("Linear growth only", power-budget 3.2), so they don't cover it. The rule stops retrigger and repeat snowballs, not growth over turns.
- **Taxonomy prices:** E06 stat multiply: the target's current stats, at least V(t) at Tiers 5–6. E08 stat transfer or consume: about V(shop tier) per use; per turn it is scaling at about V(t) a turn, over every growth cap below Tier 4. E80 multipliers and E81 "trigger another unit's effect" never double or trigger E06 or E08.
- **Status:** "a proposed rule, not saved anywhere."
- **How this fits your rules:** budgets are guidelines and designers don't see them (2 Nov). This would be a content rule that reviewers check designs against.
- **Oozes:** "they work around buffing the shop and amalgamating things into them, and eating each other, and combining and splitting … I like that as an idea" (2 Nov read-through).
- **The 10, 20, 40, 80 sequence** is ours, for illustration. The suggestion is ours.

**The original question (power-budget §9, question 9):**
> "Content rule for stat multiply and consume: "once per turn, can't be retriggered"? Without it they grow geometrically and no price holds. This is a proposed rule, not saved anywhere."

Sources: `design/tribes-and-budget:docs/design/power-budget.md` sections 3.2, 3.4 and 9; owner notes `2026-11-02f-new-effects-and-goldfish-designers.md` and `2026-11-02h-checkpoint-read-through.md`.
