# Oozes, pass 3: "What goes in comes out bigger" (identity and delight)

9 Nov 2026. One designer of the Track C Oozes panel (`docs/ideation/plan-scale-rework.md`, step 1), on the identity-and-delight angle. Paper design: no Godot runs. The numbers come from a growth calculator, not a combat sim: `build/orchestrator/pass3/oozes-wild-model.py`. Run `python3 -I oozes-wild-model.py`, or add `sweep`, `rolls`, `ablate` or `nell`. No price list was used.

## The pitch in three lines

1. **A pudding is an oven.** A unit inside an Ooze in the back row gains half its stats at every Start of Turn. A 4/5 you put in the Sixpenny Pie on round 5, fed by Dishwater Nell, is 42/47 by round 9 and 168/186 by round 12. Everyone can see it through the jelly.
2. **Every turn you choose: fight with it, or let it rise.** Inside, it is safe from every answer and keeps growing, but it only fights if the pudding is cracked. On the board it fights, and it can be answered.
3. **When it comes out, it's an event.** The pie opens and a 600/600 hedgehog walks out. Cut-and-Come-Again serves a half-size slice of it every turn. Granny Stir-Up swallows the whole family at the bell and walks in alone.

**What Battlegrounds doesn't have:** a unit that holds your other units and makes them grow while it holds them. Magnetic merges for good, Reborn brings back the same minion, and Battlegrounds prints no growth that is a share of a unit's own stats. Two cards here do have Battlegrounds relatives, and I say so on each: Stone Soup is close to Nomi's "this game" shop buff, and Dishwater Nell is close to the Demons who eat the tavern.

The owner's words this design is built on:
- "oozes are somewhat similar to how demons play in Battlegrounds. They work around buffing the shop and amalgamating things into them, and eating each other, and combining and splitting" (02h).
- "concentrating stats is always better than spreading them out. This applies doubly if you have units that hold stats really well" (09a).
- "Rewards give the player power, always" (09c).

## Why this fixes what the audit found

| The audit found (`fundamentals.md`; the Oozes card audit) | Pass 3 |
|---|---|
| "Stats do not compound." Card quality compounds, stats don't. | Rise compounds what's inside by ×1.5 a turn. Soup and Elder add two "this game" buffs. |
| No concentration. The biggest Ooze is a 10/12 Soup at R12. | The riser is 36–46% of the board, because it holds stats nobody can touch. Nell feeds the biggest unit inside. Bubble and Squeak merges two units into one. Granny makes one body at the bell. |
| Combat-only payoffs (Elder, Bubble, Granny's Attack) | Rise, Soup, Nell, Aspic, Bubble, Elder, Hasty's digest and Figgy are all permanent and visible. Granny is still combat-only, but she is built from permanent stats the shop shows. |
| Belly felt like storage (pt4 b) | Storage now earns interest. |
| Caps: Soup once a turn, Figgy and Cut-and-Come every other turn | All gone. The only limit left is Soup's "Twice a turn", which guards a real buy-and-sell loop (see "Where it could run away"). |
| Answers aim across: Posset, and Hasty across | Hasty swallows the **biggest enemy** in any row and keeps a quarter of its stats. |
| Hedgerow's lead is one tribe-agnostic aura | Every Ooze payoff reads Bellies or Oozes, so other tribes can't splash it. |

---

## Tribe rules (pass 3)

**Belly N** (kept): *"Holds this many units, safe inside. When this dies, they come out."* The exact rules in `docs/ideation/content/oozes.md` stand: last in comes out first; the first takes the Ooze's slot and the rest go to the nearest empty slots; contents count for triples; buying straight into a Belly is a buy, not a play; no nesting except Granny's gathering.

**Rise** (new keyword, on 3 cards: the Sixpenny Pie, Figgy Duff and Cut-and-Come-Again).
- Reminder (12 words): *"Start of Turn in the back row: what's inside gains half its stats."*
- Details: half of Attack and half of Health, each rounded down, at least +1/+1. It reads printed and permanent stats only, never the tribe bonus, Rings or auras. "Back row" means where the Ooze stood in the last fight.
- **Why Start of Turn:** the shared End of Turn doubler can't double it, so no common card ever turns ×1.5 into ×2.25.
- **Why the back row:** it makes "fight with it or let it rise" a real choice. A front Ooze dies early in most fights and its unit fights, but it doesn't rise. A back Ooze opens only when your front row is gone.
- **Golden** doubles the Belly, not the rate. Golden Pie: Belly 4, still half.

**Taking out** (new rule, no keyword). In the Recruit Phase, drag the last unit in out of a Belly onto an empty slot or into your hand, for free. It isn't played. This replaces the old "sell the Ooze to get it out", which made serving a risen carry cost a card. Nothing triggers on putting a unit in or taking it out except Stone Soup, which needs a buy, so moving units around grants nothing.

**The tribe's two fractions:** "half" (Rise, Nell, Cut-and-Come-Again, Granny) and "a quarter" (Hasty). The sweep moves them; the cards print words, not formulas.

---

## The 16 Oozes

Tier spread kept at 3/3/3/3/2/2. Every name, creature and portrait is kept. Bodies are slightly bigger from tier 3 up, because the target curve wants a tier-up to land near the player's median unit, and Soup's shop buff adds to it.

**How to read the lines.** Payoff numbers are total stats (Attack + Health) on the line that uses the card, at rounds 9 / 12 / 15, with Rise at half. They come from the calculator, on a good roll; a typical roll (named cards a turn late) runs 3–10% lower. "Ablation" means the board's total with the card minus the total with a plain unit of its tier in its place.

### Tier 1

**Little Dollop** (Custard Ooze). Tier 1, **1/3** (was 1/2).
- Text: "Belly 1. Units you buy into this cost 1 gold less."
- Golden 2/6: "Belly 2. Units you buy into this cost 2 gold less."
- Condition: buy a unit straight into it.
- Payoff: a stored body for 2 gold: about 13–17 stats at R9. After that it grows only through Aspic (+2 a turn) or by refilling with a Soup-sized unit.
- Permanence: permanent body; the discount is economy.
- Enabler: Stone Soup (each fill is a cheaper Soup trigger), Elder (one more opening a fight), Figgy (cheap place to keep a copy).
- Concentrates: no.
- Hook: "ROOM FOR ONE MORE!", in a voice that sets dogs off.

**Mrs Posset** (Hot Milk Ooze). Tier 1, **2/2** (was 2/1).
- Text: "Belly 1. When this dies: what comes out attacks at once."
- Golden 4/4: "Belly 2. When this dies: what comes out attacks at once."
- Condition: front row, a unit inside, and she dies.
- Payoff: one extra swing by what's inside. Early that's a tier 1's 2–3 damage. Late it's how a served carry hidden in her gets its first swing in at once: about 10 / 25–150 / 25–600 damage, depending on what you hide.
- Permanence: fight only.
- Enabler: the carry's "hide in front" trick (below), Elder, Mr Syllabub (the unit's Start of Combat fires, then it swings).
- Concentrates: no, but she lets a concentrated unit act first.
- Was: "deal 3 damage to the enemy across". The new text scales with the game; a flat 3 dies by round 8.
- Hook: curdles when contradicted. What's inside her boils over.

**Wee Wobbly** (Junket Ooze). Tier 1, 1/4. **Unchanged.**
- Text: "Belly 1. After this survives a hit: the unit inside comes out, or a 1/1 Drip if empty. Twice a fight."
- Golden 2/8: as now.
- Condition: front row, survives a hit.
- Payoff: releases its unit while it still stands, so two bodies hold the slot: 19 / 47 / 53 on the wide line. Drips are Oozes, so they carry Elder's "this game" buff (+8/+8 by R12, +17/+17 by R15).
- Permanence: fight only.
- Enabler: Elder (each release counts), Syllabub, the wide front row.
- Concentrates: no.
- Hook: bits fall off. He apologises for each one.

### Tier 2

**Stone Soup** (Broth Ooze). Tier 2, **2/3** (was 1/3).
- Text: "Belly 1. After you buy into a Belly: shop units have +1/+1 this game. Twice a turn." (16 words)
- Golden 4/6: "… +2/+2 this game. Twice a turn."
- Condition: buy a unit from the shop straight into any Ooze's Belly.
- Payoff: every unit you buy later is bigger, at every tier. One Soup gives the shop +4 by R9 and +8 by R12; two give +6 and +14, and a line that keeps filling passes +14 by R15. Ablation, per Soup: +59 / +190 to +400 / +710 to +890.
- Permanence: permanent ("this game"), shown on every shop card.
- Enabler: every Belly. Dollop makes fills cheap. Bubble and Squeak empties a place every turn. Nell's meals get bigger. Ovens get bigger dough. Tier-ups arrive at board size.
- Concentrates: no.
- Similar to: Nomi in Battlegrounds (Elementals in the tavern gain stats this game), but triggered by Bellies.
- Hook: has a stone in it, and only needs a little something from everyone.

**Moss Ooze**. Tier 2, 2/4. **Unchanged.**
- Text: "When a spell gives your Ooze stats: what's inside gains them."
- Golden 4/8: "… what's inside gains twice that."
- Condition: stat spells aimed at an Ooze holding units.
- Payoff: one Pinch of Dust on the Pie is +1/+1 on the Pie and on each unit inside, and Rise multiplies those every turn after. Spending 1–2 spare gold a turn this way is worth +20 / +165 / +960 on the carry line.
- Permanence: permanent.
- Enabler: the Pie, Figgy, Cut-and-Come-Again; Pinch of Dust, Elderflower Cordial, Last Orders, Stand Behind Me.
- Concentrates: partly (onto the oven's contents).

**Dishwater Nell** (Scullery Slime). Tier 2, **2/3** (was 1/2).
- Text: "End of Turn: eat your shop's lowest-tier unit. Your biggest unit in a Belly gains half its stats." (17 words)
- Golden 4/6: "End of Turn: eat your shop's 2 lowest-tier units. Your biggest unit in a Belly gains half their stats."
- Details: the eaten unit goes back to the pool. She'll eat a frozen unit too.
- Condition: an Ooze holding a unit, and a leftover in the shop.
- Payoff: half a low-tier unit, plus the Soup buff, into your riser every turn, then multiplied by Rise. Ablation on the carry line: +41 / +158 / +1,136. The late number is big because each meal compounds after it lands.
- Permanence: permanent.
- Enabler: the riser (she always feeds the biggest), Soup (bigger leftovers), the Pie and Cut-and-Come-Again.
- Concentrates: **yes**.
- She reads no slot, so she can stand anywhere.
- Similar to: Battlegrounds' Demons that eat a tavern minion, except the stats go into someone else's belly.
- Was: shop swap and gold. Ooze economy is now stats, not gold (see Weak points).
- Hook: nobody asked her to do the washing-up. Some of the washing-up was alive.

### Tier 3

**The Sixpenny Pie** (Pudding Ooze, Very Full). Tier 3, **2/5** (was 1/4).
- Text: "Belly 2. Rise."
- Golden 4/10: "Belly 4. Rise."
- Condition: back row, units inside.
- Payoff: each unit inside gains half its stats every Start of Turn.
  - Put in on R6 with only Aspic feeding it (the wide line): 19/20, 67/71, 229/242.
  - A 4/5 put in on R5, with Nell and Moss feeding it (the carry line): 42/47, 168/186, 595/655.
  - Ablation: +37 to +69 / +465 to +493 / +1,430 to +2,480.
- Permanence: permanent, and visible through the crust.
- Enabler: Nell, Moss, Aspic, Soup (bigger dough), Figgy (risen goldens), Cut-and-Come-Again (the riser moves in), Granny (the family's biggest pieces).
- Concentrates: **yes**.
- Was: Belly 2 and 1 gold when it dies. The pie bakes now. The blackbirds come out singing.

**Aunt Aspic** (Savoury Jelly). Tier 3, **2/5** (was 1/3).
- Text: "End of Turn: what's inside your Oozes gains +1/+1."
- Golden 4/10: "… gains +2/+2."
- Condition: units inside Oozes.
- Payoff: +2 stats on every unit inside, every turn; 6–8 units inside makes that 12–16 a turn, and in an oven it is multiplied. Ablation on the wide line: +34 / +103 / +212.
- Permanence: permanent.
- Enabler: every Belly, especially ovens.
- Concentrates: no.
- Was: only the Oozes in front of her. Reading the whole board is simpler, and her old slot puzzle fought the ovens for the back row.
- Hook: preserves anything, including grudges.

**Bubble and Squeak** (Two Oozes, Barely). Tier 3, **3/5** (was 3/4).
- Text: "Belly 2. End of Turn: the last unit inside eats the other, gaining its stats."
- Golden 6/10: "Belly 4. End of Turn: the last unit inside eats the others, gaining their stats."
- Details: the eaten unit goes back to the pool.
- Condition: two units inside at End of Turn.
- Payoff: folds a fresh 3-gold buy (with Soup's buff) into a unit you keep. That's about +24 stats a turn at R9, +40 at R12 and +55 at R15, one buy a turn.
- Permanence: permanent.
- Enabler: Soup (her place empties every turn, so every turn has a fill to trigger Soup), the early carry before Rise is big, Granny (bigger single bodies).
- Concentrates: **yes**.
- The decision: a riser left in her for End of Turn misses the next Rise. Early, eating a 3-gold unit beats half the riser's stats; late it doesn't. The player finds that crossover.
- Was: split half its stats when hit. "Combining and splitting" (02h): this is the combining, from last night's leftovers.
- Hook: fried together from yesterday. They still argue about who's on top.

### Tier 4

**Figgy Duff** (Boiled Ooze, Sees Double). Tier 4, **4/6** (was 3/5).
- Text: "Belly 1. Rise. A unit inside this goes golden with one more copy."
- Golden 8/12: "Belly 2. Rise. A unit inside this goes golden with one more copy."
- Details: the golden goes to your hand and keeps every copy's buffs (7.3.4), so a risen unit becomes a risen golden. Cut-and-Come-Again's copies never count.
- Condition: back row; a copy inside; buy the next one.
- Payoff: a second oven, and a golden from two copies with a Triple Reward Discover. The goldens that matter are the engine's: golden Pie (Belly 4), golden Nell (two meals), golden Soup (+2/+2 a fill). As a second oven its riser runs like the Pie's second unit: about 25 / 90 / 290 stats.
- Permanence: permanent.
- Enabler: golden engine pieces, and the carry (a risen golden carry).
- Concentrates: yes (goldens).
- Was: once every other turn. The limit is gone: gold and the shop limit it, and Cut-and-Come-Again's copies can't feed it, so there is no loop.

**Frumenty** (Porridge Ooze, Cook's Taster). Tier 4, **3/6** (was 2/3). Text unchanged.
- Text: "Belly 1. This has the text of what's inside it."
- Golden 6/12: "Belly 2. This has the text of what's inside it."
- Details as now: it can't lend Belly, Fly South, Shy, or on-play, on-sell or on-home text.
- Condition: an empty Ooze, or a unit with text you want twice, inside.
- Payoff: a second copy of any engine.
  - Nell inside: two meals a turn into the riser.
  - Elder inside: +2/+2 on every opening.
  - Soup inside: two shop buffs a fill.
  - Hasty inside: no room left to swallow, unless Frumenty is golden.
- Permanence: whatever it copies.
- Enabler: everything.
- Concentrates: depends.
- Hook: has tried everything once and has notes.

**Mr Syllabub** (Whipped Ooze, Light Sleeper). Tier 4, **4/7** (was 3/6). Text unchanged.
- Text: "When a unit comes out of your Oozes: its Start of Combat fires."
- Golden 8/14: "… fires twice."
- Condition: units with Start of Combat text come out of Bellies.
- Payoff, a combo piece:
  - Hasty hidden in a front Wobbly pops out and swallows a second biggest enemy mid-fight, keeping another quarter. That's about +25 / +65 / +220 permanent stats a fight at R10 / R12 / R15.
  - A neutral Start of Combat answer fires twice.
  - A Granny inside a Belly gathers the run again mid-fight.
- Permanence: fight only, though Hasty's digest is permanent.
- Enabler: Hasty, Granny, neutral Start of Combat answers.
- Concentrates: no.
- Hook: wakes up shrieking. So does everyone around him.

### Tier 5

**Elder Ooze**. Tier 5, **5/9** (was 3/7).
- Text: "Belly 1. After a unit comes out of your Oozes: your Oozes have +1/+1 this game."
- Golden 10/18: "… your Oozes have +2/+2 this game."
- Details: only your own units count; Drips and returned enemies don't. It applies at once in the fight as well.
- Condition: your Oozes open in fights. That's 4–8 a fight on a wide board: each front Belly, Wobbly's release, two from a Pie, and Granny's whole family when she pops.
- Payoff:
  - Every Ooze you own, now and later, gains +4–8/+4–8 a fight: +8/+8 by R12 and +17/+17 by R15 from R9.
  - Wide-line ablation: +202 / +335 (R12 / R15) on the snapshot.
  - Not counted there: the swelling in the fight. Each pudding that pops makes the rest bigger.
- Permanence: permanent ("this game"), shown on the tribe plaque.
- Enabler: Wobbly, Posset, the Pie, Bubble and Squeak, Granny; it also makes Drips real.
- Concentrates: no.
- **It pays most in fights you lose,** because more Bellies open. That's a comeback, not a snowball.
- Was: +1/+1 to units coming out, this fight only.

**Hasty Pudding** (Steamed Ooze). Tier 5, **3/10** (was 2/8).
- Text: "Belly 1. Start of Combat: if this has room, swallow the biggest enemy. Gain a quarter of its stats permanently." (19 words)
- Golden 6/20: "Belly 2. Start of Combat: if this has room, swallow the two biggest enemies. Gain a quarter of their stats permanently."
- Details as now: it goes back when this dies, after 3 of your units die, or when its side has nobody else.
- Condition: an empty Belly at Start of Combat.
- Payoff:
  - The enemy's biggest unit, in either row, sits out until it gets back.
  - Hasty keeps a quarter of it. Against a field whose biggest unit is a third of the board, that makes Hasty 39/47 at R12 and 195/203 at R15. By R15 a pudding has eaten its way to a carry.
- Permanence: the digest is permanent; the swallow lasts the fight.
- Enabler: Syllabub (a second swallow mid-fight), golden Frumenty.
- Concentrates: yes (into itself, from the lobby).
- The decision: an empty Belly answers a carry; a full one stores a riser. Keep it out of Granny's run, or it goes into her before it can swallow.
- Was: "the enemy across". Now it aims at the biggest enemy, one of the pool's two or three back-row answers (owner's default: rarely).

### Tier 6

**Cut-and-Come-Again** (The Pudding That Is Never Finished). Tier 6, **6/8** (was 4/4).
- Text: "Belly 1. Rise. Start of Turn: get a copy of what's inside, with half its stats."
- Golden 12/16: "Belly 2. Rise. Start of Turn: get a copy of each unit inside, with half their stats."
- Details: Oozes inside give no copy. Copies are Created and never count for triples.
- Condition: back row; your best non-Ooze riser moved in.
- Payoff: the riser keeps rising, and every turn a half-size copy of it lands in your hand. Moved in at R11, the riser is 168/186 at R12 and 595/655 at R15. The slices are about 80/90 at R12 and 290/320 at R15, which fills the front with big bodies.
- Permanence: the slices are permanent cards.
- Enabler: the carry, ovens (a slice can rise too), Granny (more bodies), Elder (more openings).
- Concentrates: both ways. It holds one concentrated carry and serves a wide board of its copies.
- Was: a base copy every other turn. "HAVE A SLICE! HAVE ANOTHER!" Now the slice is of the thing you grew.

**Granny Stir-Up** (Christmas Pudding, Everybody In). Tier 6, **6/10** (was 4/8).
- Text: "Start of Combat: touching Oozes go inside this. Gain half the stats of everything inside."
- Golden 12/20: "Start of Combat: touching Oozes go inside this. Gain the stats of everything inside."
- Details: when this dies, they come out to their own slots, still holding what they hold. Oozes in the run go in before their own Start of Combat.
- Condition: an unbroken zigzag run of Oozes through her slot.
- Payoff: one giant pudding at the bell, made of half of the Oozes in the run and everything inside them: about +200 at R12 and +560 at R15 on the wide line, up to twice that with a full run. Then the whole family comes back.
- Permanence: fight only, but made of permanent stats the shop shows at combat start.
- Enabler: the wide route's finisher. Elder counts her family coming out.
- Concentrates: **yes**. The whole board becomes one body.
- Was: Attack only. Attack-only Granny had 8 Health and traded one for one. With stats now inside the Bellies, "half of everything" is the owner's "concentration beats spread" made into a card.
- Hook: every member of the family must stir, and she means every member.

**Token.** Drip, Ooze, 1/1, no text (unchanged). It carries Elder's buff.

---

## The tribe

### Engine and rate parameter

**Engine: Rise.** Back-row ovens multiply what's inside every turn. It needs no fight wins, no combat luck and no other tribe. Everything else either feeds the oven (Nell, Moss, Aspic, Soup, Bubble) or decides what the oven makes (Figgy, Cut-and-Come-Again, Granny).

**Rate parameter: r, the share Rise adds each turn.** Default a half; sweep a quarter, a third, a half (and two thirds as a tail check). In the calculator, the strong carry line at R6 / R9 / R12 / R15 (target 53 / 194 / 759 / 2,600):

| r | Carry line, good roll | Carry, typical | Wide line (+Granny) |
|---|---|---|---|
| a quarter | 72 / 188 / 474 / 1,313 | — | 60 / 189 / 573 / 1,171 |
| a third | 72 / 200 / 552 / 1,758 | 62 / 191 / 547 / 1,729 | 60 / 193 / 609 (+147) / 1,317 (+303) |
| **a half** | **72 / 227 / 763 / 3,383** | 62 / 219 / 764 / 3,361 | **60 / 201 / 709 (+197) / 1,831 (+560)** |

**Secondary levers, if half overshoots:** Nell's share (half, then a quarter), Soup's amount (+1/+1 a fill), Elder's amount (+1/+1 an opening), Granny's share (half), Hasty's share (a quarter) and the slice (half).
- I'd keep "half" on Rise and trim Nell first. Rise is the identity and "half" is the clearest number on a card.
- Nell is what pushes the carry over the target. Without her, the carry line is 599 at R12 and 2,235 at R15. With her feeding both ovens, it's 1,028 and 4,588. Feeding only the biggest unit gives the 763 and 3,383 above.

**Why the shape is right.** An oven behind on R5–7 (a unit idle, two buys spent) is level by R8–9, when the riser is about twice the median unit, and clearly ahead from R10.

### When it comes online

- **Carry, R9–10.** The Pie lands on R5–6 (tier 3). By R9 its riser is 42/47, about 2.5 times the field's median unit. By R10–11 it's bigger than anything the enemy has. Cut-and-Come-Again on R11 turns it into a supply of slices.
- **Wide, R9 then R11.** Soup grows the shop from R3. Elder (R9) makes every opening permanent. Granny (R10–11) finishes the route.
- The clocks differ on purpose. The wide line is ahead to R12, and the carry line is steeper after it.

### The decision the engine creates

**"Fight with it, or let it rise?"** Every turn, each unit you own is in one of three places:
- **in a back oven:** it rises ×1.5, can't be answered, and fights only if your front row falls;
- **in a front Belly:** it fights after its pudding dies, dodges every Start of Combat answer, and doesn't rise;
- **on the board:** it fights from the first swing, and it can be answered.

Smaller choices hang off it:
- What goes in. Stats grow, so a unit with Cleave, Shield or Damage Reduction makes the best dough.
- Whether to feed the oven or the board with your spells.
- Whether to let Nell eat a triple piece.
- Whether to keep a gapless run for Granny, or leave gaps for units to land in.
- Whether to keep Hasty empty to answer, or full to store.

### Carry route: the Thing in the Pie

- **Turns 1–4:** Wobbly, Dollop, Stone Soup, Nell.
- **Turn 5–6:** Sixpenny Pie in the back row. Put in the biggest non-Ooze unit you can find (a 4/5 is fine).
- **Turns 6–10:** Moss Ooze. Spend every spare gold on Pinch of Dust aimed at the Pie. Figgy as a second oven. Hasty at tier 5.
- **Turn 11:** Cut-and-Come-Again over Figgy. Move the riser in, and slices start arriving.
- **Holding stats:**
  - The carry is untouchable while inside.
  - Served, it can hide in a front Belly (Posset or Wobbly) at the last moment, to dodge Start of Combat answers.
  - Its own text (Cleave, Shield, Damage Reduction from Track B neutrals) holds the rest.
- **Biggest unit:** 42/47 (R9), 168/186 (R12), 595/655 (R15); 36–46% of the board. Battlegrounds keeps about 34% in one unit.

### Non-carry route: Second Helpings (wide in the shop, tall at the bell)

- **Turns 1–4:** Wobbly, Posset, Dollop, two Stone Soups. Every buy goes into a Belly while a Soup is out.
- **Turns 5–8:** Aunt Aspic. A Pie as the one oven. Bubble and Squeak eats a fresh unit every turn.
- **Turn 9:** Elder Ooze in the back row, so every opening is permanent.
- **Turns 10–11:** Hasty in F4 with B3 empty (outside the run), and Granny in F2 in a gapless run.
- **Shape:** about 13 bodies from 7 slots, with no unit above a quarter of the board, until Granny makes one at the bell.

### Answers to other tribes' carries

- **Hasty Pudding:** swallows the biggest enemy in any row, and grows by a quarter of it each time. The lobby's runaway becomes the Oozes' meal.
- **Depth:** a giant swing kills one pudding, and a fresh unit steps out into the same slot. Overkill is wasted 7–13 times a fight.
- **Syllabub with a hidden Hasty:** a second swallow, mid-fight.
- **Granny:** one body that trades with a carry, and then a whole board comes back.
- **Posset:** whatever she holds bursts out and swings at once.

### Weak points

- **Early tempo.** Ovens idle a unit from R5, and Ooze bodies are small (1/3 to 2/5). A Hunters or Hedgerow board can take 3–5 rounds off them before R9.
- **Soft wins.** Units inside, or out of a Belly, aren't starting survivors. A narrow Ooze win hits for little more than the round base.
- **Cleave and splash.** A front row of small puddings in a line is what Cleave wants, and what comes out lands in the same row.
- **Locks on Granny.** At the bell she is the whole team, so a Turnip Scarecrow, Pin, Mire or Stalled stops the entire offense.
- **Steals.** A Changeling on Granny takes the family for a fight. A Hex on a Belly's slot hits everything that comes out there.
- **The served carry is answerable:** proportional halving, "destroy the biggest" or a Hasty mirror. Only the oven is safe.
- **No gold engine.** Ooze economy is now stats, not gold. Shared gold levers (Track B) help them like anyone.

### Two highroll moments

1. **The thing in the pie.**
   - R5: a 4/5 neutral goes into the Sixpenny Pie, with Nell beside it.
   - R6–R10: the opponents watch it through the crust (9/10, 15/17, 26/29, 42/47, 69/77), with no way to touch it.
   - R11: Cut-and-Come-Again lands and the riser moves in at 108/120.
   - From R12: "HAVE A SLICE!" Every Start of Turn, a copy at half its size arrives: about 80/90, then 125/140, then 195/215.
   - R15: the riser is 595/655, and two of its slices hold the front row. When a Whirligig finally swaps the rows and cracks the pudding, a 600/650 hedgehog walks into the middle of the fight.
2. **Hasty eats Granny.**
   - The Ooze mirror at R14. Their Granny gathers seven Oozes at the bell and stands alone at about 350/360.
   - Your Hasty Pudding resolves after her and swallows the biggest enemy: Granny, with her whole family inside. It keeps a quarter, +87/+90 for good.
   - Their side has nobody else, so she comes straight back. But your 121/129 Hasty is now about 210/220, and still eating.
   - The same moment happens against a Hunter's Glutton or a Hedgerow Dozey: whoever runs away feeds the pudding.

*A third, for the wide player: Granny at R15 with a gapless run is a 300/300 to 600/600 at the bell, depending on how much of the board joins. When she falls, every pudding drops back into place, and each one spills what it holds.*

---

## Boards at rounds 6, 9, 12 and 15 (calculator, Rise at half, good roll)

Totals count everything inside Bellies. Elder's buff is in the totals but not in the per-unit stats shown. Neither line spends its last 30-odd gold at R15, so real lines run a little higher.

**Carry line (Thing in the Pie):**
```
R6   72  Wobbly 1/4 · Dollop [5/8] · Soup 2/3 · Moss 3/5 · Nell 2/3 · Pie (B3) [9/10]
R9  227  … Figgy (B1) [12/13] · Pie [42/47, 12/13]                    biggest 39%
R12 763  Hasty 39/47 · Cut-and-Come-Again (B1) [168/186] · Pie [48/49, 43/45]   46%
R15 3383 slices 193/213 and 294/324 in front · Hasty 195/203 · CaCA [595/655] · Pie [162/163, 144/150]   36%
```

**Wide line (Second Helpings):**
```
R6   60  Wobbly [6/7] · Posset · Soup · Dollop [5/6] · Pie (B1) · Aspic (B2)
R9  201  every front Belly holds a 9/10–11/12 · Pie [19/20, 19/20] · two Soups   biggest 19%
R12 709  Granny (+197 at the bell) · Hasty 41/49 · Elder [21/22] · Pie [67/71, 67/71] · Oozes +8   19%
R15 1831 Granny (+560) · Hasty 197/205 · Pie [229/242, 229/242] · Oozes +17   25%
```

**Against the target:**
- R6 is 13–36% over, but a third to a half of that sits idle inside.
- R9 is level.
- R12: the carry line is level and the wide line is 0.9× (1.2× with Granny).
- R15: the carry line is 1.3× and the wide line is 0.7× (0.9× with Granny).
- Same order of magnitude, different clocks.
- Calculator limits: no fights, average shops, scripted buys. Granny counts the family twice, so the harness should report her gain separately.

---

## Where it could run away, and the lever for each

1. **A Start of Turn doubler.** Rise would go from ×1.5 to ×2.25 a turn. None exists, and the shared doubler is End of Turn, which is why Rise is Start of Turn. If a Start of Turn doubler is ever made, it is the Oozes' 1% card, never a common neutral.
2. **Every feed into one riser** (Nell, Moss and Pinches, Aspic, Soup). Levers: Nell's share first, then r. This is the common case to watch: the carry line at half is 1.3× the target at R15 on a typical roll too.
3. **Granny's double count.** The family fights as her, then as itself. Levers: her share (half, then a quarter), or "the Oozes beside this" instead of touching.
4. **Slices into ovens.** A slice is a unit, so it can rise; three back slots limit this. If needed: a slice can't go into Cut-and-Come-Again, or the slice drops to a quarter.
5. **The buy-and-sell loop.** A golden Dollop fill costs 1 gold and its unit sells for 1, so buying in and selling out is free. Stone Soup's "Twice a turn" bounds it. Only Soup and Old Mother Mast pay on a buy, and both have a turn limit.
6. **Hasty digesting amalgams.** A quarter of a Granny or a Glutton is a lot, but it's a rare matchup and it feeds the answer side. Lever: Hasty's share.
7. **Fight length.** 13+ bodies a side; watch the 200-attack limit in the harness.

**Snowball check.** Rise grows without wins, Elder grows faster in losses, and Hasty grows off the leader. Nothing here makes winning feed winning. The tail comes from feeds stacking (rows 2–4), which is what the sweep should measure.

---

## Harness line policies

Format as `tools/sim/line_profiles.json` on `ideation/harness`.

### `line_oozes_helpings` (tempo: wide, then Granny)

```json
{"tribe": "Oozes", "base_strategy": "oozes_second_helpings",
 "priority": ["granny_stir_up", "elder_ooze", "stone_soup", "hasty_pudding", "sixpenny_pie",
              "aunt_aspic", "bubble_and_squeak", "wee_wobbly", "mrs_posset", "little_dollop",
              "mr_syllabub", "frumenty", "moss_ooze"],
 "climb_schedule": [3, 5, 7, 8, 10], "save_threshold": 0, "save_until": 0, "engine": false}
```
- **Buy and keep:** in the order above. Keep two Stone Soups; triple Soup or Elder when you see the third copy.
- **Fills:** while a Soup is out, the first two units each turn go straight into a Belly (Dollop first, because it's cheapest; then Bubble and Squeak, because she empties every turn).
- **Places:**
  - Elder in the back row.
  - One Pie in the back row as the only oven.
  - From R10, a gapless Ooze run through Granny (F2).
  - Hasty in F4 with B3 empty, so it stays outside the run. Keep its Belly empty.
- **Gold:** spend everything, except on climb turns.

### `line_oozes_pie` (engine and carry: the Thing in the Pie)

```json
{"tribe": "Oozes", "base_strategy": "oozes_thing_in_the_pie",
 "priority": ["sixpenny_pie", "dishwater_nell", "stone_soup", "moss_ooze", "cut_and_come_again",
              "figgy_duff", "hasty_pudding", "aunt_aspic", "bubble_and_squeak", "wee_wobbly",
              "little_dollop", "mrs_posset", "frumenty", "granny_stir_up"],
 "climb_schedule": [3, 5, 7, 9, 11], "save_threshold": 3, "save_until": 6, "engine": true}
```
- **Save:**
  - From R4, hold 3 gold until the Pie shows, so the Pie and its first unit land on the same turn.
  - From R9, save to reach tier 6 on R11.
  - Otherwise, spend leftover 1–2 gold on Pinch of Dust aimed at the Pie while Moss is out, and Last Orders on the Pie from tier 5.
- **Ovens:** the Pie, Figgy and Cut-and-Come-Again always go in the back row. Nell can go anywhere.
- **First riser:** the highest Attack + Health non-Ooze unit in hand or shop on the turn the Pie lands. Prefer a Cleave, Shield or Damage Reduction neutral.
- **Cut-and-Come-Again:** when it lands, it replaces Figgy. Move the biggest riser into it, and Figgy's unit into the Pie.
- **Serve:** never before R12. From R12, serve the Pie's second riser to the front row if the last fight was lost. Play each slice over the weakest front unit.

### What both lines need from the bot

- A swallow policy: ovens get the biggest non-Ooze; front Bellies get spare bodies.
- A take-out policy (above).
- The gap rule for Granny and Hasty.
- "Keep Hasty empty."
- Without these, the tribe will look weak for the wrong reason (`oozes.md` said the same about the old bots).

---

## Engine support needed

1. **Rise** (keyword; Pie, Figgy, Cut-and-Come-Again): a Start of Turn step for back-row units. `stat_fraction` gain on both stats with ratio r, applied to each unit inside. Floor +1/+1, base and permanent layers only. It runs before other Start of Turn effects, and Cut-and-Come-Again's copy reads after it.
2. **Taking out:** a Recruit Phase action and `LegalActions` entry. It moves the last unit in to an empty slot or the hand, isn't a play, and is free.
3. **Stone Soup:** an `on_buy` condition `into_belly`, plus a "this game" shop buff (rulebook 12.1.3). Twice-a-turn counter.
4. **Dishwater Nell:** End of Turn `eat_shop` (lowest tier, back to the pool), then `stat_fraction` ½ of the eaten unit onto the selector `inside` + `biggest`.
5. **Aunt Aspic:** the selector `inside` over all your Oozes.
6. **Bubble and Squeak:** an End of Turn merge. The last in gains the others' permanent stats; the others go back to the pool.
7. **Figgy Duff:** Rise plus the existing two-copy triple. Remove the every-other-turn counter.
8. **Mrs Posset:** a death trigger on the released unit, "attacks at once" (9.4.12).
9. **Elder Ooze:** an `on_come_out` trigger (own units only), giving the Oozes tribe a "this game" buff (Track B's tribe-wide growth). It applies to the fight copy at once.
10. **Hasty Pudding:** the selector `biggest_enemy` (Track B), the existing enemy swallow, and a permanent `stat_fraction` ¼ of the swallowed unit's current stats onto itself. Golden takes two.
11. **Cut-and-Come-Again:** Rise, then `add_card` of the unit inside with stats set to ½ its current stats. Created, never triples, no Ooze copies.
12. **Granny Stir-Up:** the existing touching gather, with the gain changed from Attack to ½ of the total stats of everything gathered (Oozes and contents). The release is unchanged.
13. **Harness (Track A):** count Belly contents in the snapshot (planned), and report Granny's gain as its own column, because it counts the family twice.
14. **UI:**
    - Each unit inside shows its next Rise as "+21/+23 next turn".
    - Ovens in the back row glow; a front-row Rise Ooze shows "not rising".
    - Shop cards show Soup's buff.
    - The tribe plaque shows Elder's buff.

---

## Variations, if the panel wants another shape

1. **Undisturbed dough.** Rise works only if the oven lived through the last fight. Back-row reach becomes a real answer ("you opened the oven"), but losing then costs a Rise, which is a win-snowball risk.
2. **Rise in either row, but a unit that came out doesn't rise next turn.** One rule instead of "back row". Front ovens rise in fights they win.
3. **A tier 1 oven.** Little Dollop: "Belly 1. Rise." with r at a third. The tribe's trick shows from round 2, but the calculator puts R6 about 30% over target, and Dollop's discount moves to Stone Soup.
4. **Smaller Granny.** "Start of Combat: the Oozes beside this go inside it. Gain their stats." At most two join, so she's positional and readable.
