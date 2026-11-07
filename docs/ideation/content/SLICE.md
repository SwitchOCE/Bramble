# The first slice

What goes in the first playable build. The three design docs next to this file are the source for anything not changed here. Everything not listed comes back in later batches; nothing is cut. Reviews: `docs/ideation/evidence/design-review-1.md`, `evidence/costing-1.md`.

## Keywords

Named keywords only where a player needs the word. On the owner's record, effects seen in one step land and coined words at a distance don't.

- **Hedgerow:** Acorns (Acorn, Stash, Great Hoard: one idea, three sizes), Spill, Pass.
- **Fairies:** Ring, Rainbow, Shy.
- **Shared:** Bristle, Hunker, Hex, Nightshade. Ring is a game-wide word: spells and neutrals say it too.
- **In plain words on the card, not keywords:** Snug ("After 3 turns in this slot:"), Larder, Eats, Tunnel, Bury, Dance, Teind, Bargain, Fairy Gold.

**Pass** replaces Hand Along and Hand Back. "Pass right +1/+1: at End of Turn, this travels along touching units in the zigzag F1-B1-F2-B2-F3-B3-F4, and the last one keeps it." It resolves at End of Turn so the layout you fight with is the layout that gets it; a gap is a real cost. A sold unit's Pass starts from the slot it left. The UI shows where a Pass will land while dragging.

**Other recruit-phase position text stays instant.** On-play text like "give the units in front of this" reads where things are when played, as the owner wants: "It just lets you choose what units you want to buff."

**Turns-in-slot** is one counter on the engine, shared by Sleeping Partner and Cold Frame. A move resets it.

**Across-aimed cards are in, and scouting is a rule.** Every player can see the next opponent's board as it fought last round, by slot. The position test measured "across from" text as the only text that creates a real placement decision: adaptive gain +6.5 to +7.1 against a noise ceiling of +4.6, and scouting worth +0.40 of a place over the heuristic. This overrules Critic A's note that such cards are "solved once visible": adapting to what you see is the decision.

## Units

### Hedgerow folk (8)

From `hedgerow.md`, verbatim unless changed:
- Mrs Burdock, Mrs Sorrel, Alderman Dozey ("You may play Acorn items on this: +1/+1 per gold.")
- **Mr Crumb:** "When played and when sold: Pass right +1/+1."
- **The Sleeping Partner:** 1/2. "After 3 turns in this slot: get 2 Acorns."
- **Honorary Treasurer:** 2/4. "+1/+1 per 2 gold your held Acorns are worth."
- **Standing Committee:** 2/4. "Start of Combat: touching units get +1 Attack. If all 7 touch, +2."
- **Old Mother Mast:** 5/5. "Start of your turn: get an Acorn if you hold a Stash or Hoard, 2 if a Hoard."

### Fairies (9)

From `fairies.md`, verbatim unless changed. Folk names instead of adjective-plus-fairy: Nan Toadstool (was Toadstool Pixie), Old Moth Annis (was Mothwing Pixie), Sally Spore (was Spore Sprite).
- Nan Toadstool, Sally Spore, Will-o'-the-Wisp
- **Hedge Witch:** "Start of Combat: the enemy across has -1 Attack. Each spell you cast adds -1." Across-aimed, and the Hex word in play.
- **Hob-in-the-Hearth** and **Old Moth Annis** move to tier 2. Hob against Moth is the owner's own puzzle and is kept as it is.
- **Rainbow Chaser:** Rainbow: "A unit played into an empty slot paints it. A band fades if its unit moves or leaves." "When sold: gain 1 gold per 2 bands, 5 for all seven, then wash them."
- **Belladonna Sprite:** "Start of Combat: the 2 front enemies facing this get Nightshade."
- **Queen of Elfland:** "Every 3rd End of Turn: destroy the units behind this (or this, if none). Your other units split their stats evenly."

### Neutrals (8)

From `neutrals-spells-heroes.md`: Lamp Moth, Pill Bug, Turnip Scarecrow, Earwig Mother, Cricket Busker, Charcoal Burner, Ballooning Spider (the slice's back-row reach), Sexton Beetle (1/3, once a fight).

## Spells (10)

Elderflower Cordial, Bread from the Back, Stand Behind Me, Pinch of Dust, Spore Cloud, Shake the Tree, All-In Ale (rename: Last Orders), plus:
- **Cold Frame:** "After 2 turns in its slot, a unit gains +5/+5."
- **Boundary Stone:** a Ring spell at a fair price: it measured far under, and Spore Cloud dominated it, so it gets a bigger Ring or a new job.
- **Hungry Gap:** costs 1. "Gain 2 gold. Next turn, your shop has one fewer unit."

## Heroes (9)

Dame Hoolet, Brother Bracken, Pipkin, Dame Farthing, Hob Mumblecrust, Little King Wren, Jill Down-the-Tree, Old Mother Mousewife (rename to end the clash with Old Mother Mast), **The March Hare** (upgrades cost 4 more and climb two tiers). With only 9 heroes, the human's 3 are distinct and bots may share.

## The balance step (7 Nov 2026)

The card files in `content/` are now the truth for every number and line of text; the lists above are the first slice as designed. Reasons are in `../DECISIONS.md`, measurements in `../evidence/balance-1.md`.

- **Now 37 units and 17 spells,** one of them, A Leg Up, shown only in the opening. Tier counts for units: 9/8/7/5/5/3.
- **Units added from the next batch:** Reel-Mistress, Changeling, Cradle Fetch, Beadle Warrenby, Cluricaun, Dr Urchin, Sergeant-at-Conkers.
- **Units added to fill the tiers and the economy:** Whirligig Beetle, Pipistrelle Echo, Ichneumon Wasp, Pennywort Snail, Money Spider.
- **Spells added:** Rainy Day, Squirrel Away, Market Day, Harvest Supper, Hiring Fair, Beltane Bonfire. Hungry Gap moved to tier 2.
- **Still in the next batch:** Reynard, Tuppence, Aunt Dormer: no loop tests yet, and tier 6 has three units that fight differently.
- **Rules that changed:** a shop draws by tier odds; 40 Health, damage caps by round; the last climb costs 13; Discover always offers 3; a triple keeps waiting prizes; the first shops of rounds 1-2 offer Rainy Day and A Leg Up.

## Next batch

Reel-Mistress, Changeling, Cradle Fetch, Beadle Warrenby, Cluricaun, Dr Urchin, Sergeant-at-Conkers. Reynard, Tuppence and Aunt Dormer after the loop tests, with Reynard's wording fixed to the unit's tier.

## Bench must measure

Tier 6 turn and units bought on arrival (target: turn 8 at the earliest for economy); Acorn value held by turn; Acorns per fight; shops per long turn at banks of 12, 30, 60 (owner: about 20-30); whether any single card's presence swings win rate hard.
