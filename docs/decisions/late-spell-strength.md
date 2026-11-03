---
id: late-spell-strength
group: plays
size: big
headline: How strong should spells be late in the game?
source: design/tribes-and-budget:docs/design/power-budget.md#1
option: Keep them modest (5 per gold)
option: A little stronger at tiers 5 and 6 (6 per gold)
option: As strong as Battlegrounds' late spells
suggested: Keep them modest (5 per gold)
---
Spells are the one-shot cards in the shop, like "give a unit +2/+2", bought with gold. In our pricing, a stat spell gives about 5 Attack and Health for every gold it costs, from tier 2 up. In Battlegrounds, late spells are far stronger: a big whole-board buff late in a game gives 12 to 17 per gold. Ours, a whole-board +1/+1 at tier 5 for 3 gold, is about three times weaker per gold.

That's deliberate, because spells are what late gold buys. The stronger late spells are, the more every gold is worth, and the more every gold card has to cost. At 5 per gold, gold cards can be priced as we've proposed. At 6 per gold for tiers 5 and 6, they still just about hold. At Battlegrounds strength, most cards that give gold every turn would be priced out of the game.

**What we need from you:** how strong should late spells feel? Modest, a little stronger at the top tiers, or Battlegrounds-sized?

**Why it matters:** it sets how exciting late spells are, and it moves the price of every gold card in the game with it.

We'd suggest keeping them modest for now. Compared with how big boards are, a late Bramble spell is close to a Battlegrounds one, and it keeps room for economy cards.

## Detail

- **v1 rule (power-budget 4.5):** S(t), stat-buff SP per gold of cost, is 4 at Tier 1 and 5 at Tiers 2–6. Battlegrounds: one target, unconditional, median 4 / 6 / 5.5 / 12 (conditional) at Tiers 1, 3, 4, 5; whole board 7–8 at Tier 3, 14–17.5 at Tier 5, 14 at Tier 6.
- **The link to gold prices:** the spell rate sets the late sink (what a gold buys late), and the sink sets every gold price. Gold prices hold for a sink of about 1.8–2.5. S(t) = 5 gives 2.0 on a normal turn (bound_packages.csv); 7 gives about 2.6, just past the window [scratch]; Battlegrounds-level late spells put the sink at 3.5 or more, which would push +2 gold a turn out of Tier 5 and most recurring gold out of the game. 6 at Tiers 5–6 gives about 2.3, by interpolation, not run.
- **"Close relative to the board":** a 4-gold whole-board spell at 5 SP per gold is 20 SP, about 17% of the 118-SP board the model's standard player has on turn 12. Battlegrounds' Azerite Empowerment (56 SP for 4) is about 21% of a 270-SP Battlegrounds-pace board (budget draft; the comparison is a judgement).
- **Why flat, not rising with tier (v1):** a spell's tier buys a bigger packet and new kinds of effect, not more stats per gold.
- **Related:** what late gold buys (B6, late-gold card), gold every turn (B5), board spells in late shops (question 6).
- **The "+2/+2" example** is ours. The suggestion follows v1's choice; the budget draft calls it the owner's call.

**The original question (power-budget §9, question 1):**
> "How strong should late spells be? v1 holds stat spells to 5 SP per gold from Tier 2. Late gold then buys about 2.0 SP per gold, and the gold prices hold up to about 2.5. Options: keep 5; raise Tiers 5–6 to 6 (sink about 2.3, still inside); or Battlegrounds-strength late spells (12–17 per gold on a full board, sink 3.5 or more), which would push most recurring gold out of the game. A whole-board +1/+1 at Tier 5 costs 3 gold under v1, about 3× weaker per gold than Battlegrounds' late board spells."

Source: `design/tribes-and-budget:docs/design/power-budget.md` sections 4.5 and 9.
