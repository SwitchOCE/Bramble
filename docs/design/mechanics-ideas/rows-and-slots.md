# Mechanics ideas: rows and slots

**Status: goldfish ideation, 2 November 2026. Not adopted, not costed.** This is one of several idea lists written in answer to the owner's ask for "explicit attempts to create different effects than just what exists in Hearthstone Battlegrounds", and to "experiment with slot buff mechanics" because "We have set slots" ([2026-11-02f](../owner-notes/archive/2026-11-02f-new-effects-and-goldfish-designers.md), [2026-11-02e](../sources/2026-11-02e-mechanics-are-examples.md)).

**Angle:** the two rows and the fixed slots. That covers slot effects that stay when units change; front and back; in front of and behind; across from; gaps and empty slots as resources; moving and swapping; summon space; rows that change during combat.

**How to read it.**
- I was not shown the power budget. Every number on an example unit is by feel; balance is someone else's job.
- Keyword names are working names. Battlegrounds and Galaxy keywords mentioned below (Taunt, Magnetic, Reborn and so on) are illustrations, not Bramble mechanics (11-02e).
- "Bends" cites the [rulebook](../rulebook.md) rule each mechanic changes or breaks. Archetype IDs are from [archetypes.md](../archetypes.md) §1.2: ECO, WIDE, TALL, MEDIUM, STICKY, and the spices SCAM and BURST.
- **Close variants** of an existing keyword are marked. There are 4 of 18: Sett, Stowaway, Thicket and Shelter.

## Index

| # | Keyword | One line | Bends | Archetype |
|---|---|---|---|---|
| 1 | Sett *(variant)* | The slot grows each turn and keeps its growth for whoever lives there next | 12.2.1, 8.2.4 | MEDIUM, TALL |
| 2 | Fallow | Empty slots ripen over turns; the first unit to land there harvests them | 8.3.1, 9.1.1 | WIDE |
| 3 | Caravan | This unit closes up gaps to its left, bringing Battlegrounds-style packing back for one tribe | 8.3.4, 9.4.9 | WIDE, MEDIUM |
| 4 | Rotate | After attacking, swap with a fresh unit behind it, as geese rotate the lead of the V | 9.5.1, 8.3.5 | STICKY |
| 5 | Bolt | The first time it's hurt, dive into an empty back slot | 9.5.1, 9.4.9 | STICKY, WIDE |
| 6 | Stowaway *(variant)* | Rides another unit without using a slot and leaps out when its host dies | 8.1.1, 7.2.2, 8.4.1 | WIDE, STICKY |
| 7 | Brood | Lays an Egg in an empty enemy slot; it blocks their summons, then hatches for you | 8.4, 9.9.1 | SCAM, anti-WIDE |
| 8 | Mark | Scent-marks the enemy slot across from it; anything that enters that slot gets hurt | 8.2.4, 8.4.1, 9.8.3 | anti-WIDE, anti-STICKY |
| 9 | Thicket *(variant)* | Empty front slots grow bramble walls that soak attacks but aren't units | 9.5.1, 9.9.1 | STICKY |
| 10 | Flush | Drags the enemy's best back-row unit into their front row | 8.3.5, 9.5.1, 11.5.3 | SCAM |
| 11 | Rival | Duels the enemy across from it, even in the back row, at double damage | 8.2.6, 9.5.1, 9.5.5 | SCAM |
| 12 | Bide | A back-row unit that won't attack while shielded, and grows each time it waits | 9.4.5, 9.4.2 | TALL |
| 13 | Shelter *(variant)* | Protects the back slots behind it by column, even after the rest of the front row falls | 9.5.1, 11.5.3 | STICKY |
| 14 | Both Ends | Two twins at the far ends of a row guard each other across the gap | 8.2.2, 8.2.5 | MEDIUM, STICKY |
| 15 | Solitary | Double Attack while no friendly unit touches it | 8.2.3, 8.3.1 | TALL |
| 16 | Migrate | Moves itself to the next empty slot each turn and grows; the player steers it by blocking slots | 8.3.3 | MEDIUM |
| 17 | Stance | Two stat lines or texts, one per row; it flips when it changes row | 8.2.7, 12.2.1 | any (building block) |
| 18 | Delivery | All your summons land next to this unit instead of next to their source | 8.4.1–8.4.3, 9.4.8 | WIDE |

---

## Slot effects that stay when units change

### 1. Sett *(close variant of Galaxy's slot buffs)*

**Rules.** End of Turn: this unit's slot gains +1/+1 Sett. The Sett belongs to the slot, not the unit. Whatever unit stands in that slot, now or later, has the Sett's stats, including units summoned into it mid-combat.

**Bends.** 12.2.1: auras end when their source leaves; a Sett outlives the badger that dug it. 8.2.4: "relations belong to slots" is extended from relations to stats.

**Creature.** Badgers. Their setts are dug over generations and handed down. In the Folio they are the "faded gentry, landlords of ancient setts". The house is the heirloom, not the badger.

**Archetype.** MEDIUM and TALL, with the slot as the landing (archetypes §1.1). It is also a soft WIDE payoff, since a token summoned into the slot of a dead unit (8.4.1) moves into a mansion.

**Example.** *Old Brock*, Tier 2, 2/4, Badger. "Sett. When you sell this, its slot's Sett gains +2/+2." The landlord retires and leaves the house to the heir.

**Fun to play against.** Killing the unit in their big slot doesn't end the threat: the next token that moves in is huge too. You start reading their *slots* as the threat, and you value effects that keep things out of a slot (Brood, Mark).

**How it differs from Galaxy.** Galaxy's slot buffs come from many sources. Sett grows only while it is lived in, so who sits where each turn matters, and it pairs with Caravan and Delivery to steer units into the sett.

### 2. Fallow

**Rules.** While this is on your board, at End of Turn each empty slot on your board gains +1/+1 Fallow (up to +3/+3 a slot). The first unit to enter a fallow slot harvests it: in the Recruit Phase it keeps the Fallow permanently and the slot resets; in combat, a summon takes it for that combat only, and the slot on the recruit board stays ripe.

**Bends.** 8.3.1: gaps are legal but today cost only a body. Fallow makes an empty slot an investment that pays later. 9.1.1: because combat runs on a copy, a ripe slot feeds a combat summon every fight until a recruit unit harvests it.

**Creature.** Jays, who plant thousands of acorns that grow into oaks (Folio hook "Investment"), and Greenwood. The farmer's field left fallow so it comes back richer.

**Archetype.** WIDE: Deathrattle-style summons and Delivery land in ripe slots. It also rewards the tempo decision to field fewer units for a few turns.

**Example.** *Jay Forester*, Tier 3, 3/3, Bird. "Fallow. Start of Combat: summon a 1/1 Oakling into your empty slot with the most Fallow."

**Fun to play against.** Their board looks thin, then every death fills a ripe gap with a buffed sapling. You learn that an enemy's empty slots are loaded, not free.

---

## Moving, swapping and rows that change during combat

### 3. Caravan

**Rules.** In combat, whenever the slot to the left of this unit in its row is empty, it steps into it at once. Several Caravan units in a row step one after another, so a line closes up.

**Bends.** 8.3.4, no packing. Caravan brings Battlegrounds' packing back as a keyword, for one tribe only. A unit that moves keeps its attack flag, and stepping into a slot below the attack pointer flags it (9.4.9), so a fast-closing line can lose attacks. That is a real cost.

**Creature.** Shrews. Young shrews travel in a line, each holding the next one's tail (Folio hook "Formation").

**Archetype.** WIDE and MEDIUM. It keeps adjacency chains whole after deaths, so "adjacent" text keeps working, and it pulls units into the in-front-of and behind slots of the units that died.

**Example.** *Shrewlet Train*, Tier 1, 2/1, Shrew. "Caravan. After this steps, gain +1 Attack this combat."

**Fun to play against.** Your Cleave (11.2.7) loves them: the line keeps closing, so every hit has neighbours to splash. As they shuffle left they also leave the right-hand end, which empties the slots your across-from effects were facing.

### 4. Rotate

**Rules.** After this attacks, if it is still alive, it swaps places with the friendly unit behind it that has the most Health. The unit that comes forward keeps its own attack flag.

**Bends.** 9.5.1: back-row protection becomes a place to rest mid-fight. 8.3.5 and 9.4.9 cover the swap. The back row stops being a fixed reserve and becomes a bench.

**Creature.** Geese. A V of geese rotates the bird at the point so the lead is shared. The Folio's goose is a sentinel, "flies in a V; aggressive".

**Archetype.** STICKY, because wounded units retire behind cover, so each body takes more hits. MEDIUM too, because fresh back units get time in front.

**Example.** *Lead Goose*, Tier 3, 4/4, Bird. "Rotate. A unit that swaps forward with this gains +2 Attack this combat."

**Fun to play against.** You see their 1-Health goose slip into the back just before you'd kill it. Your back-row reach (Swoop, Rival, random effects) suddenly has a juicy target. The swap also pulls their fragile support forward into your attacks.

### 5. Bolt

**Rules.** The first time this survives damage in a combat, it bolts: it moves into an empty back slot behind it. If no slot behind it is empty, it stays.

**Bends.** 9.5.1: a unit leaves the targetable row by itself. Where it lands in the attack order follows 9.4.9. The front gap it leaves is summon space (8.4).

**Creature.** Rabbits. They thump a warning and vanish down the warren (Folio: "Thumps to warn the warren"; Watership Down).

**Archetype.** STICKY (a hit that doesn't finish it sends it out of reach) and WIDE (the gap it leaves gets refilled).

**Example.** *Warren Lookout*, Tier 1, 1/3, Rabbit. "Bolt. After this bolts, summon a 1/1 Kit into the slot it left."

**Fun to play against.** The bunny runs away, and a kit pops out of the hole. The tell is visible: a rabbit board has to leave back gaps for its bolt holes, and you can see them.

### 6. Stowaway *(close variant of Magnetic, and of a second life)*

**Rules.** Play this onto a friendly unit instead of into a slot. It rides there, using no slot, and can't be targeted. When its host dies, it leaps out into the host's slot before the host's own death effects summon anything.

**Bends.** 8.1.1 and 7.2.2: the board can hold more than 7 bodies, and a Stowaway can be played onto a full board. 8.4.1: the rider jumps ahead of the host's own summons for the dead unit's slot, so those summons go to the nearest empty slot. One rider per host.

**Creature.** Wrens, which hid on the eagle's back to fly highest (Folio hook "Rider"). Mice stowaways, who "ride larger allies into battle".

**Archetype.** WIDE (an eighth body and beyond) and STICKY (every host takes two kills).

**Example.** *Wren King*, Tier 2, 2/1, Bird. "Stowaway. When this leaps out, it attacks immediately."

**Fun to play against.** You finally drop their bear, and a furious tiny wren bursts out of its fur and pecks your damaged unit to death. Riders are drawn on their hosts, so you can count them before the fight.

**How it differs from Magnetic.** Magnetic fuses for good. A Stowaway stays itself and separates on death, so it is a stored body, not a buff.

### 7. Brood

**Rules.** Start of Combat: lay an Egg in the empty enemy slot across from this, or in the nearest empty enemy slot if that one is full. The Egg belongs to neither side: it can't attack or be attacked, protects nothing, and only takes up the slot. After the enemy side has made 3 attacks, it hatches into a 3/3 Cuckoo Chick for you, in your empty slot nearest this unit.

**Bends.** 8.4: summons today land only on their own side. Brood puts an object on the enemy board and fills their summon space. 9.9.1: the Egg is not a unit, so it never keeps a board alive.

**Creature.** Cuckoos, brood parasites that lay their egg in another bird's nest (Folio hook "Sabotage").

**Archetype.** An answer to WIDE, whose summons need empty slots; a SCAM-like spice.

**Example.** *Cuckoo*, Tier 3, 2/2, Bird. "Brood." Golden: two Eggs.

**Fun to play against.** Your Deathrattle tokens fizzle because a cuckoo egg is sitting where they wanted to land. You start leaving a decoy gap, or play summoners whose summons go somewhere else (Delivery).

---

## In front of, behind and across from

### 8. Mark

**Rules.** Start of Combat: scent-mark the enemy slot across from this. For the rest of the combat, each enemy unit that enters a marked slot takes 3 damage.

**Bends.** 8.2.4: slot relations are turned against the enemy. The mark is a hostile slot effect that stays when the unit there changes. It punishes 8.4.1 (a death summon takes the dead unit's slot first) and 9.8.3 (a unit that comes back returns to its own slot).

**Creature.** Wolves and foxes, which scent-mark territory. In the Folio, Hunters "follow wolves to kills".

**Archetype.** An answer to WIDE and STICKY, which refill and return into their own slots.

**Example.** *Gubbio Wolf*, Tier 2, 3/2, Hunter. "Mark. After an enemy dies in a marked slot, this gains +1/+1 this combat."

**Fun to play against.** Your Reborn-style rabbit pops back into its slot, steps on the scent and dies again. The counterplay is a summoner that lands elsewhere, or Caravan units that step out of the slot.

**Async note.** Across-from can't be aimed in async play (archetypes §3, rule 3). Mark doesn't need aiming: refills always go into the dead unit's own slot, so whatever stands across is the slot that gets refilled.

### 9. Thicket *(close variant of Taunt-style decoys; compare Lights' Lure in archetypes §4.1)*

**Rules.** Start of Combat: each empty front slot in front of this grows a Thicket with 3 Health. Thickets are front-row attack targets that never attack, and they don't count as units for winning, for attack order or for hero damage. A summon into a Thicket's slot clears it.

**Bends.** 9.5.1: back-row protection today comes from front-row *units*; here terrain counts. 9.9.1 and 9.2.1: Thickets aren't units, so a side left with only Thickets has lost. Thickets have no death effects, so killing them feeds nothing.

**Creature.** Brambles themselves, the game's name. Greenwood or Hedgerow folk grow hedges over their burrows.

**Archetype.** STICKY, and the protected-engine geometry that MEDIUM and TALL use (archetypes §1.2).

**Example.** *Bramble Warden*, Tier 2, 1/4, Greenwood. "Thicket. Units that attack your Thickets take 1 damage." The thorns.

**Fun to play against.** You hack through hedges while their real units behind grow. Cleave and Trample cut through brush, so you learn to value them.

**How it differs from Taunt.** It isn't a body. It can't be buffed, doesn't die, and comes from the gap itself.

### 10. Flush

**Rules.** Start of Combat: the enemy back-row unit with the highest Attack swaps places with the enemy unit in front of it that has the least Health. If no unit is in front of it, nothing happens.

**Bends.** 8.3.5: an effect moves an *enemy* unit. 9.5.1: back-row protection is beaten by moving the target, not by reaching over the front row. It is a third answer to the open question of back-row access (11.5.3), next to Swoop and Trample in archetypes §3.

**Creature.** Weasels, stoats and ferrets, which hunt inside burrows. Ferreting is the old trade of driving rabbits out of the warren.

**Archetype.** SCAM spice. It brings the enemy carry into the Hunters' line of attack.

**Example.** *Burrow Weasel*, Tier 3, 3/3, Hunter. "Flush. This attacks the unit it flushed first, if that unit lives."

**Fun to play against.** It has a real counterplay that costs something: leave both front slots in front of your carry empty, so there is nothing to swap with. That gives up a key slot, and the flushed weakling ends up safe in your back row.

### 11. Rival

**Rules.** Start of Combat: the enemy unit across from this becomes its Rival. While the Rival lives, this attacks only its Rival, even if the Rival is in the back row, and the two deal double damage to each other.

**Bends.** 8.2.6, across from, becomes a duel. 9.5.5's random target and 9.5.1's back-row protection give way to the column. A back-row Robin duels the enemy back-row unit across from it.

**Creature.** Robins, which defend their territory against rivals, sometimes to the death (Folio: "Fights rivals to the death"; the bard who duels).

**Archetype.** SCAM spice. A small robin trades into whatever big thing it faces.

**Example.** *Robin Redbreast*, Tier 2, 3/2, Bird. "Rival. If this kills its Rival, gain +2/+2 permanently."

**Fun to play against.** A tiny robin challenges your carry, and double damage both ways means it usually dies gloriously. Sometimes it wins, and the robin who killed a bear is a story worth telling. An empty slot across from it means no Rival, so gaps defend against it (Galaxy design-notes §5, idea 11).

**Async note.** As with Mark, it can't be aimed in async play. The fun is the duel, not the aim; keep the numbers small.

### 12. Bide

**Rules.** While a friendly unit stands in front of this, it waits instead of attacking. Each time your side's attack order passes its slot while it waits, it gains +2 Attack this combat. When nothing is left in front of it, it attacks normally. If it is the only unit on your side that could attack, it stops waiting.

**Bends.** 9.4.5: a unit that is able to attack declines to, and its waiting costs its side no attack (the pointer moves past it). 9.4.2: the back row's reserve role becomes a wind-up.

**Creature.** Herons, which stand perfectly still, then stab (Folio: "Stands still, then stabs"; "first-strike lancer"). This is the owner's example, "Something that skips its attack, and every time it skips its attack in combat, it gains additional stats", tied to the rows.

**Archetype.** TALL, a back carry fed by time rather than deaths.

**Example.** *Grey Heron*, Tier 3, 1/5, Bird. "Bide. When this stops waiting, it attacks immediately."

**Fun to play against.** A race with a visible counter. The faster you break the units in front of the heron, the smaller it is when it strikes. Killing its screen slowly feeds it, and killing it quickly frees it.

### 13. Shelter *(close variant of Taunt; keywords.md's "Guard" idea)*

**Rules.** The back-row units behind this can't be attacked while this lives, even after the rest of your front row has fallen, and even by attacks that reach into the back row.

**Bends.** 9.5.1: back-row protection works by column as well as by row. 11.5.3: Shelter is a counter to back-row reach (Swoop, Rival), which keeps that reach from becoming a must-have.

**Creature.** Bison, the "immovable tank". A herd turns to face a threat with the calves behind. Great beasts.

**Archetype.** STICKY, and the protected engine for a back carry.

**Example.** *Białowieża Bison*, Tier 4, 3/9, Great beast. "Shelter. When an effect would damage a unit behind this, this takes the damage instead."

**Fun to play against.** One huge beast stands over two calves at the end of the fight, and you have to chew through it. Random-target effects still reach (9.5.6), so a few pings decide it.

### 14. Both Ends

**Rules.** While a friendly unit with Both Ends stands at the other end of this row (F1 and F4, or B1 and B3), each has +1/+2, and whenever one of them is attacked, the other deals 2 damage to the attacker.

**Bends.** 8.2.2: adjacency never skips a gap. This is a relation that deliberately spans a whole row, gaps and all. It also gives the flank slots (F1 and F4, one supporter each, 8.2.1) a job the centre slots can't do. 8.2.5: ends are per row, which is what keeps it readable.

**Creature.** Hedgehogs. In Grimm's *The Hare and the Hedgehog*, the hedgehog's wife waits at the far end of the furrow, so the hare always finds "a hedgehog" there first (Folio take "Twin tricksters: one waits at each end"). The owner's thorn idea ("deals damage back to the attacker... Maybe the hedgehogs") strikes from the far end.

**Archetype.** MEDIUM and STICKY.

**Example.** *Hedgehog Twin*, Tier 2, 2/3, Hedgerow folk. "Both Ends."

**Fun to play against.** You hit the hedgehog on the left, and the one on the far right pricks you. Kill one twin and the other loses its bonus, so the fight changes partway through.

---

## Gaps, summon space and the player's placement

### 15. Solitary

**Rules.** While no friendly unit is a neighbour of this one (8.2.3: adjacent, in front or behind), it has double Attack. This is checked all the time, so the unit can wake mid-combat when its neighbours die.

**Bends.** 8.2.3 and 8.3.1: almost all position text rewards clustering; Solitary rewards gaps. An empty slot becomes a power source, not just a missing body.

**Creature.** Wildcats, solitary and untameable (Folio: Clan Chattan's "touch not the cat"). Lynxes would fit too.

**Archetype.** TALL. One carry in a clearing, with the rest of the board kept away.

**Example.** *Scottish Wildcat*, Tier 4, 4/6, Hunter. "Solitary. Start of Combat: if this is alone, gain +3 Health."

**Fun to play against.** Kill order becomes drama. Clear the units around it and it wakes up doubled. The empty slots around it are a tell you can read before the fight.

### 16. Migrate

**Rules.** End of Turn: this moves to the next empty slot after its own in reading order (wrapping from B3 to F1) and gains +1/+1 permanently. If there is no empty slot, it stays and gains nothing.

**Bends.** 8.3.3: the player places units freely. A Migrate unit places itself, so the player steers it only by deciding which slots to fill. It reads position at End of Turn, which fits archetypes §3 rule 2.

**Creature.** Lemmings and their "cheerful, endless tide" (Folio take "The Great Migration"). Their doom cult, "believers in the cliff", gives the variant below.

**Archetype.** MEDIUM scaling with a cost: it needs empty slots, which pulls against filling the board late.

**Example.** *Cliff-cult Lemming*, Tier 2, 1/1, Lemming. "Migrate. If this would migrate past B3, it leaps instead: remove it and give your other units +1/+1 permanently."

**Fun to play against.** Their board shape shifts every turn, and you can see the lemming parade marching towards B3 and know when their buff turn is coming.

### 17. Stance

**Rules.** This unit has two stat lines, or two texts: one for the front row and one for the back row. It uses the one for the row it is in, and switches at once if it changes row.

**Bends.** 8.2.7 and 7.2.1: a row stops being only a place and becomes a mode switch. 12.2.1's "recalculated whenever the board changes" now covers a unit's own stats. keywords.md §C suggests "Choose One by placement"; Stance is that as a lasting state, so moves in combat (Rotate, Bolt, Flush) flip it mid-fight.

**Creature.** Bats. Aesop's bat belongs to neither the birds nor the beasts and changes sides to suit itself (Folio take "Double agents").

**Archetype.** Any. It is a flexible building block that lets one card serve two roles. Most natural in MEDIUM.

**Example.** *Double-agent Bat*, Tier 3, Bat. "Front: 5/2. Back: 2/5, and the units in front of this have +1 Attack."

**Fun to play against.** Flush their bat into the front row and their sturdy aura-bat becomes a 5/2 glass cannon. Moving effects on both sides make stance units a target for tricks.

### 18. Delivery

**Rules.** While this lives, your summons from any source go into the empty slot nearest this unit, instead of the dead unit's slot or the slot nearest their source. Delivered units gain +1/+1.

**Bends.** 8.4.1–8.4.3, summon placement. Because a summon's attack timing depends on where it lands (9.4.8), steering summons also steers when they attack.

**Creature.** Storks, the bringers of babies; in the Folio's folklore they bring luck to the roof they nest on. Hedgerow folk could share it.

**Archetype.** WIDE. It sends tokens into protected back slots, ripe Fallow slots or a Sett, and out of the enemy's Marks and Eggs.

**Example.** *Rooftop Stork*, Tier 4, 2/5, Bird. "Delivery."

**Fun to play against.** It is the other half of a cat-and-mouse game with Mark and Brood: their babies never appear where the parent died. Kill the stork and placement snaps back to normal, right into your marked slots.

---

## Combinations worth testing

- **Sett + Caravan + Delivery:** steering bodies into a slot that has been lived in for many turns.
- **Fallow + Delivery + any summoner:** a thin board that blooms in combat.
- **Rotate, Bolt and Flush with Stance:** units flipping roles as they change rows.
- **Mark and Brood against Delivery and Caravan:** hostile slot effects against steering.
- **Bide or Solitary behind Thicket or Shelter:** back carries with new kinds of cover.

## Overlaps with the archetype longlist

- Sett and Fallow are slot enchantments, like the Fairies' **Fairy ring** (archetypes §4.1). A ring grows from spells; a Sett grows from being lived in, and Fallow from being left empty.
- Thicket covers the same ground as Lights' **Lure** decoys, but as terrain rather than units.
- Rotate, Bolt, Caravan and Flush move units in combat, like the Diggers' proposed **Tunnel** (archetypes §4.1, question 12). If only one tribe should move units, these compete with it.
- Flush and Rival are back-row access, next to **Swoop** and **Trample** (archetypes question 9).

## Questions for the owner

1. **Board objects that aren't units.** Thickets and Eggs are things in slots that aren't units. Is that a new kind of object Bramble wants?
2. **Effects on the enemy board.** Brood puts an object in an enemy slot, and Flush moves enemy units. Are both acceptable, or should effects stay on their own side?
3. **Packing as a keyword.** Caravan brings back the sliding that fixed slots removed (8.3.4), for one tribe. Does that undercut the point of fixed slots, or is it a good rule-breaker?
4. **Units that place themselves.** Migrate overrides the player's free placement (8.3.3). Is giving up control over a unit's slot fun or a chore?
5. **More than 7 bodies.** Stowaway raises the body count past 7 (8.1.1). Is that a line Bramble wants kept?
