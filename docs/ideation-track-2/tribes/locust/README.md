# Locusts (The Locust Tide)

Ideation track 2. Nothing here is decided. The 19 units are in [units.json](units.json); what was tried and changed is in [LOG.md](LOG.md).

The owner (16 Nov): "they kind of like swarm and, you know, leave devastation in their wake and breed more locusts. So I thought of them more of like a summoning tribe, more similar Battlegrounds Undead".

**The tribe in one line:** Locusts lose the first half of every fight on purpose. Their bodies are small and die to anything, and each death pays: it breeds Hoppers, raises the swarm's Attack for the rest of the game, hurts the enemy, or brings the unit back a little bigger.

**Against Battlegrounds Undead.** Alike: Attack that lives on the player and not the unit (the Tide is "your Undead have +1 Attack this game"), a come-back keyword (Molt is Reborn), death effects with ways to trigger them again (War-drummer is Monstrous Macaw, Dirge-singer is Titus Rivendare), and small bodies. Different: Hoppers that don't fit on the board wait and land later, so the swarm is bigger than seven slots; Molt makes the unit +2/+2 bigger permanently each time; a whole plan wins with damage from deaths, which Undead doesn't have; and units are eaten when you sell them, in place of Undead killing its own units in the shop.

**Against the mice.** Mice win the first exchange by hitting together, and are never paid for dying: no mouse has a death effect or comes back. Locusts never hit together, and almost every one of them is paid for dying. They win the second half of the fight, with what their dead leave behind. The Rising Tide plan is the closest the two tribes come (small bodies with a lot of Attack); see "Not sure of" in the log.

## Three things the engine and the other tribes build on

- **Hopper.** The tribe's token: a 2/2 Locust (a hopper is a young locust that can't fly yet). It sells for 0 and never combines into a golden.
- **Waiting.** In a fight, a Hopper summoned when there is no empty slot isn't lost. It waits, and lands in the next slot that empties, front row first. On screen: a count of Hoppers in the sky above the board.
- **The Tide.** One number for each player, kept all game. Every Locust that player has, on the board, in hand, summoned or returned, has that much extra Attack. It only goes up, and it never gives Health. On screen: one number beside the board, like the Briars' heap.

## Keywords

| Keyword | Reminder text |
|---|---|
| **Tide +N** | Your Locusts have +N Attack for the rest of the game. |
| **Molt** | The first time this dies each fight, it returns as a plain copy with 1 Health, then gains +2/+2 permanently. |
| **Eat** | This gains the sold unit's stats. The sold unit's death effect triggers. |
| **Guard** | Enemies must attack this first. |

Guard is the same keyword the badgers, Briars and pigeons use. "Returns" is the Briars' word for coming back, so one card can care about Molt and Root alike. The +2/+2 from Molt goes on the returned copy and on the unit you keep.

## The 19 units

| Tier | Unit | A/H | Text | Reach |
|---|---|---|---|---|
| 1 | Green Recruit | 2/2 | When this dies, summon 2 Hoppers. | open |
| 1 | Husk Sentry | 3/3 | **Guard. Molt.** | splash |
| 2 | Prophet of the Dust | 2/7 | At the end of your turn, **Tide** +1. | tribe-only |
| 2 | Horde-runner | 3/5 | At the start of your turn, get a Hopper. | open |
| 2 | Wheat Raider | 4/2 | **Molt.** When this dies, deal 4 damage to a random enemy. | open |
| 3 | Brood Mother | 3/6 | When this dies, summon a Hopper and give your Hoppers +1/+1 for the rest of the game. | tribe-only |
| 3 | Skin-shedder | 3/8 | Start of fight: give **Molt** to the units next to this. | splash |
| 3 | Gleaner | 2/8 | After a friendly unit dies, deal 5 damage to the highest-Health enemy. | splash |
| 3 | Gorger | 4/6 | The first time you sell a unit each turn, this **eats** it. | splash |
| 4 | Famine-caller | 6/4 | When this dies, **Tide** +2. | tribe-only |
| 4 | Sky-darkener | 4/8 | Start of fight: summon 3 Hoppers. | tribe-only |
| 4 | Orchard Stripper | 5/5 | **Molt.** When this dies, deal 5 damage to all enemies. | splash |
| 4 | Granary Glutton | 5/7 | Whenever you sell a Locust, this **eats** it. | tribe-only |
| 5 | War-drummer | 5/10 | Whenever this attacks, trigger the death effect of a unit behind it. | splash |
| 5 | Twice-shed Veteran | 6/8 | After another friendly unit returns, it and this gain +6/+6 this fight. | splash |
| 5 | The Eighth Plague | 4/12 | After a friendly unit dies, deal damage to a random enemy equal to the number of friendly units that died this fight. | open |
| 6 | Dirge-singer | 3/14 | Your death effects trigger twice. | splash |
| 6 | Swarm-lord | 6/10 | After 2 friendly Locusts die, **Tide** +1. | tribe-only |
| 6 | Mother of Thousands | 5/12 | Whenever you summon Hoppers, summon twice as many. | tribe-only |

Seven only pay at home (tribe-only), four work on any board (open), and eight are pieces another tribe's plan would buy on purpose (splash; who and why is in the last section). A unit that already has Molt and is given it again by a Skin-shedder Molts twice that fight.

## The five plans

Boards are for turn 9, written front row F1–F4, then back row B1–B3. The player went up a tier on turns 2, 4, 6 and 8, which takes nearly all of those turns' gold, so Tier 2 units arrive on turn 3, Tier 3 on turn 5, Tier 4 on turn 7 and Tier 5 on turn 9. Numbers are rough, set against other tribes' turn-9 boards of 300 to 400 total stats.

### 1. Rising Tide: the whole swarm hits harder every turn

- **The plan:** raise the Tide every turn and in every fight, so that every Locust, the Hoppers too, swings far above its size.
- **Key units:** Prophet of the Dust (T2, Tide +1 at the end of each turn), Famine-caller (T4, Tide +2 when it dies), War-drummer (T5, drums the Famine-caller behind it), Swarm-lord (T6, Tide +1 for every two Locusts that die).
- **Why choose it:** it starts on turn 3, and nothing is lost when a unit is sold or dies: the Attack is on the player. It is the Locust plan that likes any Locust you find.
- **Turn-9 board (Tide about +22):** F: Husk Sentry, War-drummer, Famine-caller, Wheat Raider. B: Famine-caller, Prophet of the Dust, Prophet of the Dust.
  - The two Prophets have given +14 since turn 3. Two Famine-callers have died in the front row in two fights: +8.
  - This fight the Tide rises by 2 each time the War-drummer attacks and by 2 when the front Famine-caller dies. The Sentry, bought on turn 1, has Molted every fight and is 41/19 with Guard. About ten attacks of 25 to 40, behind about 70 Health in total.
- **What beats it:** anything that kills without trading. Thorns, Cleave, damage to the whole board (the Locusts' own Orchard Stripper). A Guard with a lot of Health. Attacking second.

### 2. Brood: bigger Hoppers, and more of them than the board holds

- **The plan:** make Brood Mothers die as often as possible, so every Hopper is bigger for the rest of the game, then flood the board with them.
- **Key units:** Green Recruit (T1), Brood Mother (T3, Hoppers +1/+1 for the rest of the game), Sky-darkener (T4, 3 Hoppers at the start of the fight), War-drummer (T5), Mother of Thousands (T6, twice as many Hoppers).
- **Why choose it:** its bodies get Health as well as Attack, so small damage doesn't wipe it. The waiting Hoppers keep the front row full, which keeps the back row safe.
- **Turn-9 board (Hoppers about 12/12):** F: Green Recruit, Brood Mother, War-drummer, Brood Mother. B: Sky-darkener, Brood Mother, Sky-darkener.
  - Two Mothers have died in the front row every fight since turn 5, a third since turn 7.
  - The drum is in F3 with a Brood Mother behind it. The Recruit leaves 2 Hoppers, each Mother's death 1, each drumbeat 1, the Sky-darkeners 6: about 12 Hoppers in the fight, six of them waiting at the start, and they grow by another +5/+5 while it runs.
- **What beats it:** it is slow. Hoppers are 2/2 until turn 5. Cleave and Thorns cut through Hoppers in threes. One huge unit out-trades them one at a time.
- **Late:** at Tier 6 this and the Tide grow into one board, with every Hopper carrying both bonuses. That is the tribe's end game, as attack tokens are for Undead.

### 3. Molt: kill it twice, and it comes back bigger next turn

- **The plan:** fill the front row with units that return. Every return is +2/+2 permanently, and the Veteran makes every return count in the fight too.
- **Key units:** Husk Sentry (T1), Wheat Raider (T2), Skin-shedder (T3, gives Molt to the units next to it; one that has it already Molts twice), Orchard Stripper (T4), Twice-shed Veteran (T5, each return gives +6/+6 to the returner and to itself).
- **Why choose it:** it grows from turn 1 whether fights are won or lost, the enemy has to kill the front row two or three times, and death effects fire again with no other help. Its bodies end up with real Health. It also takes any other tribe's unit that returns or has a death effect.
- **Turn-9 board:** F: Husk Sentry, Skin-shedder, Wheat Raider, Orchard Stripper. B: Twice-shed Veteran, Gleaner, Wheat Raider.
  - The Sentry and the Raider beside the Skin-shedder return twice each. The Sentry is about 27/27 with Guard by now and the Raider 24/22.
  - Five returns before the back row is reached. A return is a plain copy, so it stands up small, but with the Veteran it is an 11/9 and not a 1-Health husk. The Veteran is about 36/38 by then. The front row dies nine times in all, so the Gleaner puts 45 on their biggest unit, and the Stripper hits the whole enemy board twice.
- **What beats it:** growth is +2/+2 a unit a turn, so a plan that multiplies outruns it late. Second lives are small. Damage to the whole board kills returners as they stand up.

### 4. Devastation: every death hurts them

- **The plan:** don't win trades. Fill the board with cheap bodies and turn each death into damage, wherever the enemy is standing.
- **Key units:** Wheat Raider (T2), Gleaner (T3, 5 damage to their biggest unit for every friendly death), Orchard Stripper (T4, 5 to all enemies), The Eighth Plague (T5, damage that grows with every death), Mother of Thousands (T6, twice the Hoppers is twice the deaths).
- **Why choose it:** the damage ignores rows, Guard and Thorns. The Gleaner is the Locust answer to a carry hidden in the back row; the Stripper and the Plague are the answer to wide boards of small units.
- **Turn-9 board:** F: Green Recruit, Wheat Raider, Orchard Stripper, Green Recruit. B: Gleaner, The Eighth Plague, Sky-darkener.
  - Thirteen friendly deaths before the back row is reached. The Gleaner puts 65 on their biggest unit. The Plague deals 1, then 2, up to 13: 91 in all, spread at random. The Stripper deals 10 to every enemy and the Raider 8 more. About 230 damage that no Guard or back row stops.
- **What beats it:** Health. A few huge units (a badger board) shrug it off. Its own bodies win no trades, so whatever the damage leaves standing wins the fight. It is the weakest Locust plan in a plain stat fight and the best against boards that go wide or hide a carry.

### 5. Feast: feed the swarm to one mouth

- **The plan:** every Locust you sell is eaten: its stats go onto the eater and its death effect goes off in the shop. Build one or two huge Locusts behind a cheap front.
- **Key units:** Horde-runner (T2, a free Hopper every turn), Gorger (T3, eats the first unit sold each turn, any tribe), Granary Glutton (T4, eats every Locust sold). The best food is a Locust with a death effect: Green Recruit, Brood Mother, Famine-caller. At Tier 6, Mother of Thousands and Dirge-singer double what an eaten Recruit leaves.
- **Why choose it:** real, permanent Attack and Health, built in the shop whether fights are won or lost. It needs nothing above Tier 4, so the gold other plans spend on Tier 5 goes into the Glutton. It is the only tall Locust board, and it wastes nothing: the unit you replace is a meal.
- **Turn-9 board (the player stayed on Tier 4):** F: Husk Sentry, Husk Sentry, Orchard Stripper, Wheat Raider. B: Gorger, Granary Glutton, Horde-runner.
  - F4 is the feeding slot: Locusts are bought, played there and sold one after another, and the last one bought stays for the fight.
  - The Glutton has eaten for three turns: about 19 cheap Locusts and Hoppers at about 2½ gold a meal with the refreshes, +4/+4 each. It is about 80/80. The Gorger has had a meal a turn since turn 5 and is about 22/24.
  - The two Sentries have Molted all game and are about 19/19 with Guard. The front must be killed twice before anything reaches the eaters.
- **What beats it:** it takes the turn's gold and stays a tier behind, so the rest of the board is what was bought early. A wide board swarms two units. Whatever removes or shuts off one unit removes half the board.

**How the plans share units.** Seventeen of the 19 serve two plans or more. The Recruit, the Sentry and the Raider are the cheap front of almost every board. The War-drummer and the Dirge-singer multiply whichever death effect the plan is built on. Eating a Famine-caller or a Brood Mother in the shop pays the Tide or the Brood without a fight. The Tide helps every board whose bodies are Locusts, and Molt gives those bodies the little Health they have.

## Tier check

Printed bodies are small on purpose (about two-thirds of the tier's usual body): the text and the second lives pay for the tier.

- **Tier 1:** fits. Green Recruit is three bodies for one card (generous, like Battlegrounds' Harmless Bonehead). Husk Sentry is two hits of Guard and grows 4 stats a turn, the tier's target.
- **Tier 2:** fits. Prophet's Tide +1 a turn is about 0.6 of a body on seven Locusts. Horde-runner is at the low end (one 2/2 a turn) until Hoppers grow. Wheat Raider is about one body in a fight.
- **Tier 3:** hot. Gleaner gives about 3 bodies in a fight (8 deaths, 40 damage), and more on a board built for it, against a target of 0.7 to 1.4. That is on purpose: it is what the damage plan stands on. Brood Mother is a little over (+1/+1 on about 8 Hoppers a fight). Skin-shedder is 8 permanent stats a turn plus two more lives. Gorger is on target at one meal a turn.
- **Tier 4:** fits. Famine-caller is about 1.3 bodies a turn. Sky-darkener is under alone (12 plain stats) and on target once Hoppers carry the Tide or the Brood bonus. Orchard Stripper is about twice the target against a full board. Granary Glutton is about 3 bodies a turn when the whole turn's gold feeds it, which is about what that gold would buy in plain units; what it adds is one body and no slot limit.
- **Tier 5:** fits the guide's shape: a multiplier (War-drummer), a direction card (Twice-shed Veteran, about 1.5 times the in-fight target, none of it kept) and a combat engine (The Eighth Plague: on target at 13 deaths with 91 damage, well over at 20 with 210).
- **Tier 6:** fits the job: three multipliers. Swarm-lord is Tide +7 a fight on a full swarm. Mother of Thousands doubles the Hoppers, Dirge-singer the death effects.
- **The first things to check in the build:** the Tide has no ceiling (a drummed Famine-caller is +2 an attack, +4 with a Dirge-singer); Mother of Thousands with The Eighth Plague (40 deaths is 820 damage) and with Swarm-lord (Tide +20 a fight); and a Dirge-singer doubling death effects that are eaten in the shop.
- **Breaks the starting shape:** no gold economy unit (Undead has none either); the economy is free bodies (Horde-runner) and eating. Tier 5 has no tempo body.

## Rules it needs

1. **Hopper token:** a 2/2 Locust, Created, that never combines into a golden.
2. **Waiting:** in a fight, a Hopper summoned with no empty slot waits. After each round of deaths, once death effects and returns are done, waiting Hoppers land in empty slots in reading order. It counts as summoned when it lands. Not in the shop.
3. **Who lands first in an emptied slot:** the dead unit's own summon or return, then a pigeon stepping in from Reserve, then a waiting Hopper. The end-of-fight check comes after Hoppers land.
4. **The Tide:** a number on the player, kept for the game; all that player's Locusts have that much extra Attack. A rise in a fight is permanent. Effects that take or copy a unit's stats don't take the Tide.
5. **"Give your Hoppers +N/+N for the rest of the game":** a second number on the player, for Hoppers only, with the same rules as the Tide.
6. **Molt:** a return (rulebook 9.8.2: a plain copy) with 1 Health; the returned copy and the unit on the recruit board both gain +2/+2 permanently. It is counted in charges: printed Molt is one each fight, and Skin-shedder adds one for this fight to any unit.
7. **"After a friendly unit returns"** as a trigger (9.7.2 step 5), shared with the Briars.
8. **Eat:** when a unit is sold, one eater gains that unit's own stats permanently (printed stats and buffs on the unit; not the Tide, the Hopper bonus, slot buffs or auras), and its "when this dies" effects resolve in the Recruit Phase. The sale itself is unchanged (gold, pool, Compost). Each sold unit is eaten once: the Gorger takes the first unit sold each turn, and a Glutton takes any other Locust sold.
9. **Death effects in the Recruit Phase:** summons land on the recruit board; an effect that needs a fight (damage to an enemy, a unit summoned "for this fight") does nothing.
10. **Triggering a death effect without the death** (War-drummer): the effect resolves from where the unit stands; a summon that would take its slot goes to the nearest empty one.
11. **"Your death effects trigger twice"** (Dirge-singer); two don't add up.
12. **Doubling the number of Hoppers summoned** (Mother of Thousands).
13. **A count of friendly deaths this fight** on each side (The Eighth Plague), and "the highest-Health enemy" as a target (Gleaner).
14. **Check the attack limit (9.10.1):** a Mother of Thousands board can summon 40 or more Hoppers, and a tie at 200 attacks would rob it.

## What Locusts give to and take from the other tribes

**Give (the eight splash pieces):**

- **Husk Sentry:** a 2-gold Guard that must be killed twice and grows every fight, for any board that hides something in the back row.
- **Skin-shedder:** stands next to any tribe's unit and gives it a second life and +2/+2 a turn: a Briar Crab-apple seeds twice, a badger Gate Warden stands up again.
- **Gleaner:** for boards that lose many bodies (mice, Briar Pips, pigeon Privates). Every death is 5 damage on the enemy's biggest unit, wherever it stands.
- **Gorger:** for any tribe. Once a turn, the unit you replace moves its stats onto the Gorger. For Briars the sold unit goes into the Compost as well.
- **Orchard Stripper:** a tech piece for any board that keeps meeting wide boards of small units: 5 to every enemy, twice a fight.
- **War-drummer and Dirge-singer:** for any death effect worth repeating (the Briars' Seed and Crab-apple).
- **Twice-shed Veteran:** for the Briars' Coppice plan: a unit that returns through Root gets +6/+6 too.

**Take:**

- **Slot buffs (pigeons, and the mice's Whetstone Vole and Grindstone Miller):** a Hopper is a plain 2/2, so it gains the most from a buffed slot, and waiting Hoppers keep landing in the same front slots all fight. The Padre (a dead unit's slot gets +1/+1 permanently) turns every Locust death into a better slot. A Guard post gives Guard to whatever Molts or lands there.
- **Returns (Briars):** Hazel Coppicer gives the whole board +1/+1 permanently on every return, and a Molt board has five or more a fight.
- **Outliving the swarm (badgers):** Old Brock gains the stats of every friendly unit that dies, and Sword-heir gains the Attack of units that die in front of it. Hoppers carrying the Tide are the best food either could have.
- **Extra attacks (badgers and mice):** a Herald of the Charge behind the War-drummer gives it a free drumbeat at the start of the fight, and the mice's Kettle-drummer makes it drum twice each time round.
- **The Compost (Briars):** Hoppers add nothing to a heap (they weren't bought), but a Gorger on a Briar board turns a sale into stats and a heap entry at once.
