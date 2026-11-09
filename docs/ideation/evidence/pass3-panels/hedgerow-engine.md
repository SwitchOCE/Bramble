# Hedgerow folk, pass 3: the Long Sleep (engine-first design, light pass)

One designer's entry for the Hedgerow panel (Track C, `docs/ideation/plan-scale-rework.md`). Angle: **engine first**. This is a **light pass**: the owner sees "nothing fundamentally too wrong" with Hedgerow (note 2026-11-09a). All 16 cards keep their creature, name and portrait, and the tier spread stays 3/3/3/3/2/2. Paper design only: nothing here has been played or run in Godot.

Board numbers come from a paper model in this folder: `hedgerow-engine-model.py`. Run `python3 -I hedgerow-engine-model.py curve=1 units=1`. It scripts two lines round by round against the target shape used by the other pass 3 models: level with today's lobby to round 7, then ×1.5 a round. It doesn't fight. Read its numbers as the size of the curve, not as measurements.

**In short:** Alderman Dozey now wakes and doubles every third turn he's left alone, the parish feeds him while he sleeps, and Squire Lollop shares his size with the rest of the Line.

## The pitch

Hedgerow keeps its whole identity: Acorns that combine into Stashes and Great Hoards, Pass to the last unit, the Hoard you hold or cash, and Alderman Dozey. Five things change:

1. **Dozey doubles every 3 turns, for good.** Today he doubles once, up to +8/+8, under a +12/+12 ceiling. Now he keeps doing it.
2. **The parish feeds the sleeper.** Acorns, Passes and spells landed before a wake are doubled with him. So the tribe's old question, "cash this now or keep it?", becomes "cash it now, or keep it for the feast?"
3. **The squire shares the wealth.** Squire Lollop now permanently gives Hedgerow folk touching him 10% of your biggest unit each End of Turn. A doubled Dozey lifts the whole Line.
4. **Lollop and the Committee only help Hedgerow folk.** Today both are taken by every tribe: 422 of 568 final boards with Lollop weren't Hedgerow. Both now grow the board permanently.
5. **The flat payoffs scale.** Mrs Mallow doubles your smallest Hedgerow unit. Mrs Clover's summons get half her stats. Mr Crumb Passes his whole self when sold. The Treasurer grows each turn you hold. Goodman Hayward's bonus covers Hedgerow folk now and later. The Sergeant's throw takes a share of its target.

*Similar to:* Battlegrounds' Rivendare-style "do it again" engines and its Quilboar Blood Gems (food you choose to spend now or later). I know of no Battlegrounds card that doubles on a timer you protect by not touching it.

## Why this fixes what's wrong now

| Problem now (`fundamentals.md`, card audit) | Pass 3 answer |
|---|---|
| Dozey's double fires once, capped at +8/+8, under a +12/+12 ceiling that binds by round 10–12 | Every 3 turns in his slot he doubles, uncapped. This is the tribe's compounding engine |
| Lollop is a neutral in practice (70 of 71 Hedgerow wins, 422 of 568 boards other tribes) | Lollop and the Committee give stats to Hedgerow folk only |
| 4 of 13 Hedgerow payoffs are fight-only and invisible in the shop | Lollop, the Committee and Hayward are permanent; Hayward's bonus shows on shop units |
| Flat +1/+1 payoffs vanish at the new scale | Mallow, Clover, Crumb, Lollop and the Sergeant scale with the board; Hayward and the Treasurer scale with the Hoard |
| Caps and limiters: Dozey ceiling, Partner "three times in all", Beadle and Clover rate limits, Treasurer +8/+8 | All removed. The only limits left are structural (one Sergeant throw a fight, the 3-turn wait) |
| Concentration needs a way to hold stats | Dr Urchin Passes **Hunker** to your last unit each fight, so the carry takes half damage |
| Answers that aim across land by layout luck | The Sergeant's throw is now a share (a Stash halves its target) and can be aimed at a back-row carry from the matching back slot. Hedgerow's own Dozey can't dodge, because he mustn't move |

## The engine

### Rules (new or changed)

- **The wake.** "Every 3 turns in this slot" (the Partner's existing wording) now also runs Dozey. The count is End of Turns spent in the same slot, including the turn he's played. Moving him restarts it. **Moving him on the turn right after a wake costs nothing**, because the next count starts then anyway. Tripling him restarts it, since a golden is a new unit.
- **Double** means gain the unit's current Attack and Health permanently (the shared proportional verb, `stat_fraction gain 1/1`). Auras and fight-only buffs don't count; Hayward's standing bonus does.
- **Order at End of Turn.** Recruiting Passes land first, then End of Turn text in reading order (rulebook 3.4.1). This is the one new ordering rule. It makes "feed before you wake" include that turn's Passes. Reading order also matters: a Lollop placed after Dozey in reading order shares Dozey's doubled size.
- **Pass** is unchanged (12.1.6): the last occupied slot in F1-B1-F2-B2-F3-B3-F4. Pass can now carry a keyword (Urchin's "Pass Hunker") and a variable amount (Crumb's "Pass its stats").
- **No new keywords.** Hunker returns to Hedgerow on Dr Urchin. Acorn, Spill, Pass, Bristle and Hunker are the tribe's words.

### How it compounds

Each 3-turn cycle, Dozey becomes **2 × (Dozey + everything fed to him during the cycle)**. What's fed:
- Acorns eaten at +1/+1 per 2 gold;
- Passes from Pym, Beadle and Crumb;
- stat spells you aim at him;
- Hayward's bonus.

Doubling every 3 turns is ×1.26 a round on its own. Feeding, and Lollop's share once he lands, raise Dozey's growth to about ×1.4 a round in the model (R9 to R15). The board then grows through two outlets:
- **Squire Lollop** gives each Hedgerow unit touching him 10% of your biggest unit a turn. With Dozey at a third of the board, that adds about 20–25% of the board each turn.
- **Mrs Mallow** doubles your smallest Hedgerow unit each turn, about 10–12% of an even board.

Together the Supper line grows about ×1.5–1.6 a round from round 12. That's the target shape.

Early food is worth most, because it is doubled at every later wake. A Stash fed on round 6 is +24/+24 by round 12 and +48/+48 by round 15. A Stash fed on round 14 is +6/+6. So the engine rewards investing early, which is when it costs the most tempo.

### The rate parameter: **w = Dozey's gain at each wake**

- **Default +100%** ("double its stats"), every 3 turns. The lever sweep picks the value.
- The model's Supper line, as the mean of an on-time and a one-round-late game, against the typical board:

| w (period 3 unless noted) | R6 | R9 | R12 | R15 | Reads as |
|---|---|---|---|---|---|
| +50% | 1.19× | 0.92× | 0.98× | 1.08× | Flat: the engine never pays |
| +75% | 1.25× | 1.04× | 1.16× | 1.39× | Gentle |
| **+100% (double)** | **1.31×** | **1.17×** | **1.38×** | **1.80×** | **September 2025 shape: level to R11, clearly ahead from R12** |
| +150% | 1.43× | 1.46× | 1.95× | 2.96× | Steep, toward Nov 2026 |
| +50%, every 2 turns | 1.30× | 1.05× | 1.17× | 1.45× | Smoother, fewer big moments |
| +100%, every 2 turns | 1.49× | 1.62× | 2.09× | 3.90× | Too fast |

- I'd keep the word **double** and move the period first (3, then 4) if the sweep says it's hot. "Double" is the moment players remember.
- **Secondary dials, in the order I'd sweep them:**
  1. **Lollop's share:** 10%, with 5% and 15%. It sets how much of the carry reaches the board, and with it the carry's share (now 31–36% at R15).
  2. **Dozey's food:** +1/+1 per 2 gold (today's text) or per gold. Per gold makes R15 about 2.15× instead of 1.80×.
  3. **Hayward:** +1/+1 per gold, or per 2 gold.

### The turn it comes online

- **Dozey's first wake, round 6–7.** He's bought at tier 3 on round 4–5 and wakes on his third End of Turn in the slot. The engine is assembled at tier 4–5 (rounds 7–10): Urchin's Hunker, Pym or Beadle feeding, then Hayward. It pays out at tier 6, when Lollop shares the carry.
- **Behind at once (rounds 3–8).** Most of these costs don't show in stat totals, but they show in fights:
  - The Partner, Pym and Dozey are 1/2, 2/4 and 2/5 bodies.
  - You hold 3–5 gold a turn of Acorns instead of buying with them.
  - You leave F4 empty so Passes land on Dozey in B3, so you fight with six units.
  - 55–75% of your stats sit on one dormouse. Under our combat rules a carry that big loses to an even board of the same total unless it holds its stats (audit §6). Urchin's Hunker is what keeps this window close.
- **Level, rounds 9–11.** Round 11 is a dip, the turn before the second feast.
- **Clearly ahead from round 12.** Lollop and Hayward spread the carry, and the biggest unit's share falls to 31–46%.

### The decision it creates, every turn: cash it now, or keep it for the feast?

Every Acorn item you get asks the same question:
- **Cash it (tempo):** gold now, for a buy, a refresh or the next Tier up. With Hayward on board, cashing also gives every Hedgerow unit +1/+1 per gold.
- **Keep it (invest):** while it waits:
  - the Treasurer grows +1/+1 per gold you hold, each turn;
  - Mother Mast pays an Acorn on each Stash;
  - the third Acorn makes a Stash, which fires Pym;
  - the Sergeant has something worth throwing.
- **Feed it on the wake turn:** everything Dozey eats before End of Turn is doubled. Feeding counts as playing it for Hayward too.

There are three more decisions, all about position:
- **The F4 gap.** Fill F4 and Passes land there, on an exposed unit. Leave it empty and they land on Dozey in B3, but you fight a body short. The usual answer: B3 while he's small, then F4 once he's big and Hunkered.
- **Move him or keep the count.** The scout shows next round's opponent, and moving Dozey to face it restarts his wait. It's free only on the turn right after a wake.
- **Triple him or keep the count.** A golden Dozey keeps all three copies' food and eats twice as much, but he starts his wait again. The best time to triple is right after a wake.

---

## The 16 cards

Stats are Attack/Health. "Payoff" numbers are rough stats delivered by rounds 9, 12 and 15 on a typical Hedgerow board, from the paper model or worked from it. Text counts are in the wording check below.

### Tier 1

**Mrs Burdock, Expecting Again** (Rabbit). Tier 1, **1/2**. *Unchanged.*
- Text: **When played: summon a 1/1 Kit behind this. Spill.**
- Golden (2/4): When played: summon two 1/1 Kits behind this. Spill.
- Condition: a free slot behind her, or none (back row, or front with its back slots full) for the Acorn.
- Payoff: a Kit or 1 gold. With Clover the Kit arrives with half Clover's stats too: about +12 / +40 / +150. Kits are Hedgerow folk, so the Parish grows them like any unit (Parish Kit about 25 / 140 / 280).
- Permanence: permanent body, or economy.
- Enabler: Clover (a summon), Mallow (a smallest), the Committee and Lollop (another body in the Line), Pym and Beadle (the Spilled Acorn).
- Concentrates: no.

**Mr Crumb** (Church Mouse Sidesman). Tier 1, **1/2**. *Changed: sold, he Passes himself.*
- Text: **When played: Pass +1/+1. When sold: Pass its stats.**
- Golden (2/4): When played: Pass +2/+2. When sold: Pass twice its stats.
- Condition: another unit on board; selling him.
- Payoff: +1/+1 now. When sold, his whole size goes onto your last unit. He grows like any Hedgerow unit (Mallow, the Committee, Lollop, Hayward), so selling him moves about +15 / +75 / +250 into the carry.
- Permanence: permanent.
- Enabler: Dozey (doubled at the next wake), the Treasurer; Mallow makes him worth selling.
- Concentrates: **yes**. It's the tribe's tool for piling a support's growth onto the carry.

**The Sleeping Partner** (Dormouse Investor). Tier 1, **1/2**. *Changed: a Stash, and no lifetime.*
- Text: **Every 3 turns in this slot: get a Stash.**
- Golden (2/4): Every 3 turns in this slot: get two Stashes.
- Condition: left alone in one slot.
- Payoff: 5 gold every 3 turns, about 1.7 a turn. Bought on round 1, that's 15 / 20 / 25 gold by rounds 9 / 12 / 15. Fed to Dozey, the first Stash alone is worth +24/+24 by round 12.
- Permanence: economy; permanent once eaten.
- Enabler: Pym (a whole Stash), Dozey (food), the Treasurer (held gold), the Sergeant (ammunition), Mast (a Stash to earn on), Hayward (5 gold played).
- Concentrates: through Dozey.

### Tier 2

**Mrs Clover, Midwife** (Rabbit, Parish Midwife). Tier 2, **2/4**. *Changed: half her stats, no limit.*
- Text: **After you summon a unit: give it half this unit's stats.**
- Golden (4/8): After you summon a unit: give it this unit's stats.
- Condition: you summon, in either phase, any tribe.
- Payoff: Clover grows with the Parish (about 28 / 80 / 300), so each Kit or Shrewlet gets about +12 / +40 / +150. Expect 1–3 summons a turn.
- Permanence: recruit summons keep it; fight summons have it for the fight.
- Enabler: Burdock, Sorrel, any tribe's summoner. A splash is harmless: on another tribe's board she stays about 2/4.
- Concentrates: no.

**Mr Pym** (Vole, Clerk to the Council). Tier 2, **2/4**. *Changed: +3/+3.*
- Text: **After you get a Stash: Pass +3/+3.**
- Golden (4/8): After you get a Stash: Pass +6/+6.
- Condition: three Acorns combine, or a Stash arrives whole (the Partner, Squirrel Away).
- Payoff: about 0.5–1 Stash a turn. On Dozey that is +12/+12 by R9 (about +40 after his wakes), +20/+20 by R12 (about +100), +30/+30 by R15 (about +250).
- Permanence: permanent.
- Enabler: Dozey, the Treasurer. He's the reason to hold the third Acorn.
- Concentrates: **yes**.

**Mrs Sorrel, Harassed** (Shrew Mother). Tier 2, **2/3**. *Unchanged.*
- Text: **After this attacks: summon a 1/1 Shrewlet behind this. Spill.**
- Golden (4/6): After this attacks: summon two 1/1 Shrewlets behind this. Spill.
- Condition: she attacks. In the back row every summon Spills.
- Payoff: in back, 1–1.5 Acorns a fight, the tribe's main fuel: about 6 / 10 / 14 Acorns in all by R9 / R12 / R15. In front, a fight body each attack, worth half Clover's stats.
- Permanence: economy, or fight-only bodies.
- Enabler: Beadle (each Acorn), Pym (the third), Dozey, the Treasurer, Hayward, Clover.
- Concentrates: no.

### Tier 3

**Alderman Dozey** (Dormouse Alderman). Tier 3, **2/5**. *Changed: the wake repeats; no caps.* **The engine.**
- Text: **Acorns played on this: +1/+1 per 2 gold. Every 3 turns in this slot: double its stats.**
- Golden (4/10): Acorns played on this: +2/+2 per 2 gold. Every 3 turns in this slot: double its stats.
- Details: feeding rounds up. Moving it restarts the wait.
- Condition: stay in one slot; be fed before the wake.
- Payoff: about 130 (90–175) by R9, 350 (230–500) by R12, 1,100 (750–1,450) by R15. The range depends on whether a wake has just landed.
- Permanence: permanent and visible. The card shows wake pips.
- Enabler: he's what the Partner, Sorrel, Pym, Beadle, Crumb, stat spells and Lollop point at.
- Concentrates: **yes, the carry**. He's 55–75% of the board from his first wake to tier 5, then 31–46%.

**Dr Urchin** (Hedgehog Apothecary). Tier 3, **2/5**. *Changed: Passes Hunker instead of fight Attack.*
- Text: **Bristle 2. Start of Combat: Pass Hunker.**
- Golden (4/10): Bristle 4. Start of Combat: Pass Hunker. *(Golden Details: also gains Hunker.)*
- Condition: a last unit other than him.
- Payoff: your carry takes half damage from attacks, so it lasts about twice as long. On Dozey that is about +45 / +180 / +600 effective Health against attacks. Bristle pricks back 2–6 a fight, which matters until about round 9.
- Permanence: a keyword grant every fight, printed on the card.
- Enabler: Dozey, the Treasurer, any Pass carry. Of the stat-holding effects, Hunker best fits a hedgehog (spines are Bristle; curling up is Hunker).
- Concentrates: makes concentration work. It's the "hold its stats" piece the audit asks for.

**Sergeant-at-Conkers** (Shrew Sergeant). Tier 3, **3/3**. *Changed: the throw takes a share.*
- Text: **Start of Combat: throw your smallest Acorn at the enemy across. It loses 10% per gold.**
- Golden (6/6): …It loses 20% per gold.
- Details: 10% of its Attack and Health per gold the Acorn is worth, rounded down, to at least 0 Attack and 1 Health. The Acorn is spent. With no enemy across, it stays in hand.
- Condition: an Acorn item in hand, and the enemy you want across from him. Back slots face back slots, so B2 hits a carry in B2.
- Payoff: against a typical enemy carry of about 65 / 250 / 850 stats, an Acorn takes about 6 / 25 / 85, a Stash halves it, and a Great Hoard takes it all.
- Permanence: one-shot, each fight.
- Enabler: holding. Cash loose Acorns first so the smallest item is a Stash. He competes with Dozey and the Treasurer for the same items.
- Concentrates: an answer, not a payoff.

### Tier 4

**Beadle Warrenby** (Rabbit Beadle). Tier 4, **3/5** (was 2/4). *Changed: no once-a-turn limit, +2/+2.*
- Text: **After you get an Acorn: Pass +2/+2.**
- Golden (6/10): After you get an Acorn: Pass +4/+4.
- Details: each Acorn item you get counts once. Combining doesn't.
- Condition: Acorn items arrive: Sorrel, Burdock, the Partner, Mast, Squirrel Away.
- Payoff: 2–3 Acorns a turn mid-game, 4–7 with Mast. On the last unit: about +15/+15 by R9, +40/+40 by R12 (about +120 after a wake), +90/+90 by R15.
- Permanence: permanent.
- Enabler: Dozey and the Treasurer. With Mast, each turn's interest also feeds the carry.
- Concentrates: **yes**.

**Mrs Mallow, Feeding Them Up** (Dormouse, Keeper of the Parish Larder). Tier 4, **3/5**. *Changed: doubles instead of +1/+1; Hedgerow only.*
- Text: **End of Turn: double your smallest Hedgerow unit's stats.**
- Golden (6/10): End of Turn: double your two smallest Hedgerow units' stats.
- Details: smallest means Attack plus Health; ties go to the earlier slot in the zigzag. It can pick itself.
- Condition: End of Turn; Hedgerow folk on board.
- Payoff: each turn it adds your smallest unit's size, about +20 / +70 / +230 a turn. Each support is doubled about once every 5–6 turns.
- Permanence: permanent.
- Enabler: Kits, Crumb (double him, then sell him into the carry), the Partner.
- Concentrates: **no, it spreads by design.** It's the Parish's compounder. It can't pile onto one unit, because a doubled unit stops being smallest.

**The Honorary Treasurer** (Bank Vole). Tier 4, **3/5**. *Changed: grows each turn you hold, permanently; no cap.*
- Text: **End of Turn: gain +1/+1 per gold your Acorns are worth.**
- Golden (6/10): End of Turn: gain +2/+2 per gold your Acorns are worth.
- Condition: Acorn items held in hand at End of Turn.
- Payoff: holding 5–10 gold gives +10–20 a turn at R9, 10–20 gold gives +20–40 at R12, and 25–50 gold with Mast gives +50–100 at R15. Her own size is about 45 / 150 / 400.
- Permanence: **permanent**. She keeps it when you spend, which today's aura doesn't.
- Enabler: the Partner, Sorrel, Mast. She's the other end of the feast decision: she grows while you wait for Dozey's wake.
- Concentrates: **yes (self)**. She's the second carry, so an answer to Dozey doesn't end the game.

### Tier 5

**Goodman Hayward** (Hedgehog, Keeper of the Hedges). Tier 5, **4/7**. *Changed: per gold, now and later.*
- Text: **After you play an Acorn: your Hedgerow folk, now and later, gain +1/+1 per gold.**
- Golden (8/14): …gain +2/+2 per gold.
- Details: cashing it or feeding it to Alderman Dozey both count. Units summoned in fights don't get it. It's a standing tribe bonus beside Harvest Supper's, with no cap.
- Condition: you play an Acorn item.
- Payoff: 2–5 gold played a turn gives every Hedgerow unit about +5–11/+5–11 by R12 and +10–18/+10–18 by R15. A single Great Hoard played is +16/+16 to every Hedgerow unit you'll ever own. Board: about +70–150 by R12, +140–250 by R15.
- Permanence: permanent, and it shows on Hedgerow units in the shop. A new tier's units arrive bigger, which is the progression fix.
- Enabler: every Acorn source; the feast (feeding counts).
- Concentrates: no, it spreads.

**The Standing Committee** (Several Mice in One Coat). Tier 5, **5/7**. *Changed: permanent, Hedgerow only, Attack.*
- Text: **End of Turn: Hedgerow folk touching this gain +1 Attack for each one touching it.**
- Golden (10/14): …gain +2 Attack for each one touching it.
- Details: touching is the unbroken zigzag run through this, including it.
- Condition: a gapless Line of Hedgerow folk. Each gap shortens it.
- Payoff: on a full Line, +7 Attack to each of the 7 every turn (+49 a turn). By R12 that's +7–28 Attack each, by R15 +28–49.
- Permanence: permanent. It used to be a fight-only aura.
- Enabler: wide boards, Kits, Burdock. It pulls against the F4 gap.
- Concentrates: no. It makes the Parish hit hard. Attack-only growth leaves it fragile against Bristle and against units that hold.

### Tier 6

**Squire Lollop, Lord of the Manor** (Hare, Patron of the Living). Tier 6, **6/8**. *Changed: shares the biggest; permanent; Hedgerow only.*
- Text: **End of Turn: Hedgerow folk touching this gain 10% of your biggest unit's stats.**
- Golden (12/16): …gain 20% of your biggest unit's stats.
- Details: biggest means most Attack plus Health, ties in reading order. Rounded down. The share is worked out once, before anyone gains.
- Condition: a Line through Lollop, and something big on your board.
- Payoff:
  - **Supper:** with Dozey about 500 at R12 and 1,450 at R15, each touching unit gains about +50 and +145 a turn, roughly 350 and 1,000 for the board.
  - **Parish:** the biggest is about 100–150 at R12 and 320–470 at R15, so each unit gains about +12 and +40 a turn.
- Permanence: permanent.
- Enabler: Dozey, the Treasurer, any big unit. It's what makes the carry route also a board.
- Concentrates: no, it spreads the carry. The biggest unit gains 10% of itself too when it touches him.

**Old Mother Mast** (Red Squirrel, Keeper of the Great Hoard). Tier 6, **6/8**. *Changed: interest on what you hold (the original design).*
- Text: **Start of Turn: get an Acorn per Stash you hold. A Great Hoard counts as three.**
- Golden (12/16): Start of Turn: get two Acorns per Stash you hold. A Great Hoard counts as three.
- Condition: Stashes and Great Hoards held at Start of Turn.
- Payoff: about 20% interest on the Larder: 2–5 gold a turn when holding, about 10–20 gold in all by R15. It compounds while you don't spend.
- Permanence: economy.
- Enabler: the Treasurer (a bigger Larder), Beadle (more Acorns, so more Passes), Pym (more Stashes), Dozey (bigger feasts), the Sergeant (ammunition).
- Concentrates: through Dozey and the Treasurer.

### Wording check

| Card | Words | Card | Words |
|---|---|---|---|
| Mrs Burdock | 9 | Dr Urchin | 7 |
| Mr Crumb | 9 | Sergeant-at-Conkers | 16 |
| The Sleeping Partner | 9 | Beadle Warrenby | 7 |
| Mrs Clover | 11 | Mrs Mallow | 9 |
| Mr Pym | 7 | The Honorary Treasurer | 11 |
| Mrs Sorrel | 10 | Goodman Hayward | 15 |
| Alderman Dozey | 17 | The Standing Committee | 15 |
| Squire Lollop | 14 | Old Mother Mast | 16 |

Median 9.5, p90 16, max 17 (the guide: median ≤ 11, p90 ≤ 17, max 22). There are no new keywords. Every limit and rounding rule sits in Details. Dozey is the longest card, and at 17 words he's at the guide's p90.

---

## The tribe

### Engine and rate

**The Long Sleep.** Alderman Dozey doubles every 3 turns he's left in his slot. You **assemble** it from:
- Dozey;
- fuel: the Partner, back-row Sorrel, Burdock and Mast;
- feeders: Pym, Beadle and Crumb;
- protection: Urchin's Hunker and the B3 slot;
- outlets: Lollop and Hayward.

You **protect** it by not touching it. The rate parameter is **w, Dozey's gain at each wake** (default +100%, every 3 turns; sweep +50% to +150%).

### Carry route: the Supper

Partner (B1, never moves) → Pym → **Dozey in B3, F4 empty** → back-row Sorrel → Urchin → Mallow or Beadle → Hayward → move Dozey to F4 on the turn after a wake and fill B3 → the Committee → **Lollop** → Mast.

- **The rhythm:** hold, hold, feast. Hold Acorns through the first two turns of each sleep, while the Treasurer grows and Mast pays. On the wake turn, feed all of it and aim stat spells at Dozey before End of Turn.
- **Wins by:** a carry too big for anyone's board, with Hunker to keep it alive and Lollop turning it into a full Line.
- **The second carry: the Treasury.** The Treasurer, Mast and the Sergeant are the same Hoard read the other way: hold everything and spend it as damage. The Treasurer is the Supper's insurance against an answer to Dozey. In a lobby with no carries to answer, she's the Pass target instead.

### Non-carry route: the Parish

Burdock, Crumb, Clover, Sorrel in front, Mallow (two if you can), the Committee, Hayward, Lollop. Cash every Acorn at once.

- **The idea:** many hands, all growing. Mallow keeps doubling the runt, the Committee arms the whole Line, and Clover's Kits and Shrewlets arrive at half her size. Lollop lifts everyone by a tenth of the biggest.
- **Its shape:** the biggest unit is only 18–22% of the board. Under our rules an even board beats a carry of the same total unless the carry holds its stats (audit §6), so the Parish is the tribe's answer to other tribes' carries.
- **Its clock:** tempo. Strong from tier 5 (round 8), level-to-ahead to round 13, then level as the engines overtake it.

### Answers to other tribes' carries

1. **Sergeant-at-Conkers:** a Stash halves the enemy across, and a Great Hoard leaves it 0/1. The scout shows where their carry stood. Put him in the matching slot (B2 faces B2) and cash your loose Acorns so the right item is smallest. It costs a real item every fight.
2. **The Parish itself:** seven even, Committee-armed bodies. Overkill is wasted, so a carry spends a whole attack on each of them.
3. **Bristle** on Urchin pricks swarms and Pack joiners early.

Hedgerow has no "biggest enemy" effect. That is left to neutrals and the answer tribes, on purpose: Hedgerow's answer is aimed and paid for in gold.

### Weak points

- **Early tempo.**
  - Its early bodies are small (1/2, 2/4, 2/5).
  - Held Acorns are gold not spent.
  - The F4 gap is a missing body.
  - Hunters and other tempo boards punish rounds 4–8.
- **One dormouse.**
  - From his first wake to tier 5, Dozey is 55–75% of the board.
  - Without Urchin, an even board or Cleave beats him.
  - Answers that shrink the biggest enemy halve the whole engine.
  - Whirligig Beetle drags a B3 Dozey into the front.
- **He can't move.** You can't rearrange for the scouted opponent without restarting his wait, except on the turn after a wake.
- **The lean turn.** The turn before a feast (round 11 in the model) is the Supper's weakest.
- **Pass goes to F4 when the board is full.** One careless buy into F4 sends every Pass to the wrong unit.
- **Attack-only Committee boards** fold to units that hold (Hunker, Shield, Damage Reduction) and to Bristle.

### Two highroll moments a player will remember

1. **The Michaelmas Feast (round 12).**
   - Dozey has been asleep two turns at 240. You've held a Great Hoard and two Stashes: the Treasurer grew on them and Mast paid interest.
   - On the third turn you feed him all 26 gold (+13/+13), and Hayward gives every Hedgerow unit +26/+26, now and later.
   - Pym and Beadle's Passes land. Then he wakes: about 640.
   - Lollop, after him in reading order, shares 10% of that with the whole Line.
   - The board goes from about 700 to about 1,500 in one End of Turn.
2. **The Sergeant's Great Hoard (round 14).**
   - The scout shows a 1,200-stat carry in your next opponent's B2.
   - You cash two loose Acorns so your smallest item is a Great Hoard, and put the Sergeant in B2.
   - At the bell he lobs 16 gold of acorns across, and their carry is 0/1 before anyone swings.
3. *(A third, rarer one.)* **The Dormitory.**
   - Two Dozeys sleep in B1 and B3 on staggered clocks, fed on alternate feasts.
   - The third copy shows up the turn after both woke. The golden keeps both stacks, eats twice as fast and starts a fresh sleep.

---

## Boards at rounds 6, 9, 12 and 15

From the paper model with the default texts (`python3 -I hedgerow-engine-model.py units=1`, then `late=1`). Units are listed as Attack + Health. "On time" finds each piece on schedule. "Late" finds everything from round 4 one round later, which also shifts Dozey's wakes. Both lines include a generic +4 stats a turn from round 3 for spells and neutrals, since the scripts buy none. The Supper line aims these at Dozey before his wakes. Without them, the Supper is 0.81× / 1.03× / 1.30× typical at R9 / R12 / R15.

**Supper line (engine and carry).** T2 R2, T3 R4, T4 R7, T5 R10, T6 R12.

| Round | On time: board (biggest first) | Total | ×typical | Late: total, ×typical | Mean ×typical |
|---|---|---|---|---|---|
| 6 | Dozey 56, Partner 13, Urchin 7, Pym 6, Sorrel 5 | 87 | 1.67× | 49, 0.94× | 1.31× |
| 9 | Dozey 174, Urchin 14, Partner 13, Pym 12, Sorrel 10, Mallow 8 | 231 | 1.46× | 140, 0.89× | 1.17× |
| 12 | Dozey 505, Lollop 125, Mallow 98, Urchin 96, Partner 95, Committee 94, Hayward 93 | 1,105 | 2.08× | 359, 0.68× | 1.38× |
| 15 | Dozey 1,463, Hayward 601, Mast 480, Lollop 402, Mallow 375, Urchin 373, Committee 371 | 4,066 | 2.27× | 2,378, 1.33× | 1.80× |

Biggest unit's share: 64–75% at R6–9, 46% (on time) to 63% (late) at R12, 31–36% at R15.

**Layout at round 12** (on time; Dozey moved to F4 on round 10, the turn after his wake):
```
F1 Standing Committee   F2 Dr Urchin      F3 Mrs Mallow        F4 Alderman Dozey
        B1 Sleeping Partner    B2 Squire Lollop     B3 Goodman Hayward
```

**Parish line (tempo).** T2 R2, T3 R4, T4 R6, T5 R8, T6 R11.

| Round | On time: board | Total | ×typical | Late: total, ×typical | Mean ×typical |
|---|---|---|---|---|---|
| 6 | Sorrel 10, Burdock 9, Mallow 8, Burdock 7, Crumb 7, Clover 6, Kit 6 | 53 | 1.02× | 40, 0.77× | 0.89× |
| 9 | Hayward 41, Sorrel 33, Mallow 32, Committee 28, Clover 28, Kit 26, Burdock 25 | 213 | 1.35× | 142, 0.90× | 1.12× |
| 12 | Mallow 146, Mallow 142, Committee 120, Hayward 92, Lollop 90, Sorrel 84, Clover 83 | 758 | 1.43× | 510, 0.96× | 1.19× |
| 15 | Mallow 472, Committee 436, Lollop 339, Hayward 335, Clover 297, Sorrel 291, Mallow 265 | 2,435 | 1.36× | 1,792, 1.00× | 1.18× |

Biggest unit's share: 18–22% throughout. The model leaves out the Parish's fight summons (Shrewlets with half Clover's stats), so its real fight strength is above these totals, mostly in rounds 4–9.

**Against the target.**
- Both lines are level with today's game to round 5–7.
- From round 8:
  - **Supper:** grows about ×1.5–1.6 a round in pulses, every 3 turns. The model's dip comes on the turn before each feast.
  - **Parish:** grows about ×1.4 a round, so it slowly falls back toward the typical board.
- **The tail:** golden Dozey (double food), golden Lollop (20%) and golden Hayward together reach 3.7× typical at R12 and 5.4× at R15. That's inside the owner's 10× top 1%, and it needs three tier 3–6 triples.
- **Common snowball:** the Supper's lead depends on finding Dozey by round 5 and Lollop by round 12, and it arrives in pulses an opponent can see coming. Dozey doesn't move, so a Sergeant-style answer lands on him reliably.

**Model limits.**
- No fights, so concentration isn't scored. The harness must test the R7–R11 window, where Dozey holds 55–75% of the board.
- No gold: buys are scripted, so the Supper's tempo cost (held Acorns, the empty F4) shows only in its tier schedule.
- No answers, no Treasurer line, no triples except in the tail run.
- End of Turn resolves the wake before Lollop, which flatters a B3 Dozey slightly.

---

## Harness lines

Card ids are the `content/units/*.json` ids. Both lines: **committed tribe** Hedgerow folk.

### Line 1: `hedgerow_parish` (tempo)

- **Engine flag:** off.
- **Buy and keep, best first:** `squire_lollop`, `standing_committee`, `mrs_mallow`, `goodman_hayward`, `mrs_clover`, `mrs_burdock`, `mrs_sorrel`, `dr_urchin`, `mr_crumb`, `sergeant_at_conkers`, `beadle_warrenby`, `honorary_treasurer`, `mr_pym`, `alderman_dozey`, `old_mother_mast`, `sleeping_partner`.
- **Always buy** a second `mrs_mallow` and copies of `squire_lollop` or `standing_committee` toward triples.
- **Sell first when full:** `mr_crumb` (his stats go to F4, your biggest unit), Kits, `mrs_burdock`, `mr_pym`, `sleeping_partner`, then the smallest unit that isn't Hedgerow.
- **Climb:** T2 R2, T3 R4, T4 R6, T5 R8, T6 R10–11.
- **Acorns:** cash every Acorn item at once. With `goodman_hayward` on board, cash before buying, so new Hedgerow units count from the next play onward.
- **Save gold:** spend out every turn, except what the next scheduled Tier up needs. Refresh up to twice a turn, more only for `standing_committee` at T5 or `squire_lollop` at T6.
- **Placement:**
  - Keep the Line gapless, so all 7 touch.
  - `standing_committee` in B2; `squire_lollop` in B1 or B3, after the biggest unit in reading order.
  - `mrs_sorrel` and `mrs_burdock` in front with a back slot free behind until the board fills.
  - `dr_urchin` in F2 or F3; your biggest unit in F4, the Pass and Hunker slot.
- **Spells:** stat spells on the smallest unit before `mrs_mallow`'s End of Turn.

### Line 2: `hedgerow_supper` (engine and carry)

- **Engine flag:** on.
- **Buy and keep, best first:** `alderman_dozey`, `dr_urchin`, `squire_lollop`, `goodman_hayward`, `mr_pym`, `sleeping_partner` (rounds 1–3 only), `mrs_sorrel` (into a back slot), `beadle_warrenby`, `mrs_mallow`, `old_mother_mast`, `honorary_treasurer`, `standing_committee`, `sergeant_at_conkers`, `mr_crumb`, `mrs_burdock` (into a back slot, for the Acorn), `mrs_clover`.
- **Dozey copies:** buy a second copy whenever offered. Keep it asleep on its own clock in a back slot (B1 once the Partner has paid and been sold, else B2 in place of Sorrel), or hold it in hand. Play the third copy only on a turn right after a wake, so the triple loses no sleep.
- **Sell first when full:** `mrs_burdock`, Kits, `mr_crumb` (sell him to Pass into Dozey once he's at least a fifth of Dozey's size), `mr_pym` after T5, `mrs_sorrel` after `old_mother_mast`, `sleeping_partner` the turn after it pays.
- **Climb:** T2 R2, T3 R4 (R5 at the latest), T4 R7, then stay at T4 through R8–R9 to finish the feeders and Urchin. T5 R10, T6 R12.
- **Acorns (the engine policy):**
  - Hold every Acorn item.
  - On Dozey's wake turn (his 3rd, 6th, 9th End of Turn in his slot), play all of them on him before ending the turn.
  - Cash only to make a scheduled Tier up, or to buy `alderman_dozey`, `dr_urchin`, `squire_lollop` or `goodman_hayward`.
  - With `sergeant_at_conkers` on board and the scout showing a carry across him, cash loose Acorns and keep one Stash or Great Hoard for him.
- **Save gold:**
  - R1–R3: spend out.
  - R3: end with enough for T3 on R4.
  - R5–R9: keep 3 gold for a Dozey copy or `dr_urchin`.
  - R9: save for T5 on R10.
  - R11: save for T6 on R12.
  - From R12: refresh freely; Mast's interest covers it.
- **Placement:**
  - `sleeping_partner` in B1, never moved.
  - `alderman_dozey` in B3 with F4 empty. Move him to F4 on the turn right after a wake, once he has at least 3× the median unit and `dr_urchin` is on board, then fill B3.
  - `mrs_sorrel` in B2; `dr_urchin` in F2 or F3.
  - `squire_lollop` after Dozey in reading order (in back when Dozey is in F4).
  - Never place anything in F4 except Dozey.
- **Spells:** aim stat spells at Dozey on his wake turn.

---

## Risks, loop guards and what the sweep should test

- **Riskiest card: Squire Lollop.**
  - The biggest unit gains 10% of itself when it touches him, which adds about ×1.1 a turn to the carry on top of the wake.
  - If R15 runs hot, first change "Hedgerow folk touching this" to "your other Hedgerow folk touching this". Then lower the share to 5%.
- **Second: Goodman Hayward.**
  - A feast can be 20–30 gold: +20–30/+20–30 to every Hedgerow unit, now and later, in one play.
  - Dials: per 2 gold, or count cashing only.
- **Third: Alderman Dozey, the engine dial w.**
  - Test a B3 Dozey against fields with and without Whirligig Beetle, biggest-enemy shrinks and Cleave.
  - Report how often the round 7–11 Supper loses to an even board of lower total. That is the concentration window.
- **Old Mother Mast: a gold loop.**
  - At 20% (40% golden) interest on held items, Acorns become Stashes, which earn more Acorns.
  - Report the Larder distribution at R12–R16, and the share of games where a single cash-out turn spends 30 gold or more.
  - Fallback: "up to 5 Acorns a turn". That's a rate limit, which is allowed here because this is a loop.
- **The Sleeping Partner: a gold engine at tier 1.** Three Partners make 5 gold a turn from round 3–6. Test 2 Acorns against a Stash.
- **Mrs Mallow with two copies or golden:** +20–25% of an even board a turn. Fallback: "gains half its stats".
- **The Sergeant's Great Hoard:** it deletes any carry for 16 gold. Count its upsets separately from coin flips (plan step 2).
- **Kits triple:** three Burdocks' Kits make a golden Kit and a Triple Reward. Kits are Created and sell for 0. This was flagged before; still worth a look.
- **Loop guards.** None are new, and no size caps remain:
  - Passes don't create Acorns.
  - Dozey's wake counts turns, not triggers.
  - Lollop's share is worked out once a turn.
  - Crumb's sold Pass needs a new Crumb, and tier 1 is 5% of a tier 6 shop.
  - The Sergeant throws once a fight.
- **Snowball check.**
  - Report the share of R12 Hedgerow boards at 2× the field median or more, separately for the Supper and Parish lines.
  - Report it by wake phase: on a wake turn, just after, and the turn before.

## Engine support needed

**Data only (mechanisms exist):**
1. **Dozey:** `turns_in_slot every: 3` (as the Partner uses) with `multiply 2`. Drop `once`, `most` and `permanent_buff_cap`, and the rulebook's 12.1.1a ceiling for him. The caps-off overlay made him double every turn (mechanics review ask 1), because it removed `once` but kept `at_least: 3`. The fix is `every`.
2. **The Partner:** `add_card stash`; drop `lifetime`.
3. **Beadle:** drop `limit`, `stats: 2`, body 3/5. **Pym:** `stats: 3`.
4. **Mallow:** smallest Hedgerow unit, `stat_fraction gain 1/1`. Golden picks two.
5. **Clover:** drop `limit`; `stat_fraction gain 1/2` of the source's stats onto the summoned unit.

**New, in order of need:**
1. **Order at End of Turn:** recruiting Passes land before any End of Turn text.
2. **`stat_fraction` from another unit:** the recipient gains a share of a different unit's stats. Lollop: the friendly biggest (the shared `pick: biggest`). Clover: the source.
3. **Pass with a keyword** (Urchin: Hunker on the last living other unit at Start of Combat) and **Pass with a variable amount** (Crumb: his current stats on sell).
4. **Hayward:** `on_item_played` (exists for pass 2 Hayward) feeding a tribe bonus with `per: gold` and no cap, kept separate from Harvest Supper's capped layer.
5. **Sergeant:** a per-gold percent: `stat_fraction reduce` with `numerator = 10 × gold value` of the thrown item, onto the enemy across.
6. **Treasurer:** an `end_of_turn` permanent buff with `per: larder` (the aura already reads the Larder).
7. **Mast:** `start_of_turn add_card acorn`, count = Stashes + 3 × Great Hoards held.
8. **Committee:** `end_of_turn` Attack to touching Hedgerow folk, `per: count touching Hedgerow`.

**Screens and bots:**
- Wake pips on Dozey showing turns to the next wake. Highlight the slot when moving him would restart it.
- The Larder as a number beside the hand.
- The Pass mark on the last unit (exists).
- Lollop's preview of this turn's share.
- The Supper line's hold-and-feast policy is what bots never do (audit: Hedgerow larder p90 = 2 gold at R8). The harness line is how to see it.

## What changed from pass 2

| Card | Pass 2 | Pass 3 | Why |
|---|---|---|---|
| Mrs Burdock | — | unchanged | Already a clean slot decision |
| Mr Crumb | Played or sold: Pass +1/+1 | Played: Pass +1/+1. Sold: Pass its stats | Late relevance; a concentration tool |
| Sleeping Partner | 2 Acorns every 3 turns, three times | a Stash every 3 turns, no lifetime | Cap removed; fuel at the new scale; fires Pym |
| Mrs Clover | +1/+1 to summons, twice a turn | half her stats to summons, no limit | Scales with the Parish; limit wasn't a loop guard |
| Mr Pym | Pass +2/+2 per Stash | Pass +3/+3 per Stash | Early feed, doubled by the wakes |
| Mrs Sorrel | — | unchanged | The tribe's fuel; already scale-free |
| Alderman Dozey | double once, up to +8/+8; +12/+12 ceiling | double every 3 turns; no caps | The engine |
| Dr Urchin | Bristle 2; after this pricks, Pass +1 Attack (fight only) | Bristle 2; Start of Combat: Pass Hunker | A fight-only flat payoff becomes the carry's stat-holding piece |
| Sergeant-at-Conkers | 3 damage per gold | −10% stats per gold | Answers must scale with carries |
| Beadle Warrenby | 2/4; Pass +1/+1 per Acorn, once a turn | 3/5; Pass +2/+2 per Acorn | Rate limit removed; T4 body |
| Mrs Mallow | smallest +1/+1 | double your smallest Hedgerow unit | Scales; tribe-only |
| Honorary Treasurer | aura +1/+1 per 3 gold held, up to +8/+8 | End of Turn: +1/+1 per gold held, permanent | Cap removed; permanent and visible; she keeps what holding earned |
| Goodman Hayward | +1/+1 to touching per Stash played | +1/+1 per gold, Hedgerow folk now and later | "This game" growth; new buys feel like progress |
| Standing Committee | fight aura +1/+1 or +2/+1, any tribe | End of Turn: touching Hedgerow +1 Attack per touching, permanent | Hedgerow only; permanent |
| Squire Lollop | fight aura +1/+1 or +2/+2, any tribe | End of Turn: touching Hedgerow gain 10% of your biggest | Hedgerow only; permanent; spreads the carry |
| Old Mother Mast | an Acorn after your first buy (2 with a Great Hoard) | an Acorn per Stash held (Great Hoard counts 3) | Interest on the Hoard: holding pays, as first designed |

Portraits: no creature changes. Mr Pym, Mrs Clover, Mrs Mallow, Goodman Hayward and Squire Lollop still use the tribe portrait (`content/portraits_pending.json`). The other eleven keep their art.
