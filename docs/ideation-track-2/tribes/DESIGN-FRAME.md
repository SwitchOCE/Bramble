# Tribe design frame (plan step 3)

For the designers of the five tribes. The owner's words are quoted; everything else is the orchestrator's proposal and can be changed by a designer who says why in the log. Nothing here is decided for the real game: this is an ideation track.

## The owner's words (16 Nov 2026)

On the first mechanic options, and what a tribe needs:

> "I think there's some weak designs there that might have been caught when you tried to flesh them into full tribes. If a tribe's not looking good and, it, you know, comparing it to like, the, you know, finding like 4 or 5 different sub-setups that all kind of seem like similarly interesting and competitive with one another, you know, and reasons you might want to run them and ways the units could be used with other tribes so that not just, you know, some of the units in the tribes are flexible and, you know, etc. You may have to go back to the beginning and try again with stuff. You have my permission to iterate multiple times and log what worked and what didn't, and I'll check it when we look at the build."

From the note on the mice, which speaks to every tribe:

> "I think, like, you're looking at the core mechanics as too simple, and the tribes will fall apart. They need to have a mix of units to provide different things and different strategies, right? If you were to look at a tribe like beasts Battlegrounds, there's like four or five different sub-strategies you can run. There's attack scaling beasts where you try and scale the attack with a five-drop and banana slammer. There's Lobster Beast, where you try and trigger lobster Deathrattle repeatedly. There's like rally beasts, where they use them to get money and use the money to try and trigger more rallies that trigger Deathrattle. You can either use Goldrin or something else. There's like Beetle Scaling Beasts. There's like, you know, all the cards kind of tie together and form a bunch of different options and strategies. And none of these tribes are really pitched as one-dimensional. They should have like three or four effects that kind of work together and kind of can either mesh together or serve as pieces for, you know, other tribes as well, and a bit flexible. It needs to be a bunch of overlapping, like horizontal design as well as vertical design. If mice only care about being near other mice, they're not interesting options for any player who doesn't have a mouse on their board. That doesn't mean that all units should not care about other mice. Some should, some shouldn't. There needs to be a mix. Think about the tribe as having to have multiple different sub-strategies"

Each tribe's pick and note are in [../HANDOVER.md](../HANDOVER.md), as the owner wrote them. Read your tribe's and the other four.

## What a finished tribe has

1. **19 units, 2 / 3 / 4 / 4 / 3 / 3 by tier** (the owner's shape), each with name, tier, Attack, Health, full card text in the `ux-copy` wording, and reminder text for any keyword.
2. **Four or five sub-strategies,** each written as: the plan in one sentence, its key units (an enabler by Tier 3, a payoff by Tier 5 or 6), why a player would choose it over the tribe's other plans, and what beats it. They should look about as interesting and as strong as each other. Units should overlap between plans: most units serve two.
3. **Units other tribes want.** Mark each unit as tribe-only (it names its own tribe), open (it works on any unit) or a splash piece (another tribe's plan would buy it on purpose, and you can say which plan). Aim for about a third tribe-only, a third open and a third splash. A tribe where every unit names its own tribe fails this.
4. **A tier check** against [the tier guide](../../design/tier-guide.md): one line per tier, and where it breaks the guide on purpose. Numbers use the rulebook's working scale, about double Battlegrounds (rulebook 1.2.5). Start generous; the owner balances afterwards ("They're more creative. They feel more powerful. I can balance them afterwards.").
5. **Rules it needs** that the rulebook doesn't have, each in one line, so the engine worker can build them.

## Shared ground between the five tribes

These are the things more than one tribe touches. Design your tribe to give to and take from them, so that mixed boards have reasons to exist. Each tribe owns one and borrows from two or three.

| Shared thing | What it is | Owner | Others that plug in |
|---|---|---|---|
| **Slot buffs** | Permanent buffs on a board slot (rulebook 8.5): whatever stands there has them, and they stay when the unit dies, moves or is sold | Pigeons (the owner: "maybe Pigeon should buff the slots rather than teach other pigeons") | Mice ("some slot attack scaling too"); summoned locusts and mice land in buffed slots; a lone badger in the best slot |
| **Attack triggers** | "Whenever this attacks", and units joining another's attack | Mice (Pile on) | Badgers (Fury is an attack trigger); anything that grants extra attacks feeds both |
| **Deaths and summons in the fight** | Units that leave bodies behind, come back, or grow the swarm as it dies | Locusts (the owner: "a summoning tribe, more similar Battlegrounds Undead") | Briars (Root comes back from the Compost); mice ("a few units that summon stuff") |
| **Selling and the Compost** | A heap that sold or buried units go into, and that units grow from or spend | Briars (the owner: "Compost wasn't optional. That's what we're doing. Find a way of making it work") | Any tribe's cheap units are compost; locust nymphs and mouse tokens could feed it if a card says so |
| **Being outnumbered** | Fewer units than the enemy | Badgers (Battle fury) | A briar board that has buried most of itself; a pigeon board that keeps empty buffed slots in reserve |

## Starting points for each tribe

Starting points, not designs. Replace any of them and log why.

- **Badgers, tall, Battle fury.** Plans to look for: the lone berserker who grows each swing while outnumbered; fury that is kept between fights; a knight who guards others (must-be-attacked, armour) and is a splash piece for any tribe's carry; cleave or trample as the answer to wide boards (the seeds page noted these are thin elsewhere); a small order of two or three knights who share fury.
- **Mice, volume, Pile on.** The owner wants Attack scaling and not Health: mice stay easy to kill. Plans to look for: Pile on with Attack buffs spread wide; slot Attack buffs that summoned mice inherit; summoners that keep the row full so there is always a neighbour; a "many small hits" payoff (effects that count attacks or hits); a siege crew that hits before the lines meet.
- **Wood pigeons, medium, Medals and Drill.** The owner finds this "a bit bland as is" and asks for "additional spice". Plans to look for: Drill as permanent slot buffs laid down turn by turn; Medals for surviving, and things that happen at 3 or 5 Medals; the reserve stepping up from the back row; orders (one-shot commands with a cost, the sergeant major shouting) as the spice; messenger pigeons that carry a buff or a Medal from one unit or slot to another.
- **Locusts, summoning, like Battlegrounds Undead.** The owner: "they kind of like swarm and, you know, leave devastation in their wake and breed more locusts." Plans to look for: breeding on death; permanent Attack for the whole swarm as locusts die (Undead's shape); coming back; devastation, meaning damage or stat loss left on the enemy or the shop as the swarm passes; a swarm-size payoff. Keep it apart from mice: mice hit together and are fragile on purpose; locusts die and come back, and get stronger for dying.
- **Briars and thorns, Compost.** Not optional. The friend's parts were Bury (put a shop unit in the heap for a cost), Root (when this dies, spend Compost to come back), Seed (when this dies, put copies in the heap) and Grow (start of fight, gain stats from the heap). Open choices for the designer: one heap or one per slot; what goes in (sold units, buried units, spells); whether Compost is spent or only counted; a limit. Plans to look for: Grow tall from a big heap; Root as a wall that keeps coming back; Bury as economy (the shop feeds the heap); thorns that hurt attackers, scaled by the heap; a mixed plan where any tribe's sold units are fuel.

## How the work runs

1. **Draft** the whole tribe once, quickly, with its sub-strategy table.
2. **Test it yourself against point 2 and 3 above.** For each sub-strategy, write the board a player would have at about turn 9 (seven slots, which units, where) and what it does in a fight. If you can't write a board for a plan, the plan isn't real. If two plans end with the same board, they are one plan.
3. **A fresh critic** (another agent, who didn't write it) reads only the unit list and tries to find the plans without being told them, then reads the table and says which plans are thin, which units nobody would buy, and which units only work at home.
4. **Revise or start again.** Starting again is allowed; say what you kept.
5. **Log** each round in `LOG.md` next to your tribe file: what you tried, what the critic found, what you changed, what you dropped and why. The owner reads this log with the build. Short entries; no process talk.

## Files

- `docs/ideation-track-2/tribes/<tribe>/units.json`: the 19 units as data (id, name, tier, attack, health, text, reminders, keywords, plans it serves, reach: tribe-only, open or splash, and a plain note for the implementer on exactly how it works).
- `docs/ideation-track-2/tribes/<tribe>/README.md`: the sub-strategies with their turn-9 boards, the tier check, and the rules it needs.
- `docs/ideation-track-2/tribes/<tribe>/LOG.md`: the rounds.
