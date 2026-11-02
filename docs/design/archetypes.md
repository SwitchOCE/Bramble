# Strategic archetypes and a first tribe longlist

**Status: draft for the owner to steer, 2 November 2026 (task D1, revision 2).** It answers the owner's ask for "what our strategic archetypes are going to be" and "a couple of proposed tribes and prototypes that we think are just easy wins" ([2026-11-02 note](owner-notes/2026-11-02-pre-development-design-pass.md)), started on the owner's word that "a lot of these choices will link in very heavily with tribe and archetype design" ([2026-11-02c note](owner-notes/2026-11-02c-bounding-fallback-and-stage-2.md)). Two reviews of revision 1 are folded in; what was declined is in the critique notes at the end.

**Revision 3 (2 November): the owner's read-through** ([2026-11-02h note](owner-notes/2026-11-02h-checkpoint-read-through.md)). The owner agrees the archetypes: "I agree with all of those". Read as also settling STICKY as a comp and SCAM and BURST as spices (to confirm). The position-text rule is declined (section 3), every tribe gets an economy angle (4.2), and the top-tribe pick waits for the mechanics (4.3). Where the owner found a tribe idea unclear, it is marked **needs examples**; the tribe redo gives each tribe example cards that play together, a scene from the player's side and analogues.

**What this is not.** No units, no tiers per unit, no numbers. Costing comes later against [power-budget.md](power-budget.md). Units per tier are the next step.

**Tags.** **[data]** comes from a research file, cited. **[judgement]** is my reading. Short names: **SE** [strategy-eras.md](../research/battlegrounds/strategy-eras.md), **OG** [other-games.md](../research/other-games.md), **ET** [effect-taxonomy.md](effect-taxonomy.md) (class IDs E, T, R), **PS** [positioning-sim.md](positioning-sim.md), **RB** [rulebook.md](rulebook.md), **PB** [power-budget.md](power-budget.md), **EB** [economy-bounding.md](economy-bounding.md) §7 guardrails, **Folio** [woodland-folio.html](../folio/woodland-folio.html) page data (seeds, takes, hooks, guide), **MI** [mechanics-ideas.md](mechanics-ideas.md) (entry numbers).

**Keyword names are stand-ins.** Battlegrounds and Galaxy keyword names in this doc (Divine Shield, Reborn, Deathrattle, Battlecry, Venomous, Taunt, Stealth, Windfury, Magnetic, Avenge, Rally, Galaxy's Hunt and so on) name a shape, not an adopted Bramble mechanic. The owner: "None of these are Bramble mechanics. We haven't designed those yet", and they belong in the docs as "illustrations only" ([2026-11-02e note](owner-notes/2026-11-02e-mechanics-are-examples.md)). Rulebook clauses cited for them (RB 8.4.1, 9.8.3, 11.2) say how the stand-in works in the rules draft, not a settled Bramble rule. Tribe signatures that rest on one are marked *placeholder* until Bramble designs its own. Where one fits, section 4.1 names a candidate Bramble mechanic from [mechanics-ideas.md](mechanics-ideas.md) beside the placeholder, by entry number; none is adopted.

---

## 1. The archetypes

### 1.1 Shape, fuel, landing

An archetype is a **shape**: what the board looks like when it wins. Scaling shapes also have a **fuel** (what makes them grow) and a **landing** (where growth goes). The shape is shared; the fuel is the tribe's flavour **[judgement, on OG §3: "The shape recurs; the trigger is the tribe's flavour", and "Scaling has two axes"]**.

Landings: one unit (TALL), the tribe's units on the board (MEDIUM), the tribe "this game" (E12, SE §4.1 #5), a slot (E16, Galaxy's answer, OG §3), or the hand (E17, Murlocs, SE Era F, J).

### 1.2 Five comps and two spices

The owner's four flavours give ECO, WIDE, SCAM, TALL and MEDIUM (scaling split as the owner split it). One more comp recurs across eras: STICKY. SE files its precedents as scaling fuels (Enforcer "SCALE (shield lost)", Mackerel "SCALE (shield)", Undead "SCALE (reborn)"); grouping them as a shape is **[judgement]**, because the way it wins (each body takes two kills) is its own. OG §3's other shapes are handled differently in Bramble **[judgement]**:
- **Before-the-fight burst** (OG shape 7) becomes BURST, a **spice** like SCAM. Battlegrounds never gave it payoffs above Tier 4 (Soul Juggler 3, filed "SCAM-adjacent + WIDE", SE Era B), and the tall and medium boards that late games turn into shrug it off.
- **Protected engine** (OG shape 6) is not a separate archetype here. Every Bramble board already protects its back row: "The 2–3 front shape comes from back-row protection, not from position text" **[data: PS §4.4]**. It is the default geometry that MEDIUM, TALL and ECO use (section 3). No searched layout used a one-front fortress, and the card built for it measured −36% **[data: PS §4.4, §5.2]**.
- **Retrigger and doubling** (OG shape 5) is an enabler (1.3).

**The owner on ECO** ([02h](owner-notes/2026-11-02h-checkpoint-read-through.md)): economy comps "tend to just be the best at high-level play", because they can buy efficient stats, or "use their economy options to play those economy units with another tribe's scaling … and use their best scaling instead of their own". The owner likes "tying economy effects to specific actions that kind of reward you for being in that type of strategy". So a tribe's economy text should pay for that tribe's own actions (Acorns from Hedgerow summons, Forage from Bird refreshes), not give plain gold any board can use.

| ID | Archetype | How it wins | Pieces (ET classes) | Enablers at | Payoffs at | Economy role |
|---|---|---|---|---|---|---|
| **ECO** | Many small actions | Makes more than it spends, then converts late. Weak board meanwhile ("don't give a large amount of stats") | E50 gold, E40/E41 cards, E14/E61 shop-side buffs; E52 free refreshes (within G1); R05–R10 recruit triggers | T1–T4: gold text sits at T1–4 and is 0% at T5–7 now **[data: PB 4.2]** | T5–T6 converters: Tethys 6, Record Smuggler 5, Nomi 5 **[data: SE Era B, F]** | Producer |
| **WIDE** | Deep board, many small units | Bodies outnumber the enemy's attacks; each trade costs the enemy more | E30 summon, R21 Deathrattle, R26 on summon, R25 Avenge, E16 slot buff | T1–T2 token makers: Imprisoner 1, Rat Pack 2, Leapfrogger 2, Forest Rover 2 **[data: SE Era A, B, D, H]** | T4–T7: Macaw 4, Goldrinn 5–6, Mama Bear 6, Kodo 7 **[data: SE Era A, B, G, I]** | Slot user. Tokens sell for 0 (RB 4.3.3) |
| **TALL** | One or two huge units | One carry outgrows everything; the rest feeds or guards it | E23 merge, E08 consume, E02 self gain, E05/E06 set and multiply, E20 keywords on the carry | T1–T3 feeders: Lullabot 1, Volumizers 2, Accord-o-Tron 3 **[data: SE Era F, I]** | T5–T7: Junkbot 5, Myrmidon 5, Beatboxer 6–7, Deity cards 5–7 **[data: SE Era A, E, F, G, J]** | Gold sink into one body; few slots used |
| **MEDIUM** | Many medium units | The tribe grows together, so no single answer beats it | E01 to others, E12 "this game", E10 amplifiers, E09 count-scaled | T2: Warleader, Deathswarmer, Lava Lurker **[data: SE Era A, E, F]** | T6: Kalecgos, Athissa, Charlga, Eliza **[data: SE Era B, C, E]** | Steady spender; needs tribe density |
| **STICKY** | Bodies that each take two kills | Every body takes two kills; the enemy runs out of attacks first | Hit-blocking layers and second lives, and payoffs when one is used. Battlegrounds stand-ins: E20 Divine Shield and Reborn grants, R27 shield lost or Reborn, E80 Deathrattle doublers | T2–T4: Bronze Warden 2, Jelly Belly 3, Drakonid Enforcer 4, Grease Bot 4 **[data: SE Era B, D, F]** | T5–T6: Titus 5, Nadina 6, Holy Mackerel 6 **[data: SE Era B, F]** | Neutral |
| *SCAM* (spice) | Kill something much bigger | One cheap piece removes the enemy's best unit, inside another comp | Kill on hit (stand-in: Venomous, RB 11.2.5), E71 destroy, E05 stat set, E70 transform on an enemy, text-aimed targets | T3–T4: Deadly Spore 3, Toxfin 4 **[data: SE Era A, J]** | T5–T6: Leeroy 5, Maexxna 6, Tyrael 6 **[data: SE Era A, E, J]** | Cheap. "Always present and always small", 2–7 cards an era **[data: SE §4.1 #7]** |
| *BURST* (spice) | Damage before or during attacks | Pings strip shields and tokens; rides WIDE ("each death deals damage") | R20 Start of Combat, E72 damage, R21/R25 death damage | T2–T3: Soul Juggler 3 **[data: SE Era B]**; prototypes Acorn Slinger 2, Spotter Rook 3, Rot Toad 3 **[data: PS §5.1]** | None above T4 in Battlegrounds **[data: SE §2]**. Late, it scales only through WIDE's death count **[judgement]** | Cheap tempo |

### 1.3 Enablers, not archetypes [judgement]

- **Retriggers and doublers** (E80, E81: Brann, Titus). They serve every shape and are the main loop risk (OG §3 shape 5; G1, EB G5–G6). Few, neutral or tribe-locked.
- **Global counters** (E12). A landing, not a shape: 1% → 16–18% of the pool **[data: SE §4.1 #5]**.
- **Golden and triple chasing** (R16: Goldgrubber, Extortionist, Tony Two-Tusk; the Pirates' golden line **[data: SE Era B, D, J; SE §3]**). A fuel any tribe can print; no tribe owns it yet.
- **Cleave and Trample** (RB 11.2.7; the owner's "overkill damage splashing through", [10-27b note](owner-notes/2026-10-27b-board-answers-and-research.md)). The main answer to WIDE and STICKY. Proposed home: Trample on Great beasts, Cleave neutral, so a lobby without Great beasts still has it.

### 1.4 Matchups, rows and precedent

| ID | Where it lives (section 3) | Strong against | Weak against | Battlegrounds tribes and eras |
|---|---|---|---|---|
| **ECO** | Recruit text on back units; bodies don't matter | Nobody in a fight; wins late | Tempo, but Bramble's damage cap (5 a fight on turns 1–3, 10 on 4–7, RB 10.1.4) and uncapped carry-over (RB 4.1.2–4.1.3) blunt it; "the damage caps … make losses cheap" **[data: ET E55]**. Pool contention. ECO may lack a real counter (question 8) | Pirates every era since 2020; Elementals' refresh line; Demons' Health and shop; Naga card generation **[data: SE §3, §4.2]** |
| **WIDE** | Front. A Deathrattle summon refills its own slot (RB 8.4.1) | TALL without Trample (one attack kills one token, RB 9.4.3), STICKY (many hits strip shields), SCAM (a kill wasted on a token) | MEDIUM (each medium body trades up), BURST, Cleave and Trample | Beasts every era; Deathrattle Mechs (A) **[data: SE §3, §4.1 #2]** |
| **TALL** | Front carry (attacks first and often) or back carry fed by front deaths | MEDIUM, BURST | WIDE, STICKY, SCAM | Mechs (A, F–J), Demons (A, D), Quilboar Knight (C), Myrmidon (E), Deity (J) **[data: SE §4.1 #3]** |
| **MEDIUM** | Back auras on the front (95–119% realised **[data: PS §1; ET §1 #6]**) plus front units with timing text | WIDE, SCAM, BURST | TALL | Murlocs (A), Dragons (B, E), Eliza Pirates (B), Naga (E), Undead (F), Quilboar (C, I) **[data: SE §2]** |
| **STICKY** | Front: a blocked hit or a second life is worth most where units are hit; a second life that returns to its slot stays there (stand-in: Reborn, RB 9.8.3) | TALL (Divine Shield is worth 0.9 × enemy Attack **[data: ET E20]**), SCAM (a blocked hit stops a kill on hit; stand-in: shield blocks Venomous, RB 11.2.2) | WIDE, BURST (Soul Juggler "extremely favored" against Divine Shield **[data: SE Era B]**), Cleave | Mech and Dragon shields (A, B, D), Mackerel (B), Undead Reborn (F, J) **[data: SE §2]** |
| *SCAM* | Text-aimed ("the highest-Attack enemy"), so it works from either row | TALL | STICKY, WIDE, MEDIUM (no single key unit) | Murlocs, the longest line; neutral Maexxna, Zapp, Leeroy, Tyrael **[data: SE §3, §4.1 #7]** |
| *BURST* | Either row; random effects ignore rows (RB 9.5.6) | WIDE, STICKY | TALL, MEDIUM | Juggler Demons (B) **[data: SE Era B]**; Red Whelp in the Dragon line **[data: SE §3]** |

"Strong / weak" entries are **[judgement]** except where tagged: design intent, to be tested when units exist.

### 1.5 Scaling fuel

The owner's triggers plus the ones the era study shows. Risk is the no-timer risk from ET §5. Owner is the tribe in section 4.

| Fuel | ET trigger | Battlegrounds line | Risk | Owner |
|---|---|---|---|---|
| When they die | R21, R25 | Beasts, Undead **[data: SE §3]** | L | Hunters (glutton), Oozes (split) |
| Summon (any) | R26 | Mama Bear, Banana Slamma, Octosari, Kodo **[data: SE Era A, F, I]** | L | Hedgerow folk |
| Summon that can't fit | R26 + full board | none in SE | L, with a per-combat cap | Hedgerow folk |
| Battlecry played or triggered | R01, R04 | Murlocs, Dragons **[data: SE §3]** | L–M | Bog folk |
| Spell played / cast on this | R07, R08 | Naga, Quilboar **[data: SE §3]** | H | Fairies |
| Merge (the owner's "magnetize") | R13 | Mechs **[data: SE §3]** | M | Oozes |
| Shield lost, Reborn | R27 | Enforcer, Grease Bot, Jelly Belly **[data: SE Era B, D, F]** | L | Bog folk, Great beasts |
| Start of Combat self-growth | R20 | Myrmidon **[data: SE Era E]** | L | Great beasts |
| Card gained | R14 | Peggy **[data: SE Era D]** | H | Hedgerow folk (Acorns gained) |
| Golden played | R16 | Goldgrubber, Extortionist **[data: SE Era B, J]** | L | unassigned (1.3) |
| Sell | R06 | Ballers **[data: SE Era H]** | H | Hedgerow folk (hamsters) |
| Refresh | R10 | Elementals **[data: SE Era I]** | H, bounded by the refresh steps **[data: ET §1 #3]** | Birds |
| Attack (Rally) | R22 | Eliza, Rally Dragons and Beasts **[data: SE Era B, H, J]** | L | Hunters (wolves) |
| Kill | R23 | 1 Battlegrounds minion, 40 Galaxy characters **[data: ET §5]** | L | Hunters |
| End of turn | R03 | Dragons **[data: SE Era E]** | L | Greenwood, Birds (nests) |
| Survived the fight | R28-like | none | L | Hive |
| Gold spent | R09 | Pirates (Tethys, Rogers) **[data: SE §4.2]** | **H**, outside the fallback (1.6) | none in this list |
| Hero Health spent | E55, R29 | Demons **[data: SE §4.1 #1]** | M, outside the fallback (1.6) | none in this list |

### 1.6 What the bounding fallback doesn't cover

The owner's fallback is rising refresh cost plus no infinite free refreshes, and "how long and how ambitious our economy effects go, we can determine later" ([11-02c note](owner-notes/2026-11-02c-bounding-fallback-and-stage-2.md)). On 2 Nov the owner set both halves ([11-02d note](owner-notes/2026-11-02d-refresh-schedule-and-free-refreshes.md)):
- **The paid refresh price is the primary guardrail.** 1 gold for refreshes 1–15 of a turn, then +1 gold every 5 (16–20 cost 2, 21–25 cost 3, and so on), with no cap (RB 4.4). The owner: "Our primary guardrail against infinites is our refresh system".
- **G1 covers every refresh the player doesn't pay for**, effect refreshes included, in the owner's wording in [content-guardrails.md](content-guardrails.md): an endless chain must be "mathematically impossible", and "A rare card that gives a few is fine".
- **No guardrail on gold back.** The owner declined one for cards that give back 1 gold or more per gold spent: "I think that we do not need that guardrail whatsoever", and "It should be okay if a rare unit does that".

**Loops the refresh price doesn't stop.** A note, not limits: the owner cut the limits proposed here ("Yes, cut them", [11-02g note](owner-notes/2026-11-02g-stage-2-checkpoint-scope.md)). The detail is in [economy-bounding.md](economy-bounding.md) **[data]**:
- **Gold-spent engines.** "If r reaches 1, the loop is infinite at any price" (ET §7.2); r ≥ 1 stays unbounded under the owner's schedule (EB, "The owner's schedule"). No tribe in section 4 carries one as its engine.
- **Effect refreshes per action.** Golganneth's Tempest + Hoggarr + golden Rogers runs unbounded under every schedule, the owner's included, since the shop refreshes after each buy at no price (EB, "The owner's schedule"; §1 #3, §3.9). G1 (decided) covers these.
- **Health as gold.** Kathra'natir made the hero Immune, "so health-costing Demons play for free" (SE Era D). No tribe in section 4 carries a Health economy.
- **Loops the player drives.** RB 9.10.2's per-action trigger limit doesn't catch them (EB §7 delta 7).

---

## 2. How archetypes link

### 2.1 Pairs that combine across tribes

| Pair | Why it works | Precedent | Longlist example |
|---|---|---|---|
| ECO → any scaling | Economy buys scaling pieces sooner | Gold Pirates into SCALE **[data: SE Era F]** | Hedgerow folk or Birds feeding Fairies or Oozes |
| WIDE → TALL | Deaths and summons feed one carry | Junkbot **[data: SE Era A]** | Hedgerow tokens dying in front of a Hunters glutton |
| WIDE → MEDIUM | Each summon buffs the team | Mama Bear **[data: SE Era A]** | Hedgerow tokens with the Bog folk chorus |
| WIDE + BURST | Each death deals damage | Soul Juggler **[data: SE Era B]** | Greenwood saplings with Bog folk Rot Toads |
| TALL + STICKY | A shielded carry needs two kills | Bristleback Knight **[data: SE Era C]** | Ooze amalgam with Great beasts' hide grants |
| TALL + SCAM | The carry wins most fights; scam removes the other carry | Hatespawn on a tall body **[data: SE Era G]** | Great beasts with a Fairy curse |
| MEDIUM + STICKY | Grown bodies that each take two kills | Mackerel Murlocs **[data: SE Era B]** | Bog folk with Lights' decoys |
| MEDIUM + ECO | Shop-side growth makes every buy bigger | Nomi **[data: SE Era B]** | Hive colony with Birds' forage |

### 2.2 Counter map

Comps only: row against column, **+** the row is favoured, **−** unfavoured, **·** even. All **[judgement]**.

| | WIDE | TALL | MEDIUM | STICKY |
|---|---|---|---|---|
| **WIDE** | | + (− against Trample) | − | + |
| **TALL** | − (+ with Trample) | | + | − |
| **MEDIUM** | + | − | | · |
| **STICKY** | − | + | · | |

What answers each, so every archetype has a counter:

| Archetype | Countered by |
|---|---|
| ECO | Tempo and pool contention, both weak in Bramble (1.4, question 8) |
| WIDE | MEDIUM; BURST; Trample and Cleave |
| TALL | WIDE; STICKY; SCAM |
| MEDIUM | TALL |
| STICKY | WIDE; BURST; Cleave |
| SCAM | STICKY (shields), WIDE (tokens) |
| BURST | TALL, MEDIUM (bodies too big) |

The four comps form a loop: WIDE beats TALL, TALL beats MEDIUM, MEDIUM beats WIDE, STICKY beats TALL and loses to WIDE. With 5 tribes a lobby (RB 5.2.4), a counter carried by one tribe is often missing, so each counter in this table has two or more carriers in section 5, or is neutral (Cleave).

---

## 3. Rows and archetypes

What the sim says **[data: PS §1, §4.4, §5.2, §6, §7; ET §1 #6]**:
- Back-to-front static text realises 95–119% of nominal. Front-to-back static text realises 0–7%: don't print it.
- Timing-based front-to-back text works: Start of Combat (Badger), Deathrattle (Hedgehog), "whenever this attacks" (Drummer Hare).
- Buffs that land on back units are under-priced (Vole's text 4.3 SP against 2.7; Hedgehog's 3.6 against 2.5). A back carry is the shape most likely to run over budget.
- "6 of the 11 prototypes want the 3 back slots", and it is "frustrating if one tribe's whole engine wants the back".
- Moving units in the Recruit Phase is free and unlimited (RB 8.3.3).

Rules this list follows **[judgement]**:
1. **Every archetype and tribe has front-bound payoffs.** No one comp needs more than 3 back slots.
2. **Recruit Phase position text may read positions when it is cast or played.** The proposed rule limiting it to End of Turn, Start of Combat or surviving the fight is declined (question 16). The owner: "give to the units in front of the Fairy" is "quite a good design … because it's not reductive"; choosing which units to buff is a placement puzzle, and "Figuring out what your best unit is is sometimes not easy" ([02h](owner-notes/2026-11-02h-checkpoint-read-through.md)). End-of-turn text such as Nest Robin's stays one option among several.
3. **Scam targets by text** ("the highest-Attack enemy"), not by "across from". In async play "in practice it is a random 3 damage" **[data: PS §5.1]**, unless the player sees the snapshot (question 6; OG §5 question 1).
4. **The back row stays mostly protected.** Back-row reach has two owners (Birds' Swoop, Great beasts' Trample) plus random effects (RB 9.5.6). Text-aimed scam also ignores rows, which is one more reason to keep it small (question 9).

| Archetype | Back-bound text | Front-bound text | Prototype (PS §5.1) |
|---|---|---|---|
| ECO | "End of Turn: if this is in the back row…"; income if this survived the fight | Few: ECO bodies are weak | Nest Robin |
| WIDE | "After a unit in front of this dies, summon into its slot" | Deathrattle refills its own slot (8.4.1); "summon into the slot in front of this" | Sapling Keeper, Puffball Ooze |
| TALL | A carry that grows when the units in front die (watch the budget) | A front carry with Start of Combat growth or Trample | Vigil Vole (back) |
| MEDIUM | Auras on the units in front | "Whenever this attacks, give the units behind this…"; Start of Combat buffs to the units behind | Lantern Moth, Drummer Hare, Hearthguard Badger |
| STICKY | Hit-blocking layers given to the units in front | A second life returning to its slot (Reborn-like); decoys in empty front slots | Fern Hare (Reborn) |
| *SCAM* | Any slot: aimed by text | Any slot | none fits (Acorn Slinger aims by slot) |
| *BURST* | "Whenever a unit in front of this attacks, deal 1 damage" | Deathrattle damage | Spotter Rook, Rot Toad |

How many units carry position text is parked for tribe design (owner, [11-02b note](owner-notes/2026-11-02b-compute-and-rows-sim.md): "In tribe design"). PS §6 proposes about a third. Section 4 gives each tribe a lean; question 11 asks for the share.

---

## 4. First tribe longlist

**This section is the starting draft for the tribe step** (owner, [11-02g note](owner-notes/2026-11-02g-stage-2-checkpoint-scope.md): "Draft for the tribe step"). At this checkpoint the owner picks only the top tribes; the rest is settled at the tribe step's checkpoint.

Ten broad creature kinds, species as flavour inside each. The owner chose "Broad creature kind" from Claude's offered options; the example list "rodents, birds, fairies, oozes" was Claude's option text, not the owner's ([11-02 note](owner-notes/2026-11-02-pre-development-design-pass.md), editor notes). The owner named fairies and oozes, and wants "a smaller number of the woodland things" ([10-27 note](owner-notes/2026-10-27-battlegrounds-direction.md) §6). Four of the ten are magical; two of those, Greenwood and Lights, are new magic kinds the owner hasn't asked for (question 2). Animal ideas come from the Folio; they are ideas, not a roster. Each species sits in one tribe. **[judgement throughout, with sources named]**

### 4.1 Identity and mechanic

| # | Tribe (species) | Identity, and its Folio flavour | Archetypes | Signature mechanic idea |
|---|---|---|---|---|
| 1 | **Fairies** (pixies, sprites, brownies, changelings) | Tricksters who bend the board's rules. Fairy rings, changelings, curses: folklore **[judgement]** | MEDIUM, SCAM | **Fairy ring:** a slot enchantment (E16) that buffs whoever stands on it at Start of Combat; spells grow the ring. **Changeling:** "Start of Combat: become a copy of the unit behind this" (a front copy of your back carry, timing-based). **Curse:** debuff an enemy unit, the owner's preferred shape ("curses that debuff enemy units is perhaps a better outcome", 02h); turning the highest-Attack enemy into a Frog (E70) stays one option |
| 2 | **Oozes** (slimes, jellies, puddings) | Shapeless, loud, "ludicrous high-pitched voices" (owner, 10-27 §6) | TALL, WIDE | **Amalgamate:** play an Ooze onto another to merge (the owner's "amalgamation mechanic"; E23, R13). **Linked:** an Ooze shares damage with the Oozes in front of and behind it (Folio hook "Linking", given to Oozes). **Split:** on death, become smaller Oozes (*placeholder:* Battlegrounds' Deathrattle; candidate: Bud, MI 30, which splits when it survives damage) |
| 3 | **Hedgerow folk** (mice, voles, shrews, hedgehogs, moles, rabbits, red squirrels, dormice, hamsters, rats) | Many small hands that hoard. Parish Council in permanent session; the Rat King committee (Folio seeds) | WIDE, ECO | **Acorns:** a stat currency in hand, played onto units (Blood Gems' shape, SE Era C). A summon with no room becomes an Acorn, a set number of times per combat. Hamsters' cheek pouches: selling drops Acorns (Folio hook) |
| 4 | **Hunters** (foxes, wolves, stoats, weasels, pine martens, badgers, otters, wolverines) | The woodland's small carnivores. Reynard's lawyers, Gubbio wolves "in hi-vis trying their best", the Ermine Court (Folio) | SCAM, TALL | **Hunt:** on-kill triggers (R23; on 40 Galaxy characters and 1 Battlegrounds minion **[data: ET §5]**; *placeholder:* Galaxy's Hunt; candidate: Gorge, MI 26). **Devour:** the glutton (Folio seed "The Gluttons") gains a fixed amount per death, not the dead unit's stats. No per-combat cap (owner, 02h: "I don't necessarily think you need something that's capped per combat"). Wolves' Pack: triggers when this attacks (R22; *placeholder:* Battlegrounds' Rally; candidate: Swarm, MI 25, a joint attack written for bees) |
| 5 | **Birds** (corvids, owls, robins, wrens, herons, puffins, storks, capercaillie) | The sky above the line. Rook parliaments that "punish the strongest enemy"; the Stork Post (Folio) | ECO, MEDIUM, SCAM | **Swoop:** attacks the enemy back row while its front lives (RB 11.5.3; "every game with a protected row has a way in" **[data: OG §4 #2]**). Swoopers sit in front and attack early. **Nest:** "End of Turn: give the units in front of this +Health permanently" (Nest Robin) is the late plan |
| 6 | **Bog folk** (frogs, toads, newts, salamanders) | A swamp opera "where every frog claims to be a cursed prince" (Folio seed "The Frog Chorus") | MEDIUM, STICKY | **Chorus:** each Bog folk played sings, buffing the others (on-play fuel; *placeholder:* Battlegrounds' Battlecry; candidate: Rehearse, MI 59, a chorus that grows in hand and debuts together). Newts regrow (Folio hook "Revive once with fewer stats"; *placeholder:* Battlegrounds' Reborn; candidate: Play Dead, MI 28). Bramble-only hook: "One 'prince' may be real" (Folio): a Fairy spell or curse on a Frog can wake the prince |
| 7 | **Great beasts** (bears, boars, bison, red deer, ibex) | The old kings of the forest: few, huge, slow. The Bison Elders; the Bathhouse Veterans (Folio) | TALL, STICKY | **Trample:** damage beyond a kill carries to the enemy behind (the owner's overkill idea, 10-27b). Front carries that grow at Start of Combat (Myrmidon's fuel). **Hide:** a hit-blocking layer for big bodies (Bristleback Knight's shape; *placeholder:* Battlegrounds' Divine Shield; candidates: Shrug, MI 3, written for bison, or Hunker, MI 1). The answer to WIDE |
| 8 | **Hive** (honeybees, bumblebees, ants) | A colony that thinks as one. Thrift against festival (Folio seed "The Hive and the Carnival") | ECO, MEDIUM, BURST | **Colony:** one "this game" counter every Hive unit reads (E12). **Aphids:** income at start of turn if the aphid survived the last fight, so back-row protection pays (Folio hook: ant). Bees sting and die (Folio hook: honeybee) |
| 9 | **Greenwood** (saplings, oaklings, mosses, fungi, treefolk) | Living wood that grows if left alone. The jay "plants thousands of acorns" (Folio hook) | TALL, WIDE | **Rooted:** "End of Turn: if this didn't move this turn, gain…" Moving resets the growth, so the free move gets a cost. Staying put alone is "boring" (owner, 02h); Rooted also asks for an action, such as fertilising it or a rainfall spell, so tending the tree is the play. **Saplings** refill emptied front slots (Sapling Keeper). Fungi spores: debuffs on death (E15; *placeholder:* Battlegrounds' Deathrattle) |
| 10 | **Lights** (will-o'-wisps, marsh lights, moths) | False lights that lure and misdirect. Folio hook "Moth, will-o'-wisp: Decoys that misdirect attacks"; the Wreckers' false lights | STICKY, BURST | **Lure:** decoy lights fill empty front slots and draw attacks (*placeholder:* Battlegrounds' Taunt; candidate: Thicket, MI 21). **Misdirect:** the first attack each combat on the unit in front of this hits another enemy. Lights flare at Start of Combat |

**Callings, not tribes [judgement].** Lifestyle groups such as burrowers cross creature kinds (badgers are mustelids, moles and rabbits are hedgerow folk). Under RB 5.2.1 they fit as a calling on the type line, like the owner's "owl scholar" or "squirrel farmer" (10-27 §5): "Mole Digger", "Badger Digger". A **Digger** calling could carry **Tunnel** (E32, moving units in combat; "No Battlegrounds or Galaxy card moves units between slots" **[data: ET §1 #5]**, though SAP's Guard pets "jump in front of friends" **[data: OG §1.1]**). For readability, Tunnel moves only into an empty slot, once per combat (question 12).

### 4.2 Economy, rows and what it shares

Each tribe gets its own kind of economy, not the same gold: that is how Battlegrounds reached "everybody has them" **[data: SE §4.3]**. Amounts wait for costing. The risk column gives the no-timer risk; guardrails named there are information, and only G1 is decided (EB §7).

| # | Tribe | Economy angle | Risk (ET §7, EB §7) | Rows lean, position-text share | Takes from Battlegrounds / shares with |
|---|---|---|---|---|---|
| 1 | Fairies | **Fairy gold:** gold that vanishes at end of turn, so it can't be banked (folklore: fairy gold turns to leaves). **Pot of gold** (owner, 02h): a leprechaun-style prize at the rainbow's end that you must do something to claim. More ideas wanted | M: E50. Generated spells that refresh fall under G1; generated gold spells are a loop risk with retriggers (EB G5, G12, proposed) | Both rows (rings on any slot, changelings in front); high | Spell payoffs from Naga; the slot landing from Galaxy (E16). Every tribe casts Tavern spells |
| 2 | Oozes | **Engulf:** absorb a shop unit's stats instead of buying it, once per turn | H: E08/E61 per action, so capped | Front amalgam, links between rows; medium | Mechs' Magnetic, Demons' shop-eating **[data: SE §4.1 #1, #3]** |
| 3 | Hedgerow folk | **Acorns** (own currency); sell and card-gained fuel. **Acorn sizes** (owner's hypothetical, 02h): three small Acorns make an Acorn Stash worth 5, not 3, so hoarding pays: "take a little bit of stuff up front now, or get more later" | L for Acorns; H for sell (R06) | Front, wide; medium | Quilboar gems, Beasts' swarm |
| 4 | Hunters | **Pilfer:** foxes take a shop card, once per turn (Created, so it sells for 0, RB 4.3.2). The one theft line. **Needs examples** (owner, 02h: "I don't really see what the foxes mean") | H: E44 | Front hunters, one back glutton; medium | Galaxy's Hunt; Undead-style death fuel for one carry |
| 5 | Birds | **Forage:** each refresh improves something in the shop. Bounded by the refresh steps **[data: SE §5.2; ET §1 #3]**. **Needs examples:** "a bit vague"; the owner asks for "three or four different economy effects that could kind of fit … and how they play" (02h) | M: R10 with free refreshes (G1) | Front Swoopers, back nests; high | Elementals' refresh economy |
| 6 | Bog folk | **Frogspawn:** eggs in hand that hatch on a later turn. The one delayed-card mechanic. **Needs examples:** the owner doesn't yet understand the tribe's design (02h) | M: E40 | Even; medium | Murlocs almost whole (Battlecry chorus), an easy win that adds little new; the prince hook is its Bramble part |
| 7 | Great beasts | **To design: a weak but real economy angle.** "None, on purpose" is withdrawn: the owner wants "every single tribe to have some economy ability … They can have poor economy … but none is probably not great" (02h, question 10). **Needs examples:** how the flavour connects to play is unclear | L | Front-heavy; low | Myrmidon's and Bristleback Knight's carries |
| 8 | Hive | **Aphid farms** (survival-gated income) | M: recurring gold, gated on survival. PB 4.1 proposes no unconditional recurring gold at Tiers 1–2 (not approved) | Back farms behind a front swarm; medium | Undead's global counter, Beetles **[data: SE Era F, H]** |
| 9 | Greenwood | **Little:** staying put is the investment | L | Front walls, back growers; medium | Dragons' end-of-turn growth **[data: SE Era E]** |
| 10 | Lights | **Little.** **Needs examples:** "sounds really cool, but I don't know how it would be balanced" (owner, 02h) | L | Front decoys, back lanterns; high | Galaxy's protected-engine support (OG §3 shape 6) |

**Merge rule for Oozes (a proposal for the tribe step) [judgement].** A merge adds the stats and keeps one text, the target's; or texts stack, except economy, refresh and retrigger texts, which never stack. Without this, merged texts pile up on one slot (four "gain 1 gold" texts on one body), which per-unit costing doesn't see. Split pieces are base-size and don't inherit merged text, so killing an amalgam doesn't hand its owner a wide board for free.

### 4.3 The most obvious includes

**The pick is deferred.** The owner: "I don't necessarily know what the top tribes will be until we've got the top mechanics and what those mechanics inspire us to do" (02h). The ranking below stays as a draft.

| Rank | Tribe | Why it is an easy win |
|---|---|---|
| 1 | **Fairies** | Named by the owner, and the magic that widens design space (pillar 5). Rings, changelings and curses bend the board's rules in ways animals can't, and all three are row-native |
| 2 | **Oozes** | Named by the owner with their mechanic ("some sort of amalgamation mechanic"). They hold the TALL merge role Mechs held, with no Mechs in the setting, and links make the stagger matter |
| 3 | **Hedgerow folk** | The setting's most familiar cast: the mice, moles, hedgehogs and rabbits of Redwall, Wind in the Willows and Beatrix Potter (Folio field guide). Swarm-and-hoard carries WIDE and the owner's ECO flavour |
| 4 | **Hunters** | Fox, stoat, badger and otter are the other half of that cast. They carry the owner's scam flavour and a back-row glutton, and own the one theft line |
| 5 | **Birds** | Bramble needs a way into the back row from the first set **[data: OG §1.4, §4 #2]**; flight is the obvious creature for it. Refresh foraging is the cleanest no-timer economy **[data: SE §5.2]** |
| 6 | **Bog folk** | The frog chorus is Battlegrounds' Murloc Battlecry line in woodland form, and the frog prince is fairy-tale canon. Low risk, little new |

Close seventh: **Great beasts**. They give STICKY its second top-six carrier and Trample, the main answer to WIDE (question 1).

**Backlog:** Great beasts, Hive, Greenwood, Lights. Further ideas: Olm "baby dragons", a late scaler (Folio seed "The Olm Sleepers"); Cuckoos, an egg planted on the enemy board (Folio hook; needs a rule for units on the opponent's side); bats as an information economy that would show the snapshot (Folio seed "The Echo Cartographers"; question 6); the Peat Wardens' living "spooky-cozy undertakers" as a Reborn line (Folio seed), in place of spirits who pay with Health (question 13).

---

## 5. Coverage check

### 5.1 Every archetype carried by at least two tribes

| Archetype | All candidates | In the top six |
|---|---|---|
| ECO | Hedgerow folk, Birds, Hive | Hedgerow folk, Birds |
| WIDE | Oozes, Hedgerow folk, Greenwood | Oozes, Hedgerow folk |
| TALL | Oozes, Hunters, Great beasts, Greenwood | Oozes, Hunters |
| MEDIUM | Fairies, Birds, Bog folk, Hive | Fairies, Birds, Bog folk |
| STICKY | Bog folk, Great beasts, Lights | **Bog folk only** |
| *SCAM* | Fairies, Hunters, Birds | Fairies, Hunters, Birds |
| *BURST* | Hive, Lights; Rot Toad-style Bog folk | **Bog folk only, as a minor piece** |
| Trample / Cleave | Great beasts; Cleave neutral | neutral Cleave only |

Pass for the longlist. In the top six, STICKY and BURST have one carrier each and Trample has none; Great beasts as the sixth or seventh tribe fixes two of the three. Tall against wide: four candidates carry TALL, two in the top six. SE §5.7 suggests about 3 tall, 4 wide and 3 mixed for ten tribes **[judgement]**; this list is about 4 tall-leaning (Oozes, Hunters, Great beasts, Greenwood), 2 wide (Hedgerow folk, and Oozes or Greenwood depending on lead) and 4 mixed.

### 5.2 No two tribes with the same core

A core is archetypes plus signature mechanic plus economy. No two match. The closest pairs **[judgement]**:

| Pair | Shared | What keeps them apart | Risk |
|---|---|---|---|
| Great beasts / Greenwood | TALL | Combat (front carry, Trample) against time (Rooted growth); STICKY against WIDE | **Near.** Both are big and slow |
| Hunters / Great beasts / Oozes | TALL | A back glutton fed by deaths / a front carry / a merged blob | Low |
| Fairies / Bog folk | MEDIUM | Slot rings and spells against Battlecry chorus; SCAM against STICKY | Low. The prince hook links them on purpose |
| Hedgerow folk / Hive | ECO | Acorns in hand against survival-gated gold; WIDE against MEDIUM | Low |
| Birds / Hive | ECO, MEDIUM | Refresh forage and nests against aphids and a global counter | Low |
| Fairies / Hunters / Birds | SCAM | Transform / on-kill / back-row reach | Low |
| Bog folk / Lights / Great beasts | STICKY | Regrowth / decoys / hides | Low |

Revision 1's overlaps are resolved: delayed cards belong to Bog folk only (Acorns don't sprout, Greenwood grows on the board); theft belongs to Hunters' foxes only; front refills belong to Greenwood only; the death-fed back carry belongs to Hunters only; Burrowers became a calling.

---

## 6. Questions for the owner

At this checkpoint the owner picks only the top tribes and answers the archetype questions (owner, [11-02g note](owner-notes/2026-11-02g-stage-2-checkpoint-scope.md)). Numbers are kept so references elsewhere still point at the right question.

Answers from the owner's read-through ([02h](owner-notes/2026-11-02h-checkpoint-read-through.md)) are given after each question.

- **1. Top tribes:** are the top five in 4.3 right, and is the sixth Bog folk (MEDIUM and STICKY; the easy Murloc line) or Great beasts (TALL and STICKY, with Trample against wide boards)? *Deferred until the top mechanics exist.*
- **4. STICKY:** an archetype of its own, or only a scaling fuel (a blocked hit or a second life used; in Battlegrounds, shield lost or Reborn)? *Its own comp, read from "I agree with all of those" (to confirm).*
- **5. SCAM and BURST:** small spices spread over 2–3 tribes each, as in Battlegrounds, or one tribe's main theme? *Spices, read from the same line (to confirm).*
- **6. Snapshot:** should the player see the board they will fight before ending the turn? Without it, scam and "across from" can't be aimed.

### For the tribe step's checkpoint

- **2. Magic against woodland:** four of ten tribes are magical here. Is that the balance you want, and do you want Greenwood and Lights as new magic kinds? *"I'm okay with magical stuff"; both stay, judged on design.*
- **3. Species per tribe:** keep each tribe to a few species, to fit "a smaller number of the woodland things", or use the wider Folio cast as flavour? *Either: "stuff that stays one species is fine"; design quality decides.*
- **7. Fairies and oozes as types:** one tribe each, or types that can sit on other tribes' type lines too (RB 5.2.2)? *Either: "stuff that crosses tribes is fine"; design quality decides.*
- **8. Banking:** should saving gold across several turns be a strategy ECO owns, given that early damage caps make losses cheap?
- **9. Back-row reach:** Birds' Swoop as the main way in with Trample second, or one neutral keyword several tribes share?
- **10. Economy for all:** should every tribe have an economy angle, or should Great beasts have none on purpose? *Every tribe has one, even a weak one.*
- **11. Position-text share:** about a third of units in every tribe, or varied by tribe (Fairies, Birds, Lights high; Great beasts low)?
- **12. Callings:** may lifestyle groups such as Diggers be callings that cross tribes, with Tunnel limited to one move into an empty slot per combat?
- **13. Undead:** a Reborn line from the Folio's living undertakers in the backlog, or no undead line at all?
- **14. Oozes' lead identity:** merge into one huge blob (TALL) or split into many (WIDE)?
- **15. Ooze merge rule:** may the tribe step start from the proposal in 4.2 (one text kept, or texts stack except economy, refresh and retrigger texts)?
- **16. Recruit Phase position text:** read only at End of Turn, at Start of Combat or after surviving the fight, never at cast time? *No: cast-time position text is fine (section 3, rule 2).*
- **17. Tone:** are insects (Hive) beside bears right for the setting, and should identities lean on the Folio's comic institutions (Frog Chorus divas, Gubbio wolves) from the start?

---

## Critique notes (revision 2)

Two reviews (strategy and power; fun, flavour and overlap) found problems in revision 1. Every must-fix item is applied. Should-fix items are applied except the ones below.

**Changed in response:**
- STICKY is now tagged [judgement] with SE's filing stated, and shield lost or Reborn (R27) is in the fuel table. BURST became a spice with corrected precedent. BULWARK is folded into the default board (1.2, section 3).
- Great beasts lost "alone in a row" and the capercaillie; they now carry front TALL with Trample. Birds have a late plan (nests) and front-bound Swoopers. Each archetype has front-bound text and no comp needs more than 3 back slots.
- Glamour as revision 1 wrote it is gone. Recruit Phase position text now reads at End of Turn or Start of Combat (3, rule 2). Aphid income depends on surviving the fight.
- 1.6 lists the shapes the fallback doesn't bound. Acorns no longer sprout, and overflow has a per-combat cap. The Ooze merge rule keeps one text. Devour gives fixed, capped gains. Generated Fairy spells exclude gold and free refreshes. E52 is once per turn or one-off.
- [data] tags fixed: Scavenging Hyena removed, Vigil Vole no longer cited as precedent, "no game moves units" narrowed to Battlegrounds and Galaxy with SAP noted, Hunt's Galaxy count stated rather than "main trigger". The owner-example attribution for Birds and Rodents is corrected and the ranks re-argued.
- Missing fuels added: plain on summon, Start of Combat self-growth, card gained, golden played. Golden chasing is named as an enabler. Cleave has a neutral home.
- The counter map now forms a loop in which MEDIUM beats WIDE, and ECO's weak counter is a question. Scam aims by text.
- The flavour fixes: the magic tribes carry the rule-bending mechanics (rings, changelings, curses, links). Wisps became Lights (decoys, from the moth and will-o'-wisp hook), dropping the Health Bargain and the bog-body dead. Burrowers became a calling. Canids and Mustelids merged into Hunters. Theft, delayed cards and front refills each have one owner. Moths, will-o'-wisps, capercaillie and otters each sit in one tribe. Hive is bees and ants. The familiar cast leads the ranking. Folio institutions appear in the identities. Bog folk's "adds little new" is said plainly.

**Declined, with reason:**
- *"Set hard rules now" for the loops outside the fallback.* Declined, because the owner deferred bounding and the project rules say the owner decides. Revision 2 proposed limits instead; the owner cut them (11-02g note), so 1.6 now only notes the loops and points to EB.
- *Recast STICKY as a fuel only.* Kept as a [judgement] archetype, because "every body takes two kills" wins differently from growth; question 4 lets the owner choose.
- *Design late BURST payoffs.* I took the other option the review offered (demote to a spice), since Battlegrounds shows no late form to build from.
- *Otters "sit oddly" in Hunters.* Otters are mustelids that hunt fish, so they fit a small-carnivore kind; the oddity was revision 1's "eat what they kill" wording, which is gone.
- *Give the Rat King's linking to Oozes.* Applied as a mechanic, but the Rat King stays as Hedgerow flavour (the committee), since a mechanic and its folklore source can sit in different tribes.

**Amended after the owner's 2 Nov answers:** Battlegrounds and Galaxy keyword names are framed as stand-ins (11-02e note; Tags), STICKY is defined by its shape, and signatures that reuse a keyword are marked *placeholder*. Section 1.6 and question 15 follow the 11-02d answers: the paid refresh price is the primary guardrail, G1 covers effect refreshes, and the gold-back limit is gone because the owner declined it. That supersedes the first declined item above as far as gold back goes.

**Amended after the owner's 11-02g answers:** the proposed limits in 1.6 are cut (effect-refresh per-turn caps as the means to G1, the Health-economy rules, and currency that never turns back into units, so Acorns lose that line in 4.1); 1.6 keeps a note of the loops the price doesn't stop. Section 4 is the starting draft for the tribe step, and section 6 keeps only the top tribes and the archetype questions for this checkpoint. Flags that rested only on PB 4.1's gold caps or EB G2–G14 are gone or kept as information, since reviewers flag only against the tier curve and the tolerance bands. The Ooze merge rule and section 3's rule 2 are labelled proposals. Placeholders in 4.1 name candidate mechanics from MI.
