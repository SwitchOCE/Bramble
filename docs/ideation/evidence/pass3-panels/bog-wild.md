# Bog folk, pass 3: the wild design (identity and delight)

9 Nov 2026, a Track C designer (`plan-scale-rework.md`, Step 1). Angle: identity and delight. No price list was used. Effects are sized by reasoning about boards at rounds 6, 9, 12 and 15 against the target shape (level with today's boards to round 7, then about ×1.5 a round). A small expected-value model backs the sizes: `bog-wild-model.py`, next to this file (`python3 -I bog-wild-model.py`). It is a paper model, not a sim. Its assumptions are listed at its top, and the harness replaces it.

## 1. The pitch

**Everything the bog sinks, it keeps.**

Bog folk still decide who fights whom. At Start of Combat their toads lay mud under the enemy across, and that enemy must attack the toad that holds it. What is new is what happens when the stuck enemy goes under. **The toad that held it swells by half of it, permanently.** Sink their 80/80 boar and your toad is 40/40 bigger for the rest of the game.

That makes Bog folk the one tribe that grows from the size of what it fights:
- **The answer tribe and the engine are the same loop.** Bog grows by sinking the enemy's biggest unit, so its reward for answering a carry is to become one. Every other tribe grows from its own board; Bog grows from yours.
- **It tracks the lobby by construction.** Meals are a share of enemy stats, so Bog rides whatever curve the other tribes reach. It never needs its own price table to keep up.
- **It brakes itself.** A Bog board far ahead eats enemies that are small next to it, so its relative growth slows. A Bog board behind still sinks the small units it holds, and those meals are big next to its own board. Bog is a comeback tribe, and an uncommon snowballer.
- **The swamp opera finally pays off.** Every frog claims to be a prince, and one of them is telling the truth. When His Highness has seen five enemies sink, the curse breaks in the middle of the fight. The units beside him double on the spot, and after the fight he is crowned. As the Prince he does it again every fifteen sinkings.

**Familiar shapes, said plainly.** Swell is closest to Hearthstone's "gain a copy of a minion's stats", aimed at the enemies you kill. Battlegrounds payoffs grow from your own board, not from the size of what you killed. Tiddy Mun is Battlegrounds' "your X trigger twice" template (Brann, Rivendare) on Bog's own keyword. The curse break is a doubler on a counter, like an Avenge (X) that keeps counting between fights.

**What a player sees.** The mud patch and the reed-line from pass 1 stay. New: when a Mired enemy sinks, a bubble of brown light runs along the reed-line into its maker, and the maker swells with a "+41/+41" pop. His Highness wears five lily-pad hearts that fill as enemies sink. The tray preview shows each Swell unit's meal against the scouted board: "If their Boar sinks: Gideon +41/+41."

## 2. Rules

### Keywords

| Word | Reminder (one sentence) | On |
|---|---|---|
| **Mire** (kept) | Start of Combat: the enemy across must attack this while this lives. This waits for it, once. | 9 cards and the Prince |
| **Mired** (kept) | Must attack the unit that mired it. | status |
| **Snap** (kept) | Attacks the Mired enemy with the most Attack. | 4 cards |
| **Swell X%** (new) | When the enemy this Mires dies, this gains X% of its stats permanently. | 6 cards and the Prince; Tiddy names it |
| **Sink:** (new trigger) | After a Mired enemy dies. **Sink (X):** after every X, counting across fights. | 4 cards and the Prince |
| **Bitter X%** (changed) | When an enemy attacks this, it first loses X% of its Attack. | 3 cards and the Peatling |
| **biggest / smallest** (Track B term) | Most / least Attack plus Health. | 3 cards |

### Rulings (for Details and the rulebook)
- **Swell** reads the sunk enemy's stats as it started the fight, before Bitter, Sal or damage, so the tribe's own answers never shrink the meal. A unit that entered mid-fight (a summon, a body out of a Belly) is read as it entered. Each stat is rounded down. A Swell unit gains even if it died earlier in the fight: the gain goes to its recruit copy. It gains nothing if it changed sides. One sinking feeds one maker, because a slot holds one patch.
- **Sink** counts every Mired enemy that dies in your fights, by any hand, win or lose, while the card is on your board. Cards in hand don't count, so holding His Highness delays the curse. A triple keeps the highest count.
- **Bitter X%** keeps pass 2's timing (rule 9.6.0, Bitter hits first). The loss is rounded up, so a 3-Attack hitter still loses 1, and it can't take Attack below 1. **Two Bitters don't add; the bigger one counts.** That replaces "own and lent Bitter stack".
- **The curse break** doubles the units beside His Highness at once, in the fight and on the recruit board: each gains its own current stats permanently. "Beside" means the same row. He becomes The Prince Restored after the fight, keeping his slot and permanent buffs.
- **Lantern Man's Mire** is laid at the bell, before every other patch, under the biggest enemy wherever it stands. A mirer of yours across that slot then lays nothing there (one patch per slot, as now).
- **Jenny's pull** happens at Start of Combat, after the patches are down. The biggest enemy in the row facing hers swaps with the enemy across from her. Each lands on whatever patch is under its new slot, as pass 1's "the patch belongs to the ground" rule says.
- **Spitfire Sal** takes Health, as Nightshade does. It isn't damage, so shields don't stop it.
- **Golden:** percentages double (Swell 50% becomes 100%, Bitter 25% becomes 50%). Doublers go up one step (double becomes triple), as Battlegrounds' golden Brann goes from twice to three times.
- **Removed caps** (owner, 9a and 9d: caps only where a loop needs one): Bridge Toad's +3/+3 ceiling, the Peat Cutter's "three times in all", Ranocchio's "once a fight" and Tiddy's "twice a fight". Two rate limits stay, each with a reason in section 6: the Peat Cutter's once a fight (gold) and the Peat King's twice a fight (summons).

### Reference meals on a typical board

The target median board, with its biggest unit holding a third. Every number below uses this table.

| | R9 | R12 | R15 |
|---|---|---|---|
| Typical enemy board | 146 | 494 | 1,666 |
| Their biggest unit | 24/25 | 82/83 | 277/278 |
| Each of their other units | 8/8 | 27/28 | 92/93 |
| Swell 50% of their biggest | +12/+12 | +41/+41 | +138/+139 |
| Swell 50% of another unit | +4/+4 | +13/+14 | +46/+46 |
| Mired enemies that die a fight (model) | 4–6 | 5–7 | 5–7 |

## 3. The 16 cards

The tier spread is unchanged: 3/3/3/3/2/2. Every creature, name and portrait is kept, and both tokens (The Prince Restored and the Peatling) are kept. Printed stats are today's scale except Gideon (+1 Attack, because his echo uses it). The scale build's body multiplier applies here as it does to every tribe. "Model size" is a unit's total stats (Attack plus Health) after the fight in `bog-wild-model.py` at Swell 50%, typical line first, then strong line.

### Tier 1

**Bridge Toad.** T1, 1/3. *A toad under every bridge, and a toll for every crossing.*
- Text: **Mire. Swell 25%.**
- Golden (2/6): Mire. Swell 50%.
- Condition: the enemy across it dies, by any hand, win or lose.
- Payoff: a quarter of that enemy, permanently. Across a middling enemy that is +2/+2, +6/+7 and +23/+23 a fight at R9, R12 and R15; across their biggest it is +6/+6, +20/+20 and +69/+69. Doubled with Tiddy. Model size: 20 / 89 on the typical tempo line (sold for the Peat King at R14); 21 / 72 / 261 on the strong carry line.
- Permanence: permanent.
- Enabler: a patch for Snap, Sal and every Sink card; Tiddy doubles it.
- Concentrates: partly. It is the first carry seed, and the tier 1 that still matters at R15. It swells at half the tier 3+ rate, so a tier 1 triple can't snowball.

**Young Pretender.** T1, 3/2.
- Text: **Snap. After this kills a Mired enemy: get 1 gold next turn.**
- Golden (6/4): …get 2 gold next turn.
- Condition: it lands the killing blow on a Mired enemy.
- Payoff: about 0.3 gold a fight while it lives, R1–R7.
- Permanence: economy.
- Enabler: its kills turn patches into Swells and Sinks early.
- Concentrates: no. Sell it from R7.

**Warty Nan.** T1, 1/3. *The toad wet-nurse feeds the little ones first.*
- Text: **Sink: your smallest Bog folk gains 25% of its stats, permanently.**
- Golden (2/6): …gains 50% of its stats, permanently.
- Condition: any Mired enemy dies (4–7 a fight from R8).
- Payoff: a quarter of every sunk enemy goes to your smallest Bog folk: about +14/+14 a fight at R9, +45/+48 at R12 and +160/+160 at R15, spread up the low end of the board.
- Permanence: permanent.
- Enabler: keeps Bufo, the Cutter, the Chorus, Sal and Hopkin on pace, so support cards are no longer dead weight by R9.
- Concentrates: **no, it levels.** This is the even-board engine. She loses pass 2's Bitter, which moves to the Chorus, Bufo and the Prima Donna.

### Tier 2

**Madame Bufo.** T2, 1/4.
- Text: **Mire. Bitter 25%. If its Mired enemy kills this, that enemy loses half its Attack.**
- Golden (2/8): Mire. Bitter 50%. If its Mired enemy kills this, that enemy loses half its Attack.
- Condition: the enemy across bites her (Bitter) and kills her (halving).
- Payoff: their carry's Attack goes ×0.75 and then ×0.5: 24 → 9 at R9, 82 → 30 at R12, 277 → 103 at R15.
- Permanence: combat only (an answer). Nan keeps her body growing.
- Enabler: makes their carry killable for the frogs. Cost: whatever sinks on her patch feeds no one's Swell.
- Concentrates: no. **This is the core decision:** halve their giant with Bufo, or let Gideon eat it.

**Vaulting Hopkin.** T2, 3/1.
- Text: **Snap. In your back row, this attacks first, with double Attack.**
- Golden (6/2): …with triple Attack.
- Condition: back row, and a Mired enemy exists.
- Payoff: an opening strike at the Mired enemy with the most Attack, for twice his Attack: about 12 at R9, 40–60 at R12 and 150–300 at R15, as Nan feeds him.
- Permanence: combat only.
- Enabler: softens the carry before it swings, so it sinks (Swell, Ranocchio, Sink).
- Concentrates: no.

**The Peat Cutter.** T2, 2/4.
- Text: **Mire. Sink: get 1 gold next turn. Once a fight.**
- Golden (4/8): …get 2 gold next turn. Once a fight.
- Condition: any Mired enemy dies, which happens in most fights, won or lost.
- Payoff: about 0.9 gold a fight, all game (the three-in-all cap is gone).
- Permanence: economy.
- Enabler: a patch; gold for rolls toward Tiddy and the T6s, and for Harvest Supper.
- Concentrates: no.

### Tier 3

**Gideon, Basso Profundo.** T3, 3/6 (was 2/6).
- Text: **Mire. Swell 50%. After its Mired enemy attacks this, hit it for this unit's Attack.**
- Golden (6/12): Mire. Swell 100%. After its Mired enemy attacks this, hit it for twice this unit's Attack.
- Details: damage only, so it doesn't hit back.
- Condition: his Mired enemy attacks him (the lock makes sure it does) and then sinks.
- Payoff: across their biggest, +12/+12, +41/+41 and +138/+139 a fight (doubled with Tiddy). Each bite also costs that enemy his Attack again, so he wins duels at about half its size. Model size: 52 / 211 / 1,267 (typical tempo); 40–130 / 364–877 / 2,000–2,600 (carry line).
- Permanence: permanent (Swell); the echo is combat only.
- Enabler: the carry for His Highness and Tiddy; his echo makes their carry sink, which feeds every Sink card.
- Concentrates: **yes, he is the tribe's carry.** He holds his stats through the echo, Bitter lent by a Chorus beside him, mid-fight Swell, and the back-row duel (in B2 he can only be hit by the enemy he Mires).

**The Natterjack Chorus.** T3, 3/4.
- Text: **Your units beside this have Mire and Bitter 25%.**
- Golden (6/8): Your units beside this have Mire and Bitter 50%.
- Condition: units beside it in its row.
- Payoff: two more patches, so two more Sink triggers a fight (Nan, the Cutter, His Highness's count, the Peat King), and Bitter 25% on two units. Beside Gideon it gives the carry Bitter.
- Permanence: aura (combat).
- Enabler: Nan, the Cutter, His Highness, Sal, Snap, the Peat King; and another tribe's wall (the Borrowed Bog splash).
- Concentrates: no. It lends Mire, not Swell, so the engine doesn't leave the tribe.

**Spitfire Sal.** T3, 1/3.
- Text: **Start of Combat: each Mired enemy loses 25% of its Health.**
- Golden (2/6): …loses 50% of its Health.
- Condition: Mired enemies at Start of Combat; more patches mean more targets.
- Payoff: with 4–5 enemies Mired, about −12, −41 and −138 Health across their stuck units at R9, R12 and R15, including −6, −20 and −69 off their carry.
- Permanence: combat only.
- Enabler: kills, so Swell and Sink fire; shrinks their carry for Ranocchio's kill.
- Concentrates: no.

### Tier 4

**Jenny Greenteeth.** T4, 3/5. *"Stay off the duckweed, dears."*
- Text: **Mire. Swell 50%. Start of Combat: pull the biggest enemy in her row across.**
- Golden (6/10): Mire. Swell 100%. Start of Combat: pull the biggest enemy in her row across.
- Details: "her row" is their row that faces hers; the enemy across her swaps places with it.
- Condition: she is in the row where their biggest stands. The player reads the scout and picks her row.
- Payoff: she always holds the biggest in her row and eats it when it sinks: +12/+12 to +41/+41 to +138/+139 a fight. In the back row she drags their back-row carry onto her patch, in reach of every Snap. Model size: 28 / 96 / 463 (tempo); 58 / 194–332 / 710–1,085 (carry).
- Permanence: permanent (Swell); the pull is combat only.
- Enabler: steers the biggest meal and makes their carry Mired for Snap, Sal and Ranocchio.
- Concentrates: yes, as a second carry. Her reach is "sometimes": it is limited to a row, it reads a scout that may be stale, and the pull alone kills nothing.

**His Highness, Allegedly.** T4, 3/5.
- Text: **Snap. Sink (5): permanently double the stats of units beside this, then become a Prince.**
- Golden (6/10): Snap. Sink (5): permanently triple the stats of units beside this, then become a golden Prince.
- Condition: five Mired enemies sink while he is on the board, which takes 1–2 fights.
- Payoff: the units beside him double once, then again every 15 as the Prince (about every third fight). Beside a 60-stat Gideon at R9 that is +60–130 stats; as the Prince, +360–880 at R12 and +2,000 at R15.
- Permanence: permanent.
- Enabler: the carry's doubler; it pays you to put the carry beside him (the back-row box below).
- Concentrates: **yes**, two units at a time.
- **The Prince Restored** (token, 6/7, golden 12/14, keeps His Highness's buffs): **Mire. Swell 50%. Sink (15): permanently double the stats of units beside this.** Golden: Swell 100%, triple.

**Signor Ranocchio, Tenor.** T4, 3/4.
- Text: **Snap. After this kills a Mired enemy: gain 50% of its stats permanently.**
- Golden (6/8): …gain 100% of its stats permanently.
- Condition: he lands the kill. Snap aims him at the Mired enemy with the most Attack.
- Payoff: +4/+4 to +12/+12 a kill at R9, +13/+14 to +41/+41 at R12, +46 to +139 at R15. Early he kills every other fight, and every fight once he is big. He compounds on himself: bigger means more kills.
- Permanence: permanent.
- Enabler: each kill also feeds the maker's Swell and every Sink card.
- Concentrates: yes, the frog carry in the back row. It isn't a Swell, so Tiddy doesn't double it: a frog carry is the slower, safer alternative to Gideon.

### Tier 5

**Tiddy Mun.** T5, 3/6. *The fen spirit raises the water, and the bog keeps twice as much.*
- Text: **Your Swells trigger twice.**
- Golden (6/12): Your Swells trigger three times.
- Condition: Swell units on your board.
- Payoff: doubles every Swell. With four Swell units on a typical board that is about +40, +150 and +500 stats a fight at R9, R12 and R15.
- Permanence: standing text; the gains are permanent.
- Enabler: Bridge Toad, Gideon, Jenny, the Prima Donna, the Peat King, the Lantern Man and the Prince.
- Concentrates: it amplifies wherever your Swell units are. With a fed Gideon it concentrates; on a Wrestling board it widens.

**The Prima Donna.** T5, 2/8.
- Text: **Mire the slot across and the slots beside it. Bitter 25%. Swell 50%.**
- Golden (4/16): Mire the slot across and the slots beside it. Bitter 50%. Swell 100%.
- Condition: enemies on her three patches sink.
- Payoff: half of up to three enemies a fight: about +12/+12, +40/+42 and +138/+138 at R9, R12 and R15 (doubled with Tiddy). In B2 she Mires their whole back row onto her. Model size: 32 at R9 (strong tempo), 195 / 1,294 at R12 / R15 (typical tempo).
- Permanence: permanent.
- Enabler: three patches for Sink, Sal and Snap; Bitter 25% on three biters.
- Concentrates: partly (three meals into one body). She is the Wrestling Match's late carry.

### Tier 6

**The Peat King.** T6, 5/9.
- Text: **Mire. Swell 50%. Sink: summon a Peatling with its stats. Twice a fight.**
- Golden (10/18): Mire. Swell 100%. Sink: summon two Peatlings with its stats. Twice a fight.
- Details: the Peatling rises in your empty slot nearest him and lasts the fight.
- Condition: Mired enemies sink, and you have empty slots (as your own units die).
- Payoff: Swell on his own patch (+41/+41 at R12, +138/+139 at R15), plus the first two enemies to sink each fight rising for you: about 2 × 55 = 110 combat stats at R12 and 2 × 185 = 370 at R15. When their carry sinks, you get their carry.
- Permanence: permanent (Swell); the Peatlings are combat only.
- Enabler: Peatlings carry Bitter 25%; they refill the Wrestling board mid-fight.
- Concentrates: no.
- **Peatling** (token, Bog folk, combat only): the sunk enemy's starting stats. Text: **Bitter 25%.**

**The Lantern Man.** T6, 4/8. *The light over the fen comes for whoever strays.*
- Text: **Mire the biggest enemy, wherever it stands. Swell 50%.**
- Golden (8/16): Mire the two biggest enemies, wherever they stand. Swell 100%.
- Condition: none. The lure always lands.
- Payoff: their biggest is always Mired. It must attack him first, even in your back row; every Snap, Sal and Ranocchio finds it; and when it sinks he eats half of it: +41/+41 at R12 and +138/+139 at R15, doubled with Tiddy. Model size: 136 / 514 (R12 / R15, strong carry line).
- Permanence: permanent (Swell); the lure is combat only.
- Enabler: points the whole tribe's answers at their carry.
- Concentrates: yes; he becomes the late carry, or the second one.
- He is the pool's one Bog "biggest enemy in any row" card (fundamentals, question 2: "two or three cards in the whole pool"). Jenny's reach is limited to a row.

### Counts against the audit

| | Pass 2 | Pass 3 |
|---|---|---|
| Payoffs that last one fight only | 9 of 13 | 4 of 16 (Bufo, Hopkin, Sal, the Chorus aura) |
| Permanent payoff cards | 4 (Toad capped, Highness one-shot, Ranocchio, Tiddy) | 10 |
| Payoffs that scale with the game | Bufo's halving | Swell ×6, Nan, Ranocchio, the curse, Bitter, Sal, Bufo, Peatlings, Hopkin |
| Caps and limiters | 5 | 2 (section 6 says why) |
| Card text, words | — | median 11.5, longest 15 (guide: median ≤ 11, max 22) |

## 4. The tribe

### Engine and its rate
**The engine is Swell: Bog units keep a share of every enemy they hold when it sinks.** Warty Nan spreads a second share to the smallest, Tiddy Mun doubles Swell, and the Prince doubles the carry on a counter.

- **The rate parameter is f, the Swell share.** Tier 3+ Swell units, Ranocchio and the Prince keep f; Bridge Toad and Warty Nan keep f/2. **Proposed f = 50%.** The sweep should try 25%, 35% and 50%.
- Secondary levers, in order of effect:
  - the Prince's repeat count (15; try 10, 15, 20 and off);
  - Tiddy's multiplier (×2; ×1.5 tested);
  - the Bitter share (25%) and Sal's share (25%).

Model results (board at fight ÷ target median; answer factor 1.15; strong = key cards on time, typical = one to two rounds late; R8–R10 dips noted):

| f | Line | R6 | R9 | R12 | R15 | Biggest unit's share |
|---|---|---|---|---|---|---|
| 50% | Carry, strong | 1.05 | 1.43 | 1.39 | 1.81 (R13 2.20) | 0.35–0.54 |
| 50% | Carry, typical | 0.83 | 0.71 (R8 0.67) | 1.17 | 1.23 | 0.30–0.52 |
| 50% | Tempo, strong | 1.23 | 0.99 | 1.52 | 1.97 | 0.28–0.34 |
| 50% | Tempo, typical | 1.16 | 0.89 (R10 0.83) | 0.90 | 1.62 | 0.24–0.29 |
| 35% | Tempo, typical | 1.11 | 0.68 | 0.64 | 0.95 | |
| 25% | Tempo, typical | 1.05 | 0.64 | 0.57 | 0.66 | |

Reading:
- At 50% both lines hold level to R8. Strong lines are ahead from R9–R11. Typical lines sag 10–30% at R8–R11, are level by R12–R13, and are ahead by R15.
- At 35% or 25% the parasitic engine can't keep a ×1.5 lobby's pace, which is why the proposal is a half.
- The strong lines top out near 2× the median, inside Battlegrounds' 13–23% of boards at twice the median, not a 10× runaway.
- The model ignores overkill, so it flatters the carry line's 50% share.

### When it comes online
- **Carry line:** R8–R9 on a strong game, when the first curse break doubles a fed Gideon. R11–R12 on a typical one.
- **Tempo line:** level from R1 on mirers and Bitter. It comes online at R10–R11, when Tiddy and the Prima Donna land, and is clearly ahead from R12–R13.
- Engine shape: a Swell unit is behind when bought (a small body), level after two or three meals, and ahead after that, because its meals grow with the lobby.

### The decision the engine creates
**Who eats whom.** Every fight starts with a matching puzzle against the scout, and the tray shows each Swell unit's meal.
- The biggest meal is their carry, and their carry also bites hardest.
- Put Gideon across it and he may eat half of it, or die first.
- Put Bufo across it and it is halved, but nobody swells.
- Put Jenny in its row and she takes it.
- With the Lantern Man in play, their carry is his, and Gideon must find the next meal.

Three slower decisions sit on top:
1. **Feed one or lift all.** Nan levels the board; the Prince doubles the two units beside him; Tiddy amplifies whichever you built.
2. **When to break the curse.** Play His Highness now for an early double, or hold him in hand (he doesn't count there) until the carry is worth doubling.
3. **Leave a gap for the Peat King's Peatlings, or fill the board.**

### Carry route: "The Frog and the Ox"
- **The carry.** Gideon from R5, fed by Swell across their biggest, protected by his echo, Bitter from a Chorus beside him, and the back-row duel.
- **The doubler.** His Highness beside him (R7–R9) breaks the curse, and the Prince keeps doubling.
- **The late game.** Tiddy doubles every meal from R9–R11. Jenny or the Lantern Man steers the biggest meal.
- **Fallback.** Ranocchio is the frog carry if Gideon doesn't show.
- **The back-row box.** B1 His Highness, B2 Gideon, B3 Jenny or the Chorus. Gideon sits across their biggest back-row unit, which must come into your back row to bite him past your front row, so he duels it alone. The front row is Bufo across their biggest front unit, plus Bridge Toad and Nan.
- Typical R12 board from the model (about 840 stats against a 494 median):

```
F1 Bridge Toad 28/33   F2 Jenny Greenteeth 95/100   F3 Madame Bufo 25/32   F4 Warty Nan 22/27
       B1 His Highness 30/36    B2 Gideon 180/185    B3 Tiddy Mun 25/28
```

Jenny in F2 pulls their biggest front-row unit onto her patch. Gideon holds their biggest back-row unit. At this stage Bufo is often sold for the Prima Donna or the Lantern Man.

### Non-carry route: "The Wrestling Match"
- **The board.** A wide, even board of fat toads: Bridge Toad, Bufo, the Cutter, Gideon, the Chorus, Jenny, then the Prima Donna, Tiddy and the Peat King.
- **How it grows.** Nan lifts the smallest every fight, so bodies stay even. Under our rules, at equal totals, even and bigger bodies always win (audit point 6).
- **How it fights.** It locks 4–7 enemies, shrinks each by Bitter, burns them with Sal, and raises the first two that sink as Peatlings.
- **Model sizes.** Units are about 2× the median unit at R12 and 1.5–5× at R15, with the biggest unit's share 0.2–0.3. It is a strong non-carry route, as the fundamentals asked of Bog.

### Answers to other tribes' carries
Bog is the pool's predator of carries, and its reward for answering is growth.
- **The lock.** Their carry's first attack must go into a toad, wasting its overkill on a 1/4.
- **Bitter 25%** (Bufo, the Chorus, the Prima Donna, Peatlings) takes a quarter off every biter before it hits, all game.
- **Bufo** halves the carry's Attack when it kills her (×0.375 with her Bitter).
- **Sal** takes 25% of every Mired enemy's Health at Start of Combat.
- **Reach, in three grades:**
  - *across*: needs the scout to be right;
  - *Jenny*: the biggest in one row;
  - *the Lantern Man*: the biggest anywhere, at tier 6 only.
- **Snap and Hopkin** focus whatever is Mired with the most Attack.

Against each tribe:
- **Hedgerow's Pass carry** sits in the last slot, which a back-row mirer or the Lantern reaches.
- **An Ooze's Belly** empties onto the patch, and every body that sinks feeds a Sink card.
- **A Hunter that is Mired** bites the toad, not its quarry.

### Weak points
- **The carry line's mid-game.** The greedy line sits at 0.67–0.79 of the median at R8–R11 on a typical game, and survives on its answers.
- **Wide token boards.** Meals are small, one Mire holds one of seven, and Bitter takes 1 off a 2-Attack token.
- **A stale scout.** An opponent who moves their carry each round puts your mud on a token, and Bufo halves nothing.
- **Start of Combat shots across** (Sergeant-at-Conkers) kill a mirer before its lock does anything. The patch and its Swell stay.
- **The Changeling** swaps a toad to their side; its Swell then feeds no one.
- **Birds.** A Mired Egg is a tiny meal, and Nests hide the real Bird.
- **A carry-less lobby,** where meals stay small, though then everyone is small.
- **Over-feeding Gideon.** Past about 40% of the board, overkill wastes him, and an even board of the same total beats him.

### Two highroll moments
1. **The curse breaks mid-fight.** Round 9. Gideon is 50/60 in B2 with His Highness in B1 and Jenny in B3. Sal's fireworks open the fight. The fifth Mired enemy goes under, the frog's hearts fill and the crown lights. Gideon jumps to 100/120 and Jenny to 50/60 in the middle of the fight, and they wipe a board that was winning. After the fight the frog stands up a prince. With a golden His Highness it's a tripling, and he does it again every 15 sinkings.
2. **The Lantern Man brings their carry home.** Round 13. Their 300/320 carry hides in B3. The Lantern Man's light settles on it and the mud spreads under it. Sal takes 80 Health off it, Hopkin vaults in with a double strike, and Ranocchio's tongue finishes it. It sinks. The Lantern Man swells +150/+160, doubled by Tiddy to +300/+320, so he is now their carry's size for good. The Peat King raises their carry as a 300/320 Peatling on your side to finish the fight.

## 5. Harness lines (for `BenchSuites.REGISTRY`)

Both lines are committed to Bog folk and buy Harvest Supper with spare gold once their units are bought.

### Placement policy (both lines)

Read the scout and rank their units by Attack plus Health.
1. The Lantern Man takes their biggest.
2. Swell units, biggest first, go across their biggest remaining units.
3. Exception: if an enemy has more than 2× the stats of your Swell unit there, put Madame Bufo across it instead and move that Swell unit to the next enemy.
4. Jenny goes in the row holding their biggest unit that isn't yet Mired.
5. His Highness goes beside the carry in the same row.
6. The Prima Donna goes in F2 or F3, or in B2 when two of their top three are in the back row.
7. The Chorus goes mid-row, beside a non-mirer or beside the carry.
8. Sal and Hopkin go in the back row.
9. With six units, leave the empty slot beside the Peat King.

### Line `bog_tempo`: The Wrestling Match (engine flag off)
- **Buy and keep, highest first:**
  1. `tiddy_mun`
  2. `prima_donna`
  3. `peat_king`
  4. `gideon`
  5. `jenny_greenteeth`
  6. `warty_nan`
  7. `madame_bufo`
  8. `natterjack_chorus`
  9. `bridge_toad`
  10. `spitfire_sal`
  11. `lantern_man`
  12. `signor_ranocchio`
  13. `peat_cutter`
  14. `young_pretender`
  15. `vaulting_hopkin`
  16. `his_highness`
- **Sell first when full:**
  1. `young_pretender` (from R6)
  2. `vaulting_hopkin`
  3. `peat_cutter` (from R10)
  4. `spitfire_sal` (from R12)
  5. `natterjack_chorus` (once the Prima Donna is in)
  6. the smallest non-Swell unit
- **Tier up:** T2 on R3, T3 on R5, T4 on R7, T5 on R9, T6 on R12.
- **Save gold:** spend everything, except bank up to 2 on R8 and R11 when that makes the next tier-up on time. Roll at T5 for `tiddy_mun` and `prima_donna` before buying anything else.

### Line `bog_engine`: The Frog and the Ox (engine flag on)
- **Buy and keep, highest first:**
  1. `gideon`
  2. `his_highness`
  3. `tiddy_mun`
  4. `jenny_greenteeth`
  5. `lantern_man`
  6. `warty_nan`
  7. `bridge_toad`
  8. `madame_bufo`
  9. `vaulting_hopkin`
  10. `signor_ranocchio`
  11. `prima_donna`
  12. `young_pretender`
  13. `natterjack_chorus`
  14. `peat_king`
  15. `spitfire_sal`
  16. `peat_cutter`
- **Copies:** buy second copies of `gideon` and `his_highness` (triples), and keep pairs.
- **Sell first when full:**
  1. `young_pretender`
  2. `vaulting_hopkin` (from R10)
  3. `madame_bufo` (from R11)
  4. the smallest unit that isn't the carry or beside it
- **Tier up:** T2 on R2, T3 on R4, T4 on R6, T5 on R8, T6 on R10.
- **Save gold:**
  - bank 2–3 on R5 to reach T4 on R6, and bank on R9 to reach T6 on R10;
  - hold `his_highness` in hand until `gideon` has at least 3× your median unit's stats, or until R9 at the latest, then play him beside Gideon;
  - otherwise spend everything.

## 6. Risks and levers

| Risk | What to watch | First lever |
|---|---|---|
| **f = 50% is too strong late** (strong lines reach 1.8–2.2× at R13–R15) | The share of R13–R15 boards at 2× the median against Battlegrounds' 13–23% | Tiddy to "half again", then f to 40% |
| **Golden Swell 100%** with Tiddy keeps 200% of a sunk carry | Golden Gideon or Jenny lobbies | Golden Swell to 75% |
| **The proportional answer stack** (Bitter, Bufo, Sal, Lantern) makes Bog oppressive against carry tribes | Carry tribes' field win rate against Bog; how long fights last | Sal to 20%, then Bitter to 20%, then the Lantern Man to the back row only |
| **Warty Nan:** a T1 that delivers about 0.2 of a board a fight late | Whether every Bog board keeps her to R16 (fine), and her export (none: "Bog folk" only) | Nan to f/3 |
| **The Prince's repeat** gives the carry line its late shape (off: 0.77 at R15; every 10: 2.5–2.8×) | Turns between doublings; R15 carry size | Repeat 20 |
| **Peatlings** copy whole enemies, twice a fight | Fights decided by a risen carry | Half its stats. "Twice a fight" stays as the readable story ("he raises two"), not as a size cap; remove it if sims show no flood. |
| **The Peat Cutter's once a fight** | Bog gold per turn against other tribes (owner, 9d: no common economy snowballs) | Remove the limit if Bog is short of gold |
| **Early heat** (tempo lines at 1.15–1.23 at R6 in the model, which ignores gold) | R4–R7 field rates | Bridge Toad and Nan at f/3 |
| **Carry-line mid-game dip** (0.67–0.79, R8–R11) | Hero Health at R12 on the engine line | His Highness at Sink (4), or Gideon to 3/7 |
| **Over-concentration** (Gideon 40–55% of the board in the model) | Biggest unit's share in snapshots; overkill waste | The Prince doubles one unit beside him plus the smallest |

**Variations kept for the panel:**
1. **Swell on the bite:** "When its Mired enemy attacks this: first gain 10% of its stats." It needs no kill, holds stats before the hit and compounds per bite, but it is messier to read.
2. **The court variation:** the curse break doubles all your frogs once and never repeats. It is a bigger single moment, without a late engine.
3. **Tiddy feeds the biggest** instead of doubling Swell: pure concentration. The model put the carry at 75% of the board, which is too tall under our rules.
4. **The Peat King doubles Swell** and Tiddy is the leveller: the model shows 3–6× late with Nan, so it was dropped.

## 7. Engine support needed

| Need | For | Size |
|---|---|---|
| **Fight-start stat snapshot** per unit, plus "as it entered" for mid-fight arrivals | Swell, Nan, Ranocchio, Peatlings | Small (pass 1 specified a bell snapshot) |
| **Swell X%**: `on_enemy_death` with the maker filter (patch maker == self); gain X% of the snapshot, rounded down, written to the recruit copy even if dead, skipped if it changed side | 6 cards and the Prince | Small: `on_enemy_death` and `subject_mired` exist |
| **Sink trigger and Sink (X)**: a persistent per-unit counter kept between fights, triples keep the highest, not counting in hand | Nan, the Cutter, the Peat King, His Highness, the Prince | Small (the kiss counter exists) |
| **"Your Swells trigger twice"**: a multiplier hook on Swell | Tiddy Mun | Small |
| **Proportional Bitter**: % of Attack, rounded up, floor 1, highest source wins | Bufo, the Chorus, the Prima Donna, Peatlings | Small (Track B: proportional debuffs) |
| **Proportional Health loss** at Start of Combat on Mired enemies (not damage) | Spitfire Sal | Small (Nightshade's path) |
| **Selectors biggest and smallest** (Attack plus Health, reading order breaks ties), with a "not combat summons" filter | Nan, Jenny, the Lantern Man | Small (Track B: biggest) |
| **Pull**: swap the biggest enemy in the facing row into the slot across; re-check Mired status on both moved units | Jenny | Small (relocate events exist) |
| **Mire with a target**: patch under the biggest enemy, laid first at the bell | The Lantern Man | Medium |
| **Double / triple stats**, permanent and in combat, for units beside, on a Sink count; transform after the fight keeping slot and buffs | His Highness, the Prince | Small–medium (multiply and transform exist) |
| **Summon a copy of the subject's snapshot stats** as a Peatling, limit 2 | The Peat King | Small (`summon of: subject` exists) |
| **One-way strike** for this unit's Attack after its Mired enemy attacks it | Gideon | Small |
| **Remove caps** | Bridge Toad's `permanent_buff_cap`, the Cutter's `lifetime`, Ranocchio's limit, Tiddy's limit | Data only |
| **UI** | Swell preview in the tray against the scout; Sink hearts on His Highness and the Prince; the fight-log line "The Boar sinks: Gideon swells +41/+41"; the bubble along the reed-line | Small–medium |
| **Harness/bots** | The placement policy above; "hold His Highness" logic; scout reading. Bots must hold their carries still between rounds, or every across-card measures as a coin flip (pass 1). | Medium |

## 8. What changed from pass 2

| Card | Pass 2 | Pass 3 | Why |
|---|---|---|---|
| Bridge Toad | +1/+1 when attacked, capped +3/+3 | Swell 25% | The cap removed the tail; growth now tracks the lobby |
| Young Pretender | Same | Same | Early Snap and gold |
| Warty Nan | Bitter 1, lends Bitter 1 | Sink: the smallest gains 25% | Support cards were flat 8–11 stats by R9; she lifts them |
| Madame Bufo | Bitter 2, halving | Bitter 25%, halving | Flat Bitter vanished at scale |
| Vaulting Hopkin | +2 Attack first | Double Attack first | Same reason |
| Peat Cutter | 1 gold, three in all | 1 gold a fight, all game | Cap removed |
| Natterjack Chorus | Lends Mire and Bitter 1 | Lends Mire and Bitter 25% | Scale |
| Gideon | Counter-attack +2 | Swell 50% plus a one-way echo | The carry; the echo holds his stats |
| Spitfire Sal | 2 damage per Mired enemy | 25% of each Mired enemy's Health | Scale |
| Jenny Greenteeth | −2 Attack, neighbour strikes | Swell 50%, pulls the biggest in her row | Folklore; steers the meal; "sometimes" reach |
| His Highness | Third kiss: a 6/7 Prince with a spell discount | Sink (5): double beside; the Prince repeats at 15 | The opera's payoff becomes the doubler |
| Signor Ranocchio | +1/+1 on a Mired attack, once a fight | 50% of the Mired enemies he kills | Proportional; limit removed |
| Tiddy Mun | +1/+1 to a hit wall, twice a fight | Your Swells trigger twice | The T5 capstone lands in the mid-game hole |
| The Prima Donna | Three patches, Bitter 2 once per enemy | Three patches, Bitter 25%, Swell 50% | The wide carry |
| The Peat King | 4/4 Peatlings, twice a fight | Swell 50%; Peatlings copy the sunk | The drowned rise for you |
| The Lantern Man | +3 Attack per Mired enemy | Mires the biggest anywhere; Swell 50% | Folklore; the one any-row reach |
