# Bog folk, pass 3: the Peat (engine-first design)

One designer's entry for the Bog folk panel (Track C, `docs/ideation/plan-scale-rework.md`). Angle: **engine first**. This is a design on paper only; nothing here has run in Godot. The board numbers come from a rough paper model in this folder, `bog-engine-model.py` (`python3 -I bog-engine-model.py`, with options `r=`, `offer_cost=`, `king_mult=`, `tiddy=`, `arrive=`, `hits=` and `verbose=1`). It runs scripted lines with guessed hit counts and no fights, so its numbers show the scale of the curve. They are not measurements.

## The pitch

The bog gets deeper every time you feed it. **The Peat** is one number for the whole tribe. It starts at 1, and it rises only when you pay for it: the Peat Cutter hands you a Turf each turn, and casting it costs 3 gold and raises the Peat by 1. Every Bog folk reward is "gain the Peat", which means +Peat/+Peat permanently. Toads gain it when the enemy they Mire bites them (**Swell**). Frogs gain it when they Snap. Once Tiddy Mun arrives, every Bog folk gains it at the end of each turn.

So the toads still decide who fights whom, and now every fight they hold makes them bigger. The Prima Donna, who glues three enemies to herself, becomes the carry. The Peat King doubles every Swell. The Lantern Man drags the enemy's biggest unit into the mud from any row and halves it, so the tribe stays the answer to carries at any size.

Every turn asks one question: **do I cut peat or buy tempo?** A Turf costs as much as a unit. It loses this fight's stats and pays a little in every fight after.

*Similar to:* Battlegrounds' Quilboar Blood Gems, which give one standard reward that grows all game. Brann Bronzebeard for the King. Elementals' "this game" buffs for Tiddy Mun. Magic's Provoke, as before, for Mire.

## Why this fixes what's wrong now

| Problem now (`fundamentals.md` §1, `card-audit-birds-bog-fairies.md`) | Pass 3 answer |
|---|---|
| 9 of 13 Bog payoffs last one fight only, and they are invisible in the shop | 10 of 16 cards now grow something permanent: unit stats, the Peat or Tiddy's tribe layer. The Peat shows on the tribe icon, and every "gain the Peat" shows its live value. The 5 combat-only cards are the answer kit. |
| Permanent growth is tiny and capped: Bridge Toad +3/+3, Ranocchio once a fight, Tiddy twice a fight, Cutter "three times in all" | All of those caps are gone. Growth is limited only by how often the Mired enemy attacks, and the Peat rises only from gold. |
| The whole tribe has no gold-to-stats channel (audit assumption 10) | Turfs turn gold into the Peat, which feeds every gain. Pretender's gold and the Prince's spell discount feed the Turfs. |
| No concentration: Bog was built as an answer, not a concentrator | The Prima Donna holds three Mired enemies, so she gets about three Swells a fight. With the Chorus beside her she gets twice that, and with the King twice again. She holds 30–47% of the board in the model, and Battlegrounds' median is 33–35%. |
| Flat answers lose value as numbers grow (audit assumption 4) | Bitter becomes proportional (a quarter of the attacker's Attack). Bufo and the Lantern Man halve. Sal's damage, Hopkin's Attack and the allies' extra attacks all grow with the Peat or the layer. |
| Bog's payoffs fire when walls are hit, and walls died first (pass 2 root cause) | Swell resolves before the hit, after Bitter. A wall that swells is bigger when the blow lands, so holding a carry is how a wall survives. |
| New tiers don't feel like progress | The T5 and T6 cards raise the rate, not just a body. Tiddy's layer reaches new Bog folk too. Bodies still arrive small, which is a known gap (the levers section). |

## Rules (new or changed)

**Mire** is unchanged, including the wait. *Reminder:* "Start of Combat: the enemy across must attack this while this lives. That enemy swings first."

**Snap** is unchanged. *Reminder:* "This attacks the Mired enemy with the most Attack, wherever it stands."

**Bitter** (changed: proportional). *Reminder (13 words):* "When an enemy attacks this, it first loses a quarter of its Attack."
- Details: round the loss up, and stop at 1 Attack. Bitter applies on every attack, at declaration, as now.
- A unit either has Bitter or it doesn't. Lent Bitter doesn't stack with its own.
- Early on it plays like today's Bitter 1–2: a 3-Attack hit loses 1 and a 6-Attack hit loses 2. At round 12 it takes 13 off a 50-Attack hit, and at round 15 it takes 45 off a 180-Attack hit.
- The fraction is the answer side's lever (sweep ⅕, ¼ or ⅓).

**Swell** (new trigger keyword). `Swell: X` means "when an enemy this Mires attacks this, do X". *Reminder (10 words):* "When an enemy this Mires attacks this, before the hit."
- **Timing:** at attack declaration, after Bitter and before damage. So the gain can save the wall. It is still permanent if the hit then kills the wall.
- It fires on every such attack. There is no limit: the number of times the Mired enemy attacks is the limit, and the attack cap bounds that.
- A unit can have Swell more than once (its own plus one lent by the Chorus). Each copy triggers.
- Swell is on 8 cards (Bridge Toad, Gideon, Jenny, the Prima Donna, the Peat King, the Lantern Man, the Prince Restored, and Swell lent by the Chorus). "Swell:" replaces "After the enemy this Mires attacks this:", which saves 7 words per card. That meets the keyword budget.

**The Peat** (new tribe number, this game). *Reminder (8 words):* "Starts at 1. Gain the Peat: +Peat/+Peat permanently."
- Each player has their own Peat. It is shown on the Bog folk tribe icon, beside the tribe bonus. Card text that says "gain the Peat" shows its live value: "gain the Peat (+10/+10)".
- **Raise the Peat by N** adds N. Only Turfs raise it.
- "Gain the Peat twice" means +2×Peat/+2×Peat.

**Turf** (new Created spell, 3 gold, `pool: false`). Text: "Raise the Peat by 1." The Peat Cutter adds one to your hand at Start of Turn. Turfs can be kept and cast later, and the hand limit is the only brake. Art: a crop of the turf stack already in the Peat Cutter's portrait.

**Biggest** means most Attack plus Health; ties go in reading order (Track B's "biggest enemy in any row" selector).

**Order at one attack declaration:** the attack's own bonuses, then Bitter, then Swell effects in this order: gains, halving, then queued replies. Then the damage exchange. Gideon's reply and Jenny's ally attack are queued attacks (`queue_attack`) after the hit, as today, and a counter never triggers another counter.

## The engine

### How it compounds

Each round the board grows by about **Peat × (Swells a fight × King multiplier + 7 with Tiddy) × 2**.
- **The Peat** rises linearly with gold invested: one Turf per Cutter per turn, 3 gold each.
- **Swells a fight** rise as you assemble mirers that Swell. One Toad gives about 1, Gideon and Jenny add about 1 each, the Prima Donna about 2.5, and the Chorus doubles one of those. The Peat King then doubles everything.
- **Tiddy Mun** adds the Peat to every Bog folk each turn, including Bog folk bought later.

A rising rate times a rising number of applications gives cubic board growth. The previous pass found that a cubic curve fits Battlegrounds' September 2025 shape well (see `birds-engine.md`). The Peat is fed only by gold, so a lead doesn't raise its own rate. That is why it can't snowball by itself.

### The rate parameter: **r, the Peat a Turf adds**

The lever sweep picks the value. In the paper model below, the Diva line uses default levers and the board totals are permanent stats at the round's fight.

| Round | 6 | 9 | 12 | 15 |
|---|---|---|---|---|
| Battlegrounds Sept 2025 mean (R15 = R14 × 1.5) | 53 | 194 | 759 | ~2,600 |
| Bramble bots today, median | 52 | 92 | 133 | ~165 |
| **Bog Diva line, r = 1** (one Cutter, Tiddy R9, Diva R10, King R12) | **54** | **197** | **827** | **2,251** |
| Bog greedy (Cutter R3, second Cutter R6, every Turf) | 67 | 192 | 880 | 2,682 |
| Bog tempo line (permanent stats only; its answers don't show) | 37 | 111 | 415 | 1,215 |
| Bog highroll (golden Cutter R6, golden Diva R10, King R11) | 73 | 198 | 1,205 | 3,831 |
| Diva line, r = 2 | 59 | 299 | 1,480 | 4,206 |

- **Per unit:** the Diva line is about 14/14 at R9, 59/59 at R12 (with the Diva at 127/133) and 161/161 at R15. That is the brief's target: about 50/50 at R12 with a carry well above it, and units in the hundreds by R14–16.
- **Growth a round:** ×1.6 from R9 to R12 and ×1.4 from R12 to R15. The model's late game is flatter than the target because it doesn't roll for goldens. In play, surplus gold buys triples of the Diva, Gideon and the Chorus, which doubles their Swells.
- **The biggest unit's share:** 31% on the Diva line and 46–47% on the highroll.
- **Sensitivity:** changing the hit guess by ±12% moves R12 to 767–926.

Secondary levers, in the order I'd sweep them:

| Lever | Default | Diva line R12 / R15 at the other values |
|---|---|---|
| Turf cost (gold per Peat; also the price of the decision) | 3 | 2 → 924 / 2,348 (R6 63). 4 → 677 / 2,032 |
| Peat King multiplier | ×2 | ×1.5 → 763 / 1,947 |
| Tiddy's layer | Peat a turn | off → 547 / 1,509 |
| Arrival bonus (Bog folk you buy gain the Peat once per tier) | off | on → 1,133 / 2,557, with R6 at 78 |
| Bitter fraction | ¼ | ⅕ or ⅓; this tunes the answer side, not the curve |

A fractional r can run inside the sweep, with the Peat shown rounded down. If the sweep lands between 1 and 2, ship r = 1 and lower the Turf's cost instead, so the card always says "by 1".

### The turn it comes online: **round 9**

On a typical line:
1. A Peat Cutter lands at R3–R4, and you cast your first Turf at R5.
2. Bridge Toad, Gideon and Jenny are swelling by R7.
3. Tiddy Mun (T5) arrives at R9 and the Prima Donna at R9–R10.

From R9, one Turf at 3 gold returns about 2 × (5 Swells + 7) = 24 stats a round, every round. That beats a fresh 3-gold body (about 28 stats at R9) within two rounds. A highroll is online at R7 (two Cutters, a golden Cutter, or Peat 6 by R8). A lowroll comes online at R11 (no Cutter before R7).
- **Behind at once (R4–R7).** The Cutter is a 2/4, and each Turf is a unit you didn't buy, about 15% of a round-5 board.
- **Level by R7–R8.** A Turf at R5 pays about +4 to +6 stats a round from 2–3 Swells, so it pays back in about two rounds.
- **Clearly ahead from R10.** Tiddy, the Diva and later the King multiply every Peat point.

Bog runs a mid clock. Birds run a later one (`birds-engine.md`).

### The decision it creates, every turn

**Cut peat or buy tempo?**

| Turn | Cut peat (invest) | Buy tempo |
|---|---|---|
| R5, 8 gold | Turf + one unit. Peat 1 → 2, so every Swell now gives +2/+2. | Two units, about +10 stats in this fight |
| R8, 10 gold | Two Turfs, no roll. Peat 3 → 5. | Tier up to 5 a turn early, or roll for Jenny |
| R11, 10 gold | Three Turfs. With the Prince, that's 8 gold. | Roll for the golden Diva |
- Late game, gold stops being tight, and the question becomes "Turfs or rolls for goldens?"
- There is a second, smaller decision: **frogs or walls.** A Snap frog or Spitfire Sal that kills a Mired enemy before it swings wins the fight sooner (tempo), but costs that toad its Swell (growth). Vaulting Hopkin in the back row strikes first, so he is the tempo choice. In the front he waits his turn.
- **Rule of thumb for players and bots:** cast a Turf when 2 × (Swells a round + 7 if Tiddy) × rounds left is more than a 3-gold unit gives this round.

## The 16 cards

The tier spread is unchanged at 3 / 3 / 3 / 3 / 2 / 2. Every card keeps its creature, name, portrait, tier and printed stats; only its text changes.
- Tokens: the Prince Restored is kept with new text, and the Turf is new.
- The Peatling token is retired. Its art is kept for the variation listed under the Peat King.

**"Typical board"** below means the scripted Diva line at default levers:
- Peat is 5 / 10 / 13 at R9 / R12 / R15.
- Tiddy's layer is +0 / +20 / +53 on every Bog folk.
- Enemy units average about 14/14, 54/54 and 185/185, and an enemy carry is about 20/20, 125/125 and 400/400.

Cards that aren't on that line at a round are estimated with the same Peat and layer.

### Tier 1

**Bridge Toad** (T1, 1/3). *Mire. Swell: gain the Peat.* (5 words)
*Golden 2/6:* Mire. Swell: gain the Peat twice.
- **Condition:** the enemy across attacks it, which the lock and the wait make happen in almost every fight where an attacker stands there.
- **Payoff:** +Peat/+Peat a Swell, about one a fight. Kept from R1: about 20/22 at R9 (33/35 with the Chorus beside it), 65–80 a stat at R12, and 135–150 a stat at R15.
- **Permanence:** permanent. It shows on the board and in the scout.
- **Enabler:** makes a patch for Snap, Sal and the Lantern. It's a target for the Chorus's second Swell before the Diva arrives.
- **Concentrates:** yes, on itself. It is the early carry and teaches the tribe in one card.

**Warty Nan** (T1, 1/3). *Bitter. Your units beside this have Bitter.* (7 words)
*Golden 2/6:* Bitter. Your units in this row have Bitter.
- *Wording-guide note:* Bitter has no number, so the golden doubles her reach (beside, at most 2 units, becomes the row, at most 3).
- **Condition:** she or a unit beside her is attacked.
- **Payoff:** each attacker loses a quarter of its Attack before each hit. That is about −4 a hit at R9, −13 at R12 and −45 at R15, or roughly −10 / −35 / −100 enemy Attack over a fight on the walls beside her.
- **Permanence:** combat only. Her body grows only through Tiddy's layer (21/23 at R12, 54/56 at R15).
- **Enabler:** keeps swellers alive for more Swells (Toad, Gideon, the King, borrowed walls), so Gideon's replies land.
- **Concentrates:** no. She protects the unit that does.

**Young Pretender** (T1, 3/2). *Snap. After this kills a Mired enemy: get 1 gold next turn.* (11 words)
*Golden 6/4:* the same, get 2 gold next turn.
- **Condition:** its Snap kills a stuck enemy. It is likeliest early and against enemies that Bitter and Sal have softened.
- **Payoff:** about 0.3 gold a fight, so roughly a Turf every ten fights. Body 3/2, plus Tiddy's layer late.
- **Permanence:** economy.
- **Enabler:** Turfs, and the first gold of a greedy line.
- **Concentrates:** no. It is the tempo opener, and you sell it by R6–R8.

### Tier 2

**Madame Bufo** (T2, 1/4). *Mire. Bitter. If her Mired enemy kills her, it loses half its Attack.* (13 words)
*Golden 2/8:* … it loses three quarters of its Attack.
- **Condition:** the enemy across kills her, which it usually does.
- **Payoff:** Bitter, then halving. At R9 a 20-Attack carry ends at 7. At R12 a 125-Attack carry goes to 94 and then to 47. At R15, 400 goes to 300 and then 150.
- **Permanence:** combat only. She is the sacrificial diva.
- **Enabler:** shrinks the carry so the Snap frogs, Gideon and Jenny's allies finish it.
- **Concentrates:** no. She is the tribe's earliest answer to concentration, and halving keeps her relevant at every scale.

**Vaulting Hopkin** (T2, 3/1). *Snap. In your back row, this attacks first, with double Attack.* (11 words)
*Golden 6/2:* … with triple Attack.
- **Condition:** he's in your back row.
- **Payoff:** a first strike at the biggest stuck enemy, before it swings. That's 6 damage at R9, about 46 at R12 and about 112 at R15, with Tiddy's layer.
- **Permanence:** combat only.
- **Enabler:** the tempo half of the "frogs or walls" choice. He kills the carry before it bites, but then the toad holding it doesn't swell.
- **Concentrates:** no.

**The Peat Cutter** (T2, 2/4). *Start of Turn: get a Turf.* (5 words)
*Golden 4/8:* Start of Turn: get two Turfs.
- **Turf** (Created spell, 3 gold): *Raise the Peat by 1.*
- **Condition:** none to get the Turf. Casting it costs 3 gold, and that is the decision.
- **Payoff:** with one Cutter and a Turf most turns, the Peat goes from 1 to 5 / 10 / 13 at R9 / R12 / R15 (6 / 11 / 18 with two Cutters). Each Peat point is then worth about 2 × (Swells + 7 with Tiddy) stats every round: about 10 a round at R9 and 40–50 at R12 with the King.
- **Permanence:** the Peat is permanent, and it stays if you sell the Cutter. Only new Turfs stop.
- **Enabler:** every "gain the Peat" card, plus Sal.
- **Concentrates:** neither. It is the rate.

### Tier 3

**Gideon, Basso Profundo** (T3, 2/6). *Mire. Swell: gain the Peat and attack it back.* (9 words)
*Golden 4/12:* Mire. Swell: gain the Peat twice and attack it back.
- *Details:* the reply comes after the hit, if he lives.
- **Condition:** the enemy across attacks him.
- **Payoff:** bought at R5: 17/21 at R9, 71/75 at R12, 177/181 at R15. He also replies once a Swell for his own Attack, so about 70 damage at R12.
- **Permanence:** permanent growth. The reply is combat only.
- **Enabler:** a second carry for the Chorus. He is Jenny's best neighbour, because his Attack lands on her Mired enemy.
- **Concentrates:** yes.

**The Natterjack Chorus** (T3, 3/4). *Your units beside this have Mire and "Swell: gain the Peat."* (11 words)
*Golden 6/8:* … "Swell: gain the Peat twice."
- **Condition:** units beside it in the same row, and enemies across from them.
- **Payoff:** a sweller beside it gets a second Swell. Beside the Diva at R12 that is about +30/+30 more a fight, and +80/+80 at R15 with the King. Or it turns two plain neighbours, of any tribe, into swellers: a Hedgerow Hunker wall becomes a growing toad.
- **Permanence:** the gains are permanent.
- **Enabler:** the Diva, Gideon, the King, borrowed walls, and more patches for Snap, Sal and the Lantern.
- **Concentrates:** it's your choice. Beside one sweller it concentrates; beside two non-mirers it spreads. Lent Mire also makes the borrower wait once.

**Spitfire Sal** (T3, 1/3). *Start of Combat: deal damage equal to the Peat to each Mired enemy.* (12 words)
*Golden 2/6:* … twice the Peat …
- **Condition:** Mired enemies at Start of Combat.
- **Payoff:** about 5 to each of 4 at R9 (20 in total, a third of an average enemy's Health), 10 to each of 5 at R12 (50), and 13 to each of 5 at R15 (65).
- **Permanence:** combat only. She fades at R15, as T3 cards should.
- **Enabler:** softens enemies for Snap and Pretender's gold. Like Hopkin, she is the tempo side of "frogs or walls", since a kill before the swing costs a Swell.
- **Concentrates:** no.

### Tier 4

**His Highness, Allegedly** (T4, 3/5). *Snap. After a Mired enemy dies: get a kiss, once a fight. Third kiss: become The Prince Restored.* (18 words, unchanged)
*Golden:* … become a golden Prince Restored.
- **The Prince Restored** (token, 6/7, Bog folk): *Mire. Swell: gain the Peat. Your first spell each turn costs 1 less.* (13 words). *Golden 12/14:* gain the Peat twice … costs 2 less.
- **Condition:** three fights with a Mired death each. Kisses are kept between fights, as now.
- **Payoff:** a new sweller, about 46/47 at R12 (just turned) and 152/153 at R15. The first Turf each turn costs 2 gold (1 if golden), or about +0.5 Peat a turn for the same gold.
- **Permanence:** a permanent transform. Stats are kept.
- **Enabler:** Turfs, Harvest Supper and any spell.
- **Concentrates:** partly; it's one more sweller.

**Jenny Greenteeth** (T4, 3/5). *Mire. Swell: gain the Peat, and your highest-Attack unit beside this attacks it.* (14 words)
*Golden 6/10:* Mire. Swell: gain the Peat twice, and your units beside this attack it.
- **Condition:** the enemy across attacks her.
- **Payoff:** bought at R7: 15/18 at R9, 69/72 at R12, 176/179 at R15. Each Swell also gives her strongest neighbour an extra attack on that enemy: about 70 damage at R12 with Gideon beside her, and 130 with the Diva.
- **Permanence:** permanent growth. The extra attack is combat only.
- **Enabler:** gives a concentrated neighbour extra attacks, which is the carry's payoff.
- **Concentrates:** yes, both on herself and by making the carry act more.

**Signor Ranocchio, Tenor** (T4, 3/4). *Snap. After this attacks a Mired enemy: gain the Peat.* (9 words)
*Golden 6/8:* … gain the Peat twice.
- **Condition:** a stuck enemy is alive when he attacks, about 1.4 times a fight.
- **Payoff:** bought at R8: 17/19 at R9, about 72/74 at R12 and about 155/157 at R15 if kept. On the tempo line he is the biggest unit at R12 (44/46).
- **Permanence:** permanent.
- **Enabler:** the frog route's carry. It rewards having more patches.
- **Concentrates:** yes. He is the back-row frog carry, and Snap aims him at their best stuck unit.

### Tier 5

**Tiddy Mun** (T5, 3/6). *End of Turn: your Bog folk gain the Peat this game.* (10 words)
*Golden 6/12:* … gain the Peat twice this game.
- *Details:* this raises the Bog folk tribe bonus (the Supper layer, 5.2.9), so it reaches Bog folk in hand and ones you get later. It doesn't count toward Supper's +3/+3, and it stays if Tiddy is sold.
- **Condition:** none, but it is only as good as your Peat.
- **Payoff:** bought at R9, the layer is +20/+20 on every Bog folk by R12 (about +280 board stats) and +53/+53 by R15 (about +740).
- **Permanence:** permanent and inherited. This is the tribe's progression piece.
- **Enabler:** every Bog folk that doesn't Swell (frogs, Bufo, Nan, Hopkin, Sal, the Cutter) keeps up because of it.
- **Concentrates:** no. It grows the six supports, while the Swells build the carry.
- *Hook:* the fen spirit who holds the water level. Now the water rises for everyone.

**The Prima Donna** (T5, 2/8). *Mire the slot across and the slots beside it. Bitter. Swell: gain the Peat.* (15 words)
*Golden 4/16:* … Swell: gain the Peat twice.
- **Condition:** three enemy slots across and beside her, with attackers in them.
- **Payoff:** about 2.5 Swells a fight, or 5 with the Chorus. Bought at R10: 127/133 at R12 (31% of the board) and 347/353 at R15. Golden on the highroll: about 275/287 at R12 and 881/893 at R15.
- **Permanence:** permanent.
- **Enabler:** three Mired enemies for Snap, Sal and the Lantern, and their deaths give His Highness his kisses.
- **Concentrates:** **yes. She is the carry.**
- **How she holds her stats:** every attacker loses a quarter first, she swells before each hit, and her Attack kills each enemy she holds on contact, so it never swings twice.
- **Placement:** in F2/F3 she glues three of their front row to herself. In B2 she pulls their whole back row onto her, past your front.

### Tier 6

**The Peat King** (T6, 5/9). *Mire. Swell: gain the Peat. Your Swells trigger twice.* (9 words)
*Golden 10/18:* Mire. Swell: gain the Peat twice. Your Swells trigger three times.
- **Condition:** any of your units swells.
- **Payoff:** doubles every Swell, including Gideon's reply and Jenny's ally attack. That is about +150 to +200 board stats a round at R12 and +350 at R15. His own body is 45/49 at R12 and 151/155 at R15.
- **Permanence:** the gains are permanent.
- **Enabler:** every Swell card. He is Brann for the bog.
- **Concentrates:** he multiplies whatever you've concentrated, so the Diva doubles.
- *Variation:* golden, also "after a Mired enemy dies: a Peatling with the Peat's stats rises nearest this", to keep the Peatling art in use.

**The Lantern Man** (T6, 4/8). *Mire the biggest enemy, in any row. Swell: halve its Attack.* (11 words)
*Golden 8/16:* Mire the two biggest enemies, in any row. Swell: halve its Attack.
- *Details:* his patch is laid first at the bell. Halving comes after Bitter.
- **Condition:** the biggest enemy, wherever it stands (Track B selector). It must swing at him.
- **Payoff:** each swing at him is halved first. At R12 a 125-Attack carry hits for 62, or 47 with Nan's Bitter. At R15, 400 becomes 200, or 150 with Bitter. If he survives, it halves again on the next swing.
- **Permanence:** combat only.
- **Enabler:** holds the enemy carry in place for Snap frogs, Sal and Hopkin.
- **Concentrates:** no. This is the tribe's answer to concentration, and the only Bog card that reaches any row.
- *Hook:* the light over the fen that leads travellers off the path, and only the biggest ones follow.

### Word counts

- Card texts run 5–18 words, with a median of 11 (guide: median ≤ 11, p90 ≤ 17, max 22).
- His Highness (18 words) is unchanged.
- The Prima Donna and Jenny (15 and 14 words) are the longest new texts.

## Routes

### The carry route: "The Diva" (engine line)

At R12 on the model line (Peat 10, layer +20), every enemy slot is Mired:
```
F1 Tiddy Mun 23/26   F2 The Prima Donna 127/133   F3 The Peat Cutter 22/24   F4 Jenny Greenteeth 69/72
       B1 Gideon 71/75        B2 The Peat King 45/49        B3 The Prince Restored 46/47
```
- The Prima Donna in F2 Mires their F1, F2 and F3. Jenny takes their F4. Gideon, the King and the Prince Mire their B1, B2 and B3.
- No enemy is free, so Tiddy and the Cutter aren't attacked while the locks hold.
- The King doubles every Swell, so each locked swing makes the Diva +20/+20 before it lands. At R10–R11 the Chorus beside her did the same job.
- Their attackers shrink by a quarter, hit a swollen diva, and die to her reply.
- Total 827, about level with the Sept 2025 curve (759 at R12). By R15 the same board is 2,251, with the Diva at 347/353.
- *Model shortcut:* the Prince is shown turned at R12. Real kisses take three fights, so expect him a round or two later.

**When it's right:** a Cutter in the first four turns, a full Bog board by R8, and Tiddy and the Diva both seen at T5. **When it's wrong:** opponents who leave empty slots, Eggs or 0-Attack units across your swellers. Then switch to frogs.

### The non-carry route: "The Drowning" (tempo and answers)

At R9 on the tempo line (T5 since R8, Peat 3), its strongest stretch:
```
F1 Bridge Toad 11/13   F2 Madame Bufo 1/4   F3 Gideon 10/14   F4 Jenny Greenteeth 10/13
       B1 The Peat Cutter 2/4   B2 Signor Ranocchio 10/12   B3 His Highness 3/5
```
- It climbs fast (T6 at R10), casts few Turfs, and wins fights by deciding who fights whom.
- Bufo sits across their best hitter: Bitter, then halving when it kills her. Gideon replies to every swing.
- Jenny's strongest neighbour hits her Mired enemy each time it swings, and Ranocchio Snaps their best stuck unit.
- From R11 the Lantern Man lures and halves their carry, wherever it stands.
- Its permanent stats trail the engine line (111 against 197 at R9, 415 against 827 at R12). Its strength is in combat, which the model doesn't count.
- It must add Tiddy (R10) and the Diva (R12) and keep casting Turfs, or it falls off by R14 (1,215 at R15).

## Answers to other tribes' carries

| Carry type (current examples) | What Bog does |
|---|---|
| Back-row pile (a Hedgerow Pass carry, a Birds Redbreast) | The Lantern Man lures it from any row. A B-slot mirer bogs the carry across, and the Prima Donna in B2 pulls their whole back row onto her. Snap reaches it wherever it stands. |
| Front-row giant (a Hunters pack leader, a Queen-fed Fairy) | Put Bufo across it: Bitter, then halving. Gideon replies on every swing. Hopkin hits it first. |
| A fight-only Attack pile (Granny in the Oozes) | Bitter shrinks it by a quarter a swing, and the Lantern halves it. Each swing it spends on a toad is a swing that doesn't hit a support. |
| Bellies and refills (Oozes) | Bog's best matchup. Each body that comes out lands on the same patch, is Mired, and attacks the same toad, so it swells again. |
| A wide token board (Hedgerow summons, Wobbly Drips) | Bog's weak point: Mire holds a few and Bitter takes 1. But every token that lands on a patch swings into a toad, so the walls still swell. |

At the target scale, a Mired R12 carry of 125/125 takes Hopkin's 46 first, then Ranocchio's 72 and the Lantern's halving, and dies in the first cycle. So Bog's answers grow with its own engine.

## Weak points (the counterplay)

- **Starve the Swell.** The opponent puts empty slots, Eggs, 0-Attack or Stalled units across Bog's swellers. Their scout shows Bog's last layout, and Bog's shows theirs, so it is a mind game, and a skill one. This is also why Birds' Nests are Bog's hardest matchup.
- **Kill the wall before the lock.** Start of Combat shots across (Sergeant-at-Conkers), and any neutral that hits "the biggest enemy", will find the Diva.
- **Proportional answers on the Diva:** Nightshade halves her Health each hit, the Changeling swaps her, and Ichneumon Wasp poisons her.
- **Gold-hungry.** Turfs compete with tier-ups, so Bog climbs a turn or two late. A fast-tier lobby punishes it at R6–R9.
- **The Bog mirror** can drag on: facing mirers lock each other and both swell. Watch fight length and attack-limit ties.

## Two highroll moments a player will remember

1. **"The Diva's aria."** Round 13. You have a golden Prima Donna in F3, a golden Natterjack Chorus beside her, and the Peat King, with the Peat at 12. Three of their front row are glued to her. Each swing triggers her own Swell (gain the Peat twice) and the Chorus's (twice), and the King doubles both, so she gains 8 × 12 = **+96/+96 before each hit lands**. After three swings she is +288/+288 up in one fight, she has killed all three on contact, and she keeps it all. It takes golden copies of two cards plus the King, which I'd guess is the top 1–3% of Bog games.
2. **"Into the bog."** Round 14. Their 800/800 carry is hidden in B3 behind two Taunts. Your Lantern Man in B2 lures it, and Warty Nan beside him lends Bitter. Its first swing goes 800, then 600 after Bitter, then 300 after the halving, before it hits. The Lantern drowns, but the carry is now at 300 Attack for the rest of the fight. Ranocchio and Hopkin Snap it every cycle, and it dies having killed one unit.
- *A third, for greedy players:* "the cash-in". You save 8 Turfs and 20 gold, then at R11 you turn the Prince golden and cast them all. The Peat goes from 9 to 17, and Tiddy gives every Bog folk +17/+17 that End of Turn.

## Harness lines (two line policies)

Ids are content ids. "Buy and keep" means buy when offered and keep while the board has room, earlier in the list winning a slot. Placement hints go to the placer.

### Line 1: `bog_tempo` ("The Drowning")
- **Priority (buy and keep):**
  1. `prima_donna`
  2. `lantern_man`
  3. `jenny_greenteeth`
  4. `signor_ranocchio`
  5. `gideon`
  6. `madame_bufo`
  7. `vaulting_hopkin`
  8. `tiddy_mun`
  9. `peat_king`
  10. `spitfire_sal`
  11. `his_highness`
  12. `natterjack_chorus`
  13. `bridge_toad`
  14. `young_pretender`
  15. `peat_cutter`
  16. `warty_nan`
  - Neutral: `harvest_supper`, aimed at Bog folk.
  - Sell first: `young_pretender` (from R5), then `warty_nan`, `vaulting_hopkin` and `spitfire_sal` once T5 cards need the slot.
- **Climb:** T2 R2, T3 R4, T4 R6, T5 R8, T6 R10. Always climb when you can afford it from R4.
- **Gold:** never save before R9; spend down to 0–2.
  - Take one `peat_cutter` from R6, only on a full board or when nothing in the list is offered.
  - Cast at most one Turf a turn, only with 3+ gold left after the turn's buy and climb. Never skip a climb for a Turf.
  - From R11, cast every Turf held.
- **Placement:** Bufo across the scouted top-Attack enemy, Lantern Man in the back, Hopkin and Ranocchio in the back row, and mirers never across Eggs or empty slots.
- **Engine flag:** off.

### Line 2: `bog_diva` (engine and carry)
- **Priority (buy and keep):**
  1. `prima_donna`
  2. `peat_cutter` (first copy)
  3. `tiddy_mun`
  4. `natterjack_chorus`
  5. `peat_king`
  6. `gideon`
  7. `bridge_toad`
  8. `jenny_greenteeth`
  9. `his_highness`
  10. `peat_cutter` (second copy, before R8 only)
  11. `madame_bufo`
  12. `signor_ranocchio`
  13. `warty_nan`
  14. `lantern_man`
  15. `spitfire_sal`
  16. `vaulting_hopkin`
  17. `young_pretender`
  - Neutral: `harvest_supper`, and Cricket Busker, which makes each Turf effectively 2 gold.
  - Triples to chase from R11: `prima_donna`, `natterjack_chorus`, `gideon`.
- **Climb:** T2 R2, T3 R5, T4 R7, T5 R9, T6 R11–R12. Save for a climb one turn ahead (the save threshold is the next climb's cost on the turn before it).
- **Gold:** from the turn the first Cutter lands, cast every Turf held whenever 3+ gold is left after the turn's core buy. On a climb turn, climb first.
  - Bank at most 3 Turfs.
  - From R12, put surplus gold into rolls for the triples above before casting extra banked Turfs, unless Tiddy is on board.
  - Sell a Cutter only once the Peat is 10+ and the slot is needed for a T5 or T6 sweller.
- **Keep:** Bridge Toad until a T5 or T6 sweller needs its slot. The Chorus beside the Prima Donna, or beside the biggest sweller before she arrives.
- **Placement:** the Prima Donna in F2/F3, or in B2 when their back row holds 2+ attackers. The King and Gideon on the other front slots, and Nan beside whichever wall the scout says holds their biggest.
- **Engine flag:** on.

## Engine support needed

| Need | For | What |
|---|---|---|
| `swell` trigger | 8 cards | At attack declaration, after `bitter`, when the attacker stands on a patch this unit made. One fire per instance; granted copies (`bog_aura`) count. The pass 2 prototype already put a "Tiddy first" hook in that slot. |
| `peat` player number | Peat, Turf, Sal, Tiddy | Per player, starts at 1. Effects `raise_peat` (amount × r) and `gain_peat` (a permanent buff of Peat × n). `per: peat` for Sal's damage. Shown on the tribe icon, and as live values in card text. |
| `turf` spell | Peat Cutter | Created, cost 3, `pool: false`, from `add_card` on `start_of_turn`. The Prince's discount applies (existing `spell_cost`). |
| Tribe layer by Peat | Tiddy Mun | Raise the Bog folk tribe bonus (the Supper layer) by the Peat at `end_of_turn`, as its own source outside Supper's +3/+3. |
| Trigger multiplier | Peat King | "Your Swells trigger twice" (golden three times), Brann-style, applied to Swell triggers only. |
| Proportional Bitter | Bitter | Track B proportional debuffs: a quarter, rounded up, floor 1. Remove Bitter's number and `once_per_enemy`. |
| Biggest-enemy Mire with bell priority | Lantern Man | Track B's `biggest` selector (any row). His patch is laid before the others at the bell. The Swell effect multiplies the attacker's Attack by 0.5 for the fight. |
| Proportional combat buffs | Hopkin, Bufo golden | ×2 / ×3 Attack in the back row; halving ×0.25 for golden Bufo. |
| Removals | Toad, Cutter, Tiddy, Ranocchio, Peat King, Prima Donna, Lantern, Chorus | Bridge Toad's `permanent_buff_cap`; the Cutter's gold and "three times"; Tiddy's and Ranocchio's limits; the Peatling summon; the Prima Donna's once-per-enemy; the Lantern's Mired-count aura; the Chorus's Bitter. |
| Screens | All | A Swell log line ("Madame Bufo swells: +10/+10"). The Peat on the tribe icon. A shop preview of Tiddy's layer on Bog folk. Track B's phone check of 3- and 4-digit stats. |
| Bots and lines | Harness | Turf casting by the rule of thumb above. Swellers placed across real attackers, never across Eggs, 0-Attack units or gaps. The Lantern in the back. |

## Risks, loops and calls for the panel

- **Loops:** Swell fires only on attacks, so the attack cap bounds it. The King's doubled replies are counters, which never chain. Jenny's ally attack isn't an enemy attack, so it can't cause a Swell. There is no in-fight loop that needs a limit.
- **Common snowball:** the rate (the Peat) rises only from gold, and gold is flat after Early Spoils. A Bog lead doesn't speed its own rate. The positive loop is survival (bigger walls take more swings), and that is capped by how many enemies attack. I expect no common snowball; the harness should check the round-8 leader's win share.
- **Tail:** golden Diva, Chorus, King and Cutter are the highrolls, and they need triples. That fits the owner's "top 1% at 10×" (9d). The model's highroll line is only 1.5–1.7× the Diva line (1,205 against 827 at R12, 3,831 against 2,251 at R15).
- **Progression bar:** new T5–T6 Bog folk arrive small (a fresh King is 45/49 at R12 against a 59/59 median unit). Their value is a jump in rate. If the playtest's tier-up check fails, turn on the arrival lever ("Bog folk you buy gain the Peat once per tier": the King arrives at 65/69), and accept R6 at about 78.
- **Bitter at ¼ on the Diva** may make her hard to crack without proportional answers. The other tribes' panels and the Track B neutrals should each carry one halving or "biggest enemy" answer.
- **The early overshoot on greedy lines** (R6 at 67 against 52 today) comes from Turfs cast at R3–R4. If the R6 field shows Bog ahead too early, put the Turf at 4 gold before R6, or move the Peat Cutter to T3. The second option would trade Gideon or Sal down to T2.

## What changed from pass 2, card by card

| Card | Pass 2 | Pass 3 |
|---|---|---|
| Bridge Toad | +1/+1 after its Mired enemy attacks, up to +3/+3 | Swell: gain the Peat, uncapped |
| Warty Nan | Bitter 1, lends Bitter 1 | Proportional Bitter, lent beside (golden: the row) |
| Young Pretender | unchanged | unchanged (its gold now feeds Turfs) |
| Madame Bufo | Bitter 2, halves her killer | Proportional Bitter, halves her killer (golden: three quarters) |
| Vaulting Hopkin | back row: first, +2 Attack | back row: first, double Attack |
| Peat Cutter | Mire, gold on Mired deaths, three times in all | Start of Turn: get a Turf (Peat +1 for 3 gold) |
| Gideon | counter with +2 Attack | Swell: gain the Peat and attack it back |
| Natterjack Chorus | lends Mire and Bitter 1 | lends Mire and Swell: gain the Peat |
| Spitfire Sal | 2 damage to each Mired enemy | damage equal to the Peat to each Mired enemy |
| His Highness / Prince | Prince: Mire, spell discount | Prince also has Swell: gain the Peat |
| Jenny Greenteeth | −2 Attack, neighbour attacks | Swell: gain the Peat, neighbour attacks (golden: both neighbours) |
| Signor Ranocchio | +1/+1 once a fight | gain the Peat after each Snap at a Mired enemy |
| Tiddy Mun | +1/+1 to the hit unit, twice a fight | End of Turn: Bog folk gain the Peat this game |
| The Prima Donna | 3 patches, Bitter 2 once per enemy | 3 patches, Bitter, Swell: gain the Peat (the carry) |
| The Peat King | Peatlings after Mired deaths, twice a fight | Swell: gain the Peat; your Swells trigger twice |
| The Lantern Man | +3 Attack per Mired enemy | Mire the biggest enemy, any row; Swell: halve its Attack |
| Tokens | Peatling, Prince Restored | Prince Restored, Turf (new); Peatling retired |

## How to reproduce the numbers

`python3 -I build/orchestrator/pass3/bog-engine-model.py` prints the four lines at R6/9/12/15. Add `verbose=1` for every round and unit, or the lever options listed at the top. Its limits:
- no fights and no opponents;
- hits per patch guessed at 1.0 / 1.1 / 1.15 / 1.2 by stage, and 0.85 for the Diva's;
- 85% of patches have an attacker;
- permanent stats only, so Bitter, halving, Snap, Sal and Hopkin don't show;
- triples only on the scripted highroll;
- the 7-slot cap held by scripted sells;
- simple gold with no rolls.
