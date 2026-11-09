# Fairies, pass 3: the Throne (carry and answers)

One designer's entry for the Fairies panel (Track C, `docs/ideation/plan-scale-rework.md`). Angle: **carry and answers**. Paper design only; nothing here has run in Godot. Board numbers come from a rough paper model, `fairies-carry-model.py` in this folder (`python3 -I fairies-carry-model.py line=all`). It plays scripted lines on one board with no shops, fights or opponents. Treat its numbers as the scale of the curve, not as measurements.

## The pitch

**Fairies keep their power in the ground.** A Ring is power on a slot, and Rings now have no cap. Every Ring you make is as big as your **Glamour**, a number that only goes up. So you pick one slot to be your **throne** and point your Rings at it. Whoever stands there is your carry. When you find a better body, move it onto the throne: the Ring stays, so a new carry costs nothing. When the carry dies in a fight, a Wisp rises in its place and picks the Ring up. And you can't steal a fairy's glamour: take the body and the power stays home.

Fairies also have the pool's best answers to everyone else's carry: the Changeling steals it onto your Ring, Lady Belladonna poisons the biggest enemy in any row, and the Hedge Witch curses whatever stands across from her.

*Similar to:* Battlegrounds' Blood Gems and "this game" counters (one number that keeps rising and sizes every new buff), Brann-style doublers (the Queen), and Once Upon a Galaxy's slot buffs. No Battlegrounds tribe keeps its stats on the board instead of the minion.

## Why this fixes what's wrong now

From `docs/ideation/fundamentals.md` and the audit (`evidence/fundamentals-audit/card-audit-birds-bog-fairies.md`):

| Problem now | Pass 3 answer |
|---|---|
| Rings capped at +4/+4 a slot: at most +28/+28 on the board, ever (audit, assumption 2) | No cap. Ring size is your Glamour, which climbs all game |
| The only concentrator is the Queen, and she spreads what she takes over every other Fairy | The throne: Rings aim at one slot by position, and the Queen doubles your biggest Ring |
| Concentration needs stats that hold (fundamentals §1.6); Fairies have none | Cleave on the throne (Cluricaun), Shield in front (Hob), a full-stat refill when the carry dies (Will-o'-the-Wisp), a front-row twin (Cradle Fetch), and Rings that can't be stolen or destroyed with the body |
| Fairies' answers aim by position and the enemy dodges them | Belladonna now hits the biggest enemy in any row. The Changeling and the Witch still aim across, which is the placement game |
| Flat answers fade as stats grow (audit, assumption 4) | Hex is a percentage; Nightshade and the Changeling were already proportional |
| Economy is one-shot (Chaser, Shy) and feeds nothing | The Chaser stores gold from Ring-making; Shy brownies pay gold and leave Rings and Glamour behind |
| Rainbow is a bank to cash out by round 6, not a route | Rainbow is retired; its two leprechauns get new jobs in the Ring engine |
| Bots can't value slot power (0.9% of seats pick Fairies; 31% win when they do) | The line lists below; the throne is a fixed slot that a scripted line can follow |

## The engine

### Rules (new or changed)

- **Ring (changed).** "Ring a slot" gives that slot +X/+X, where X is your Glamour at that moment. Rings add up and have **no cap** (rulebook 8.5.4's cap is removed). As now, a Ring lasts the game, stays when units move, are sold or die, copies into fights, and does nothing on an empty slot. Shy units get nothing from Rings. "Ring a slot twice" makes two Rings.
  - *Reminder:* "This slot has +X/+X. Whoever stands here has it." The slot shows its size; card text shows the live size, as in "Ring this slot (+8/+8)".
- **Glamour (new player number).** It starts at 1, only goes up, and shows on the Fairies' tribe icon. Old Moth Annis, Silky and Fairy Monarch raise it. Neutral Ring spells use the caster's Glamour, so a non-Fairy player rings at 1.
  - *Reminder:* "How big each new Ring is. It only goes up."
- **Your biggest Ring (term).** The slot holding your largest Ring; ties go to reading order. The UI marks it with a small crown: the throne. Four cards read it.
  - *Reminder:* "The slot with your largest Ring."
- **Hex (changed to a percentage).** Uses Track B's percent Hex: "Start of Combat: the enemy across has X% less Attack." It stays on the slot as now. The Witch's tier cap is removed; Hex stops at 100%.
- **Shy (unchanged from pass 2).** Only a spell aimed at it buffs it, then it leaves and pays 2 gold next turn.
- **Rainbow, Bands and the Pot are retired.** Rainbow Chaser and Cluricaun keep their names and art with new text.

### How it compounds

Ring stats added each turn = (Ring events a turn) × (Glamour). Both grow:

- **More Ring events.** Each Ring maker you add (Sally, Lob, a second Sally, goldens, Spore Clouds) adds events to every later turn.
- **Bigger Rings.** Annis adds Glamour every turn, Silky adds a lump, and from tier 6 the Monarch adds 1 Glamour for every Ring made. With 6–8 Rings a turn, that's +6–8 Glamour a turn.
- **Doubling.** The Queen doubles your biggest Ring every third turn.

So the early game rings at Glamour 1 (level with today), the engine turns on with Annis at tier 4, and the Monarch and the Queen steepen the curve after round 12. In the model, the wide line grows about ×1.57 a round from round 12 to 15, close to the September 2025 shape.

### The rate parameter: **r = Glamour per trigger**

- Annis gives +r each End of Turn; Silky gives +r per Shy unit leaving. Default **r = 1**; sweep 1, 2 and 3.
- Second knob, **m**: Glamour per Ring made with the Monarch out. Default 1; sweep 1 and 2.
- Fixed for the sweep: Queen every 3rd turn; Spore Cloud rings twice (see the neutral proposals below).

| Model line (defaults) | R6 | R9 | R12 | R15 |
|---|---|---|---|---|
| r = 1, m = 1: wide typical / carry typical | 65 / 66 | 149 / 174 | 467 / 377 | 1,798 / 1,130 |
| r = 2, m = 1 | 65 / 66 | 183 / 234 | 711 / 585 | 2,354 / 1,728 |
| r = 1, m = 2 | 65 / 66 | 149 / 174 | 497 / 377 | 2,790 / 1,418 |
| Target, median / strong (September 2025 shape on today's start) | 52 / 60 | 150 / 200 | 500 / 700 | 1,700 / 2,400 |

r = 1 puts typical play on the median; r = 2 puts typical play at "strong". The sweep should pick between them once the lines run against a real field.

### The turn it comes online

- **Rounds 1–6:** every Ring is +1/+1, uncapped. Fairies are about level with today: 65 at round 6 against a target of 52–60.
- **Rounds 7–9: the engine starts.** Annis lands at tier 4 (round 7), and the first thank-you turn (Silky) adds Glamour. Rings reach +5/+5 by round 9. The throne is a real carry by **round 9–10**, when a tier 4–5 body is planted on a slot already holding about +35/+35.
- **Round 12 on: the curve steepens.** The Monarch and the Queen arrive. Glamour goes from about 10 to 25–40 by round 15.

Engine cards follow "behind at once, level in a few turns, clearly ahead after": Annis and the Monarch add no stats the turn you buy them, are level in one or two turns, and are far ahead after three.

### The decision it creates, every turn

**Where does this turn's Ring go?**

- **The throne:** concentrate. The carry crosses the enemy's breakpoints sooner, but one Horseshoe, Nightshade or "biggest enemy" answer finds all of it.
- **A wall:** spread. The front row survives longer and the board shrugs off single-target answers, but nothing crosses the breakpoints.

Every Ring maker answers this through placement rather than a prompt:
- Lob at the end of a row rings one slot; in the middle it rings two.
- Sally rings whatever slot she stands on, so moving her each turn is the choice.
- Nan rings a slot you pick next to her.

Around it sit three more choices:
- **When to plant the carry:** move a better body onto Sally's grown slot, and Sally starts growing a new one.
- **When to thank the brownies:** give up the Shields and the Ring-maker for gold, Rings and Glamour.
- **What the Queen tithes:** the units behind her die every third turn.

## The 16 cards

Tier spread stays 3/3/3/3/2/2. Three cards change tier, each with a reason below: **Old Moth Annis 2→4** (the Glamour clock must start after the early game), **Silky 4→3** (the thank-you turn moves earlier, so it feeds Glamour sooner), **Cradle Fetch 3→2** (its effect scales with the throne, so a cheap early copy stays useful all game). Every creature, name and portrait is kept.

Payoff estimates use the model's typical Glamour: **about 5 at round 9, 10 at round 12 and 30 at round 15**, and a throne holding about +35, +90 and +250. "Ring" means +Glamour/+Glamour.

### Tier 1

**Nan Toadstool**, Pixie Trickster, 2/1
- **Text:** When played: Ring a slot next to this.
- **Golden:** When played: Ring a slot next to this twice.
- **Condition:** played, next to the slot you want; the player picks the slot.
- **Payoff:** one Ring: +5/+5 at R9, +10/+10 at R12, +30/+30 at R15. Late, she is the cheapest Ring there is (buy, play, sell: 2 gold a Ring) and the perfect tithe for the Queen.
- **Permanence:** permanent, on the slot.
- **Enabler:** every biggest-Ring card, the Chaser's store, the Monarch's Glamour.
- **Concentrates:** yes; you choose the slot.

**Rainbow Chaser**, Leprechaun Cobbler, 1/3
- **Text:** After you Ring a slot: store 1 gold. Once a turn. When sold: get the stored gold.
- **Golden:** After you Ring a slot: store 2 gold. Once a turn. When sold: get the stored gold.
- **Condition:** you make a Ring each turn (almost free on a Fairy board).
- **Payoff:** about 1 gold a turn, banked. Bought on round 1–2, it sells for 4–6 gold on round 5–7: a tier-up turn. Late copies are rare (tier 1 odds).
- **Permanence:** economy; the stored gold shows on the card.
- **Enabler:** gold for Spore Clouds and Nans; ties the tribe's economy to Ring-making, so it doesn't splash (the owner's 2 Nov note on economy).
- **Concentrates:** no.
- **Decision:** sell now for the tier-up, or keep the pot growing.

**Hedge Witch**, Hag of the Hedgerow, 1/3
- **Text:** Hex 10%. Each spell you cast adds 5%.
- **Golden:** Hex 20%. Each spell you cast adds 10%.
- **Details:** Hex stops at 100%.
- **Condition:** spells cast while she's owned; placed across the enemy's carry.
- **Payoff:** with the tribe's 1–2 Ring spells a turn: about 40% less Attack on the enemy across at R9, 65% at R12 and 90% at R15. Against a 120-Attack carry at R12, that's −78 Attack.
- **Permanence:** combat only; it stays on the enemy slot for the fight.
- **Enabler:** answers; rewards the spell-heavy Ring line.
- **Concentrates:** no; it answers concentration. On a Ring she's also a real body.

### Tier 2

**Sally Spore**, Sprite Gardener, 1/3
- **Text:** End of Turn: Ring this slot.
- **Golden:** End of Turn: Ring this slot twice.
- **Condition:** standing on the slot you want grown.
- **Payoff:** +5/+5 a turn at R9, +10/+10 at R12, +30/+30 at R15. If she stays put, her slot holds about +16/+16 by R9, +45/+45 by R12 and +140/+140 by R15. She is the early carry, then the gardener: plant a better body on her slot and she starts again elsewhere.
- **Permanence:** permanent, on the slot.
- **Enabler:** the throne (she grows it first), Fetch, Will, Cluricaun, the Queen.
- **Concentrates:** yes.

**Hob-in-the-Hearth**, Brownie Helper, 1/4
- **Text:** Shy. The units in front of this have Shield.
- **Golden:** Shy. The units next to this have Shield.
- **Golden details:** Shy pays 4 gold.
- **Condition:** in the back row with units in front. B2 shields F2 and F3; B1 shields F1 and F2.
- **Payoff:** two Shields a fight. Each stops one hit: about 10 Health each at R9, 40 at R12 and 120 at R15. Thank him for 2 gold, plus a Ring and Glamour with Silky.
- **Permanence:** standing aura (recruit and combat).
- **Enabler:** a front-row throne; Silky.
- **Concentrates:** protects it. His Shield is the front carry's stat-holder.

**Cradle Fetch**, Fetch Double, 2/3
- **Text:** Start of Combat: gain half the biggest Ring behind this.
- **Golden:** Start of Combat: gain the biggest Ring behind this.
- **Condition:** in the front row, in front of a Ringed slot. In front of a B2 throne, that's F2 or F3.
- **Payoff:** about +18/+18 at R9, +45/+45 at R12 and +125/+125 at R15: a second big body for the fight, which soaks the enemy's single-target answer.
- **Permanence:** combat only, but the shop shows combat-start stats.
- **Enabler:** the throne.
- **Concentrates:** it mirrors the carry: two big bodies instead of one.

### Tier 3

**Lob-Lie-by-the-Fire**, Hearth Lubber, 2/3
- **Text:** Shy. End of Turn: Ring the slots beside this.
- **Golden:** Shy. End of Turn: Ring the slots beside this twice.
- **Golden details:** Shy pays 4 gold.
- **Condition:** an end slot (F1, F4, B1, B3) rings one neighbour; a middle slot rings two. Lob gets nothing from Rings, so his own slot is where you don't ring.
- **Payoff:** +5/+5 a turn per slot at R9, +10/+10 at R12, +30/+30 at R15. In B1 or B3 he feeds only B2: the throne's steadiest feeder.
- **Permanence:** permanent, on the slot.
- **Enabler:** the throne; Silky.
- **Concentrates:** yes from an end slot, spreads from the middle.

**Silky**, Grey Lady of the House, 3/4
- **Text:** Shy. After a Shy unit leaves: Ring its slot. Glamour +1.
- **Golden:** Shy. After a Shy unit leaves: Ring its slot twice. Glamour +2.
- **Details:** This counts too. Destroying or selling a Shy unit doesn't count.
- **Condition:** thank Shy units with aimed spells (Pinch of Dust, 1 gold each).
- **Payoff:** the thank-you turn. On round 7, thanking Hob and Silky gives 4 gold next turn, two Rings, and Glamour +2. That +2 makes every later Ring 2 bigger: about +100 stats spread across the board by R15.
- **Permanence:** permanent (Rings, Glamour) plus economy.
- **Enabler:** Glamour for everything; frees slots for late bearers.
- **Concentrates:** partly. Its Rings land where the brownies stood.

**Cluricaun**, Leprechaun Reveller, 3/4
- **Text:** The unit on your biggest Ring has Cleave.
- **Golden:** The units on your two biggest Rings have Cleave.
- **Condition:** a throne.
- **Payoff:** the carry hits the target and both units beside it. Each swing kills up to 3 (fundamentals: Cleave is worth about +11 win points on equal boards, more on a concentrated one). This is why the throne beats wide boards.
- **Permanence:** standing aura.
- **Enabler:** the throne; a stolen enemy on your throne Cleaves too.
- **Concentrates:** it is what makes concentration pay.

### Tier 4

**Old Moth Annis**, Moth Hag, 3/6
- **Text:** End of Turn: Glamour +1.
- **Golden:** End of Turn: Glamour +2.
- **Condition:** on the board. That's its price: a slot that holds a clock, not a fighter.
- **Payoff:** every later Ring is 1 bigger per turn she stays. With 4–6 Rings a turn, she adds about +20 stats a turn by R9, +50 by R12 and +60 by R15 (before the Monarch takes over).
- **Permanence:** permanent; Glamour never falls.
- **Enabler:** every Ring maker.
- **Concentrates:** no; it sizes everything.
- **Tier 4 because:** at tier 2 she made rounds 5–9 far too fast (the model's first draft hit 79 at round 6 and 236 at round 9).

**Will-o'-the-Wisp**, Wisp Lantern-Bearer, 3/6
- **Text:** When the unit on your biggest Ring dies: summon a Wisp in its place. Once a fight.
- **Golden:** When the unit on your biggest Ring dies: summon a Wisp in its place. Twice a fight.
- **Condition:** a throne that dies in the fight.
- **Payoff:** a 1/1 Wisp that takes up the Ring. The carry comes back at full Ring size: about 36/36 at R9, 91/91 at R12 and 251/251 at R15.
- **Permanence:** combat only.
- **Enabler:** the throne. It also works when a stolen enemy dies on your throne.
- **Concentrates:** it protects concentration. This is the throne's Reborn.

**Changeling**, Changeling Babe, 2/2
- **Text:** Start of Combat: swap sides with the enemy across. Swap back after it attacks once.
- **Golden:** Start of Combat: swap sides with the enemy across. Swap back after it attacks twice.
- **Condition:** placed across from their carry.
- **Payoff:** their carry hits its own team once: about 30 damage at R9, 120 at R12 and 400 at R15. It also stands on your slot, so it gets your Ring there, and it's missing from their board until it swaps back.
- **Permanence:** combat only.
- **Enabler:** answers; the throne (see "the Changeling on the throne").
- **Concentrates:** no; it punishes concentration.

### Tier 5

**Lady Belladonna**, Sprite Poisoner, 4/8
- **Text:** Start of Combat: give the biggest enemy Nightshade.
- **Golden:** Start of Combat: give the two biggest enemies Nightshade.
- **Condition:** none. It finds the biggest enemy in any row (Track B's selector).
- **Payoff:** each time that enemy is attacked, it first loses half its current Health. A 150/150 carry at R12 falls in 3–4 hits instead of 8. She is also the throne's favourite body: a 4/8 that is an answer.
- **Permanence:** combat only.
- **Enabler:** wide attackers (Wisps, Reel-Mistress's dance).
- **Concentrates:** no; this is the pool's strongest answer to concentration.
- **Rare by design:** if the pool can afford only two or three "any row" answers, this is Fairies' one. Fallback if the pool is full: the current "across, or from the back row the two across from the slots in front of this".

**Reel-Mistress**, Pixie Dancing-Mistress, 4/7
- **Text:** After a unit attacks: its Ring moves to your next unit. Each Ring moves once a fight.
- **Golden:** After a unit attacks: its Ring moves to your next unit. Each Ring moves twice a fight.
- **Condition:** many units on Rings, which is the wide route.
- **Payoff:** every Ring swings twice: with the owner and the next attacker, where Rings meet and add up. Total Ring Attack swung goes up by about 60 at R9, 200 at R12 and 700 at R15, fight only.
- **Permanence:** combat only.
- **Enabler:** the wide route.
- **Concentrates:** in the fight only: Rings gather on the next attacker. It works against the throne, which loses its Ring after its first swing, so throne players skip her. That's the route choice at tier 5.

### Tier 6

**Fairy Monarch**, Fairy Sovereign, 5/7
- **Text:** After you Ring a slot: Glamour +1.
- **Golden:** After you Ring a slot: Glamour +2.
- **Condition:** Ring makers on board; spells count.
- **Payoff:** with 6–8 Rings a turn, Glamour rises 6–8 a turn instead of 1. That's +12/+12 more on every Ring two turns later and +25/+25 four turns later. In the model, the wide line goes from 467 at R12 to 1,798 at R15 after she lands.
- **Permanence:** permanent; Glamour never falls.
- **Enabler:** every Ring maker. Spore Cloud ringing twice counts twice.
- **Concentrates:** no; it sizes everything.

**Queen of Elfland**, Fairy Queen, 8/8
- **Text:** Every 3rd End of Turn: destroy units behind this, or this if none. Double your biggest Ring.
- **Golden:** Every 3rd End of Turn: destroy units behind this, or this if none. Double your biggest Ring twice.
- **Details:** The count shows on her. The first Teind falls 2 turns after she's played. The doubling happens even if she pays with herself.
- **Condition:** in the front row with something cheap behind her. A corner (F1, F4) tithes one unit, F2 or F3 tithes two. Nan and tokens make good tithes.
- **Payoff:** a throne of +90 becomes +180 at R14, and +250 at R15 becomes +500 at R17. That's ×2 every three turns: about ×1.26 a turn on the carry. Golden is ×4, the top 1%.
- **Permanence:** permanent.
- **Enabler:** the throne.
- **Concentrates:** yes, strongly.
- **Decision:** the tithe. The units behind her are a body and a slot every third turn, and the throne's best feeders (Lob, Fetch) want those slots.

### Token

**Wisp**, 1/1 Fairy. Summoned by Will-o'-the-Wisp. Combat only.

### Wording check

| Card | Words | | Card | Words |
|---|---|---|---|---|
| Nan Toadstool | 8 | | Cluricaun | 8 |
| Rainbow Chaser | 16 | | Old Moth Annis | 5 |
| Hedge Witch | 8 | | Will-o'-the-Wisp | 17 |
| Sally Spore | 6 | | Changeling | 15 |
| Hob-in-the-Hearth | 9 | | Lady Belladonna | 8 |
| Cradle Fetch | 10 | | Reel-Mistress | 16 |
| Lob-Lie-by-the-Fire | 9 | | Fairy Monarch | 7 |
| Silky | 11 | | Queen of Elfland | 17 |

- **Length:** median 9 words, maximum 17. The guide asks for a median of 11 or less, p90 of 17 or less, and a maximum of 22.
- **Keywords:**
  - Ring: 9 cards.
  - Glamour: 3 cards plus the Ring reminder.
  - Biggest Ring: 4 cards.
  - Shy: 3 cards.
  - Hex and Nightshade: one card each, kept because each is also a fight status.
  - Shield and Cleave: shared Track B keywords.
- **Net change:** Rainbow, Bands and the Pot go; Glamour and "biggest Ring" come in.

## The tribe

### Carry route: the Throne

- **The plan:**
  - Grow one slot from round 3 with Sally standing on it.
  - Feed it with Lob from an end slot, Nan, and Ring spells.
  - Plant a real body on it at round 9–10, usually Lady Belladonna (an answer that is also a fine 4/8), the Monarch or a golden unit. Sally walks to a front slot and grows a second big unit.
  - Hold it with Cluricaun (Cleave), Will (the refill) and Fetch (the twin in front).
  - Double it with the Queen from round 12.
- **The throne's slot:**
  - **B2** is the default. It's protected, Lob in B1 or B3 feeds only it, and Fetch in F2 or F3 mirrors it.
  - **F2 or F3** is the front throne. It attacks first and Cleaves every cycle, Hob behind gives it Shield, and Lob beside feeds it. But it eats every enemy swing.
- **Shape:** in the model the throne holds about 47–50% of the board, with a second big unit (Sally's slot or Fetch) at 25–40%. The rest is chaff: clocks, feeders and the tithe.

### Non-carry route: the Long Dance

- **The plan:** spread the Rings. Put two Sallies on two walls, Lob in the middle of a row (two slots), and Spore Clouds across the front. Reel-Mistress makes every Ring swing twice, and the Monarch sizes it all.
- **Shape:** the biggest unit holds 32–36% of the board, Battlegrounds' normal shape. In the model it's the larger total (467 at R12, 1,798 at R15) but has no single unit over the enemy's breakpoints.
- **When to take it:** it loses less to Horseshoe and biggest-enemy answers, so it suits a lobby full of answers. The throne suits a lobby of wide boards.

### Placement decisions (the angle's main ask)

| Decision | Options | What it trades |
|---|---|---|
| Where the throne is | B2, B1/B3, or F2/F3 | Protection and late swings against Shield, first swings and Cleave every cycle |
| Where Sally stands this turn | The throne-to-be, a wall, a slot for the next bearer | Concentration against spread, every End of Turn |
| When to plant the carry | Now, onto Sally's slot, or wait for a tier 5–6 body | A better body's text against a turn of Sally's growth on the throne |
| Lob's slot | End of a row (one Ring) or middle (two) | Focus against spread; his own slot wastes Rings |
| Hob's slot | Behind the units you want shielded | Front throne or front walls; keep Shy units off Rings |
| Fetch's slot | In front of the throne | A twin for the fight; F2 and F3 copy the bigger of their two back slots |
| The Queen's slot | Corner (one tithe) or middle (two tithes) | Bodies lost every third turn against keeping F2/F3 free |
| Answers | Changeling and Witch across the scouted carry | Their carry may sit across from your own throne: see below |

**The Changeling on the throne.** When the scout shows their carry across from your throne, the Changeling can't reach it from another slot. So for one fight, put the Changeling on the throne and move your bearer to a side slot.
- At Start of Combat, their carry swaps onto your throne. It gets your Ring and Cluricaun's Cleave, and fights for you.
- Your own bearer fights as a bare body that turn.
- When it swaps back, it goes home without your Ring.

### Answers to other tribes' carries

| Answer | Reach | Against a carry of 300/300 at R15 |
|---|---|---|
| Lady Belladonna (T5) | The biggest enemy, any row | Each hit halves its Health first: about 3 hits to kill instead of 8 |
| Changeling (T4) | The enemy across | One swing of 300 into its own team, standing on your Ring; it misses its own first cycle |
| Hedge Witch (T1) | The enemy across | 90% less Attack with a spell-heavy line: it hits for 30 |
| Cleave on the throne | The front row | Wide boards lose 3 units a swing |
| Neutrals that fit | Whirligig Beetle swaps their rows (their back-row carry comes forward); Ichneumon Wasp; Turnip Scarecrow across the carry | |

Against the other tribes' pass 3 carries:
- **Hedgerow's Pass carry** sits on the last slot in Pass order, often F4 or B3: Changeling in F4 or B3.
- **The Birds' Redbreast** sits in B2: Changeling and Witch in B2, which means moving your throne to B1 or B3 for that fight.
- **Any carry:** Belladonna finds it.

### Weak points

- **Iron.** Horseshoe (neutral, 1 gold) halves the Ring across from a slot for a fight. One cheap spell halves the throne. That's good: it's the anti-Fairy scam, and it gets stronger as Rings grow.
- **Biggest-enemy answers** (Nightshade-like effects, proportional Attack cuts, Bog's halving) always find the throne.
- **Chaff.** Feeders, clocks and Shy units are 10–20-stat bodies at R12. A wide board kills the Fairy front row in one cycle and reaches the throne early.
- **A late curve that leans on the Monarch.** A Fairy board without her flattens after round 12 (carry line: 377 at R12 against 470 with an earlier Monarch). Hiring Fair with 5 Fairies helps.
- **The slot squeeze.** Seven slots must hold the throne, Sally, Lob, a clock, Cluricaun, Will, Fetch, the Queen and her tithe. Something always sits on the bench.
- **Route clash.** Reel-Mistress strips the throne's Ring after its first swing. Shy units waste Rings under them.
- **Spell supply.** The late game wants a Spore Cloud most turns, and the shop shows one spell.

### Two highroll moments a player will remember

1. **"Their carry, on my throne."** Round 13. The scout shows their 400/400 Dozey across from your +250 throne, so you put the Changeling there. At Start of Combat, Dozey swaps sides as a 650/650 with Cleave and wipes three of his own front row on his one swing. Then he walks home with no Ring and half his Health.
2. **"The golden Teind."** Round 14. You triple the Queen with a Hiring Fair pick. Her count hits 3 that same End of Turn: a Nan behind her dies, and your +180 throne becomes +720/+720. The next three fights end before your back row attacks.

Smaller ones: the thank-you turn (two Pinches for 4 gold, two Rings and Glamour +2), and the Wisp king (your 300/300 Belladonna falls, and a 1/1 Wisp rises as 301/301).

## Boards at rounds 6, 9, 12 and 15

Model defaults: r = 1, m = 1, Spore Cloud rings twice, Queen every 3rd turn. Typical lines climb T2 R3, T3 R5, T4 R7, T5 R10, T6 R12; the fast line climbs T2 R2, T3 R4, T4 R6, T5 R8, T6 R10. Board stats are combat-start sums, as in `evidence/reference-curves.md`.

| Round | Wide, typical | Throne, typical | Throne, fast climb | Throne, highroll | Target median / strong | Biggest unit's share (wide / throne) |
|---|---|---|---|---|---|---|
| 6 | 65 | 66 | 94 | 94 | 52 / 60 | 22% / 36% |
| 9 | 149 | 174 | 225 | 257 | 150 / 200 | 34% / 47% |
| 12 | 467 | 377 | 470 | 797 | 500 / 700 | 32% / 49% |
| 15 | 1,798 | 1,130 | 1,396 | 2,466 | 1,700 / 2,400 | 34% / 50% |
| Glamour at 9 / 12 / 15 | 4 / 13 / 39 | 5 / 8 / 24 | 6 / 16 / 32 | 6 / 26 / 47 | | |

- "Highroll" adds a golden Sally on round 7 and the Monarch on round 10 to the fast climb. It's 1.5–2.1× the typical throne, and the fast climb alone is 1.2–1.4×. The top 1% (golden Queen, golden Monarch) sits beyond the model.
- The throne line's total runs 20–35% below the wide line from round 12. It pays for concentration with tithes, Shy feeders and the slot squeeze. Whether that pays off in fights is the first thing the field sim must answer.
- Early, both lines are about 10% above the strong target at round 6. Watch it, but it comes from uncapped +1/+1 Rings, not from the engine.

**Throne, round 9** (174, tier 4, Glamour 5):

| F1 | F2 | F3 | F4 |
|---|---|---|---|
| Will-o'-the-Wisp 5/8 | Cluricaun 5/6 | Neutral wall 17/18 | Old Moth Annis 6/9 |

| B1 | B2 | B3 |
|---|---|---|
| Lob 4/5 | **Sally Spore 40/42** (the throne) | Hob 3/6 |

**Throne, round 12** (377, tier 6, Glamour 8):

| F1 | F2 | F3 | F4 |
|---|---|---|---|
| Old Moth Annis 6/9 | Cluricaun 6/7 | Sally Spore 59/61 | Queen of Elfland 12/12 |

| B1 | B2 | B3 |
|---|---|---|
| Lob 5/6 | **Lady Belladonna 91/95** | Wisp tithe 4/4 |

The no-Queen version (Will, Fetch and Hob kept) totals 433, with Fetch 39/40, Sally 72/74 and Belladonna 76/80.

**Throne, round 15** (1,130, Glamour 24): Belladonna 245/249 on the throne, Sally 280/282 in F3, the Monarch, Cluricaun, the Queen, Lob and a tithe. Biggest share 50%.

**Wide, round 15** (1,798, Glamour 39): Sallies 305/307 and 176/178, Reel-Mistress 239/242, Belladonna 100/104, Will 39/42, the Monarch, golden Lob. Biggest share 34%.

## Harness lines

### Line 1: `fairies_tempo` (tempo)

- **Engine flag:** off until tier 4, then on. Committed to Fairies.
- **Buy and keep, in order:** hob_in_the_hearth, nan_toadstool, cradle_fetch, sally_spore, cluricaun, lob_lie_by_the_fire, changeling, will_o_the_wisp, belladonna, old_moth_annis, fairy_monarch, queen_of_elfland, hedge_witch, silky, rainbow_chaser, reel_mistress.
  - **Neutral fill:** turnip_scarecrow, ballooning_spider, charcoal_burner, whirligig_beetle.
  - **Spells:** spore_cloud and boundary_stone on the biggest front wall; harvest_supper on a Fairy.
- **Climb:** T2 R2, T3 R4, T4 R6, T5 R8, T6 R10. Buy one unit on climb turns when gold allows.
- **Place:**
  - Rings on the front row.
  - Hob in the back row behind the two strongest front units.
  - Changeling and Witch across the scouted biggest enemy.
  - Fetch in front of the biggest back-row Ring.
- **Save:** never; spend to 0. From T6, spend surplus on refreshes for Spore Clouds.

### Line 2: `fairies_throne` (engine and carry)

- **Engine flag:** on.
- **Buy and keep, in order:** sally_spore (up to 3 for the triple), nan_toadstool, rainbow_chaser, lob_lie_by_the_fire (2), hob_in_the_hearth, silky, old_moth_annis, cluricaun, will_o_the_wisp, cradle_fetch, belladonna, fairy_monarch, queen_of_elfland, changeling, hedge_witch. Never reel_mistress.
  - **Spells:**
    - spore_cloud and boundary_stone, always bought.
    - pinch_of_dust only to thank Shy units on the thank-you turn.
    - harvest_supper on a Fairy.
    - hiring_fair at T5+ with 5+ Fairies and no Fairy T6.
- **Climb:** T2 R3, T3 R5, T4 R7, T5 R10, T6 R12, as in the model (knob: one turn faster at T5 and T6).
- **Place:**
  - **Throne:** B2. Sally stands on it from her first turn.
  - **Lob:** B1, then B3 for a second copy.
  - **Hob:** B3 until a second Lob needs the slot.
  - **Fetch:** F2 or F3.
  - **Cluricaun, Annis and the Monarch:** any front slot.
  - **The Queen:** F1 or F4, with a Nan or a token behind her.
  - **Planting:** when a T4+ bearer is bought (Belladonna first), move Sally to the front slot with the biggest Ring and plant the bearer on B2.
- **Ring spells:** to the throne while the throne holds under 50% of the board; otherwise to Sally's slot. The front walls are a knob worth testing.
- **Thank-you turn:** the turn Silky is bought, if Hob is on board and 2 gold remain: Pinch Hob, then Silky.
- **Answers:**
  - **Changeling:** across the scouted biggest enemy. If that slot is the throne and their carry is bigger than ours, put it on the throne for that fight and move the bearer to the nearest empty slot.
  - **Witch:** across their highest-Attack unit.
- **Save:**
  - Keep the Rainbow Chaser until its stored gold plus gold in hand pays the next tier-up, then sell it on that turn.
  - From R9, keep 2 gold for a Spore Cloud each turn if the shop has none, and refresh once for it.
  - From R10, hold 6 gold for Hiring Fair while no Fairy T6 is owned.
- **Knobs worth tuning:** the 50% share rule, the planting tier, and whether to take the Queen at all.

## Risks, loop guards and what the sweep should test

| Risk | Guard now | Lever if sims show it's common |
|---|---|---|
| The throne at 50% loses to even boards of the same total (fundamentals §1.6) | Cleave, the Wisp refill, the Fetch twin, Shield in front, a second big unit | Will gives the unit on your biggest Ring Damage Reduction 25%, or Cluricaun adds Shield |
| A fast climb plus a golden Sally snowballs from round 9 (1.7× median) | None but the field and answers | r stays 1; Silky's Glamour applies to its own thank only |
| The Monarch is on almost every winning Fairy board (a "Lollop") | Spread acceleration: Annis, Silky, Queen | Monarch at +1 per 2 Rings, or a second Glamour source at T5 |
| Queen ×2 every 3 turns plus golden gives ×4 too often | Golden T6 is rare; the tithe costs bodies | Teind every 4th turn |
| Nan buy-play-sell loops with the Chaser and the Monarch | Tier 1 odds fall late; refresh costs rise; the Chaser stores once a turn | Nan's Ring only on the first play each turn |
| Hex reaches 100% across a carry | Across only; the carry's owner can dodge when live | 4% a spell |
| The Changeling on the throne is too strong | Your own bearer loses the throne for that fight | The stolen unit gets no Rings |
| Big numbers unreadable on a phone (Track B check) | — | Drop a step in era |

A rare highroll never fails the tribe (owner, 9d). The golden Queen and the golden Monarch are the intended top 1%.

What the sweep and the field fights should measure, in this order:
1. Throne board against an even board of the same total, at rounds 9, 12 and 15. Does Cleave plus the refill make concentration pay?
2. r = 1 against r = 2, and m = 1 against m = 2, on both lines against the field.
3. Share of Fairy wins with the Monarch on board.
4. How often Belladonna and the Changeling decide fights against the other tribes' carries (the variance budget's "upsets from answers").
5. Horseshoe's effect on throne boards (the anti-Fairy answer must reach them sometimes).

## Engine support needed

| Need | For | What |
|---|---|---|
| Glamour | Ring, Annis, Silky, Monarch, all Ring spells | A player-level number, default 1, saved in the game state, shown on the Fairy icon. Ring effects read it on resolution. |
| Ring without a cap; "Ring N times" | All Ring cards | Remove 8.5.4's cap and the full-Ring refusal. Each Ring is one event. |
| Ring events as a trigger | Rainbow Chaser, Fairy Monarch | `on_ring` listener: who rang, which slot, how many times |
| Selector: your biggest Ring | Cluricaun, Will, Fetch, the Queen | The slot with the largest Ring, ties in reading order, live in fights (Rings can dance) |
| Self-slot and beside-slot ringing at End of Turn | Sally, Lob | `ring` with targets `self_slot` and `adjacent` |
| On-play slot choice next to the unit | Nan | Target prompt over the 2–4 slots next to it, empty or not |
| Aura granting a Track B keyword | Cluricaun (Cleave), Hob (Shield) | Keyword grant by selector, recomputed on board change |
| Death trigger on the biggest Ring's unit; summon into its slot | Will-o'-the-Wisp | Once/twice a fight; the Wisp takes the slot (8.4.6) |
| Half of a slot's Ring, at Start of Combat | Cradle Fetch | Track B proportional stats, read from a slot effect |
| Biggest-enemy selector | Lady Belladonna | Track B, plus the existing Nightshade |
| Percent Hex with separate base and step | Hedge Witch | Track B's percent Hex adds its base per spell; this needs a step (5%) apart from the base (10%) |
| Double a slot's Ring | Queen of Elfland | A multiplier on a slot effect; the existing Teind counter |
| Glamour +N at End of Turn and on Shy leaving | Annis, Silky | Small scripts on the existing hooks |
| Stored gold on a unit | Rainbow Chaser | Per-unit counter with a once-a-turn guard; paid on sale; shown on the card |
| Changeling golden: swap back after two attacks | Changeling | A count on the existing swap |
| Ring moves after any attack, with a per-Ring count | Reel-Mistress | Existing script; remove the cap note; golden count 2 |
| UI | All | Ring size on slots, a crown on the biggest Ring, live Ring size in card text, Glamour on the tribe icon |
| Retire Rainbow and Bands | Chaser, Cluricaun, Rainbow's End | Code can stay dormant |

## Neutral and spell proposals (for the neutral and spell panels)

- **Spore Cloud (T2, 2 gold): "Ring a slot twice."** A non-Fairy player still gets +2/+2 (as now). A Fairy at Glamour 10 gets +20/+20, or about 20 stats a gold, near Battlegrounds' 28 a gold at turn 12.
- **Boundary Stone (T4, 2 gold): "Ring a slot three times."** +3/+3 for others, as now.
- **Horseshoe stays as written** ("Next fight: halve the Ring across from a slot"). It is the anti-Fairy answer and must stay in the pool.
- **Rainbow's End** is retired with Rainbow.
- **Fit notes:**
  - Cricket Busker (gold per spell) and Pipistrelle Echo (a Ring spell aimed at it also rings the slots beside it) are strong partners. Watch Pipistrelle: one Spore Cloud becomes six Rings.

## What changed from pass 2

| Card | Pass 2 | Pass 3 | Why |
|---|---|---|---|
| Nan Toadstool | Ring this slot +1/+1 | Ring a slot next to this (Glamour-sized) | Reaches an occupied throne without shuffling units |
| Rainbow Chaser | Rainbow pot | Stores 1 gold per turn you Ring | Economy tied to the engine; Rainbow retired |
| Hedge Witch | Hex 1 + 1 per spell, capped at tier | Hex 10% + 5% per spell | Flat answers fade at scale; tier cap removed |
| Hob-in-the-Hearth | +1 Health to the units in front | Shield to the units in front | A stat-holder for the front throne; flat buffs fade |
| Sally Spore | Ring the nearest empty slot | Ring this slot | One Ring a turn, aimed by where she stands; grows the throne |
| Cradle Fetch (T3→T2) | Becomes a base copy of the unit behind | Gains half the biggest Ring behind | A twin that scales with the throne; cheap early, kept late |
| Lob-Lie-by-the-Fire | +1 Attack beside | Rings the slots beside | Scale-consistent growth; end slots focus |
| Silky (T4→T3) | Ring the leaving Shy unit's slot +2/+2 | Ring it and Glamour +1 | The thank-you turn feeds Glamour, earlier |
| Cluricaun | Rainbow; +1 Attack on painted slots | Cleave on the throne's unit | Concentration needs a stat-holder |
| Old Moth Annis (T2→T4) | +1 Attack behind | End of Turn: Glamour +1 | The tribe's clock, started after the early game |
| Will-o'-the-Wisp | 1/1 Wisps into empty Rings | A Wisp refills the throne once a fight | The carry holds its stats |
| Changeling | Swap until it attacks once | Same; golden attacks twice | Already proportional |
| Lady Belladonna | Nightshade across, or two from the back row | Nightshade on the biggest enemy | One of the pool's few any-row answers |
| Reel-Mistress | Rings dance, past the cap | Same, no cap; golden moves twice | The wide route's multiplier |
| Fairy Monarch | Rings under Fairies +1/+1 more | After you Ring a slot: Glamour +1 | The late compounding layer |
| Queen of Elfland | Destroy units behind; other Fairies share their stats | Destroy units behind; double your biggest Ring | Concentrate, not spread |

Rules removed: the Ring cap (8.5.4), the Hex tier cap, Rainbow and Bands. Rule added: Glamour. Shy is unchanged.
