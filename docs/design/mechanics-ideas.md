# Mechanics ideas (merged list)

**Superseded as the working list on 2 November by [mechanics-library.md](mechanics-library.md)**, which rewrites all 65 with example units, a play scene and variations, plus 9 new mechanics. This file stays as the first-round record.

Four goldfish designers, who did not see the power budget, wrote 72 mechanics in answer to the owner's 2 November ask for effects beyond Battlegrounds' and for slot mechanics. Merged, they make 65: 37 NEW, 27 VARIANT of a named Battlegrounds or Galaxy card, and 1 RESKIN. Each entry gives the rules, the system rule it bends, a creature, an archetype and example units, then a rules review (against [rulebook.md](rulebook.md) and [architecture-notes.md](architecture-notes.md)) and a rough budget review (against [power-budget.md](power-budget.md)). Nothing is adopted, and every price is a guess until simulated. Read the shortlist of 15 first, then the proposed taxonomy entries. The seven [questions for the owner](#questions-for-the-owner) are at the end.

## Shortlist: the 15 most promising

Picked for being new, for answering one of the owner's own examples, for a clean rules review, and for a budget review that is in band or fixed by a small change. Close behind: Antlers (2, Hunker's attacking twin), Rival (16), Jink (22) and Flood (46). **Flag** means outside the budget band; **edge** means near it. R numbers are the [rules review's shared findings](#rules-review-shared-findings).

| # | Mechanic | Text | Creature | Archetype | Bends | Review flags |
|---|---|---|---|---|---|---|
| 1 | **Hunker** (NEW) | Damage this takes while it is being attacked is halved, rounded up. | Badger | STICKY, MEDIUM | 9.6.1 step 3: damage equals Attack | Rules: clean (R1). Budget: flag at 2/7 (+39%); 2/5 fits. |
| 4 | **Shell (N)** (NEW) | No single hit deals more than N damage to this. | Snail | STICKY; answers TALL | 9.6.1 step 3 | Rules: clean; golden N open (R12). Budget: flag at 1/9 (+48%); 1/6 fits; it grows late, so sim turns 8–12. |
| 5 | **Peck** (NEW) | This unit's attack damage lands as that many 1-damage hits. | Woodpecker | Answers STICKY | 9.6.1 step 3; 9.6.3 death checks | Rules: cap the pecks (about 10), or a huge woodpecker on a hedgehog uses up the trigger limit. Budget: in band. |
| 7 | **Bristle (N)** (VARIANT of Galaxy's Stinky) | When an enemy damages this in an attack, deal N damage to that enemy. | Hedgehog | STICKY; answers WIDE | 9.6.1: a damage step after the exchange | Rules: loops with Curl and Both Ends unless R2. Budget: Tier 1 in band; Tier 4 flag (+22%), 2/5 fits. |
| 9 | **Bide** (NEW) | Skips its attacks and grows each time its side's order passes it, until it wakes. | Heron, dormouse | TALL (back carry) | 9.4.5–9.4.6: a unit that can attack declines | Rules: the wake test needs R3's wording. Budget: Grey Heron flag (+22%), 1/3 fits; dormice in band or edge. |
| 10 | **Whistle** (NEW) | Never attacks; on its turn, the next enemy attack deals half damage. | Marmot | STICKY, MEDIUM (back row) | 9.4.5–9.4.6: a turn spent not attacking | Rules: must override 9.4.6 (0 Attack is skipped); needs R3, R4. Budget: in band; Whistle-Watch Marmot edge. |
| 11 | **Mire** (NEW) | An enemy unit damaged by this skips its next attack. | Toad | MEDIUM, STICKY; answers TALL | 9.4.5: the enemy's order changed from outside | Rules: clean; say the skip doesn't stack. Budget: edge. |
| 13 | **Alibi** (VARIANT of BG Champion of Y'Shaarj) | When an enemy could have attacked this but attacked another unit, this gains +1/+1. | Fox | WIDE, MEDIUM | 9.5.5: the random target becomes a trigger | Rules: weak readability; the must-be-attacked pairing fails as written. Budget: both examples flag; +1 Attack per trigger fits. |
| 21 | **Thicket** (VARIANT of BG Taunt) | Start of Combat: each empty front slot in front of this grows a 3-Health hedge that never attacks. | Brambles (Greenwood) | STICKY | 9.5.1, 9.9.1: a target that isn't a unit | Rules: needs the R7 table of slot occupants. Budget: edge; blank on full boards. |
| 24 | **Quick** (NEW) | In an exchange this strikes first; if that kills, it takes no damage. | Stoat | TALL, SCAM | 9.6.1 step 3, 9.6.2: damage is simultaneous | Rules: clean; the animation must show who struck first. Budget: in band, weaker late. |
| 25 | **Swarm** (NEW) | When this attacks, other Swarm units in its row join in; the target hits back only the leader. | Bees | WIDE; beats TALL | 9.4.1, 9.4.5, 9.6.1: one attacker per turn | Rules: clean; only unflagged bees join. Budget: Worker Bee 1/1 flag (under), 2/2 fits; Drone Captain in band. |
| 40 | **Mark** (NEW) | Start of Combat: mark the enemy slot across; each enemy that enters it takes 3 damage. | Wolf, fox | Answers WIDE and STICKY refills | 8.2.4: a hostile slot effect | Rules: 8.5 needs an owner for slot effects made in combat. Budget: in band. |
| 45 | **Both Ends** (NEW) | With a partner at the other end of the row, both have +1/+2 and each pricks the other's attacker for 2. | Hedgehog | MEDIUM, STICKY | 8.2.2: a relation that spans gaps | Rules: a reflect (R2); 9.6.1 needs an "attacker gone" line. Budget: in band. |
| 56 | **Fast (action)** (NEW) | End of Turn: if you didn't refresh (or buy, or sell) this turn, gain the effect; each turn in a row adds 1. | Heron, olm | TALL, late scalers | 3.1.2, 4.4: with no timer, refreshing to empty is the usual best play | Rules: clean; only paid refreshes count. Budget: both flag (streaks grow quadratically); a cap per turn fits. |
| 57 | **Dig Down** (NEW) | Once per turn, drop a tier until End of Turn and refresh free at that tier. | Mole | WIDE, golden chasing | 4.6.1, 6.1.2: tier only rises | Rules: passes G1 at once per turn; needs a draw tier apart from the player's tier. Budget: in band. |

## Owner reactions to the shortlist (2 Nov)

From the owner's read-through of the checkpoint doc ([2026-11-02h](sources/2026-11-02h-checkpoint-read-through.md)). The owner hasn't read this file in full. **These are directions for iteration, not decisions:** "my reaction doesn't necessarily dictate what changes. It dictates what iterates", and "Nothing in design ever gets cut straight away. You think about it a bit and see what it can teach you" ([2026-11-02i](owner-notes/archive/2026-11-02i-reactions-are-directions.md)). A designer may push back: "Hey, it works here, and here's an example", or "what if we change it to work like this?" No mechanic is picked yet: "Building a big library of good ideas is never a bad play." Every idea needs an example unit with rules text, how it interacts, why a player would run it, and a situation where it is good, plus variations (02h, 02i).

| Mechanic | Reaction | Direction to explore |
|---|---|---|
| Hunker | "This seems cool" | Example cards |
| Shell | "Potentially cool"; maybe "a flat number is problematic" | Also try the owner's version: the first hit (or first few) deals at most N, then the shell breaks, like Divine Shield. A 5-Health snail with Shell 7 must be buffed to use it |
| Peck | "10 is probably far too much" | Also try **Peck X**: its attack counts as X attacks (2 or 3), the damage split among them, so on-attack triggers fire X times; good against Shell |
| Bide | "I like that … We could explore that" | Example cards |
| Whistle | "I'd need a bit more of an example" | Example cards and a play scene |
| Mire | The owner explored the idea ("it makes their backline attack into you"), no change asked | Example cards |
| Alibi | "Interesting"; maybe "whenever an enemy unit attacks a different unit", renamed | Also try the simpler trigger and other names |
| Thicket | "I still don't understand it well" | Example cards and a play scene |
| Quick | "Incredibly strong … would need to go on high-tier units … we'd need some sort of limits" | Try it on high tiers, with limits |
| Swarm | "I like that idea a lot" | Example cards |
| Mark | "Doesn't make sense to me at all … Maybe there's iteration to it" | Example cards; look for the version that works |
| Both Ends | "I still don't get the proposal" | Example cards and a play scene |
| Fast | "It rewards you for not playing the game"; "might be a dead end, but we should still explore it" (02i) | Explore what it teaches; try time-bound versions ("Don't move for 3 turns, then X", 02i) |
| Dig Down | "I have no idea what Dig Down even means" | Example cards and a play scene |

## Proposed taxonomy entries

From the budget review. They are now in [effect-taxonomy.md](effect-taxonomy.md) and its CSV, each marked "proposed 2 Nov, from mechanics-ideas.md". Price rules and tolerances are in [Budget review: proposed taxonomy entries](#budget-review-proposed-taxonomy-entries). R32–R34 are taxonomy trigger IDs, not the rules review's findings R1–R12.

- **E89** Damage-taken modifier: halve, ignore hits of N or less, or cap each hit at N. Hunker, Antlers, Shrug, Shell, Curl, Whistle.
- **E90** Exchange modifier on the dealing side: first strike, split hits, joint attacks, bonus damage on one target. Quick, Peck, Swarm, Grudge, Rival, War Dance.
- **E91** Redirect or share: attacks or damage go to another friendly unit. Shoulder, Shelter, Knot.
- **E92** Fight-end rule acting on ties and stalls. Last Word.
- **E93** Attack denial on enemies. Mire, War Dance.
- **E94** Move or take enemy units. Flush, Changeling.
- **E95** Split self, stat-neutral. Bud, and the Oozes' Split in archetypes.md.
- **E96** Off-slot state: riding, underground, limp, asleep, away. Ride, Burrow, Play Dead, Hibernate, Fly South.
- **E97** Slot object or terrain. Thicket, Brood's Egg, Bury's Nut and Fallow, Mark, Flood's water.
- **E98** Upkeep: a recurring gold cost on a unit. Upkeep, Hungry.
- **R32** Trigger: on skip (the attack order passes this without it attacking). Bide, Whistle.
- **R33** Trigger: when another friendly unit is attacked. Alibi, Whistle-Watch Marmot, Both Ends.
- **R34** Trigger: on upgrade (your Tavern tier rises). Hibernate.

## About this list

**Status: ideas, 2 November 2026. Nothing here is adopted. The costs in the budget review lines are rough.** This merges the four goldfish designers' lists in [mechanics-ideas/](mechanics-ideas/): [combat.md](mechanics-ideas/combat.md), [rows-and-slots.md](mechanics-ideas/rows-and-slots.md), [recruit-and-shop.md](mechanics-ideas/recruit-and-shop.md) and [creatures-first.md](mechanics-ideas/creatures-first.md). Those files stay as the record of what each designer wrote; this file is the working list.

They answer the owner's ask for "explicit attempts to create different effects than just what exists in Hearthstone Battlegrounds", and "The good mechanics break the system rules. They change them" ([2026-11-02f](owner-notes/archive/2026-11-02f-new-effects-and-goldfish-designers.md)), and the point that Battlegrounds keywords "are illustrations" and that "We have set slots, so we can experiment with slot buff mechanics" ([2026-11-02e](sources/2026-11-02e-mechanics-are-examples.md)).

**How to read it**
- **Not costed.** The designers did not see the power budget, on purpose, and this merge didn't open it either. Every tier and stat line is by feel. A separate review costs them.
- **Names are working names.** Rule numbers are from [rulebook.md](rulebook.md). Archetype IDs (ECO, WIDE, TALL, MEDIUM, STICKY, and the spices SCAM and BURST) are from [archetypes.md](archetypes.md) §1.2.
- **Grouped by what the mechanic does**, not by who wrote it. Each entry names its source file and number.
- **Every designer's example unit is kept**, including both versions where two designers wrote the same mechanic.
- **Rules review** lines (2 Nov 2026) check each mechanic against [rulebook.md](rulebook.md), [architecture-notes.md](architecture-notes.md) and guardrail G1 in [content-guardrails.md](content-guardrails.md). Findings shared by many mechanics are numbered R1–R12 in [Rules review: shared findings](#rules-review-shared-findings).
- **Budget review (2 Nov).** A reviewer who did see the budget added a "Budget review" line under each mechanic: a rough cost of each example unit against [power-budget.md](power-budget.md) (V(t), the tier curve with its growth caps, and the tolerance bands) and the nearest classes in [effect-taxonomy.md](effect-taxonomy.md). Most effect prices are **[guess]**; the sim decides. **Flag** means clearly outside the band (more than about 5 points past it, or over a growth cap); **edge** means near the line, with no change asked for yet. Each flag has a change that keeps the mechanic's idea. Reviewers don't flag against power-budget 4.1's gold caps or guardrails G2–G14, which the owner hasn't approved ("Don't flag against them", 2026-11-02g); where one matters, the line says so as information. Mechanics with no class get a proposed entry in [Budget review: proposed taxonomy entries](#budget-review-proposed-taxonomy-entries), now also in effect-taxonomy.md.

**Labels.** Each mechanic was checked against [battlegrounds/keywords.md](../research/battlegrounds/keywords.md), the Battlegrounds card data ([minions.csv](../research/battlegrounds/data/minions.csv), plus trinkets and anomalies), [galaxy/design-notes.md](../research/galaxy/design-notes.md), Galaxy's keyword table ([galaxy/rules.md](../research/galaxy/rules.md) §10) and [galaxy/data/card-list.md](../research/galaxy/data/card-list.md).
- **NEW:** no close match in Battlegrounds or Galaxy.
- **VARIANT:** a clear twist on an existing keyword or card, which is named.
- **RESKIN:** the same as an existing keyword or card, which is named.
- "Retired" means the card is not in the current Battlegrounds pool.

## Counts

**65 mechanics** after merging 72 designer entries (7 merges). **37 NEW, 27 VARIANT, 1 RESKIN.**

The designers marked 15 of their 72 as close variants. This check found more: 14 entries the designers called new have a clear parent, and one marked variant is a reskin. They are listed in [Where this check changed a designer's label](#where-this-check-changed-a-designers-label).

| Group | Mechanics | NEW | VARIANT | RESKIN |
|---|---|---|---|---|
| A. How much damage a hit does | 6 | 5 | 1 | |
| B. Damage back to the attacker | 2 | 1 | 1 | |
| C. Not attacking, and stopping attacks | 4 | 4 | | |
| D. When something else is attacked | 2 | | 2 | |
| E. Choosing targets and reaching the back row | 5 | 3 | 2 | |
| F. Protection and dodging | 3 | | 3 | |
| G. Attack order and timing | 3 | 2 | 1 | |
| H. Kills, overkill and survival | 5 | 1 | 4 | |
| I. Extra bodies, off-slot zones and switching sides | 4 | 2 | 2 | |
| J. Moving your own units in combat | 3 | 2 | 1 | |
| K. Slots, gaps and terrain | 9 | 6 | 2 | 1 |
| L. Gold over turns | 5 | 3 | 2 | |
| M. The shop: buying, selling, refreshing, tiers | 6 | 5 | 1 | |
| N. Waiting off the board: hand and sleep | 3 | 1 | 2 | |
| O. Copies, triples, spells and the pool | 5 | 2 | 3 | |
| **Total** | **65** | **37** | **27** | **1** |

## Index

| # | Mechanic | Label | Closest existing | Source |
|---|---|---|---|---|
| 1 | Hunker | NEW | (Warpwing's retired "Immune while attacking" is the nearest) | combat 1 |
| 2 | Antlers | VARIANT | Galaxy Ranged | combat 2 |
| 3 | Shrug (N) | NEW | | combat 3 |
| 4 | Shell (N) | NEW | | combat 4 |
| 5 | Peck | NEW | | combat 5 |
| 6 | Knot | NEW | | combat 13 |
| 7 | Bristle (N) | VARIANT | Galaxy Stinky | combat 6 |
| 8 | Curl | NEW | (parts overlap Bristle and Hunker) | creatures 1 |
| 9 | Bide *(merged with Slumber)* | NEW | | rows 12, combat 8 |
| 10 | Whistle *(merged)* | NEW | | combat 9, creatures 13 |
| 11 | Mire | NEW | | combat 10 |
| 12 | War Dance | NEW | | creatures 16 |
| 13 | Alibi | VARIANT | BG Champion of Y'Shaarj, Arm of the Empire | combat 11 |
| 14 | Shoulder | VARIANT | BG Elistra the Immortal; Taunt | combat 12 |
| 15 | Grudge | NEW | | combat 7 |
| 16 | Rival | VARIANT | BG Interrogator Whitemane | rows 11 |
| 17 | Nocturnal | VARIANT | Galaxy Sneak | creatures 6 |
| 18 | Shiny | NEW | | creatures 4 |
| 19 | Flush *(merged with Tongue)* | NEW | | rows 10, creatures 17 |
| 20 | Shelter | VARIANT | BG Taunt | rows 13 |
| 21 | Thicket | VARIANT | BG Taunt | rows 9 |
| 22 | Jink | VARIANT | BG Divine Shield | creatures 15 |
| 23 | Headstart | VARIANT | BG Heroic Broodmother ("Start of Combat: Attack immediately") | combat 15 |
| 24 | Quick | NEW | | combat 16 |
| 25 | Swarm | NEW | | creatures 5 |
| 26 | Gorge | VARIANT | BG Overkill (retired), Wildfire Elemental | combat 14 |
| 27 | Bloodied | VARIANT | BG Frenzy (retired) | combat 17 |
| 28 | Play Dead | VARIANT | BG Reborn | creatures 14 |
| 29 | Last Word | NEW | | combat 18 |
| 30 | Bud | VARIANT | BG Silver Goose (retired) | creatures 7 |
| 31 | Ride *(merged with Stowaway)* | VARIANT | BG Magnetic plus a Deathrattle summon | rows 6, creatures 10 |
| 32 | Burrow | VARIANT | BG Deity (Aberrations) | creatures 3 |
| 33 | Changeling | NEW | | creatures 8 |
| 34 | Brood | NEW | | rows 7 |
| 35 | Caravan | VARIANT | Battlegrounds' board packing | rows 3 |
| 36 | Rotate | NEW | | rows 4 |
| 37 | Bolt | NEW | | rows 5 |
| 38 | Sett | RESKIN | Galaxy slot buffs | rows 1 |
| 39 | Bury *(merged with Fallow)* | VARIANT | Galaxy slot buffs | creatures 2, rows 2 |
| 40 | Mark | NEW | | rows 8 |
| 41 | Solitary | NEW | | rows 15 |
| 42 | Migrate | NEW | | rows 16 |
| 43 | Stance | VARIANT | BG Choose One | rows 17 |
| 44 | Delivery | NEW | | rows 18 |
| 45 | Both Ends | NEW | | rows 14 |
| 46 | Flood | NEW | | creatures 18 |
| 47 | Cache | VARIANT | BG anomaly Prudence of Amitus | recruit 1 |
| 48 | Thrift / Revel | VARIANT | BG Tavern Tipper (retired) | recruit 2 |
| 49 | Upkeep *(merged with Hungry)* | NEW | | recruit 3, creatures 11 |
| 50 | Wager | NEW | | recruit 4 |
| 51 | Bargain | NEW | | creatures 9 |
| 52 | Pawn | NEW | | recruit 6 |
| 53 | Barter | NEW | | recruit 7 |
| 54 | Aisle | NEW | | recruit 8 |
| 55 | Cold Store | VARIANT | BG Freeze | recruit 9 |
| 56 | Fast | NEW | | recruit 10 |
| 57 | Dig Down | NEW | | recruit 12 |
| 58 | Hibernate | VARIANT | Galaxy Mysterious Egg; BG Lockbox | recruit 11 |
| 59 | Rehearse *(merged with creatures' Hibernate)* | VARIANT | BG hand-buff cards (Bream Counter, Futurefin) | recruit 13, creatures 12 |
| 60 | Fly South *(was Migrate in recruit)* | NEW | | recruit 18 |
| 61 | Mimic | VARIANT | Galaxy Mirror Mirror; BG Karmic Chameleon | recruit 5 |
| 62 | Foundling | VARIANT | BG Elemental of Surprise, Zilliax modules | recruit 14 |
| 63 | Pair | VARIANT | BG First Mate Pip (retired), False Idols anomaly | recruit 15 |
| 64 | Brew | NEW | | recruit 16 |
| 65 | Endangered | NEW | | recruit 17 |

## Merges

| Kept | Merged in | Why they are one mechanic | What was kept from each |
|---|---|---|---|
| **Bide** (rows 12) | Slumber (combat 8) | Both skip attacks, grow on each skip, and stop when a condition is met: the owner's "skips its attack… gains additional stats" | Bide's name and turn rules; Slumber's wake-on-damage as a second wake rule; all three example units |
| **Whistle** (combat 9) | Whistle (creatures 13) | Same marmot, same rule | Combat's stalemate note; creatures' "this cycle" and splash wording; both marmots |
| **Ride** (creatures 10) | Stowaway (rows 6) | Same wren riding a host and leaping out on its death | Ride's name (plainer); Stowaway's timing (leaps before the host's own summons) and full-board rule; both Wren Kings |
| **Rehearse** (recruit 13) | Hibernate (creatures 12) | Both grow while in your hand | Rehearse's name, so Hibernate stays with the board-sleeper (recruit 11); all three examples |
| **Upkeep** (recruit 3) | Hungry (creatures 11) | Same shrew paying gold each turn | Upkeep's pay-or-starve rule; Hungry kept as a version that also attacks first; both shrews |
| **Flush** (rows 10) | Tongue (creatures 17) | Both move an enemy back-row unit into the front row | Flush's name; both shapes (swap and pull), which have opposite counters; both examples |
| **Bury** (creatures 2) | Fallow (rows 2) | Both put a pickup in an empty slot that the first unit to enter takes | Bury's name (a Nut is a clear object); Fallow's ripening as a second version; both examples |

Not merged, though close: **Curl** and **Bristle** (both hedgehog thorns; Curl is a bundle of thorns, halving and not attacking), **Fast** and **Bide** (the same "rewarded for not acting" idea, but in the shop and in combat), **Headstart** and Hungry's attack-first half (an extra early attack against a permanent place at the front of the order), and **Foundling** and **Changeling** (same folklore, different mechanics).

---

## Shared rules several mechanics need

These are proposals, from [combat.md](mechanics-ideas/combat.md), extended to the mechanics the other designers wrote.

**1. The damage pipeline.** Today a hit deals damage equal to Attack (9.6.1 step 3). With these mechanics, each hit on a unit is worked out in this order:
1. **Split.** Peck turns one attack into several 1-damage hits. Each goes through steps 2–5 on its own.
2. **Ignore.** Shrug (N): a hit of N or less does nothing.
3. **Halve.** Hunker, Antlers, Whistle, Curl: the hit is halved. Two halvings on one hit halve twice.
4. **Cap.** Shell (N): the hit is at most N.
5. **Share.** Knot: what is left is spread across the knot.

A hit-blocking layer (Divine Shield is the Battlegrounds stand-in; Jink is one here) would sit before step 1 and block the whole attack, or before step 2 and block one peck.

**Rounding conflict.** Combat's halvings round **up**, so halving never stops a 1-damage hit and every wall has a clear answer. Creatures' Curl rounds **down**, so 1-Attack tokens can't scratch it, on purpose; creatures' Whistle rounds up. The owner said "either it rounds up or down, I don't know". This needs one rule, or a stated choice per keyword (question 1).

**2. Skipping.** Bide, Whistle, Curl, Mire, War Dance and Nocturnal all have a unit not attack when its turn comes. Proposal: a skipping unit is flagged as having attacked this cycle (9.4.5 step 5) but deals no damage, and its side's turn passes to the next unit that can attack. Skipping costs the side that unit's attack, not a whole turn. *A harsher dial:* a skip uses up the side's turn, so the enemy gets two attacks in a row. Whether the 200-attack limit (9.10.1) counts skipped turns is open (question 2).

**3. Off-slot states.** Ride (riding), Burrow (underground), Play Dead (limp), Hibernate (asleep) and Fly South (away) all put a unit somewhere other than a normal slot. Creatures-first suggests one "off-slot" state with shared rules for targeting and for when combat ends (question 3).

---

## Rules review: shared findings

*Rules and engine review, 2 Nov 2026. Each mechanic below has a "Rules review" line that cites these by number (R1–R12). Layers are those in [architecture-notes.md](architecture-notes.md): rule queries with modifier handlers, the event queue, stat layers, the board geometry module, and the random service.*

- **R1. Damage needs a named query.** architecture-notes.md lists queries for the shop and targeting but none for damage. Add `damageTaken(hit)`, with shared rule 1's steps as unit-layer handlers, plus a step 0 that multiplies or adds (War Dance's double, Rival's double, Grudge's +2) before Peck's split. The proposed order (Ignore before Halve and Cap) is worth keeping: it is what stops Shrug with Shell, or Shrug with Hunker, making a unit immune. Also rule that **a hit reduced to 0 deals no damage and fires no "when damaged" triggers**, or Shrug and Curl still feed Bristle, Bud and Grudge.
- **R2. Reflected damage never triggers reflected damage.** Bristle only blocks Bristle-to-Bristle. Curl pricks on any damage, so Bristle → Curl prick → Bristle repeats until the hedgehog dies, and Both Ends and the Bramble Warden join the same chain. Tag Bristle, Curl, Both Ends and Thicket damage as *reflect*, and say no reflect triggers a reflect.
- **R3. "Acts" is not "can attack".** Bide, Whistle, Curl, War Dance, Mire and Nocturnal need 9.4.5 to tell a unit that takes its turn without attacking from one that can attack. The end-of-combat test (9.9.1) and every "last unit on its side" clause (Bide, Curl, Play Dead) should test **attacks**: "no other friendly unit can attack". Otherwise two Whistle boards never end if whistling counts as able to attack. And Curl plus a marmot against a Whistle board ties, because Curl never counts as last. A no-progress rule would also help: if a full cycle of both sides deals no damage, the fight ends as a tie, instead of running to the 200-attack limit (9.10.1) against Shrug, Shell or Flood walls.
- **R4. Cycles are per side and need a counter.** "First cycle" (Nocturnal), "this cycle" (Whistle) and "once per cycle" (Shoulder) need each side to count its cycles, and text must say whose cycle. Rule that a side's cycle also ends when it passes (9.4.10), or a side with only Nocturnal units never reaches cycle 2.
- **R5. Out-of-order attacks.** Hungry and Headstart must skip the pointer the way 9.4.12 does. Otherwise a Hungry unit in B3 attacking first sets `P = 7` and flags the whole side for the cycle. "Attacks immediately" fired from inside death resolution (Grey Heron, Ride, Burrow, Play Dead) should queue after the current death pass and before the 9.9.1 check.
- **R6. Targeting needs a fixed handler order.** `validTargets` gets reach (Grudge, Rival, Nocturnal, Shiny, War Dance, Flush's weasel) and protection (Shelter, off-slot states) from many cards. Proposed order: base 9.5.1, then reach, then protection, then must-be-attacked (9.5.4), then a separate `defender` step for redirects (Shoulder). That makes **protection beat reach**, which Shelter's text already assumes. It also needs a fallback: a reach unit whose chosen target is protected attacks normally.
- **R7. A slot can hold more than a unit.** The geometry module needs kinds of occupant: unit; non-unit object (Thicket, Egg); pickup (Nut, Fallow); slot effect (Sett, Mark); unit in a slot but inactive (asleep, limp); unit with no slot (rider, underground, away). For each kind, one table should answer: does it block summons, and does it count for who attacks first (9.2.1), back-row protection (9.5.1), random targets (9.5.6), adjacency and neighbours (8.2), an empty board (9.9.1) and hero damage (10.1.1)? This is question 3, made into one table.
- **R8. Start of Combat effects that move things.** Flush, Changeling, Burrow, Brood, Thicket, Rival and Flood all change the board at Start of Combat. Under 9.3.2 a random player resolves first, and 9.3.4 says unit effects read the board from before the hero-power phase. Proposed: each Start of Combat effect reads the board as it stands when it resolves. The owner should know that random side order then decides, for example, whether a Rival is picked before or after a Changeling swap.
- **R9. Combat results flowing back to the Recruit Phase.** Cache (did it die), Aisle (which slot it fought from), Mimic (who was across), Wager (who won) and Shiny's steal all read combat or write from it. 9.1.1 only allows "permanently" on your own units. The engine needs a combat report keyed by recruit-board unit. **Writing to the opponent's board is impossible against a recorded snapshot (2.1.4)**, so effects like Shiny's permanent steal can't work as written.
- **R10. Combat side apart from owner.** Changeling makes a unit fight for the other side. Every "friendly" and "enemy" selector would then read a combat-side attribute, not the card's owner. The rest of the list doesn't need this, so it is a reason to hold Changeling back. If it is kept, the side attribute is cheap to build in from the start.
- **R11. G1 (unpaid refreshes).** Dig Down is the only mechanic here that grants free refreshes directly. It is once per turn per mole, which matches G1's own example, so it passes as long as nothing retriggers or resets activated abilities. Pawn and Aisle make fixed-price buy, sell and play cycles that can be repeated, so a "when sold, bought or played: refresh the shop" unit would become a refresh for about 1 gold that skips the rising price (4.4.2). Pair ("triggers fire twice") and Brew (double numbers) are retrigger and doubling sources and belong on G1's list of retrigger effects that every free-refresh card is reviewed against.
- **R12. Golden numbers against thresholds.** 7.3.5 doubles numbers but keeps thresholds and counters. Shrug N, Shell N and Cache X read as thresholds or caps, so as the rule stands they **don't** double on a golden. That contradicts Shrug's entry and answers the designers' golden-Shell question (Shell isn't weakened). The owner should confirm which it is (question 7).
- **Readability on 4-3.** Line-drawn relations (Rival, War Dance, Grudge, Shelter, Both Ends, Knot, Mark, Aisle) are readable one at a time. Two or three on one board will need the UI to show only the hovered unit's lines. Slot effects (Sett, Bury, Mark, Fallow) all need one shared slot-badge design.

---

## Budget review: proposed taxonomy entries

*Proposed by the budget review, 2 Nov. Added to [effect-taxonomy.md](effect-taxonomy.md) and its CSV as proposed entries; nothing here is adopted. Numbers continue after E88 and R31 so they can't clash with existing IDs; they could be renumbered into families later. R32–R34 are taxonomy trigger IDs (R01–R31), not the rules review's shared findings R1–R12. Every price is **[guess]** until simulated.*

| ID | Class | Mechanics | Price rule (SP at the card's tier) | Tol. |
|---|---|---|---|---|
| E89 | Damage-taken modifier: halve (while attacking, while defending, or always), ignore hits of N or less, cap each hit at N | Hunker, Antlers, Shrug, Shell, Curl; Whistle on the enemy's next hit | Halve while defending or while attacking: about **0.3** × Health. Halve always: about 1.0 × Health, × 0.7 if the unit can't attack. Ignore ≤ N: the share of the tier's damage arriving in hits of N or less × Health (about 0.15 for N = 2 at Tier 5). Cap at N: (1 − N ÷ typical hit at the turn of use) × Health; it grows with the game, so sim it late too | 15 |
| E90 | Exchange modifier, dealing side: first strike, split one attack into 1-damage hits, joint attacks, bonus or multiplied damage against one target | Quick, Peck, Swarm, Grudge, Rival, War Dance | First strike: Divine Shield's price × the chance it one-shots. Split: 0–1. Joint attack: about 0.6 per Swarm unit with a partner in its row. Bonus damage: extra damage × 0.85 × hits on that target | 15 |
| E91 | Redirect or share: attacks or damage go to another friendly unit | Shoulder, Shelter (effect damage), Knot | Taunt's price (0) plus the value of what it protects, about 0.5–2. Sharing: about 0 net (keeps attackers alive, gives up the attacker's wasted overkill) until simulated | 15 |
| E92 | Fight-end rule: acts on ties and stalls | Last Word | Chance of a tie with this unit in the last exchange × a win's value over a tie: under 0.5 | 15 |
| E93 | Attack denial on enemies | Mire, War Dance | About **0.8** × A(t) per enemy attack removed | 15 |
| E94 | Move or take enemy units | Flush (swap, pull), Changeling | Moving a back unit into their front: about 2.5. Switching sides: 2 × the unit's SP less both bodies, so it grows with enemy boards and needs a condition | 15 (move), 25 (switch) |
| E95 | Split self, stat-neutral | Bud; the Oozes' Split in archetypes.md | About 1–2: more bodies and attacks against chip damage, worse against Cleave | 15 |
| E96 | Off-slot state: riding, underground, limp, asleep, away | Ride, Burrow, Play Dead, Hibernate, Fly South | The body × the chance it comes back, plus its entry effect; turns away cost the body for those fights. A rider that uses no slot: E23's +1 for now, likely more on full late boards | 15 in combat, 25 across turns |
| E97 | Slot object or terrain: a non-unit in a slot or on a board | Thicket, Brood's Egg, Bury's Nut and Fallow, Mark, Flood's water | Decoy: E30 at 0.7 × its Health. Pickup: E16, one-off when taken. Hostile mark: E72 × refills a fight. Terrain: the net E15 over both boards | 15 (combat), 25 (T14 pickups) |
| E98 | Upkeep: a recurring gold cost on a unit | Upkeep, Hungry | Optional payment: the lower of the gold's value (2.2) and the drawback. Forced payment: minus the recurring gold price per turn held (at Tiers 1–2 that is more than a plain unit's whole value, 4.1) | 25 |
| R32 | On skip: the attack order passes this without it attacking | Bide, Whistle | About 1 a cycle while it waits; a back unit waits about 2 cycles on a full board | — |
| R33 | When another friendly unit is attacked | Alibi, Whistle-Watch Marmot, Both Ends | Enemy attacks while this lives × the share not aimed at it: about 3–5 a fight for a front unit | — |
| R34 | On upgrade (your Tavern tier rises) | Hibernate | At most 5 a game; about one every 2 turns at standard pace (tier_reach.csv) | — |

Mechanics that fit existing classes: Bristle (E72 on R24), Bloodied (E06 on an R24 threshold), Gorge (E03 on R23), Headstart (E83, E15), Jink (E20, E32), Nocturnal and Shiny (E83 reach), Caravan, Rotate, Bolt, Migrate and Delivery (E32), Sett (E16), Solitary (E06 with C02), Stance (a body with C02), Cache and Wager (E50), Bargain (E01 or E50 with a delayed drawback), Pawn (E54), Barter (E44), Aisle (E53, E14 with C02), Cold Store (E14, E63), Fast (E02 with C03), Dig Down (E52, E62), Rehearse (E17, E02), Mimic (E31), Foundling (E85), Pair (E23, E80), Brew (nearest E80), Endangered (E09).

---

## A. How much damage a hit does

### 1. Hunker — NEW
- **Rules.** Damage this takes while it is being attacked is halved, rounded up.
- **Bends.** 9.6.1 step 3 (damage equal to Attack). Only applies as the defender; damage from effects and from its own attacks is taken in full.
- **Creature.** Badger. A badger in its sett is the classic thing you can't dig out; the Folio's "faded gentry" and "Bathhouse Veterans" both suit a stubborn defender.
- **Archetype.** STICKY, and MEDIUM front-liners.
- **Example.** *Sett Warden*, Tier 3, 2/7. Hunker.
- **Fun against.** Big hitters are wasted on it, but a swarm of 1-Attack tokens or a Peck unit hits it at full value, so WIDE boards and BURST pings are the answer. The badger is unprotected when it attacks.
- **Check.** No halving exists in either game (no card text says "half damage"). The nearest is Warpwing's retired "Immune while attacking", which is all-or-nothing and for the attacker. This is the owner's own example ("50% less damage when it's defending").
- **From.** combat 1.
- **Rules review:** Changes 9.6.1 step 3. Clean as a Halve handler on `damageTaken` at the unit layer (R1). Define "being attacked" as the exchange damage when this is the defender (9.6.1 step 3) only, so splash taken next to the target, reflects and effects hit in full. No loop, and rounding up means it can't stall alone. Readable: one badge on one unit.
- **Budget review:** *Sett Warden* T3 2/7: body 9 (already +12% before text) + Hunker ≈ 0.3 × Health = 2.1 (proposed E89) **[guess]** ≈ 11.1 against V(3) 8: **+39%, flag (over, ±15%).** Change: 2/5 (7 + 1.5 ≈ 8.5, +6%).

### 2. Antlers — VARIANT of Galaxy's Ranged
- **Rules.** Damage this takes while it is attacking is halved, rounded up. This includes damage reflected at it during its attack.
- **Bends.** 9.6.1 step 3 (the exchange is symmetric).
- **Creature.** Red deer stag. It leads with its antlers, so it takes the blow on bone. It suits a Great beasts front carry.
- **Archetype.** TALL (a front carry that trades up many times).
- **Example.** *Rutting Stag*, Tier 4, 6/5. Antlers.
- **Fun against.** A Hunker defender halves the stag's damage while the stag halves the badger's, so the trade is slow for both. Quick defenders strike it first, and random damage effects ignore it.
- **Check.** Galaxy's Ranged takes no damage back when attacking; Antlers takes half. Also near Warpwing's retired "Immune while attacking". The owner's other example ("50% less damage when it's attacking").
- **From.** combat 2 (marked variant by the designer).
- **Rules review:** Changes 9.6.1 step 3. Halve handler at the unit layer (R1). It needs a time window: "while attacking" should mean 9.6.1 steps 1–4 of its own attacks, extra attacks (9.4.12) included, but not death resolution in step 5. Damage from an enemy death effect then lands in full. Antlers against Hunker is slow but finite, because both round up. No loop. Readable.
- **Budget review:** *Rutting Stag* T4 6/5: body 11 + Antlers ≈ 0.3 × Health = 1.5 (proposed E89; a front carry takes about half its damage as retaliation) **[guess]** ≈ 12.5 against V(4) 10: **+25%, flag (over, ±15%).** Change: 6/4 (10 + 1.2 ≈ 11.2, +12%).

### 3. Shrug (N) — NEW
- **Rules.** Hits of N damage or less deal no damage to this.
- **Bends.** 9.6.1 step 3 and 9.6.3: some damage events do nothing at all.
- **Creature.** Bison. Thick fleece and a huge frame; the Folio's Bison Elders are "immovable tanks" whom "nothing moves".
- **Archetype.** STICKY and TALL. A built-in answer to WIDE.
- **Example.** *Bison Elder*, Tier 5, 4/10. Shrug 2.
- **Fun against.** Your token army bounces off it. The answer is clear: one big hitter, a SCAM kill, or a debuff that lowers Shrug. Peck does nothing to it.
- **Golden.** Doubles N under 7.3.5 (Shrug 4), which is a large jump. Worth checking.
- **Check.** No damage threshold exists in either game.
- **From.** combat 3.
- **Rules review:** Ignore handler (R1), clean. Under 7.3.5 as written, N is a threshold, so a golden keeps Shrug 2, not 4 as the entry says (R12). Needs R1's rule that a hit reduced to 0 fires no damage triggers, so ignored hits don't feed Bristle, Bud or Grudge. Stall: against a board with no hit above N it can't be killed, and the fight runs to the 200-attack tie. That is the intended counter, but R3's no-progress rule would end it sooner. Readable: a number badge.
- **Budget review:** *Bison Elder* T5 4/10 Shrug 2: body 14 (+17% before text) + Shrug 2 ≈ 0.15 × Health = 1.5 (share of Tier-5 damage that arrives in hits of 2 or less; proposed E89) **[guess]** ≈ 15.5 against V(5) 12: **+29%, flag (over, ±15%).** Change: 3/8 Shrug 2 (11 + 1.2 ≈ 12.2, +2%). Golden 6/16: if N doubles to 4 (as the entry says), ≈ 22 + 0.35 × 16 ≈ 27.6 against 24 (+15%), at the edge of the golden check; if N stays 2 (7.3.5 as written, rules review R12), ≈ 24.4, on the line.

### 4. Shell (N) — NEW
- **Rules.** No single hit deals more than N damage to this.
- **Bends.** 9.6.1 step 3: the attacker's Attack stops mattering above N.
- **Creature.** Snail. A shell doesn't care how hard you hit it, only how often.
- **Archetype.** STICKY. The answer to TALL, the mirror of Shrug.
- **Example.** *Grove Snail*, Tier 3, 1/9. Shell 3.
- **Fun against.** Your 40-Attack carry does 3 a hit, until you bring the answer: Peck, a wide board, or BURST pings. It sharpens the counter loop in archetypes.md §2.2 (STICKY beats TALL).
- **Golden.** Doubling N makes Shell *weaker* (question 7).
- **Check.** No damage cap exists in either game. Galaxy's Mouse Trap and Battlegrounds' Granite Guardian ("reduce the attacker's Health to 1") are the nearest anti-TALL walls, but they work on the attacker.
- **From.** combat 4.
- **Rules review:** Cap handler (R1). Order matters against Halve: halve then cap 10 gives 3, cap then halve gives 2. Fix the order in the rulebook, not per card. Golden: under 7.3.5 the cap stays 3, so Shell isn't weakened, unless the owner changes 7.3.5 (R12, question 7). State that N is at least 1. Every hit then deals at least 1, so it is slow but never immune, and Ignore running before Cap stops Shrug plus Shell making a unit immune. No loop. Readable.
- **Budget review:** *Grove Snail* T3 1/9 Shell 3: body 1 + 9 × 0.9 (Health-only, E04) = 9.1; at turns 4–6 (A 3.3–4.0) Shell 3 cuts about a quarter of incoming damage, so effective Health × 1.33 ≈ +2.7 (proposed E89) **[guess]** ≈ 11.8 against V(3) 8: **+48%, flag (over, ±15%).** It also grows with the game: against late hits of 6+ Shell 3 halves damage or better. Change: 1/6 Shell 3 (1 + 5.4 + 1.8 ≈ 8.2, +3% at its turns); sim it at turns 8–12 too.

### 5. Peck — NEW
- **Rules.** When this attacks, its damage to the target is dealt as that many separate 1-damage hits. Retaliation is normal.
- **Bends.** 9.6.1 step 3 (one damage event per attack) and 9.6.3 (deaths are checked after each event; here the hits land together and deaths are checked after the last).
- **Creature.** Great spotted woodpecker. It drums, it doesn't punch.
- **Archetype.** An answer to STICKY. It goes through Hunker, Shell and Knot, strips a one-hit blocking layer with one peck, and is useless against Shrug.
- **Example.** *Drumming Woodpecker*, Tier 3, 4/3. Peck.
- **Fun against.** Every peck is a hit, so against Bristle 1 a 4-Attack woodpecker takes 4 back and usually dies. Players learn which walls a woodpecker opens and which it bounces off.
- **Check.** Windfury and Galaxy's "I attack 3 times" give more attacks, not more hits per attack. Nothing splits one attack into many hits.
- **From.** combat 5.
- **Rules review:** Changes 9.6.1 step 3 and 9.6.3 (deaths are checked after the last peck). Clean if one attack can carry a list of hits through `damageTaken` (R1). Ambiguities: does the defender's damage back land with the first peck or after the last? Proposed: with the whole group. A woodpecker that Bristle kills mid-volley keeps pecking, because deaths wait; say so. Trigger cost: every peck fires per-hit triggers (Bristle, Bud, Grudge, Curl), so a 5,000-Attack woodpecker hitting a hedgehog uses up the 10,000-trigger limit (9.10.2) and ties the fight. Cap the pecks (for example at 10, with the rest added to the last). Readable as "many small hits" up to about 10.
- **Budget review:** *Drumming Woodpecker* T3 4/3: body 7 + Peck ≈ 0.5 (gains against shields, Hunker, Shell and Knot; loses against Shrug and Bristle; proposed E90) **[guess]** ≈ 7.5 against V(3) 8: −6%, in band (±15%).

### 6. Knot — NEW
- **Rules.** Damage dealt to a Knotted unit is split as evenly as possible among all your Knotted units. Any leftover point goes to the unit that was hit.
- **Bends.** 9.6.3: a unit's Health is no longer only its own; Knotted units tend to die together.
- **Creature.** Rats, from the Folio's Rat King: "tails have knotted into one gossiping hive-mind", "shared HP and buffs across a knot".
- **Archetype.** WIDE and MEDIUM.
- **Example.** *Knotted Rat*, Tier 2, 2/3. Knot. *The Rat King*, Tier 6, 5/5. Knot. Your Knotted units have +1 Health for each Knotted unit.
- **Fun against.** The knot looks impossible to crack, then collapses at once. A big hit is spread out, but every hit counts, so Peck and wide boards wear it down. SCAM kills that destroy instead of damaging cut it one rat at a time.
- **Check.** No shared-damage mechanic in either game. **Overlaps** archetypes.md's Ooze "Linked" (question 6). **Name clash:** Galaxy has a card called *The Rat King* (Sneak; Hunt), so the example needs another name.
- **From.** combat 13.
- **Rules review:** Changes 9.6.3. A Share handler at the end of `damageTaken` (R1). State that shares are not new hits: they skip Ignore, Halve and Cap on the rat that receives them and fire no "when damaged" triggers. Otherwise one Shrug rat ignores its share, and one Bud rat splits whenever any rat is hit. Rows: shares reach Knotted units in the back row through back-row protection. That is a real rule break, so say it. Riding or underground rats (R7): in the knot or not? The Rat King's aura means each death lowers the others' maximum Health, which can kill more rats in the same check; say aura-loss deaths resolve in the same pass. No loop. Readable with a drawn rope.
- **Budget review:**
  - *Knotted Rat* T2 2/3: body 5 + Knot ≈ 0 net (sharing keeps every rat attacking, but the attacker's overkill is no longer wasted; proposed E91) **[guess, sim]** ≈ 5 against V(2) 7: **−29%, flag (under, ±15%).** Change: 3/4 (7, 0%).
  - *The Rat King* T6 5/5: body 10 + aura of +1 Health per Knotted unit on every Knotted unit, about N² Health: N ≈ 4 in a committed build gives 16 × 0.9 (back aura survival, E13) ≈ 14 → ≈ 24 against V(6) 14: **+71%, flag (over, ±15%)**, and it grows as N². Change: 3/3, "This has +2 Health for each Knotted unit" (the King is in the shared pool, so the Health still protects every rat): 6 + 8 × 0.9 ≈ 13.2 at N = 4 (−6%), ≈ 15 at N = 5 (+7%).

## B. Damage back to the attacker

*The owner: "Something that deals damage back to the attacker whenever it's dealt damage. Maybe the hedgehogs do that: the thorn effect." Creatures-first points out that a defender already hits back for its full Attack (9.6.1 step 3), so thorns are new mainly where they answer damage that isn't an attack exchange, or where they fire on the attacker's own attack. Both Ends (45) also strikes back, from the far end of a row.*

### 7. Bristle (N) — VARIANT of Galaxy's Stinky
- **Rules.** Whenever an enemy unit deals damage to this in an attack (attacking it or defending against it), deal N damage to that unit. Bristle damage never triggers Bristle.
- **Bends.** 9.6.1: adds a damage event after the exchange and before death resolution, so a hedgehog that dies still pricks.
- **Creature.** Hedgehog, as the owner suggested. The Folio's "losing racers" take (the hare always beaten by the hedgehog) gives a natural rival in Headstart.
- **Archetype.** STICKY; a front wall that trades twice. Strong against WIDE (1-Health tokens die attacking it).
- **Example.** *Hedgerow Hedgehog*, Tier 1, 1/3. Bristle 1. *Hedgehog Apothecary*, Tier 4, 2/6. Bristle 3.
- **Fun against.** It punishes many small attacks, so it is the one wall where swarming is wrong. Hit it once, hard. Whether it reflects damage from effects is a dial (question 7).
- **No loops.** Bristle damage can't trigger Bristle, so two hedgehogs can't ping each other forever.
- **Check.** Galaxy's Stinky: "After I'm attacked, deal that much damage to a random enemy." Bristle hits the attacker for a fixed N, and also fires when the hedgehog attacks. Battlegrounds' Granite Guardian (retired) also punishes the attacker.
- **From.** combat 6 (marked variant by the designer).
- **Rules review:** Adds a damage step between 9.6.1 steps 3 and 4. Clean as an event-queue trigger tagged as a reflect. Loop: Bristle only stops Bristle triggering Bristle, so Bristle → Curl prick → Bristle repeats until a unit dies. Under Curl's rounding down, Bristle 1 deals 0 to Curl, so only the hedgehog loses Health. R2 fixes this. "In an attack" should mean 9.6.1 steps 1–4. It fires once per peck (Peck) and once per joining bee (Swarm), which is good counterplay. Readable if Bristle damage shows as a separate pop after the exchange.
- **Budget review:**
  - *Hedgerow Hedgehog* T1 1/3 Bristle 1: body 4 + about 1.5 exchanges a fight × 1 damage × 0.85 ≈ 1.3 (E72 on R24) ≈ 5.3 against V(1) 5: +6%, in band (±15%).
  - *Hedgehog Apothecary* T4 2/6 Bristle 3: body 8 + about 2 exchanges × 3 × 0.7 (chip damage on bigger bodies is partly wasted) ≈ 4.2 ≈ 12.2 against V(4) 10: **+22%, flag (over, ±15%).** Change: 2/5 Bristle 3 (7 + ≈ 3.6 ≈ 10.6, +6%).

### 8. Curl — NEW
- **Rules.** This doesn't attack, and it takes half damage (rounded down). Whenever anything damages it, the unit responsible takes 1 damage; if the source isn't a unit (a hero power), a random enemy takes it. When it is the last unit on its side, it uncurls and fights normally.
- **Bends.** 9.4.5: a unit with Attack sits out the attack order. 9.6.1 step 3: the exchange stops being equal.
- **Creature.** A hedgehog doesn't fight or run; it rolls into a ball and lets the predator hurt itself. The Folio's hedge-apothecaries "carry cures on their spines".
- **Archetype.** STICKY: a wall that wins by making the enemy run out of attacks. Rounding down means 1-Attack tokens can't scratch it and take a prick each, so it punishes BURST and WIDE.
- **Example.** *Pincushion Hedgehog*, Tier 2, 2/6. Curl. (Golden: pricks for 2.)
- **Fun against.** The ping board kills itself on spines; the token swarm bounces off. The answer is one big hitter (halving 10 still lets 5 through). The uncurl clause stops two Curl boards staring at each other until the fight ties (9.9.1).
- **Check.** As a whole, no close match. Its thorns are a cousin of Stinky that fire on any damage source. **Overlaps** Bristle, Hunker and Bide in this list: it may be better as one unit's text built from those parts than as its own keyword.
- **From.** creatures 1.
- **Rules review:** Changes 9.4.5 (a unit with Attack sits out) and 9.6.1. Needs R3: "last unit on its side" should be "no other friendly unit can attack", or Curl plus a Whistle marmot against a Whistle board ties, which is the stall the uncurl clause exists to prevent. Rounding down contradicts its own text: a 1-Attack token deals 0, so "whenever anything damages it" doesn't fire and the token takes no prick. Write "whenever this is hit" if the prick should fire on 0. Loops with Bristle and Both Ends (R2). Is "the unit responsible" ever friendly (your own splash or effects)? Say enemy sources only. Readable as a ball, but uncurling needs a visible cue.
- **Budget review:** *Pincushion Hedgehog* T2 2/6: its Attack works only once it uncurls (≈ 0.4); halving rounded down about doubles its Health against attacks, 12 effective Health at about 0.7 SP each on a unit that doesn't attack ≈ 8.4 (proposed E89; E83 "can't attack") **[guess]**; pricks ≈ 3 hits × 0.85 ≈ 2.5 (E72 on R24) → ≈ 11.3 against V(2) 7: **+61%, flag (over, ±15%).** Change: 1/4 (0.2 + 5.6 + 2 ≈ 7.8, +11%).

## C. Not attacking, and stopping attacks

*The owner: "Something that skips its attack, and every time it skips its attack in combat, it gains additional stats… Things that don't attack, but get rewarded every time they skip." Fast (56) is the shop version. All of these need shared rule 2.*

### 9. Bide — NEW *(merged with Slumber)*
- **Rules.** While it waits, this skips its attacks, and each time its side's attack order passes it, it grows. It stops waiting for the rest of combat when its wake condition is met, or when it is the only unit on its side that could attack. Two wake conditions were written:
  - **Screen** (Bide, rows): it waits while a friendly unit stands in front of it, and gains +2 Attack this combat each time it waits.
  - **Sleep** (Slumber, combat): it waits until it takes damage, and gains +1/+1 each time it skips.
- **Bends.** 9.4.5 (a unit that can attack, does) and 9.4.6: a unit able to attack declines to, and the pointer moves past it. 9.4.2: the back row's reserve role becomes a wind-up.
- **Creature.** Heron, which stands perfectly still, then stabs (Folio: "first-strike lancer"). Hazel dormouse, which "sleeps over half the year", and the Marmot Cantons' hibernators who "wake stronger".
- **Archetype.** TALL. A back carry fed by time rather than deaths; protected in the back row while the front holds.
- **Examples.**
  - *Grey Heron*, Tier 3, 1/5, Bird. "Bide. When this stops waiting, it attacks immediately."
  - *Hazel Dormouse*, Tier 2, 1/3. Slumber.
  - *Seven Sleepers' Dormouse*, Tier 5, 3/6. Slumber; it gains +2/+2 instead.
- **Fun against.** A race with a visible counter. Screen: break the units in front of the heron fast and it strikes small; break them slowly and you feed it. Sleep: one ping at the start of the fight wakes it tiny, since random damage ignores rows (9.5.6).
- **Check.** No skip-and-grow exists. Battlegrounds' Arcane Cannon (retired) "Can't attack" but gains nothing; Galaxy's Punxsutawney Phil rewards not attacking, but only on death.
- **Other names.** Slumber (combat 8).
- **From.** rows 12, combat 8.
- **Rules review:** Changes 9.4.5–9.4.6 (a unit able to attack declines). Clean with R3's "acts" step in `attackOrder`. Screen reads "in front of" (8.2.1), which only back slots have, so a front-row Bide never waits; say so. Gaps: a B1 heron is screened by a unit in either F1 or F2. The wake rule "the only unit on its side that could attack" fails with two Bide units, since each sees the other. Two Sleep dormice in one back row that nothing can reach would wait for ever. Use "no friendly unit that isn't waiting can attack". Grey Heron's "attacks immediately" can fire inside death resolution when its screen dies (R5). No loop. Readable with a counter on the unit.
- **Budget review:**
  - *Grey Heron* T3 1/5, back: body 0.75 + 5 = 5.75. Screen gives +2 Attack per wait, about 2 waits on a full board (proposed trigger R32), as a combat buff on a back unit (× 1.4, T04) ≈ 4.2; waking attack +0.5; the back-row attacks it gives up −0.7 → ≈ 4.0 **[guess]**. Total ≈ 9.75 against V(3) 8: **+22%, flag (over, ±15%).** For scale, the rows study measured "+1/+1 when a unit in front dies" on a Tier-3 back unit at 4.4 SP. Change: 1/3 (3.75 + 4.0 ≈ 7.75, −3%).
  - *Hazel Dormouse* T2 1/3 Slumber: 3.75 + about 2 skips × +1/+1 on a back unit ≈ 3.1 net ≈ 6.9 against V(2) 7: −2%, in band.
  - *Seven Sleepers' Dormouse* T5 3/6: 8.25 + 2 skips × +2/+2 ≈ 7.2, minus ≈ 1.5 for skipped attacks ≈ 14 against V(5) 12: +16%, edge, no flag.
  - Assumes the growth lasts this combat only (the 27 Oct rule for combat buffs). If it is permanent, it is combat-triggered scaling and over every growth cap.

### 10. Whistle — NEW *(both designers wrote it)*
- **Rules.** This never attacks. Each time its place in the attack order comes, it whistles instead: the next enemy attack this cycle deals half damage, rounded up, for the attacker's whole damage step, splash included. The pointer moves past it as if it had attacked.
- **Bends.** 9.4.1, 9.4.5 and 9.4.6: a unit takes a turn in the order to do something other than attack (units with 0 Attack are normally just skipped). 9.6.1: the next attack's damage is halved.
- **Creature.** Marmot. Alpine marmots post sentries on rocks that whistle an alarm; the Folio's "whistle-sentries who raise the alarm at everything, including clouds".
- **Archetype.** STICKY and MEDIUM, as back-row support. It turns a protected back slot into steady defence.
- **Examples.**
  - *Marmot Lookout*, Tier 2, 0/4. Whistle.
  - *Whistle-Watch Marmot*, Tier 2, 1/5. Whistle. Whenever an enemy attacks one of your other units, this gains +1 Attack this combat. (The owner's "rewarded when something else is attacked"; it only matters when the marmot is hit back.)
- **Fun against.** Each whistle is a visible trade: one attack given up, half of one enemy hit saved. 1-Attack tokens lose nothing to it, and a Swarm or many small attackers beat it. A big single hitter is what it stops.
- **Stalemates.** A board left with only Whistle units can't attack, and the fight ties (9.9.2). Last Word interacts with that.
- **Dials.** Combat's version halves "the next enemy attack" with no time limit and only to its target; creatures' version lasts "this cycle" and includes splash.
- **Check.** Arcane Cannon's "Can't attack" exists; spending the attack turn on an effect does not.
- **From.** combat 9, creatures 13.
- **Rules review:** Changes 9.4.5 and 9.4.6. Marmot Lookout has 0 Attack, so 9.4.6 skips it and it would never whistle; Whistle must override 9.4.6. Decide whether whistling uses up the side's turn. Under shared rule 2 it doesn't (the next unit attacks the same turn), so it is free, not "one attack given up". "This cycle" needs R4 (whose cycle?); "the enemy's next attack before your next turn" is cleaner. Two whistles: one attack halved twice, or two attacks halved once? R3: the stalemate test must count attacks, not whistles, or two Whistle-only boards loop. Readable as a debuff on the next enemy attacker.
- **Budget review:**
  - *Marmot Lookout* T2 0/4: body 4 + about 3 whistles a fight × about 1 damage saved × 0.8 ≈ 2.4 (proposed E89 on the enemy's next hit, R32) **[guess]** ≈ 6.4 against V(2) 7: −9%, in band (±15%).
  - *Whistle-Watch Marmot* T2 1/5: its Attack only matters on retaliation (≈ 0.5) + 5 + 2.4 + retaliation bonus ≈ 0.5 ≈ 8.4: +20%, edge, no flag. If the sim agrees, 1/4 (≈ 7.4, +6%).

### 11. Mire — NEW
- **Rules.** An enemy unit damaged by this skips its next attack.
- **Bends.** 9.4.5: the enemy's attack order is changed from outside.
- **Creature.** Common toad, and the Bog folk. Mud and bog water slow anything that wades in; the Folio's Fen Tigers sabotage and flood.
- **Archetype.** MEDIUM and STICKY. Also anti-TALL: a carry that attacks a toad loses its next attack.
- **Example.** *Mudwallow Toad*, Tier 2, 2/4. Mire.
- **Fun against.** Quick attackers kill the toad before it deals damage. Many small attackers make one toad's mire matter less. "My bear got stuck in the mud" is easy to read.
- **Check.** Neither game's combat has it. It is the same idea as constructed Hearthstone's Freeze ("lose next attack"), which Battlegrounds uses only for the shop.
- **From.** combat 10.
- **Rules review:** Changes 9.4.5 from outside. A skip flag on the enemy unit, set through `attackOrder` (R3). Define that it is one flag and doesn't stack, and whether an extra attack (9.4.12, Headstart) uses it up. It also fires when the toad is the defender ("damaged by this" includes damage back), so attacking a toad mires the attacker; say if that is intended. No loop: a skip never stops the other side. Readable: mud on the enemy.
- **Budget review:** *Mudwallow Toad* T2 2/4: body 6 + about 1.1 enemies a fight survive its damage and lose an attack, × A(2) 2.5 × 0.8 ≈ 2.2 (proposed E93) **[guess]** ≈ 8.2 against V(2) 7: +17%, edge, no flag. If the sim puts it over, 2/3.

### 12. War Dance — NEW
- **Rules.** Instead of its first attack, this dances: the highest-Attack enemy is entranced and can't attack until this attacks or dies. This unit's next attack goes at the entranced unit, in either row, for double damage.
- **Bends.** 9.4.5: an enemy unit is taken out of its own side's attack order. 9.5.1: the strike ignores back-row protection. It spends a turn, as the owner's "something that skips its attack" asked.
- **Creature.** Stoat. Stoats do a wild leaping "war dance" that seems to hold a rabbit still before the strike; the Folio's "war-dance troupe".
- **Archetype.** SCAM: it shuts down the enemy carry for a cycle, then hits it hard. It targets by text, not by across-from (archetypes.md §3 rule 3).
- **Example.** *Ermine Dancer*, Tier 4, 3/4. War Dance.
- **Fun against.** Your carry stands still, watching. Kill the stoat before its second turn: pings and fast front units free the carry.
- **Check.** No disabling effect in either game's combat. Interrogator Whitemane (retired) marks a big enemy for double damage but doesn't stop it.
- **From.** creatures 16.
- **Rules review:** Changes 9.4.5 (an enemy is removed from its own side's order) and 9.5.1 (reach, through 9.5.7). A `canAttack` handler on the enemy unit plus a targeting override (R6). Ambiguities: a tie for highest Attack (random, combat stream); the entranced unit being Sheltered or untargetable when the strike comes (R6); "double damage" is R1's step 0, before Peck splits it. If the stoat is Mired, the entranced unit waits longer, but both end. No loop. Readable as a line from stoat to target.
- **Budget review:** *Ermine Dancer* T4 3/4: body 7 + the entranced carry loses about one attack (≈ 5) + double-damage strike ≈ 2.5, minus its own skipped first attack ≈ 2.5 → ≈ 5 (proposed E93, E90; reach is E83) **[guess]** ≈ 12 against V(4) 10: +20%, edge, no flag. If the sim agrees, 3/3 (≈ 11, +10%).

## D. When something else is attacked

*The owner: "Something that gets rewarded every time something else is attacked instead of itself, when it's a legal target, or maybe when it's not a legal target… Maybe just whenever anything else is attacked." The Whistle-Watch Marmot (10) is the plain "whenever anything else is attacked" version.*

### 13. Alibi — VARIANT of Battlegrounds' Champion of Y'Shaarj and Arm of the Empire
- **Rules.** Whenever an enemy attacks and this was one of the units it could have targeted, but it chose another, this gains +1/+1.
- **Bends.** 9.5.5: the random target choice becomes a trigger for the units it didn't pick.
- **Creature.** Fox. The Folio's "Reynard's lawyers, talk their way out of any fight". It was there, but it wasn't involved.
- **Archetype.** WIDE (more friendly candidates, more triggers) and MEDIUM.
- **Examples.** *Reynard's Clerk*, Tier 2, 2/3. Alibi. *Reynard, Esquire*, Tier 5, 4/5. Alibi; your other Foxes also gain +1/+1.
- **Fun against.** Attacking it first matters but is random. A must-be-attacked effect on another unit makes the fox a legal target never chosen, which is a strong pairing.
- **Back-row version.** "Whenever a friendly unit is attacked while this can't be targeted" rewards a protected back unit instead (the owner's "maybe when it's not a legal target").
- **Check.** Battlegrounds' Champion of Y'Shaarj and Arm of the Empire (both retired) grow whenever a friendly Taunt minion is attacked; Galaxy's Prickles buffs the unit in front when it is attacked. Alibi's twist is the trigger: being a legal target that wasn't chosen.
- **From.** combat 11. **Name clash:** creatures' Play Dead example is also called *Reynard's Clerk*.
- **Rules review:** Changes 9.5.5: target choice becomes an event. Needs a "target chosen" event carrying the candidate list, after 9.5.4–9.5.5 and before 9.6.1 step 1, ordered against Shoulder's redirect. The pairing the entry suggests doesn't work: under 9.5.4 a must-be-attacked unit narrows the candidates, so the fox isn't one and never triggers. Either define "could have targeted" as the candidates before 9.5.4, or drop the pairing. A back-row fox is never a candidate while the front row lives, so only the back-row version works there. No loop. Readability is weak: a +1/+1 on a unit nobody touched is easy to miss.
- **Budget review:**
  - *Reynard's Clerk* T2 2/3: body 5 + about 3–4 triggers a fight while it lives in front (enemy attacks that pass it over; proposed trigger R33), +1/+1 for the combat, realised ≈ 4.5 **[guess]** ≈ 9.5 against V(2) 7: **+36%, flag (over, ±15%).** Battlegrounds' Champion of Y'Shaarj (+1/+1 per Taunt attacked) was a Tier 4. Change: "gains +1 Attack" per trigger (5 + ≈ 2.5 ≈ 7.5, +7%).
  - *Reynard, Esquire* T5 4/5: body 9 + its own Alibi ≈ 4 + other Foxes (about 1.5 × 3 triggers × 2 SP × 0.7, C01) ≈ 6.3 ≈ 19 against V(5) 12: **+60%, flag (over, ±15%).** Change: 3/3, and the other Foxes gain +1 Attack instead of +1/+1 (6 + 4 + ≈ 3.6 ≈ 13.6, +13%).

### 14. Shoulder — VARIANT of Battlegrounds' Elistra the Immortal and Taunt
- **Rules.** Once per cycle, when an enemy attacks a unit adjacent to this, this becomes the defender instead.
- **Bends.** 9.5.5 and 9.6.1: the defender changes after targeting, before the "when attacked" step, so the new defender's triggers fire and the original's don't.
- **Creature.** Brown bear. It puts its shoulder in the way. It suits the Folio's "honey monks" and "sleeping king".
- **Archetype.** STICKY and TALL; it guards a carry next to it.
- **Example.** *Bear Warden*, Tier 4, 3/9. Shoulder.
- **Fun against.** Only once a cycle, and only for its row neighbours, so gaps beside it (8.2.2) switch it off. On F1 it guards only F2.
- **Check.** Elistra the Immortal (retired): "Whenever a friendly Taunt minion is attacked, this gets attacked instead." Shoulder is that redirect, limited to neighbours and once a cycle. The designer compared it to Taunt.
- **From.** combat 12 (marked variant by the designer).
- **Rules review:** Changes 9.5.5 and 9.6.1. A `defender` redirect step after targeting (R6), clean if it runs before step 1 as written. Ambiguities: "once per cycle" is the bear's cycle or the attacker's (R4)? Two bears next to the target: take the first in reading order. A bear that redirects onto itself and then Jinks makes the attack miss: intended? Gaps switch it off (8.2.2), which reads well. A back-row bear guards only back-row neighbours, and only once the back row can be attacked. No loop. Readable.
- **Budget review:** *Bear Warden* T4 3/9: body 12 (+20% before text) + Shoulder ≈ Taunt (0 SP) plus the carry it guards ≈ 0.5 (proposed E91) **[guess]** ≈ 12.5 against V(4) 10: **+25%, flag (over, ±15%).** Change: 3/7 (≈ 10.5, +5%).

## E. Choosing targets and reaching the back row

*These are back-row access next to archetypes.md's Swoop and Trample (question 9 there). Shelter (20) is the counter.*

### 15. Grudge — NEW
- **Rules.** When an enemy unit damages this, that enemy is marked. This attacks marked enemies first, even in the back row, and deals +2 damage to them.
- **Bends.** 9.5.1 (back-row protection) and 9.5.5 (random target).
- **Creature.** Rook and crow. Crows remember faces and hold grudges; the Folio's "Rook courts" judge other birds, and Rook parliaments "punish the strongest enemy".
- **Archetype.** SCAM, and back-row reach that the enemy turns on themselves.
- **Example.** *Rook Magistrate*, Tier 3, 3/4. Grudge.
- **Fun against.** The enemy decides who gets marked. Hit the rook with your back-row carry and it comes for the carry; hit it with a token and the grudge is wasted.
- **Check.** No targeting by memory in either game.
- **From.** combat 7.
- **Rules review:** Changes 9.5.1 and 9.5.5. A targeting override (9.5.7) plus a +2 at R1's step 0. Ambiguities: does effect damage mark? As written, any damage from an enemy unit does. With several marked enemies, pick at random. A marked unit that is Sheltered or untargetable falls under R6. A unit that dies and returns is a fresh copy (9.8.2) and loses its mark. Marks belong to units, so they follow units that move. No loop. Readable: a mark on the enemy.
- **Budget review:** *Rook Magistrate* T3 3/4: body 7 + 2 bonus damage on marked targets (about 1.25 attacks × 0.6 chance a marked enemy is alive × 2 × 0.85 ≈ 1.3; proposed E90) + back-row reach ≈ 0.5 (E83) **[guess]** ≈ 8.8 against V(3) 8: +10%, in band (±15%).

### 16. Rival — VARIANT of Battlegrounds' Interrogator Whitemane
- **Rules.** Start of Combat: the enemy unit across from this becomes its Rival. While the Rival lives, this attacks only its Rival, even in the back row, and the two deal double damage to each other.
- **Bends.** 8.2.6 (across from) becomes a duel. 9.5.5's random target and 9.5.1's back-row protection give way to the column.
- **Creature.** Robin, which defends its territory against rivals, sometimes to the death (Folio: "Fights rivals to the death"; the bard who duels).
- **Archetype.** SCAM spice. A small robin trades into whatever big thing it faces.
- **Example.** *Robin Redbreast*, Tier 2, 3/2, Bird. "Rival. If this kills its Rival, gain +2/+2 permanently."
- **Fun against.** Double damage both ways means the robin usually dies gloriously, and sometimes kills a bear. An empty slot across means no Rival, so gaps defend against it (Galaxy design-notes §5, idea 11).
- **Async.** It can't be aimed in async play; the fun is the duel, so keep numbers small.
- **Check.** Interrogator Whitemane (retired): "Start of Combat: Give an enemy minion from Tier 5 or higher Taunt. It takes double damage this combat." Rival makes the duel one-on-one, by column, with double damage both ways. Galaxy's across-from cards (Viscount Chocolat, Mix-O Match-O) are duels without combat.
- **From.** rows 11.
- **Rules review:** Changes 8.2.6 and 9.5.1/9.5.5. The bond should follow the unit, not the slot, once either unit moves (Jink, Flush, Rotate). "Attacks only its Rival" when the Rival can't be targeted (Shelter, an off-slot state): proposed, it attacks normally (R6), or Rival plus Shelter stops the robin attacking at all. Start of Combat order (R8): a Changeling swap or a Flush that resolves first changes who is across. "Permanently" on the robin is fine, since it is your own unit. No loop. Readable as a duel line.
- **Budget review:** *Robin Redbreast* T2 3/2: body 5 + the duel ≈ 1.5 (it trades up, but double damage back usually kills it; proposed E90) + "+2/+2 permanently" on a kill: at about 0.7 kills a fight that is ≈ 2.8 SP of growth a fight, over the Tier-2 combat growth cap of 1.7, priced c_combat 2.8 × 2.8 ≈ 7.8 (E02 on R23) **[guess]** ≈ 14.3 against V(2) 7: **+104%, flag (over the growth cap, ±25%).** Change: 2/2 and "+1 Attack permanently" on a kill (≈ 0.7 SP a fight, under the cap, ≈ 2.0): 4 + 1.5 + 2.0 ≈ 7.5 (+7%). Attack growth still feeds the double damage, so the robin still snowballs, more slowly.

### 17. Nocturnal — VARIANT of Galaxy's Sneak
- **Rules.** This sits out the first attack cycle of each combat. From the second cycle on, it attacks the enemy with the lowest Health, in either row.
- **Bends.** 9.4.5: it opts out of cycle 1. 9.5.1 and 9.5.5: it ignores back-row protection and doesn't choose at random.
- **Creature.** Owl. Owls hunt at night, silently, taking the weak or the stragglers; the Folio's owls are "the court that sits after dark".
- **Archetype.** SCAM: a finisher for wounded units that waits safe in the back row through the first cycle.
- **Example.** *Tawny Magistrate*, Tier 3, 5/2. Nocturnal.
- **Fun against.** Fragile back-row support is in danger once night falls, so Health on support matters, and so does finishing fast.
- **Check.** Galaxy's Sneak attacks the back row first. Nocturnal waits a cycle and then picks the weakest anywhere. Battlegrounds' Lighter Fighter (retired) aims at the lowest-Health enemy, as a Deathrattle.
- **From.** creatures 6 (marked variant by the designer).
- **Rules review:** Changes 9.4.5 (it sits out cycle 1) and 9.5.1/9.5.5. Needs R4. A side with only Nocturnal units can't attack in cycle 1, so 9.4.5 step 4 passes and its cycle never ends. Its units never attack; if the enemy also can't attack, 9.9.1 ends the fight as a tie at once. Rule that a side's cycle ends when it passes. Lowest Health: random on a tie, and the next lowest if that unit is protected (R6). No loop. Readable only if the UI shows cycles ("night falls").
- **Budget review:** *Tawny Magistrate* T3 5/2, back-bound: body 3.75 + 2 = 5.75; sitting out cycle 1 ≈ −1.5; picking the lowest-Health enemy in either row ≈ +2.5 (E83) **[guess]** ≈ 6.75 against V(3) 8: −16%, edge (under), no flag. If the sim agrees, 5/3 (≈ 7.75).

### 18. Shiny — NEW
- **Rules.** This attacks enemy golden units if there are any, in either row. Whenever it damages a golden unit, it steals +1/+1 from it permanently. With no golden enemy it attacks normally.
- **Bends.** 9.5.1: back-row protection, but only for golden targets. 7.3: golden status becomes something the enemy can aim at.
- **Creature.** Magpie. Magpies can't resist shiny things; the Folio's Shiny Syndicate "can't resist anything shiny, including evidence".
- **Archetype.** SCAM, and an answer to golden chasing (archetypes.md §1.3). Magpies could own both the hoarding and the stealing.
- **Example.** *Fence Magpie*, Tier 3, 3/3. Shiny. (Golden: steals +2/+2, and treats other golden units as ordinary targets: thieves don't rob each other.)
- **Fun against.** Your triple becomes a target as well as a prize. The magpie still has to survive the exchange, so it is a tax on the player far ahead.
- **Check.** No targeting by golden status in either game. Galaxy's Sneak and Viscount Chocolat ("steal +3/+3 from the enemy across") each share one half.
- **From.** creatures 4.
- **Rules review:** Changes 9.5.1 for golden targets, through a targeting override (R6). The steal is the problem. "Permanently" from an enemy unit writes to the other player's recruit board, which can't happen against a recorded snapshot (2.1.4, 9.1.1; R9). Make the victim's loss "this combat" and the magpie's gain permanent. No loop. Readable, since goldens already stand out.
- **Budget review:** *Fence Magpie* T3 3/3: body 6 + permanent steal (combat-triggered growth, about 2 SP × 0.5 hits on goldens a fight = 1 SP, under the Tier-3 combat cap; c_combat 2.5 × 1 ≈ 2.5) + the golden's loss (E15 ≈ 1.1) + golden-seeking reach (E83 ≈ 0.4) **[guess]** ≈ 10 against V(3) 8: +25% (±25%: scaling), edge, no flag. Its value rises late as enemy goldens get more common (C08: 0.1 → 0.25 per unit).

### 19. Flush — NEW *(merged with Tongue)*
- **Rules.** Start of Combat: move an enemy back-row unit into their front row. Two shapes were written:
  - **Swap** (Flush, rows): the enemy back-row unit with the highest Attack swaps places with the enemy unit in front of it that has the least Health. If nothing is in front of it, nothing happens.
  - **Pull** (Tongue, creatures): the lowest-Health enemy back-row unit is pulled into an empty slot in their front row. If their front row is full, nothing happens.
- **Bends.** 8.3.5: an effect moves an *enemy* unit. 9.5.1: back-row protection is beaten by moving the target, not by reaching over the front row (11.5.3). 8.2.4: the moved unit's "in front of" and "behind" auras now point elsewhere.
- **Creature.** Weasels, stoats and ferrets hunt inside burrows (ferreting drives rabbits out of the warren). Frogs and toads snatch prey from a distance with a sticky tongue.
- **Archetype.** SCAM spice. It brings the enemy carry, or fragile support, into the line of attack.
- **Examples.**
  - *Burrow Weasel*, Tier 3, 3/3, Hunter. "Flush. This attacks the unit it flushed first, if that unit lives."
  - *Bullfrog Tenor*, Tier 3, 3/4. Tongue.
- **Fun against.** The two shapes have opposite defences, which is worth knowing when choosing one. Against the swap, leave the front slots in front of your carry empty, so there is nothing to swap with. Against the pull, fill your front row, which clashes with squirrels, oozes and summons that want gaps.
- **Check.** No Battlegrounds or Galaxy effect moves enemy units (archetypes.md cites the same finding for Tunnel).
- **Other names.** Tongue (creatures 17).
- **From.** rows 10, creatures 17.
- **Rules review:** Changes 8.3.5 (an effect moves an enemy unit) and 9.5.1. Clean as a geometry-module move. Ambiguities: Swap's "the enemy unit in front of it with the least Health" needs a tie rule. Pull's "an empty slot in their front row": proposed, the nearest by 8.4.2's table from the pulled unit's slot. Order against other Start of Combat effects (R8): an enemy aura that resolves later reads the new board. 9.3.4 needs to say whether earlier unit moves count. The weasel's "attacks the flushed unit first" falls under R6. No loop. Readable: one animated move before the fight.
- **Budget review:**
  - *Burrow Weasel* T3 3/3: body 6 + bringing their back carry into the front ≈ 2.5 (proposed E94) **[guess]** ≈ 8.5 against V(3) 8: +6%, in band (±15%).
  - *Bullfrog Tenor* T3 3/4: body 7 + 2.5 × about 0.4 chance the enemy has an empty front slot ≈ 1 ≈ 8 (0%). In band; blank against full boards, by design.

## F. Protection and dodging

### 20. Shelter — VARIANT of Battlegrounds' Taunt
- **Rules.** The back-row units behind this can't be attacked while this lives, even after the rest of your front row has fallen, and even by attacks that reach into the back row.
- **Bends.** 9.5.1: back-row protection works by column as well as by row. 11.5.3: a counter to back-row reach (Swoop, Rival, Grudge, Nocturnal), which keeps reach from becoming a must-have.
- **Creature.** Bison, the "immovable tank". A herd turns to face a threat with the calves behind. Great beasts.
- **Archetype.** STICKY, and the protected engine for a back carry.
- **Example.** *Białowieża Bison*, Tier 4, 3/9, Great beast. "Shelter. When an effect would damage a unit behind this, this takes the damage instead."
- **Fun against.** One huge beast stands over two calves at the end, and you chew through it. Random-target effects still reach (9.5.6).
- **Check.** Taunt protects others by drawing attacks; Shelter protects by column. It is close to keywords.md's "Guard" idea, which is a Bramble suggestion, not a Battlegrounds keyword.
- **From.** rows 13 (marked variant by the designer).
- **Rules review:** Changes 9.5.1 and 11.5.3. While Shelter lives it is a front-row unit, so 9.5.1 already protects every back unit from ordinary attacks: Shelter matters only against reach. That is a good job, but "even after the rest of your front row has fallen" adds nothing; cut it. Needs R6 (protection beats reach). "Behind" is 8.2.1: one slot for F1 and F4, two for F2 and F3. The bison's "takes the damage instead" contradicts the Fun line ("random-target effects still reach"): the effect can pick the calf, but the bison takes the damage. No loop. Readable as short lines to the slots behind.
- **Budget review:** *Białowieża Bison* T4 3/9: body 12 (+20% before text) + Shelter ≈ 2 (protects about 1.5 back units after the front falls, and soaks effect damage meant for them; proposed E91) **[guess]** ≈ 14 against V(4) 10: **+40%, flag (over, ±15%).** Change: 3/6 (≈ 11, +10%).

### 21. Thicket — VARIANT of Battlegrounds' Taunt
- **Rules.** Start of Combat: each empty front slot in front of this grows a Thicket with 3 Health. Thickets are front-row attack targets that never attack, and they don't count as units for winning, for attack order or for hero damage. A summon into a Thicket's slot clears it.
- **Bends.** 9.5.1: back-row protection comes from terrain, not only units. 9.9.1 and 9.2.1: a side left with only Thickets has lost. Thickets have no death effects, so killing them feeds nothing.
- **Creature.** Brambles themselves, the game's name. Greenwood or Hedgerow folk grow hedges over their burrows.
- **Archetype.** STICKY, and the protected-engine shape MEDIUM and TALL use.
- **Example.** *Bramble Warden*, Tier 2, 1/4, Greenwood. "Thicket. Units that attack your Thickets take 1 damage."
- **Fun against.** You hack through hedges while their real units grow. Cleave and Trample cut through brush.
- **Check.** Taunt tokens are decoys that are bodies; Thickets aren't bodies, can't be buffed and come from the gap. **Overlaps** archetypes.md's Lights "Lure".
- **From.** rows 9 (marked variant by the designer).
- **Rules review:** Changes 9.5.1 and 9.9.1 with a non-unit object (R7, question 3). Needs the R7 table. Thickets count as front-row candidates for 9.5.1, which is the point, but should not count for 9.2.1, 9.9.1, 10.1.1, random enemy effects (9.5.6), Cleave's adjacency or neighbour text. "A summon into a Thicket's slot clears it" implies 8.4 treats the slot as empty; say so. The Bramble Warden's 1 damage is a reflect (R2). No loop: Thickets come only at Start of Combat. Readable: hedges in the gaps, the clearest slot idea on the list.
- **Budget review:** *Bramble Warden* T2 1/4, back: body 4.75 + about 1.2 Thickets a fight on turns 2–4 × (3-Health decoy ≈ 2.1 + 1 prick ≈ 0.85) ≈ 3.5 (proposed E97) **[guess]** ≈ 8.25 against V(2) 7: +18% at its turns, edge, no flag. Blank on a full board, like power-budget worked example #9; price it for turns 2–4 and say so on the card's design note.

### 22. Jink — VARIANT of Battlegrounds' Divine Shield
- **Rules.** The first time each combat this is attacked, if a slot next to it in its row is empty, it darts into that slot and the attack misses (no damage either way).
- **Bends.** 9.6.1: an attack whose defender is gone ends without damage; here the defender leaves on purpose. 8.3.5: units change slots in combat. 9.4.9: darting to a lower-numbered slot flags it as having attacked.
- **Creature.** Hare. A hare doesn't fight; it jinks, turning sharply sideways at full speed.
- **Archetype.** STICKY that wants gaps, so it pulls against wide boards.
- **Example.** *Jack Hare*, Tier 1, 2/2. Jink.
- **Fun against.** Visible from the board: a hare with an empty slot beside it dodges once. Random effects and splash can't be dodged. The move breaks the hare player's own adjacency auras.
- **Check.** Divine Shield also blocks one hit. Jink needs a gap, moves the unit, and blocks retaliation too.
- **From.** creatures 15 (marked variant by the designer).
- **Rules review:** Uses 9.6.1's existing "defender gone after step 1" line, so it is cleaner than it looks: Jink is a step 1 ("when attacked") effect. Ambiguities: both neighbouring slots empty (proposed: right, as 8.4.2 does), and redirects onto it (Shoulder). Against Peck the whole attack misses. Darting to a lower slot flags it (9.4.9), so a hare that hasn't attacked can lose its attack; say if that cost is intended. It darts onto Marks. No loop: once per combat. Readable, since the gap is visible.
- **Budget review:** *Jack Hare* T1 2/2: body 4 + one Divine-Shield-like block (1.8 at Tier 1, E20) × about 0.6 chance of an empty slot beside it on turns 1–4 ≈ 1.1 **[guess]** ≈ 5.1 against V(1) 5: +2%, in band (±15%). Blank on a full board.

## G. Attack order and timing

*Hungry (in Upkeep, 49) also attacks first in each cycle, ahead of reading order.*

### 23. Headstart — VARIANT of Battlegrounds' Heroic Broodmother
- **Rules.** This makes one attack before either side's first attack, after Start of Combat. Then it attacks in normal order. Each time it attacks, it loses 1 Attack.
- **Bends.** 9.2.1 (who attacks first) and 9.4.2 (attack order).
- **Creature.** Hare. The fastest runner who tires and loses the race (Folio: "Losing racers, forever beaten by hedgehogs").
- **Archetype.** BURST spice and early tempo. It strips a blocking layer or a token before the fight proper.
- **Example.** *March Hare*, Tier 1, 3/1. Headstart.
- **Fun against.** A hedgehog in front gives the old story: the hare's first attack lands on Bristle and it dies. Otherwise wait it out; it fades. If both sides have Headstart, the side that attacks first goes first.
- **Check.** Heroic Broodmother (current pool): "Start of Combat: Attack immediately." Headstart adds the fade. Galaxy's Jelly Roger makes your side attack first.
- **From.** combat 15.
- **Rules review:** Changes 9.2.1 and 9.4.2. Must skip the pointer the way 9.4.12 does (R5). Order: all Headstart attacks happen after Start of Combat, first attacker's side first, reading order within a side. At 0 Attack it is skipped (9.4.6), which is clean. No loop. Readable.
- **Budget review:** *March Hare* T1 3/1: body 4 + attacks first (E83 ≈ A(1) = 2) − the fade (E15 on itself ≈ −0.5; at 1 Health it rarely attacks twice) **[guess]** ≈ 5.5 against V(1) 5: +10%, in band (±15%).

### 24. Quick — NEW
- **Rules.** In an exchange, this deals its damage first. If that kills the other unit, this takes no damage from it. If both units are Quick, the exchange is simultaneous again.
- **Bends.** 9.6.1 step 3 and 9.6.2 (damage is simultaneous).
- **Creature.** Stoat. It kills with one fast bite; the Folio's stoat "war-dance troupe".
- **Archetype.** TALL and SCAM. A Quick carry trades for free against anything it can one-shot.
- **Example.** *Ermine Duellist*, Tier 3, 4/2. Quick. Works attacking and defending.
- **Fun against.** Big-Health units take the bite and hit back. Bristle still fires (the hedgehog was dealt damage), so a hedgehog is a cheap answer.
- **Check.** Neither game has it; Magic: The Gathering's first strike is the precedent. Galaxy's Ranged also avoids retaliation, but always and only when attacking.
- **From.** combat 16.
- **Rules review:** Changes 9.6.1 step 3 and 9.6.2. The exchange becomes two ordered strikes with a death check between, which fits a `strikeOrder` query. Define where splash and Bristle sit: splash lands with the Quick strike. Bristle still fires on a hedgehog the Quick strike kills, which needs Bristle's "dies but still pricks" to work across the death check. Peck plus Quick: all the pecks first. Both Quick: simultaneous. No loop. Readable only if the animation shows who struck first.
- **Budget review:** *Ermine Duellist* T3 4/2: body 6 + first strike ≈ Divine Shield's 3.0 at Tier 3 × the chance it one-shots (about 0.5–0.8 at Tier 3) ≈ 2.5 (proposed E90) **[guess]** ≈ 8.5 against V(3) 8: +6%, in band (±15%). Weaker late, as enemy Health grows.

### 25. Swarm — NEW
- **Rules.** When a Swarm unit attacks, every other Swarm unit in its row joins in and hits the same target at the same time. The target hits back only the unit that started the attack, and all of them count as having attacked this cycle.
- **Bends.** 9.4.1 and 9.4.5: one attack per side per turn, from one unit. The pointer is set by the leader and every joiner is flagged. 9.6.1: the exchange is no longer one against one.
- **Creature.** Honeybee and bumblebee. Bees mob an intruder together.
- **Archetype.** WIDE, built to beat TALL: five 1/1 bees deal 5 to the big unit and lose one bee. Cleave, splash and Curl are the natural answers.
- **Examples.** *Worker Bee*, Tier 1, 1/1. Swarm. *Drone Captain*, Tier 4, 3/3. Swarm. Your other Swarm units have +1 Attack while they join this one's attacks.
- **Fun against.** Easy to read (a cloud of bees goes for your big unit), with counters other tribes carry. It makes "wide against tall" a choice of form, not only of numbers.
- **Check.** No joint attacks in either game.
- **From.** creatures 5.
- **Rules review:** Changes 9.4.1, 9.4.5 and 9.6.1. Joiners are flagged, so a row of bees makes one joint attack a cycle; good. Left open: does a bee that is already flagged join a later leader (a bee summoned mid-cycle, 9.4.8)? Proposed: only unflagged bees join. Do stopped units (Mired, entranced) join? Joiners take Bristle and Curl pricks one by one, which is good counterplay; say so. Row only, so gaps don't matter. The pointer is the leader's. No loop. Readable as one cloud on one target.
- **Budget review:**
  - *Worker Bee* T1 1/1: body 2 + Swarm ≈ 0.6 (joiners skip retaliation; needs another Swarm unit in its row, × 0.6; proposed E90) **[guess]** ≈ 2.6 against V(1) 5: **−48%, flag (under, ±15%).** Change: 2/2 (4 + 0.8 ≈ 4.8, −4%). If the bee must stay 1/1, "on play: summon a 1/1 Worker Bee" (≈ 5.2).
  - *Drone Captain* T4 3/3: body 6 + Swarm 0.6 + +1 Attack to about 3 joiners × about 1.25 attacks it leads × 0.85 ≈ 3.2 ≈ 9.8 against V(4) 10: −2%, in band.

## H. Kills, overkill and survival

### 26. Gorge — VARIANT of Battlegrounds' Overkill and Wildfire Elemental
- **Rules.** When this kills a unit by attacking it, this gains Health equal to the excess damage.
- **Bends.** 9.6.3: excess damage below 0 is normally lost. Here it is a resource.
- **Creature.** Wolverine, the "mountain glutton" (Folio seed "The Gluttons").
- **Archetype.** TALL, a front carry that grows by fighting.
- **Example.** *Glutton Wolverine*, Tier 4, 6/4. Gorge.
- **Fun against.** It grows most on tiny tokens, so WIDE feeds it. Put sturdy medium units in front that die to exactly its hit, or a hedgehog that punishes each meal.
- **Check.** Overkill (retired) triggered on excess damage; Wildfire Elemental (current) deals the excess to a neighbour. Gorge is the same trigger paid to the attacker's Health. archetypes.md's Trample spends excess damage on space.
- **From.** combat 14.
- **Rules review:** Changes 9.6.3 (excess damage becomes a resource). Define excess as the damage after the pipeline (Shell, Halve and Knot all reduce it) minus the target's Health before the hit. With Peck, only the last peck has excess. The Health lasts this combat (12.1.2). No loop. Readable.
- **Budget review:** *Glutton Wolverine* T4 6/4: body 10 + about 0.8 kills a fight × about 2 excess damage → +1.6 Health this combat ≈ 1.5 (E03 on R23) **[guess]** ≈ 11.5 against V(4) 10: +15%, edge, no flag. If the Health is permanent, it is combat-triggered scaling (c_combat 2.1 × 1.6 ≈ 3.4 → +34%, over): then give it a cap ("up to +6 Health").

### 27. Bloodied — VARIANT of Battlegrounds' Frenzy
- **Rules.** Bloodied triggers once, the first time this unit's Health drops to half its maximum or lower and it survives.
- **Bends.** 9.6.3: adds a threshold between full Health and death.
- **Creature.** Wild boar. In hunting lore a wounded boar is the most dangerous animal in the forest.
- **Archetype.** TALL and STICKY.
- **Example.** *Wounded Tusker*, Tier 3, 3/6. Bloodied: double this unit's Attack.
- **Fun against.** Kill it in one hit and it never triggers; chip it and you get the angry version. The threshold stays half on a golden (7.3.5).
- **Check.** Frenzy (retired): "the first time this takes damage and survives". Bloodied moves the trigger to half Health.
- **From.** combat 17 (marked variant by the designer).
- **Rules review:** Adds a threshold to 9.6.3. Ambiguities: rounding of "half", and a maximum Health that changes mid-combat (losing an aura can trip it). It checks after the death check. Stat layers: "double this unit's Attack" as a multiplier also doubles every later buff. If a one-off is meant, write "gains Attack equal to its Attack". No loop. Readable.
- **Budget review:** *Wounded Tusker* T3 3/6: body 9 (+12% before text) + doubling its Attack once at half Health (E06 in combat; fires in about 0.7 of fights, with about one attack left) ≈ +2 **[guess]** ≈ 11 against V(3) 8: **+38%, flag (over, ±15%).** Change: 3/4 (7 + ≈ 1.5 ≈ 8.5, +6%).

### 28. Play Dead — VARIANT of Battlegrounds' Reborn
- **Rules.** The first time this would die each combat, it lies limp at 1 Health instead: it can't be attacked and skips its attacks, and the enemy's "after this kills" effects fire as if it had died. After the next enemy attack on a unit adjacent to it, it springs up and attacks that attacker immediately. If it is the last unit on its side, it springs up at once.
- **Bends.** 9.6.3: a unit at 0 Health doesn't die. 9.7.2: kill triggers fire with no death. 9.5: it leaves the candidate list. 9.4.12: it attacks out of turn. Random effects (9.5.6) can still hit it while limp, which is the counter.
- **Creature.** Fox. Reynard, in the old fables, plays dead by the road to catch the crows that come to peck him.
- **Archetype.** SCAM and STICKY. A second life that pays off with an ambush rather than a return.
- **Example.** *Reynard's Clerk*, Tier 3, 3/3. Play Dead. When this springs up, it has +4 Attack for that attack.
- **Fun against.** The enemy's on-kill unit fires and celebrates, then the fox gets up. Random damage and splash are clear answers.
- **Check.** Reborn is a second life at 1 Health. Play Dead keeps the unit, hides it, and fakes the kill. Battlegrounds' Adaptable Barricade (retired) also survives at 1 Health.
- **From.** creatures 14. **Name clash:** combat's Alibi example is also *Reynard's Clerk*.
- **Rules review:** Changes 9.6.3, 9.7.2, 9.5 and 9.4.12, the most hooks of any one unit here. Limp is an in-slot inactive state (R7). Ambiguities: the enemy's kill effects fire, but do your own death counters (9.7.4) and "whenever a friendly unit dies" also fire? The spring-up attack happens inside an enemy attack, so queue it after that attack's death pass (R5). With no adjacent unit (gaps, 8.2.2) it only springs when it is last, and "last" should be R3's "no other friendly unit can attack". A side with only a limp fox isn't empty for 9.9.1. No loop: once per combat. Readable as a lying-down sprite.
- **Budget review:** *Reynard's Clerk* T3 3/3: body 6 + a second life (Reborn-like, 0.4 × body ≈ 2.4, E20; proposed off-slot state E96 while limp) + the ambush with +4 Attack (≈ 4 × 0.85 × 0.8 chance it springs) ≈ 2.7 **[guess]** ≈ 11.1 against V(3) 8: **+39%, flag (over, ±15%).** Change: 2/3, and +2 Attack on the ambush (5 + 2.0 + 1.4 ≈ 8.4, +5%).

### 29. Last Word — NEW
- **Rules.** If a death resolution would leave both boards empty and this is among the dying, it survives with 1 Health instead. If combat would end because neither side can attack, this gains +1 Attack and combat goes on.
- **Bends.** 9.9.1 and 9.9.2: both ways a fight ties.
- **Creature.** Wren. The wren hid on the eagle's back, flew highest and was crowned king of birds for being the last one up (Folio hook "A small unit rides a big one").
- **Archetype.** STICKY and SCAM. A tie-breaker that turns draws into wins.
- **Example.** *Jenny Wren*, Tier 2, 1/2. Last Word.
- **Fun against.** Kill the wren before your last unit trades. It breaks Whistle-only boards and Hunker walls that would stall. The 200-attack limit (9.10.1) still ends any fight that runs on.
- **Check.** Nothing in either game acts on ties.
- **From.** combat 18.
- **Rules review:** Changes 9.9.1 and 9.9.2. Needs "once per combat". Two Last Word wrens trading with each other both survive every time, and the fight runs to the 200-attack tie. The "+1 Attack and combat goes on" clause loops when nothing can attack for another reason (Mired, entranced, Curl), until the 10,000-trigger limit (9.10.2). Write "once per combat, and only if that lets a unit attack". Readable only when it fires, which is rare.
- **Budget review:** *Jenny Wren* T2 1/2: body 3 + Last Word ≈ 0.3 (chance of a tie with the wren in the last exchange, times a win's value over a tie; proposed E92) **[guess]** ≈ 3.3 against V(2) 7: **−53%, flag (under, ±15%).** Change: Tier 1 at 2/2 (≈ 4.3, −14%), or Tier 2 at 2/4 (≈ 6.3, −10%).

### 30. Bud — VARIANT of Battlegrounds' Silver Goose
- **Rules.** Whenever this survives damage, it splits: it loses half its current Attack and Health (rounded down), and a copy with that half and the same text appears in the nearest empty slot. Split copies are combat-only.
- **Bends.** 9.6.3: damage normally only lowers Health; here it also makes bodies. 8.4.2: where the bud lands. No stats are created: an 8/12 that takes 2 becomes two 4/5s. A full board means no split.
- **Creature.** Ooze. Oozes are unstable magic slime; real slime moulds split and rejoin.
- **Archetype.** TALL in the shop (one big blob to pump), WIDE in the fight once it is hit. One answer to archetypes.md question 14 (merge or split): grow by merging, fight by splitting.
- **Example.** *Pudding Ooze*, Tier 4, 6/10. Bud.
- **Fun against.** Chip damage makes it worse; one big hit that kills it, or Cleave, solves it.
- **Check.** Silver Goose (retired): "Whenever this takes damage, summon a 2/2 Fledgling with Taunt." Bud divides itself instead of making new stats. **Overlaps** archetypes.md's Ooze "Split" (on death).
- **From.** creatures 7.
- **Rules review:** Changes 9.6.3 and summons (8.4.2). Needs a minimum: a 1-Health bud loses 0 and makes a 0-Health copy. Proposed: no split below 2 Health. Copies are summons, so Delivery (+1/+1 each split) and Sett or Fallow add stats, Mark damages them, and 9.4.8 sets their flags. Peck plus Bud fills the board in one attack, one split per peck. It is bounded by the 7 slots. No loop beyond that. Readable: one blob becomes two.
- **Budget review:** *Pudding Ooze* T4 6/10: body 16 (+60% before text) + Bud ≈ 1.5 (no stats are made; more bodies and attacks against chip damage, worse against Cleave; proposed E95) **[guess]** ≈ 17.5 against V(4) 10: **+75%, flag (over, ±15%).** Change: 4/5 (9 + 1.5 ≈ 10.5, +5%). 6/10 stays over even at Tier 6 (≈ 17.5 against 14).

## I. Extra bodies, off-slot zones and switching sides

### 31. Ride — VARIANT of Battlegrounds' Magnetic plus a Deathrattle summon *(merged with Stowaway)*
- **Rules.** Play this onto a friendly unit instead of into a slot (Ride: one with more Attack). It rides that unit, uses no slot and can't be targeted; one rider per mount, and it can be played onto a full board. When the mount dies, the rider leaps into the mount's slot before the mount's own death effects summon anything (those go to the nearest empty slot), and attacks immediately.
- **Bends.** 8.1.1 and 7.2.2: the board can hold more than 7 bodies. 8.4.1: the rider jumps ahead of the mount's own summons. 9.4.12: it attacks out of turn.
- **Creature.** Wren, from the fable of the wren on the eagle's back (Folio hook "Rider"). The Folio's mice "ride larger allies into battle".
- **Archetype.** STICKY (each host takes two kills) and WIDE (more bodies than slots).
- **Examples.**
  - *Wren King*, Tier 2, 2/1, Bird. "Stowaway. When this leaps out, it attacks immediately." (rows)
  - *Wren King*, Tier 2, 2/1. Ride. When this leaps, it has +2 Attack. (creatures)
- **Fun against.** You drop their bear and a tiny wren bursts out of its fur and pecks your damaged unit to death. Riders are drawn on their hosts, so you can count them. Proposal (creatures): Cleave and splash hit the rider too.
- **Dials.** Stowaway had no "more Attack" limit and didn't attack on leaping by itself; Ride had both.
- **Check.** Magnetic also uses no slot, but fuses for good; a Deathrattle summon also fills the slot. The rider stays itself and separates on death.
- **Other names.** Stowaway (rows 6); Pouch (pelican, cut from creatures as too close).
- **From.** creatures 10, rows 6 (both marked variant by their designers).
- **Rules review:** Changes 8.1.1 and 7.2.2 (more than 7 bodies), and adds a step to 9.7.2: riders leap after 9.7.1 and before the mount's own death effects. Needs a no-slot zone in the geometry module (R7). Does a rider count for 9.2.1, hero damage (10.1.1), triples, Start of Combat, its own auras, and random enemy effects (9.5.6)? What happens to it when the mount is sold, moved or tripled away? Several mounts dying together: riders leap in 9.7.3 order. Its attack comes from inside death resolution (R5). No loop. Readable as a rider drawn on its host, though crowded on a full board.
- **Budget review:**
  - *Wren King* (rows) T2 2/1: body 3 realised × 0.9 (it enters when the mount dies) + attacks at once ≈ 1.2 (E83) + no slot used ≈ 1 (E23) **[guess]** ≈ 4.9 against V(2) 7: **−30%, flag (under, ±15%).** Change: 3/2 (4.5 + 1.5 + 1 ≈ 7.0, 0%).
  - *Wren King* (creatures) T2 2/1, +2 Attack on leaping: 2.7 + 2.4 + 1 ≈ 6.1: −13%, in band.
  - Both rest on E23's "+1 SP for a saved slot", which likely under-prices an eighth body on a full late board (power-budget 6.4: one unit is worth 21–23 points of win rate). Sim riders before printing one above Tier 2 (proposed E96).

### 32. Burrow — VARIANT of Battlegrounds' Deity
- **Rules.** Start of Combat: this goes underground. It leaves its slot and can't attack, be attacked or be hit by any effect. After the first friendly death, it surfaces in that unit's slot (or the nearest empty one) and attacks immediately.
- **Bends.** 9.1.2: this unit is in combat but on no slot, a new zone. 9.4.12: it attacks out of turn when it surfaces. Units are counted for who attacks first (9.2.1) before it digs.
- **Creature.** Mole. Moles come up where you don't expect them; the Folio's "velvet conspirators" had a molehill topple a king.
- **Archetype.** WIDE and STICKY: a refill safe from Start of Combat damage. If the dead unit's own summon takes the slot (8.4.1), the mole takes the nearest one.
- **Example.** *Velvet Sapper*, Tier 3, 4/3. Burrow. When this surfaces, it has +3 Attack for that attack.
- **Fun against.** You know the mole is coming (its slot is empty and a molehill shows), so the first kill is a choice.
- **Check.** Battlegrounds' Deity (Aberrations, current) stays off the board and joins the combat after 4 friendly Aberration deaths. Burrow starts on the board, hides, and comes up after one death.
- **From.** creatures 3.
- **Rules review:** Changes 9.1.2 (a combat unit with no slot, R7) and 9.4.12. Ambiguities: does the slot it left accept summons? The molehill suggests not, the text suggests yes. It should surface before the 9.9.1 empty-board check, so a side whose last slotted unit dies isn't counted as empty. If no friendly unit dies, does it count for hero damage (10.1.1)? It can surface into a Mark or an Egg slot. No loop. Readable: a molehill.
- **Budget review:** *Velvet Sapper* T3 4/3: body 7 + surfacing after the first friendly death and attacking at once with +3 Attack (≈ 1.5 for the early attack + ≈ 2.5 for the bonus) − an empty slot at Start of Combat (≈ 0.5) ≈ 3.5 (proposed E96; E83) **[guess]** ≈ 10.5 against V(3) 8: **+31%, flag (over, ±15%).** Change: 3/2, keeping +3 Attack (5 + 3.5 ≈ 8.5, +6%).

### 33. Changeling — NEW
- **Rules.** Start of Combat: this swaps places with the enemy unit across from it, and each fights for its new side this combat. If the slot across is empty, nothing happens.
- **Bends.** 9.1.1: each side fights with its own copied board; here a unit fights for the other side. 8.2.6: across from. 10.1.1: proposal: a swapped unit counts for the side it ended the fight on. The most rule-breaking idea on the list.
- **Creature.** The folklore changeling: fairies take a child and leave one of their own in its place.
- **Archetype.** SCAM. The changeling is a weak body, and the enemy's unit fights for you.
- **Example.** *Changeling Babe*, Tier 4, 1/1. Changeling.
- **Fun against.** Your own unit hitting your board is a memorable story. Defend by position: put a cheap unit in the mirrored slot. In async play it plays as a random theft unless the player sees the snapshot.
- **Check.** No unit changes sides in either game. **Overlaps** archetypes.md's Fairy "Changeling" (a copy of the unit behind), which is a different mechanic with the same name.
- **From.** creatures 8.
- **Rules review:** Changes 9.1.1 and ownership: a unit gets a combat side apart from its owner (R10). Every friendly/enemy selector, death effect, summon and death counter must read the combat side, and "permanently" on a swapped unit must not write to the other player's board (R9). Two Changelings across from each other swap twice in 9.3.2 order and undo each other. Its result against Rival or Flush depends on random Start of Combat order (R8). No loop. The hardest to read on the list without strong side colours.
- **Budget review:** *Changeling Babe* T4 1/1: body 2 + the swap: you gain the unit across and they lose it, less the two 1/1s, × 0.9 chance the slot is filled ≈ 9 at turn 6 (a unit of about 7 SP), ≈ 20 at turns 10–12 (13–17 SP) (proposed E94) **[guess]** → ≈ 11 against V(4) 10 at its tier's turn (+10%), about +120% late: **flag (over; it scales with the enemy's board, ±25%).** Change: 2/2, and only if the enemy unit across has 6 Attack or less (about 0.7 of units at turn 6, about 0.4 late): ≈ 10.3 at turn 6, ≈ 9.8 late. Their biggest carry is then safe; mid-size units still change sides.

### 34. Brood — NEW
- **Rules.** Start of Combat: lay an Egg in the empty enemy slot across from this, or in the nearest empty enemy slot if that one is full. The Egg belongs to neither side: it can't attack or be attacked, protects nothing, and only takes up the slot. After the enemy side has made 3 attacks, it hatches into a 3/3 Cuckoo Chick for you, in your empty slot nearest this unit.
- **Bends.** 8.4: summons land only on their own side; Brood puts an object on the enemy board and fills their summon space. 9.9.1: the Egg is not a unit, so it never keeps a board alive.
- **Creature.** Cuckoo, the brood parasite (Folio hook "Sabotage").
- **Archetype.** An answer to WIDE, whose summons need empty slots; a SCAM-like spice.
- **Example.** *Cuckoo*, Tier 3, 2/2, Bird. "Brood." Golden: two Eggs.
- **Fun against.** Your Deathrattle-style tokens fizzle because an egg sits where they wanted to land. Leave a decoy gap, or use Delivery.
- **Check.** Galaxy's Mysterious Egg and Battlegrounds' Lockbox share only the egg; neither touches the enemy board.
- **Other versions.** Creatures-first cut its own Brood (the Egg hatches mid-fight and pushes out its neighbours) because it needs the same "unit on the other side" ruling as Changeling.
- **From.** rows 7.
- **Rules review:** Changes 8.4 with an object on the enemy board (R7). Ambiguities: the Egg "belongs to neither side" but sits on the enemy board. It blocks their summons (yes, the point) but doesn't count as front for 9.5.1 (as written). Does it stop Caravan stepping in or Cleave splashing? Does "after 3 enemy attacks" count extra attacks? A dead cuckoo hatches from its last slot (12.2.3). A full board means the hatch fails (8.4.5). No loop. Readable: an egg in their gap.
- **Budget review:** *Cuckoo* T3 2/2: body 4 + 3/3 chick (E30: 6 × 0.8) × your empty slot by then (≈ 0.8) × an empty enemy slot at Start of Combat (≈ 0.9 on turns 4–6, ≈ 0.3 on full boards) + blocked enemy summon space ≈ 0.5 (proposed E97) **[guess]** ≈ 8 at turns 4–6 (0%), ≈ 5.2 late (−35%). In band at its turns (±15%); weak late, by design.

## J. Moving your own units in combat

*Flush (19) and Jink (22) also move units. archetypes.md proposes Tunnel for a Digger calling; if only one group should move units, these compete with it.*

### 35. Caravan — VARIANT of Battlegrounds' board packing
- **Rules.** In combat, whenever the slot to the left of this unit in its row is empty, it steps into it at once. Several Caravan units in a row step one after another, so a line closes up.
- **Bends.** 8.3.4 (no packing): packing comes back as a keyword, for one tribe. A unit that moves keeps its attack flag, and stepping into a slot below the attack pointer flags it (9.4.9), so a fast-closing line can lose attacks.
- **Creature.** Shrews. Young shrews travel in a line, each holding the next one's tail (Folio hook "Formation").
- **Archetype.** WIDE and MEDIUM. It keeps adjacency chains whole after deaths.
- **Example.** *Shrewlet Train*, Tier 1, 2/1, Shrew. "Caravan. After this steps, gain +1 Attack this combat."
- **Fun against.** Your Cleave (11.2.7) loves them: the line keeps closing, so every hit has neighbours to splash. As they shuffle left they empty the slots your across-from effects were facing.
- **Check.** Battlegrounds packs every board by rule; Caravan is that rule as a per-unit keyword, leftward within a row only.
- **From.** rows 3.
- **Rules review:** Changes 8.3.4 (packing comes back, per unit). Timing problem: 9.7.1 empties a dying unit's slot before any trigger, so a Caravan unit stepping "at once" takes the slot before the dying unit's own summon can (8.4.1). Say Caravan steps after death resolution ends, left to right. Stepping below `P` flags it (9.4.9). It steps onto Marks and is blocked by Eggs. No loop, since moves only go left. Readable.
- **Budget review:** *Shrewlet Train* T1 2/1: body 3 + stepping ≈ 0.3 (E32) + +1 Attack after a step (about one step a fight, ≈ 0.5 realised) **[guess]** ≈ 3.8 against V(1) 5: **−24%, flag (under, ±15%).** Change: 2/2 (≈ 4.8, −4%).

### 36. Rotate — NEW
- **Rules.** After this attacks, if it is still alive, it swaps places with the friendly unit behind it that has the most Health. The unit that comes forward keeps its own attack flag.
- **Bends.** 9.5.1: the back row becomes a place to rest mid-fight. 8.3.5 and 9.4.9 cover the swap.
- **Creature.** Geese. A V of geese rotates the bird at the point so the lead is shared; the Folio's goose "flies in a V; aggressive".
- **Archetype.** STICKY (wounded units retire behind cover) and MEDIUM (fresh back units get time in front).
- **Example.** *Lead Goose*, Tier 3, 4/4, Bird. "Rotate. A unit that swaps forward with this gains +2 Attack this combat."
- **Fun against.** Their 1-Health goose slips into the back just before you'd kill it, so your back-row reach has a target. The swap also pulls their fragile support forward.
- **Check.** No unit moves itself in either game's combat.
- **From.** rows 4.
- **Rules review:** Changes 9.5.1 through a geometry swap (8.3.5). Ambiguities: a back-row goose has no one behind it, so nothing happens; a tie for most Health goes to reading order. The unit brought forward lands in slot `P` unflagged, so 9.4.5 makes it its side's next attacker. It would have attacked later in the cycle anyway, so there is no extra attack, but the order changes. No loop. Readable.
- **Budget review:** *Lead Goose* T3 4/4: body 8 (on V(3) before text) + rotation (a wounded attacker rests in the back, ≈ 1, E32) + +2 Attack to the unit that comes forward (it survives about half its attacks: ≈ 0.5 × 1.8, E01) ≈ 2 **[guess]** ≈ 10 against V(3) 8: **+25%, flag (over, ±15%).** Change: 3/4 (≈ 9, +12%).

### 37. Bolt — NEW
- **Rules.** The first time this survives damage in a combat, it bolts: it moves into an empty back slot behind it. If no slot behind it is empty, it stays.
- **Bends.** 9.5.1: a unit leaves the targetable row by itself. Its place in the attack order follows 9.4.9. The front gap it leaves is summon space (8.4).
- **Creature.** Rabbits. They thump a warning and vanish down the warren (Folio: "Thumps to warn the warren"; *Watership Down*).
- **Archetype.** STICKY and WIDE (the gap it leaves gets refilled).
- **Example.** *Warren Lookout*, Tier 1, 1/3, Rabbit. "Bolt. After this bolts, summon a 1/1 Kit into the slot it left."
- **Fun against.** The bunny runs and a kit pops out of the hole. A rabbit board has to leave back gaps for its bolt holes, and you can see them.
- **Check.** The trigger is Frenzy's ("survives damage"), but no unit retreats in either game.
- **From.** rows 5.
- **Rules review:** Changes 9.5.1 (a unit retreats by itself). Ambiguities: F2 and F3 have two back slots behind them; which one? A back-row unit has nothing behind it. It checks after the death check. A move into a back slot above `P` keeps the flag (9.4.9), so no extra attack. No loop: once per combat. Readable.
- **Budget review:** *Warren Lookout* T1 1/3: body 4 + (bolting ≈ 0.5 + a 1/1 Kit ≈ 1.6, E32 + E30) × survives a first hit ≈ 0.7 × an empty back slot ≈ 0.8 ≈ 1.2 **[guess]** ≈ 5.2 against V(1) 5: +4%, in band (±15%). Blank on a full board.

## K. Slots, gaps and terrain

*The owner: "We have set slots, so we can experiment with slot buff mechanics." Galaxy's slot buffs and Paint are the precedent (design-notes §5, ideas 9 and 12).*

### 38. Sett — RESKIN of Galaxy's slot buffs
- **Rules.** End of Turn: this unit's slot gains +1/+1 Sett. The Sett belongs to the slot, not the unit: whatever unit stands there, now or later, has its stats, including units summoned into it mid-combat.
- **Bends.** 12.2.1: auras end when their source leaves; a Sett outlives the badger. 8.2.4: "relations belong to slots" extends to stats.
- **Creature.** Badgers. Setts are dug over generations and handed down; the Folio's "faded gentry, landlords of ancient setts".
- **Archetype.** MEDIUM and TALL, with the slot as the landing. A soft WIDE payoff, since a token summoned into a dead unit's slot (8.4.1) moves into a mansion.
- **Example.** *Old Brock*, Tier 2, 2/4, Badger. "Sett. When you sell this, its slot's Sett gains +2/+2."
- **Fun against.** Killing the unit in their big slot doesn't end the threat: the next token that moves in is huge too. You read their *slots* as the threat.
- **Check.** Galaxy's slot buffs already stay on the slot for whoever stands there, summons included, and Galaxy cards give them from many triggers (Candy Claws: "Hunt — Give my slot +1/+1"; The Sour Patch Kid: "When I'm attacked, give my slot +1/+1"). Sett is a slot buff on an End of Turn trigger. The designer called it a variant because it grows only while lived in; that is the trigger, not a new rule. Still a good fit for the owner's slot-buff ask.
- **From.** rows 1 (marked variant by the designer).
- **Rules review:** Uses 8.5 slot effects as written, so it is clean and bends no rule once 8.5 exists. Engine: slot effects feed the stat layers as an addition read from the slot. Growth is unbounded but linear. Readable if slots show their buffs, a UI every slot idea needs.
- **Budget review:** *Old Brock* T2 2/4: "End of Turn: slot +1/+1" is s = 2 SP a turn, over the Tier-2 growth cap of 1.3; E16 adds × 1.1 because the slot keeps it: 3.7 × 2 × 1.1 ≈ 8.1, plus +2/+2 on sale ≈ 4.4 → ≈ 18.5 against V(2) 7: **+164%, flag (over the growth cap, ±25%).** This is power-budget's own example: unconditional "+1/+1 every turn" fits from Tier 4 (3.2). Change: Tier 4, 1/1, sale gives +1/+1 (2 + 3.1 × 2 × 1.1 + 2.2 ≈ 11, +10%). Or keep Tier 2 with "+1 Health a turn" and +1/+1 on sale, 1/1 (≈ 8.3, +19%).

### 39. Bury — VARIANT of Galaxy's slot buffs *(merged with Fallow)*
- **Rules.** Empty slots on your board hold a pickup that the first unit to enter takes. Two versions were written:
  - **Nut** (Bury, creatures): End of Turn: this buries a Nut in a random empty slot on your board (at most 3 Nuts on a board). The first unit to enter a Nut's slot eats it for +1/+1 permanently. A Nut nobody eats for 3 of your turns sprouts into a 1/2 Oakling in that slot.
  - **Ripening** (Fallow, rows): while this is on your board, at End of Turn each empty slot gains +1/+1 Fallow (up to +3/+3). The first unit to enter a fallow slot harvests it: in the Recruit Phase it keeps the Fallow permanently and the slot resets; in combat, a summon takes it for that combat only.
- **Bends.** 8.1 and 8.3.1: a slot holds something that isn't a unit, so a gap becomes a resource rather than a missing body. 9.1.1: because combat runs on a copy, a pickup taken in combat is still there afterwards, so a ripe or nutted gap feeds a combat summon every fight until a recruit unit takes it. Both designers say this is intended.
- **Creature.** Red squirrels and jays scatter-hoard and forget many caches, which grow into trees (the Folio's Acorn Exchange; jays as "Investment"). The farmer's field left fallow comes back richer.
- **Archetype.** WIDE (Deathrattle-style summons and Delivery land in ripe slots) and ECO (a delayed free unit). It rewards fielding fewer units for a few turns.
- **Examples.**
  - *Hoarder Squirrel*, Tier 1, 1/2. Bury.
  - *Jay Forester*, Tier 3, 3/3, Bird. "Fallow. Start of Combat: summon a 1/1 Oakling into your empty slot with the most Fallow."
- **Fun against.** Their board looks thin, then every death fills a ripe gap with a buffed sapling. A board with holes that will fill on a known turn gives a window to punish it.
- **Check.** A Galaxy slot buff on an *empty* slot, used up by the first unit to enter. Galaxy's slot buffs stay for every later occupant. **Overlaps** archetypes.md's Hedgerow Acorns (cards in hand) and the Fairies' Fairy ring (a slot enchantment grown by spells).
- **Other names.** Fallow (rows 2).
- **From.** creatures 2, rows 2.
- **Rules review:** Changes 8.1 and 8.3.1 with pickups (R7). Needs a "unit enters slot" event in the geometry module that covers playing, moving, summoning and returning. Fallow: free moves (8.3.3) let one unit walk through every ripe slot in one turn and harvest them all permanently. Add "a unit harvests at most once per turn", or count only playing a unit in. The combat copy keeps pickups for the next fight, as intended. A sprouting Nut is a Recruit Phase summon (8.4.7) and Created. No loop. Readable: a nut in a gap.
- **Budget review:**
  - *Hoarder Squirrel* T1 1/2 (Nut): a Nut a turn is about +1/+1 for the next unit placed while you have gaps: s ≈ 2 × 0.8 = 1.6 SP a turn, twice the Tier-1 growth cap (0.8); 3.9 × 1.6 ≈ 6.2 + Oakling ≈ 0.5 (E16, proposed E97) → ≈ 9.7 against V(1) 5: **+94%, flag (over the growth cap, ±25%).** Change: Tier 2, 1/1, same text (s ≈ 1.4, at the Tier-2 cap: 2 + 5.2 + 0.5 ≈ 7.7, +10%). The price depends on whether moving a unit in the Recruit Phase "enters" a slot: if it does, any unit can eat each Nut.
  - *Jay Forester* T3 3/3 (Fallow): every empty slot ripens +1/+1 a turn (up to +3/+3), about 3–4 SP a turn mid-game, about twice the Tier-3 cap of 1.7 (≈ 10); and the Start of Combat Oakling takes up to +3/+3 every fight, because a pickup taken in combat stays (Bends): a 4/4 token ≈ 5 a fight → ≈ 21 against V(3) 8: **+160%, flag (over the growth cap, ±25%).** Change: Tier 4, 1/1, "At End of Turn, your empty slot with the least Fallow gains +1/+1 Fallow (up to +2/+2)": one slot a turn (s = 2, under the Tier-4 cap 2.5) ≈ 3.1 × 2 × 1.1 × 0.7 (a gap exists) ≈ 4.8, Oakling up to 3/3 ≈ 3.4 → ≈ 10.2 (+2%).

### 40. Mark — NEW
- **Rules.** Start of Combat: scent-mark the enemy slot across from this. For the rest of combat, each enemy unit that enters a marked slot takes 3 damage.
- **Bends.** 8.2.4: slot relations turned against the enemy, a hostile slot effect that stays when the unit there changes. It punishes 8.4.1 (a death summon takes the dead unit's slot first) and 9.8.3 (a returning unit comes back to its own slot).
- **Creature.** Wolves and foxes scent-mark territory. In the Folio, Hunters "follow wolves to kills".
- **Archetype.** An answer to WIDE and STICKY, which refill and return into their own slots.
- **Example.** *Gubbio Wolf*, Tier 2, 3/2, Hunter. "Mark. After an enemy dies in a marked slot, this gains +1/+1 this combat."
- **Fun against.** Your Reborn-style rabbit pops back into its slot, steps on the scent and dies again. Counter with a summoner that lands elsewhere, or Caravan units that step out.
- **Async.** No aiming is needed: refills go into the dead unit's own slot, so whatever stands across is the slot that gets refilled.
- **Check.** No hostile slot effects in either game.
- **From.** rows 8.
- **Rules review:** A hostile slot effect on the enemy board. 8.5 needs an owner for slot effects made in combat (8.5.2 only copies each board's own). It uses the enters-slot event, so every move and summon triggers it, including Caravan, Jink, Rotate, Flush and returns. A Caravan line stepping into a Mark dies one unit at a time; bounded. No loop. Readable: scent on their slot.
- **Budget review:** *Gubbio Wolf* T2 3/2: body 5 + 3 damage to units that refill the marked slot (≈ 0.3 a fight outside summon builds, ≈ 0.8) + +1/+1 when the marked unit dies (it usually does; the wolf is alive about half the time, ≈ 0.9) ≈ 1.7 (proposed E97) **[guess]** ≈ 6.7 against V(2) 7: −4%, in band (±15%).

### 41. Solitary — NEW
- **Rules.** While no friendly unit is a neighbour of this one (8.2.3: adjacent, in front or behind), it has double Attack. This is checked all the time, so it can wake mid-combat when its neighbours die.
- **Bends.** 8.2.3 and 8.3.1: almost all position text rewards clustering; Solitary rewards gaps.
- **Creature.** Wildcats, solitary and untameable (Folio: Clan Chattan's "touch not the cat"). Lynxes would fit too.
- **Archetype.** TALL. One carry in a clearing.
- **Example.** *Scottish Wildcat*, Tier 4, 4/6, Hunter. "Solitary. Start of Combat: if this is alone, gain +3 Health."
- **Fun against.** Kill order becomes drama: clear the units around it and it wakes up doubled.
- **Check.** Galaxy's Underdog rewards having fewer units than the enemy, which is a board count, not a neighbour test. Galaxy design-notes §5 idea 12 suggests "If the slot beside me is empty, +2 Attack" as a Bramble idea.
- **From.** rows 15.
- **Rules review:** Only reverses the reward of 8.2.3. Clean as a stat-layer aura that is recalculated when the board changes (12.2.1). Define neighbours as units only, so Thickets, Eggs and riders don't count (R7). As a multiplier it also doubles later buffs. No loop. Readable.
- **Budget review:** *Scottish Wildcat* T4 4/6: body 10 + double Attack once its neighbours are dead (about 0.5 of fights, about one attack: ≈ 1.7, E06 with C02) + Start of Combat +3 Health only if alone (≈ 0.3: it needs gaps, which cost a unit late, 6.4) **[guess]** ≈ 12 against V(4) 10: +20%, edge, no flag. If the sim agrees, 4/5. Stronger on turns with gaps.

### 42. Migrate — NEW
- **Rules.** End of Turn: this moves to the next empty slot after its own in reading order (wrapping from B3 to F1) and gains +1/+1 permanently. If there is no empty slot, it stays and gains nothing.
- **Bends.** 8.3.3: the player places units freely; a Migrate unit places itself, and the player steers it only by choosing which slots to fill. It reads position at End of Turn (archetypes §3 rule 2).
- **Creature.** Lemmings and their "cheerful, endless tide" (Folio take "The Great Migration"); their doom cult, "believers in the cliff".
- **Archetype.** MEDIUM scaling with a cost: it needs empty slots.
- **Example.** *Cliff-cult Lemming*, Tier 2, 1/1, Lemming. "Migrate. If this would migrate past B3, it leaps instead: remove it and give your other units +1/+1 permanently."
- **Fun against.** Their board shape shifts every turn, and you can see the lemmings marching towards B3 and know when the buff turn comes.
- **Check.** No unit moves itself between turns in either game.
- **From.** rows 16. The recruit list's stork "Migrate" is a different mechanic, renamed Fly South (60).
- **Rules review:** Changes 8.3.3 (a unit places itself). Ambiguity: with several migrators, 3.4.1 resolves End of Turn in reading order, so a lemming that moves to a later slot could trigger twice. List the triggers before any move. Define "past B3" as "the next empty slot can only be reached by wrapping". It steps into Bury and Fallow slots. No loop. Readable.
- **Budget review:** *Cliff-cult Lemming* T2 1/1: +1/+1 a turn while a slot ahead is empty: s ≈ 2 × 0.7 = 1.4 SP a turn (the Tier-2 cap is 1.3): 3.7 × 1.4 ≈ 5.2 (E02, E32) + the leap (+1/+1 to about 5 others ≈ 9 SP, less its own body, × about 0.4 chance it gets there ≈ 1.6) **[guess]** ≈ 8.8 against V(2) 7: +26% (±25%: scaling), edge, no flag. Sim the leap turn.

### 43. Stance — VARIANT of Battlegrounds' Choose One
- **Rules.** This unit has two stat lines, or two texts: one for the front row and one for the back row. It uses the one for the row it is in, and switches at once if it changes row.
- **Bends.** 8.2.7 and 7.2.1: a row becomes a mode switch. 12.2.1's "recalculated whenever the board changes" now covers a unit's own stats, so moves in combat (Rotate, Bolt, Flush) flip it mid-fight.
- **Creature.** Bats. Aesop's bat belongs to neither birds nor beasts and changes sides to suit itself (Folio take "Double agents").
- **Archetype.** Any; a building block that lets one card serve two roles. Most natural in MEDIUM.
- **Example.** *Double-agent Bat*, Tier 3, Bat. "Front: 5/2. Back: 2/5, and the units in front of this have +1 Attack."
- **Fun against.** Flush their bat into the front row and their sturdy aura-bat becomes a 5/2 glass cannon.
- **Check.** Choose One picks one of two modes once, when played. Stance picks by row and keeps switching. keywords.md §C suggests "Choose One by placement"; Stance is that as a lasting state.
- **From.** rows 17.
- **Rules review:** Changes 7.2.1 and 8.2.7 through a stat-layer "set base stats" handler keyed on row. Damage stays when it switches: a back 2/5 with 3 damage moved forward becomes 5/2 at -1 Health and dies. State that a switch can kill (death check after a move); Flush and Rotate will use it. No loop. Readable, though two stat lines on one card are busy.
- **Budget review:** *Double-agent Bat* T3: front 5/2 = 7 (−12%); back 2/5 = 6.5 + "+1 Attack to the units in front" (the rows study measured 1.9 SP for that on Lantern Moth) = 8.4 (+5%). In band in either row (±15%). No new class: a body with a row condition (C02).

### 44. Delivery — NEW
- **Rules.** While this lives, your summons from any source go into the empty slot nearest this unit, instead of the dead unit's slot or the slot nearest their source. Delivered units gain +1/+1.
- **Bends.** 8.4.1–8.4.3, summon placement. A summon's attack timing depends on where it lands (9.4.8), so steering summons also steers when they attack.
- **Creature.** Storks, the bringers of babies, who bring luck to the roof they nest on. Hedgerow folk could share it.
- **Archetype.** WIDE. It sends tokens into protected back slots, ripe Bury slots or a Sett, and out of Marks and Eggs.
- **Example.** *Rooftop Stork*, Tier 4, 2/5, Bird. "Delivery."
- **Fun against.** Their babies never appear where the parent died. Kill the stork and placement snaps back to normal, right into your marked slots.
- **Check.** No summon-placement control in either game. Galaxy's Geppetto buffs a summon's slot but doesn't move it.
- **From.** rows 18.
- **Rules review:** Changes 8.4.1–8.4.3. Clean as a `summonSlot` query handler at the unit layer. Ambiguities: two storks (first in reading order); does it cover returns (9.8.3) and Ride or Burrow arrivals? Proposed: summons only. Each Bud split gains +1/+1, which adds stats, bounded by the board. No loop. Readability is medium: summons land away from where players expect.
- **Budget review:** *Rooftop Stork* T4 2/5: body 7 + +1/+1 per summon (R26: 0.5 a fight, 2 in a summon build) × 0.8 + placement control ≈ 0.5 (E32, E01) **[guess]** ≈ 8.3 outside summon builds (−17%), ≈ 10.7 in one (+7%). In band for the build it serves (±15%); no flag.

### 45. Both Ends — NEW
- **Rules.** While a friendly unit with Both Ends stands at the other end of this row (F1 and F4, or B1 and B3), each has +1/+2, and whenever one of them is attacked, the other deals 2 damage to the attacker.
- **Bends.** 8.2.2: adjacency never skips a gap; this relation spans a whole row, gaps and all. It gives the flank slots (F1 and F4, 8.2.1) a job the centre can't do. 8.2.5: ends are per row.
- **Creature.** Hedgehogs. In Grimm's *The Hare and the Hedgehog*, the hedgehog's wife waits at the far end of the furrow (Folio take "Twin tricksters"). The owner's thorn idea, struck from the far end.
- **Archetype.** MEDIUM and STICKY.
- **Example.** *Hedgehog Twin*, Tier 2, 2/3, Hedgerow folk. "Both Ends."
- **Fun against.** You hit the hedgehog on the left, and the one on the far right pricks you. Kill one twin and the other loses its bonus.
- **Check.** No end-to-end relation in either game; Galaxy uses neighbours, in front, behind and across.
- **From.** rows 14.
- **Rules review:** Changes 8.2.2 (a row-wide relation through gaps). Timing: "whenever one is attacked" is 9.6.1 step 1, so the 2 damage can kill the attacker before the exchange. 9.6.1 needs an "attacker gone" line to match its "defender gone" line. It is a reflect (R2). Ends are per row: a twin in F1 and one in B3 aren't ends of the same row. No loop with R2. Readable.
- **Budget review:** *Hedgehog Twin* T2 2/3: body 5 + (+1/+2 ≈ 3, + 2 damage when attacked ≈ 1.5) × about 0.4 chance a partner holds the other end ≈ 1.8 (E13 and E72 on proposed R33, with C02) **[guess]** ≈ 6.8 against V(2) 7: −3%, in band (±15%). It needs two copies or a second Both Ends unit.

### 46. Flood — NEW
- **Rules.** Start of Combat: raise the water by 1 on both boards for this combat (to a maximum of 3). Each water level gives front-row units -1 Attack, except units with Swim, which get +1 Attack instead. The back row stands on higher ground and stays dry.
- **Bends.** 9.3.1: game-wide combat modifiers come from the modifier layer; here a unit sets terrain for both boards. It adds a combat state other text can read ("while the water is up").
- **Creature.** Beavers dam streams and flood the land around them; the Folio's Dyke Board: "the water level decides every battle". Swim suits otters, frogs, newts and water voles.
- **Archetype.** MEDIUM for water creatures, and a counter to front-row TALL carries. Beavers have no home in the longlist yet.
- **Example.** *Dam-Warden Beaver*, Tier 3, 2/5. Flood. *Ditch Otter*, Tier 2, 3/2. Swim.
- **Fun against.** Symmetric terrain both players can see: lean on the back row, or field swimmers. It hurts the beaver player's own dry front row too.
- **Check.** Galaxy has row-wide slot buffs (Down Came the Rain: "Give all three front row slots +1/+1") and Battlegrounds has lobby-wide anomalies, but no unit sets terrain for both boards.
- **From.** creatures 18.
- **Rules review:** Changes 9.3.1: a unit registers a combat-only game-wide modifier for both boards. It fits the modifier layer if units may register at that layer; say they can. Attack floors at 0 (1.2.4), so at level 3 front units can reach 0 and can't attack (9.4.6). A front-only board then can't attack, and two such boards tie at once (R3). The water stays after the beaver dies; say so. No loop. Readable as a water line.
- **Budget review:**
  - *Dam-Warden Beaver* T3 2/5, back: body 6.5 + net terrain ≈ +0.5 (enemy front −1 Attack ≈ 4.4 against your own front −1 Attack ≈ −4, plus any Swim payoff; proposed E97) **[guess]** ≈ 7 against V(3) 8: −12%, in band (±15%).
  - *Ditch Otter* T2 3/2 Swim: body 5 + ≈ 0.5 (+1 Attack while water is up, which needs a Flood unit on either board) ≈ 5.5 against V(2) 7: **−21%, flag (under, ±15%).** Change: 3/3 (≈ 6.5, −7%).

## L. Gold over turns

*Bramble carries gold over with no interest (4.1.2–4.1.3) and has no recruit timer (3.1.2). Each recruit mechanic says how it ends within a turn. Wager depends on the async model (2.1.5).*

### 47. Cache — VARIANT of Battlegrounds' anomaly Prudence of Amitus
- **Rules.** Once per turn, you may bury up to 3 gold in this unit; it has +1 Health for each buried gold. At the start of your next turn you dig it all up plus 1, unless this died in the last combat: then you dig up half (rounded down) and the rest sprouts into a 1/2 Oak Seedling in your hand.
- **Bends.** 4.1.3 (holding gold earns nothing): a small, capped interest. 9.1.1: a death in combat changes next turn's gold.
- **Creature.** Red squirrel, which scatter-hoards and forgets a share of its nuts, which sprout (the Folio's Acorn Exchange).
- **Archetype.** ECO.
- **Example.** *Nutkin Teller*, Tier 2, 1/2, Red Squirrel. "Cache (3)."
- **Fun against.** Killing the squirrel robs the bank. A fat squirrel is a target worth reaching, so back-row reach gets a reason.
- **Ends.** One deposit per Cache unit per turn, capped at 3; the +1 is per unit, not per gold.
- **Check.** Prudence of Amitus: "Unspent Gold carries over to your next turn. If you saved at least 5, gain 1 extra." Cache puts that interest on a unit that can be killed.
- **From.** recruit 1.
- **Rules review:** Changes 4.1.3 and needs R9 (did it die last combat?). Ambiguities: selling or tripling a squirrel with gold buried in it (lost or returned?); golden under 7.3.5 (does X double to 6 and the +1 to +2, or is X a cap? R12); a Seedling into a full hand (7.1.2). No refresh, no loop. Readable.
- **Budget review:** *Nutkin Teller* T2 1/2: burying 3 gold loses gold unless the squirrel survives (back units survive 17–33% of fights), so the best play is 1 gold a turn: about conditional recurring +1 gold × 0.3 survival ≈ 6.5 × 0.3 ≈ 2.0 (E50; 2.2's Tier-2 price for +1 a turn at a sink of 2.0) + 1 Health while buried ≈ 1 → 2.75 + 3 ≈ 5.75 against V(2) 7: −18% (±25%: economy), in band. For information: on a board that keeps it alive (survival above about 0.6) it nears unconditional recurring gold at Tier 2, which power-budget 4.1's proposed gold caps (not approved) would rule out. Re-check survival in the bot.

### 48. Thrift / Revel — VARIANT of Battlegrounds' Tavern Tipper
- **Rules.** *Thrift:* End of Turn: if you have more gold than you started the turn with, do the effect. *Revel:* End of Turn: if you have 0 gold, do the effect.
- **Bends.** 4.1.2–4.1.3. Carry-over makes banking neutral; these put a board reward on each side, so "save or spend" becomes a build identity.
- **Creature.** Aesop's ant and grasshopper; the Folio's "The Hive and the Carnival": thrifty ants and bees against a cicada brass band.
- **Archetype.** Thrift: ECO turning into MEDIUM. Revel: MEDIUM and tempo.
- **Examples.** *Granary Ant*, Tier 3, 2/4, Ant. "Thrift: give your back-row units +1/+2 permanently." *Cicada Bandleader*, Tier 2, 3/2. "Revel: give this and the units behind it +2/+1 permanently."
- **Fun against.** A Thrift board fights weakly early and spikes later; a Revel board hits hard now with no bank.
- **Ends.** One check at End of Turn, no counter.
- **Check.** Tavern Tipper (retired): "If you have any unspent Gold at the end of your turn, gain +1/+2." Thrift alone is nearly a reskin of it; Revel is the mirror, and Battlegrounds' spend counters (Gunpowder Courier, "Whenever you spend 5 Gold") are its nearest cousins.
- **From.** recruit 2.
- **Rules review:** Changes only the incentives in 4.1.2–4.1.3. Define "started the turn with" as gold after 3.2.1 step 1. Clean End of Turn triggers. No loop. Readable.
- **Budget review:**
  - *Granary Ant* T3 2/4: +1/+2 to every back unit (3 × 2.75 ≈ 8.25 SP) on each turn it fires. As written ("more gold than you started the turn with", with this turn's income counted in the start) it needs a net gold gain, about 0.3 of turns **[guess]**: s ≈ 2.5 SP a turn, over the Tier-3 cap of 1.7; 3.5 × 2.5 ≈ 8.7 → ≈ 14.7 against V(3) 8: **+84%, flag (over the growth cap, ±25%).** Change: 2/2, "give a random back-row unit +1/+2 permanently" (≈ 6.9 at 0.3 of turns, −14%; ≈ 10.7, +34%, if the condition fires on 0.7 of turns, so the wording matters).
  - *Cicada Bandleader* T2 3/2: spending to 0 is normal play, so Revel fires on about 0.7 of turns; +2/+1 to this and about 1.5 units behind ≈ 6.75 SP a turn → s ≈ 4.7, over three times the Tier-2 cap of 1.3; 3.7 × 4.7 ≈ 17 → ≈ 22 against V(2) 7: **+214%, flag (over the growth cap, ±25%).** Change: 1/1, "Revel: give this and the units behind it +1 Attack permanently" (s ≈ 1.5, at the cap: 2 + 5.5 ≈ 7.5, +7%).

### 49. Upkeep (X) — NEW *(merged with Hungry)*
- **Rules.** At the start of your turn, choose: pay X gold, or this unit Starves (half Attack, rounded down) until you next pay.
- **Hungry version** (creatures): This attacks first in each cycle, ahead of the reading order. At the start of each of your turns it eats 1 gold; if you have none, it loses 1/1 permanently.
- **Bends.** 3.2.1 (start of turn gives gold, never takes it) and 4.1: a recurring cost on a body. Hungry also bends 9.4.2 and 9.4.5: attack order is reading order from F1, and it jumps that, which Battlegrounds never does.
- **Creature.** Shrew. Shrews must eat every few hours and are the fastest things in the hedge (Folio hook: "Pay upkeep each round or lose HP; very fast attacks"); the Redwall shrew guerrillas.
- **Archetype.** Tempo for any comp, and a cheap early carry for TALL. Creatures-first adds that it may be the counter to ECO that archetypes.md §2.2 says is missing: it hits hard on turns 1–4.
- **Examples.** *Pygmy Shrew Berserker*, Tier 1, 4/3. "Upkeep (1)." *Pygmy Shrew*, Tier 1, 3/1. Hungry.
- **Fun against.** Upkeep boards punch above their tier early, then feel the bill; a starved shrew says that player is short on gold. With uncapped carry-over, 1 gold is a real cost on turn 2 and almost nothing on turn 12, so the cost may need to scale (for example, gold equal to its tier). A Hungry shrew in the back row attacks first and can't be attacked: test whether that is fine.
- **Ends.** One payment per unit, once per turn. No trigger, no loop.
- **Check.** Battlegrounds' Activate costs are optional; nothing in either game charges a unit a recurring cost.
- **Other names.** Hungry (creatures 11).
- **From.** recruit 3, creatures 11.
- **Rules review:** Changes 3.2.1 (the start of a turn can take gold) and, for Hungry, 9.4.2 and 9.4.5. Upkeep needs a player choice inside the start-of-turn steps. That is fine with no timer; place it after 3.2.1 step 1 and before step 5. Hungry must skip the pointer (R5): a Hungry unit in B3 attacking first would set `P = 7` and flag its whole side. A Hungry unit shrunk to 0 Health dies in the Recruit Phase, and 5.3.7 covers the pool. Starve's halving is a stat-layer multiplier. No loop. Readable.
- **Budget review:**
  - *Pygmy Shrew Berserker* T1 4/3 Upkeep (1): starved it is a 2/3 (5 SP, on V(1)). Paying 1 gold buys +2 Attack for that fight, about 2 SP for a gold that buys 2.0–2.4 SP elsewhere (2.2, 4.1): a fair option, ≈ +0.5 → ≈ 5.5: +10%, in band (±25%: economy). Because the option is fair early and late, the cost doesn't need to scale with turn.
  - *Pygmy Shrew* T1 3/1 Hungry: body 4 + attacks first each cycle (E83 ≈ A(1) 2) − a forced gold every turn (income always arrives first, so it always eats; recurring −1 gold at Tier 1 ≈ −2.4 SP a turn while held) → **far under on any hold past one turn, flag (under, ±25%).** Change: make the payment a choice, as in Upkeep: "pay 1 gold, or this loses 1/1 permanently", on 3/1 (≈ 6, +20%, edge; 2/1 if the sim says so). Both use proposed E98.

### 50. Wager (X) — NEW
- **Rules.** At End of Turn you may stake up to X gold on your next fight. Win: get double at the start of next turn. Tie: get it back. Lose: it's gone. At most one wager a turn, at your highest Wager value.
- **Bends.** 10.1: a fight pays out only in hero damage; Wager pays it in gold too. It uses the next-opponent information you already have (2.3.3).
- **Creature.** Otter: the Norse otter's ransom and its cursed gold; the Folio's otter smugglers.
- **Archetype.** ECO and tempo: it turns a board that is ahead into gold.
- **Example.** *Ransom Otter*, Tier 3, 3/3. "Wager (3). After you win a wager, this gains +1/+1 permanently."
- **Fun against.** Beating a board that bet on itself takes their gold as well as their health. Early bets are cheap because of the damage caps (10.1.4).
- **Ends.** One stake per turn, capped by X; the payout is fixed at double.
- **Async.** Against a recorded board it is a bet on your own board, not a duel.
- **Check.** Battlegrounds' anomaly Gladiator's Spoils rewards winning with a card, not a stake.
- **From.** recruit 4.
- **Rules review:** Changes 10.1 (fights pay gold). Needs R9 and an async answer: the fight's result must exist before the player's next turn starts. What happens against a ghost (2.1.2)? No loop. Readable.
- **Budget review:** *Ransom Otter* T3 3/3: a stake at a 50% win rate is worth 0 on average. If players stake only when they expect to win (about 0.65, using the next-opponent information, 2.3.3), it is ≈ +0.3 × 3 gold on about 0.6 of turns ≈ +0.55 gold a turn ≈ 2.8 SP (E50 on R28, Tier-3 recurring price 5.1); "+1/+1 permanently" per won wager is s ≈ 0.7, under the cap, ≈ 2.5 **[guess]**. Total ≈ 11.3 against V(3) 8 if players pick their fights (+41%), ≈ 9.5 if not (+19%), ±25%: edge, no flag until the bot shows how players stake. Change if it does: 2/2 (≈ 9.3, +16%).

### 51. Bargain — NEW
- **Rules.** When you play this, you get its gift at once, and its price comes due at the start of your turn a set number of turns later. Selling the fairy before then pays the price at once, doubled.
- **Bends.** 3.2.1: a new start-of-turn step where debts are paid. 4.1: gold borrowed against later turns. 4.3: selling has a cost as well as a value.
- **Creature.** Fairy. Fairy bargains always carry a catch, and the debt always comes due. Pairs with archetypes.md's fairy gold that vanishes.
- **Archetype.** ECO (borrowed tempo) and TALL (a big gift on one unit now).
- **Examples.** *Hob of the Crossroads*, Tier 2, 2/2. Bargain: give a unit +4/+4 permanently now. Price, in 2 turns: your shop has one fewer unit that turn. *Thrice-Kissed Sprite*, Tier 4, 3/3. Bargain: gain 4 gold now. Price, in 3 turns: lose 6 gold; if you can't, your highest-Attack unit loses 4 Attack permanently.
- **Fun against.** The debt day shows on the fairy, so you can see when an opponent will be weak. The price should sometimes land on the board, so fights show it.
- **Check.** No delayed costs in either game. Lockbox and Mysterious Egg are delayed rewards, the mirror image.
- **From.** creatures 9.
- **Rules review:** Changes 3.2.1 with a debt step. Keep the debt on the player, not the fairy, or tripling the fairy (7.3.1 removes it without selling) escapes the price. A golden doubles both gift and price under 7.3.5, and selling doubles it again. "If you can't" needs wording for partial payment. No loop. Readable, if the debt day is shown.
- **Budget review:**
  - *Hob of the Crossroads* T2 2/2: body 4 + "+4/+4 permanently now" (E01 one-off, 0.9 × 8 ≈ 7.2) − one fewer shop unit on one turn (≈ −0.5) **[guess]** ≈ 10.7 against V(2) 7: **+53%, flag (over, ±15%).** Change: 1/1 and +3/+3 (2 + 5.4 − 0.5 ≈ 6.9, −1%).
  - *Thrice-Kissed Sprite* T4 3/3: a player can dodge "lose 6 gold" by holding under 6 on debt day, so the real price is −4 Attack on the carry (≈ −4); 4 gold now ≈ 4 × 2.2 = 8.8 → ≈ 10.8 against V(4) 10: +8% (±25%), in band. For information: 4 gold in one trigger is over power-budget 4.1's proposed one-off cap (1 per trigger from Tier 3), which the owner hasn't approved. Wording fix: "if you can't, lose what you have and your highest-Attack unit loses 4 Attack", so the price can't be dodged (question 7).

## M. The shop: buying, selling, refreshing, tiers

### 52. Pawn — NEW
- **Rules.** You may sell a unit with Pawn for 3 gold instead of 1. It goes into an extra Pawn slot at the end of your shop, frozen, with its buffs. Buy it back for 4 before the end of your next turn, or it is forfeit and returns to the pool.
- **Bends.** 4.3.3 (sell value), 6.1.1 (shop size) and 4.5 (freeze).
- **Creature.** The Folio's corvid crime family: "jackdaws run the pawnshop".
- **Archetype.** ECO (a loan that lands an upgrade or triple a turn early); TALL (pawn the feeders for the carry's big turn).
- **Example.** *Jackdaw Pawnbroker*, Tier 2, 2/3, Bird. "Your other units have Pawn."
- **Fun against.** Boards that pawned something to spike are thinner this fight. Forfeits put copies back into the pool for everyone.
- **Ends.** One Pawn slot. Buying back costs 1 more than the loan, so a pawn cycle always loses gold.
- **Check.** Battlegrounds' Time Saver (retired) sells for more, but nothing in either game lets you buy a sold unit back.
- **From.** recruit 6.
- **Rules review:** Changes 4.3.3, 6.1.1 and 4.5. Two leaks. A pawned Created unit sells for 3, against the owner's "anything you didn't pay for sells for 0" (4.3.2, N5 §8), and when forfeited it can't return to the pool (5.3.6). Buying it back pays gold, so under 4.3.1 it comes back Bought. Exclude Created units or pawn them for 0. G1 (R11): pawning and buying back repeats sell and play triggers for 1 gold each, at a price that never rises. Any "when sold or played: refresh the shop" unit then gives a 1-gold refresh outside 4.4.2. Limit pawning to once per turn. Readable.
- **Budget review:** *Jackdaw Pawnbroker* T2 2/3: forfeiting a pawned unit is a sale for 3 instead of 1, so +2 gold about every other turn once the board is full (one Pawn slot): ≈ +1 gold a turn, almost unconditional (E54) ≈ 6 SP at Tier 2 **[guess]** → ≈ 11 against V(2) 7: **+57%, flag (over, ±25%).** Change: Tier 3, sell for 2 and buy back for 3 (the cycle still loses 1): 5 + ≈ 2.6 ≈ 7.6 (−5%). Pawn must apply to Bought units only, since Created units sell for 0 (rulebook 4.3.2): a pawned Created unit would turn every card generator into gold.

### 53. Barter — NEW
- **Rules.** Once per turn, instead of buying, swap one of your board units with a unit in your shop. The shop unit takes its slot directly, and your old unit goes into that shop slot with its buffs; it loses them if the shop refreshes.
- **Bends.** 4.2.1 (units cost 3) and 7.2.3 (units enter through the hand and trigger "when played"): a bartered unit skips the hand and its play effects. The new unit takes the old one's origin (4.3).
- **Creature.** The Folio's fox "rag-and-bone traders".
- **Archetype.** MEDIUM and WIDE: cheap pivots when the shop shows your tribe.
- **Example.** *Rag-and-Bone Fox*, Tier 3, 3/3, Fox. "Barter. After you barter, the new unit gains +1/+1 permanently."
- **Fun against.** Barter boards change shape fast, so last turn's snapshot is a weak forecast.
- **Ends.** Once per turn per Barter unit. No gold changes hands; a buffed unit left in the shop costs the normal 3 to take back.
- **Check.** No board-to-shop swap in either game.
- **From.** recruit 7.
- **Rules review:** Changes 4.2.1 and 7.2.3. Ambiguities: a Created unit bartered into the shop must not return to the pool on a refresh (5.3.6), so it vanishes. A bartered golden returns copies under 5.3.5. The new unit triples at once if it completes one (7.3.1). Swapping a Created token makes the shop unit Created (sells for 0), which is fine. No refresh, no loop: once per turn per Barter unit. Readable.
- **Budget review:** *Rag-and-Bone Fox* T3 3/3: a barter replaces "sell for 1, buy for 3", so each use saves 2 gold, and a player upgrading the board uses it about every turn: ≈ recurring +2 gold a turn; "+1/+1 permanently" per barter is s = 2 SP a turn, over the Tier-3 growth cap of 1.7 (E44, E02) **[guess]** → ≈ 6 + 10 + 7 ≈ 23 against V(3) 8: **+188%, flag (over the band and the growth cap, ±25%).** Change: "Barter (1 gold)" and drop the +1/+1 (saves 1 gold a turn, ≈ 5.1 at the Tier-3 recurring price), on 1/2: ≈ 8.1 (+1%). The +1/+1 payoff could live on a Tier-5 fox.

### 54. Aisle — NEW
- **Rules.** Shop cards line up with your board slots in reading order: card 1 with F1, card 5 with B1. A unit's aisle is the slot it fought from in your last combat; Aisle text acts on the shop card in that aisle, each time the shop fills.
- **Bends.** 6.1: the shop ignores position. Now combat position is also shop position, and free moves (8.3.3) gain a cost.
- **Creature.** The Folio's Sett Gentry, badger landlords whose tenants "pay rent to stand near them".
- **Archetype.** ECO and MEDIUM.
- **Examples.** *Sett Landlord*, Tier 2, 2/5, Badger. "Aisle: that card costs 1 less (minimum 1)." *Market Hedgehog*, Tier 4, 3/4. "Aisle: that unit has +2/+2."
- **Tier gate for free.** The shop has 4 cards at Tier 1 and 7 at Tier 6 (6.1.1), so back-row aisles open only at Tier 4 and up.
- **Fun against.** A landlord in the front row for the discount is a tough unit you have to chew through.
- **Ends.** One effect per shop card per fill; a discount never goes below 1 gold.
- **Check.** Battlegrounds' "right-most minion in the Tavern" effects read shop position, but not the board's.
- **From.** recruit 8.
- **Rules review:** Changes 6.1 (the shop reads board position) and needs R9 (which slot it fought from). Ambiguities: is the spell slot numbered (6.1.1)? Units bought since the last combat have no aisle. A discount to 1 makes buying (1) and selling (1) cost nothing, so buy and sell triggers repeat for only the refresh price. 4.4.2 bounds that, so it passes G1 as long as no Aisle effect refreshes (R11). Readable only with a UI link from slot to shop card, which is real work.
- **Budget review:**
  - *Sett Landlord* T2 2/5: about one discounted buy a turn, more on refresh-heavy turns because each fill re-rolls the aisle card: ≈ recurring +0.7 gold a turn, conditional on buying that card (E53, C02) ≈ 6.5 × 0.7 ≈ 4.5 **[guess]** → ≈ 11.5 against V(2) 7: **+64%, flag (over, ±25%).** Change: Tier 3, 2/2, "once per turn": 4 + ≈ 3.6 ≈ 7.6 (−5%).
  - *Market Hedgehog* T4 3/4: +2/+2 on the aisle card when you buy it (E14 or E61, about 0.5 a turn: s ≈ 2 SP, under the Tier-4 cap 2.5): 3.1 × 2 ≈ 6.2 → ≈ 13.2 against V(4) 10: **+32%, flag (over, ±25%).** Change: 2/3 (≈ 11.2, +12%) and "once per turn", so a turn of many refreshes doesn't buff every aisle card it buys (the R10 risk; G8).

### 55. Cold Store — VARIANT of Battlegrounds' Freeze
- **Rules.** Once per turn, put one shop card in Cold Store. It stays through refreshes and turns, gains +1/+1 at the start of each of your turns, and takes up a shop slot until you buy it.
- **Bends.** 4.4.1 (refresh replaces every card), 4.5.3 (the freeze ends each turn) and 5.3.2 (a copy kept out of the pool for many turns).
- **Creature.** Wolverine, which "caches meat in snow".
- **Archetype.** TALL (ripen a carry before buying it); golden chasing (hold the third copy).
- **Example.** *Snow-Cache Wolverine*, Tier 3, 4/3. "Cold Store. Units you buy from Cold Store are Bought and keep their growth."
- **Fun against.** A unit ripening for five turns lands as a surprise. In a live lobby a stored copy is one fewer for your triple.
- **Ends.** One stored card per player, growing a fixed amount once a turn.
- **Check.** Freeze keeps the shop for one turn. Cold Store keeps one card through refreshes and grows it.
- **From.** recruit 9 (marked variant by the designer).
- **Rules review:** Changes 4.4.1, 4.5.3 and 5.3.2. Clean as a `shopOffer` handler that pins one slot. The text conflicts with itself: "once per turn" against "one stored card per player". Growth is unbounded but linear. It shrinks the shop by one, which is a third of the units at tier 1. Creates no refresh. No loop. Readable.
- **Budget review:** *Snow-Cache Wolverine* T3 4/3: the one stored card grows +1/+1 a turn until bought (E14 on one card: s = 2 SP a turn, over the Tier-3 cap of 1.7), realised in full when bought: 3.5 × 2 ≈ 7, less a shop slot ≈ 0.5 **[guess]** → ≈ 13.5 against V(3) 8: **+69%, flag (over the growth cap, ±25%).** Change: 2/2 and growth "up to +3/+3" (0.9 × 6 ≈ 5.4 → ≈ 9.4, +17%). Or print it at Tier 5 as it is (2.6 × 2 ≈ 5.2 → ≈ 12.2, +2%).

### 56. Fast (action) — NEW

**Owner's doubts, 2 Nov:** "It rewards you for not playing the game … Being rewarded for not making choices is not fun" ([02h](sources/2026-11-02h-checkpoint-read-through.md)). Not cut: "Fast might be a dead end, but we should still explore it" ([02i](owner-notes/archive/2026-11-02i-reactions-are-directions.md)). A time-bound version ("Don't move for 3 turns, then X") is one direction.
- **Rules.** End of Turn: if you didn't do the named action this turn (refresh, buy or sell), this gains the effect. Each turn in a row adds +1 to it; doing the action resets the streak.
- **Bends.** 3.1.2 and 4.4. With no timer, the usual best play is to refresh until gold runs out; Fast puts a board price on every refresh. The shop form of the owner's "Things that don't attack, but get rewarded every time they skip".
- **Creature.** Heron, which "stands still, then stabs"; olm, which "can go years without food".
- **Archetype.** TALL and late scalers; the counter-plan to ECO's long turns.
- **Examples.** *Still-Water Heron*, Tier 2, 3/2, Bird. "Fast (refresh): +1/+1 permanently." *Olm Sleeper*, Tier 5, 2/8. "Fast (buy): +3/+3 permanently."
- **Fun against.** Fast players take short turns and grow slowly, so beat them early.
- **Ends.** One check at End of Turn; the streak adds a fixed +1 a turn.
- **Check.** Tavern Tipper rewards unspent gold, which is close in spirit, but nothing rewards not doing a named action, or streaks.
- **From.** recruit 10.
- **Rules review:** Bends no structural rule: one End of Turn check. Define whether free refreshes (Dig Down, effects, 4.4.6) count as "refresh"; proposed, paid only. No loop. Readable.
- **Budget review:**
  - *Still-Water Heron* T2 3/2, Fast (refresh): the streak makes growth quadratic (+1/+1, +2/+2, +3/+3 …), about +15/+15 over turns 2–6 for a player who doesn't refresh, which is common early: s ≈ 6 SP a turn against the Tier-2 cap of 1.3 (E02 with C03): **flag (over the growth cap, ±25%).** Change: 2/2, "+1 Attack permanently, +1 more for each turn in a row, up to +2 a turn" (s ≈ 1.5 × 0.7 of turns ≈ 1.05: 4 + 3.9 ≈ 7.9, +13%).
  - *Olm Sleeper* T5 2/8, Fast (buy): "+3/+3, +1 more each turn" is s ≈ 8 SP a turn while fasting, and carry-over makes skipping buys cheap (bank, then spend), so it is far over the Tier-5 cap of 3.8: **flag (over the growth cap, ±25%).** Change: 2/6, "+1/+1, +1 more for each turn in a row, up to +3/+3" (s ≈ 2: 8 + 5.2 ≈ 13.2, +10%).

### 57. Dig Down — NEW
- **Rules.** Once per turn, lower your tier by 1 until the end of the turn, and refresh your shop for free at that tier. You can't upgrade while dug down.
- **Bends.** 4.6.1 (tier only rises) and 6.1.2 (draws use your tier). Late boards can fish for low-tier copies and token makers.
- **Creature.** The Folio's mole miners' union, digging down into an old seam.
- **Archetype.** WIDE (late access to Tier 1–2 token makers) and golden chasing (better odds on low-tier triples).
- **Example.** *Mole Foreman*, Tier 4, 3/5, Mole. "Dig Down." Golden: two tiers.
- **Fun against.** Late boards turn up with golden Tier 1s nobody expected.
- **Ends.** Once per turn per mole, one free refresh each; the tier returns at End of Turn.
- **Check.** No effect lowers your tier in either game. Discover-a-lower-tier effects are the nearest.
- **From.** recruit 12.
- **Rules review:** Changes 4.6.1 and 6.1.2. Needs a draw tier separate from the player's tier in the rule queries (for example `shopTier(player)` beside the tier used for upgrades). Ambiguities: do several moles stack down to tier 1? Does the shop shrink to the lowered tier's size (6.1.1)? G1 (R11): the only mechanic here that gives unpaid refreshes directly. Once per turn per mole is the guardrail's own example, so it passes while no effect retriggers or resets activated abilities. Readable.
- **Budget review:** *Mole Foreman* T4 3/5: one free refresh a turn (about half of recurring +1 gold at Tier 4, ≈ 2.1; E52) + low-tier access for triples and token makers (≈ 1, E62 in reverse) **[guess]** ≈ 11 against V(4) 10: +10% (±25%), in band. It is once per turn per mole, so it passes G1 (R11).

## N. Waiting off the board: hand and sleep

### 58. Hibernate (N) — VARIANT of Galaxy's Mysterious Egg and Battlegrounds' Lockbox
- **Rules.** This unit sleeps through your next N upgrades. While asleep it stays in its slot but combat treats the slot as empty, and each upgrade gives it +3/+3 permanently. It wakes after the Nth.
- **Bends.** 9.1.2 (each unit fights from its slot) and 9.2.1 (sleepers aren't counted for who attacks first). Upgrading becomes a trigger.
- **Creature.** The dormouse "sleeps over half the year"; the Dormouse Clockmakers' guild "hibernates by law".
- **Archetype.** TALL.
- **Example.** *Clockwork Dormouse*, Tier 2, 1/1. "Hibernate (2)."
- **Fun against.** Their board fights a body short now, and you can see the sleeper, so you know what is coming.
- **Ends.** A game has at most five upgrades, so growth is bounded.
- **Check.** Mysterious Egg ("After 3 turns, I hatch…") and Lockbox (a golden that unlocks later) are delayed payoffs that take space. Hibernate counts upgrades, not turns, and grows.
- **From.** recruit 11 (marked variant by the designer). Creatures-first used the same name for in-hand growth, merged into Rehearse (59).
- **Rules review:** Changes 9.1.2 and 9.2.1 with an in-slot inactive unit (R7). "Combat treats the slot as empty" must say whether summons can land there; two units in one slot breaks 8.1. Proposed: it blocks summons but isn't a candidate, attacker or neighbour, and doesn't count for 9.2.1, 9.9.1 or 10.1.1. Golden: N is a counter and stays (7.3.5). Bounded by five upgrades. Readable.
- **Budget review:** *Clockwork Dormouse* T2 1/1 Hibernate (2): no combat value for about 4 fights (its slot is free on small boards), then +6/+6 → 7/7 by about turn 6 at standard pace. Against a plain 7-SP unit held from turn 2 it ends about +20% by turn 12 (E02 on proposed trigger R34, on upgrade; proposed E96 while asleep) **[guess]**: in band (±25%), edge, no flag. Bought with fewer than N upgrades left, it never wakes: a trap, as intended.

### 59. Rehearse — VARIANT of Battlegrounds' hand-buff cards *(merged with creatures' Hibernate)*
- **Rules.** End of Turn: if this is in your hand, it gains +1/+1 permanently, or +2/+2 if another Rehearse card is in your hand too. Once played, it stops growing.
- **Bends.** 3.4.2 (cards in hand do nothing) and 7.1: the hand becomes a growth space that competes with board slots, beside the gold that already carries over.
- **Creature.** The Folio's Frog Chorus and fox travelling theatre, rehearsing offstage before opening night. Dormice sleeping through half the year (the hand as a den).
- **Archetype.** MEDIUM (a chorus that debuts together) and TALL.
- **Examples.**
  - *Understudy Toad*, Tier 3, 2/2, Frog. "Rehearse. When you play this, give your other Frogs +1/+1 for each turn it rehearsed (up to 4)."
  - *Hazel Dormouse*, Tier 2, 1/1. Hibernate (plain +1/+1 a turn in hand).
  - *Old Sleeper*, Tier 5, 4/4. Hibernate. When you play this, give its stats gained in hand to the units adjacent to it as well.
- **Fun against.** A thin board for a few turns, then opening night. The cost (a hand slot and a unit not on the board) is visible.
- **Ends.** Once per turn, and the 10-card hand caps it.
- **Check.** Battlegrounds' Bream Counter grows in hand when you play a Murloc, and Futurefin feeds hand cards; Rehearse grows on its own each turn.
- **Other names.** Hibernate (creatures 12). **Name clash:** *Hazel Dormouse* is also the Slumber example in Bide (9).
- **From.** recruit 13 (marked variant by the designer), creatures 12.
- **Rules review:** Changes 3.4.2 (cards in hand act). 3.4.1 resolves End of Turn in reading order, which the hand doesn't have; add "board, then hand left to right", as 9.3.1 does for Start of Combat. Growth is unbounded but linear. No loop. Readable.
- **Budget review:**
  - *Understudy Toad* T3 2/2: in hand it grows +1/+1 a turn (+2/+2 with a second Rehearse card: s up to 4, over the Tier-3 cap of 1.7), and on play gives other Frogs +1/+1 per turn rehearsed, up to 4 (0.9 × 8 × about 1.2 Frogs ≈ 8.6). With in-hand growth at 0.6 for the turns it isn't fighting (≈ 4.2) **[guess]**: ≈ 4 + 4.2 + 8.6 ≈ 16.8 against V(3) 8: **+110%, flag (over, ±25%).** Change: 1/1; the keyword grows +1/+1 only (no pair doubling); payoff "+1 Attack to your other Frogs per turn rehearsed (up to 3)": 2 + 4.2 + 3.2 ≈ 9.4 (+18%).
  - *Hazel Dormouse* T2 1/1, plain +1/+1 a turn in hand: 2 + 3.7 × 2 × 0.6 ≈ 6.4 against V(2) 7: −9%, in band if held up to about 4 turns; consider "up to 4 turns" on the keyword.
  - *Old Sleeper* T5 4/4: what it gains in hand also goes to about 1.43 neighbours on play, ≈ 4.9 SP a turn in hand → 8 + 2.6 × 4.9 × 0.6 ≈ 15.6 against V(5) 12: +30% (±25%), edge, no flag. If the sim agrees, 3/3 (≈ 13.6, +13%).

### 60. Fly South — NEW *(called Migrate in the recruit list)*
- **Rules.** End of Turn: you may send this away. It leaves the board, and its slot is empty. At the start of your turn after next it returns to its slot (or the nearest empty one, 8.4.2) with +2/+2 and a bundle: a Created random unit of your tier in your hand.
- **Bends.** 3.4.2 and 8.3. A unit is normally on the board or in hand; a migrant is neither for two turns, and it frees a slot without selling.
- **Creature.** The Stork Post: storks "bring the babies" and are "mysteriously absent every winter".
- **Archetype.** ECO and WIDE.
- **Example.** *Stork Courier*, Tier 3, 3/3, Bird. "Migrate." Golden: two bundles.
- **Fun against.** You catch them a body short while the storks are away, and they come back with a delivery.
- **Ends.** One return per stork every two turns. Bundles are Created and sell for 0 (4.3.3), so there is no gold loop.
- **Check.** Battlegrounds' Free Travel Winner (retired) removes itself for a reward but doesn't come back.
- **Renamed** here because rows' Migrate (42) is a different mechanic. The example's text still says "Migrate".
- **From.** recruit 18.
- **Rules review:** Changes 3.4.2 and 8.3 with an off-board zone that lasts across turns (R7). Ambiguities: a return onto a full board (wait, lost, or to hand?); does an away unit count for triples, hero damage, or pool returns on elimination (5.3.8)? A bundle into a full hand (7.1.2). No loop. Readable.
- **Budget review:** *Stork Courier* T3 3/3: a flight costs two fights without the stork; it returns with +2/+2 (permanent growth, c(3) 3.5 per SP a turn) and a Created random unit of your tier (E41 ≈ 0.4 × V(k) ≈ 4) (proposed E96 while away) **[guess]**. Flying every third turn, the gains roughly pay for the missed fights: about −3% to +25% by how often it flies (±25%), in band, no flag.

## O. Copies, triples, spells and the pool

*Golden chasing has no owner in archetypes.md §1.3; Mimic, Foundling and Pair are three candidates, and Shiny (18) is its counter. Mimic and Endangered depend on the async model (2.1.4, 2.1.5).*

### 61. Mimic — VARIANT of Galaxy's Mirror Mirror and Battlegrounds' Karmic Chameleon
- **Rules.** At the start of your turn, this becomes a copy of the unit that was across from it in your last fight (8.2.6): base stats, not golden, keeping Mimic and its own buffs. If that slot was empty, it stays as it is.
- **Bends.** 4.3.1 and 5.3.6: units come from the pool or your own effects; Mimic takes one from another player's board. The copy is Created and counts toward triples (7.3.3).
- **Creature.** Jay, which imitates the calls of other birds; a Folio "noisy sentinel".
- **Archetype.** Golden chasing: a mimic can be the third copy of a unit you saw your opponent run.
- **Example.** *Mocking Jay*, Tier 4, 2/2, Bird. "Mimic. Has +2/+2."
- **Fun against.** Your best unit gets borrowed, and where you put it decides what they can borrow. It reads the slot the jay fought in, so it can't be aimed by moving it in the Recruit Phase.
- **Ends.** Once per turn, at the start of it.
- **Async.** The copied unit may come from a lobby with other tribes; whether that's allowed depends on 2.1.5.
- **Check.** Mirror Mirror copies Ranged, Sneak and Treasure Hoard from the enemy across; Karmic Chameleon (retired) transforms into a copy of a friendly neighbour. Mimic copies the whole enemy unit, between fights. **Name clash:** Galaxy has a card called *Mimic*.
- **From.** recruit 5 (marked variant by the designer).
- **Rules review:** Changes 4.3.1 and 5.3.6, and needs R9 (who was across). Conflict: 4.3.6 says origin stays through a transform, so a Bought Mimic stays Bought, but the entry says the copy is Created; pick one. Triples: is a copy that keeps Mimic's text the same unit as the original for 7.3.1? "Across" at which moment: after Start of Combat moves, or at the end of the fight? Async: copies may come from tribes outside the lobby (5.1.3). No loop. Readable.
- **Budget review:** *Mocking Jay* T4 2/2: it becomes the base copy of the unit across (about V of the enemy unit's tier: 9 at turn 6, 13–14 late) plus its own +2/+2, × 0.9 chance the slot was filled (E31) **[guess]**: ≈ 11.7 at turn 6 (+17%), ≈ 15.3 late (+53%), ±25%: **flag (over late).** Change: drop "Has +2/+2" (≈ 8.1 at turn 6, ≈ 11.7 late: −19% to +17%), or keep it at Tier 5.

### 62. Foundling — VARIANT of Battlegrounds' Elemental of Surprise and Zilliax modules
- **Rules.** In your hand or on your board, this counts as a copy of any non-golden unit for a triple. When it completes one, the golden also gains the Fairy type. If it could complete two triples, you choose.
- **Bends.** 7.3.1 (a triple needs three copies of the same unit).
- **Creature.** The folklore changeling, a fairy child left in a cradle in place of a human one.
- **Archetype.** Golden chasing.
- **Example.** *Cradle Changeling*, Tier 3, 2/2, Fairy. "Foundling."
- **Fun against.** Goldens arrive a turn or two early with an odd extra type, so Fairy payoffs reach into other tribes.
- **Ends.** Each Foundling is used up by one triple. The golden sells for 1 (4.3.4).
- **Check.** Elemental of Surprise (current) "can triple with any Elemental"; Zilliax modules triple with each other. Foundling is that wildcard for any unit, plus a type.
- **From.** recruit 14.
- **Rules review:** Changes 7.3.1. Clean as a `tripleMatch` query. Ambiguities: 7.3.1 triples "at once", so buying a Foundling while holding a pair triples immediately, which the player may not want. Three Foundlings make a golden Foundling. A choice in the middle of buying is fine with no timer. No loop. Readable.
- **Budget review:** *Cradle Changeling* T3 2/2: it saves about one buy when you hold a pair (E44 ≈ 4 from Tier 3, × about 0.6) + the Fairy type ≈ 0.3 (E85) **[guess]** ≈ 6.7 against V(3) 8: −16% (±25%), in band.

### 63. Pair — VARIANT of Battlegrounds' First Mate Pip and the False Idols anomaly
- **Rules.** Two copies of a Pair unit combine into a Bonded pair: one unit with both copies' stats and buffs, whose triggers fire twice. It isn't golden and gives no Triple Reward; a third copy makes it golden as normal, and it keeps the pair's stats.
- **Bends.** 7.3.1 (three copies), 7.3.5 (golden doubles numbers) and 7.3.6 (Triple Reward).
- **Creature.** Swans pair for life; the Children of Lir and Six Swans tales.
- **Archetype.** TALL early, and STICKY when the text protects.
- **Example.** *Mute Swan Paladin*, Tier 2, 2/4, Bird. "Pair. Start of Combat: give the units in front of this +1 Health this combat."
- **Fun against.** An early 4/8 that isn't golden, and a known spike when the third swan lands.
- **Ends.** Each merge uses up cards; a pair can't re-pair.
- **Check.** First Mate Pip (retired), the trinket Designer Eyepatch and the anomaly False Idols make goldens from 2 copies. Pair makes a halfway step that isn't golden and then still triples.
- **From.** recruit 15.
- **Rules review:** Changes 7.3.1, 7.3.5 and 7.3.6. "Triggers fire twice" is a retrigger, so Pair goes on G1's retrigger list (R11): any free-refresh trigger on a Pair unit doubles. Ambiguities: does a Bonded pair count as two copies for a triple? Three copies arriving at once: pair or triple? Does the golden keep firing twice on top of doubled numbers? No loop by itself. Readable.
- **Budget review:** *Mute Swan Paladin* T2 2/4, back: body 5.5 + Start of Combat +1 Health to the 2 units in front ≈ 1.8 ≈ 7.3 against V(2) 7: +4%, in band (±15%). Bonded pair: 4/8 (11) + the trigger twice (3.6) + one slot saved (≈ 1, E23; E80 for "triggers fire twice") ≈ 15.6 against two cards' 14: +11%, in band. Unclear: if the golden doubles the pair's stats (8/16), three copies give four times the body (owner question).

### 64. Brew — NEW
- **Rules.** While a unit with Brew is on your board, two copies of the same Tavern spell in your hand combine at once into a Strong copy: double its numbers, same cost. A Strong spell can't brew again.
- **Bends.** 6.1.5 (spells can't triple) and the spell pool counts in 5.1.2.
- **Creature.** The Folio's toadstone apothecaries, "witch-healers with jewels in their heads".
- **Archetype.** MEDIUM, through spell lines.
- **Example.** *Toadstone Apothecary*, Tier 3, 2/4, Toad. "Brew. After you cast a Strong spell, this gains +2/+2 permanently."
- **Fun against.** Their spell turns hit twice as hard but come less often.
- **Ends.** Two cards make one, and it doesn't chain. *Flag for balance:* whether Brew should double gold or refresh spells.
- **Check.** Battlegrounds doubles spells by casting them twice (Balinda Stonehearth); nothing merges two spell cards.
- **From.** recruit 16.
- **Rules review:** Changes 6.1.5. A Strong spell doubles numbers, so a spell that refreshes or gives gold doubles too: G1 review (R11), as the entry's flag says. Pool: two copies go in, one Strong copy comes out; what returns? 5.3 doesn't cover spell copies. It combines "at once", so you can't hold two plain copies. No loop by itself. Readable.
- **Budget review:** *Toadstone Apothecary* T3 2/4: merging two spells into one Strong spell moves no stats (the same total, one fewer cast, which slightly hurts on-cast triggers); the payoff "+2/+2 permanently" per Strong cast, at about 0.3 a turn, is s ≈ 1.2, under the cap: 3.5 × 1.2 ≈ 4.2 (E02 on R07; the merge is nearest E80) **[guess]** ≈ 10.2 against V(3) 8: +28% (±25%), edge, no flag. If the sim agrees, 2/3 (≈ 9.2, +15%). For information: a Strong refresh spell is one more unpaid refresh, so it gets a G1 review (R11); a Strong "gain 2 gold" is 4 gold in one trigger, which the proposed guardrails G5, G6 and G12 (not approved) would rule out.

### 65. Endangered — NEW
- **Rules.** This has +1/+1 for each of its copies missing from the pool (bought, shown in any shop, or held by anyone), counted at Start of Combat.
- **Bends.** 5.1.2 and 5.3: the pool's copy counts become a public stat.
- **Creature.** Capercaillie, "a forest-grouse icon in decline"; the bison "saved from extinction".
- **Archetype.** TALL.
- **Example.** *Last Capercaillie*, Tier 5, 4/4, Bird. "Endangered." With all 9 Tier 5 copies out it is 13/13.
- **Fun against.** A real dilemma: hate-buying a copy feeds theirs; leaving the copies lets them triple.
- **Ends.** A count, not a trigger, capped by copies per tier (5.1.2).
- **Async.** Only means something if lobbies share a pool (2.1.5).
- **Check.** Battlegrounds' anomaly Emergency Landing removes copies from the pool, but nothing reads the count.
- **From.** recruit 17.
- **Rules review:** Changes 5.1 and 5.3: pool counts become a stat. Needs a `poolCount` query. Async: whose pool, and "shown in any shop" reads other players' live shops (2.1.5). Bounded by copies per tier. Readable as a number on the card, but it tells you how many copies rivals hold.
- **Budget review:** *Last Capercaillie* T5 4/4: about 3–4 copies out of the pool mid-late (yours included, plus copies you hold) → +3/+3 to +4/+4 (E09, count-scaled) **[guess]** ≈ 14–16 against V(5) 12: +17% to +33% (±25%), edge, no flag. Hate-buys and held copies push it up. If the sim agrees, 3/3 (≈ 12–14). It depends on the async pool (2.1.5).

---

## Cut ideas from the creatures-first list

Not counted above. Kept so they aren't lost.
- **Churn (wild boar).** When this attacks, the target's slot is churned up: no summon can enter it this combat. Anti-WIDE (bends 8.4.1). Cut as the answer to Bud, Burrow and Bury if they prove too strong.
- **Echo (bat).** While this is on your board, you see the snapshot you will fight before you end your turn. Cut because it depends on archetypes.md question 6.
- **Brood (cuckoo).** A version of Brood (34) where the Egg hatches mid-fight and pushes out its neighbours.
- **Pouch (pelican).** Carry the unit behind this, safe, and release it when this dies. Cut as too close to Ride (31).

## Where this check changed a designer's label

| Mechanic | Designer said | This check | Parent |
|---|---|---|---|
| Sett | close variant | RESKIN | Galaxy slot buffs, already given by unit triggers |
| Gorge | new | VARIANT | BG Overkill (retired), Wildfire Elemental |
| Headstart | new | VARIANT | BG Heroic Broodmother, "Start of Combat: Attack immediately" |
| Alibi | new | VARIANT | BG Champion of Y'Shaarj, Arm of the Empire; Galaxy Prickles |
| Rival | new | VARIANT | BG Interrogator Whitemane |
| Play Dead | new | VARIANT | BG Reborn |
| Bud | new | VARIANT | BG Silver Goose |
| Burrow | new | VARIANT | BG Deity |
| Caravan | new (said so: "brings Battlegrounds' packing back") | VARIANT | BG packing |
| Bury / Fallow | new | VARIANT | Galaxy slot buffs |
| Stance | new | VARIANT | BG Choose One |
| Cache | new | VARIANT | BG anomaly Prudence of Amitus |
| Thrift / Revel | new | VARIANT | BG Tavern Tipper |
| Foundling | new | VARIANT | BG Elemental of Surprise, Zilliax modules |
| Pair | new | VARIANT | BG First Mate Pip, False Idols |
| Shoulder | variant of Taunt | VARIANT (parent changed) | BG Elistra the Immortal is closer than Taunt |

Most parents above are retired Battlegrounds cards, which the keyword glossary doesn't list; they were found in the card data. A twist on a retired card can still be good design. The label only says how far it is from what players have seen.

## Overlaps to settle later

**Same creature, several mechanics.** Picking a tribe's keyword will mean choosing between these.
| Creature | Mechanics |
|---|---|
| Hedgehog | Bristle, Curl, Both Ends (and the Market Hedgehog example in Aisle) |
| Badger | Hunker, Sett, Aisle |
| Dormouse | Bide (Slumber), Hibernate, Rehearse |
| Fox | Alibi, Play Dead, Barter (and Mark's foxes) |
| Stoat, weasel | Quick, War Dance, Flush |
| Heron | Bide, Fast |
| Wren | Ride, Last Word |
| Jay | Bury (Fallow), Mimic |
| Stork | Delivery, Fly South |
| Shrew | Caravan, Upkeep |
| Bison | Shrug, Shelter |
| Wolverine | Gorge, Cold Store |
| Marmot | Whistle (and Bide's Marmot Cantons) |

**Example names used twice.** *Reynard's Clerk* (Alibi, Tier 2, 2/3; Play Dead, Tier 3, 3/3) and *Hazel Dormouse* (Slumber, Tier 2, 1/3; Hibernate, Tier 2, 1/1). *The Rat King* (Knot) and *Mimic* are also names of Galaxy cards.

**Overlaps with archetypes.md.** Knot against the Oozes' Linked; Bud against the Oozes' Split; Changeling (the swap) against the Fairies' Changeling (a copy); Thicket against the Lights' Lure; Bury and Sett against the Fairy ring and Hedgerow Acorns; Rotate, Bolt, Caravan and Flush against the Diggers' Tunnel; Flush, Rival, Grudge, Nocturnal and Shiny against Swoop and Trample as back-row access.

## Questions for the owner

Merged from the four designers' lists and the rules and budget reviews, with duplicates combined. Where a reviewer proposed an answer, it is marked *proposed*.

1. **Rounding when damage is halved.** One rule for the whole game, or a choice per keyword? Rounding up means a 1-damage hit always lands (Hunker, Antlers, Whistle). Curl rounds down on purpose, so 1-Attack tokens can't hurt it.
2. **Turns that aren't attacks.** May a unit spend its place in the attack order on something other than an attack (Bide, Whistle, War Dance, Curl, Nocturnal)? If so, *proposed:* a skip costs only that unit's attack, not its side's turn (shared rule 2), and a fight ends as a tie when a full cycle of both sides deals no damage, instead of running to the 200-attack limit (R3). Still open: do non-attack turns count toward that limit?
3. **What the board holds besides one unit per slot.** Do you want non-unit objects in slots (Thicket, Brood's Egg, Bury's Nut, Fallow, Mark, Flood's water), and units that are in combat on no slot (Ride's riders, Burrow, Play Dead; Hibernate and Fly South between fights)? *Proposed:* one shared off-slot state, and one table (R7) saying what each kind counts for. And is 7 bodies a line to keep? *Proposed:* if riders may pass it, they stay at Tier 1–2 until simulated, since E23's +1 SP probably under-prices an eighth body.
4. **Reaching into the enemy's board.** Which of these may effects do: put objects in enemy slots (Brood), move enemy units (Flush), make a unit fight for the other side (Changeling), permanently change the opponent's board (Shiny's steal)? *Proposed:* no permanent change to the opponent, since fights are against snapshots, so Shiny's victim loses the stats for that combat only. Changeling alone needs units to fight for the other side (R10): hold it back from v0, or keep it with a condition such as "only if the enemy unit across has 6 Attack or less" so it stays on a unit budget. If enemy moves stay in, should Start of Combat keep its random side order (9.3.2), which decides results like Rival against Changeling, or use a fixed order?
5. **Bending fixed slots and free moves.** Three ideas break a placement rule. Caravan brings packing back for one tribe (8.3.4), Migrate makes a unit place itself each turn (8.3.3), and Aisle makes the slot a unit fought from pick which shop card it affects, so moves get a cost. Which are good rule-breakers, and which undercut fixed slots or become a chore?
6. **Owners for two open ideas.** Golden chasing has no tribe yet (archetypes.md 1.3). Foundling, Pair and Mimic serve it: should one tribe own it, or neutral units? And should shared damage go to rats (Knot, Hedgerow folk) or Oozes (Linked)?
7. **Smaller rulings, as a set.** Accept these defaults, or name the ones to change:
   - Reflected damage never triggers reflected damage. It becomes a system rule, which stops the Bristle, Curl and Both Ends chain (R2). Bristle reflects damage from attacks only, not enemy pings; Curl reflects all damage.
   - Protection beats reach: Shelter wins over Grudge, Rival, Nocturnal, Shiny and War Dance, and a reach unit whose target is protected attacks normally (R6).
   - Golden thresholds don't double, as 7.3.5 reads now: a golden Shrug, Shell or Cache keeps its N, so a golden Shell isn't weakened (R12).
   - Combat text that says "gains" with no duration means "this combat" (Slumber, Gorge, Alibi).
   - Thrift's "more gold than you started the turn with" counts this turn's income in the start. That fires on about 0.3 of turns; the "banked some gold" reading fires on about 0.7 and costs about 3 times as much.
   - Bargain's "if you can't pay" takes the gold you have as well as the Attack, so holding under 6 gold doesn't dodge the debt.
   - Pawn applies to Bought units only, so Created units still sell for 0, and pawning is limited to once per turn.
   - A Strong refresh spell from Brew is reviewed under G1 (R11), like any other unpaid refresh.
   - Sett goes to Tier 4 with the printed +1/+1 a turn, rather than Tier 2 with +1 Health a turn.
   - A third copy makes a Bonded pair golden at the normal golden size, not double the pair (four times one body). This is the reading that keeps it in budget; the review left it open.

Not asked here: Mimic, Endangered and Wager can't be judged until the async model (rulebook 2.1.4, 2.1.5) is settled.
