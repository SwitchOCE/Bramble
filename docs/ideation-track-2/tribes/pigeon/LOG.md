# Wood pigeons: log

Three rounds. Two were read by a fresh critic who saw only the unit list first. The last set of changes has not been read by a critic.

The current roster and retired texts are in [the 19 Nov rework](README.md). These notes record the earlier design rounds.

## Where the earlier draft ended

Four plans, not five: Parade ground, Hold the post, Old soldiers, Air wing. A fifth (a short board that fills up during the fight) was tried twice and both critics found it was the Post plan again, so its units were folded into Parade and the Post.

## Round 1

**Tried.** One idea under everything: the post matters more than the soldier.
- Every buff a pigeon gives to someone else goes on a slot. This is the owner's "buff the slots rather than teach other pigeons".
- Five plans: Parade, Post, Old soldiers, Air wing, and a "reserve" plan with an empty front row filled by 2/2 Privates.

**Dropped before the first draft, and why.**
- *Stepping up from the back row* (the "Close ranks" option). Back-row units already attack, so moving one forward only exposes it. Reserve from the hand does the same job and adds a body.
- *Recruits handed to the hand each turn.* Three tokens make a golden and a Discover from the next tier, every three turns, from a Tier 2 unit.
- *"Drill" as a word on cards.* Mice borrow slot buffs, and a second word for the same thing would break the one-term rule. Cards say "give this slot". Drill is the plan's name.
- *A Colour Ensign whose neighbours copy his slot.* It made one tall slot better than seven even ones in every case.
- *"When played" effects.* None are used, so the tribe works the same if play effects move to "when bought" (owner's ideas log, 15 Nov).

**The critic found** all five plans and the splash units without being told. Problems:
- Parade had about twice the stats of the others. The causes were an Ensign that gave every slot the weakest slot's buff, and a Tier 3 volley that grew with the Drill.
- The reserve plan gave up real units for 2/2s and had no payoff before Tier 6.
- The Padre had no limit, which matters on a Locust board.

**Changed.**
- Colour Ensign: his own slot copies the strongest slot. He is now the Post's Tier 5 unit.
- Recruiting Sergeant: fills an empty slot in front of him at any point in the fight, 2 a fight, so he works behind a full front row too.
- Padre: 8 a fight.

## Round 2

**The critic found** four plans. Problems:
- The Post and the reserve plan were one plan: same units, same board with a Bugler swapped in.
- The Lance Corporal ("give a slot +4/+4" for 1 gold) was the engine of three boards and every other tribe's best Tier 2, and it didn't matter where he stood.
- The queue leaked: a reserve could step into the wrong emptied slot and miss the post.
- Units that take another unit's stats (the Locusts' Eat, a Badger heir) could take a slot's buff with them.

**Changed.**
- Four plans. The replacements (Territorial, Recruiting Sergeant, Bugler) became Parade's way of fighting, which Parade lacked, and stay as the Post's queue. The two plans now differ in where the Drill goes: every slot, or one.
- Lance Corporal: "give the slots in front of this +2/+2". He needs a back slot, like the other officers.
- Reserve units and Privates go to the Guard post first.
- Slot buffs never travel with a unit: copies and "gain its stats" effects use the unit's own stats.
- Lieutenant moved to Tier 4 and his volley reads the slot's Attack buff again. The Mouse designer had already built on that (slot Attack makes the volley bigger). Grenadier Guard moved down to Tier 3, so the Guard post arrives earlier.

## What worked

- Slot buffs made other tribes' units fit without trying: Hoppers, Compost copies and Cousins land in a drilled slot and have its buff. Three other designers wrote that into their own units.
- Reserve was the unit both critics named first as the one that makes a player sit up, with The Colonel.
- Putting the officers' effects on "the units in front of this" gives a real choice: four officers want the three back slots.

## Not sure of

- **Parade against the Post.** They share eight units. The boards are different, but a player may feel them as one plan with a dial.
- **Reserve costs the engine something:** the hand becomes part of a fight, and a saved board has to carry it.
- **Air wing before Tier 5** is two Aces and a Squadron Leader: a package, not yet a plan.
- **"trail"** in the owner's note is read as "Drill".

## 17 Nov 2026: made one game with the other four tribes

Not a design round. One pass over all five tribes wrote [../SHARED-RULES.md](../SHARED-RULES.md), the glossary and the rulings where tribes meet, and brought this tribe's files into line with it. No stats, tiers or costs changed.

- **Slot multipliers** (shared ruling 13). Before: "two effects that multiply slot buffs don't multiply each other: the bigger one applies". Now: the Regimental Sergeant Major doubles a buff when it is given, the Mice's Edgewright doubles what slots give in a fight, and one of each stack; two of the same kind still don't. Why: the old rule needed the engine to remember which part of a slot's buff had been doubled, and it left the Mice's slot capstone dead beside ours. The Lieutenant's dial (half the buff) matters more now.
- **Recruiting Sergeant's text:** "summon a Private there" (was "a 2/2 Private"), with the reminder *Private: A 2/2 Pigeon.* Why: the Mice and Locusts name their token and put its stats in the reminder.
- **Recruiting Sergeant's Privates come after waiting summons** in an emptied slot (shared ruling 6): own death effect, return, Reserve, waiting Hoppers and Compost copies, then Privates. Before: after Reserve, with waiting summons not placed.
- **Cleave is ours alone.** The README said Guard and Cleave were Badger keywords. The Badgers replaced Cleave with Overrun; Cleave and Private now have rows in the keyword table.
- **Badger cross-references fixed.** No Badger card counts empty slots, there is no Sett Steward, and Privates and Reserve units don't end a Badger's being outnumbered: the count is fixed when the fight starts and units in hand aren't counted. A lone Badger does have a back row (its Squires), so the Air wing is good against it, not bad.
- **Start of fight:** Recruiting Sergeant and Colour Ensign resolve in the set-up pass; Lieutenant and Wing Commander in the main pass. Capital after the colon on Lieutenant, Colour Ensign and Wing Commander.
- **"The Volley"** is no longer a name; the Lieutenant now shows the slot buff reminder.
- **Reserve** is written as its own rule block: a unit "in Reserve", not a "waiting" unit (waiting now means a summon with no slot); a permanent gain it earns goes to the unit in hand; a return is not "joining the fight".
- **units.json fields.** Same fields as the other four tribes: `tribe` and `type` on every unit, a `golden` field, `splash_for` on every unit (empty unless it is a splash piece), tribe rule blocks under `rules`, and `note` renamed `implementer` and rewritten to say how the card works under the shared rules.
