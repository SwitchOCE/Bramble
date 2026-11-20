# Briars and thorns (The Hedge Wardens)

Ideation track 2. Nothing here is decided. The 19 units are in [units.json](units.json); what was tried and changed is in [LOG.md](LOG.md). Keywords shared with the other four tribes, and the rulings where tribes meet, are in [../SHARED-RULES.md](../SHARED-RULES.md); where this file and that one differ, that one wins.

The owner (16 Nov): "Compost wasn't optional. That's what we're doing. Find a way of making it work".

**The tribe in one line:** a Briar player's power is in the ground, not on the units. Everything sold, buried or seeded goes on one heap, and the five plans are five things to do with it: count it, sharpen thorns with it, spend it to come back, get paid for feeding it, or bring the best units in it back to fight.

It resembles Magic's graveyard (a pile that cards count, spend and bring things back from), with a little of Battlegrounds' Undead, whose buffs also live on the player and not on the unit.

## The Compost

Other tribes and the engine build on this, so it comes first.

- **One heap for each player,** kept for the whole game. Not one per slot.
- **It is a list of units,** shown as one number. Most cards only read the number.
- **What goes in:**
  - a unit you bought, when you sell it (a golden adds one entry for each bought copy in it);
  - a shop unit you **Bury**;
  - a copy of a unit with **Seed**, each time it dies;
  - anything a card says goes in.
- **What doesn't:** units nobody paid for (tokens, Discover picks) add nothing when sold. It is the same line as their sell value of 0. Spells never go in. Another tribe's card can say otherwise ("when you sell this, it goes into your Compost").
- **Counted, spent and copied.**
  - **Counted:** Grow, Thorns and Elder Mother read the number and leave the heap alone.
  - **Spent:** Root takes from the bottom. The lowest-tier entries go first, and they are gone for good. Root is not a choice: if the heap can pay, it pays.
  - **Copied:** a card that summons from the Compost makes a plain copy of the highest-tier unit in it for that fight. The entry stays. Each entry comes out once a fight. A copy is whatever tribe its card is.
- **No limit on the heap.** The limits are on the cards: a unit Roots once a fight, each Bury unit buries once a turn, and Grow counts every 2 units.
- **Fights use the real heap.** The board is copied into a fight, but the heap is the player's, not the board's. A Seed in a fight adds to it for good, and a Root in a fight spends from it for good.
- **Every player has one.** A player who never buys a Briar still fills a heap by selling, so a Briar picked up late already has something to work with.

**On screen:** a compost heap beside the board with its number on it. A sold unit drops onto it. Tapping it opens the list, highest tier at the top (these come out to fight), lowest at the bottom (these are spent first). While a Bury is unused the heap glows, and the player drags a shop unit onto it. In a fight, Seeds fly into it, Roots pull from it, and the number ticks. Both players' numbers show.

## Keywords

| Keyword | Reminder text |
|---|---|
| **Bury:** *effect* | Once a turn, put a shop unit in your Compost, then do what follows. |
| **Seed** | When this dies, add a copy of it to your Compost. |
| **Root N** | The first time this dies each fight, spend N Compost to return it. |
| **Grow N** | Start of fight: Gain +N/+N for every 2 units in your Compost. |
| **Thorns N** | Whenever this is attacked, deal N damage to the attacker first. |
| **Guard** | Enemies must attack this first. |

Bury, Root, Seed and Grow are the friend's four parts. Thorns is from the seed page. Guard is shared by every tribe. The token is a Pip: *A 3/3 Briar with Seed.* "Returns" is the shared word for coming back after dying, so one card can care about Root and the locusts' Molt alike.

A unit that Roots comes back as it stands on your board in the shop: full Health and its permanent stats, without anything it gained in the fight. Copies from the heap are always plain.

## The five plans

Heap sizes are for turn 9. A player who feeds the heap on purpose has about 20; one who also spends has about 10; a player with no Briars has 6 to 8 from selling.

Boards are written front row F1–F4, then back row B1–B3.

### 1. Overgrowth: bank the heap, start every fight huge

- **Key units:** Blackberry Sprawl (T3, Grow 2), Ivy Climber (T4, the units in front of it have Grow 1), Briar King (T6, other front-row Briars have Grow 2, so it stands in the back row). Fed by Bramble Runner, Crab-apple and Hedge Layer.
- **Why choose it:** the biggest single units in the tribe, and the stats aren't on them. Sell a Sprawl, buy a better unit, and nothing is lost.
- **Turn-9 board (heap 20):** F: Sprawl, Sprawl, Lone Hawthorn, Crab-apple. B: Ivy Climber, Ivy Climber, Hedge Layer.
  - F2 Sprawl has Grow 4 (its own 2 and both Ivies) and starts at 44/48. F1 Sprawl has Grow 3: 34/38. Lone Hawthorn has Grow 1 and Guard: 16/32.
  - It runs no Root units: they would spend the heap it is counting. Lone Hawthorn is its Guard because it has no Root.
- **What beats it:** speed. Before turn 6 the heap is small and these are plain bodies. Nothing grows after the fight starts. Two or three units hold all the stats, so anything that removes one unit outright hurts most.

### 2. Thorn wall: whoever attacks pays first

- **Key units:** Nettle Sprout (T1), Nettle Skirmisher (T3, Thorns 4), Holly Knight (T4, front-row Briars get +1 Thorns for every 3 Compost), Lone Hawthorn (T5, Guard, Thorns 8, and what the thorns kill goes on the heap).
- **Why choose it:** it is the answer to boards of many small attackers. They die on the thorns before they land a hit, and a dead attacker's attack is over.
- **Turn-9 board (heap 18, so each Holly Knight adds 6):** F: Skirmisher (Thorns 16), Lone Hawthorn (Guard, Thorns 20), Skirmisher (Thorns 16), Blackthorn Sapling (Thorns 12). B: Holly Knight, Ivy Climber, Holly Knight.
  - Every attack into the front row costs the attacker 12 to 20 before it lands. The Ivy (Grow 1 on F2 and F3, +9/+9) gives the Guard the Health to be hit many times, and three of the four come back once. A Leafmould Carter in place of the second Holly Knight trades thorns for Health.
- **What beats it:** it is all or nothing. A few huge attackers shrug the thorns off (a lone badger). Damage that isn't an attack goes round them: the locusts' death damage, and the mice's Pile on and Hit, which land without attacking. Against mice it kills the one mouse that attacks, not the ones that pile on. The badgers' Hedge Lancer and Tourney Champion take no damage on their opening strike, thorns included.
- **Overgrowth and the Thorn wall share the bank.** They are two payoffs for one big heap and they compete for the same back-row slots: each slot is an Ivy or a Holly Knight. Which one a player leans on depends on the lobby: thorns against wide boards, Grow against tall ones.

### 3. Coppice: cut back, grow thicker

- **Key units:** Blackthorn Sapling (T2, Root 1, and +1/+1 for good each time it returns), Nettle Skirmisher (T3, Root 1), Hawthorn Warden (T4, Guard, Root 2), Hazel Coppicer (T5, every return gives the board +1/+1 for good), The Old Hedge (T6, all other Briars have Root 1).
- **Why choose it:** it is the strongest plan early. It works from turn 3 and from a heap of four or five, and the enemy has to kill its front row twice. Returned units keep their permanent stats, so everything it gains counts double.
- **Turn-9 board (heap about 10, held level):** F: Sapling (about 11/12 before Coppicer buffs), Warden, Skirmisher, Crab-apple. B: Hazel Coppicer, Hedge Layer, Old Stump.
  - Three returns a fight: the Sapling grows, and the Coppicer gives the board +3/+3 for good every turn. At turn 9 the Coppicer has only been out a turn or two; before it, the plan lives on its second lives. It spends 4 Compost a fight; the Crab-apple, the Bury and a sale put 4 back. The Stump is the last line: when the front row has fallen twice, it leaves the best unit in the heap.
- **What beats it:** an empty heap means no returns, so it needs its feeders. It never has the biggest unit on the table. Anything that kills the whole front row at once kills it twice just as fast.

### 4. Mulch: get paid for feeding the heap

- **Key units:** Hedge Layer (T2, Bury: Gain 2 gold), Sweetbriar (T2, grows for good whenever anything goes on the heap), Leafmould Carter (T4, Bury: Briars +2/+2 for good), Old Mother Midden (T6, the same again, and every Bury effect happens twice).
- **Why choose it:** it is paid when things go in and doesn't care what happens to the heap afterwards. The stats are real and permanent, on any Briar, and nothing has to survive or be counted. It is the safest plan and the richest.
- **Turn-9 board (heap 16):** F: Sweetbriar (about 32/36), Hawthorn Warden, Crab-apple, Sweetbriar (about 22/26). B: Hedge Layer, Leafmould Carter, Leafmould Carter.
  - Three Buries a turn: 2 gold, +4/+4 on every Briar, 3 Compost, and each Sweetbriar grows by 3 more. After three turns of two Carters every Briar carries +12/+12, and the Warden brings that back with it when it Roots. No unit on this board reads the heap.
- **What beats it:** it is linear and it has no trick: three slots are the engine, each Bury costs a shop offer, and it wins on stats or not at all. Thorns, a carry with a multiplier, or damage that ignores stats beat it.

### 5. Regrowth: bury the best, fight with it every turn

- **Key units:** Old Stump (T3, when it dies, a copy of the highest-tier unit in the heap takes its place), Elder Mother (T5, start of fight: a copy of the best unit in the heap arrives, bigger for each unit in it). Stocked by Hedge Layer, Leafmould Carter and Lone Hawthorn. It is the smallest plan: two key units and three that stock the heap.
- **Why choose it:** it fights with the best units in the lobby without buying them, whatever their tribe. A Tier 5 unit in the shop that doesn't fit the board is still worth burying, and it stays worth it: the heap keeps it.
- **Turn-9 board (heap 14, five units and two empty slots):** F: Old Stump, Old Stump, empty, empty. B: Elder Mother, Hedge Layer, Leafmould Carter.
  - One Bury a turn since turn 3 and two since turn 6: by turn 9 the top of the heap is one Tier 5 and three or four Tier 4s. Elder Mother puts a copy of the best unit into F3 with +14/+14. Each Stump that dies becomes a copy of the next best.
  - Elder Mother needs one empty slot to summon a copy. A golden can use both empty slots.
- **What beats it:** the copies are plain: never golden, no buffs, no start-of-fight effects. With five units it usually attacks second (units are counted before the copies arrive, rulebook 9.2.1). It is only as good as the best four units the shop has shown.

### How the plans overlap

| Unit | Overgrowth | Thorn wall | Coppice | Mulch | Regrowth |
|---|---|---|---|---|---|
| Bramble Runner (T1) | feeds early | | feeds early | feeds early | |
| Nettle Sprout (T1) | | key | | | |
| Hedge Layer (T2) | feeds | | feeds | key | stocks |
| Sweetbriar (T2) | | body | | key | |
| Blackthorn Sapling (T2) | | body | key | | |
| Blackberry Sprawl (T3) | key | | | | |
| Nettle Skirmisher (T3) | | key | key | | |
| Crab-apple (T3) | feeds | | feeds | feeds | |
| Old Stump (T3) | | | last line | | key |
| Ivy Climber (T4) | key | Health | | | |
| Hawthorn Warden (T4) | | Guard | key | body | |
| Holly Knight (T4) | | key | | | |
| Leafmould Carter (T4) | | Health | | key | stocks |
| Lone Hawthorn (T5) | Guard | key | | | stocks |
| Hazel Coppicer (T5) | | | key | | |
| Elder Mother (T5) | bank | | | | key |
| Briar King (T6) | key | | | | |
| Old Mother Midden (T6) | | | | key | stocks |
| The Old Hedge (T6) | | | key | | |

Bramble Runner is on none of the turn-9 boards: it is the turn-1 seed, and by turn 9 it has been sold onto the heap. Thirteen of the nineteen serve two plans or more. The plans treat the heap differently: Overgrowth and the Thorn wall want it big, Coppice spends the bottom of it, Regrowth only cares about the top four, and Mulch only cares that things go in. So Root units cost a banking board something, and The Old Hedge is a card a banking board doesn't want.

## Units other tribes want

| Reach | Units |
|---|---|
| **Tribe-only** (names Briars, or only works with Briar cards): 5 | Holly Knight, Leafmould Carter, Briar King, Old Mother Midden, The Old Hedge |
| **Open** (works on any board): 9 | Bramble Runner, Nettle Sprout, Sweetbriar, Blackthorn Sapling, Blackberry Sprawl, Nettle Skirmisher, Crab-apple, Ivy Climber, Hawthorn Warden |
| **Splash** (another tribe's plan buys it on purpose): 5 | see below |

- **Hedge Layer:** 2 gold a turn for any plan that is saving, and it starts that player's heap.
- **Old Stump:** any tribe with a unit worth a second copy sells or buries one, once. The copy lands in the Stump's slot, so a pigeon slot buff applies to it. The locusts' War-drummer and Dirge-singer repeat it.
- **Lone Hawthorn:** no other tribe has Thorns. A Guard that kills Hoppers and other small attackers before they hit, for any tribe in a lobby full of them. Tokens it kills don't feed the heap; bought units do.
- **Hazel Coppicer:** triggers on any return. It is the permanent growth the locusts' Molt plan lacks.
- **Elder Mother:** for a board that keeps slots empty in the shop. On a pigeon board with drilled slots left open, the slot buffs apply to the copies. On a badger board the copies arrive after the outnumbered count is taken, so the Knights still rage.

Tribe-only and splash are 5 each of 19, under the third the frame aims for; open is 9. The heap belongs to the player, not the tribe, so most Briars work for anyone who has sold units, but only modestly on a small heap (an Ivy Climber on a heap of 8 gives two units +4/+4). The five tribe-only units are the payoffs that make an all-Briar board worth it.

## Shared ground

- **Gives:** the Compost (any tribe's bought units are fuel; a card in another tribe can send its tokens there), Thorns as the answer to boards of small attackers, and units that die twice for the tribes that count deaths and returns.
- **Takes:** slot buffs matter more to Briars than to most, because copies from the heap arrive plain and a slot buff is the only buff they have. The locusts' units that repeat death effects work on Seed, Crab-apple and Old Stump.
- **Thorns and attack triggers:** Thorns hits only the unit making the attack, before its own attack effects, and if that unit dies the attack is over. Mice that pile on hit first and are not attacking, so thorns don't touch them, and units reached by Overrun or Cleave were not attacked, so their thorns do nothing. Nothing reduces Thorns (the badgers dropped Plate). An attack that "takes no damage" takes none from Thorns.
- **Being outnumbered:** a Regrowth board can start the fight with five units on purpose. The badgers' count is taken when the fight starts and never changes, so their Fury, Grudge and Relic Seeker units on that board are paid as if it stayed short, copies or not.

## Tier check

A body is the median plain unit's stats at that tier: 9 / 12 / 14 / 18 / 20 / 25.

- **Tier 1:** one tempo body (Nettle Sprout, about half a body of thorn damage a fight) and one seed (Bramble Runner, 1 Compost a turn). Fits.
- **Tier 2:** economy (Hedge Layer), a scaler (Sweetbriar) and an enabler (Blackthorn Sapling). The Sapling gives two things, a second body in the fight and 2 permanent stats per return, which is generous on purpose: it is the Coppice plan's only growth before Tier 5. Hedge Layer's 2 gold every turn is the likeliest card here to be bought by every player in the lobby. That is partly the point, since it starts their heaps. The dial, if it is too much: the gold only when a Briar is buried.
- **Tier 3:** four enablers. Blackberry Sprawl is on target at heap 10 (20 stats, 1.4 bodies) and hot at heap 20 (40 stats, nearly 3). It pays for the turns spent feeding.
- **Tier 4:** Ivy Climber gives two units 20 stats each at heap 20, about 2 bodies, on target. Holly Knight is about 3 bodies of damage at heap 18, over on purpose, because thorns do nothing to a few huge attackers. Leafmould Carter is 28 permanent stats a turn on a full Briar board, 1.5 bodies against 1.3. Hawthorn Warden is a Guard twice.
- **Tier 5:** Hazel Coppicer is the direction card (about 2 bodies a turn at three returns). Lone Hawthorn is the tempo piece. Elder Mother is the combat engine (one plain Tier 4 or 5 body with +15/+15 at a heap of 15).
- **Tier 6:** Briar King, from the back row, gives four front-row Briars Grow 2: 160 stats at heap 20, about 6 bodies, on target. The Old Hedge gives every other Briar a second life at its permanent stats for 1 Compost each. Old Mother Midden alone is 56 permanent stats a turn (2 bodies); with two Carters it is 168 (nearly 7, inside the top end of 10).
- **Where the plans stand against each other:** at turn 9 the five are within about a quarter of each other on stats. By turn 13, without Tier 6 units, Mulch leads by up to half, because its stats are permanent and come back with Root. The dial is Leafmould Carter (front-row Briars only, or +2/+1). Hazel Coppicer gives more on a locust Molt board (about five returns a fight) than on a Briar board at turn 9 (three); the dial is counting only the first three returns a fight.
- **Golden:** numbers double and Root costs stay. The ceiling worth chasing is a golden Sprawl (Grow 4) in front of two Ivies.

## Balance picks, 20 Nov 2026

| Unit | Tier | Stats | Text | Golden |
|---|---|---|---|---|
| Blackthorn Sapling | 2 | 5/6 | Root 1. After this returns, gain +1/+1 permanently. | 10/12, Root 1, +2/+2 per return |
| Hedge Layer | 2 | 2/7 | Bury: Gain 2 gold. | 4/14, 4 gold |
| Elder Mother | 5 | 5/13 | Start of fight: Summon a copy of the highest-tier unit in your Compost, with +1/+1 for each unit in it. | 10/26, copies the 2 highest-tier units with +1/+1 per entry |
| Old Mother Midden | 6 | 7/18 | Bury: Give your Briars +2/+2 permanently. Your Bury effects happen twice. | 14/36, +2/+2, Bury effects happen three times |

## Rules the engine needs

1. **The Compost:** a list of entries (card, tier) on each player, kept all game. It is not copied into a fight; a fight changes the real one. When others fight a saved copy of a board, that fight uses a copy of the heap and changes nothing on the real player, like every other "permanently" effect.
2. **Selling into it:** selling a Bought unit adds one entry (a golden adds one for each Bought copy). Selling a Created unit adds nothing.
3. **Bury:** each unit with Bury on the board gives one Bury a turn. The player picks a shop unit (not a spell; frozen is fine). It leaves the shop, an entry is added, then that unit's Bury effect resolves. With no unit in the shop there is nothing to bury.
4. **Spend N:** remove the N lowest-tier entries, oldest first on a tie. If there are fewer than N, nothing is spent and the effect fails.
5. **Copy from the Compost:** find the highest-tier entry not yet copied this fight (newest first on a tie) and summon a plain, non-golden copy. The entry stays and is marked used until the fight ends. The copy is Created and lasts the fight; its own death effects work, Seed included. No empty slot, or nothing left to copy: nothing happens. Because each entry comes out once a fight, no chain of copies can run on.
6. **Seed:** a death effect (9.7.2 step 2): add an entry for this unit's card. Tokens with Seed add an entry at tier 1.
7. **Root N:** a return (9.7.2 step 4, after the unit's own death effects). Unlike 9.8.2, the unit comes back as it stands on the recruit board: full Health and permanent stats, nothing from this fight. A unit with no recruit-board self (a token, a copy) comes back plain. Once a fight for each unit, and not a choice. It goes to its own slot, or the nearest empty slot if a summon took that (9.8.3). If no slot is free, or N can't be spent, nothing is spent and it stays dead. It counts toward the return limit (9.10.3). A unit with Root from two sources returns once and pays the lower cost. A unit that also has the locusts' Molt uses Root first when the heap can pay, and Molt on a later death.
8. **Grow N:** a Start of fight trigger in reading order: +N/+N for every 2 entries (round down), counted when it resolves, for this fight. Grow from several sources adds up. Entries marked used still count. A unit that arrives after the start of the fight doesn't Grow.
9. **Thorns N:** at 9.6.1 step 1, the defender deals N damage to the attacker, on every attack against it, out-of-turn attacks included. It is damage, not an attack and not a Hit. Thorns from several sources add up. If the attacker dies, the attack ends there, before its own attack effects and any pile-on. An attacker that "takes no damage" on that attack takes none.
10. **Enemies killed by Thorns** (Lone Hawthorn): add an entry for the dead unit's card if it was Bought. Created units add nothing, so the fight copy of a board must carry each unit's Bought or Created flag.
11. **Two triggers:** "whenever a unit goes into your Compost" (any entry added, in either phase) and "after a friendly unit returns" (9.7.2 step 5, shared with the locusts).
12. **A heap-changed event,** so auras that read the number (Holly Knight) update in the middle of a fight.
13. **Auras that give a keyword** (Ivy Climber, Briar King, The Old Hedge), recalculated as 12.2.1.
14. **"Your Bury effects happen twice"** (Old Mother Midden): the effect after a Bury resolves twice, or three times with a golden Midden. One unit is buried and one entry added.
15. **Elder Mother:** summon one copy at the start of the fight, or two if golden. Each gets +1/+1 per Compost entry. With no empty slot the copy is lost and its entry remains available (shared ruling 6).
16. **Other tribes' effects on Briar cards:** Seed, Crab-apple's Pip and Old Stump's copy are death effects, so anything that repeats or triggers death effects repeats them. Root is a return, not a death effect. A sale that another card also uses (the locusts' Eat) still adds its entry. A death effect set off without a death (a War-drummer, being eaten) still resolves in full: a Seed adds its entry, a Pip or a copy with no empty slot is lost.
