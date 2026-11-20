# Shared rules for the five tribes

Ideation track 2. Nothing here is decided for the real game.

This is the one glossary for the build: every keyword and defined term on a card, the one reminder text for it, the rule an engineer codes, and the rulings where two tribes meet. Each tribe's `units.json` copies its spellings and reminder text from here. Where a tribe's file and this one differ, this one wins.

Written 17 Nov 2026 from the five designers' drafts of 16 Nov. Section 3 lists what was renamed or merged, and each tribe's `LOG.md` has a dated line for what changed in it. Rule numbers are the [rulebook](../../design/rulebook.md)'s.

## 1. Wording every card follows

**A fight** is the rulebook's combat. Cards say "fight".

**Trigger words.** The same words always mean the same moment.

| On the card | When it resolves |
|---|---|
| Start of fight: | Rulebook 9.3, in two passes (ruling 41) |
| Whenever this attacks | 9.6.1 step 2, before damage, on every attack it makes, out-of-turn ones included |
| Whenever this is attacked | 9.6.1 step 1, before the attacker's effects, for the attack's target only |
| Whenever a neighbour attacks | 9.6.1 step 2, after the attacker's own effects |
| After this kills | 9.7.2 step 1, for a unit this unit's own damage killed |
| When this dies | A death effect: 9.7.2 step 2 |
| After a friendly unit dies | 9.7.2 step 3. Never a death effect |
| After a friendly unit returns, After this returns | 9.7.2 step 5 |
| At the start of your turn | On the recruit board. Effects that use the last fight read its saved report. |
| At the start of your turn, At the end of your turn | 3.2.1, 3.4.1, while the unit is on the board |
| When played: | 7.2.3, after the unit is placed from hand |
| Order (N): and Bury: | Something the player does in the Recruit Phase, once a turn for each unit that has it |
| Instead of attacking | The unit's own turn in the attack order is replaced |

**Other wording rules.**

- After a trigger word and a colon, the effect starts with a capital: "Start of fight: Summon 3 Hoppers."
- **How long.** "This fight" ends with the fight. "Permanently" is on the unit or the slot and is kept (ruling 35). "For the rest of the game" is a number on the player (the Tide, the Hopper bonus). A gain made in the shop or after a fight with no words about time is permanent.
- **Where.** "In front of" and "behind" are the diagonal slots (8.2.1). "Next to" is the slot beside it in the same row (8.2.2). A "neighbour" is next to, in front of or behind: up to four (8.2.3). "Across from" is the enemy slot with the same label (8.2.6).
- **Limits** are written "(5 a fight)".
- **Tokens** are named in card text ("summon a Pip"); their stats are in the reminder.
- **Golden** doubles every number and leaves thresholds alone (7.3.5). Each unit's `golden` field says what that means for it.

## 2. Glossary

"Touched by" names the other tribes whose cards use the term or meet it on a mixed board.

### Shared by every tribe

| Term | Reminder text | Rule | Touched by |
|---|---|---|---|
| **Guard** | Enemies must attack this first. | Must be attacked (9.5.4; the engine's `taunt`). It limits attacks only: a Hit, a pile-on hit and damage from effects ignore it. A back-row Guard matters once the back row can be attacked, and against Sortie. | Badgers, Pigeons (Guard post), Locusts, Briars and the Mice’s Thimble Sentinel. |
| **Death effect** | (none) | "When this dies, …" and Seed. Resolves at 9.7.2 step 2 from the slot the unit died in. It can be set off without a death (War-drummer, Eat) and doubled (Dirge-singer). "After a friendly unit dies" effects and returns are not death effects. | Locusts own most. Briars: Seed, Crab-apple, Old Stump. Mice: Hand-me-down. No Badger or Pigeon has one. |
| **Returns** | (none) | The unit died and came back in the same fight (9.7.2 step 4): Molt and Root, nothing else. It goes to its own slot, or the nearest empty one (9.8.3). One return for each death; 5 a fight for one unit (9.10.3). | Locusts (Molt), Briars (Root). Twice-shed Veteran, Hazel Coppicer and Blackthorn Sapling trigger on it. |
| **Plain copy** | (none) | The card as printed: no buffs, counters or given keywords. It still takes its slot's buff, auras and the Tide like any unit. | Molt returns (a golden stays golden), copies from the Compost (never golden). |
| **Own stats and borrowed stats** | (none) | Own: printed stats and every buff on the unit itself, this fight's gains included. Borrowed: its slot's buff, lent stats, any other aura, the Tide, the Hopper bonus. An effect that copies, keeps or takes a unit's stats uses own stats only (ruling 43). An effect that only reads Attack or Health reads the total. | Eat, Hand-me-down, Sword-heir, Old Brock, Compost copies, returns, triples. |
| **Bought and Created** | (none) | Rulebook 4.3.1. Tokens, copies and Discover picks are Created and add nothing to a Compost. Since 19 Nov 2026 a Created real card (a copy, a Discover pick) sells like a Bought one; a token still sells for 0 (rulebook 4.3.2–4.3.5). The fight copy of a board carries the flag. | Hopper, Private, Cousin, Pip; Lone Hawthorn reads it on enemy units. |
| **Attacks twice** | (none) | Two attacks back to back on its turn (9.4.11). From several sources it is still twice. | None. |
| **Attacks immediately** | (none) | One extra attack at once, out of turn (9.4.12). Always a single attack. | Hedge Lancer, Tourney Champion, Herald of the Charge, The Oakfeller, Wing Commander, Needle Sister. |
| **Active** ("{1}:") | (none: a gold coin holding the cost, then a colon; no keyword word) | Rulebook 11.7.1–11.7.2. In the Recruit Phase, pay the coin's gold (0 is free) to use the effect, once a turn for each unit on the board. Golden doubles the effect, not the cost. Replaces Order (N). | Any tribe. First on Lance Corporal (1) and Grenadier Guard (0). |
| **Charge N** | Works this many times, then stops. Refills each fight. | Rulebook 11.7.3, 11.7.5. Written in front of the effect it limits; all uses come back at the start of every fight. Golden doubles the effect’s numbers and the Charge (7.3.5). | Any tribe. Pigeons first; Mice: Thimble Captain, Needle Sister, Grandmother Hob and Old Mother Needle. |
| **Supply N** | Works this many times in all, then never again. | Rulebook 11.7.4–11.7.5. Uses left are a count on the unit. A triple adds the copies' remaining Supply; a golden from Discover starts full. Golden leaves N alone. | Sentry only, for now. |

### Badgers own

| Term | Reminder text | Rule | Touched by |
|---|---|---|---|
| **Outnumbered** | Counted when the fight starts: enemy units beyond yours. Back-row Squires aren't counted. | One number for each side for the whole fight, set when the boards are counted (9.2.1) and before any Start of fight effect: enemy units on the board minus yours, never below 0, leaving out back-row Squires on both sides. Nothing changes it afterwards (rulings 1 to 5). | Any tribe's board can be the short one: Pigeons holding units in hand, Briars' Regrowth. |
| **Fury N** | Whenever this attacks or is attacked, gain +N Attack, and +N more for each unit you're outnumbered by. | A trigger at 9.6.1 step 1 (attacked) and step 2 (attacks), before damage: +N x (1 + the count) in Attack, this fight (balance pass 1, 19 Nov 2026, a proposal under test: it was +N x the count). Attacks only. Fury from every source adds into one N; the Marshal doubles it last. | Master-at-Arms and the Marshal give or double it on any tribe's unit. |
| **Grudge N** | At the start of your turn, gain +N Health, and +N/+N more for each unit you were outnumbered by last fight. Works even if this died. | Use the highest Grudge number once for each unit on the recruit board. |
| **Squire** | In the back row, this isn't counted for Outnumbered. | A keyword on the seven Badger Squires, and a word on their type line. Left out of the count on both sides while in the back row. | None. The Mice's Needle Squire was renamed. |
| **Knight** | (type line, no reminder) | A word on the type line of the twelve Badger Knights. "Your Knights" reads the type line, never the name. | None. Holly Knight (Briar) is not a Knight; Dame Bodkin's type line was changed. |
| **Lends** | The units in front have that much extra while this is on the board. | An aura (12.2.1) from a unit to the two slots in front of it: extra Attack, or extra maximum Health, equal to the lender's own total as it stands, its slot's buff included. When the lender leaves, lent Health goes but never takes a unit below 1. Two lenders add up. Lent stats are borrowed. | Mice and Pigeons put slot buffs on a lender's slot. |
| **Overrun** | Damage beyond what kills its target carries on to another enemy. | When an attack's damage exchange deals more than its target has Health left, the rest goes to another enemy picked as that unit's next attack would pick, and so on. Only the first target was attacked and strikes back. Not for a Hit or a pile-on hit. | Greatsword Bearer gives it to any tribe's unit. |

### Mice own

| Term | Reminder text | Rule | Touched by |
|---|---|---|---|
| **Pile on N** | The first N times a neighbour attacks each fight, this hits the target first. | Rulebook 11.7.11. At 9.6.1 step 2, after the attacker's own effects and "whenever a neighbour attacks" effects, every neighbour with Pile on Hits the target, all at the same moment. If the target is dead afterwards the attack ends: no damage either way, and the kill is not the attacker's. If the attacker died in step 1, nobody piles on. N counts the neighbour attacks the unit hears each fight, its first N; one heard with 0 Attack still uses one. A golden doubles N (7.3.5). Pile on from several sources adds up and piles on once. The count is a fight count, so a return keeps it (ruling 21). | Works beside any tribe's attacker, and on any attack: out of turn, a Sortie. |
| **Hand-me-down** | When this dies, the nearest friendly Mouse gains its Attack this fight. | Rulebook 11.7.12–11.7.13. A death effect (9.7.2 step 2), a keyword on the card. Only the unit's own Attack passes (ruling 43): this fight's buffs on it pass, its slot's buff, Renown and auras don't. **Nearest** is the friendly Mouse fewest neighbour steps (8.2.3) from the slot it died in, counting through empty slots; ties go in reading order. A Mouse dying at the same time can't inherit. With no Mouse left, or 0 Attack, nothing happens. | Locusts: the Dirge-singer resolves it twice, and a War-drummer sets it off without a death (it then passes to the nearest other Mouse). Any tribe's unit can carry it; only a Mouse inherits. |
| **Hit** | Deal this unit's Attack as damage. It takes none back. | Damage equal to the unit's total Attack. Not an attack: it triggers no "attacks" or "is attacked" effect, and Guard and rows don't limit it. "The enemy with the least Health" looks at both rows and current Health; ties are random. | A pile-on is a Hit. |
| **Cousin** | A 2/2 Mouse with Hand-me-down. | The Mouse token. Hayloft Aunt adds one to hand. In fights it is summoned into the empty slot nearest its source (8.4.2). With no empty slot it is lost. | Lands in Pigeon slot buffs; its death pays Locust and Badger "after a friendly unit dies" cards. |

### Pigeons own

| Term | Reminder text | Rule | Touched by |
|---|---|---|---|
| **Renown** | The unit that starts the fight here, and any reservist who steps in, has +1/+1 for each Renown. | Rulebook 11.7.6–11.7.7. A permanent number on a slot; it never moves with a unit. Summons, returns and units that move in during a fight don't get it. Gained in a fight, it goes on the real slot and counts from the next fight. Borrowed (ruling 43). | Any tribe's unit standing in the slot. Replaces Pigeon slot buffs. |
| **Slot buff** *Retired 19 Nov 2026.* | Stays on the slot. Any unit standing there has it. | A stat layer on each of a player's 7 slots (8.5), added to whatever unit stands there. Given in the shop it is permanent; given in a fight it lasts the fight unless the card says permanently. Borrowed, never the unit's own (rulings 9 to 14). Pigeons give Renown. | Every tribe's units stand in them. |
| **Guard post** | The unit here has Guard. You have one Guard post. | A slot effect: the unit in that slot has Guard, whatever it is and however it got there. One for each player; setting a new one clears the old. Renown given to the post stays on that slot if the post moves. | Any unit that lands there: Hoppers, Cousins, returning units. |
| **Reserve** | In a fight, this steps from your hand into a slot a friendly unit died in. Your Guard post first. Up to 2 a fight. | A unit with Reserve in hand at the start of a fight stands by off the board, with its own permanent buffs. After each round of deaths it steps into an empty slot a friendly unit died in this fight (ruling 6), filling the Guard post, then the most Renown, then reading order (rulebook 11.7.8–11.7.9); at most 2 from hand a fight. Once a fight for each unit. Not a summon, not a return. The hand is unchanged after the fight. | Quartermaster grants it permanently and raises the reserve limit by one. The Colonel multiplies Renown for hand reservists. |
| **Sortie** | Attacks the enemy back row while it has units. | The attacker's candidates are the enemy back row if it has units (overrides 9.5.1). A front-row Guard is ignored; a back-row Guard applies. | Squadron Leader gives it to any tribe's unit. |
| **Cleave** | Also damages a random unit next to its target. | The attack's damage also lands on one unit next to the target in the target's row, picked at random (11.2.7; one, not both: owner, 19 Nov 2026). That unit was not attacked. | None. Badgers dropped it for Overrun. |
| **Private** | A 2/2 Pigeon reservist. | A Created token that steps in after waiting summons, outside the hand limit. | Counts as a friendly death for other tribes' cards. |

### Locusts own

| Term | Reminder text | Rule | Touched by |
|---|---|---|---|
| **Tide +N** | Your Locusts have +N Attack for the rest of the game. | One number on the player, starting at 0, never falling. Every Locust that player owns has that much extra Attack. "Tide +N" adds N, at once, in a fight or out of it. Borrowed. | None: only Locusts have it. |
| **Hopper bonus** | (in card text: "give your Hoppers +1/+1 for the rest of the game") | A second number on the player, for Hoppers only, with the Tide's rules. | None. |
| **Hopper** | A 2/2 Locust. In a fight, a Hopper with no room waits for a slot. | The Locust token. Created; never combines into a golden. | Lands in Pigeon slot buffs. |
| **Waiting** | (in the Hopper reminder; for other cards: "With no room, they wait for a slot.") | A summon that waits is held in one line for each side and lands after a round of deaths (ruling 6), first to wait first, in the first empty slot in reading order. It counts as summoned when it lands. Fights only. | Briars: Elder Mother's copies wait in the same line. |
| **Molt** | The first time this dies each fight, it returns as a plain copy with 1 Health, then gains +2/+2 permanently. | A return. Counted in charges: printed Molt is one a fight; Skin-shedder adds one for this fight. The +2/+2 goes on the returned copy and on the recruit-board unit. | Skin-shedder gives it to any tribe's unit. |
| **Eat** | This gains the sold unit's stats. The sold unit's death effect triggers. | When a unit is sold, one eater gains its own Attack and Health permanently, then its death effects resolve in the Recruit Phase. Stats only: no keywords, Fury or counters. The sale is unchanged (gold and Compost). Not a death. | Gorger eats any tribe's unit. |

### Briars own

| Term | Reminder text | Rule | Touched by |
|---|---|---|---|
| **Compost** | Your heap. Units you bought go here when you sell them. | One list of unit entries on each player, shown as a number. Bought units go in when sold. Fights use the real one: what a fight adds or spends stays. "The heap" is the same thing in plain talk; cards say Compost. | Every player has one. Locust cards that repeat death effects feed it through Seed. |
| **Bury** | Once a turn, put a shop unit in your Compost, then do what follows. | Each Bury unit on the board gives one Bury a turn: a shop unit (not a spell) leaves the shop, its entry is added, then the effect resolves. | None. |
| **Seed** | When this dies, add a copy of it to your Compost. | A death effect: add an entry for this unit's card. | War-drummer, Dirge-singer, Skin-shedder and Gorger repeat it. |
| **Root N** | The first time this dies each fight, spend N Compost to return it. | A return. Removes the N lowest-tier entries. The unit comes back as it stands on the recruit board: full Health, permanent stats, nothing from this fight. Not a choice. If N can't be paid or no slot is free, it stays dead and nothing is spent. | Twice-shed Veteran pays on it. |
| **Grow N** | Start of fight: Gain +N/+N for every 2 units in your Compost. | Start of fight, main pass: +N/+N for every 2 entries, rounded down, on the unit, this fight. Grow from several sources adds up. Units that arrive later don't Grow. | Ivy Climber gives it to any tribe's unit. |
| **Thorns N** | Whenever this is attacked, deal N damage to the attacker first. | At 9.6.1 step 1, N damage to the unit making the attack. Damage, not an attack. If the attacker dies the attack ends there. Thorns from several sources add up. | Meets every tribe's attackers (rulings 23 to 26). |
| **Pip** | A 3/3 Briar with Seed. | The Briar token. Summoned into the dying Crab-apple's slot. With no empty slot it is lost. | None. |
| **Copy from the Compost** | A plain copy for this fight. Each unit in your Compost comes out once a fight. | A plain, non-golden copy of the highest-tier entry not yet copied this fight. The entry stays. The copy is Created, lasts the fight, and is whatever tribe its card is. | Any tribe's unit can be the one copied. |

### Tokens

| Token | Stats and text | Tribe | With no empty slot | Made by |
|---|---|---|---|---|
| **Private** | 2/2 | Pigeon | Steps into the slot of a friendly death | Recruiting Sergeant, Bugler |
| **Cousin** | 2/2, Hand-me-down | Mouse | Lost | Hayloft Aunt, Thimble Captain, King Speck |
| **Hopper** | 2/2 | Locust | Waits (fights only) | Green Recruit, Horde-runner (to hand), Brood Mother, Sky-darkener |
| **Pip** | 3/3, Seed | Briar | Lost | Crab-apple |

All four are Created, take their slot's buff, and count as their tribe. One summoned in a fight lasts that fight. A Hopper got in the shop (Horde-runner, an eaten Green Recruit) stays like any unit.

## 3. Renames and merges

| Was | Now | Why |
|---|---|---|
| Cleave as a Badger keyword | **Overrun** is the Badgers'. **Cleave** is a Pigeon keyword only (Flying Ace). | The Badgers dropped Cleave. The two are different effects and both stay. |
| "Whenever a friendly unit dies", "When a unit in front of this dies" (Sett Sexton, Old Brock, Sword-heir) | **After** … dies | The Pigeons and Locusts write this trigger "After a friendly unit dies", and the Badger notes already resolved it at the same step. |
| "When this is attacked" (Thorns), "When a neighbour attacks" (Pile on) | **Whenever** this is attacked, **Whenever** a neighbour attacks | Matches Fury, Gate Warden and Thimble Captain. |
| "Tide: Your Locusts have this much extra Attack…" on cards | **Tide +N: Your Locusts have +N Attack for the rest of the game.** | The Locust files had two reminders for one keyword. |
| "Brood bonus" | **Hopper bonus** | Two names for one number. |
| "heap" in reminder text | **Compost** | Cards say Compost. "Heap" stays in plain talk and in the Compost reminder. |
| "summon a 2/2 Private", "summon a 3/3 Pip with Seed" | "summon a **Private**", "summon a **Pip**", stats in the reminder | The Mice and Locusts already name their token and put its stats in the reminder. |
| "the Volley" (the Lieutenant's effect) | No name | No card or other tribe uses the word. |
| Needle Squire (Mouse) | Needle Pikeman | Already done by the Mouse designer; the Badger README still had the old name. |
| Dame Bodkin's type line, "Dormouse Knight" | **Dormouse Duellist** | Knight is a Badger type word that Badger cards read. |
| A "waiting" Reserve unit | A unit **in Reserve** | "Waiting" now means only a summon with no slot. |
| "beside" | **next to** | One word for the same-row slot. |
| Plate (Badger armour) | Gone | The Badgers dropped it; the Briar README still named it. |
| Lowercase "start of fight: summon…", "When played: give…" | Capital after the colon | One template. |

Not renamed, for the owner: card names that share a word across tribes are listed in [CROSS-TRIBE.md](CROSS-TRIBE.md).

## 4. Rulings between tribes

Each is the simplest reading that keeps every tribe's plans working. "Weakens" names a card or plan that loses something.

### Outnumbered

1. The count is taken once, when the boards are counted for first attack (9.2.1), before any Start of fight effect.
2. Nothing changes it afterwards: not Privates, Hoppers, Cousins, copies from the Compost, returns, units stepping in from Reserve, or deaths.
3. Units in hand are never counted, with or without Reserve, on either side.
4. So a board that starts short and fills up is outnumbered for the whole fight (a Knight with Elder Mother, Sky-darkener or The Colonel), and an enemy that starts short and fills up is not counted at its full size. *Weakens:* Fury against Regrowth, Reserve and other boards that start with gaps.
5. Who attacks first (9.2.1) and loss damage (10.1) count every unit on the board, Squires included. They don't use this number.

### Who fills an emptied slot

6. After each round of deaths, in this order:
   1. the dead unit's own death-effect summons, the first into its slot (8.4.1): Hoppers, a Pip, Old Stump's copy;
   2. its return, Root before Molt, to its own slot or the nearest empty one;
   3. Reserve: one unit into each empty slot a friendly unit died in this fight, the Guard post first, then most Renown, then reading order, leftmost in hand first;
   4. waiting summons (Hoppers and Elder Mother's copies, one line), each into the first empty slot in reading order;
   5. Recruiting Sergeant and Bugler spend Charge to call a Private where an eligible friend died if the slot is still empty;
   6. then the end-of-fight check (9.9.1).
7. Cousins and Pips never wait. A Cousin is placed during an attack (9.6.1 step 2), in the empty slot nearest its source.
8. Every arrival takes its place in the attack order by 9.4.8.

*Weakens:* a Recruiting Sergeant on a Locust board (Hoppers take the slot before a Private can), and a Thimble Captain on a Reserve board (Reserve units reach the post before a Cousin can).

### Slot buffs

9. Any unit in the slot has the buff: tokens, copies, returning units, Reserve units, any tribe.
10. A slot buff is borrowed. It is never copied, kept or taken with the unit (ruling 43).
11. Effects that only read a unit's Attack or Health read the total, slot buff included: Lends, Hit and Pile on, Tourney Champion's target, Gleaner's target.
12. Colour Ensign copies Renown onto its slot for this fight only.
13. No card doubles slot buffs or Renown now: the Sergeant Major gives Renown and doubles nothing, and the Edgewright left with the Mouse rework. *Retired 19 Nov 2026. S9 removed stat slot buffs and their multiplier hooks.*
14. Regimental Sergeant Major gives Renown to all seven slots at end of turn.

### Returns: Molt and Root

15. A return is a unit that died and came back: Molt and Root. Both trigger "after a friendly unit returns" (Twice-shed Veteran, Hazel Coppicer) and "after this returns" (Blackthorn Sapling).
16. Molt brings back a plain copy with 1 Health, then gives +2/+2 permanently. Root brings the unit back as it stands on the recruit board, at full Health.
17. One return for each death. A unit with both uses Root first when the Compost can pay, otherwise Molt.
18. A Private stepping in is a reservist.
19. Stepping in from Reserve, a Private, a Cousin, a Hopper landing and a copy from the Compost are not returns.
20. Every death of a returning unit is a real death: death effects, death counts and "after a friendly unit dies" cards see each one.
21. A returned unit is the same unit for every "a fight" limit: Pile on N, Charge N.
22. A return is not a summon and not joining the fight: the Air Marshal and Mother of Thousands don't see it.

*Weakens:* a Pigeon or Badger given Molt by a Skin-shedder comes back plain, so for the rest of that fight it has no granted Fury from Master-at-Arms. The unit on the recruit board keeps them.

### Attacks, Hits and damage

Three things deal damage: an **attack**, a **Hit** (pile-on hits included), and **plain damage** (Thorns, death effects, Gleaner, The Eighth Plague, the Lieutenant, Overrun's carried damage, Cleave's splash).

23. Only an attack triggers "whenever this attacks" on the attacker and "whenever this is attacked" on its target: Fury, Thorns, Gate Warden, Pile on, Thimble Captain, King Speck, War-drummer. A Hit and plain damage trigger none of them.
24. Thorns hurts only the unit making the attack. Units that pile on are not attacking. Units reached by Overrun or Cleave were not attacked, so their Thorns and Fury do nothing.
25. If Thorns kills the attacker, the attack ends: no "whenever this attacks" effects, no pile-on, no damage.
26. An attack that "takes no damage" (Hedge Lancer, Tourney Champion at the start of the fight) takes none from anything while it resolves, Thorns included. *Weakens:* the Thorn wall against the Badgers' Charge.
27. No card reduces attack damage any more. If one comes back, it does not reduce Thorns or Hits.
28. Overrun needs a kill to carry damage onward.
29. A kill belongs to the unit whose damage did it. When a pile-on kills the target, the attacker did not kill it. *Weakens:* Flying Ace (no Renown) and The Oakfeller (no extra attack) with Mice piling on next to them.
30. Overrun and Cleave apply only to an attack's damage exchange. A Sortie unit with Overrun carries on into the back row.

### A death effect triggered without a death

31. When a War-drummer or an eater sets off a death effect, nothing has died: death counts don't move (The Eighth Plague, Swarm-lord), "after a friendly unit dies" cards don't trigger (Gleaner, Padre, Old Brock, Sword-heir), and the unit doesn't return.
32. The effect itself resolves in full from where the unit stands. A Seed adds its entry, and Sweetbriar sees it. A summon that would take the unit's slot goes to the nearest empty one: a Hopper waits, a Pip or a copy from the Compost with no room is lost.
33. Dirge-singer doubles a death effect however it was set off. It doesn't double "after a friendly unit dies" cards or returns.
34. In the shop, a death effect that needs a fight does nothing (damage to an enemy, Old Stump's copy).

### Permanent gains made in a fight

35. A gain that says "permanently" is written to the unit in the fight and to the real unit at the same moment. It is kept if the unit dies later in that fight, win or lose.
36. A unit that exists only in the fight (a token, a copy) keeps it for the fight. A Reserve unit's gain goes to the unit in hand.
37. Numbers on the player (the Tide, the Hopper bonus) and the Compost are the real ones: a fight changes them at once and for good.
38. Renown earned in combat goes to the real slot immediately and counts from the next fight.
39. Gold earned in a fight is paid at the start of the next turn (Shrew Cutpurse). Relic Seeker pays at the start of that turn.
40. Grudge, Old Campaigner and Relic Seeker use the last fight's count and survivors at the start of the next recruit turn.

A fight against a saved copy of a board or the ghost writes nothing back to that side.

### Start of fight

41. Two passes. **Set-up pass,** both sides: Colour Ensign, Skin-shedder. **Main pass,** one side picked at random first (9.3.2), each side's units in reading order: Grow, Hedge Lancer, Tourney Champion, Herald of the Charge, Wing Commander, Parish Standard-bearer, Lieutenant, Sky-darkener, Elder Mother. Deaths resolve after each effect (9.3.5).
42. A unit that arrives during or after Start of fight doesn't run Start of fight effects.

*Weakens:* nothing, but position now matters in the main pass. A Standard-bearer buffs only the Mice present when it resolves.

### Own and borrowed stats

43. An effect that copies, keeps or takes a unit's stats uses its own stats only: Eat, Sword-heir, Old Brock, a copy from the Compost, a return, a triple. Never the slot's buff, lent stats, another aura, the Tide or the Hopper bonus.

*Weakens:* Sword-heir and Old Brock. The Badger draft had them take lent stats, and the Locust README promised them Hoppers "carrying the Tide". Under this ruling a Hopper is worth 2/2 to them and a Knight is worth what it holds itself. The Last Oath loses about 27 Health on its turn-9 board. The dial, if the plan is too thin: a line on Sword-heir alone, "and what its Squires lent it".

### Types and tribes

44. Type words are read from the type line, never the name. Knight and Squire are Badger words.
45. A token is its tribe (a Cousin is a Mouse for the Standard-bearer). A copy from the Compost is whatever tribe its card is.
46. A unit of another tribe can hold another tribe's keyword or counter (Fury on a Mouse, Reserve on a Badger, Molt on a Briar). Cards that name a tribe still check the tribe.

## 5. For the engineers: what the rules core has and lacks

From `src/core/README.md` on `ideation/core-bridge` (commit 5ded5653). Check these before coding a card that leans on them.

**There and usable:** hits and joining an attack (`hit`, `on_friendly_attack`), `attack_now`, `instead_of_attack`, `Q_CANT_ATTACK`, heaps that fights change for real, player counters, waiting summons (one line for each side, landing in reading order), `run_death_effects` in both phases, `Q_DEATH_EFFECT_TIMES`, paid returns (`return_health`, `on_returned`), `after_fight` with a `FightReport`, permanent write-back, fight gold, auras that give keywords, `Unit.grant_effect`.

**Missing or different:**

- **The outnumbered count.** `AuraContext.outnumbered()` is a live yes or no. The rule needs a number for each side, set once at fight set-up, leaving out back-row Squires, and saved in the fight report for `on_start_of_turn`.
- **Reserve.** Hand units are not in a fight yet, and nothing steps into "a slot a friendly unit died in".
- **The slot order in ruling 6.** The core lands waiting summons after returns. Reserve goes before that step and the Recruiting Sergeant's check after it.
- **Two Start of fight passes** (ruling 41).
- **Moving the Guard post.** A slot keyword can be added but not cleared through the context.
- **Bought or Created on fight units** (Lone Hawthorn).
- **Overrun, the "takes no damage" attack, and whose kill it was** when a pile-on kills.
- **Root's return** brings back the recruit-board unit, not a fresh copy; **Molt** counts charges.
- **Own stats** (ruling 43) as one helper every taker calls.

## 6. Fields in every `units.json`

Top level: `tribe`, `faction`, `type` (the tribe word cards use), `status`, `stat_scale`, `shared_rules`, `rules` (the tribe's own rule blocks), `keywords` (term and reminder, copied from section 2), `tokens`, `units`.

Each unit, in this order: `id`, `name`, `tribe`, `type` (the type line), `tier`, `attack`, `health`, `text`, `reminders` (the lines the card shows), `keywords` (glossary terms the card uses, spelled as here, without numbers), `golden`, `plans`, `reach` (`tribe-only`, `open` or `splash`), `splash_for` (empty unless `reach` is `splash`), `implementer` (how it works under these rules).

Each token: `id`, `name`, `tribe`, `type`, `tier`, `attack`, `health`, `text`, `reminders`, `keywords`, `implementer`.

For the engine's card data: `tribe` goes in `tribes`, and the words of `type` go in `types`.
