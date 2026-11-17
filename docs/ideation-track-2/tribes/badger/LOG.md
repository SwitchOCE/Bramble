# Badgers: design log

Three rounds, each read by a fresh critic who saw only the unit list first. The tribe was rebuilt twice. Short version: Fury as first written did not carry a tribe, and most of the work was finding a form of it that does.

## Round 1: Fury as an attack trigger, five plans

**Tried.** Fury as the options page had it: "whenever this attacks while you're outnumbered", mostly +stats. Around it: units that grow for each empty slot on your board, a Guard wall, a squire who holds Attack and adds it to the Knight in front (Armsbearer), a first-strike Lancer, and units that inherit from the dead. Five plans: Alone, The Order, The Lance, The Gate, The Last Oath.

**The critic found.**
- Only one plan was real: two Armsbearers behind anything. It needed no Fury, and mice wanted the card more than badgers did.
- The two plans named after Fury lost at turn 9. Flat +1/+1 to +3/+3 is noise against 18/22 units, and Fury switched on at six units against seven, so staying small bought nothing.
- The Gate and The Last Oath were one plan.
- Nobody would buy the empty-slot gold unit, the Cub, the Master-at-Arms or the Berserker.

**Kept.** The squire who holds the Knight's stats; the first-strike Lancer; Herald; the heir; Old Brock.

**Dropped.**
- Counting empty slots (three units). One measure, outnumbered, is enough.
- Plate (armour that takes a flat amount off each hit). It was on two units and risked walls that small attackers can't hurt at all.
- The Bulwark's answering attack from behind: the unit answering died doing it.

## Round 2: Fury scales with how outnumbered you are

**Tried.** Fury N: whenever this attacks or is attacked, +N/+N for each unit you're outnumbered by, counted live. Staying small now matters: one unit against seven gets six times the gain. Armsbearer's Attack only grows after fights started outnumbered, so mice can't run it. Four plans.

**The critic found** (with a small fight simulation):
- A lone Berserker with two Master-at-Arms beat seven units every time. Adding any Squire behind it made it lose, because every Squire lowered the count. The tribe's two halves, Knights and Squires, were fighting each other.
- Fury that gives Health makes a cliff: once each hit gives more Health than it takes, the unit can't die.
- Because the count was live, Fury faded as the badger won, and fights ended in double knock-outs.
- The Order was Alone with extra bodies, and worse. The Bulwark was still dead.
- Fights were decided by unit count more than by anything either player did.

**Kept.** Fury scaling with the count. Fury triggering when attacked as well as when attacking, which answers "the outnumbered side attacks second".

## Round 3: Knights and Squires

**Tried.** The rebuild that is in the files now, at its core:
- The count is fixed when the fight starts, and back-row Squires aren't counted. A Knight can have a retinue without losing its Fury.
- Fury gives Attack only. Overrun (extra damage carries on to the next enemy) is what makes more Attack worth having. Health comes from the Shield-bearer's loan and from Grudge.
- Grudge is the kept fury: after each fight, +1/+1 for each unit outnumbered by. The lenders have it, the Cub has it, and the Grudge-keeper gives it to every Knight.
- Lance (takes no damage when it attacks) for the plan that doesn't lean on Fury.

I checked boards in my own rough simulation before sending it out. It showed the Order was real once the Sexton was in it, and the Last Oath needed the Sexton at +2 Fury.

**The critic found.**
- Red Mist is the owner's pick and Fury is its engine. The choice between one Knight and two is a real one.
- Lance was the strongest plan and ignored Fury. With the Oakfeller it beat everything, and other tribes could pump a Lancer for the same effect.
- The Order was the weakest plan on the board I had written for it.
- The Last Oath stood on the Sexton; the Sword-heir added little.
- A full board with three Squires still counts as outnumbered by 3. Grudge and Relic Seeker pay even when you lose. Two Relic Seekers stacked.
- Eight words to learn is a lot. Cut Lance first.
- My Red Mist board had a Herald in a slot where it did nothing: a front slot has only two slots behind it.

**Changed after it** (no fourth review):
- Lance is gone as a keyword. The Lancer and the Champion take no damage on their start-of-fight strike only, and both have Fury. The Oakfeller is now a Fury unit. The plan is called The Charge.
- Dame gives her Knights +2 Fury as well as Overrun, and the Order's board has the Sexton where the Herald was. In my simulation the Order then holds its own; nobody else has checked that.
- Sword-heir also takes the dead unit's Fury, and moved to tier 3; the Sexton moved to tier 4.
- Only one Relic Seeker pays. Squire's wording is narrowed to the count only, and enemy Squires are left out the same way.
- "This fight" added to Sword-heir and Old Brock.
- Boards in the README corrected and re-run.

**Not changed, and flagged in the README for the owner:** a full board can count as outnumbered; Grudge pays on a loss; every plan is weak to a few big units; Master-at-Arms has no limit; the heirs on a locust board.

## What worked and what didn't

- **Worked:** one number for the whole tribe (the count), used in the fight (Fury) and after it (Grudge). Squires that hold stats and lend them forward: it fits two rows and fixes the tall tribe's usual problem, that upgrading the big unit throws away what you built. Asking critics to play the turn-9 boards out: both rebuilds came from that.
- **Didn't work:** Fury as flat stats; a count that changes during the fight; Fury that gives Health; a second measure (empty slots); a Guard wall as its own plan; a keyword that makes a unit untouchable.
- **Still unsure:** whether four plans are as even as they look. The simulations use plain enemies and flip on a few stat points. The Last Oath is the thinnest plan before tier 6. The tribe likely runs hot against wide boards and cold against a few big units.

## 17 Nov 2026: made one game with the other four tribes

Not a design round. One pass over all five tribes wrote [../SHARED-RULES.md](../SHARED-RULES.md), the glossary and the rulings where tribes meet, and brought this tribe's files into line with it. No stats, tiers or costs changed.

- **Card text, three cards.** Sett Sexton "Whenever another friendly Badger dies", Old Brock "Whenever a friendly unit dies" and Sword-heir "When a unit in front of this dies" now all start "After …". Why: the Pigeons and Locusts write that trigger "After a friendly unit dies", the notes here already resolved it at that step, and one trigger word should mean one moment.
- **Sword-heir and Old Brock take a unit's own stats only** (shared ruling 43). Before: "as they were when it died, lent stats included". Now: printed stats and buffs on the unit, this fight's gains included, and not its slot's buff, lent stats, auras, the Tide or the Hopper bonus. Why: every tribe needed one answer to "what moves when stats are taken", and the Pigeons (slot buffs) and Locusts (the Tide) had already ruled theirs out. This weakens the Last Oath: the heir ends about 27 Health lower on the README board. Flagged for the owner in the README with a dial.
- **"Takes no damage" means from anything** while the opening strike resolves, Thorns included (Hedge Lancer, Tourney Champion). Before: only the damage exchange. Why: it is what the card says, and otherwise a 6-Health Lancer dies on its own opening against any thorn.
- **The count:** units in hand are never counted, and nothing in the fight changes it (Privates, Hoppers, copies from the Compost, Reserve). Same rule as before, now written for every other tribe's arrivals.
- **Relic Seeker:** if a player has several, the one that pays most pays (a golden one). Before: "only one pays", not saying which.
- **Stale names fixed in the README:** Needle Squire is Needle Pikeman; "a briar board that has buried most of itself" is the Regrowth board (Bury takes shop units); Cleave is a Pigeon keyword.
- **units.json fields.** Same fields as the other four tribes: `tribe` and `type` on every unit, a `golden` field, `splash_for` on every unit (empty unless it is a splash piece), tribe rule blocks under `rules`, and `note` renamed `implementer` and rewritten to say how the card works under the shared rules.
