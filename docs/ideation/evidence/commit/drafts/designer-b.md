# Designer B: make the generic gold tribal

## 1. The idea in three sentences

About 40% of board stats come from tavern spells and Rings that work the same on every board, so the gold a player spends after round 8 doesn't care what they are. Rework those sources so the unit you aim at names a tribe, and the spell pays more to units of that tribe. The biggest late spell, Harvest Supper, stops buffing bodies and gives the **tribe** a standing bonus that units bought later also get. Committing then pays twice: every cast reaches more units, and a tier-6 of your tribe arrives already big.

## 2. Why it fixes "committing doesn't pay"

The measurements point at three things, and each change below answers one of them.

- **Generic sources are 40-42% of stats and tribe-to-tribe buffs are 1-2%.** You can't fix that by printing more tribal cards: bots would still pile Stand Behind Me onto whatever they have. Change the 40% itself. If Stand Behind Me, Harvest Supper and Rings pay about 1.5-2x on a committed board and about 0.6-0.8x on a scattered one, the stat pile becomes tribal without anyone buying a new card.
- **No card rewards the fifth, sixth or seventh unit.** A standing tribe bonus ("your Hedgerow folk have +1/+1 for the rest of the game") is worth exactly as many units as you have of that tribe. The seventh unit gets the whole bonus too.
- **A round-15 tier 1 carries 28 stats and a tier 6 carries 18, because buffs land on the first bodies and never move.** A standing tribe bonus lives on the tribe, not on a body. A Hiring Fair tier 6 of your tribe walks in carrying everything the tribe has banked. Off-tribe, it still walks in at printed size, so the reward goes to committing.

Mixed boards aren't dead. Pinch of Dust, Elderflower Cordial, Last Orders and Beltane Bonfire stay generic on purpose, as the floor. A mixed board still gets the base value from every reworked spell, and a two-tribe board can still line up its own kin behind each other.

## 3. Card changes and new cards

Stat-spell rates below are first guesses for the costing reviewer, not costed numbers.

### Spells (CORE)

**Stand Behind Me**: tier 3, cost 2 (was: the units behind it gain +1/+2)
- **Text:** Aim at a front-row unit: the units behind it gain +1/+1. Those that share a tribe with it gain +2/+3 instead.
- **How it plays:** the position puzzle the owner likes stays ("the units behind this"), and now it asks "who stands behind whom?" A Bog folk Mire tank in F2 with two Bog folk in B1 and B2 gives +4/+6 to the pair, 10 stats for 2 gold. A mixed line gives 4. Today it gives 6 on any board.
- **Should it stay at all?** Yes, but no longer as the default gold sink. Its problem was being the best repeatable rate in the game with no condition (cast 4.7 times a player). Now its best rate needs kin lined up, and off-tribe it pays the same 2 stats a gold as Pinch of Dust. Keep it at tier 3, so it reads as a step up from the tier-1 floor spells.

**Bread from the Back**: tier 2, cost 2 (the mirror, changed for consistency)
- **Text:** Aim at a back-row unit: the units in front of it gain +1/+1. Those that share a tribe with it gain +2/+2 instead.
- **How it plays:** the back-row support unit names the tribe it feeds. Hunters put a Hunter in B2 and feed the Pack in F2-F3.

**Harvest Supper**: tier 5, cost 3 (was cost 4: give your units +1/+1, and your smaller row another +1/+1)
- **Text:** Aim at a unit with a tribe: for the rest of the game, your units of that tribe have +1/+1, including ones you get later.
- **How it plays:** the late spell that turns gold into a tribe. A seven-unit tribe gets 14 stats now, and every unit of that tribe you buy, summon or bring home later gets the bonus too. A board with four of a tribe gets 8 stats, against 20 today. The bonus shows on the tribe's icon in the HUD and on each unit's stats ("Hedgerow folk +3/+3").
- **Why cut the row clause:** Stand Behind Me already carries the position puzzle, and one clause is easier for a newcomer to read.

**Hiring Fair**: tier 5, cost 6 (CORE, small change)
- **Text:** Aim at a unit with a tribe: Discover a tier 6 unit. At least one option shares its tribe.
- **How it plays:** 6 gold now buys "the tier 6 of my tribe", which arrives carrying everything from Harvest Supper. This answers "a 6-gold Hiring Fair felt wasted" without making the bodies bigger.

**Unchanged on purpose (the generic floor):** Pinch of Dust, Elderflower Cordial, Last Orders, Beltane Bonfire, Cold Frame. A mixed or neutral-heavy board still has full-rate places to spend gold, at lower rates than a committed board gets. Tavern spells stay a real choice: kin spells for the committed, floor spells for the scattered, and economy spells (Rainy Day, Market Day, A Leg Up) for both.

### Rings and Fairies (CORE)

**Ring** (keyword; one line added)
- **Added:** A Fairy standing on a Ring has twice its stats.
- **How it plays:** Nan Toadstool's +1/+1 Ring is +2/+2 under a Fairy. A Hedgerow board that hires two Fairies for Rings still gets the face value, so the "Hired Help" build lives on, but the best Ring user is now a Fairy. Spore Cloud and Boundary Stone stay neutral spells, and they become the Fairies' generic gold.
- **Costing flag:** Fairies are already 23% of Hard picks. If doubling runs hot, cut Sally Spore's Ring to +1/+0 per turn before touching the rule.

**Spore Cloud** (tier 2, cost 2) and **Boundary Stone** (tier 4, cost 2): text unchanged. With the Ring line, they're worth double under a Fairy.

### Hedgerow folk (OPTIONAL)

**Hedgerow Elder**: tier 4, 4/6 (was vanilla)
- **Text:** After you play a Stash or a Great Hoard, your Hedgerow folk have +1/+1 for the rest of the game, including ones you get later.
- **Golden:** ...+2/+2...
- **How it plays:** it rewards the owner's hoarding choice ("take a little now, or more later"). You can cash three Acorns for 3 gold, or wait for a Stash that pays 5 gold and grows the tribe. Kits, Shrewlets and Hoglets are Hedgerow folk, so every summon arrives with the bonus. That is Hedgerow's "bunch of medium units".

### Oozes (CORE)

**Moss Ooze**: tier 2, 2/4 (was vanilla 3/4)
- **Text:** When a spell gives one of your Oozes stats, the units inside it gain them too.
- **Golden:** ...gain twice that.
- **How it plays:** today a Belly is a blind spot for gold, because the unit inside gets nothing from spells. With Moss Ooze, Stand Behind Me aimed at an Ooze tank in F2 reaches Bellies in B1 and B2, and a Pinch of Dust on Frumenty also grows the unit whose text she wears. Bellies become the best place on the board to spend a spell.

**Great Ooze**: tier 5, 6/6 (OPTIONAL; was vanilla)
- **Text:** After you buy a unit into a Belly, your Oozes have +1/+1 for the rest of the game, including ones you get later. Twice a turn.
- **Golden:** ...+2/+2... Twice a turn.
- **How it plays:** the Ooze buying action (Little Dollop, Stone Soup) now feeds the whole tribe as well.

### Birds (CORE; see section 4)

**Nest** (keyword; one line added)
- **Added:** A unit standing on a Nest is also a Bird.

**Fieldfare**: tier 2, 3/3 (was vanilla 4/3)
- **Text:** When a Bird comes home, your Birds have +1/+1 for the rest of the game, including ones you get later. Once a turn.
- **Golden:** ...+2/+2... Once a turn.
- **How it plays:** each return grows the flock, the Birds away included. Fieldfares flock in winter, so the name fits.

### Bog folk (OPTIONAL)

**Crested Newt**: tier 4, 5/4 (was vanilla 6/4)
- **Text:** Once a fight, after a Mired enemy faints, your Bog folk have +0/+2 for the rest of the game, including ones you get later.
- **Golden:** ...+0/+4...
- **How it plays:** Health for a Health tribe. The Peat King's Peatlings are Bog folk, so they arrive with it.
- **Bog folk's generic gold** is mostly Stand Behind Me: a Mire tank in F2 or F3 and two Bog folk behind it. The +3 Health suits Mire, Bitter and kisses.

### Hunters (OPTIONAL)

**Stoat Captain**: tier 4, 4/5 (was vanilla 5/5)
- **Text:** After your first Take each fight, your Hunters have +1/+0 for the rest of the game, including ones you get later.
- **Golden:** ...+2/+0...
- **How it plays:** Attack for an Attack tribe. Pack attacks multiply it, because every joiner carries it. Laird of the Sett makes a Take near-certain, so the tier-6 Hunter line now has a reason to want a tribe board.
- **Hunters' generic gold** is Bread from the Back, with a back-row Hunter feeding the Pack in front.

### Each tribe's version of "my generic gold"

| Tribe | Best generic spend | Why it pays more for them |
|---|---|---|
| Hedgerow folk | Harvest Supper, plus Acorns cashed as Stashes | Their tokens inherit the standing bonus, so a wide board of summons grows with every cast |
| Fairies | Spore Cloud, Boundary Stone, their own Rings | Rings are worth double under a Fairy |
| Oozes | Any spell on an Ooze, with Moss Ooze | The spell also feeds the units inside its Belly |
| Birds | Harvest Supper, and Fieldfare on each return | The bonus lives on the tribe, so Birds away lose nothing, and Nest-sitters count as Birds |
| Bog folk | Stand Behind Me behind a Mire tank | Kin get +2/+3, and Health is what Mire wants |
| Hunters | Bread from the Back into the Pack | Kin get +2/+2, and every Pack joiner swings with it |
| Mixed board | Pinch of Dust, Elderflower, Last Orders, Beltane | Full value on any board, at lower rates than a committed board's kin spells |

## 4. Birds

Birds are weak for two reasons, and both come from how generic gold works. Fly South takes a Bird off the board, so a buff spell cast on it does nothing for two fights. And the Nest left behind is an empty slot, or holds a filler that isn't a Bird and doesn't count for any Bird card. That is why pinned Birds boards are only a third Birds.

The direction keeps Fly South and Nests, and puts the Birds' stats on the tribe:

1. **The standing bonus doesn't fly away.** Harvest Supper and Fieldfare buff "your Birds" for the rest of the game, so a Bird coming home has every bonus banked while it was away. Flying no longer wastes gold, and sending Birds south is the action that grows the flock (Fieldfare).
2. **Whoever sits on a Nest is a Bird.** The filler on F2's Nest gets the Birds' standing bonus, counts for Drumming Woodpecker's "+1 Attack to your other Birds", and counts as a Bird for Stand Behind Me's kin clause. So a Birds board is seven Birds even with three Birds away. Nests stop being dead slots and become the place where a cheap body turns into a buffed Bird for two turns. The Great Lump stops being the only good Nest-sitter.
3. **Returning needs room:** the Bird comes back to hand, as now. A Nest-sitter is usually a cheap unit you're happy to sell, so the slot frees itself.

*Costing flag:* The Seven Whistlers counts different Birds. If sitters count toward its seven, that's a welcome buff to a weak tier 6. If it gets out of hand, word it "different Bird cards".

## 5. Oozes and Birds being skipped

**Oozes (1% of picks).** Mostly it's the bot's hand-set prior: Oozes have `strategy_fit` weights of +3-4 and no `power` entry, and pinned Ooze boards play about average (4.25 and 5.00). The bot weights need fixing whatever else changes. The game-side reason is smaller but real: a Belly hides units from the 40% of stats that come from spells, so an Ooze board turns the same gold into fewer stats. **What changes:** with Moss Ooze, a spell on an Ooze reaches its Belly, so Oozes get more out of a spell than anyone. Great Ooze ties the tribe's buying action to a standing bonus.

**Birds (0.1%).** Game-weak, as measured (pinned 5.25-5.38). Spells are wasted on fliers, Nests give no stats, and the board isn't Birds. **What changes:** see section 4. The standing bonus survives the trip, Nest-sitters count as Birds, and Fieldfare makes flying the way the flock grows. The bots also need a Birds `power` entry, or they won't try it.

## 6. How a game plays with this

**Committed: Hedgerow.** Turns 1-6 look as they do today: Mr Crumb, Mrs Burdock, Acorns. At tier 3 they cast Stand Behind Me on a Hedgerow unit in F2, and B1 and B2 (both Hedgerow) get +2/+3 each. At tier 4 Hedgerow Elder arrives, and two Stashes later every Hedgerow unit has +2/+2, Kits included. At tier 5 they cast three Harvest Suppers over two turns: +3/+3 to seven units, and to every Shrewlet that Mrs Sorrel summons mid-fight. At tier 6 a Hiring Fair aimed at a Hedgerow unit offers Old Mother Mast, and she comes in at 11/13, not 6/8. Their stats grow with each unit they own, not just with the first bodies they bought.

**Mixed: two Fairies for Rings, three Hedgerow, two Hunters.** Rings give the non-Fairies face value. Stand Behind Me pays +2/+3 only where they can line up kin, so in practice one cast in two. Harvest Supper aimed at the Hedgerow trio gives +6/+6. They lean on Pinch of Dust and Last Orders at full rate. Their late tier 6 arrives at printed size, unless it happens to be Hedgerow.

**Why the committed player wins more:** the same 3 gold of Harvest Supper is 14 stats now plus future units, against 6. The same 2 gold of Stand Behind Me is 10 against 4-10. The mixed board still fights, because its spells still work, but its stat curve is shallower, and its tier 6 doesn't inherit anything.

## 7. New rules or engine needs

1. **Tribe standing bonus (one new rule).** Each player has a per-tribe "+A/+H for the rest of the game" pool. It applies to every unit of that tribe the player has in play, on the board and in fights, including units bought, summoned, coming out of a Belly or coming home later. It works like an aura: the unit doesn't own it, so selling, Hand-Me-Downs and Turned Cloak don't touch it. A dual-tribe unit gets both pools. A rise in the bonus counts as a stat rise for Shy. The engine needs a player-level modifier keyed by tribe, and the HUD shows it on the tribe icon.
2. **Selector "shares a tribe with the chosen unit".** The engine already has `tribe` filters and `of: chosen`. This adds a dynamic tribe taken from the chosen unit.
3. **Ring rule line:** double for a Fairy. **Nest rule line:** the sitter is also a Bird (a type grant from a slot effect).
4. **Discover with a guaranteed tribe option** (Hiring Fair).

No new keywords.

## 8. Risks

- **Stat inflation for the committed.** Committed boards get more stats. That's the aim, but standing bonuses compound with tokens (Hedgerow summons, Peatlings, Wisps). The costing reviewer should price Harvest Supper's bonus per expected unit-round, not per cast.
- **Hedgerow and Fairies are already the top picks.** Ring doubling and Hedgerow token inheritance help the leaders. That's why the Hedgerow card is optional and the Fairy change has a named trim (Sally Spore). Watch Queen of Elfland: her "split evenly" spreads a standing bonus that is already even, so it probably doesn't break, but test it.
- **Kin columns, not kin boards.** Stand Behind Me rewards a local pair of the same tribe, which a two-tribe board can arrange. The commitment reward comes mostly from Harvest Supper and the tribe cards, and Stand Behind Me mostly stops rewarding scattered boards.
- **Neutral units fall behind.** They have no tribe, so they get only the base value. That may be fine (they're flexible glue), but the Neutral pool's support units (Lamp Moth, Pill Bug) get relatively weaker.
- **Readability.** "Those that share a tribe with it" assumes the type line is prominent. The card frame needs a clear tribe icon, and the kin bonus should be highlighted when you aim.
- **Nest-sitter Birds** could turn every filler into a Bird for Seven Whistlers or Drumming Woodpecker. That's probably good for a weak tribe, but it's the one rule line here that changes what a unit *is*.
- **Bots.** None of this shows up in the measurements until bot priors stop hand-favouring Hedgerow and Fairies. Rerun the pinned probes before judging Oozes and Birds.
