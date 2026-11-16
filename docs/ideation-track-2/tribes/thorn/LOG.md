# Briars and thorns: design log

Three rounds, 16 Nov 2026. Each round a reader who had not seen the plans read only the unit list and tried to find them. The tribe is in [README.md](README.md) and [units.json](units.json).

## The Compost choices, and why

These were the friend's open questions. All settled by the designer, none decided.

| Choice | Settled as | Why |
|---|---|---|
| One heap or one per slot | One heap for each player | A pile on a slot that gives stats is a slot buff, and the pigeons own slot buffs. One heap is one number on screen, and other tribes can plug into it without learning seven. |
| A count or a list | A list of units, shown as a count | A count alone makes every sold unit worth exactly 1. A list lets a few cards bring the best unit back, which is what makes other tribes' units real fuel. Most cards still read only the number. |
| Spent or counted | Both, on different cards | It is what splits the tribe into plans: bank it (Grow, Thorns), spend the bottom (Root), use the top (copies), or be paid on the way in (Bury). |
| What goes in | Bought units you sell, shop units you Bury, Seeds, and what a card says | Tokens and other free units stay out, the same line as their sell value of 0. Otherwise every token-maker in the game is a free heap engine. Spells stay out to keep it one kind of thing. |
| A limit | None on the heap | A cap feels bad and hides the number. The limits are on the cards: Root once a fight, one Bury a turn, Grow counts every 2. |
| Fights | Fights change the real heap | The friend's point: the board is copied into each fight, so a heap that was copied too would refill itself. Seeds add for good and Roots spend for good. |

## Round 1: first draft

**Tried.** Five plans, each a different thing to do with the heap: Overgrowth (count it), Thorn wall (count it for damage), Coppice (spend it to come back), Mulch (be paid for burying), Regrowth (summon the best unit out of it, used up each time). Grow gave +1/+1 for each unit in the heap.

**The reader found** all five plans and the splash pieces without being told. Problems:
- Overgrowth ran far ahead: the heap only grows and Grow stacked from three sources.
- Mulch looked like Overgrowth with two cards swapped, and its Tier 6 card was weak.
- Regrowth used up its best units faster than two Buries a turn could replace them, so its board fell apart in a few turns.
- Hedge Layer's gold would be bought by every player.
- Bramble Runner and Crab-apple were under-statted.

**Changed.**
- Regrowth now copies the best unit and leaves it in the heap. Each entry comes out once a fight. This also removed every way a unit could bring itself back without end.
- Old Mother Midden became a real capstone: its own Bury buff, and every Bury effect happens twice.
- The Mulch board lost its Grow units, so it stands on its own cards.
- Briar King reaches the front row only.
- Enemy tokens killed by thorns stopped feeding the heap.

## Round 2

**The reader found** all five again. Problems:
- Overgrowth still dwarfed the rest late (about 800 stats against 250 to 300 at turn 13).
- Coppice had no growth before Tier 5, and returned units came back plain, so its second life was weak.
- Regrowth's turn-9 board claimed Tier 5 units it could not have yet.
- Thorns were all or nothing.
- Golden text was missing.

**Changed.**
- Grow now counts every 2 units. Sprawl is Grow 2, Ivy gives Grow 1, the King gives Grow 2.
- Crab-apple makes one Pip, not two, to slow the heap.
- Root brings a unit back as it stands on the shop board, permanent stats included. This is a change from the rulebook's plain return (9.8.2) and is the biggest single change of the three rounds: it made Coppice a plan before Tier 5 and gave permanent buffs a reason to sit on Root units.
- Blackthorn Sapling gains +2/+2 for good each time it returns ("cut back, grow thicker", from the first options page).
- Elder Mother's copies wait for a slot on a full board, so the empty slots are a choice.
- Holly Knight went back to every 3 units. The two readers disagreed (one wanted every 2); every 3 with room for a second Holly Knight was kept.

## Round 3

**The reader found** all five again, checked every number on the boards and found no errors. Rough stats at turn 9: Overgrowth 263, Thorn wall 250 plus thorn damage, Coppice 255 plus second lives, Mulch 310 plus returns, Regrowth 250. At turn 13 without Tier 6: 390, 410, 470, 580, 350.

**Still wrong, and fixed:** boards that used units not marked for that plan; whether Pips and copies are Briars (Pips yes, copies only if their card is); Ivy Climber and Elder Mother oversold as splash pieces; Elder Mother's text shortened; Thorns against mice written honestly after reading the mouse tribe (Pile on lands without attacking, so thorns kill only the mouse that attacks).

**Still wrong, and left for the owner's balance pass, with a dial each (in the README tier check):**
- Mulch leads by up to half at turn 13.
- Hazel Coppicer gives more on a locust Molt board than at home.
- Hedge Layer's gold is good for every tribe.

## Dropped, and why

- **A pile on each slot** (the friend's first version). It is the pigeons' slot buffs under another name, and seven piles is seven numbers.
- **A death swarm plan** (Seed units dying to buff the survivors). It is the locusts' plan. Seed stayed as a feeder on two units.
- **Thorns and Root as one plan.** They want opposite things from the heap: thorns count it, Root spends it.
- **Buffs for every unit sold.** Buying and selling a Tier 1 unit costs 1 gold, so it turned into a clicking contest. Bury triggers took its place, because a Bury unit buries once a turn.
- **Summoning that uses the unit up.** See round 1.
- **Root that returns a plain copy.** See round 2.

## Not sure of

- **Six keywords** (Bury, Seed, Root, Grow, Thorns, Guard) and the heap is a lot for one tribe. Four are the friend's parts, so none was cut. No card carries more than two.
- **Regrowth is the smallest plan:** two key units and three that stock the heap. It depends on what the other tribes' Tier 5 and 6 units do as plain copies, which nobody has tested.
- **Overgrowth and the Thorn wall share one big heap.** A player can blend them. They compete for back-row slots, not for the heap.
- **The Thorn wall is a counter more than a plan.** It is very good against locust Hoppers, poor against a lone badger, and only partly works against mice.
- **Nothing was simulated.** Every number here is arithmetic on a turn-9 board.
- **Hedge Layer** works in the shop phase. The owner's 15 Nov idea of locking shop-phase economy units to the board would apply to it and to every Bury unit; it is not in the rulebook, so it is not applied.

## 17 Nov 2026: made one game with the other four tribes

Not a design round. One pass over all five tribes wrote [../SHARED-RULES.md](../SHARED-RULES.md), the glossary and the rulings where tribes meet, and brought this tribe's files into line with it. No stats, tiers or costs changed.

- **Crab-apple's text:** "summon a Pip" (was "a 3/3 Pip with Seed"), with the reminder *Pip: A 3/3 Briar with Seed.* Why: the Mice and Locusts name their token and put its stats in the reminder.
- **Thorns reminder:** "Whenever this is attacked" (was "When"), to match Fury and Gate Warden. **Grow reminder:** capital after the colon. **Old Stump and Elder Mother reminder:** "your Compost" (was "the heap").
- **Elder Mother's copies and the Badgers.** The notes and README said the copies count as units and end a Badger's being outnumbered. The Badgers' count is fixed when the fight starts, so they don't: a board that leaves slots empty for copies is counted as short all fight.
- **Elder Mother's copies wait in the same line as Locust Hoppers** and land by the same rule (shared ruling 6). Before: "the first slot that opens, after that slot's own death summons and returns".
- **Thorns against a "takes no damage" attack:** the Badgers' Hedge Lancer and Tourney Champion take none on their opening strike (shared ruling 26). This weakens the Thorn wall a little against the Badgers' Charge. Plate is gone from the Badgers, so the line about it is gone.
- **Root beside the Locusts' Molt:** a unit with both uses Root first when the Compost can pay, and Molt on a later death.
- **Seed set off without a death** (a War-drummer, being eaten) still adds its entry and Sweetbriar sees it; a drummed Crab-apple's Pip or a drummed Old Stump's copy with no empty slot is lost, and the Stump marks no entry used.
- **Holly Knight** is a Briar, not a Knight, for Badger cards: they read the type line, not the name.
- **units.json fields.** Same fields as the other four tribes: `tribe` and `type` on every unit, a `golden` field, `splash_for` on every unit (empty unless it is a splash piece), tribe rule blocks under `rules`, and `note` renamed `implementer` and rewritten to say how the card works under the shared rules.
