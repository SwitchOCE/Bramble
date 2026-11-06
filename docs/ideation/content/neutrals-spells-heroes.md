# Neutrals, tavern spells and heroes

Everything that isn't a tribe: 14 neutral units, 18 tavern spells, 20 heroes. First design pass, not yet costed; a separate reviewer does that. All numbers are starting guesses.

## Three things that shaped the set

**A plain swap spell does nothing here.** Moving and swapping your own units in the Recruit Phase is already free and unlimited (rulebook 8.3.3). So every "swap" here happens during the fight, or moves something other than the unit: buffs, stats, the enemy's rows.

**Recruit moves are free, so position text needs something that locks it in.** Text read at Start of Combat or in the fight commits the player. Text read at cast time is a puzzle you solve on the spot, which the owner likes (02h: "It can be an interesting puzzle to figure those things out").

**Neutral creatures are the small and odd ones:** snails, moths, beetles, spiders, bats, and a few plain folk. That keeps them clear of Hedgerow folk, Fairies, Oozes and Birds.

Each card's **Engine** line says `data` if `docs/ideation/engine.md` can already express it, or names the feature it needs (F1 to F14, listed at the end).

---

## Neutral units

Golden follows rulebook 7.3.5: numbers double, thresholds and counters don't. "Stats only" means the text has no number to double.

### Tier 1

**Pennywort Snail**
- Neutral, Snail. Tier 1. 1/3
- **Text:** Sells for 1 more gold per turn it ended on your board, up to 3 turns.
- **Golden:** Sells for 2 more gold per turn, up to 3 turns.
- **Why:** a savings account any build can open. The choice is when to cash it in: it holds a slot until then, and the slot gets dearer every turn.
- **Art:** a fat snail with a stack of round pennywort leaves on its shell, like coins.
- **Engine:** F6.

**Lamp Moth**
- Neutral, Moth. Tier 1. 1/2
- **Text:** Start of Combat: the units in front of this gain +1 Attack this combat.
- **Golden:** +2 Attack.
- **Why:** only does anything from the back row, and which back slot picks which two front units it serves. An early reason to think about the stagger.
- **Art:** a moth asleep on an unlit paper lantern, its wings lit from below.
- **Engine:** data.

**Pill Bug**
- Neutral, Woodlouse. Tier 1. 1/4
- **Text:** Whenever this is attacked, the units behind it gain +1 Attack this combat.
- **Golden:** +2 Attack.
- **Why:** a wall that pays the back row. F2 and F3 feed two units, F1 and F4 feed one, so you choose between reach and focus.
- **Art:** a woodlouse half rolled up, one eye peering out, grit flying off its plates.
- **Engine:** data.

### Tier 2

**Earwig Mother**
- Neutral, Earwig. Tier 2. 1/2
- **Text:** When this dies, summon two 1/1 Nymphs in empty slots behind it.
- **Golden:** Two 2/2 Nymphs.
- **Why:** starts a deep board in any build, and asks you to leave back slots open for it. Without room behind it, the Nymphs go to the nearest empty slot (8.4.2).
- **Art:** an earwig mother standing guard over a clutch of pale nymphs, pincers raised.
- **Engine:** F12 (summon into `behind`).

**Cricket Busker**
- Neutral, Cricket. Tier 2. 2/2
- **Text:** After you cast a spell, gain 1 gold next turn, twice a turn.
- **Golden:** 2 gold, still twice a turn.
- **Why:** economy that is great for a spell player and nearly blank for anyone else.
- **Art:** a cricket fiddling on a mushroom, a thimble out for coins.
- **Engine:** data.

**Turnip Scarecrow**
- Neutral, Folk. Tier 2. 0/4
- **Text:** The enemy across from this skips its first attack.
- **Golden:** Skips its first two attacks.
- **Why:** a slot-matching guess. Stand it across from where you think their best attacker stands. Wrong slot, and it's a 0/4 that does nothing but soak hits.
- **Art:** a scarecrow with a carved turnip head and a torn coat, crows pointedly elsewhere.
- **Engine:** data: `status` `mired` at Start of Combat on `across`. Golden needs a count, because `mired` doesn't stack today.

### Tier 3

**Ballooning Spider**
- Neutral, Spider. Tier 3. 3/2
- **Text:** In your back row, this attacks the enemy back row.
- **Golden:** Stats only.
- **Why:** the plain way past the front row, for any build. It only works from your own back row, so it attacks late and may never get the chance.
- **Art:** a small spider drifting on a long gossamer thread over a hedge.
- **Engine:** F2.

**Sexton Beetle**
- Neutral, Beetle. Tier 3. 2/3
- **Text:** After a friendly unit dies, gain 1 gold next turn, twice a fight.
- **Golden:** 2 gold, still twice a fight.
- **Why:** pays summon and death builds for what they already do, and pays a little for losing. Barely fires for one or two big units that don't die.
- **Art:** an orange-banded burying beetle with a tiny spade, wearing a black sexton's hat.
- **Engine:** data.

### Tier 4

**Mole Cricket**
- Neutral, Cricket. Tier 4. 3/4
- **Text:** When this dies, the unit behind it steps into its slot with +2 Attack and attacks.
- **Golden:** +4 Attack.
- **Why:** turns a protected back-row unit into a surprise extra attack. If two units stand behind it, the one with the most Attack comes forward. The cost: that unit is now exposed.
- **Art:** a mole cricket bursting from the soil, spade forelegs wide, a shadow rising behind it.
- **Engine:** F1.

**Larder Spider**
- Neutral, Spider. Tier 4. 2/5
- **Text:** Once a turn, wrap a shop unit: it survives refreshes and gains +1/+1 each turn.
- **Golden:** +2/+2 each turn.
- **Why:** a slow plan with a cost. Only one unit can be wrapped at a time and it keeps a shop slot full until you buy it. Buy today or let it fatten: the wait is the choice.
- **Art:** a spider patiently wrapping a very surprised shop card in silk.
- **Engine:** F3, F11. From the library's Cold Store.

**Ichneumon Wasp**
- Neutral, Wasp. Tier 4. 1/3
- **Text:** An enemy this damages dies after its next attack.
- **Golden:** Dies instead of its next attack.
- **Why:** kills any size, but on a delay. Back-row targets may never attack before the fight ends, so it wants the enemy's front-row attackers. Blocked hits don't count.
- **Art:** a slender black wasp, long ovipositor raised, hovering over a huge oblivious beetle.
- **Engine:** F13.

### Tier 5

**Charcoal Burner**
- Neutral, Folk. Tier 5. 4/5
- **Text:** End of Turn: burn your gold above 8. Units behind this gain +1/+1 per 3 burned.
- **Golden:** +2/+2 per 3 burned.
- **Why:** gives late gold a use, and it isn't optional. If you want to bank past 8, sell it. Position decides who eats: F2 or F3 feed two units.
- **Art:** a sooty old badger-faced burner beside a smoking earth mound, coins going on the fire.
- **Engine:** F7.

**Pipistrelle Echo**
- Neutral, Bat. Tier 5. 3/6
- **Text:** Spells you aim at this also hit the units adjacent to it.
- **Golden:** Also hit all its neighbours.
- **Why:** makes every one-target spell a small board spell, if you lay out the row for it. Works with any spell aimed at a unit.
- **Art:** a tiny bat hanging in a hollow, sound rings drawn in ink, sparks following them.
- **Engine:** F9.

### Tier 6

**Whirligig Beetle**
- Neutral, Beetle. Tier 6. 5/7
- **Text:** Start of Combat: the enemy's rows swap places. Each enemy moved takes 2 damage.
- **Golden:** 4 damage.
- **Why:** undoes the enemy's whole layout. Their protected carries are now in front; their tanks hide behind. F1 swaps with B1, F2 with B2, F3 with B3, and F4 stays. Empty slots swap too.
- **Art:** a glossy beetle spinning on a pond, the water and everything on it turning with it.
- **Engine:** F1.

---

## Tavern spells

All costs are the price to buy; spells then wait in hand and are cast for free (rulebook 4.2.5). Prices never rise within a turn, which is what makes them somewhere for late gold to go.

### Tier 1

**Elderflower Cordial**, cost 1
- **Text:** Give a unit +1/+3 in the front row, or +3/+1 in the back row.
- **Why:** the plainest position spell. Move the unit first if you want the other split, then move it back.
- **Art:** a stoppered bottle of pale cordial among elderflower heads.
- **Engine:** F12 (per-row split).

**Rainy Day**, cost 1
- **Text:** Next turn, gain 1 gold, or 3 if you lose your next fight.
- **Why:** insurance. It's a poor buy if you expect to win and a good one if you're about to lose anyway.
- **Art:** a mouse under a leaf in the rain, clutching a jar of coins.
- **Engine:** F5.

**Hungry Gap**, cost 1
- **Text:** Gain 3 gold. Next turn, your shop has one fewer unit.
- **Why:** gold now, fewer options next turn. Named for the lean weeks of early spring.
- **Art:** an empty larder shelf with three coins on it and one lonely turnip.
- **Engine:** F6.

### Tier 2

**Shake the Tree**, cost 1
- **Text:** Refresh the shop, but keep one card you choose.
- **Why:** hunting for a triple while holding the piece you've found. It never gets dearer, so it stays useful past 15 refreshes. It costs gold every time, so no free-refresh loop.
- **Art:** a squirrel shaking a branch as cards tumble out, gripping one in its teeth.
- **Engine:** F4.

**Changing of the Guard**, cost 1
- **Text:** Choose two units. When your first unit dies next fight, they swap places.
- **Why:** the owner's "swap two units", made to matter. Bring a healthy unit forward just when the line breaks, or pull a fresh attacker into place.
- **Art:** two beetle sentries in mismatched helmets, passing each other in step.
- **Engine:** F1, F4, F5.

**Cold Frame**, cost 2
- **Text:** If a unit stays in its slot for 2 more End of Turns, it gains +5/+5.
- **Why:** the owner's "don't move for 3 turns, then X" as a spell. Moving it, selling it or tripling it loses the prize, and every shop tests your patience.
- **Art:** a glass cold frame in a garden, one seedling inside and thriving.
- **Engine:** F10.

**Bread from the Back**, cost 2
- **Text:** Aim at a back-row unit: the units in front of it gain +2/+1.
- **Why:** the aimed unit gets nothing. B1, B2 and B3 each pick a different pair, so the shape of your board decides who eats.
- **Art:** a loaf passed forward hand to paw along a line, the last one looking hopeful.
- **Engine:** data.

### Tier 3

**Stand Behind Me**, cost 2
- **Text:** Aim at a front-row unit: the units behind it gain +1/+3.
- **Why:** the partner of Bread from the Back: it feeds the back row, and F2 and F3 reach two units.
- **Art:** a very small beetle with its arms out in front of two much larger ones.
- **Engine:** data.

**Hand-Me-Downs**, cost 2
- **Text:** Move a unit's permanent buffs to a unit in front of or behind it.
- **Why:** lets a build change its carry without losing what it has grown. A scaled unit about to be sold passes it on first.
- **Art:** an old coat, much too large, being handed from one small creature to another.
- **Engine:** F14.

**Poacher's Path**, cost 2
- **Text:** Next fight, a unit's first attack hits the enemy back row, if it can.
- **Why:** one-off back-row reach for a build that doesn't have it. Best on your F1, which attacks first.
- **Art:** a gap in a hedge, a chalk arrow, and a pair of eyes in the dark.
- **Engine:** F2, F5.

**Pawn Ticket**, cost 1
- **Text:** Sell a unit for gold equal to its tier, even if Created.
- **Why:** gets real money from a high-tier unit you've finished with, or from a Created one that would sell for nothing.
- **Art:** a torn paper ticket pinned to a very indignant toad.
- **Engine:** F6.

**Turned Cloak**, cost 1
- **Text:** Swap a unit's Attack and Health for good.
- **Why:** builds that pile up Health get a one-shot carry. Builds that pile up Attack get a late wall.
- **Art:** a cloak turned inside out, the lining a shocking colour.
- **Engine:** F14.

### Tier 4

**Boundary Stone**, cost 3
- **Text:** Aim at a slot: whoever stands there has +2/+2 for the rest of the game.
- **Why:** stats that outlive the unit. Any player can reach slot play, and the buff makes a late gold purchase feel permanent.
- **Art:** a mossy standing stone with a fresh chalk mark, in the middle of a field.
- **Engine:** data.

**Wormwood Charm**, cost 2
- **Text:** Next fight, the enemy across from a unit has half its Attack.
- **Why:** a curse you aim by guessing where they'll stand. The owner preferred curses that debuff (02h).
- **Art:** a knotted sprig of wormwood hung on a nail, smoke curling off it.
- **Engine:** F5.

**Market Day**, cost 3
- **Text:** This turn, units in your shop cost 2.
- **Why:** pays back only if you buy three or more, so it wants banked gold and a big shopping turn. Spells aren't affected.
- **Art:** a crowded stall with a chalked-down price and a very busy shrew behind it.
- **Engine:** F6.

### Tier 5

**Harvest Supper**, cost 3
- **Text:** Give your units +1/+1. Give your smaller row another +1/+1.
- **Why:** the late board spell, with a reason to arrange rows just before casting. If the rows tie, you choose. Moves being free, that's a puzzle rather than a lock.
- **Art:** a long table in a barn at dusk, a small end and a crowded end.
- **Engine:** F12 (smaller-row selector).

**All-In Ale**, cost 1
- **Text:** Spend all your gold. Give a unit +1/+1 for every 2 spent.
- **Why:** a straight late-gold sink for one big unit. Best bought ahead of a turn with a big bank, and a real choice against one more refresh.
- **Art:** a huge tankard, a tiny drinker, coins pouring in from the top.
- **Engine:** F7.

### Tier 6

**Beltane Bonfire**, cost 2
- **Text:** Spend all your gold. Give a row +1/+1 for every 5 spent.
- **Why:** the same sink for a build of medium units. A row is chosen, so front or back is the question.
- **Art:** a great May-eve fire with silhouettes dancing round it, coins in the flames.
- **Engine:** F4, F7.

---

## Heroes

3 are offered at the start of a game. None needs a tribe, so all can appear in any lobby. No armor or health numbers yet: those are for the costing pass.

### Heroes that bend a system rule

**Dame Hoolet**, tawny owl. Passive.
- **Power:** Your back row attacks before your front row.
- **The game:** the protected row is now also the fast one. Put your damage behind and your walls in front, and win before they reach you.
- **Rule bent:** attack order (9.4).
- **Art:** a tawny owl in spectacles, looking over your shoulder at the board.
- **Engine:** F2.

**Jack-in-the-Green**, walking May bush. Passive.
- **Power:** Once a fight, after all your front-row units attack, your rows swap places.
- **The game:** build two lines, not one. Attackers get one swing and then step back; the second row, fresh and unhurt, takes over.
- **Rule bent:** fixed slots in a fight (8.3.4).
- **Art:** a dancing figure entirely covered in leaves, ribbons flying.
- **Engine:** F1, F8.

**The March Hare**. Passive.
- **Power:** Your upgrades cost 2 more and climb two tiers.
- **The game:** you go 1, 3, 5, 6. You skip tiers and their units altogether, and you spend whole turns saving with a thin board, then arrive early with a big shop.
- **Rule bent:** tiers (4.6). The cost is the listed upgrade plus 2.
- **Art:** a wild-eyed hare mid-leap over a tiered shop sign.
- **Engine:** F6.

**Jill Down-the-Tree**, red squirrel. Power, free, once a turn.
- **Power:** Drop one tavern tier and gain 2 gold.
- **The game:** high tier isn't always best. Climb for a key unit, then go down to hunt cheap triples with a thin shop and a fat purse. Going back up costs the full upgrade again.
- **Rule bent:** tiers only go up (4.6.1).
- **Art:** a squirrel sliding headfirst down a trunk, coins falling from her cheeks.
- **Engine:** F6.

**Tuppence**, bank vole. Passive.
- **Power:** You have no Refresh: when you buy a unit, its slot refills at once.
- **The game:** every buy is also a look. You can't reroll a bad shop, you can only buy your way through it, so 3-gold fillers become your search. Selling back to fund the next buy is the core loop.
- **Rule bent:** the refresh (4.4). Refills count on the refresh schedule: after the 15th a buy costs +1, then +1 per 5 more. That is what keeps it from going infinite with on-buy gold.
- **Art:** a vole on a shop ladder, shelves restocking themselves behind her.
- **Engine:** F6.

**Pipkin**, urchin pedlar. Passive.
- **Power:** Your shop has 2 more cards, but you may buy only 2 units a turn.
- **The game:** you see much more and take less. Gold piles up, so it goes to upgrades and spells, which have no limit. Every buy has to be the right one.
- **Rule bent:** shop size and the buy action (4.2, 6.1.1).
- **Art:** a young hedgehog with a pack larger than itself, goods hanging off every spine.
- **Engine:** F6.

**Keeper Greaves**, old ferret. Power, 1 gold, +1 each use.
- **Power:** Pick a shop unit: your shops never offer it again.
- **The game:** you build your own shop. Each removal costs more and thins what you'll see, so the later shops are mostly what you want. Copies stay in the pool for everyone else.
- **Rule bent:** the shared pool (6.1.3).
- **Art:** a ferret in gaiters with a ledger, crossing a name off with some satisfaction.
- **Engine:** F11.

**Mistress Burdock**, badger cook. Passive.
- **Power:** You have a Larder: an eighth slot that never fights, but its unit's effects still fire.
- **The game:** one unit can work full time without fighting. Keep your best shop or end-of-turn effect safe there, and fight with seven.
- **Rule bent:** the board has 7 slots (8.1.1). The Larder has no neighbours and combat doesn't copy it.
- **Art:** a stout badger in an apron at a cellar door, one small creature napping on a shelf inside.
- **Engine:** F11.

**Aunt Dormer**, dormouse. Power, free.
- **Power:** Put a unit from hand to bed: after 3 End of Turns it wakes golden in hand.
- **The game:** one bed, one sleeper at a time. You pay a whole unit's tempo for three turns and then get a golden with no triple needed, though no Triple Reward. A unit you buy now is one you can't use until turn +3.
- **Rule bent:** triples (7.3). Close to the owner's "don't move for 3 turns, then X".
- **Art:** a dormouse in a nightcap tucking a snoring card into a walnut-shell bed.
- **Engine:** F11.

**Goody Nettle**, hedge-witch toad. Passive.
- **Power:** A spell that has been in hand through an End of Turn casts twice.
- **The game:** never cast today what could wait until tomorrow. Buying spells a turn ahead means a hand kept half full and a board a turn behind.
- **Rule bent:** spells as instant one-shots (6.1.5).
- **Art:** a toad stirring a pot, shelves of labelled spell jars marked "tomorrow".
- **Engine:** F9.

**Hob Mumblecrust**, house hob. Power, free, once a turn.
- **Power:** Borrow 3 gold; next turn, repay 4, or lose 1 Health per gold short.
- **The game:** tempo at a price. Borrow every turn and you're always one turn ahead and a little poorer, and when the bill comes due, you pay in Health. The player picks when the debt stops.
- **Rule bent:** gold can't go below 0 (4.1.5); Health becomes a currency.
- **Art:** a tiny hob with a long tally stick, grinning, your coin purse in his other hand.
- **Engine:** F6.

**Dame Farthing**, harvest mouse. Passive.
- **Power:** Start of turn: gain 1 gold per 5 you carried over, up to 3.
- **The game:** saving as a plan: bank in the early turns, spend everything late. Similar to interest in Teamfight Tactics, which Bramble's rules otherwise leave out.
- **Rule bent:** no interest (4.1.3).
- **Art:** a mouse on a wheat stalk counting coins into a very small wicker bank.
- **Engine:** F7.

**Reynard the Fence**, fox. Passive.
- **Power:** Bought units sell for 2 at tiers 3-4, and 3 at tiers 5-6.
- **The game:** at the top tiers a buy is free if you resell it. Flip units all turn hunting triples, and pay only for refreshes. Created units still sell for 0.
- **Rule bent:** sell value (4.3.3).
- **Art:** a fox in a long coat, opening it to show a lining full of cards.
- **Engine:** F6 (`sell_value` by tier).

**Marketwife Sorrel**, rabbit. Passive.
- **Power:** A shop unit costs 1 less if its aisle slot was empty at your last fight.
- **The game:** a gap in your fight pays next turn. The first shop unit lines up with F1, the second with F2, and so on (the library's Aisle). Each gap costs you strength now for cheap buys later.
- **Rule bent:** fixed unit price (4.2.1).
- **Art:** a rabbit at a stall whose shelves line up neatly with the board behind her.
- **Engine:** F6, F11.

### Heroes that change how you fight

**Little King Wren**. Passive.
- **Power:** Start of Combat: your lowest-Attack unit uses the highest enemy Attack for its first attack.
- **The game:** smallest unit, biggest hit. From the folk tale where the wren rode the eagle's back to fly highest. Deliberately keep a tiny unit, and place it where it swings early.
- **Scam flavour.** Ties and placement matter, because F1 swings first.
- **Art:** a very small crowned wren on an eagle's head, looking pleased with itself.
- **Engine:** F13.

**Mother Snare**, vixen poacher. Power, 1 gold, once a turn.
- **Power:** Name an enemy slot: your first attacker next fight hits it if occupied, ignoring rows.
- **The game:** reading the opponent. You see the board they fought with last round, and bet they kept it. Good guess: their carry dies first. Bad guess: nothing happens.
- **Rule bent:** back-row protection (9.5.1).
- **Art:** a vixen kneeling to set a wire by a run, one ear turned your way.
- **Engine:** F2, F5.

**Brother Bracken**, hermit badger. Passive.
- **Power:** Start of Combat: each unit gains +1/+1 per empty slot next to it.
- **The game:** fewer units, placed apart. You decide how few you can afford, and where the gaps do most, against a rule that rewards more units with the first attack (9.2.1).
- **Art:** a hermit badger at a lonely cave mouth, a lot of empty space around him.
- **Engine:** F12 (`per` empty neighbours).

**Hazel Oldroot**, hedge-layer. Passive.
- **Power:** A unit that ends 3 turns in a new slot plants it: that slot gains +2/+2.
- **The game:** a slow garden. Stay put for three turns, then move on and plant the next slot. You choose between keeping your best layout and growing the board.
- **Rule:** one unit plants each slot only once, so standing still stops paying.
- **Art:** an old field mouse laying a hedge, new shoots sprouting behind her.
- **Engine:** F10.

**Mistress Fidget**, pygmy shrew. Passive.
- **Power:** Every 4th buy, sell, play, cast or refresh in a turn: gain 1 gold.
- **The game:** lots of small actions. Cheap spells, selling, tripling and one-gold refreshes all count toward the next coin, so the busy player's turn pays for itself in part. Moves don't count.
- **Art:** a shrew in constant motion, drawn in several places at once.
- **Engine:** F8.

**Old Mother Mousewife**, wood mouse. Passive.
- **Power:** After a front-row unit dies, summon a Mouse behind it, with stats equal to your tier.
- **The game:** a deep board without a tribe. Leave back slots open and treat the front row as doors that open on mice. The later the game, the bigger the mice.
- **Art:** an old mouse by a boot-shaped house, a line of children going out of the door.
- **Engine:** F8, F12.

---

## Coverage check

| Owner's flavour | Neutrals | Spells | Heroes |
|---|---|---|---|
| Small actions, money | Cricket Busker, Pennywort Snail | Rainy Day, Hungry Gap, Pawn Ticket | Fidget, Tuppence, Reynard |
| Deep board | Earwig Mother, Sexton Beetle | Bread from the Back, Harvest Supper | Mousewife, Jack-in-the-Green |
| Scam | Ichneumon Wasp, Turnip Scarecrow | Wormwood Charm, Poacher's Path | Little King Wren, Mother Snare |
| One or two big units | Larder Spider, Charcoal Burner | All-In Ale, Hand-Me-Downs, Turned Cloak, Cold Frame | Aunt Dormer, Oldroot |
| Bunch of medium units | Lamp Moth, Pill Bug, Pipistrelle Echo | Beltane Bonfire, Stand Behind Me, Boundary Stone | Bracken, Goody Nettle |
| Position | Whirligig, Mole Cricket, Ballooning Spider | Changing of the Guard, Elderflower Cordial | Hoolet, Jack-in-the-Green, Sorrel |
| Rule bends: shop, hand, tiers, slot, refresh | | Market Day, Shake the Tree | Pipkin, Keeper Greaves (shop); Dormer, Nettle (hand); March Hare, Jill (tiers); Burdock (slot); Tuppence (refresh) |

7 of 18 spells carry economy: Rainy Day, Hungry Gap, Shake the Tree, Pawn Ticket, Market Day, All-In Ale, Beltane Bonfire. That follows `shared-economy`, which puts most economy on spells anyone can buy.

---

## The 5 strongest combos

1. **Dame Hoolet + Ballooning Spiders.** Back row attacks first, into the enemy back row. Their carries can die before anyone on their side swings. This is the fastest way past the front-row rule in the set.
2. **Goody Nettle + Pipistrelle Echo + All-In Ale.** Hold the Ale overnight, aim it at the Echo. It hits three units, twice, from one bank. A repeat uses the amount first spent, so the second cast doesn't find an empty purse.
3. **Reynard + Market Day.** Units cost 2 and tier 5-6 units sell for 3: every buy earns a gold, and the only thing stopping you is the rising refresh price. This is the long turn the owner wants ("a very, very long time, but not infinitely"), and the easiest combo to get wrong.
4. **Dame Farthing + Charcoal Burner.** Bank for interest through the midgame, then play the Burner: its first End of Turn burns the whole pile into the units behind it. After that the Burner holds you at 8 gold, which still earns 1 a turn.
5. **Ichneumon Wasp + Whirligig Beetle.** The enemy's protected carries are moved to the front, where the Wasp can reach them. Any it damages die after their next attack, whatever their size.

## Riskiest to balance

- **Reynard the Fence.** At tiers 5-6 flipping is free, and any discount or on-buy gold makes it pay. Check with Market Day and every tribe's on-buy effects.
- **Tuppence.** Removing the Refresh removes the rule that bounds loops, so the escalating buy price has to hold. An on-sell or on-buy gold effect is the first thing to test.
- **Dame Hoolet.** Could be the best hero by a lot, or merely good. The bench will show it quickly, and the same goes for Whirligig Beetle at tier 6.
- **Aunt Dormer.** A free golden every 3 turns, repeatedly. May need a longer sleep or a tier limit.
- **Ichneumon Wasp.** A 1-Attack unit that kills anything. Divine-shield-style effects are its only hard counter, and the delay may not be enough.
- **The March Hare.** Tier 3 on turn 3 and tier 5 by about turn 6 could be either the fastest route or an early death. It depends on tribe strength at tiers 2 and 4, which it skips.
- **Spending all your gold with a repeat.** Pipistrelle Echo and Goody Nettle both multiply the X spells, and a big bank makes the numbers large. Late board size may run away here.

## Engine features beyond the doc

The doc can already do: Lamp Moth, Pill Bug, Cricket Busker, Sexton Beetle, Bread from the Back, Stand Behind Me, Boundary Stone and plain Turnip Scarecrow. Everything else needs one of these:

| # | Feature | Used by |
|---|---|---|
| F1 | Move and swap in combat. `swap` and `move` are recruit only. Needs "steps into slot, attacks at once", and "swap rows". | Mole Cricket, Whirligig, Changing of the Guard, Jack-in-the-Green |
| F2 | Attack rules as queries: forced targets past the back-row rule, and back row first. | Ballooning Spider, Poacher's Path, Mother Snare, Dame Hoolet |
| F3 | Activated abilities on units. The doc keeps `activated` for heroes and spells. | Larder Spider |
| F4 | New spell aims: a shop card, two units, a row. | Shake the Tree, Changing of the Guard, Beltane Bonfire |
| F5 | Effects that wait: `duration: next_combat`, and a next-turn gold step that reads last fight's result. Rainy Day's result is checked at the start of the next turn. | Rainy Day, Changing of the Guard, Poacher's Path, Wormwood Charm, Mother Snare |
| F6 | More rule queries: `unit_cost`, `buys_per_turn`, `tier_step`, `tier_down`, `no_refresh` (with buys on the refresh schedule), a next-turn `shop_size` change on a spell, and per-unit `sell_value` that can read tier and a counter. | Market Day, Sorrel, Pipkin, March Hare, Jill, Tuppence, Hungry Gap, Hob (gold below 0 as Health), Reynard, Pawn Ticket, Pennywort Snail |
| F7 | Gold steps: spend all, burn above N, and `per` a spent or carried amount with a divisor. | All-In Ale, Beltane Bonfire, Charcoal Burner, Dame Farthing |
| F8 | Hero triggers beyond `start_of_combat`, in combat (`on_friendly_death`, row finished attacking), and one "any action" event in recruit. | Jack-in-the-Green, Mousewife, Mistress Fidget |
| F9 | Spell hooks: "aimed at this" redirect to more targets, and spell age in hand with a repeat cast that keeps the first amount spent. | Pipistrelle Echo, Goody Nettle |
| F10 | A per-unit "turns in this slot" counter that resets on `on_move`, keyed by slot for the once-only planting rule. | Cold Frame, Hazel Oldroot |
| F11 | New zones: wrapped shop card, Larder slot, bed, and a per-player shop filter. Also the last fight's board kept for reading. | Larder Spider, Mistress Burdock, Aunt Dormer, Keeper Greaves, Marketwife Sorrel |
| F12 | Selector additions: summon into `behind`, `empty_neighbours` for `per`, `smaller_row`, and a step that reads the chosen unit's row. | Earwig Mother, Mousewife, Brother Bracken, Harvest Supper, Elderflower Cordial |
| F13 | New combat statuses: dies after (or instead of) next attack, and "uses this Attack for its first attack". | Ichneumon Wasp, Little King Wren |
| F14 | Stat-layer edits: move permanent buffs between units, swap Attack and Health. Fits the `architecture-lessons` stat layers. | Hand-Me-Downs, Turned Cloak |

Screens: Mother Snare needs the next opponent's last board visible. Marketwife Sorrel needs aisle markers on the shop. Aunt Dormer, Burdock and Larder Spider each need a small new place on the recruit screen.
