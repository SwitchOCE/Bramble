# Oozes, pass 3: the Big Pudding (carry and answers)

Pass 3 design panel, Oozes, "carry and answers" angle. 9 Nov 2026. Paper design only: nothing is built or costed, and no price list was used. Sizes come from a toy growth model and from the audit's combat model, extended for these cards (section 9; scripts in `oozes-carry-model/`).

The owner's direction this answers:
- Oozes "work around buffing the shop and amalgamating things into them, and eating each other, and combining and splitting" (2 Nov, 02h).
- "concentrating stats is always better than spreading them out. This applies doubly if you have units that hold stats really well" (9a).
- "Rewards give the player power, always." (9c)
- "It's way harder to beat 3 units that are 500 million / 500 million than a single 2.1 billion one." (9d)

## 1. The tribe in one paragraph

Oozes eat. One pudding becomes the Big Pudding. You feed it units through its Belly, and it digests them into permanent stats. Stone Soup makes the whole shop taste of it: every shop unit carries a tenth of your biggest Ooze's stats. So each meal makes the next meal bigger, and every support you buy later is bigger too. Every unit you buy has three homes: the board, a Belly (a spare life), or a stomach (food). That choice is the tribe. The carry holds its stats by splitting when hit, by keeping a meal inside, and by a Shield. It moves to a better pudding by being eaten. Against other tribes' carries, the tribe does the same thing outward: Hasty Pudding swallows the biggest enemy, wherever it stands.

*Similar to:* Battlegrounds Demons, which consume tavern minions (Ur'zul, Felbat), plus the Elementals' tavern buffs. The difference is that you can see the stomach, and the shop's buff is a share of your own pudding, so it grows as the pudding grows.

## 2. The engine: the Stock Pot

**Loop.** A meal goes in. Digest makes the biggest Ooze bigger. Stone Soup then gives every shop unit +1/10 of that Ooze, so the next meal and the next support are bigger.

**Rate parameter: `r`, Stone Soup's share.** Default 1/10. Sweep 1/20, 1/16, 1/10, 1/8, 1/5. Golden doubles it.

Secondary dials stay at their defaults unless `r` alone can't reach the target shape:
- `a`, Aunt Aspic's eat bonus: +50%.
- `e`, Elder Ooze's share: 1/10.
- `s`, Cut-and-Come-Again's slice: 1/5.

**Why it compounds.** Carry growth a turn ≈ meals × (base stats + r × carry). From round 8 there are two to three meals a turn: one bought, Nell's, and from round 12 a slice. So the carry grows about ×1.3 a round from round 8, plus the base. Supports bought late carry the share too, and Elder Ooze keeps older Oozes at a share of the carry. The board follows the carry instead of leaving it alone.

**What brakes it.**
- Each Digest Ooze has Belly 1: one bought meal a turn per stomach. More meals need another stomach, a stuffed Sixpenny Pie (gold), or Nell.
- Gold: a meal costs 3, or 2 into Little Dollop.
- Only your best Stone Soup counts (golden counts double). Without this, two copies would double the compounding rate, and tripling them into a golden would be a downgrade. This is the tribe's one stacking rule, and it guards a loop.
- The carry is one target. Answers that hit the biggest enemy hit it.

**Model curve** (board stats at combat, toy model, `routes.py`):

| Line | R6 | R9 | R12 | R15 | Biggest unit's share, R12 |
|---|---|---|---|---|---|
| Typical carry line: Soup, Dollop then Bubble, Nell from R6, Elder R10, slices R12, no Aspic | 74 | 213 | 760 | 2,674 | 41% |
| Low roll: no Nell, no Aspic | 63 | 135 | 336 | 924 | 34% |
| With Aspic (+50%) | 78 | 255 | 1,043 | 4,986 | 43% |
| Golden Soup, without / with Aspic | 91 / 98 | 349 / 461 | 1,801 / 3,016 | 10,026 / 25,784 | — |
| Pot line (non-carry route) | 90 | 191 | 700 | 1,649 | 35% |
| Target: Battlegrounds Sep 2025 means | 53 | 194 | 759 | ~2,600 (R14 1,751 × 1.5) | ~34% (Nov 2026) |

The typical line sits on the target from round 9. Aspic games run 1.4× at round 12 and 1.9× at round 15, which is the spread the target wants (13–23% of boards at twice the median). Golden Soup with Aspic reaches about 10× at round 15, the owner's top-1% figure. Golden Soup with golden Aspic reaches about 30×: see section 8.

Model limits:
- It charges no gold for tier-ups and treats every support as base plus share, while engine pieces have smaller bodies. So rounds 4–7 run high: the real round 6 board is closer to 55–65.
- Golden Soup is modelled as owned from round 3, so that row overstates.

## 3. Words the tribe uses

- **Belly N** (existing): "Holds this many units, safe inside. When this dies, they come out."
- **Digest** (new; Little Dollop, Bubble and Squeak, Frumenty). Reminder: *"Start of Turn: this eats what's inside it."*
- **Eat** (new verb; Digest, Dishwater Nell, Aunt Aspic). Reminder: *"Destroy it. The eater gains its stats permanently."*
- **Shield**, **Cleave**: the Track B keywords, as built on `ideation/mechanics`.
- **"your biggest Ooze"** stays plain words: the Ooze on your board with the most Attack plus Health, with ties going to reading order. The UI marks it with a ladle, and Stone Soup's share shows on every shop card.

Rulings, for Details or the rulebook:
- Eating takes the eaten unit's own Attack and Health (base plus permanent), not the tribe bonus or Rings.
- An eaten Ooze's insides are eaten too.
- Eaten units return to the pool, and no gold is paid.
- Start of Turn order: Digest, then Cut-and-Come-Again's slice, then the shop.

Text length:
- Card text runs a median of 13 words, p90 15, max 18 (Bubble and Squeak). The guide asks for a median of 11 or less, so the median is two over; p90 and max pass.
- The extra words are conditions that change play ("next to this", "if this has room"). By the guide's rule 8, those stay.

## 4. The 16 cards

The tier spread stays at 3/3/3/3/2/2. All names, creatures and portraits are kept.

### Tier 1

**Little Dollop** (Custard Ooze). T1, 1/2.
- **Text:** Belly 1. Digest. Units you buy into this cost 1 gold less.
- **Golden (2/4):** Belly 2. Digest. Units you buy into this cost 2 gold less.
- **Condition:** buy units into it. Stone Soup makes those meals grow.
- **Payoff:** the first carry. Kept as the carry, it reaches ~30/30 at R7, 65/65 at R9, 155/155 at R12 and 570/570 at R15. Usually it is eaten into Bubble and Squeak or Frumenty between R5 and R9, and passes all of that on. The discount is worth about one extra meal every three turns.
- **Permanence:** permanent and visible.
- **Enabler:** gives Stone Soup an early biggest Ooze, and Nell and Aspic an early eater. Figgy Duff makes a golden Dollop from two copies: two 1-gold meals a turn.
- **Concentrates:** yes.
- *Changed:* gains Digest. The Belly is now a stomach.

**Mrs Posset** (Hot Milk Ooze). T1, 2/1.
- **Text:** Belly 1. When this dies: its killer loses half its stats.
- **Golden (4/2):** Belly 2. When this dies: its killer loses three quarters of its stats.
- **Details:** the killer is the unit whose attack or effect dealt the killing damage. Rounds down; Health stays at 1 or more.
- **Condition:** dies to an enemy, so it stands in the front row.
- **Payoff:**
  - R2–5: halves a 3/3 to 6/6 attacker. In the model at R4 it wins 42% where a plain 2/1 wins 31%.
  - Late: when its killer is the carry, which happens about 1 time in 5–7, it takes ~60 stats off at R9, ~150 at R12 and ~570 at R15.
  - With a unit inside, the slot keeps a body. In the model at R12, against a board with 60% of its stats in one unit, it adds 28–55 points.
- **Permanence:** fight only.
- **Enabler:** a front Belly for the non-carry route; a cheap meal later.
- **Concentrates:** no; it's an answer.
- *Changed:* "3 damage to the enemy across" becomes "halve its killer". The across aim landed by layout luck. The killer is often the biggest hitter. Halving Attack alone did nothing in the model (a halved carry still one-shots), so it halves both stats.

**Wee Wobbly** (Junket Ooze). T1, 1/4.
- **Text:** Belly 1. After this survives a hit: what's inside comes out, or a 1/1 Drip.
- **Golden (2/8):** Belly 2. After this survives a hit: what's inside comes out, or a 2/2 Drip.
- **Condition:** front row, hit and alive.
- **Payoff:**
  - R1–5: a wall that turns hits into bodies, two or three Drips a fight, and lets its reserve out early.
  - R9 onwards: nothing on the board. It gets sold, or eaten: a fresh Wobbly with Soup is a +6/+6 meal at R9 and +15/+15 at R12.
- **Permanence:** fight only.
- **Enabler:** early Bellies and the tempo opening.
- **Concentrates:** no.
- *Changed:* "Twice a fight" is cut. Board slots already bound the Drips.

### Tier 2

**Stone Soup** (Broth Ooze). T2, 2/3. **The engine.**
- **Text:** Units in your shop gain a tenth of your biggest Ooze's stats.
- **Golden (4/6):** Units in your shop gain a fifth of your biggest Ooze's stats.
- **Details:** shown live; a unit keeps it when bought. Only your best Stone Soup counts. Rounds down.
- **Condition:** one Ooze bigger than the rest.
- **Payoff:** every unit you see is bigger. Each shop unit gets +6/+6 at R9, +15/+15 at R12 and +57/+57 at R15. With three or four buys or eats a turn, that is about 45, 110 and 400 stats a turn.
- **Permanence:** permanent once bought. Visible in the shop.
- **Enabler:** every meal (Digest, Nell, slices), every support, and Figgy's copies.
- **Concentrates:** it rewards concentration (it reads the biggest Ooze), then hands it on to the supports you buy.
- *Changed:* was "+1/+1 to itself when you put a unit in a Belly, once a turn". It returns to the owner's "buffing the shop", as a share that grows.

**Dishwater Nell** (Scullery Slime). T2, 2/3 (was 1/2).
- **Text:** End of Turn: the biggest Ooze next to this eats your shop's biggest unit.
- **Golden (4/6):** End of Turn: the biggest Ooze next to this eats your shop's two biggest units.
- **Details:** frozen units are safe. "Next to" means beside, in front or behind.
- **Condition:** an Ooze next to her, and a unit left in the shop at End of Turn.
- **Payoff:** a free meal every turn: ~20 stats at R9, ~40 at R12, ~115 at R15. Over rounds 6 to 15 that is about a third of the carry.
- **Permanence:** permanent.
- **Enabler:** with Aspic behind the eater, Nell's meals gain the +50%. With Stone Soup, every leftover carries the share.
- **Concentrates:** yes. She has to touch the carry, which pins where the carry stands.
- *Changed:* she no longer swaps shop units or pays gold. "Their late game is eating the shop's leftovers" (pass 1) is now literal. The body goes up to par because the gold is gone.

**Moss Ooze**. T2, 2/4.
- **Text:** Your biggest other Ooze has Shield.
- **Golden (4/8):** Your two biggest other Oozes have Shield.
- **Details:** decided before Start of Combat.
- **Condition:** an Ooze bigger than this one.
- **Payoff:** the carry stops one hit a fight: ~15 damage at R9, 40–60 at R12, 150–250 at R15. With Bubble and Squeak, the first hit makes it split at full stats.
- **Permanence:** an aura in every fight, visible on the board.
- **Enabler:** Bubble and Squeak, Frumenty, and the front-row carry that Aspic wants.
- **Concentrates:** it holds a carry.
- *Changed:* was "spells on your Ooze also grow what's inside". Spells now land on a Digest Ooze, which is the carry.

### Tier 3

**Aunt Aspic** (Savoury Jelly). T3, 2/4 (was 1/3).
- **Text:** Oozes in front of this gain 50% more when they eat.
- **Golden (4/8):** Oozes in front of this gain double when they eat.
- **Details:** two Aspics add up to double. It counts Digest and Nell. B1 is behind F1–F2, B2 behind F2–F3, B3 behind F3–F4.
- **Condition:** she stands in the back row, and the eater stands in a front slot in front of her.
- **Payoff:** +50% on every meal: about +15 stats a turn at R9, +40 at R12 and +250 at R15. In the model the board ends ×1.4 at R12 and ×1.9 at R15.
- **Permanence:** permanent.
- **Enabler:** Dollop, Bubble, Frumenty, Nell and slices.
- **Concentrates:** yes. It also pulls the carry into the front row, where it is hit first. That is the trade.
- *Changed:* was "+1/+1 to what's inside the two Oozes in front". It is now a multiplier on eating. The body is raised to par for a back-row T3.

**Bubble and Squeak** (Two Oozes, Barely). T3, 3/4.
- **Text:** Belly 1. Digest. After this survives a hit: split half its stats into a copy. Once a fight.
- **Golden (6/8):** Belly 1. Digest. After this survives a hit: split half its stats into a copy. Twice a fight.
- **Details:** the copy goes to the nearest empty slot; no room, no split. A hit stopped by Shield counts. Copies don't split.
- **Condition:** fed, hit and alive, with an empty slot nearby.
- **Payoff:** the carry that holds. After eating the Dollop it reaches 65/65 at R9, 155/155 at R12 and 570/570 at R15. In a fight it becomes two halves: two attacks a cycle and half the wasted overkill. In the model at R12, with a 41% carry and equal totals:
  - Shield alone wins 11–30%.
  - Shield plus the split wins 70–88%, and still 57–88% at 0.85 of the total.
  - The plain carry wins 0%.
- **Permanence:** permanent stats; the split is fight only.
- **Enabler:** Moss (Shield makes the first hit a free split) and Aspic.
- **Concentrates:** yes, and it holds.
- *Changed:* gains Digest. The split keeps its stats, and the model prefers that: a split that adds new stats won even at 0.7 of the total.

**The Sixpenny Pie** (Pudding Ooze, Very Full). T3, 2/5.
- **Text:** Belly 2. When this dies: get 1 gold next turn for each unit that comes out.
- **Golden (4/10):** Belly 4. When this dies: get 1 gold next turn for each unit that comes out.
- **Details:** eaten whole, everything inside is eaten too.
- **Condition:** front row with units inside, or eaten whole.
- **Payoff:**
  - Pot route: ~2 gold a fight from R5, about one more meal every one or two turns.
  - Carry route, the turducken: stuff it with two shop units and feed it to the carry. That is three meals in one stomach, for 9 gold: ~45 stats at R9, ~100 at R12, ~320 at R15, in one Digest.
- **Permanence:** gold; or permanent stats through Digest.
- **Enabler:** three-meal turns for a Digest carry, Ooze reserves for Elder, and Syllabub.
- **Concentrates:** yes in the carry route.
- *Changed:* the text is unchanged. The eat rule gives it a second job.

### Tier 4

**Frumenty** (Porridge Ooze, Cook's Taster). T4, 2/3.
- **Text:** Belly 1. Digest. This has the text of the last unit it digested.
- **Golden (4/6):** Belly 2. Digest. This has the text of the last two units it digested.
- **Details:** it doesn't borrow Belly or Digest. Borrowed text reads from its slot.
- **Condition:** digest a unit whose text you want.
- **Payoff:** the carry with a keyword of your choice, at the same stats as Bubble (it usually eats the Dollop or Bubble). Examples:
  - A Cleave neutral. In the model at R12, a carry with Shield and Cleave wins 75–86% at equal totals.
  - Ballooning Spider. From the back row it attacks their back row, where carries hide.
  - Hasty Pudding. It swallows their biggest unit, if its own Belly is empty: a meal or the swallow.
  - Your old Bubble and Squeak. It now splits too.
- **Permanence:** permanent.
- **Enabler:** the Track B neutral keywords and other tribes' text.
- **Concentrates:** yes.
- *Changed:* was "has the text of what's inside it". Now the text stays after the meal.

**Figgy Duff** (Boiled Ooze, Sees Double). T4, 3/5.
- **Text:** Belly 1. A unit inside this goes golden when you buy one more copy.
- **Golden (6/10):** Belly 2. Units inside this go golden when you buy one more copy.
- **Details:** both copies must be bought. The golden goes to your hand.
- **Condition:** a bought unit inside, and a second copy in the shop.
- **Payoff:** a golden from two copies, plus the Triple Reward. The goldens that matter:
  - Stone Soup: the share doubles, to +30/+30 a shop unit at R12. In the model it takes R15 from ~2,700 to ~10,000.
  - Aspic: meals doubled.
  - Nell: two free meals a turn.
  - Dollop: two 1-gold meals a turn.
  - Bubble and Squeak: splits twice.
- **Permanence:** permanent.
- **Enabler:** every Ooze golden, and Discovers.
- **Concentrates:** through its goldens.
- *Changed:* "Once every other turn" is cut. It guarded a loop with Cut-and-Come-Again's copies, which are gone. Belly 1 and gold bound it now.

**Mr Syllabub** (Whipped Ooze, Light Sleeper). T4, 3/6.
- **Text:** When a unit comes out of your Oozes: its Start of Combat fires.
- **Golden (6/12):** When a unit comes out of your Oozes: its Start of Combat fires twice.
- **Condition:** units with Start of Combat text inside your Oozes.
- **Payoff:** answers twice in one fight.
  - A Hasty Pudding kept inside a front Pie comes out and swallows the next-biggest enemy.
  - A neutral "biggest enemy" answer fires a second time.
  - Granny, kept inside a Belly, gathers again.
- **Permanence:** fight only.
- **Enabler:** Hasty Pudding, Granny and neutral answers.
- **Concentrates:** no.
- *Changed:* nothing.

### Tier 5

**Elder Ooze**. T5, 3/7.
- **Text:** End of Turn: your other Oozes permanently gain a tenth of your biggest Ooze's stats.
- **Golden (6/14):** End of Turn: your other Oozes permanently gain a fifth of your biggest Ooze's stats.
- **Details:** Oozes inside Bellies count; Oozes in hand don't.
- **Condition:** a big Ooze, and other Oozes on the board or inside.
- **Payoff:** each other Ooze gains about +6/+7 a turn at R10, +15/+16 at R12 and +57/+57 at R15. Across 4–7 Oozes that is +120–220 board stats a turn at R12 and +450–800 at R15. It keeps supports at about a quarter of the carry. In the model, the carry's share falls from ~70% at R9 to ~41% at R12.
- **Permanence:** permanent.
- **Enabler:** the pot route (Ooze reserves grow inside their Bellies), Granny (more Attack to gather) and Pie.
- **Concentrates:** no. It spreads the pudding to the family, which is the distribution the owner asked for.
- *Changed:* was "units coming out of your Oozes gain +1/+1" (fight only), with Belly 1. It is now permanent and proportional, without a Belly.

**Hasty Pudding** (Steamed Ooze). T5, 2/8.
- **Text:** Belly 1. Start of Combat: if this has room, swallow the biggest enemy.
- **Golden (4/16):** Belly 2. Start of Combat: if this has room, swallow the two biggest enemies.
- **Details:** the swallowed unit comes back out on its own side, in its own slot, when this dies. While inside, it isn't a survivor.
- **Condition:** an empty Belly at Start of Combat, and a Pudding that lives long (back row).
- **Payoff:** their biggest unit sits out until Pudding dies. That is 30–60% of their board: ~60–110 stats at R9, 250–450 at R12, 900–1,500 at R15. In the model at R12, against a board with 60% of its stats in one unit:
  - a plain board wins 47%;
  - with Pudding in F2, 61%;
  - with Pudding in B2, 100%.
- **Permanence:** fight only.
- **Enabler:** Syllabub (swallows twice) and Frumenty (borrows the swallow).
- **Concentrates:** no; it's an answer. It is one of the pool's two or three "biggest enemy" cards (fundamentals, question 2 default).
- *Changed:* "the enemy across" becomes "the biggest enemy", in any row. Where Pudding stands is now the decision.

### Tier 6

**Granny Stir-Up** (Christmas Pudding, Everybody In). T6, 4/8.
- **Text:** Cleave. Start of Combat: touching Oozes go inside this. Gain their Attack.
- **Golden (8/16):** Cleave. Start of Combat: touching Oozes go inside this. Gain twice their Attack.
- **Details:** when this dies, they come out to their own slots, whole.
- **Condition:** an unbroken run of Oozes.
- **Payoff:** one swing with the family's Attack that hits three units: ~300 Attack at R12 (carry 156 plus supports), ~1,000 at R15. Then everyone comes out whole, so the carry hid inside her for the first hits. In the model at R12, the same board wins 10% without her and 75% with her, against a Battlegrounds-shaped board. Gaining Health as well won every fight, so she gains Attack only.
- **Permanence:** fight only.
- **Enabler:** Elder (a bigger family), Syllabub (she gathers again) and Bubble (it comes out and splits).
- **Concentrates:** yes, in the fight.
- *Changed:* adds Cleave, so the gathered Attack isn't wasted as overkill.

**Cut-and-Come-Again** (The Pudding That Is Never Finished). T6, 4/4.
- **Text:** Start of Turn: get a Drip with a fifth of your biggest Ooze's stats.
- **Golden (8/8):** Start of Turn: get two Drips with a fifth of your biggest Ooze's stats.
- **Details:** a Drip is an Ooze with no text. With a full hand, it's lost.
- **Condition:** a big Ooze, and room in your hand.
- **Payoff:** a free unit every turn: ~31/31 at R12, ~115/115 at R15. Play it as a support at a fifth of the carry, or feed it back: +20% on the carry a turn, +30% with Aspic.
- **Permanence:** permanent.
- **Enabler:** free meals for Digest, Oozes for Elder, stuffing for Pie.
- **Concentrates:** either way. The choice comes every turn.
- *Changed:* was "every other Start of Turn: a base copy of the last non-Ooze inside". It is now "have a slice": a free share of the pudding, and the copy loop with Figgy is gone.

**Token: Drip.** Ooze, 1/1, no text. Created, so it sells for 0. Cut-and-Come-Again sets its stats.

## 5. The tribe

### Engine and rate
The Stock Pot (section 2), tuned by `r`, Stone Soup's share. Default 1/10; the sweep picks.

### When the build comes online
- **Carry line:**
  - Behind on R3–6. Dollop is 1/2, and the gold goes into food.
  - Online on R5–6, with Soup, a Digest Ooze and Nell. The share first shows in the shop as +2/+2 to +3/+3.
  - Level by R7–8.
  - Clearly ahead from R9–10, with Bubble or Frumenty, Aspic and Elder.
- **Pot line:**
  - Ahead on R3–8, with bodies and spare lives.
  - Level on R9–12, with Elder.
  - Behind from R13 unless it pivots into the carry.

### The decision the engine creates
- **Each unit you buy:** onto the board as a support, into a Belly as a spare life, or into a stomach as food. And which stomach?
- **Each turn:**
  - Feeding compounds, through the Soup, but leaves fewer bodies and one target.
  - Buying spreads the risk and wins this fight.
- **Each fight:**
  - A front carry gets Aspic's +50%, Shield and the split, and is hit first.
  - A back carry is safe and grows slower.
- **Smaller choices:**
  - Freeze a unit or let Nell eat it.
  - Eat each Cut-and-Come-Again Drip or play it.
  - Eat your carry into a better pudding, or keep two.

### Carry route: the Big Pudding
1. **R1–4:** Little Dollop, and every spare unit into it. Stone Soup when seen.
2. **R5–7:** Nell next to the Dollop. With Aspic, the carry moves to F2 and Aspic goes in B1 or B2. Without Aspic, the carry stands in B2.
3. **R6–9:** eat the Dollop into Bubble and Squeak, or into Frumenty at T4. Add Moss for the Shield, and leave a gap beside the carry for the split.
4. **R9–11:** Elder for the supports. Hasty Pudding if the lobby's carries are big.
5. **R11 on:** Cut-and-Come-Again slices go back into the carry; Granny for Cleave.

Typical R12 board (~760 stats on the board, plus ~160 inside):
```
F1 Sixpenny Pie 34/38 [two Oozes 30/30]   F2 Granny Stir-Up 20/25   F3 Moss Ooze 30/34   F4 Elder Ooze 22/28
        B1 Dishwater Nell 30/32     B2 Bubble and Squeak 156/158, Shield [meal 22/22]     B3 Stone Soup 30/33
```
- Nell in B1 touches B2, so she feeds Bubble.
- All seven are Oozes, so at Start of Combat Granny gathers the run: ~320 Attack with Cleave.
- Every engine piece except Moss works in the Recruit Phase, so it can stand in front as a wall without losing anything. Fights run on a copy.

### Non-carry route: Second Helpings (the pot line)
The biggest Ooze stays in B2 as a pot. It only cooks the shop, through Soup, Elder and slices, and gets one meal a turn. Gold goes into units, and spare units go into front Bellies that don't digest (Posset, Wobbly, Pie, Figgy, Pudding). Ooze reserves first, so Elder grows them while they wait. That makes about 11 bodies a fight, each at a share of the pot.
```
F1 Mrs Posset 20/17 [Ooze 40/42]   F2 Sixpenny Pie 38/43 [two Oozes 38/40]   F3 Wee Wobbly 28/34 [Ooze 38/40]   F4 Elder Ooze 30/40
        B1 Hasty Pudding 25/40 (empty)     B2 Bubble and Squeak, the pot, 121/122     B3 Stone Soup 33/36
```
- Why it works: answers to big units barely hurt it, because its pot rarely fights.
- The model puts it level with the target to round 12 (R12 ~700), with the biggest unit at 29–35% of the board, Battlegrounds' shape. It falls behind the carry line late (R15 ~1,650 against ~2,700). That is its clock.

### Answers to other tribes' carries
1. **Hasty Pudding (T5):** swallows the biggest enemy, in any row. In the back row it holds that unit until your front row falls.
2. **Mrs Posset (T1):** halves its killer's stats. That is often the biggest hitter, and it lands sometimes, not reliably. Strong from R2 to R5. Late, it holds a spare life.
3. **Mr Syllabub (T4):** fires Start of Combat answers again as they come out: a second swallow, a second neutral answer.
4. **Frumenty (T4):** eats an answer and keeps its text. With Hasty Pudding's text it swallows; with Ballooning Spider's it hits the back row.
5. **Granny's Cleave and Bubble's split** answer wide boards rather than carries.

### Weak points
- **Early tempo on the carry line:** Dollop is 1/2, and gold goes into food on R2–6.
- **"Biggest enemy" answers from other tribes and neutrals:** a swallow or a halving takes the carry, which is 40–70% of the board. The split doesn't help against a swallow. Elder's spread and the pot line do.
- **Wide boards with many attacks:** the carry kills one unit per attack. It needs Cleave (Frumenty, Granny) or the split.
- **Placement is readable:** Aspic needs a front carry, Nell must touch it and Bubble needs a gap. A scout sees all of it.
- **Stone Soup:** without it, the line is the low roll (R12 ~340). Soup is T2 with 15 copies, and Figgy's golden Soup is the best highroll.
- **Bellies win softly:** units inside don't count as survivors.
- **Splashing:** Hasty Pudding and Posset fit any board. Soup, Nell, Aspic, Elder, Moss and Cut-and-Come-Again need an Ooze to read, so they don't splash.

### Two highroll moments
1. **The turducken (R10):** golden Aspic sits behind your Bubble in F2. You stuff a Sixpenny Pie with two +10/+10 shop units and feed the whole Pie to Bubble. Next turn it eats all three at double, +90/+90, and every unit in your shop gains +9/+9 while you watch.
2. **Granny's Christmas (R13):** a full run of Oozes. At Start of Combat they all go into Granny, and one 600-Attack Cleave kills three of their units. She falls, and the family comes out whole. Your Bubble's Shield pops and it splits into two 280/280s, while your back-row Hasty Pudding still holds their carry.

### Placement decisions
| Choice | Option A | Option B |
|---|---|---|
| Carry's row | Front (F2–F3): Aspic's +50%, attacks first, needs Shield and the split | Back (B2): safe while the front lives, slower, the pot |
| Nell | Touching the carry, which pins its slot | Elsewhere: she feeds a different Ooze, which spreads |
| Bubble's gap | Leave a front gap beside it: one fewer body, a full split later | Full board: the split waits for a death |
| Hasty Pudding | Back row: holds their carry longest | Front row: opens sooner, while your back row stays safe |
| Recruit-phase engines (Soup, Nell, Elder, Aspic, Cut-and-Come-Again) | Front walls, losing nothing | Back row, kept for Moss and the carry |
| Granny | Inside an unbroken run of Oozes | A gap cuts who joins |

## 6. Harness lines

Two profiles in the format of `tools/sim/line_profiles.json` (on `ideation/harness`).

```json
"line_oozes_carry": {
  "tribe": "Oozes", "base_strategy": "oozes_second_helpings",
  "priority": ["stone_soup", "little_dollop", "dishwater_nell", "aunt_aspic", "bubble_and_squeak",
               "moss_ooze", "cut_and_come_again", "elder_ooze", "frumenty", "hasty_pudding",
               "granny_stir_up", "figgy_duff", "sixpenny_pie"],
  "climb_schedule": [3, 5, 7, 9, 11],
  "save_threshold": 2, "save_until": 10,
  "engine": true, "priority_weight": 14, "tribe_weight": 4
},
"line_oozes_tempo": {
  "tribe": "Oozes", "base_strategy": "oozes_second_helpings",
  "priority": ["wee_wobbly", "mrs_posset", "stone_soup", "sixpenny_pie", "little_dollop", "elder_ooze",
               "hasty_pudding", "mr_syllabub", "granny_stir_up", "cut_and_come_again", "moss_ooze",
               "bubble_and_squeak"],
  "climb_schedule": [3, 6, 8, 10, 12],
  "save_threshold": 0, "save_until": 8,
  "engine": false, "priority_weight": 14, "tribe_weight": 4
}
```

**Saving gold.**
- **Carry line:** bank 2 gold only on the turn before a climb (R4, R6, R8, R10), so the climb and one meal fit in the same turn. Otherwise spend everything, because a meal now compounds through the Soup. From R12, save for a turducken turn (9 gold) when a Pie is on the board.
- **Tempo line:** never save.

**What the line brain needs beyond priorities** (engine support, item 13 below):
1. **Meals:** after the board is set, every spare unit goes into the biggest Digest Ooze with room. Pick the shop unit with the most stats. Use the Dollop's discount while it is the carry.
2. **Carry move:** when Bubble and Squeak or Frumenty arrives, put the Dollop into it from the board, unless the Dollop is golden.
3. **Placement:**
   - With Aspic, the carry goes in F2 and Aspic in B1. Without Aspic, the carry goes in B2.
   - Nell stands next to the carry.
   - Moss and the recruit-phase engines go anywhere.
   - Leave one front gap beside Bubble when there's a spare body.
   - Hasty Pudding goes in B1 or B3.
4. **Pudding:** buy and keep it when the next opponent's biggest unit holds 35% or more of its board.
5. **From R10,** buy one support a turn: the biggest Soup-buffed unit, preferring Oozes for Elder. It replaces the smallest unit.
6. **Drips** go into the carry if it has room; otherwise play them.
7. **Freeze** only for an engine card; otherwise leave the shop to Nell.
8. **Tempo line:** front Bellies get Ooze reserves first, and the pot in B2 gets one meal a turn.

## 7. Engine support needed

1. **Digest:** a Start of Turn trigger. It eats the Belly's contents, nested ones included: they return to the pool, and the eater gains their own Attack and Health permanently, excluding the tribe bonus and Rings.
2. **`eat` effect:** a target selector plus a stat gain, with an "eat multiplier" query that Aspic adds to (+50% each, additive).
3. **A shop stat layer from a player-level live value:** floor(r × the biggest Ooze's Attack/Health), applied to shop units, kept on purchase, best Soup only, doubled on golden. Precedent: pass 1 Soup's per-shop layer.
4. **Selectors:**
   - `biggest_own` with a tribe filter and `exclude_self`, over the board.
   - `biggest_own_next_to` for Nell.
   - `shop_biggest_unfrozen`.
   - `biggest_enemy` exists on `ideation/mechanics`.
5. **Nell:** an End of Turn eat from the shop.
6. **Moss:** grants Shield (Track B) before Start of Combat.
7. **Bubble:** the split already exists. A hit that Shield stops must count as "survives a hit".
8. **Frumenty:** borrows text from a persisted "last digested" record instead of live contents (existing `borrows_text`).
9. **Elder:** End of Turn `stat_fraction` gain (Track B) over other own Oozes, inside Bellies included.
10. **Hasty Pudding:** switch the target to `biggest_enemy`. Golden takes the two biggest.
11. **Posset:** a killer reference on the death event, then `stat_fraction` reduce on both stats.
12. **Granny:** add Cleave (Track B). Drop the Belly requirement on Cut-and-Come-Again, and add "Drip with a fraction of the biggest Ooze" to hand.
13. **Line brain:** meal policy, carry transfer, the placement rules above and the Pudding trigger. Without these the tribe will look weak for the wrong reason, as pass 1 warned.
14. **UI:**
    - the ladle mark on the biggest Ooze;
    - Soup's share shown inside shop stats, with a pot icon;
    - a "next turn +X/+Y" preview on a Digest Ooze;
    - Aspic lighting the two slots it serves;
    - the meal visible floating inside the jelly.
15. **Data only:** Wobbly and Figgy limits removed; Nell and Aspic bodies.

## 8. Risks, and what the sims must check

- **Shape:** sweep `r`. Measure growth from R8, the share of boards at twice the median, the top 1%, and the biggest unit's share (aim 30–45%).
- **Aspic is the common spike.** If Aspic carry lines are more than ~25% of Ooze games and sit at ≥1.9× by R15, the fallbacks are, in order: move Aspic to T4; +33%; count Digest only.
- **Golden Soup is the hottest card** (`r` doubles). Golden Soup with golden Aspic reached ~30× in the model.
  - Rare highrolls don't fail work (9d), so watch how often it happens, not how high it goes.
  - Fallback: golden Soup counts ×1.5, not ×2, and the golden text reads "three twentieths".
- **The carry may hold too well.** With Shield and the split, the model's carry beats equal-total fields 70–88%.
  - The lever is `r` (smaller totals), not the split.
  - If the field sim still shows a common snowball, the fallback is "split after the second hit".
- **Hasty Pudding at "biggest enemy, any row":** run the carry-against-answer sim.
  - In the back row it won every model fight against a 60% carry. That may be too sure.
  - Fallbacks: "the biggest enemy in the front row", or the swallowed unit comes out after Pudding has attacked twice.
- **Turducken rate (eating a Pie whole):** gold bounds it, at three meals for 9 gold. Watch R12+ lines that do it every turn.
- **Elder:** it adds ~0.6 × carry to the board a turn. If the carry's share falls below ~30%, the tribe stops feeling like a carry tribe: drop `e` to 1/20.
- **Fight length:** reserves, splits and Granny's family make fights long. Watch the attack limit.

## 9. Evidence

The scripts are in `oozes-carry-model/`. The combat files extend the audit's `bramble_combat.py` (copied, not changed): split, Belly reserves, swallow the biggest, curdle and Granny's gather.
- **`routes.py`:** growth for both lines, grid-searched against the target (section 2's table).
- **`r12.py`, `r12b.py`, `r12c.py`:** R12 carry holding.
  - Plain carry: 0%.
  - Shield alone: 11–30%.
  - A split that adds new stats wins even at 0.7 of the total, so it was rejected.
  - The stat-keeping split with Shield: 70–88%.
- **`answers.py`:** Hasty Pudding F2 against B2; Posset alone and with a reserve.
- **Granny:** gathering Attack plus Cleave gave 75% against the Battlegrounds shape. Gathering both stats gave 100%, so Attack only.
- **Caveat:** like the audit's model, it is near-deterministic. Fights flip on breakpoints from 0% to 100%, so read it for direction only. The field sims on `ideation/harness` decide.

## 10. Changes from pass 2, in one list

- **New:** Digest (Dollop, Bubble, Frumenty) and the verb Eat.
- **Engine:** Stone Soup becomes the shop share, the engine. Nell eats leftovers. Aspic multiplies eating. Elder spreads the pudding. Cut-and-Come-Again slices it.
- **Answers:** Hasty Pudding targets the biggest enemy. Posset halves its killer.
- **Granny:** gains Cleave.
- **Moss:** gives Shield to the carry.
- **Frumenty:** keeps the text of its last meal.
- **Limits removed:** Wobbly's twice a fight; Figgy's every other turn. Cut-and-Come-Again's copy loop is gone, and so is the reason for Figgy's limit.
- **One new stacking rule:** only the best Stone Soup counts.
- **Unchanged:** Sixpenny Pie text, Mr Syllabub, the tier spread, names and art.
