# Fairies, pass 3: the Fairy Ring (engine-first design)

Track C design panel, engine-first angle. 9 Nov 2026, ideation branch. Designed without a price list. The numbers come from a hand model (scripted boards, no fights), so they size the effects and nothing more. Section 9 gives the model and its limits.

**In short:** a Ring with nobody on it grows by half every End of Turn. A gap you leave on round 3 holds about +30/+30 by round 9 and +100/+100 by round 12. Every turn asks one question: step onto that Ring now and fight with it, or leave it empty and let it grow.

---

## 1. The engine

### What the player assembles

| Piece | Cards | Job |
|---|---|---|
| Seed | Nan Toadstool (T1), Rainbow Chaser (T1), Sally Spore (T2), Spore Cloud and Boundary Stone (spells) | Put the first +1/+1 on a slot |
| Light | Old Moth Annis (T2: empty Rings behind her), Reel-Mistress (T5: every empty Ring), Fairy Monarch (T6: Rings under Fairies) | Make Rings grow. Coverage widens with each tier. |
| Use | Hob, Lob, Silky (pass a Ring's growth to the units beside them), Cradle Fetch (fights with the Ring behind it), Will-o'-the-Wisp (empty Rings fight as Wisps), or stepping a unit onto the Ring | Turn Ring stats into fight power |
| Gather | Queen of Elfland | Pull a tenth of every Ring into one carry |
| Answer | Hedge Witch, Changeling, Lady Belladonna | Beat other tribes' carries |

Brownies are what make the engine work. Shy units ignore Rings, so a brownie can stand on a growing Ring without stopping it. The Ring under it keeps growing, and the brownie passes that growth to the unit beside it. Brownies give an empty field a body in the fight and turn its growth into permanent stats on a real unit.

### Rules it needs (BRAMBLE ideation)

1. **No Ring cap.** 8.5.4 goes (`RING_CAP` in `src/core/board_upkeep.gd`). Under the plan this becomes a data overlay that can be switched back on.
2. **Grow.** A growing Ring gains *g* of its Attack and Health, rounded up, and always at least +1/+1. Reminder: *"A growing Ring gains half its stats, rounded up."*
3. **Once each End of Turn.** A Ring grows at most once each End of Turn. This is a loop guard: growers overlap (Annis's Rings sit inside Mistress's, and two Annises both reach B2), and stacked multipliers are the common runaway. It is the same reason Brann doesn't stack in Battlegrounds. Growth "when played" (Monarch) is outside this limit.
4. **Empty Ring.** An empty Ring is a Ring on a slot with no unit. **A Ring under a Shy unit grows as if empty.** Wisps still need a truly empty slot.
5. **Shy, narrowed.** Only a spell aimed at the unit thanks it. A Ring spell on its slot adds to the Ring and leaves it in place. Today 12.1.7 says "the unit or its slot", which would make seeding a brownie's field send the brownie off.
6. **Rainbow X** replaces painted slots and Bands: *"A unit you play into a slot with no Ring Rings it +X/+X."*

### The rate parameter

**`ring_growth` (g): the share of its stats a Ring gains each time it grows.**
- Default: **1/2**.
- Sweep: 1/3, 1/2 and 2/3. These read cleanly on the reminder, and only the reminder's word changes.
- In the model, 1/2 puts the typical carry line on the September 2025 shape. At 2/3 the line overshoots: round 12 nearly doubles and round 15 quadruples (section 1, sizes).
- Secondary knobs:
  - the Teind share (1/10);
  - rounding (up, or down with a +1 floor);
  - Old Moth Annis's tier (2 or 3);
  - Cluricaun's gold (2).

### The turn the build comes online

- **Round 8** for the carry route: round 7 on a highroll, round 10 on a lowroll. From then on the Rings add more stats each turn than two 3-gold buys.
- **Round 7** for the Wisp route: the turn Will-o'-the-Wisp lands on fields grown since round 3.
- Before that the board is behind. Brownies and Annis are small bodies, lit slots stand empty, and gold goes on seeds.

### The decision it creates

**Fill or tend.** Every grown empty Ring offers the same choice each turn.
- **Fill:** put a unit on it. It fights with the Ring's stats now, but the Ring stops growing.
- **Tend:** leave it empty, or put a brownie on it. It grows by half and fights only through Wisps, Fetch and brownies.

Smaller decisions come from the same engine:
- **Seed or buy:** 2 gold on a Ring spell for a lit field, or a body now.
- **Thank or keep:** a brownie pays 2 gold and frees its slot, or keeps passing growth.
- **Crown the Queen:** move the fed carry out of B2 and seat her there.

### Sizes (hand model, board stats at combat start, g = 1/2)

| Round | 4 | 6 | 7 | 9 | 12 | 15 |
|---|---|---|---|---|---|---|
| Today's bot median (Bramble) | 30 | 52 | 64 | 92 | 133 | ~165 |
| Target shape (Battlegrounds Sep 2025 mean) | 24 | 53 | 79 | 194 | 759 | ~2,600 |
| **Carry route, typical** | 17 | 53 | 65 | 155 | 474 | 2,260 |
| Carry route, highroll (each tier one round earlier) | 26 | 56 | 86 | 191 | 708 | 2,706 |
| Carry route, lowroll (Annis late and badly placed) | 20 | 33 | 36 | 72 | 147 | 310 |
| Wisp route, typical | 20 | 46 | 135 | 313 | 914 | 3,476 |
| Tempo line (Rainbow court, pivots at T5) | 52 | 74 | 99 | 122 | 359 | 1,231 |
| Carry route, typical, at g = 2/3 | 17 | 64 | 91 | 282 | 1,245 | 10,011 |

**What the table shows:**
- **Shape:** the typical carry line is behind on rounds 4–5, level with today's boards on rounds 6–7, then grows about ×1.5 a round.
- **Carry:**
  - Round 12: the carry holds about 97/97 on a 474 board, about 41% of it.
  - Round 15: the crowned Queen is about 525/484 of 2,260, about 45%.
- **Spread:** highroll against typical is about 1.5 times at round 12. The lowroll is the risk (section 8).
- **Goldens:** golden Queen plus golden Silky on a highroll reach about 3,300 at round 15, about 1.3 times the target. Fairies give a modest tail at 1/2. The 10-times tail would need g = 2/3 or several goldens.

---

## 2. The sixteen cards

The spread stays 3/3/3/3/2/2, and every current creature, name and portrait stays.

Card text runs 6 to 16 words, with a median of 12.5. That is slightly over the guide's 11, because the three brownies share a 14–15 word sentence (section 8). The tribe now uses seven terms: Ring, grow, empty Ring, Shy, Rainbow, Nightshade and Wisp. Pass 2 used eleven.

**A typical board for the payoff lines below** (g = 1/2): a lit field holds about **+30/+30 at R9, +100/+100 at R12 and +400/+400 at R15**, and grows by half of that each turn.

| T | Card | Stats | Role | Text |
|---|---|---|---|---|
| 1 | Nan Toadstool | 2/1 | Seed | When played: Ring this slot +1/+1. |
| 1 | Hedge Witch | 1/2 | Answer | Start of Combat: the enemy across loses Attack equal to the Ring under this. |
| 1 | Rainbow Chaser | 1/2 | Seed, gold | Rainbow 1. When sold: get 1 gold per Ring you have. |
| 2 | Hob-in-the-Hearth | 1/4 | Brownie (Health) | Shy. After the Ring under this grows: the units beside this gain that much Health. |
| 2 | Old Moth Annis | 2/3 | Light (behind) | End of Turn: the empty Rings behind this grow. |
| 2 | Sally Spore | 1/3 | Seed | End of Turn: Ring your empty slot nearest this +1/+1. |
| 3 | Lob-Lie-by-the-Fire | 2/4 | Brownie (Attack) | Shy. After the Ring under this grows: the units beside this gain that much Attack. |
| 3 | Cradle Fetch | 2/3 | Use | Start of Combat: gain the stats of the biggest Ring behind this. |
| 3 | Cluricaun | 3/4 | Gold | Rainbow 1. Start of Turn: if all seven slots have Rings, get 2 gold. |
| 4 | Changeling | 2/2 | Answer | Start of Combat: swap sides with the enemy across. Swap back after that enemy attacks once. |
| 4 | Silky | 3/6 | Brownie (both) | Shy. After the Ring under this grows: the units beside this gain that much. |
| 4 | Will-o'-the-Wisp | 3/6 | Use | Start of Combat: summon a 1/1 Wisp into each empty Ring. |
| 5 | Reel-Mistress | 4/7 | Light (all empty) | End of Turn: your empty Rings grow. |
| 5 | Lady Belladonna | 4/8 | Answer | Start of Combat: give the biggest enemy Nightshade. |
| 6 | Fairy Monarch | 6/8 | Light (Fairies), arrival | When played: your Rings grow. End of Turn: the Rings under your Fairies grow. |
| 6 | Queen of Elfland | 8/8 | Gather (carry) | End of Turn: the Ring under this gains a tenth of your other Rings. |

**Printed bodies stay small on purpose.** A Fairy's power is on the ground, so a new unit arrives on a Ring. Monarch's arrival grow is the tier-6 spike. If Track B raises every tribe's bodies, apply the same raise here.

### Tier 1

**Nan Toadstool**, T1, 2/1 (kept)
- **Text:** When played: Ring this slot +1/+1.
- **Golden:** When played: Ring this slot +2/+2.
- **Condition:** played into the slot you want as a field, then moved off it. Moving is free.
- **Payoff:** a +1/+1 seed. Lit from R3 and left empty, it is the whole field: about +27/+27 at R9, +93/+93 at R12 and +315/+315 at R15 (rounding up doubles a +1 early).
- **Permanence:** permanent, on the slot.
- **Enables:** Annis, Mistress (something to grow); Hob, Lob, Silky, Fetch and Will (ways to use it).
- **Concentrates:** yes, one slot.

**Hedge Witch**, T1, 1/2 (reworked: Hex becomes plain text)
- **Text:** Start of Combat: the enemy across loses Attack equal to the Ring under this.
- **Golden:** Start of Combat: the enemy across loses Attack equal to twice the Ring under this.
- **Details:** Uses the Ring's Attack. Attack can't go below 0.
- **Condition:** she stands on a Ring, and the enemy you want to blunt stands across from her.
- **Payoff:**
  - On a tempo board (a seeded front Ring that Monarch later grows): −6 Attack at R9, −36 at R12, −120 at R15.
  - Stepped onto a big field late: −100 at R12, −400 at R15. She also carries those stats herself.
- **Permanence:** a combat effect. Her Ring is permanent.
- **Enables:** Ring spells and Rainbow on her slot; Monarch, which grows her Ring because she's a Fairy.
- **Concentrates:** no. She's an answer.

**Rainbow Chaser**, T1, 1/2 (reworked: Rainbow now seeds Rings)
- **Text:** Rainbow 1. When sold: get 1 gold per Ring you have.
- **Golden:** Rainbow 2. When sold: get 2 gold per Ring you have.
- **Reminder (Rainbow X):** A unit you play into a slot with no Ring Rings it +X/+X.
- **Condition:** units played into bare slots while it's on board. The pot pays when you sell it.
- **Payoff:** 4–7 seeds of +1/+1 over R1–R4, then a pot of 5–7 gold on R3–R5. That pays a tier-up and a buy. The seeds become fields on an engine board or small Rings on a tempo board.
- **Permanence:** the seeds are permanent; the gold is one-shot.
- **Enables:** Cluricaun (seven Rings), Annis and Mistress (seeds to grow), Witch.
- **Concentrates:** no. It spreads seeds.

### Tier 2

**Hob-in-the-Hearth**, T2, 1/4 (reworked)
- **Text:** Shy. After the Ring under this grows: the units beside this gain that much Health.
- **Golden:** Shy. After the Ring under this grows: the units beside this gain twice that much Health. *Details: Shy pays 4 gold.*
- **Condition:** Hob stands on a lit Ring with a unit beside him. He's meant for B1 or B3, beside the B2 carry.
- **Payoff:** the field's growth goes to the carry as Health: about +15 a turn at R9, +50 at R12 and +200 at R15. That adds up to about the field's size: +30, +100 and +400 Health.
- **Permanence:** permanent on the unit.
- **Enables:** a carry of any tribe; he's the reason to keep a field empty before Will.
- **Concentrates:** yes. From B1 or B3 his only neighbour is B2.

**Old Moth Annis**, T2, 2/3 (reworked)
- **Text:** End of Turn: the empty Rings behind this grow.
- **Golden:** End of Turn: your empty Rings in the back row grow.
- **Details:** A Ring under a Shy unit counts as empty.
- **Condition:** she stands in the front row with seeded, empty (or tended) Rings behind her. F2 reaches B1 and B2; F3 reaches B2 and B3; a corner reaches one slot.
- **Payoff:** lights 1–2 fields. Each grows about +15/+15 a turn at R9 and +50/+50 at R12. From T5, Mistress covers the same Rings, and Annis becomes optional.
- **Permanence:** permanent; the growth stays on the slots.
- **Enables:** every seed card; Hob, Lob, Silky, Fetch and Will.
- **Concentrates:** yes, into the 1–2 slots behind her. Placing her is the early puzzle: which field does she light?

**Sally Spore**, T2, 1/3 (kept)
- **Text:** End of Turn: Ring your empty slot nearest this +1/+1.
- **Golden:** End of Turn: Ring your empty slot nearest this +2/+2.
- **Condition:** an empty slot near her. Move her to choose which one.
- **Payoff:** one seed a turn on R3–R8. Lit seeds add about +60/+60 in total by R12, folded into the fields. Her value late is near nothing, so sell her for a body.
- **Permanence:** permanent, on the slot.
- **Enables:** Annis and Mistress; she starts front-row fields for Mistress and Will.
- **Concentrates:** partly. She keeps feeding the same nearest slot.

### Tier 3

**Lob-Lie-by-the-Fire**, T3, 2/4 (reworked)
- **Text:** Shy. After the Ring under this grows: the units beside this gain that much Attack.
- **Golden:** Shy. After the Ring under this grows: the units beside this gain twice that much Attack. *Details: Shy pays 4 gold.*
- **Condition:** as Hob, but Lob gives Attack. Hob on one side of B2 and Lob on the other give the carry both stats.
- **Payoff:** +15 Attack a turn at R9, +50 at R12 and +200 at R15. That adds up to about the field's size.
- **Permanence:** permanent on the unit.
- **Enables:** the B2 carry.
- **Concentrates:** yes.

**Cradle Fetch**, T3, 2/3 (reworked: it copies a Ring, not a unit)
- **Text:** Start of Combat: gain the stats of the biggest Ring behind this.
- **Golden:** Start of Combat: gain twice the stats of the biggest Ring behind this.
- **Condition:** front row, with a big Ring behind it. F1 reads B1, F4 reads B3, and F2 or F3 read whichever of their two is bigger.
- **Payoff:** in fights it holds the field's stats: +30/+30 at R9, +100/+100 at R12 and +400/+400 at R15 (golden doubles). A brownie field then fights twice: through the brownie's growth and through the Fetch.
- **Permanence:** a combat effect. The shop shows it as combat-start stats.
- **Enables:** brownie fields and Wisp fields. It protects the back row with a big front body.
- **Concentrates:** yes, one front unit.

**Cluricaun**, T3, 3/4 (reworked)
- **Text:** Rainbow 1. Start of Turn: if all seven slots have Rings, get 2 gold.
- **Golden:** Rainbow 2. Start of Turn: if all seven slots have Rings, get 4 gold.
- **Condition:** a full rainbow, meaning every slot has a Ring. Rainbow 1 on this card and on the Chaser does most of the work.
- **Payoff:** +2 gold a turn from about R5–6, so about +20 gold by R15. That's about ten Ring spells or six buys. It's the tempo line's climbing money.
- **Permanence:** gold, every turn.
- **Enables:** Ring spells, faster tiers, and the owner's pot of gold ("you've got to do something to go get it").
- **Concentrates:** no.

### Tier 4

**Changeling**, T4, 2/2 (kept)
- **Text:** Start of Combat: swap sides with the enemy across. Swap back after that enemy attacks once.
- **Golden:** Start of Combat: swap sides with the enemy across. Swap back after that enemy attacks twice.
- **Condition:** an enemy across from it worth stealing. Place it from the next opponent's last board.
- **Payoff:**
  - Their carry makes one attack against its own side. At R12, a ~120/120 carry kills one of their ~50/50 units.
  - If the Changeling stood on a Ring, the stolen unit fights with your Ring as well.
  - When it swaps back, it loses the Ring. Its Health drops, and it can die.
- **Permanence:** combat only.
- **Enables:** answers; big Rings make it a weapon.
- **Concentrates:** no.

**Silky**, T4, 3/6 (reworked: the head brownie)
- **Text:** Shy. After the Ring under this grows: the units beside this gain that much.
- **Golden:** Shy. After the Ring under this grows: the units beside this gain twice that much. *Details: Shy pays 4 gold.*
- **Condition:** on a lit Ring beside the carry. She usually replaces Hob or Lob.
- **Payoff:** both stats: +15/+15 a turn at R9, +50/+50 at R12 and +200/+200 at R15. That adds up to about the field's size in each stat.
- **Permanence:** permanent on the unit.
- **Enables:** the carry route's tier-4 step.
- **Concentrates:** yes.

**Will-o'-the-Wisp**, T4, 3/6 (kept)
- **Text:** Start of Combat: summon a 1/1 Wisp into each empty Ring.
- **Golden:** Start of Combat: summon a 2/2 Wisp into each empty Ring. Each Ring refills once.
  - This breaks golden rule 7 on purpose: at this scale a 2/2 base adds nothing. The refill makes each field fight twice, which is the highroll for the Wisp route.
- **Condition:** empty slots that hold Rings. Brownie slots don't count.
- **Payoff:** each field fights as a Wisp with the field's stats. On a typical Wisp board: about 53/53 and 28/28 at R9, 265/265 and 141/141 at R12, and 892/892 and 474/474 at R15.
- **Permanence:** the Wisps are combat-only; the Rings behind them are permanent and visible.
- **Enables:** the non-carry route; Belladonna (more attacks); Annis and Mistress.
- **Concentrates:** no. One Wisp per field, though the biggest field gives a big Wisp.

### Tier 5

**Reel-Mistress**, T5, 4/7 (reworked: her dance now grows the Rings)
- **Text:** End of Turn: your empty Rings grow.
- **Golden:** End of Turn: your Rings grow.
- **Details:** A Ring under a Shy unit counts as empty.
- **Condition:** empty or tended Rings anywhere, front row included.
- **Payoff:**
  - Every field is lit, including front-row gaps and anything Annis couldn't reach.
  - About +55/+55 a turn across the fields at R12 on a carry board and +210/+210 on a Wisp board. At R15 it's +350/+350 to +850/+850.
  - This is the mid-game acceleration.
- **Permanence:** permanent.
- **Enables:** everything; she frees Annis's slot.
- **Concentrates:** no; it grows every field.

**Lady Belladonna**, T5, 4/8 (reworked: biggest enemy, any row)
- **Text:** Start of Combat: give the biggest enemy Nightshade.
- **Golden:** Start of Combat: give the 2 biggest enemies Nightshade.
- **Reminder (Nightshade):** When attacked, it first loses half its current Health.
- **Condition:** they have a carry, and you have many attacks (Wisps, Fetch).
- **Payoff:** a 300-Health carry drops to about 150, then 75, as Fairy units hit it. Two or three hits kill it instead of five to ten.
- **Permanence:** combat only.
- **Enables:** the Fairies' best answer to concentration. It's one of the two or three "biggest enemy" cards the plan wants in the pool.
- **Concentrates:** no.

### Tier 6

**Fairy Monarch**, T6, 6/8 (reworked)
- **Text:** When played: your Rings grow. End of Turn: the Rings under your Fairies grow.
- **Golden:** When played: your Rings grow twice. End of Turn: the Rings under your Fairies grow.
- **Condition:** Rings already on the board; Fairies standing on Rings.
- **Payoff:**
  - On arrival, every Ring grows by half at once: about +55/+55 (carry board) to +210/+210 (Wisp board) across the board at R12, and +350/+350 to +850/+850 at R15.
  - After that, the Rings under Fairy dancers grow every turn too: the Witch's, the Queen's, a Fairy carry's.
  - The King makes the late game compound for the whole Fairy board.
- **Permanence:** permanent.
- **Enables:** the tempo line's late game (its many small Rings start to grow); the Queen.
- **Concentrates:** no on its own. With the Queen, it grows the carry's Ring.

**Queen of Elfland**, T6, 8/8 (reworked: the Teind gathers instead of destroying)
- **Text:** End of Turn: the Ring under this gains a tenth of your other Rings.
- **Golden:** End of Turn: the Ring under this gains a fifth of your other Rings.
- **Details:** The Teind. Your other Rings keep their stats. Rounded down.
- **Condition:** many Rings. She is best seated at B2, between two brownies.
- **Payoff:**
  - Her Ring gains about +10/+10 to +40/+40 a turn at R12 and +70/+70 to +170/+170 at R15, and Monarch grows it on top.
  - Crowned at R12–13 in the B2 seat, she is about 500/500 by R15, including the brownies' growth. Golden: about 940/940.
- **Permanence:** permanent.
- **Enables:** the carry route's capstone.
- **Concentrates:** yes. She is the tier-6 carry.

---

## 3. Routes

### Carry route: the seat at B2

- **Layout:** the carry sits in **B2**, protected by the back row. Brownies tend fields at **B1** and **B3**, and B2 is their only neighbour. Annis stands in F2 (lighting B1) or F3 (lighting B3); two Annises light both. Fetches stand at F1 and F4 and fight with the fields behind them.
- **The carry:** any tribe's unit is fine. The best non-Shy body you hold at round 5 takes the seat. A neutral with a holding keyword is ideal (shield, cleave or damage reduction, from Track B). Keep it all game.
- **At tier 6:** crown the Queen. Move the old carry to the front (it keeps its permanent stats) and seat her at B2.
- **How it holds its stats:**
  - back-row protection;
  - Fetches in front that carry the fields' stats;
  - Rings stay on the slot when units die;
  - the stats are permanent on the unit, so an enemy Changeling can't take them away.
- **Example board, R12 typical (474):**
  - Front: Fetch 98/99 (F1), Annis 5/6, Belladonna 7/11, Mistress 12/15.
  - Back: Silky 6/9 on a +93 field, carry 97/97, Lob 5/7.

### Non-carry route: Wisp fields

- **Layout:** three empty back fields lit by Annis, then by Mistress. Will-o'-the-Wisp arrives at T4, and the fields fight as Wisps behind a thin front row. A Fetch at F1 reads B1.
- **Shape:** wide and even-big. It's stronger in totals than the carry route, but every body is textless and nothing holds stats.
- **Example board, R12 typical (914):** Wisps of 265/265, 141/141 and 13/13 behind Belladonna, Monarch, Mistress and Will.

### Tempo line: the Rainbow court

- **Early:** fill every slot with a Ringed unit from round 1 (Rainbow), and sell the Chaser for its pot. Cluricaun's gold buys fast tiers. Fight with Witch, Fetch, Changeling and good neutral bodies. It's ahead on rounds 3–7.
- **At T5:** pivot. Sell two back bodies so their Rings become fields, and add Will.
- **At T6:** Monarch makes all its small Rings grow.
- **The risk:** it falls behind from round 9 and needs early damage banked (section 8).

---

## 4. Answers and weak points

**Answers to other tribes' carries**
- **Lady Belladonna:** biggest enemy, any row, and halves its Health before each hit. She is the reliable one, and many Wisp and Fetch attacks make her stronger.
- **Changeling:** their carry hits its own side once. On your Ring it hits harder, then shrinks when it goes home.
- **Hedge Witch:** the enemy across loses Attack equal to her Ring. It scales with the Fairy board.
- **Placing them:** the Changeling and the Witch aim across, so place them from the next opponent's last board. They land sometimes, by design. Belladonna always reaches the carry, but only matters once it is attacked.

**Weak points**
1. **Rounds 3–6:** few bodies, small brownies and empty lit slots. Fairies lose early fights by design.
2. **Horseshoe** (neutral spell: halve the Ring across from a slot, next fight). It is the direct answer to a big field, a Fetch or the carry's Ring.
3. **Answers that hit the biggest unit:** the B2 carry or the big Wisp. Proportional halving answers do the same.
4. **The back row falls hard.** Once the front row falls, the back row is brownies (1/4, 2/4, 3/6) and a carry. The carry route is thin up front unless Fetches stand there.
5. **The Wisp route:** textless Wisps die to cleave and area damage, and nothing holds their stats.
6. **The pull to fill fields:** every lost fight pushes the player to step onto a field, which ends its growth.
7. **The lowroll:** missing Annis or placing her badly leaves almost nothing growing until Mistress (section 8).

---

## 5. Two highroll moments

1. **The Wisp night (round 7).**
   - Will-o'-the-Wisp lands on a board that has kept three fields empty since round 3 (+20, +13, +3).
   - At the next fight the board goes from four bodies to seven, and three Wisps rise from the gaps.
   - The board goes from about 50 stats to about 135 with one buy.
   - Golden Will refills every field once, so each Wisp comes back.
2. **The crowning (rounds 11–13).**
   - Fairy Monarch arrives, and every Ring on the board grows at once.
   - Next turn the Queen takes the seat at B2 between Silky and Lob. Her Ring gathers a tenth of every Ring each turn, and Monarch grows it too.
   - She is about 500/500 by round 15. With golden Queen and golden Silky on a highroll, the biggest unit reaches about 1,000/940.

Smaller ones: a golden Cradle Fetch reading a +400 field fights as 800/800. Cluricaun's first full rainbow pays 2 gold every turn after.

---

## 6. Harness lines

Each line is a profile over the Hard brain: a card priority list, a climb schedule, a save threshold, the committed tribe (Fairies) and an engine flag. Card ids are the `content/units` ids. Spells are named separately.

### Line T: tempo (Rainbow court)

- **Engine flag:** off until Reel-Mistress lands, then on (pivot).
- **Buy and keep, in order:**
  1. `rainbow_chaser` (round 1–2 only)
  2. `nan_toadstool`
  3. `hedge_witch`
  4. `cluricaun`
  5. `cradle_fetch`
  6. `changeling`
  7. `belladonna`
  8. `will_o_the_wisp`
  9. `reel_mistress`
  10. `fairy_monarch`
  11. `queen_of_elfland`

  Otherwise buy the highest-tier neutral body, preferring holding keywords. Skip `hob_in_the_hearth`, `lob_lie_by_the_fire`, `silky`, `sally_spore` and `old_moth_annis`.
- **Spells:** `spore_cloud` and `boundary_stone` on the Witch's slot; `harvest_supper` on a Fairy.
- **Play:** while Chaser or Cluricaun is out, always play into a slot with no Ring. Aim for seven Rings by round 5.
- **Sell the Chaser:** the first turn its pot is 5 or more and the gold completes a tier-up or two buys (rounds 3–5).
- **Climb:**
  - T2 on round 2;
  - T3 on round 4 (with the pot);
  - T4 on round 5–6;
  - T5 on round 7–8;
  - T6 on round 9–10.

  Climb whenever you can and still buy one unit.
- **Save:** never before T5. At T5 or above, save toward T6 if the shop has no Fairy of tier 5 or higher.
- **Pivot:** the turn Reel-Mistress lands, sell the two weakest back-row bodies and keep those slots empty. Buy `will_o_the_wisp` next.
- **Placement:**
  - Witch across the scouted opponent's biggest front unit.
  - Changeling across their biggest unit in its row.
  - Fetch in front of the biggest Ring.

### Line E: engine and carry (Fairy ring)

- **Engine flag:** on from round 1. **Fill/tend rule:** never put a non-Shy unit on a lit field. If the board is full, sell the weakest front body rather than fill a field. Cash out (step the best body onto the biggest field) only after two lost fights in a row with Health at 15 or less.
- **Buy and keep, in order:**
  1. `old_moth_annis`
  2. `hob_in_the_hearth`
  3. `nan_toadstool`
  4. `sally_spore`
  5. `lob_lie_by_the_fire`
  6. `cradle_fetch`
  7. `old_moth_annis` (second copy)
  8. `silky`
  9. `reel_mistress`
  10. `queen_of_elfland`
  11. `fairy_monarch`
  12. `belladonna`
  13. `cradle_fetch` (second copy)
  14. `will_o_the_wisp` (only with two or more empty Rings)
  15. `changeling`

  For the B2 seat at round 5, take the best non-Shy body, preferring a holding keyword.
- **Spells:** `spore_cloud` and `boundary_stone` on a lit field (B1 or B3) whenever affordable through round 9. They beat a 3-gold body until round 8. `harvest_supper` on a Fairy. Never aim a unit buff at a Shy unit.
- **Layout:**
  - B1 and B3: brownies; B2: the carry.
  - Annis in F2 (lights B1); a second Annis in F3 or F4 (lights B3).
  - Fetch in F1 or F4; Mistress, Belladonna and Monarch fill the front.
  - Queen into B2 at T6, with the old carry moved to the front.
- **Climb:**
  - T2 on round 2;
  - T3 on round 5;
  - T4 on round 7;
  - T5 on round 9;
  - T6 on round 11–12.
- **Save:** rounds 1–8, spend everything, seeds first. From round 9, save toward the next tier if the shop has no Mistress, Queen, Monarch or Silky.
- **Variant W (the Wisp route, optional third line):**
  - Drop the brownies and keep B1–B3 empty.
  - Buy `will_o_the_wisp` first at T4.
  - Fetch in F1; otherwise as line E.

---

## 7. Engine support needed

| Need | For | Notes |
|---|---|---|
| Ring cap off | All | `RING_CAP` in `board_upkeep.gd` becomes a data overlay (plan Track B: caps switchable) |
| `grow` effect on Rings | Annis, Mistress, Monarch | Fraction `ring_growth`, rounded up with a +1 floor. A once-per-End-of-Turn guard per Ring. Selectors: empty Rings `behind`, all empty Rings, Rings under Fairies, all Rings. "Empty" counts Shy-occupied slots for growth only. |
| `on_ring_grown` trigger with an amount | Hob, Lob, Silky | Fires for the unit standing on that slot. Buffs `beside` with Attack, Health or both equal to the amount (×2 golden). Replaces the Hob/Lob End of Turn effects and `silky.gd`. |
| Combat buff equal to the biggest Ring `behind` | Cradle Fetch | Replaces the copy logic in `cradle_fetch.gd` |
| Combat Attack loss on `across` equal to the own slot's Ring Attack | Hedge Witch | Replaces `hex.gd` |
| Rainbow X | Chaser, Cluricaun | On play into a slot with no Ring, while a Rainbow unit is on board: add a Ring. Chaser `on_sell` pays gold per Ring; Cluricaun `start_of_turn` pays gold if 7 Rings. Retires `rainbow_paint.gd`, `band_attack.gd` and Bands. |
| Target `biggest_enemy` | Belladonna | Track B mechanic |
| Golden refill once per Ring | Will-o'-the-Wisp | A death trigger on Wisps, once per slot a fight |
| Teind gather | Queen | Own Ring += floor(share × sum of other Rings), per stat. Rewrites `teind.gd` and rulebook 12.1.5. |
| Arrival grow | Monarch | `on_play`: grow every Ring (twice golden), outside the End of Turn guard. Rewrites `fairy_monarch.gd`. |
| Grow instead of dance | Reel-Mistress | Rewrites `reel_mistress.gd` (the dance goes to variation notes) |
| Shy narrowed | Shy cards | Slot spells don't thank (`shy.gd`, rulebook 12.1.7) |
| Ring badges | UI | Each Ring shows its next value ("+30 → +45") and a lit mark when something will grow it. Empty fields show the Wisp or Fetch they'll make. Needs 4-digit Rings readable on the phone board (Track B phone check). |
| Line policy support | Harness | The fill/tend rule, the B2 carry seat and the T5 pivot as profile options |

---

## 8. What changed from pass 2, and why

- **Ring cap removed.** The owner wants no per-card size caps as balance. The audit found the +4/+4 cap binds by rounds 8–10 on the slots in use (assumption 2).
- **Rings grow.** Fairies had no compounding text; Monarch was +1/+1 flat. Growth is the engine, and it has one rate.
- **Old Moth Annis:** from +1 Attack to the units behind her (2 stats a turn) to lighting the Rings behind her. She keeps her lantern and her "behind".
- **Hob, Lob and Silky:** from +1 a turn, or a Ring on leaving, to passing their field's growth to the units beside them.
  - Shy becomes a reason to stand on a Ring, and the three-card keyword bar still holds.
  - Their 14–15-word shared sentence is the price.
  - If that's too long: "Shy. Passes its Ring's growth to the units beside it as Health."
- **Rainbow:** painted slots and Bands go. Rainbow now seeds Rings, the Chaser's pot pays per Ring, and Cluricaun pays for a full rainbow. This keeps the owner's leprechaun pot of gold (2 Nov) with one fewer subsystem. Cluricaun's +1 Attack aura was flat and would vanish at the new scale.
- **Hex** folds into Hedge Witch's plain text. It was one card, and a flat Hex capped at your tier dies at the new scale; tying it to her Ring makes it scale.
- **Cradle Fetch** copies a Ring instead of a unit. It keeps the "takes someone else's shape" fantasy and serves the engine.
- **Reel-Mistress:** dance becomes growth.
  - With uncapped Rings, a combat-only wave would be a ×2 multiplier on top of growth, and hard to read.
  - The dance isn't cut. It goes to variation notes as a golden or a later tier-6 variant.
- **Lady Belladonna:** positional to biggest enemy. The plan asks for two or three such answers, and Fairies are the answer tribe.
- **Queen of Elfland:** the Teind changes from destroying the units behind her and sharing their stats evenly, which spread stats and put her on 634 non-Fairy boards, to gathering a tenth of every Ring into hers. That concentrates, and Rings tie it to Fairies. The sacrifice version goes to variation notes.
- **Fairy Monarch:** from +1/+1 above the cap to an arrival grow plus growth under Fairies. That gives tier 6 a visible spike and the tempo line a late game.
- **Bodies:**

  | Card | Pass 2 | Pass 3 |
  |---|---|---|
  | Hob-in-the-Hearth | 1/3 | 1/4 (pass 2's own note) |
  | Old Moth Annis | 2/2 | 2/3 |
  | Lob-Lie-by-the-Fire | 2/3 | 2/4 |
  | Cluricaun | 2/3 | 3/4 |
  | Fairy Monarch | 4/6 | 6/8 |

**Risks for the sims to check, with the knob for each:**
1. **Carry route against Wisp route.** The model gives the Wisp route about twice the stats.
   - The question: do concentration and back-row protection make the B2 carry competitive in fights?
   - Knob: if not, Hob and Lob pass both stats.
2. **Lowroll cliff.** The lowroll is about 0.3 times typical at round 12. It's the risk most likely to make Fairies feel bad.
   - Knob 1: Annis lights all empty back-row Rings (today's golden text) at base.
   - Knob 2: Sally's seeds land already lit.
3. **Mid-game spike on the Wisp route.** About twice today's median at round 7.
   - Knob 1: Will-o'-the-Wisp to tier 5.
   - Knob 2: Annis lights only the one Ring behind her.
4. **Rounding up** makes +1 seeds double early. If rounds 4–8 run hot, round down with a +1 floor.
5. **The tempo line falls off after round 9.** Whether banking damage on rounds 3–7 is enough depends on the damage table, which the plan re-sets with the curve.
6. **Splash.** A non-Fairy board with Annis plus Spore Cloud grows a field.
   - Acceptable as a line.
   - If it dominates, tag Ring spells Fairy or offer them only with a Fairy on board.
7. **Bots.** Without the fill/tend rule, bots fill every field and the engine never shows. The line profiles need the engine flag before any Fairy result means anything.

---

## 9. The model and its limits

- **Scripts:**
  - `fm3.py`: base engine, the tempo line and the earlier carry and Wisp scripts;
  - `fm5.py`: Annis lighting only the Rings behind her (the final rule), plus the highroll, lowroll and Wisp lines;
  - `fm6.py`: Monarch's arrival grow, the final typical carry line and the per-card credit.

  All three are in `build/orchestrator/pass3/fairies-model/`. Line E's numbers come from `fm6.py`.
- **What it does:** each line is a hand-written schedule of buys, seeds and placements by round, with tiers on the typical, highroll or lowroll timing. It applies End of Turn in reading order with the rules above, and sums combat-start Attack plus Health (Wisps and Fetch included).
- **What it leaves out:**
  - fights, opponents and damage;
  - shop luck and gold accounting (spell timing is assumed);
  - neutral bodies, beyond placeholders by tier;
  - Harvest Supper, beyond +1 at three points;
  - win rates of any kind.
- **What it is for:** checking the shape (behind, level, ahead), the rate's effect and rough payoff sizes. Track A's harness and constructed-field fights decide the rest.
