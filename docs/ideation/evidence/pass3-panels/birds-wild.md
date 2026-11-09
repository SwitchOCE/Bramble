# Birds, pass 3: "They come home bigger" (identity and delight)

9 Nov 2026. One designer of the Track C Birds panel (`plan-scale-rework.md`, step 1), on the identity-and-delight angle. Paper design: no Godot runs. The numbers come from a growth calculator, not a combat sim: `build/orchestrator/pass3/birds-wild-model.py` (run `python3 birds-wild-model.py 0.5 0.25`). No price list was used.

## The pitch in three lines

1. **Nobody is ever all home.** Sell a Bird and it flies south instead. You keep it.
2. **They come home bigger.** Every turn a Bird is away, it Grows by half. Two turns away means it comes home at 2¼ times its size.
3. **When all seven are home, the world ends.** The Seven Whistlers halve every enemy on the one turn the whole flock stands on your board together.

The sky is your bench and your bank. The board the opponent scouted isn't the board they fight: Birds land mid-fight, come home twice their size, or turn up all at once for the omen.

**What Battlegrounds doesn't have:** a unit you sell to make it stronger, a bench that grows while it's off the board, and a capstone that needs a full board of seven different units of one tribe. The closest things: Magic's suspend and phasing (the delay), stat doublers (the Golden Egg), and Hearthstone's Menagerie cards (the "different units" count).

## Why this fixes what the audit found

- **Stats parked at half.** Eggs no longer hold half a Bird. A Bird away grows instead, so absence is now the payoff, not a tax.
- **Flat, capped growth.** Growth is proportional, so it is small at round 4 (a 2/3 comes home 5/7) and large at round 12 (a 40/40 comes home 90/90), with no cap. This is the "level to round 7, then ×1.5 a round" shape by construction.
- **Combat-only payoffs.** The main payoffs (Grow, the Golden Egg, the Lump's meals, Redbreast) are permanent and visible: on the board, or in the away tray with a "home next turn: 68/68" line.
- **No concentration.** Both carry routes pile stats onto one unit, and both carries get Cleave to use their overkill.
- **Thin gold-to-stats channel.** Mrs Stork turns spent gold into homecomings that Grow.

---

## Tribe rules (pass 3)

**Fly South** (keyword). Reminder: *"Sold, it flies south 2 turns, growing each End of Turn, then comes home to hand."*
- Details: it pays no sale gold. A Bird played this turn can't fly, so selling it is a plain sale. It comes home before Start of Turn text. If your hand is full, it waits on the doorstep. Kept from pass 2.

**Grow** (new keyword, 4 cards). Reminder: *"Gains half its current stats."*
- Details: rounded up. It reads current Attack and Health, with the tribe bonus. The gain is permanent. A golden Bird doesn't Grow twice: its doubled base already doubles everything.
- **This "half" is the tribe's rate parameter, r.**

**Nest.** Reminder: *"The slot a Bird left. A 0/1 Egg fights there unless a unit stands on it."*
- One Nest per slot. A new Nest replaces the old one, but the older Bird still comes home. The Nest doesn't move. Kept.

**Egg** (changed). A 0/1 with no text. It was half the Bird's current stats.
- A 0/1 cracks at the first hit. That is what makes the Gabble Ratchet's landing a moment.
- Tom Tit and Redwing raise it.
- An empty Nest shows `Egg 0/1 · home in 1`.

**Unchanged:** away Birds can't be aimed at, don't count for triples, and return their pool copies on elimination. Ghost snapshots carry the away list.

---

## The 16 Birds

Tier spread 3/3/3/3/2/2, as now. Every creature, name and portrait is kept. Six Birds fly: One Swallow, Chiffchaff, Mrs Jay, Jack Daw, Old Tern and Mother Goose. Redwing no longer flies. T4–T6 bodies are a little larger, so a tier-up lands near the median unit.

| T | Card | Stats | Text | Golden |
|---|---|---|---|---|
| 1 | One Swallow | 1/2 | Fly South. When played: get 1 gold. | 2/4. …get 2 gold. |
| 1 | Chiffchaff | 1/2 | Fly South. When played: gain +1/+1. | 2/4. …+2/+2. |
| 1 | Mrs Dunnock | 2/3 | End of Turn: a Bird whose Nest is beside this comes home a turn sooner. | 4/6. …two Birds whose Nests are beside this… |
| 2 | Mr Redbreast | 2/4 | End of Turn: gain +1/+1 for each Bird away. | 4/8. …+2/+2… |
| 2 | Mrs Jay | 3/3 | Fly South. When sold: get an Acorn. | 6/6. …two Acorns. |
| 2 | Redwing | 2/4 | Eggs beside this have half their Bird's Attack. | 4/8. …their Bird's Attack. |
| 3 | Jack Daw | 3/3 | Fly South. Start of Combat: steal a quarter of the Attack of the enemy across. | 6/6. …steal half… |
| 3 | Old Tern | 3/4 | Fly South. When this comes home: your other Birds away Grow. | 6/8. …Grow twice. |
| 3 | Tom Tit | 3/4 | Your Eggs have their Bird's Health. | 6/8. Your Eggs have their Bird's stats. |
| 4 | Mrs Stork | 4/7 | Every 6 gold you spend: a Bird away Grows and comes home. | 8/14. …two Birds away… |
| 4 | The Cuckoo | 4/7 | When a Bird beside this flies: it Grows. | 8/14. …it Grows twice. |
| 4 | Mag Pye | 4/7 | Start of Combat: steal the text of the enemy across. | 8/14. …across and the next along. |
| 5 | The Great Lump | 5/7 | Cleave. End of Turn: if this is on a Nest, gain a quarter of its Bird's stats. | 10/14. …gain half… |
| 5 | Mother Goose | 6/8 | Fly South. When played: get a Golden Egg. | 12/16. …two Golden Eggs. |
| 6 | The Gabble Ratchet | 6/10 | When a unit on a Nest dies: its Bird lands there. | 12/20. …lands there with double stats. |
| 6 | The Seven Whistlers | 7/9 | Start of Combat: halve the enemy across. With seven different Birds on your board, halve every enemy. | 14/18. …loses three quarters… every enemy does. |

**Golden Egg** (token spell, 0 gold, Created): *"Double a Bird's stats. It gains Cleave."*

**Text length:** median 9.5 words, longest 17, inside the guide's 22.

### Reading the per-card lines

- **Rough stats** use r = ½ on the two typical lines below (T4 on round 7, T5 on 10, T6 on 12, Suppers on rounds 8, 10 and 12). A range runs from the plain line to the line that supports the card.
- **"Away"** means the Bird is in the sky that fight.

---

### Tier 1

**One Swallow** (1/2). *Swallow, Seasonal Labourer.* Fly South. When played: get 1 gold.
- **Condition:** played, which includes every replay after a trip.
- **Payoff:**
  - Money: about 1 gold every 2–3 rounds, so roughly 3 gold by R9, 5 by R12 and 7 by R15.
  - The body Grows too: R9 6/9 to 14/21, R12 about 36/51 (with Stork), R15 about 180/260 if you're still flying it. Usually it's sold by R12.
- **Permanence:** gold is economy; the body's growth is permanent.
- **Enables:** Mrs Stork's 6-gold count, Old Tern's "other Birds away", the Whistlers' count. Turn-1 buy: a 1/2 that refunds a gold.
- **Concentrates:** no.

**Chiffchaff** (1/2). *Warbler, Town Crier.* Fly South. When played: gain +1/+1.
- **Condition:** played.
- **Payoff:**
  - +1/+1 a landing, which every later trip multiplies. It plays as a 2/3 on turn 1.
  - R9 16/24 to 23/35. R12 57/84 to 125/185. R15 190/280 to 390/580 (the high end is beside the Cuckoo).
- **Permanence:** permanent.
- **Enables:** the Cuckoo's and Lump's best food, a Golden Egg target, and Tom Tit Eggs with big Health.
- **Concentrates:** yes. It's the tiny warbler that comes back from Africa as the carry.

**Mrs Dunnock** (2/3). *Hedge Sparrow, Foster Mother.* End of Turn: a Bird whose Nest is beside this comes home a turn sooner.
- **Condition:** a Nest beside her at End of Turn.
- **Payoff:** tempo. That Bird misses one fight, not two, but Grows once (×1.5, not ×2¼).
  - R4–R8 this keeps a 5–15-stat Bird in one more fight.
  - By R9 she should be sold.
- **Permanence:** none.
- **Enables:** early flights in the Homecoming line. She works against the Cuckoo and the Lump.
- **Concentrates:** no. Her window is R1–R7; after that she is a trap, and the bot line sells her on R8.

### Tier 2

**Mr Redbreast** (2/4). *Robin, Who Stays.* End of Turn: gain +1/+1 for each Bird away.
- **Condition:** Birds in the sky at End of Turn.
- **Payoff:** linear, about +2–3/+2–3 a turn.
  - R9 11/13 to 16/18. R12 20/22 to 27/29. R15 26/28 to 35/37. Golden doubles the gain.
  - With Golden Eggs he is the stay-at-home carry: about 85/93 by R15 on two Eggs.
- **Permanence:** permanent and visible.
- **Enables:** a reliable Golden Egg target that never misses a fight.
- **Concentrates:** partly (self, linear). The front-row wall that holds while everyone's gone. Buy him at R2–R3 with one flier already out.

**Mrs Jay** (3/3). *Jay, Who Plants Oaks.* Fly South. When sold: get an Acorn.
- **Condition:** flown. Flying is selling.
- **Payoff:**
  - An Acorn (1 gold, or Hedgerow food) every trip.
  - The best flier body in the tribe: R9 13/13 to 42/42, R12 50/50 to 143/143, R15 113/113 to 476/476.
  - As the Golden Egg carry: 111/111 at R12 and 489/489 at R15.
- **Permanence:** permanent.
- **Enables:** Hedgerow's Acorn payoffs and Stork's count. The default carry for the Golden Egg and the Cuckoo.
- **Concentrates:** yes.

**Redwing** (2/4). *Thrush, Winter Visitor.* Eggs beside this have half their Bird's Attack.
- **Condition:** Eggs beside it in the same row. At most two.
- **Payoff:** those Eggs hit with half their Bird's Attack.
  - About +10 Attack at R9, +25–70 at R12, +60–240 at R15.
  - With Tom Tit, an Egg becomes half a Bird with full Health: Jay's Egg is 21/42 at R9.
- **Permanence:** a fight aura, shown on the Nest.
- **Enables:** Tom Tit, the Ratchet (an Egg that trades, then cracks), the Sky line's R8–R10 peak.
- **Concentrates:** no. It shows the sky in the fight. It stopped flying, because a Redwing away switches its own aura off.

### Tier 3

**Jack Daw** (3/3). *Jackdaw, Collector of Other People's Things.* Fly South. Start of Combat: steal a quarter of the Attack of the enemy across.
- **Condition:** an enemy across at Start of Combat. The back row counts, so B2 faces B2.
- **Payoff:** proportional theft.
  - Against the typical enemy across: about 2–3 Attack at R9, 10–25 at R12 and 30–75 at R15.
  - The same quarter of a 300-Attack carry is 75.
  - His own body Grows when flown: 22/22 at R12, 50/50 at R15.
- **Permanence:** the theft lasts the fight; the body is permanent.
- **Enables:** answers (see the tribe section) and the Whistlers' count.
- **Concentrates:** no. Scout, then move him across their carry.

**Old Tern** (3/4). *Arctic Tern, Who Has Seen Both Poles.* Fly South. When this comes home: your other Birds away Grow.
- **Condition:** she lands while other Birds are away. Stork's recall counts.
- **Payoff:** a Grow for the whole sky.
  - About +10 stats at R9 (on a ~20-stat sky), +50–100 at R12, +250–500 at R15 per landing.
  - Her own body: 22/24 at R12, 50/54 at R15.
- **Permanence:** permanent.
- **Enables:** Stork (call her home on purpose), the Cuckoo and the Lump (bigger food).
- **Concentrates:** no. It spreads across the sky, but the biggest Bird gains the most. Fly her with a full sky.

**Tom Tit** (3/4). *Blue Tit, Who Minds the Eggs.* Your Eggs have their Bird's Health.
- **Condition:** Eggs on the board.
- **Payoff:** Eggs become 0-Attack walls with the Bird's Health.
  - About +20–40 Health at R9, +80–140 at R12, +250–500 at R15 (Chiffchaff's Egg is 0/279 at R15).
  - A surviving starting Egg adds hero damage.
- **Permanence:** a fight aura, shown on the Nest.
- **Enables:**
  - Flying gets cheaper, because the slot still holds a wall.
  - Redwing adds Attack.
  - With the Ratchet, the Egg soaks hits first and then the Bird lands, two bodies from one Bird.
- **Concentrates:** no. Golden Tom Tit makes flying free: a highroll.

### Tier 4

**Mrs Stork** (4/7). *White Stork, Postmistress.* Every 6 gold you spend: a Bird away Grows and comes home.
- **Condition:** 6 gold spent, with a Bird away that has missed a fight. You pick which; if you don't, it's the one away longest.
- **Payoff:** a 2-turn trip becomes 1 fight away with the same 2¼× growth, so the flock cycles twice as often.
  - About one recall a turn R7–R9, and two from R10.
  - Each recall is one more fight from a ~20-stat Bird at R9, a ~100-stat Bird at R12 and a ~300-stat Bird at R15.
  - Plus its When played text again: Swallow gold, Chiffchaff +1/+1, Goose's Golden Egg.
- **Permanence:** the growth is permanent.
- **Enables:** Mother Goose (an Egg every 2 turns, not 3), Old Tern on demand, and the Whistlers' all-home turn.
- **Concentrates:** partly (you choose who comes home).
- **Why buy:** late gold buys power. Each 3-gold unit or refresh also counts toward the next homecoming.

**The Cuckoo** (4/7). *Cuckoo, Who Doesn't Raise Its Own.* When a Bird beside this flies: it Grows.
- **Condition:** a Bird flies from a slot beside it in the same row. At most two Nests.
- **Payoff:** each trip is ×3⅜, not ×2¼.
  - On Mrs Jay: 32/32 at R9 (21/21 without), 113/113 at R12 (50/50), 383/383 at R15 (113/113).
- **Permanence:** permanent.
- **Enables:** the Lump's meals, the Ratchet's landers, Golden Egg targets.
- **Concentrates:** yes, on two slots. The slot puzzle is which two fliers sit beside her.

**Mag Pye** (4/7). *Magpie, Receiver of Stolen Goods.* Start of Combat: steal the text of the enemy across.
- **Condition:** the enemy across has text worth having. It resolves before other Start of Combat text.
- **Payoff:**
  - Their engine is hers this fight: Cleave off their carry, Lollop's aura, the Lantern Man's count, a Belly, Nightshade.
  - Against a plain unit, nothing.
- **Permanence:** this fight only.
- **Enables:** nothing (it's an answer).
- **Concentrates:** no. Kept from pass 2 at a larger body.

### Tier 5

**The Great Lump** (5/7). *Cuckoo Chick.* Cleave. End of Turn: if this is on a Nest, gain a quarter of its Bird's stats.
- **Condition:** standing on the Nest of a Bird that is away, at End of Turn. You may move it to the biggest Bird's Nest each turn.
- **Payoff:**
  - A permanent copy of a quarter of the sky's biggest Bird, every turn: 75/93 at R12 and 356/454 at R15 on the typical Sky line.
  - With two Golden Eggs it's 1,400/1,800.
  - Cleave spends its overkill on the units beside its target.
- **Permanence:** permanent and visible. It needs no flight, so it fights every round.
- **Enables:** the Ratchet. When the Lump dies on a Nest, that Bird lands in its place.
- **Concentrates:** yes. It's the tribe's non-flying carry. The joke is the flavour: much too big for the nest, and it pushes the others out.

**Mother Goose** (6/8). *Greylag, on a Very Fine Gander.* Fly South. When played: get a Golden Egg.
- **Condition:** played, whether bought or replayed after each trip. One trip takes 3 rounds, or 2 with Stork or Dunnock.
- **Payoff:** each Golden Egg doubles a Bird and gives it Cleave.
  - About +20–40 stats at R10, +50–110 at R12 and +200–500 at R15 per Egg.
  - On arrival she doubles your best Bird at once, so the tier-up is felt the turn you buy her.
  - Her own body: 15/19 at R12, 50/65 at R15.
- **Permanence:** permanent.
- **Enables:** any carry. With Stork it's the Homecoming line's doubler.
- **Concentrates:** yes, strongly. From the rhyme: Jack's goose laid him a golden egg.

### Tier 6

**The Gabble Ratchet** (6/10). *Wild Geese, Hounds of the Night Sky.* When a unit on a Nest dies: its Bird lands there.
- **Condition:** an Egg, or a unit standing on a Nest, dies in the fight. Once per Nest a fight.
- **Payoff:** the away Bird lands at its current stats and fights the rest of the fight. Afterwards it is away again, with its trip unchanged.
  - About +150–330 stats mid-fight at R12 and +500–1,000 at R15 (Jay 476/476 lands when the Lump dies).
- **Permanence:** the landing lasts the fight; the Bird's stats are permanent.
- **Enables:** 0/1 Eggs crack at once, Tom Tit Eggs soak first, and the Lump's death brings its Bird.
- **Concentrates:** yes (it lands the big ones). The owner's favourite idea from pass 1, kept: both halves of the Bird at once.

**The Seven Whistlers** (7/9). *Curlews, Six Looking for the Seventh.* Start of Combat: halve the enemy across. With seven different Birds on your board, halve every enemy.
- **Condition:**
  - Always: an enemy across.
  - The omen: all seven slots hold different Birds, Whistlers included, so no Eggs, no copies and no other tribes.
- **Payoff:**
  - Across: −35 to −150 stats at R12 (an average unit to a carry), −120 to −500 at R15.
  - All seven home: about −250 at R12 and −850 at R15, the whole enemy board halved.
- **Permanence:** this fight only.
- **Enables:** it rewards a planned "everyone home" turn (Stork recalls, no flights) and pulls against flying and tripling.
- **Concentrates:** no (it's an answer). Changed from pass 2's −1/−1 per homecoming.

---

## The tribe

### Engine and rate parameter
**The engine is Grow-while-away.** A flier gains r of its stats each End of Turn it's away. The flock compounds at about ×1.3 a round on plain 2-turn trips (away 2 fights in 3), and about ×1.5 a round with Mrs Stork (away 1 fight in 2). Additive buffs bought between trips (Supper, Chiffchaff, Pinch, Last Orders) get multiplied by later trips, so **cast your buffs on a Bird before it flies.**

**Rate parameter: r, the Grow fraction. Default ½.** The sweep should try 0.3 to 0.75. Board totals on the two typical lines (from the model):

| r | Line 1 R12 | Line 1 R15 | Line 2 R12 | Line 2 R15 |
|---|---|---|---|---|
| 0.4 | 357 | 978 | 376 | 1,100 |
| **0.5** | **438** | **1,458** | **496** | **1,958** |
| 0.6 | 535 | 2,140 | 719 | 3,820 |
| Target median | ~500 | ~1,700 | ~500 | ~1,700 |

Secondary knobs if a piece runs hot: the Lump's fraction (¼), the Golden Egg (×2), the Whistlers (½), Stork's step (6 gold), and the Cuckoo's extra Grows (1).

### When it comes online
- **R3–R5: behind.** Flights cost fights while losses are cheap (round base 0–1). The Sky line's R4 board is about 26 stats against today's 30.
- **R6: level or a little ahead** (51–73).
- **R7–R8: online.** Stork or the Cuckoo arrives, and a Bird comes home 20+/20+ for the first time.
- **R10: the carry starts.** Mother Goose's first Golden Egg, or the Lump's first meal.

Birds are a slow-start, strong-finish clock.

### The decision it creates
Every turn: **who flies, before which fight?**
- A flight gives up a body (and its text) now, for 2¼× later.
- You scout the next opponent. Fly before a ghost or a weak board; keep the flock home before a rival or an elimination fight.
- Hero Health is what you spend.

Around that:
- **Where the Nests go:** beside the Cuckoo (grow more), beside Dunnock (home sooner), beside Redwing (Eggs that hit), front row once the Ratchet is out (landers become the wall), or under the Lump (it eats).
- **Who gets the Golden Egg:**
  - the Bird about to fly, so the trip multiplies a doubled base;
  - or the Bird that stays, a reliable carry.
- **Diversify or triple:** the Whistlers want seven different Birds; goldens want three of one.
- **Whether to land everyone** for the omen this turn and give up a turn of growth.

### Carry routes
1. **The Golden Egg (Homecoming line).**
   - Pick one flier: Mrs Jay by default, or Chiffchaff, or Redbreast if you want it never to miss a fight.
   - Pour Supper and buffs into it, fly it with Stork, and double it with every Golden Egg. Cleave comes with the first Egg.
   - About 111/111 at R12 and 489/489 at R15 on a typical roll.
2. **The Great Lump (Sky line).**
   - It never flies. It sits on the biggest away Bird's Nest and eats a quarter of it each turn. It cleaves.
   - It takes Golden Eggs too. When it dies, the Ratchet lands the Bird it was eating.
   - About 75/93 at R12 and 356/454 at R15.

### Non-carry route: the Flock
- Five or six fliers cycle through Stork and the Cuckoo, each about 50/50 by R12.
- Tom Tit and Redwing make the Eggs hold and hit.
- The Gabble Ratchet lands the whole sky mid-fight.
- The Seven Whistlers halve the enemy across every fight, and halve every enemy on the turn all seven are home.
- No unit is over 40% of the board, so answers that halve one unit do little.

### Answers to other tribes' carries
- **Seven Whistlers:** halves the enemy across, in either row, every fight. On an all-home turn, it halves every enemy.
- **Jack Daw:** steals a quarter of the Attack across. Golden steals half. It grows with the target, so it stays relevant at any scale.
- **Mag Pye:** takes the carry's text: Cleave, an aura, a Belly or Nightshade.
- **The sky as a dodge:**
  - Scout a Changeling, Belladonna or Bufo across your carry? Fly the carry south this turn. Away Birds can't be hit.
  - No other tribe can hide its carry from a bad matchup.
- **All three answers aim across.** They reach a back-row carry only if you scout and place them there, so they reach it sometimes, not always. That is the default in `fundamentals.md` question 2.

### Weak points
- **Early tempo.** R3–R6 boards are thin while Birds fly, and tempo tribes punish that. Losses are cheap then; the Health spent shows up later.
- **Proportional answers on the carry.** Bufo, Belladonna and the Changeling scale with the carry: a Changeling turns a 978/978 Jay against you. The dodge needs scouting and a free flight.
- **Back-row reach.** The Ratchet, Stork, the Cuckoo and the Whistlers sit behind. Kill the Ratchet and nothing lands.
- **Being read.** Nests show. A careful opponent keeps its carry off the slots across from Jack Daw, Mag Pye and the Whistlers.
- **Away Birds can't take spells.** Cast before you fly.
- **Wide boards against a single carry.** A carry kills one unit an attack; Cleave helps but doesn't fix it. The Flock route is better there.
- **Supply.** Six fliers are shared by the lobby, so a second Bird player starves you of Jays and Chiffchaffs.
- **The omen fights the engine.** An all-home turn is a turn without growth.

### Two highroll moments
1. **The goose that laid the golden egg.**
   - Golden Mother Goose plus Mrs Stork: she lands every second turn with two Golden Eggs.
   - The same Mrs Jay goes from 20/20 on round 10 to 80/80, flies, comes home 180/180, eats two more Eggs at 720/720, and after round 14's trip and two more Eggs stands at about 6,500/6,500, cleaving. (Two recalls a turn need about 12 gold spent.)
   - It takes a golden T5 plus Stork, so it's a top-1% game. Ten times the median is acceptable (owner, 9d).
2. **All seven home.**
   - Round 13: four units and three Eggs on the scouted board. Stork calls two Birds home, the Tern's landing pulls a third, and seven different Birds stand on the board for the first time all game.
   - The curlews whistle and every enemy halves before the first attack.
   - The tribe's motto is "Nobody is ever all home". The one time they are, the world ends.
   - *Also:* the everyday surprise is the Gabble Ratchet. An Egg cracks under the first hit and a 476/476 Jay drops out of the sky into the slot.

---

## Boards (typical rolls, r = ½, Lump ¼)

The board is 7 slots: units home plus Eggs on empty Nests. The sky isn't counted unless the Ratchet lands it. Targets: ~55 / ~150 / ~500 / ~1,700 (level with today's to R7, then ×1.5 a round).

**Line 1, Homecoming:** Dunnock early, Stork R7, Tern R8, Goose R10, Whistlers R12, Eggs on Mrs Jay.

| Round | Board | vs target | Biggest | On the board |
|---|---|---|---|---|
| R6 | 51 | 0.93 | Redbreast 6/8 | Redbreast, Swallow, Dunnock, Jack Daw, Tom Tit; Eggs 0/9 (Chiffchaff), 0/5 (Jay) |
| R9 | 119 | 0.79 | Jay 13/13 | Redbreast 11/13, Swallow 6/9, Jay, Jack Daw 4/4, Tom Tit, Stork 5/8; Egg 0/24 |
| R12 | 438 | 0.88 | Jay 111/111 (50%) | Jay (2 Eggs, Cleave), Redbreast 20/22, Goose 17/21, Whistlers, Stork, Tom Tit; Egg 0/84 |
| R15 | 1,458 | 0.86 | Jay 489/489 (67%) | Jay (3 Eggs), Tern 44/51, Redbreast 26/28, Whistlers, Stork, Tom Tit; Egg 0/279 |

Plus the Whistlers' halving across: about −35 to −150 at R12 and −120 to −500 at R15.

**Line 2, Sky:** Redwing and Tom Tit Eggs, the Cuckoo R7, the Lump R10, the Ratchet R12. No Stork, no Goose.

| Round | Board | vs target | Biggest | On the board |
|---|---|---|---|---|
| R6 | 73 | 1.33 | Redbreast 8/10 | Redbreast, Redwing, Chiffchaff 6/9, Swallow, Tern, Tom Tit; Egg 4/8 (Jay) |
| R9 | 203 | 1.35 | Chiffchaff 23/34 | Redwing, Cuckoo, Chiffchaff, Redbreast 16/18, Tern 9/10, Tom Tit; Egg 21/42 (Jay) |
| R12 | 496 | 0.99 | Chiffchaff 79/117 (39%) | Lump 75/93, Chiffchaff, Redbreast 27/29, Cuckoo, Ratchet, Tom Tit; Egg 0/24 |
| R15 | 1,958 | 1.15 | Chiffchaff 390/583 (49%) | Lump 356/454, Chiffchaff, Redbreast 35/37, Cuckoo, Ratchet, Tom Tit; Egg 0/51 |

Plus the Ratchet's landers: about +330 at R12 and +1,050 at R15.

**Strong rolls** (T4 R6, T5 R8, Goose by R9, eggs on the Lump) run about 2–3 times these by R15: 4,000–5,000. That matches Battlegrounds' p90/p50 of about 2.4 at turn 15. The golden Goose plus Stork line is the 10× tail.

**Reading:** both lines sit near the target from R12. Line 1 lags at R9 ("behind at once"). Line 2 runs about 1.3× from R6 to R9, because cheap early flights and Redwing/Tom Tit Eggs are strong then. If the sweep shows Birds winning R5–R9 too often, take the Line 2 levers below first.

---

## Where it could run away, and the lever for each

| Risk | Why | Lever, in order |
|---|---|---|
| Golden Goose + Stork | ×4 every 2 rounds on one Bird | Accept as the top-1% tail (owner, 9d). If it's common: Golden Egg "+half" instead of ×2 when golden. |
| Cuckoo + Stork on one Bird | 3 Grows per 2-round cycle, ×1.84 a round | The Cuckoo Grows only Birds on 2-turn trips (no Stork recall that trip). |
| Lump on Cuckoo food | It copies a quarter of a fast grower every turn | Lump fraction ¼ → ⅕, or it eats only a Bird away for 2+ turns. |
| Cheap early flights (Line 2, R6–R9 at 1.3×) | Early losses cost 0–2 Health | Grow starts on a trip's second End of Turn; or Tom Tit gives half Health. |
| Redwing + Tom Tit, "free flight" | Two Nests fight at full Health and half Attack, so flying costs little | Accepted as a T2+T3 reward. If it removes the flying decision, Redwing reaches one Egg. |
| The omen is common | A full Bird board at T6 halves every enemy | Count only after a Stork or Tern recall that turn; or at seven, every enemy loses a quarter. |
| Stork + Swallow gold | Gold refunds feed recalls | Bounded: a Bird must miss a fight, and a Swallow refunds 1 per 6 gold. |

No per-card size caps. The rate limits are the ones already in Fly South: a Bird must fight at home before it flies again, and Stork needs it to have missed a fight.

---

## Harness line policies

Card ids are as in `content/units/`. The new token is `golden_egg`; `nest_egg` changes to 0/1.

### `birds_homecoming` (tempo → Golden Egg carry)
- **Buy and keep, in order:** mother_goose, mrs_stork, seven_whistlers, old_tern, mrs_jay, chiffchaff, tom_tit, one_swallow, mr_redbreast, jack_daw, mag_pye, gabble_ratchet, mrs_dunnock (R1–R7 only), redwing, cuckoo, great_lump.
- **Sell first:** mrs_dunnock (R8), then jack_daw, then one_swallow (R12), then mag_pye.
- **Climb:** T2 R2, T3 R5, T4 R7, T5 R10, T6 R12. Climb a round early if the gold is there and the last fight was won.
- **Save:**
  - Spend out every turn from R1. From R7, Stork counts every gold spent, so leftover gold is lost homecomings.
  - The one save: bank 2–3 on R9 to make T5 on R10.
  - Hold a Golden Egg in hand only while the carry is away; play it the turn the carry lands.
- **Fly policy (engine flag):**
  - Fly a Bird that fought last round if any of these hold:
    - Stork is on the board;
    - the scouted opponent's last board is under 0.8× yours, or a ghost;
    - it's round 5 or earlier and Dunnock is beside the Nest.
  - Keep at least 4 units with Attack home.
  - Don't fly the carry before a fight that could knock you out (Health ≤ 2× the round's likely loss).
  - On a turn when seven different Birds can stand on the board with the Whistlers, recall with Stork and fly nothing.
- **Golden Egg target:** the carry if it's home, else the biggest home Bird that flies next turn.

### `birds_sky` (engine and carry: Cuckoo, Lump, Ratchet)
- **Buy and keep, in order:** great_lump, cuckoo, mother_goose, gabble_ratchet, chiffchaff, mrs_jay, tom_tit, redwing, old_tern, mr_redbreast, one_swallow, jack_daw, mrs_stork, seven_whistlers, mag_pye. Mrs_dunnock only as an R1–R2 body, sold by R5.
- **Sell first:** one_swallow (R10), then redwing (once the Ratchet is out), then jack_daw.
- **Climb:** T2 R2, T3 R4, T4 R6, then hold T4 on R7–R8 while the sky builds. T5 R9, T6 R11–R12.
- **Save:** bank 3–4 on R8 to make T5 on R9. Otherwise spend out.
- **Fly policy:**
  - Fly every flier the turn after it fights.
  - The two biggest fliers fly from the slots beside the Cuckoo.
  - Before End of Turn, move the Lump onto the Nest of the biggest Bird away.
  - Once the Ratchet is out, put Nests in the front row.
- **Golden Egg target:** the Lump.

### Bot needs for both lines
The bots need a fly decision, Nest placement, the Lump's seat, a Golden Egg target and Stork's pick. Without them, Birds look weak for the wrong reason, as in passes 1 and 2.

---

## Engine support needed

**Exists** (pass 2): the Fly South away zone and Nests, `on_home`, `bring_home` and `on_gold_spent every N` (Stork), count selectors (Redbreast), the Gabble Ratchet landing, `mag_pye`, `dunnock`, and Acorns.

**Changed or new:**
1. **Grow.** At End of Turn, each away Bird gains ceil(r × stats), with r in config (the lever). Its order: after board End of Turn text, before the Lump reads its Bird.
2. **Egg.** The default `egg_spec` becomes 0/1. Tom Tit sets Health (full); golden Tom Tit sets full stats. Redwing sets ceil(½ Attack) beside it; golden Redwing sets full Attack. The strongest of each applies.
3. **Cuckoo.** An `on_fly` trigger for a slot beside it gives Grow ×1 (golden ×2).
4. **Stork.** A player-chosen eligible away Bird gets Grow, then `bring_home`. If none is chosen, the one away longest.
5. **Old Tern.** `on_home` gives the other away Birds Grow.
6. **The Great Lump.** At End of Turn, on a Nest: a permanent buff of ceil(¼ × the Bird's stats). Plus Cleave (Track B).
7. **Mother Goose.** `on_play` adds a `golden_egg` spell. The Golden Egg is a 0-gold aimed spell, Bird only: double Attack and Health (permanent layer, Track B's doubler) and grant Cleave.
8. **Jack Daw.** A proportional Attack steal across (Track B proportional).
9. **Seven Whistlers.** Halve the enemy across (Track B). A distinct-Birds-on-board count, then halve every enemy.
10. **Redbreast.** End of Turn +1/+1 × the count of away Birds.

**UI:**
- An away tray shows each Bird's stats now, at the next End of Turn, and at landing (`home in 1 · 45/45 → 68/68`).
- Nests show Egg stats.
- The Golden Egg previews its target.
- Stork's recall offers a pick.
- The sell button already says "Fly south".

**Ghosts:** snapshots keep the away list, so the Ratchet works against ghosts.

---

## Variations, if the panel wants another shape

- **Grow at homecoming only** (×2¼ in one pop). It's one visible jump, not two, and the same rate.
- **Long Haul.** When sold, choose 1–3 turns away. The trip length becomes a per-flight decision, and Dunnock, the Cuckoo and Stork become shortcuts rather than rules.
- **The Whistlers count the sky.** "Start of Combat: every enemy loses a tenth for each Bird away" (up to 7). That ties the capstone to flying rather than landing. It's less memorable but a smoother curve.
- **Golden Egg on any unit.** It splashes into other tribes, so I advise against it: tribe-only payoffs keep the tribe word (`fundamentals.md`).
