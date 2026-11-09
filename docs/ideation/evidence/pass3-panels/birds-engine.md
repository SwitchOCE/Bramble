# Birds, pass 3: the Flyway (engine-first design)

One designer's entry for the Birds panel (Track C, `docs/ideation/plan-scale-rework.md`). Angle: **engine first.** Paper design only. Nothing here has run in Godot. The board numbers come from a rough paper model, `birds-engine-model.py` in this folder (`python3 -I birds-engine-model.py r=1 max_stay=4 golden_bird_x2=1`). It plays scripted lines: no fights, no opponents, and a naive "fly everything" policy. Treat its numbers as the scale of the curve, not as measurements.

## The pitch

Nobody is ever all home, and now every trip pays. A Bird that flies south comes home with the **Tailwind**: +X/+X for good. Each homecoming then raises the Tailwind by 1. Mr Redbreast never flies. He stays behind and grows every time anyone comes home, so he is the tribe's carry. Mrs Stork turns spare gold into early homecomings, Old Tern calls the whole flock home at once, and Mother Goose doubles the wind when she lands. Every turn asks the same question: **who flies today?** A flight costs that Bird's body for two fights, because only a half-size Egg holds its slot. It buys a bigger Bird, a bigger robin and a stronger wind for the rest of the game.

*Similar to:* Battlegrounds' Blood Gems and Elemental counters ("this game" values that keep rising) and Brann-style doublers. Phasing in Magic for the coming and going. No Battlegrounds tribe pays for being sold.

## Why this fixes what's wrong now

The current Birds are the weakest tribe (4.9% first). Causes, from `fundamentals.md` and the audit (`card-audit-birds-bog-fairies.md`):

| Problem now | Pass 3 answer |
|---|---|
| Away stats sit at half value, and nothing pays them back (audit assumption 1, "High risk") | Every trip pays interest. The Bird comes home +X/+X, and the Lump, Redwing, the Ratchet and Cuckoo keepers put away stats into the fight at full |
| The only open-ended pile (the Cuckoo) sits away, so it is invisible | The carry, Mr Redbreast, never leaves. His growth shows on the board and in the scout |
| The two routes (Homecoming and Hatchery) fight each other: Tern, Stork and Dunnock cut Cuckoo trips short | Both routes now want **homecomings**. Shortening a trip is always good |
| Payoffs are linear, capped or fight-only (6 of 11) | One rising number, permanent growth, a doubler at T5. Fight-only effects are kept for answers and the T6 landing |
| The owner (8 Nov): "why would I ever want these units on the board in the early game?" | Turn 1: Chiffchaff plays as a 2/3, Swallow pays a gold, Dunnock is a 2/3. Redbreast grows from any homecoming and doesn't need Nests |
| Economy doesn't feed stats | Stork turns all spending into homecomings, and Swallow and Jay gold feeds Stork |

## The engine

### Rules (new or changed)

- **Tailwind** (new tribe number). It starts at 1 each game and shows on the Birds' tribe icon, like the Supper bonus.
  - When a Bird comes home, it gains +X/+X permanently, X being your Tailwind. Then Tailwind rises by **r** (the rate parameter, default 1).
  - "Gains the Tailwind" on a card means it gains +X/+X too.
  - Golden Birds gain it twice. *(Why: golden doubles the card, and the homecoming bonus is the card's main payoff.)*
  - *Reminder:* "Birds gain +X/+X when they come home. Then it rises by 1." (12 words)
- **Fly South** (changed reminder): "Sells for no gold. Comes home in 2 turns and gains the Tailwind." (12 words). It works as today: it must fight once at home before it can fly, it returns to hand, and its When played text fires again.
- **Comes home** means any return from away to hand: the trip ends, Dunnock, Stork or the Tern. The Ratchet's mid-fight landing is not a homecoming.
- **Nest and Egg:** unchanged (half stats, no text). The half Egg is the price of investing. Its fraction is a secondary lever (below).
- **Biggest:** most Attack plus Health. Ties go in reading order. Used by Tom Tit, Jack Daw and the Whistlers. The enemy version is Track B's "biggest enemy in any row" selector.
- **Shield** (Track B): the first damage this takes is prevented. The name follows whatever Track B settles on.
- **Order at a homecoming:** the Bird gains X → Redbreast and Cuckoo keepers gain X → Tailwind rises by r → that Bird's own homecoming text (Goose doubles, the Tern calls the others home, each in turn).

### How it compounds

Growth per turn ≈ **homecomings a turn × Tailwind × (1 + listeners)**.
- Homecomings rise as you assemble fliers, Dunnock, Stork and the Tern. They are capped by flier slots: each flier must be played and fight once per cycle, so 2–3 flier slots give 2–3 homecomings a turn.
- Tailwind rises with every homecoming, so it is the running count of the flock's trips. Goose doubles it.
- Listeners (Redbreast, the Cuckoo's keeper, the Lump) multiply each homecoming.

Applications growing linearly times a rate growing linearly gives cubic board growth. A cubic curve from round 5 fits the September 2025 Battlegrounds shape closely: T8 123 → T14 1,751, fitted 60 + 2.33·(t−5)³ gives 123 / 351 / 860 / 1,760 at T8/10/12/14 against the real 123 / 305 / 759 / 1,751. Goose's doubling adds the late kick and the tail.

### The rate parameter: **r = Tailwind gained per homecoming**

The lever sweep picks it. Paper model, median ("typical") engine line, combat-start board stats:

| r | R12 typical | R15 typical | R12 strong | R15 strong | Reads as |
|---|---|---|---|---|---|
| 0.5 (every 2nd homecoming) | ~270 | ~890 | ~600 | ~1,440 | Too flat, below target |
| **1 (default)** | **~440** | **~1,600** | **~1,075** | **~2,640** | **September 2025 shape** |
| 2 | ~750 | ~3,000 | ~2,000 | ~4,400 | Nov 2026 steepness |

Secondary levers, in the order I'd sweep them:
1. **Goose's multiplier:** ×1.5 / ×2 (golden ×3). With Goose at ×1, the typical R15 board drops from ~1,600 to ~1,100, so she drives about a third of the late game and most of the tail.
2. **Egg fraction:** ½ or ¾ of the away Bird. This is the tempo cost of investing, and the clock of the "behind at once" window.
3. **Redbreast's share:** gains X or half of X per homecoming. This sets carry concentration (now 0.35–0.55 of the board).

### The turn it comes online

**Round 8** (tier 4, Mrs Stork, with Redbreast and 3–4 fliers cycling). Tailwind is about 7–11 by then and Redbreast gains 15–30 a turn. A highroll is online at R6–7 (early Stork, golden Redbreast); a lowroll at R10.
- **Behind at once** (R3–R7): 1–2 Birds away as half Eggs, about 10–20% under a tempo board.
- **Level** by R9–10.
- **Clearly ahead** from R11–12 in strong games. Birds run a late clock. The median engine game is level at R12 and on the target at R15.

### The decision it creates, every turn

**Who flies today, and who holds the Nest?**
- **Fly (invest):**
  - the Bird misses two fights as a half Egg;
  - it comes back +X;
  - Redbreast and the Nest's keeper gain X;
  - Tailwind rises for the rest of the game.
- **Stay (tempo):** keep the body for a fight you need to win.

Inputs each turn:
- the scouted next opponent;
- your Health;
- whether Stork's next 6 gold will bring the right Bird home (she takes the Bird away longest, so the order you fly in is a plan);
- which slots become Nests (beside Dunnock or Redwing, under the Lump).

Gold asks a second question: buy another flier (more homecomings later), a stayer (a body now), or tier up. With Stork on board, every 6 gold spent on any of these is also a homecoming.

---

## The 16 cards

Tier spread kept at 3/3/3/3/2/2. Every creature, name and portrait is kept (Barn Owl stays out of the pool). Seven fly: Swallow, Chiffchaff, Redwing, Jay, Jack Daw, Tern, Goose. Nine stay: Dunnock, Redbreast, Tom Tit, Cuckoo, Mag Pye, Stork, Lump, Ratchet, Whistlers.

Payoff numbers are for a **typical engine board**, with Tailwind about 7 / 14 / 45 and about 2 / 2.5 / 2.5 homecomings a turn at R9 / R12 / R15 (paper model, r = 1). "Enemy carry" means the biggest enemy unit at the target shape: about 25/25 at R9, 100/100 at R12 and 300/300 at R15.

### Tier 1

**One Swallow**: T1, 1/2. *Kept.*
- **Text:** Fly South. When played: get 1 gold.
- **Golden (2/4):** Fly South. When played: get 2 gold.
- **Condition:** played, which includes every replay after a homecoming.
- **Payoff:** 1 gold a play (about 5 by R15), and its own trips. Body ~8/8 at R9, ~25/25 at R12, ~90/90 at R15.
- **Permanence:** gold now; the body's growth is permanent.
- **Enabler:** Mrs Stork (gold becomes homecomings), Redbreast and the Tailwind (each trip is a homecoming).
- **Concentrates:** no.

**Chiffchaff**: T1, 1/2. *Changed: gains the Tailwind when played.*
- **Text:** Fly South. When played: this gains the Tailwind.
- **Golden (2/4):** Fly South. When played: this gains the Tailwind twice.
- **Condition:** played, which includes every replay.
- **Payoff:** it plays as a 2/3 on turn 1, then gains X twice a cycle (homecoming and replay). ~20/20 at R9, ~60/60 at R12, ~200/200 at R15: the biggest flier.
- **Permanence:** permanent.
- **Enabler:** the Lump, the Ratchet and Redwing (it's the Bird worth expressing); Redbreast.
- **Concentrates:** partly. It's the flier-carry the Lump and the Ratchet show at full.

**Mrs Dunnock**: T1, 2/3. *Kept text; golden changed.*
- **Text:** End of Turn: a Bird whose Nest is beside this comes home a turn sooner.
- **Golden (4/6):** End of Turn: two Birds whose Nests are beside this come home a turn sooner.
- **Details:** never sooner than next turn.
- **Condition:** a Nest beside her at End of Turn.
- **Payoff:** about +0.5 homecomings a turn, worth about X stats a turn spread over the Bird, Redbreast and the wind: ~7 at R9, ~15–25 at R12, ~45–75 at R15. A 2/3 body on turn 1.
- **Permanence:** tempo, turned into permanent growth.
- **Enabler:** Goose (sooner doublings), the Tern (a sooner flock call), every flier.
- **Concentrates:** no.

### Tier 2

**Mr Redbreast**: T2, 2/4. *Changed: the carry.* Robin, Who Stays.
- **Text:** After a Bird comes home: this gains the Tailwind too.
- **Golden (4/8):** After a Bird comes home: this gains the Tailwind twice.
- **Condition:** any Bird of yours coming home, by any route. He never flies.
- **Payoff:**

  | Round | Typical | Strong |
  |---|---|---|
  | R5 | 4/6 | |
  | R9 | ~25/27 | ~58/60 |
  | R12 | ~85/85 | 150–290 |
  | R15 | ~330/330 | ~460/460 |

- **Permanence:** permanent and visible.
- **Enabler:** Tom Tit (his Shield) and the Cuckoo (he can keep a Nest and gain twice). Every flier, Stork, Dunnock and the Tern feed him.
- **Concentrates:** **yes.** He holds 0.35–0.55 of the board in the model.

**Redwing**: T2, 2/4. *Kept text; golden changed.*
- **Text:** Fly South. Eggs beside this have their Bird's full stats.
- **Golden (4/8):** Fly South. Eggs next to this have their Bird's full stats.
- **Condition:** Redwing is home, with empty Nests beside it (golden: next to it).
- **Payoff:** up to two Eggs fight at full instead of half: about +18 fight stats at R9, +50 at R12, +150 at R15.
- **Permanence:** fight-only, but shown on the Nest's Egg readout.
- **Enabler:** lowers the cost of investing. Chiffchaff and Goose Eggs are the big ones.
- **Concentrates:** no.
- **Note:** fly it in the turns you don't need the cover.

**Mrs Jay**: T2, 3/3. *Kept.*
- **Text:** Fly South. When sold: get an Acorn.
- **Golden (6/6):** Fly South. When sold: get two Acorns.
- **Condition:** flown, or sold for good.
- **Payoff:** an Acorn a trip (about 4 by R12). Body ~8/8 at R9, ~20/20 at R12, ~50/50 at R15. The tier's biggest body for early tempo.
- **Permanence:** gold now; the body's growth is permanent.
- **Enabler:** Stork (gold); Hedgerow's Acorn payoffs if splashed (Dozey, Pym, Beadle).
- **Concentrates:** no.

### Tier 3

**Tom Tit**: T3, 3/4. *Changed: guards the carry instead of the Eggs.* Blue tits mob anything bigger than them.
- **Text:** Start of Combat: give your biggest Bird Shield.
- **Golden (6/8):** Start of Combat: give your two biggest Birds Shield.
- **Condition:** a Bird on board; it picks the biggest at Start of Combat.
- **Payoff:** blocks one enemy hit on the carry: ~15–25 damage at R9, 60–120 at R12, 200–400 at R15. The audit's model scores a shield at about +13 win-rate points.
- **Permanence:** fight-only.
- **Enabler:** Mr Redbreast, Chiffchaff and the Lump (any carry). It makes concentration safe.
- **Concentrates:** it protects a concentrated unit.

**Jack Daw**: T3, 3/3. *Changed: proportional, aimed at the biggest.*
- **Text:** Fly South. Start of Combat: steal a quarter of the biggest enemy's Attack.
- **Golden (6/6):** Fly South. Start of Combat: steal half of the biggest enemy's Attack.
- **Details:** any row. Lasts the fight. Rounded down.
- **Condition:** Jack Daw is home (an Egg has no text).
- **Payoff:**
  - R9: steals ~6, a 12-point swing.
  - R12: ~25, about 50.
  - R15: ~80, about 160.
  - His body grows as a flier (~15/15 at R12).
- **Permanence:** fight-only.
- **Enabler:** none. It's an answer.
- **Concentrates:** no. It cuts the enemy's concentration.
- **Decision:** keep him home against a carry, or fly him for the wind.

**Old Tern**: T3, 3/4. *Kept.*
- **Text:** Fly South for 3 turns. When this comes home: your other Birds away come home too.
- **Golden (6/8):** Fly South for 1 turn. When this comes home: your other Birds away come home too.
- **Condition:** its trip ends, or Stork or Dunnock brings it back, with others away.
- **Payoff:** a burst of 3–5 homecomings at once.
  - **R9** (Tailwind 7): Redbreast +~35/+35, every Bird +7 or more, Tailwind +4.
  - **R12:** Redbreast +~80/+80.
  - **R15:** Redbreast +~200/+200.
  - Every replay text fires again.
- **Permanence:** permanent growth.
- **Enabler:** Redbreast, the Cuckoo, Chiffchaff, Swallow. It's best with Stork, who can bring the Tern home early.
- **Concentrates:** feeds Redbreast in bursts.

### Tier 4

**The Cuckoo**: T4, 3/6. *Changed: pays whoever kept the Nest.* She leaves her children with others, and pays them.
- **Text:** After a Bird comes home: the unit that held its Nest gains the Tailwind too.
- **Golden (6/12):** After a Bird comes home: the unit that held its Nest gains the Tailwind twice.
- **Details:** the unit standing on that Nest's slot when the Bird comes home. Eggs don't count. Any unit can hold a Nest.
- **Condition:** a unit on a Nest when its Bird lands.
- **Payoff:** stayers grow too. Keepers gain about +7–14 a turn at R9, +14–28 at R12 and +45–90 at R15. Two keepers reach ~50/50 by R12 and ~100/100 by R15.
- **Permanence:** permanent.
- **Enabler:** the Lump (the ideal keeper), Redbreast on a Nest (gains twice), Stork and Tom Tit as keepers.
- **Concentrates:** no. This is the **flock route's** engine and spreads the growth.

**Mag Pye**: T4, 3/6. *Kept.*
- **Text:** Start of Combat: steal the text of the enemy across.
- **Golden (6/12):** Start of Combat: steal the text of the enemy across and the next one along.
- **Details:** first of all Start of Combat effects. A Belly isn't text.
- **Condition:** a scouted engine across. Move her after scouting.
- **Payoff:** answers a card, not a stat line. She takes Squire Lollop's +2/+2 to all, the Lantern Man's Attack aura, a Committee or the enemy's Shield-giver. Worth nothing against plain bodies.
- **Permanence:** fight-only.
- **Enabler:** none. It's an answer.
- **Concentrates:** no.

**Mrs Stork**: T4, 3/6. *Kept.* The card that brings the engine online.
- **Text:** Every 6 gold you spend: the Bird away longest comes home.
- **Golden (6/12):** Every 6 gold you spend: the two Birds away longest come home.
- **Details:** it must have missed a fight. A tie goes to the leftmost Nest.
- **Condition:** spending gold on anything (units, refreshes, tier-ups, spells), with Birds away.
- **Payoff:** about +1 homecoming a turn (golden +2), with no extra gold needed. Each is worth about 20–25 stats a turn at R9, 40–55 at R12 and 120–150 at R15. That's 4, 8 and 22 stats per gold. It rises the way Battlegrounds' gold value does, a step behind it (2.8 at T8, 9.9 at T10, 28 at T12 in Nov 2026).
- **Permanence:** permanent growth.
- **Enabler:** every flier. Swallow and Jay gold feed her. Flying Goose or the Tern first lets her aim them.
- **Concentrates:** through Redbreast.

### Tier 5

**The Great Lump**: T5, 3/5. *Changed: full stats.* The cuckoo chick.
- **Text:** On a Nest, this also has its Bird's stats.
- **Golden (6/10):** On a Nest, this also has twice its Bird's stats.
- **Details:** loses them when that Bird comes home; then move it to another Nest.
- **Condition:** standing on a Nest whose Bird is away.
- **Payoff:** puts a flier's whole body into the fight and onto the board: +60/+60 on Chiffchaff's Nest at R12, +150–200 at R15. With the Cuckoo it also keeps +X when that Bird lands.
- **Permanence:** a standing aura, visible in recruit and fight; plus permanent Cuckoo gains.
- **Enabler:** Chiffchaff (the biggest flier), the Cuckoo and the Ratchet (if the Lump dies on a Nest, the Bird lands too: the pile counts twice).
- **Concentrates:** yes.

**Mother Goose**: T5, 4/7. *Changed: the doubler.*
- **Text:** Fly South. When this comes home: double your Tailwind.
- **Golden (8/14):** Fly South. When this comes home: triple your Tailwind.
- **Details:** she gains the Tailwind first. *(Why triple, not ×4: the bonus doubles from +100% to +200%. ×4 is a sweep variant.)*
- **Condition:** her trip ends, or Stork or Dunnock brings her home.
- **Payoff:** Tailwind 14 → 28 at R12 and 35 → 70 at R15. Every later homecoming then gives twice as much to the Bird, Redbreast and keepers: about +100 a turn after the R12 doubling and +300 a turn after R15.
- **Permanence:** permanent (the number never falls).
- **Enabler:** every homecoming. She's best with Stork (fly Goose first so she's the Bird away longest) and Dunnock beside her Nest.
- **Concentrates:** multiplies everyone, Redbreast most.

### Tier 6

**The Gabble Ratchet**: T6, 4/8 (was 3/7). *Kept text.* The owner's "both halves of the Bird" payoff.
- **Text:** When a unit on a Nest dies: its Bird lands there.
- **Golden (8/16):** When a unit on a Nest dies: its Bird lands there with twice its Attack.
- **Details:** Eggs count. Once per Nest a fight. It lands at its current stats, and after the fight it's still away, trip unchanged. Landing isn't coming home.
- **Condition:** a unit dies on a Nest: an Egg or a keeper.
- **Payoff:** full-size Birds drop into the fight. At R15, 2–3 Nests of 100–200 Birds give +300–500 fight stats; at R12, about +120.
- **Permanence:** fight-only (a capstone, not the main payoff).
- **Enabler:** Chiffchaff and Goose (big away Birds), the Lump (Lump dies, then the Bird lands), Redwing (front Eggs).
- **Concentrates:** a second wave, spread across Nests.

**The Seven Whistlers**: T6, 5/7. *Changed: the answer at T6.* Six looking for the seventh.
- **Text:** Start of Combat: halve the Attack and Health of the biggest enemy.
- **Golden (10/14):** Start of Combat: halve the Attack and Health of the two biggest enemies.
- **Details:** any row. The enemy keeps half, rounded up. Each Whistlers picks the biggest at that moment.
- **Condition:** none.
- **Payoff:** removes about −100/−100 from an R12 carry and −300/−300 at R15. It's the tribe's scam.
- **Permanence:** fight-only.
- **Enabler:** none. It's an answer, and it lets the flock route beat single carries.
- **Concentrates:** no. It breaks the enemy's concentration.

### Wording check

Card text runs 7–16 words, median 10, against the guide's median of 11 and maximum of 22. New terms:
- **Tailwind:** on 5 cards plus Fly South.
- **Biggest:** on 3 cards.
- **Shield:** comes from Track B.

---

## The tribe

### Carry route: "The Robin Who Stays"
- **Pieces:** Mr Redbreast (two copies for the triple), the fliers, Dunnock, Stork, the Tern, Tom Tit, Goose.
- **Placement:** Redbreast sits in B2, behind the fliers, Eggs and keepers, with Tom Tit's Shield. He's the carry at 0.35–0.55 of the board.
- **The highroll:** a golden Redbreast by R6–8, which gains 2X a homecoming.

### Non-carry route: "The Cuckoo's Nest" (the flock)
- **Pieces:** the Cuckoo, the Lump, Goose, the Ratchet and the Whistlers, with no Redbreast focus.
- **How it grows:** each homecoming feeds the Bird and its keeper. The board becomes five or six units at 60–200 each by R15, and the Ratchet adds a second wave.
- **Why it works:** under our rules even, big boards beat one carry (`fundamentals.md` §1.6). The Whistlers halve the carry it meets.
- **The two routes share every enabler.** The shop decides the lean, and they mix: Redbreast is fine on a Cuckoo board. This replaces pass 2's Homecoming and Hatchery, which pulled the same Nests opposite ways.

### Answers to other tribes' carries
| Card | Reaches | Size |
|---|---|---|
| Jack Daw | Biggest enemy, any row | −¼ Attack (golden ½) |
| The Seven Whistlers | Biggest enemy, any row | −½ Attack and Health (golden: two enemies) |
| Mag Pye | The enemy across | Its text |
| Tom Tit (defence, not an answer) | Our own carry | Shield, against one hit from a big enemy |

Two "any row" answers in one tribe uses most of the 2–3 for the whole pool that `fundamentals.md` §4 Q2 suggests, so the synthesis should log it if both stay. Neither destroys, and Jack Daw is away two fights in three if the player flies him. The sweep should check that carries still win often enough; Whistlers on "the enemy across" is the fallback.

### Weak points
- **Tempo, R4–R8.** Birds away are half Eggs. A Bird player who invests early loses 2–3 fights, cheap ones at the current damage table.
- **Answers to the biggest.** Enemy Whistlers or Jack Daw, Changeling (swaps the carry to their side), the Ichneumon Wasp, Hasty Pudding across, Belladonna's Nightshade across. The flock route is the hedge.
- **Wide boards against the carry route.** Overkill is wasted: a 330/330 robin kills one unit an attack.
- **Slot pressure late.** Stayers (Stork, Cuckoo, Lump, T6s) crowd out flier slots, and fewer flier slots means fewer homecomings. The player must choose.
- **Back-row reach.** Ballooning Spider and Swoop units reach the Ratchet and Redbreast.
- **Being read.** Nests and the Tailwind number are public.
- **Pool competition.** A second Bird player takes Redbreasts and Chiffchaffs.

### Two highroll moments a player will remember
1. **"Everyone's home."**
   - **Board:** R10, Tailwind 12, Old Tern and five other Birds away. You spend your 6th gold, and Mrs Stork brings the Tern home early.
   - **Then:** the Tern calls the whole flock back at once. Tailwind climbs 12 → 18, and the robin greets each of them: +12, +13, +14, +15, +16, +17. That's **+87/+87 in one Start of Turn**.
   - **Then:** six bigger Birds in hand, and Chiffchaff gains again as it's played.
2. **"Goose brings the wind."**
   - **Board:** R13, Tailwind 31. Mother Goose lands (+31/+31, wind to 32) and the number on your Bird icon doubles to 64 (golden: 96).
   - **Then:** the same turn Stork's gold brings Chiffchaff home at +64/+64, and Redbreast takes another +64/+64.
   - **Then:** next fight, the enemy kills your front Egg, and the Gabble Ratchet drops a 200/200 Chiffchaff into the gap.

---

## Boards at rounds 6, 9, 12 and 15

The paper model's typical line runs T2 R3–4, T3 R6, T4 R8, T5 R11 and T6 R13. Its R9 dips because it flies everything at once; a sensible policy holds about 110–140. The target column maps Battlegrounds' September 2025 shape onto Bramble's flat start, per the brief.

| Round | Tailwind (typ.) | Typical engine board | Strong engine board | Target median / strong | Biggest unit's share |
|---|---|---|---|---|---|
| 6 | 3–4 | ~50 | ~56 | ~52 / ~60 | 0.25–0.35 |
| 9 | 7–11 | ~110–160 | ~300 | ~150 / ~200 | 0.35–0.45 |
| 12 | 13–41 | ~440 | ~900–1,100 | ~500 / ~700 | 0.35–0.55 |
| 15 | 40–75 | ~1,600 | ~2,600 | ~1,700 / ~2,400 | 0.35–0.45 |

**Typical carry board, round 12** (tier 5, Tailwind 15, Goose still away):

| Slot | Unit | Stats |
|---|---|---|
| F1 | The Great Lump, on Chiffchaff's Nest | 63/65 |
| F2 | One Swallow | 25/26 |
| F3 | Old Tern | 21/22 |
| F4 | Tom Tit, a Cuckoo keeper | 18/19 |
| B1 | Mrs Stork | 15/18 |
| B2 | Mr Redbreast | 85/85 |
| B3 | The Cuckoo | 4/7 |

- **Away:** Chiffchaff 60/60, Mrs Jay 20/20, Mother Goose.
- **Total:** about 470. Redbreast holds 36% and has Tom Tit's Shield.

**Typical board, round 15** (tier 6, Tailwind about 45 after one doubling):

| Slot | Unit | Stats |
|---|---|---|
| F1 | Chiffchaff | 200/200 |
| F2 | Swallow | 93/94 |
| F3 | The Great Lump, on Jay's Nest | 133/135 |
| F4 | Mrs Stork | 48/51 |
| B1 | The Cuckoo | 34/37 |
| B2 | Mr Redbreast | 330/330 |
| B3 | The Gabble Ratchet | 4/8 |

- **Total:** about 1,700. Redbreast holds 39%.

---

## Harness lines

### Line 1: `birds_tempo` (tempo)
- **Engine flag:** off. Committed to Birds.
- **Buy and keep, in order:** mr_redbreast, mrs_jay, mrs_dunnock, chiffchaff, redwing, tom_tit, jack_daw, mag_pye, mrs_stork, cuckoo, mother_goose, great_lump, seven_whistlers, gabble_ratchet, one_swallow, old_tern.
  - **Neutral fill:** turnip_scarecrow, charcoal_burner, whirligig_beetle.
  - **Spells:** harvest_supper (on a Bird), stand_behind_me.
- **Climb:** T2 R2, T3 R4, T4 R6, T5 R8, T6 R10 (Battlegrounds' curve). Buy one unit on climb turns when gold allows.
- **Fly:** only if 6 real units stay on board and the scouted next opponent is under 0.8× our board. Swallow and Chiffchaff go first. Never fly Jack Daw when the next opponent's biggest unit is 2× our median unit.
- **Save:** never. Spend to 0. At T6, spend surplus on refreshes for a Redbreast triple or a Whistlers.

### Line 2: `birds_flyway` (engine and carry)
- **Engine flag:** on.
- **Buy and keep, in order:** mr_redbreast (up to 3 for the triple), chiffchaff (2), one_swallow, mrs_dunnock, old_tern, mrs_stork, tom_tit, mother_goose (2), cuckoo, great_lump, redwing, mrs_jay, gabble_ratchet, seven_whistlers, jack_daw, mag_pye.
  - **Spells:** harvest_supper (Birds), and hiring_fair at T5 or higher with 5+ Birds.
  - **Flock variant knob:** the same list with cuckoo and great_lump moved to the front and only one mr_redbreast.
- **Climb:** T2 R3, T3 R5, T4 R7, T5 R10, T6 R13. That's one turn slower than tempo from T4, so gold buys fliers and Stork steps.
- **Fly:**
  - From R3, each turn fly every flier that has fought once, biggest first, while at least 4 real units stay on board (Eggs extra).
  - Mother Goose is always first. Old Tern goes only when 2+ other Birds are away.
  - Hold every flight in a turn where Health ≤ 12 and the scout shows a stronger board.
- **Place:** Redbreast in B2, the Lump on the biggest away Bird's Nest, Dunnock beside Goose's or the Tern's Nest. Under the Cuckoo, stayers stand on Nests before Eggs do.
- **Save:**
  - No saving before T4.
  - With Stork on board: if her 6-gold count resets each turn, end the turn's spending on a multiple of 6 and carry the rest. If it carries over, spend to 0.
  - From R10, hold 6 gold for a Hiring Fair while no T6 Bird is owned.

Every tribe gets the same knob-tuning budget (plan Track A). The knobs worth tuning here are the fly threshold (4 real units), the Goose-first rule and the climb turns at T4–T5.

---

## Risks, loop guards and what the sweep should test

| Risk | Guard now | Lever if sims show it's common |
|---|---|---|
| Two Geese plus Stork: Tailwind ×4 every 2 turns | Each Goose must fly, miss a fight and land; Stork needs "missed a fight" | Only the first Goose homecoming each turn doubles (a rate limit, not a cap) |
| Golden Redbreast plus Tern bursts: one unit at 60%+ of the board | Tom Tit is the only holder, and the answers above reach him | Golden gains 1.5X; sweep Redbreast at ½X |
| Stork turns all gold into homecomings | Landed Birds can't fly that turn, and she needs Birds away that missed a fight | Every 8 gold |
| Common snowball | Growth comes from homecomings, which are slot- and fight-limited. Winning feeds nothing except Spoils in R1–4 | n/a: report it if sims show it |
| A carry vs. answer arms race (two biggest-enemy answers in one tribe) | Jack Daw flies; Whistlers is T6 | Whistlers on "the enemy across" |
| Late slot squeeze cuts homecomings | It's a real choice | A T5–T6 stayer that is also a keeper |
| Behind-at-once window too deep (R4–R8) | Redwing, Eggs, Dunnock | Egg fraction ¾ |

A rare highroll never fails the tribe (owner, 9d): the two Geese and the golden Redbreast are the intended top 1%.

## Engine support needed

1. **Tailwind:**
   - a per-player tribe counter in the stat layer next to the Supper bonus;
   - it increments by r on each Bird homecoming and is multiplied by Goose;
   - it shows on the Birds icon and in the scout;
   - it goes into snapshots and ghosts.
2. **Fly South homecoming growth:** +X (golden 2X) on landing in hand or on the doorstep, from any return route.
3. **Trigger** "after a friendly Bird comes home", with access to that Bird and to the unit on its Nest slot (Redbreast, the Cuckoo).
4. **Effects:** "gain the Tailwind ×n" (a buff read from the counter) and "multiply Tailwind" (Goose).
5. **Track B pieces:** the "biggest enemy, any row" selector; proportional steal of Attack (Jack Daw); halve Attack and Health (Whistlers); Shield granted at Start of Combat to "your biggest Bird" (Tom Tit).
6. **Parameter changes:** the Lump to factor 1 (golden 2); Redwing's golden reach to `neighbours`; the Ratchet's body to 4/8.
7. **Removed:**
   - Goose's away strikes and +1/+1 homecoming;
   - the Whistlers' homecoming count;
   - Tom Tit's Egg Health aura;
   - the Cuckoo's trip extension and End of Turn growth.

   Rulebook 12.1.4 drops the Tom Tit and Goose sentences, and gains a Tailwind rule (12.1.4b).
8. **UI:**
   - the away tray shows "home in N · +X";
   - an empty Nest shows its Egg and "keeper +X" under the Cuckoo;
   - the Tailwind number pulses when it rises.
9. **Harness:** snapshots log Tailwind, away Birds' stats and homecomings a turn. Line policies need the fly and keep decisions above.

## What changed from pass 2

| Card | Pass 2 | Pass 3 | Why |
|---|---|---|---|
| Chiffchaff | gain +1/+1 when played | gains the Tailwind when played | It scales, and plays as a 2/3 on turn 1 |
| Mr Redbreast | +1/+1 per Nest | gains the Tailwind per homecoming | The carry. He no longer needs Nests to be worth buying |
| Redwing | golden +2/+2 | golden reaches next to | The doubled reach suits big Eggs |
| Tom Tit | Eggs full Health | Shield on your biggest Bird | Carries need a way to hold stats |
| Jack Daw | steal 2 Attack across | steal ¼ of the biggest enemy's Attack | Flat answers fade as stats grow |
| The Cuckoo | longer trips; away Birds +2/+2 | the Nest's keeper gains the Tailwind | Ends the route conflict and makes stayers grow |
| The Great Lump | half the Bird's stats | full | Un-parks the away stats |
| Mother Goose | strikes 2; Birds +1/+1 at home | doubles the Tailwind | The doubler and late compounding |
| The Gabble Ratchet | 3/7 | 4/8 | Body only |
| The Seven Whistlers | −1/−1 across per homecoming, up to −3 | halve the biggest enemy | A real answer at the scale |
| Swallow, Dunnock, Jay, Tern, Mag Pye, Stork | — | kept (Dunnock's golden now names two Birds) | They already do their engine jobs |
