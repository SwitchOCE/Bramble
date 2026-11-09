# Hedgerow folk, pass 3 synthesis: the Long Sleep

9 Nov 2026. This is the synthesis for the Track C Hedgerow panel (`docs/ideation/plan-scale-rework.md`, step 1). The panel had one design, the engine-first light pass (`hedgerow-engine.md`). I start from it, take the breaker's fixes I accept (`hedgerow-breaker.md`), and change three things my own model found.

This is a paper design: nothing ran in Godot, and no price list was used. The numbers come from a new model in this folder, `hedgerow-pass3-model.py`:
- Run `python3 -I hedgerow-pass3-model.py`. The saved output is `hedgerow-pass3-model.out.txt`.
- **It charges gold.** That was the breaker's main complaint about the designer's model. Income runs 3 to 10 with carry-over. Units cost 3, tier-ups get their per-turn discount, and refreshes cost 1–2 gold a turn. Held Larder items aren't gold you can spend. Spare gold buys flat +1/+1 spells, and there's no free +4 a turn.
- **It fights.** Each line's board fights field boards in a plain Bramble combat: reading order, pointer and flags, back-row protection, Last Blow, Hunker and Bristle. There are four fields:
  - **median:** a 34% carry and six supports;
  - **even:** seven equal units;
  - **strong:** the median shape at 1.35×;
  - **strong+answer:** a strong board where one opponent in three halves your biggest unit at Start of Combat.
- **It scores every round and both schedules.** Each line runs on time and one round late, and fights are scored at every round from R6 to R16. That's breaker point 5: the on-time Dozey wakes exactly on the checkpoint rounds.

The target is the panel's: level with today to R7, then ×1.5 a round. Typical boards are 52 / 158 / 531 / 1,793 at R6 / 9 / 12 / 15. "×typ" means board ÷ typical.

**In short:** Alderman Dozey still doubles every third turn he's left alone, and the parish still feeds him while he sleeps. He now arrives at tier 4, his guard's Hunker ends when the guard dies, and the Committee pays the whole Line by its smallest member, so the wide board has an engine too.

## The pitch

Hedgerow keeps its whole identity:
- Acorns that combine into Stashes and Great Hoards;
- Pass to your last unit;
- the hoard you hold or cash;
- the gapless Line;
- Alderman Dozey, asleep.

Three ways to play it, one tribe question each:
1. **The Supper (carry):** "feed it now, or keep it for the feast?" Hold your Larder while Dozey sleeps. Then feed him everything on his third turn and watch him double. Squire Lollop shares a tenth of him with the Line every morning.
2. **The Parish (wide):** "who's the runt?" Mrs Mallow doubles your smallest Hedgerow unit each turn. The Standing Committee pays everyone in the Line a fifth of the smallest one's stats, so raising the floor raises the whole board.
3. **The Treasury (hold):** "cash it now, or let it grow?" The Treasurer grows on every gold you hold. Old Mother Mast pays interest. Then one turn, with Goodman Hayward down, you cash the lot and every Hedgerow unit you'll ever own gets +1/+1 per gold.

*Similar to:* Battlegrounds' Quilboar Blood Gems (food you spend now or later), Rivendare-style "do it again" engines, and Mrs Mallow is a cousin of Battlegrounds' "your lowest-stat minion" buffs. I know of no Battlegrounds card that doubles on a timer you protect by not touching it, or that pays a whole board by its weakest member.

## What I took, and where from

| From | Kept | Changed |
|---|---|---|
| **The engine design** (base) | The Long Sleep: Dozey doubles every 3 turns in his slot, with no cap, and food is doubled with him. The F4 gap. "Move him or keep the count". Crumb's sold Pass. Mallow doubling the runt. The Sergeant's share-based throw. Hayward's "this game" tribe bonus. Lollop and the Committee tribe-only and permanent. Mast as interest. No new keywords | **Dozey moves to tier 4** and Mallow to tier 3, with Urchin staying at tier 3. Urchin's Hunker becomes an aura that ends when he dies. The Committee is rebuilt. Beadle Passes +1/+1, not +2/+2 |
| **The breaker** | "Except your biggest" on Lollop, and Lollop at Start of Turn. The golden Sergeant throws two items. Mast up to 5 a turn. The Partner pays per Hedgerow unit touching it. One word for the item family. Clover only for Hedgerow summons. The Treasury as its own route and line. Every-round reporting. "Buy every Lollop" in the Supper line | The R6–R11 fix, and the Committee's text. Both are explained below |
| **My model** | — | It found the on-time Supper 1.6× typical at R6 and winning every fight from R6, even with the breaker's swap. The cause is the first wake doubling a stack built since round 1, so Dozey moves to tier 4. Hunker for the whole fight made every fight 0% or 100%, so it became an aura. The breaker's Committee fed the carry, not the Parish, so the Committee now reads the Line |

## Why this fixes what the audit found

| Problem now (`fundamentals.md`, card audit) | Pass 3 answer |
|---|---|
| Dozey's double fires once, capped at +8/+8, under a +12/+12 ceiling | Every 3 turns in his slot he doubles, with no cap. This is the tribe's compounding engine |
| Lollop is a neutral in practice (70 of 71 Hedgerow wins; 422 of 568 boards were other tribes') | Lollop and the Committee give stats to Hedgerow folk only. The Partner pays per Hedgerow unit touching it |
| 4 of 13 Hedgerow payoffs are fight-only and invisible in the shop | Lollop, the Committee, the Treasurer and Hayward are now permanent. Hayward's bonus shows on shop units |
| Flat +1/+1 payoffs vanish at the new scale | These now scale with the board: Mallow, Clover, Crumb, Lollop, the Committee and the Sergeant. Hayward, the Treasurer and Mast scale with the Larder |
| Caps and limiters: Dozey's ceiling, the Partner's "three times in all", Beadle's and Clover's rate limits, the Treasurer's +8/+8 | All removed. One rate limit stays on a loop (Mast, up to 5 a turn). The structural limits stay: the 3-turn wait and one throw a fight |
| Concentration needs a way to hold stats, and answers must reach a carry sometimes | Urchin gives your last unit Hunker while he lives. Kill Urchin and the carry is exposed. Dozey can't move without losing his count, so aimed answers find him |
| No tail | Goldens reach 2.9–3.6× typical at R15–R16, and a golden Parish 5.8–8.6×. No ordinary line reaches 2× at a checkpoint |

---

## Tribe rules (new or changed)

- **Larder** (a term, not a keyword). Reminder: *"Your Acorns, Stashes and Great Hoards, and the gold they're worth."* The Larder total shows beside the hand, with the hand limit (10 cards, rulebook 7.1.1).
  - "Acorn" now means only the 1-gold item.
  - "Larder item" means any of the three. This answers breaker point 11.
- **Get counts combining.** A Stash formed from three Acorns is a Stash you get (Pym). Combining never makes an Acorn, so Beadle counts only real Acorns. One rule for both cards.
- **The wake.** "Every 3 turns in this slot" (the Partner's wording) counts End of Turns spent in the same slot, including the turn the unit is played.
  - Moving the unit restarts the count. Moving it on the turn right after a wake costs nothing.
  - A triple restarts it, because the golden is a new unit.
  - **Dozey wakes after your other End of Turn effects.** So everything that lands that turn is doubled with him: food, Passes, the Committee's share, the Partner's Acorns and the Beadle Passes they fire. This makes "feed before you wake" one rule with no reading order to learn. It finishes breaker point 10.
- **Double** means gain your current Attack and Health permanently. Tribe bonuses (Hayward, Harvest Supper) count. Auras and fight-only buffs don't.
- **Recruiting Passes land first at End of Turn,** then End of Turn text resolves in reading order (rulebook 3.4.1, 12.1.6). A Pass fired during End of Turn lands at once.
- **Hunker on the last unit is an aura.** Urchin gives it to your last unit (the Pass order F1-B1-F2-B2-F3-B3-F4) while he lives. Like any aura it's worked out again as units die (12.2.1).
- **Crumb's sold Pass** moves his own stats. His tribe bonuses stay behind, as in the Queen of Elfland ruling (12.1.5).
- **Hayward's bonus** is a standing tribe bonus with no cap, beside Harvest Supper's. Units summoned in fights don't get it.
- **No new keywords.** Acorn, Stash, Great Hoard, Spill, Pass, Bristle and Hunker are the tribe's words. Larder is a term with a reminder and a number on screen.

---

## The 16 cards

The tier spread stays 3/3/3/3/2/2, and every creature, name and portrait is kept.

| T | Card | Stats | Text | Golden |
|---|---|---|---|---|
| 1 | Mrs Burdock | 1/2 | When played: summon a 1/1 Kit behind this. Spill. | 2/4. …two 1/1 Kits… |
| 1 | Mr Crumb | 1/2 | When played: Pass +1/+1. When sold: Pass its stats. | 2/4. …Pass +2/+2. …Pass twice its stats. |
| 1 | The Sleeping Partner | 1/2 | Every 3 turns in this slot: get an Acorn per Hedgerow unit touching this. | 2/4. …two Acorns per… |
| 2 | Mrs Clover | 2/4 | After you summon a Hedgerow unit: give it half this unit's stats. | 4/8. …give it this unit's stats. |
| 2 | Mr Pym | 2/4 | After you get a Stash: Pass +3/+3. | 4/8. …Pass +6/+6. |
| 2 | Mrs Sorrel | 2/3 | After this attacks: summon a 1/1 Shrewlet behind this. Spill. | 4/6. …two 1/1 Shrewlets… |
| 3 | Mrs Mallow | 2/5 | End of Turn: double your smallest Hedgerow unit's stats. | 4/10. …your two smallest Hedgerow units'… |
| 3 | Dr Urchin | 2/5 | Bristle 2. Your last unit has Hunker. | 4/10. Bristle 4. Your last two units have Hunker. |
| 3 | Sergeant-at-Conkers | 3/3 | Start of Combat: throw your smallest Larder item across. That enemy loses a tenth of its stats per gold. | 6/6. …throw your two smallest Larder items across… |
| 4 | Alderman Dozey | 3/6 | Larder items played on this: +1/+1 per 2 gold. Every 3 turns in this slot: double its stats. | 6/12. …+2/+2 per 2 gold… |
| 4 | Beadle Warrenby | 3/5 | After you get an Acorn: Pass +1/+1. | 6/10. …Pass +2/+2. |
| 4 | The Honorary Treasurer | 3/5 | End of Turn: gain +1/+1 per gold in your Larder. | 6/10. …+2/+2 per gold… |
| 5 | Goodman Hayward | 4/7 | After you play a Larder item: your Hedgerow folk have +1/+1 per gold this game. | 8/14. …+2/+2 per gold… |
| 5 | The Standing Committee | 5/7 | End of Turn: Hedgerow folk touching this gain a fifth of the smallest one's stats. | 10/14. …two fifths… |
| 6 | Squire Lollop | 6/8 | Start of Turn: Hedgerow folk touching this, except your biggest, gain a tenth of its stats. | 12/16. …a fifth… |
| 6 | Old Mother Mast | 6/8 | Start of Turn: get an Acorn per 5 gold in your Larder. Up to 5. | 12/16. …two Acorns per 5 gold. Up to 10. |

### Reading the per-card lines

- "Payoff" numbers are from the model's lines (named on each card) at R9 / R12 / R15. Stats are Attack/Health. Board numbers are Attack + Health totals.
- **Supper on time:** T2 R2, T3 R4, T4 R7, T5 R10, T6 R12. **Late:** every buy from R4 one round later, which moves Dozey's wakes from R9 / R12 / R15 to R10 / R13 / R16.

### Tier 1

**Mrs Burdock, Expecting Again** (Rabbit). Tier 1, **1/2**. *Unchanged.*
- Text: **When played: summon a 1/1 Kit behind this. Spill.**
- Golden (2/4): When played: summon two 1/1 Kits behind this. Spill.
- Condition: a free slot behind her, or none for the Acorn (back row, or front with both slots behind full).
- Payoff:
  - A Kit, or an Acorn (1 gold, a Beadle Pass, a third of a Stash).
  - With Clover the Kit arrives with half her stats: about +2/+4 at R6 and +4/+8 at R9.
  - Once the Committee is down, a 1/1 Kit is your Line's smallest member and shrinks its payout. So you sell it or let Mallow double it. That's a real decision about a token.
- Permanence: permanent body, or economy.
- Enabler: Clover (a summon), Mallow (a smallest), Pym and Beadle (the Spilled Acorn), the Committee and Lollop (another body in the Line).
- Concentrates: no.

**Mr Crumb** (Church Mouse Sidesman). Tier 1, **1/2**. *Changed (engine design): sold, he Passes himself.*
- Text: **When played: Pass +1/+1. When sold: Pass its stats.**
- Golden (2/4): When played: Pass +2/+2. When sold: Pass twice its stats.
- Details: his tribe bonuses stay behind.
- Condition: another unit on board; selling him.
- Payoff:
  - On the Supper he sits in B3 on R6 as your last unit. He takes Pym's two Passes and Hunker, and fights as the round's carry (11/12).
  - On R7 you sell him as Dozey takes B3, so his 11/12 lands on Dozey before the first wake. That's 22/24 of Dozey by R9, 44/48 by R12 and 88/96 by R15.
  - With Mallow it's a two-turn combo: double him, then sell him into the carry.
- Permanence: permanent.
- Enabler: Dozey and the Treasurer (whatever is last). Mallow makes him worth selling.
- Concentrates: **yes.** He's the tribe's tool for piling a support's growth onto the carry.

**The Sleeping Partner** (Dormouse Investor). Tier 1, **1/2**. *Changed: Acorns per Hedgerow unit touching (breaker point 8), no lifetime.*
- Text: **Every 3 turns in this slot: get an Acorn per Hedgerow unit touching this.**
- Golden (2/4): Every 3 turns in this slot: get two Acorns per Hedgerow unit touching this.
- Details: touching is the unbroken zigzag run through this, including it. Moving it restarts the wait.
- Condition: left alone in one slot, in a long Line of Hedgerow folk.
- Payoff:
  - On the Supper: 2 Acorns on R3, then 6, 6, 7 and 7 on R6, R9, R12 and R15. That's about 28 gold over the game.
  - Each Acorn fires Beadle, and every third one makes a Stash for Pym.
  - With F4 empty the run is six long. A full Line pays seven.
  - On another tribe's board it pays 1 Acorn every 3 turns, its own.
- Permanence: economy; permanent once eaten.
- Enabler: Beadle (each Acorn), Pym (each Stash), Dozey (food), the Treasurer (held gold), Mast (a Larder to earn on), Hayward (gold played), the Sergeant (ammunition).
- Concentrates: through Dozey.

### Tier 2

**Mrs Clover, Midwife** (Rabbit, Parish Midwife). Tier 2, **2/4**. *Changed: half her stats, Hedgerow summons only, no limit.*
- Text: **After you summon a Hedgerow unit: give it half this unit's stats.**
- Golden (4/8): After you summon a Hedgerow unit: give it this unit's stats.
- Condition: you summon a Hedgerow unit (Kits, Shrewlets), in either phase.
- Payoff:
  - Clover is 8/16 at R9 on the Parish, so a Kit arrives at about +4/+8.
  - Fight Shrewlets from a front-row Sorrel arrive at half her size. The model doesn't count these, so the Parish fights a little better than it shows.
  - "Hedgerow" costs one word and stops a grown Clover feeding another tribe's summons (breaker note).
- Permanence: recruit summons keep it; fight summons have it for the fight.
- Enabler: Burdock, Sorrel.
- Concentrates: no.

**Mr Pym** (Vole, Clerk to the Council). Tier 2, **2/4**. *Changed (engine design): +3/+3.*
- Text: **After you get a Stash: Pass +3/+3.**
- Golden (4/8): After you get a Stash: Pass +6/+6.
- Details: a Stash formed from three Acorns counts.
- Condition: three Acorns combine (the Partner's bursts, Sorrel, Spills, Squirrel Away).
- Payoff:
  - On the Supper, three Stashes on R3–R7 give +9/+9. It goes into Crumb, then Dozey.
  - On Dozey that's about +36/+36 by R15. He fades after R8, and the Supper sells him for Beadle.
- Permanence: permanent.
- Enabler: Dozey, the Treasurer. He's the reason to hold the third Acorn.
- Concentrates: **yes.**

**Mrs Sorrel, Harassed** (Shrew Mother). Tier 2, **2/3**. *Unchanged.*
- Text: **After this attacks: summon a 1/1 Shrewlet behind this. Spill.**
- Golden (4/6): After this attacks: summon two 1/1 Shrewlets behind this. Spill.
- Condition: she attacks. In the back row every summon Spills.
- Payoff:
  - In back she makes 1 Acorn a fight, or 1.5 from R9. That's about 11 Acorns by R12 and 15 by R15, the Supper's steady fuel.
  - In front she makes a fight body each attack, worth half Clover's stats.
- Permanence: economy, or fight-only bodies.
- Enabler: Beadle (each Acorn), Pym, Dozey, the Treasurer, Hayward, Clover.
- Concentrates: no.

### Tier 3

**Mrs Mallow, Feeding Them Up** (Dormouse, Keeper of the Parish Larder). Tier 3, **2/5** (was tier 4). *Changed: doubles, Hedgerow only, one tier earlier.*
- Text: **End of Turn: double your smallest Hedgerow unit's stats.**
- Golden (4/10): End of Turn: double your two smallest Hedgerow units' stats.
- Details: smallest means Attack plus Health; ties go to the earlier slot in the zigzag. It can pick itself. Shy units are skipped (12.1.7).
- Condition: End of Turn; Hedgerow folk on board.
- Payoff:
  - **Parish:** three Mallows, which triple into a golden once the third arrives. Each adds the runt's size every turn: about +60–70 a turn at R12 and +300 at R15.
  - **Supper:** about +6–10 a turn on the supports.
- Permanence: permanent.
- Enabler: the Committee, which pays by the runt, so Mallow raises everyone's pay. Also Crumb (double him, then sell him) and Kits.
- Concentrates: **no, it spreads by design.** A doubled unit stops being the smallest.
- Why tier 3: she's the Parish's compounder and must arrive by R4–R5. Dozey takes her old tier 4 slot.

**Dr Urchin** (Hedgehog Apothecary). Tier 3, **2/5**. *Changed: an aura of Hunker on your last unit, while he lives.*
- Text: **Bristle 2. Your last unit has Hunker.**
- Golden (4/10): Bristle 4. Your last two units have Hunker.
- Condition: a last unit other than him, and Urchin alive.
- Payoff:
  - Your carry takes half damage when attacked, until the enemy kills Urchin.
  - In the model, a Supper with Hunker for the whole fight wins 81% of its R9–R11 fights against median boards. With the aura it wins 42%. Against strong boards at R12–R16 it's 59% against 44%.
  - So the aura keeps the carry alive without making fights certain.
- Permanence: an aura, printed on the card.
- Enabler: Dozey, the Treasurer, any Pass carry.
- Concentrates: makes concentration work. It's the "hold its stats" piece the audit asked for, and killing him is the answer.
- The decision: front row (he dies early, a body for the trades) or back row (Hunker lasts, but he takes a back slot).

**Sergeant-at-Conkers** (Shrew Sergeant). Tier 3, **3/3**. *Changed: a share per gold; golden throws two.*
- Text: **Start of Combat: throw your smallest Larder item across. That enemy loses a tenth of its stats per gold.**
- Golden (6/6): Start of Combat: throw your two smallest Larder items across. That enemy loses a tenth of its stats per gold.
- Details: the item is spent. Each throw takes its own share, so two Stashes leave a quarter. Rounded down, to at least 0 Attack and 1 Health. With no enemy across, the item stays in hand.
- Condition: a Larder item in hand, and the enemy you want across from him. B2 faces B2.
- Payoff:
  - An Acorn takes a tenth, a Stash halves the target, and a Great Hoard leaves it at 0/1.
  - In the model, a Stash on the on-time Supper's carry drops it from 100% to 17% against median boards at R9. At R12 it drops from 79% to 6% against strong boards.
  - At R15 a Great Hoard is needed: it drops the Supper from 89% to 7% against strong boards.
- Permanence: one-shot, each fight.
- Enabler: holding. Cash loose Acorns first so the right item is the smallest. He competes with Dozey and the Treasurer for the same items.
- Concentrates: an answer, not a payoff.

### Tier 4

**Alderman Dozey** (Dormouse Alderman). Tier 4, **3/6** (was tier 3, 2/5). *Changed: the wake repeats, no caps, one tier later.* **The engine.**
- Text: **Larder items played on this: +1/+1 per 2 gold. Every 3 turns in this slot: double its stats.**
- Golden (6/12): Larder items played on this: +2/+2 per 2 gold. Every 3 turns in this slot: double its stats.
- Details: feeding rounds up. He wakes after your other End of Turn effects. Moving him restarts the wait.
- Condition: stay in one slot, and be fed before the wake.
- Payoff:
  - On time: 90/98 at R9, 262/282 at R12, 686/728 at R15.
  - Late: 25/29 at R9 (asleep, wakes R10), 102/112 at R12, 282/304 at R15.
  - He's 76% of the board at R9, 61% at R12 and 44% at R15.
- Permanence: permanent and visible. The card shows wake pips.
- Enabler: he's what the Partner, Sorrel, Pym, Beadle, Crumb, stat spells and Lollop point at.
- Concentrates: **yes, the carry.**
- Why tier 4:
  - At tier 3 (bought R4, first wake R6), his first wake doubles everything the line has held since R1. With this pass's other texts, that line is 1.61× typical at R6 and 1.55× at R9. It wins 94% of its R6–R8 fights against median boards.
  - At tier 4, R6 is the early Pass board, and the first wake lands on R9 (1.21×). Breaker point 3 asked for this window to be fixed; this is the fix.

**Beadle Warrenby** (Rabbit Beadle). Tier 4, **3/5**. *Changed: no once-a-turn limit.*
- Text: **After you get an Acorn: Pass +1/+1.**
- Golden (6/10): After you get an Acorn: Pass +2/+2.
- Condition: Acorns arrive: Sorrel, Spills, the Partner's bursts, Mast, Squirrel Away.
- Payoff:
  - About 4 Acorns a turn on R8–R12 gives +4/+4 a turn on the last unit.
  - On Dozey, each wake doubles that. His R8–R9 Passes (about +10/+10) are about +40/+40 of Dozey by R15.
- Permanence: permanent.
- Enabler: Dozey and the Treasurer.
- Concentrates: **yes.**
- Why +1/+1: the engine design's +2/+2 puts the Supper at 1.34× at R9 and 1.47× at R15. +1/+1 gives 1.21× and 1.32×. A feeder before a doubler doesn't need to be big.

**The Honorary Treasurer** (Bank Vole). Tier 4, **3/5**. *Changed: grows each turn you hold, permanently; no cap.*
- Text: **End of Turn: gain +1/+1 per gold in your Larder.**
- Golden (6/10): End of Turn: gain +2/+2 per gold in your Larder.
- Condition: Larder items held in hand at End of Turn.
- Payoff:
  - On the Treasury line: 73/75 at R9, 191/193 at R12, 401/403 at R15.
  - On the Supper she's a late buy (109/114 at R15), because the feasts empty the Larder.
- Permanence: **permanent.** She keeps what holding earned.
- Enabler: the Partner, Sorrel, Mast.
- Concentrates: **yes (self).** She's the Treasury's carry. In the Supper she grows during the two turns before each feast.

### Tier 5

**Goodman Hayward** (Hedgehog, Keeper of the Hedges). Tier 5, **4/7**. *Changed: per gold, this game.*
- Text: **After you play a Larder item: your Hedgerow folk have +1/+1 per gold this game.**
- Golden (8/14): After you play a Larder item: your Hedgerow folk have +2/+2 per gold this game.
- Details: cashing it or feeding it to Alderman Dozey both count. A standing tribe bonus with no cap. Units summoned in fights don't get it.
- Condition: you play a Larder item.
- Payoff:
  - **Supper:** +16/+16 by R12 and +37/+37 by R15, about +220 and +520 on the board. Dozey's wakes double his share.
  - **Treasury:** the cash-out. 54 gold played on R14 adds +64/+64 to every Hedgerow unit, about +900 stats in one turn.
  - **Parish:** small (+5/+5), because it has few Acorns.
- Permanence: permanent, and it shows on Hedgerow units in the shop. A new tier's units arrive bigger, which is the progression fix.
- Enabler: every Acorn source, the feast and the cash-out.
- Concentrates: no, it spreads.
- The engine design's text said "now and later". The rulebook's word is "this game" (breaker point 11).

**The Standing Committee** (Several Mice in One Coat). Tier 5, **5/7**. *Changed: pays the Line by its smallest member, permanently.*
- Text: **End of Turn: Hedgerow folk touching this gain a fifth of the smallest one's stats.**
- Golden (10/14): End of Turn: Hedgerow folk touching this gain two fifths of the smallest one's stats.
- Details: touching is the unbroken zigzag run through this, including it. The smallest one is the smallest Hedgerow unit in that run, which can be this, and it gains too.
- Condition: a gapless Line of Hedgerow folk with no tiny member. Each gap shortens the run, and each runt shrinks the pay.
- Payoff:
  - **Parish:** its smallest is about 70 at R12, so about +90 a turn. At R15 it's about 315, so about +440 a turn.
  - **Supper:** about +75 a turn at R12 and +300 at R15.
- Permanence: permanent. It used to be a fight-only aura.
- Enabler: Mallow (raise the floor), Hayward (raises every unit equally), Clover (Kits that aren't tiny), Lollop (raises everyone but the biggest).
- Concentrates: **no.** It pays even boards and the Parish, and a Line with one giant and six runts gets little.
- The fiction: a committee is only as strong as its weakest member.

### Tier 6

**Squire Lollop, Lord of the Manor** (Hare, Patron of the Living). Tier 6, **6/8**. *Changed: shares the biggest at Start of Turn, except to the biggest; permanent; Hedgerow only.*
- Text: **Start of Turn: Hedgerow folk touching this, except your biggest, gain a tenth of its stats.**
- Golden (12/16): Start of Turn: Hedgerow folk touching this, except your biggest, gain a fifth of its stats.
- Details: biggest means most Attack plus Health; ties go to the earlier slot in reading order. Rounded down. The share is worked out once, before anyone gains. Copies add up, but the biggest never gains from them.
- Condition: a Line through Lollop, and something big on your board.
- Payoff:
  - **Supper:** from R13, about +26/+28 to each of six others, about +320 a turn. By R16 it's +68/+72 each, about +840.
  - **Parish:** about +65 a turn at R12 and +370 at R15.
- Permanence: permanent.
- Enabler: Dozey, the Treasurer, any big unit. It's what makes the carry route a whole board, and the insurance when an answer finds Dozey.
- Concentrates: no, it spreads the carry.
- Why the changes:
  - "Except your biggest" means a second copy doesn't compound the carry (breaker point 1).
  - Start of Turn means he always reads last night's final size and lands where the player sees it (point 10).
  - "A tenth" replaces "10%" (point 11).

**Old Mother Mast** (Red Squirrel, Keeper of the Great Hoard). Tier 6, **6/8**. *Changed: interest on the Larder, up to 5 a turn.*
- Text: **Start of Turn: get an Acorn per 5 gold in your Larder. Up to 5.**
- Golden (12/16): Start of Turn: get two Acorns per 5 gold in your Larder. Up to 10.
- Condition: a held Larder.
- Payoff:
  - 20% interest, up to 5 gold a turn. On the Treasury line the Larder is 48 gold at R12, so she pays the full 5.
  - Each Acorn fires Beadle, and the Acorns combine into Stashes for Pym.
- Permanence: economy.
- Enabler: the Treasurer, Beadle, Pym, Dozey (bigger feasts), the Sergeant (ammunition).
- Concentrates: through Dozey and the Treasurer.
- "Up to 5" is the one rate limit, on a loop (breaker point 7). Without it, two Masts grow a held Larder by ×1.67 a turn until the hand fills. "Per 5 gold in your Larder" is 15 words against 16, and a Great Hoard still counts as three (point 11).

### Wording check

| Card | Words | Card | Words |
|---|---|---|---|
| Mrs Burdock | 9 | Sergeant-at-Conkers | 19 |
| Mr Crumb | 9 | Alderman Dozey | 18 |
| The Sleeping Partner | 13 | Beadle Warrenby | 7 |
| Mrs Clover | 12 | The Honorary Treasurer | 10 |
| Mr Pym | 7 | Goodman Hayward | 15 |
| Mrs Sorrel | 10 | The Standing Committee | 15 |
| Mrs Mallow | 9 | Squire Lollop | 16 |
| Dr Urchin | 7 | Old Mother Mast | 15 |

- Median 11 words, p90 18, longest 19. The guide asks for a median of 11 or less, p90 of 17 or less and a maximum of 22, so the p90 is one word over.
- The two long cards are Dozey (18) and the Sergeant (19). "Larder item" costs a word on each. The shortest Sergeant I found that names what loses what is 19 words.
- No new keywords. Limits and rounding sit in Details, except Mast's "Up to 5", which changes how you play (guide rule 2).

---

## The tribe

### Engine and rate parameter

**The Long Sleep.** Dozey doubles every 3 turns he's left in his slot, and everything that reaches him before the wake is doubled with him.
- You **assemble** it from:
  - fuel: the Partner, back-row Sorrel, Spills, Mast;
  - feeders: Pym, Beadle, Crumb;
  - protection: Urchin's Hunker and the B3 slot;
  - outlets: Hayward, the Committee, Lollop.
- You **protect** it by not touching it.
- Doubling every 3 turns is ×1.26 a round on its own. Feeding and the outlets bring the line to about the target slope from R12.

**Rate parameter: w, Dozey's gain at each wake.** Default +100% ("double"), every 3 turns. The table is the mean of the on-time and late lines, board ÷ typical:

| w | R9 | R12 | R15 | R15, 3-round mean | Reads as |
|---|---|---|---|---|---|
| +75% | 1.13 | 1.03 | 1.10 | 1.07 | Gentle: level all game |
| **+100% (double)** | **1.21** | **1.16** | **1.32** | **1.28** | **Level to R11, clearly ahead from R13** |
| +150% | 1.36 | 1.44 | 1.84 | 1.79 | Steep, toward Nov 2026 |
| ×2 every 4 turns | 0.86 | 0.41 | 1.17 | 1.19 | Lumpy: two wakes by R15 |
| Engine design's tiers (Dozey T3) | 1.55 | 1.36 | 1.57 | 1.54 | Ahead at once, the wrong shape |

Keep the word **double**: it's the moment players remember. If the harness says the Supper is hot, turn the secondary dials first.

**Secondary dials**, in the order I'd sweep them (Supper R15, mean of on time and late):

| Dial | Default | Sweep | Model |
|---|---|---|---|
| Lollop copies | 1 | 0, 1, 2 | 0.98 / **1.32** / 1.53 |
| Lollop share | a tenth | a twentieth, an eighth | 1.12 / **1.32** / 1.42. Two Lollops at a twentieth: 1.19 |
| Committee share | a fifth | a tenth, a quarter | Parish R15: 0.98 / **1.48** / 1.86. Supper R15: 1.10 (off) / **1.32** / 1.38 |
| Dozey's food | per 2 gold | per gold | **1.32** / 1.51 |
| Hayward | per gold | per 2 gold | **1.32** / 1.09 |
| Beadle | +1/+1 | +2/+2 | **1.32** / 1.47 |
| Treasurer (Treasury line) | per gold | per 2 gold | Treasury R12 **0.80** / 0.53 |

### The turn it comes online

- **The early board (R3–R7) is a Pass carry, not the engine.** The Partner's first big burst on R6 (6 Acorns, two Stashes for Pym) lands on Crumb in B3, who fights Hunkered as an 11/12. That's why the Supper is 1.30× at R6 and wins 87% of its R6–R8 fights against median boards. Early losses cost little (round base 2–3), so this is tempo the tribe can afford.
- **Behind at once: R8.** Dozey is a 3/6 asleep in B3. You're holding 16–17 gold of Larder, F4 is empty, and you fight with six. The board is 1.00× on time, and it wins 13% against strong boards.
- **First feast: R9 on time (R10 late).** The board goes from 105 to 249.
- **The lean turns: R10–R11.** On R11 the Supper wins 8% against median boards. That's the dip before the second feast. The scout shows it coming, and so do Dozey's pips.
- **Clearly ahead from R12–R13.** The second wake, Hayward and Lollop. R12–R16 fights: 71% against median, 43% against strong, 37% against strong with answers.

### The decision it creates, every turn: feed it now, or keep it for the feast?

Every Larder item asks the same question:
- **Cash it (tempo):** gold now, for a buy, a refresh or the next Tier up. With Hayward down, cashing also gives every Hedgerow unit +1/+1 per gold this game.
- **Keep it (invest):** while it waits:
  - the Treasurer grows +1/+1 per gold, each turn;
  - Mast pays an Acorn per 5 gold;
  - the third Acorn makes a Stash, which fires Pym;
  - the Sergeant has something worth throwing.
- **Feed it on the wake turn:** everything Dozey eats before End of Turn is doubled. Feeding counts as playing it for Hayward too.
- **When the question changes:** from about R12, Hayward pays the same whether you feed or cash, and cashing also gives you the gold. So late on, the question becomes "hold or cash", and feeding is mostly a R7–R11 decision. The pitch says so (breaker note). The per-gold food dial would keep feeding alive longer.

There are four more decisions, all about position:
- **The F4 gap.** Fill F4 and Passes and Hunker land there, on an exposed unit. Leave it empty and they land on Dozey in B3, but you fight a body short. The usual answer: B3 while he's small, then F4 once he's big, on the turn after a wake.
- **Move him or keep the count.** The scout shows next round's opponent. Moving Dozey away from their Sergeant restarts his wait, unless it's the turn right after a wake.
- **Where Urchin stands.** In the front he's a body that dies early and takes Hunker with him. In the back he keeps Hunker longer but costs a back slot.
- **Triple him or keep the count.** A golden Dozey keeps all three copies' food and eats twice as much, but starts his wait again. Buy the third copy on a turn right after a wake.

### Carry route: the Supper

Partner (B1, never moves) → Pym → Mallow → back-row Sorrel and Urchin → Crumb into B3 → **Dozey into B3 on R7, sold Crumb into him, F4 empty** → Beadle → Hayward, moving Dozey to F4 on the turn after a wake → the Committee → **Lollop** (buy every copy) → Mast → the Treasurer.

- **The rhythm:** hold, hold, feast. Hold the Larder through the first two turns of each sleep. On the wake turn, feed all of it and aim stat spells at Dozey before End of Turn.
- **Wins by:** a carry bigger than anyone's, with Hunker while Urchin stands, and Lollop and the Committee turning it into a full Line. Dozey holds 44% of the R15 board, about a Battlegrounds-shaped carry plus a bit.
- **The insurance:** an answer that halves Dozey at R15 leaves the Supper winning 89% against strong boards. Lollop, the Committee and Hayward have already spread him.

### Second carry: the Treasury

Partner → Pym → Mallow → back Sorrel → Urchin → **the Treasurer in F4 on R7** → Beadle → the Sergeant → Hayward → Mast → Lollop → **cash out on R14**.

- **The idea:** never spend a Larder item. The Treasurer grows on it every turn and everything Passes to her. Then cash the lot with Hayward down: every Hedgerow unit gets +1/+1 per gold this game, and you have the gold to spend.
- **Its clock:** strong early, lean late, then a spike.
  - R6–R11: 1.12–1.38×. It wins 97% of R6–R8 fights against median boards and 64% at R9–R11.
  - R12–R13: 0.68–0.80×, and it wins 2–6% of those fights. You're holding 48–54 gold and fighting with one big vole.
  - R14 cash-out: the board goes from 586 to 1,926, and it wins 94% that round.
- **It's the answer route too.** The Sergeant's ammunition is the Larder, and a Great Hoard deletes a carry.
- **Weak point:** the R12–R13 lean is deep. A player who cashes out a turn earlier gives up a little size and skips the worst of it. That's a real decision.

### Non-carry route: the Parish

Burdock, Clover and Sorrel in front → Mallow (three copies, so a golden) → Crumb → Urchin in the back row → the Committee → Hayward → Lollop. Cash every Acorn at once.

- **The idea:** many hands, all growing.
  - Mallow keeps doubling the runt.
  - The Committee pays everyone a fifth of the runt.
  - Lollop lifts everyone but the biggest by a tenth of the biggest.
  - Kits and Shrewlets arrive at half Clover's size.
- **The decision it adds:** keep the Line gapless and with no runt. Sell the tiny Kit, or let Mallow double it first.
- **Its shape:** the biggest unit is only 18–21% of the board. Under our rules an even board beats a carry of the same total unless the carry holds its stats, so the Parish is the tribe's answer to other tribes' carries.
- **Its clock: late.**
  - R6–R11: 0.83–0.92×. It wins only 13–21% of its fights against median boards.
  - R12–R16: 75% against median boards, and 99–100% at R15–R16. It's 1.48× at R15 and 1.73× at R16.
- **This is the shape problem in this design** (see weak points). The model leaves out neutrals and fight summons, which favour the Parish early. The harness should check its R4–R9 win rate first.

### Answers to other tribes' carries

1. **Sergeant-at-Conkers:** a Stash halves the enemy across, and a Great Hoard leaves it at 0/1. The scout shows where their carry stood. Put him in the matching slot (B2 faces B2) and cash loose Acorns so the right item is the smallest. It costs a real item every fight. The golden throws two items, so two Stashes leave a quarter: no longer a 5-gold delete every fight (breaker point 2).
2. **The Parish itself:** seven even bodies with no runt. Overkill is wasted, so a carry spends a whole attack on each of them.
3. **Bristle** on Urchin pricks swarms and Pack joiners early.

Hedgerow adds no "biggest enemy" effect. Its answer is aimed and paid for in gold, which leaves the any-row answers to neutrals and the answer tribes (fundamentals question 2).

### Weak points

- **The Parish's early game.** It's below typical R6–R11 in the model and loses most fights there. Its Hedgerow bodies are small (1/2, 2/4), and the model has no neutrals or fight Shrewlets. Levers, if the harness agrees:
  - Clover gives her full stats to summons (the golden becomes double);
  - T1–T2 Hedgerow bodies get +1 Health;
  - the Parish line buys neutrals to R6.
- **The Parish's late slope.** Three Mallows and the Committee grow it about ×1.75 a turn from R13. The lever is the Committee at a sixth.
- **One dormouse.**
  - From his first wake to tier 6, Dozey is 61–76% of the board.
  - Kill Urchin and he takes full damage.
  - A Sergeant across him halves the engine.
  - Answers that shrink the biggest enemy find him in any row.
  - Whirligig Beetle drags a B3 Dozey into the front.
  - A Supper that loses Dozey early has only Pym and Beadle's small bodies.
- **He can't move.** You can't rearrange for the scouted opponent without restarting his wait, except on the turn after a wake. Dozey is the easiest carry in the game to aim at, and that's the price of the sleep.
- **The lean turns.** R10–R11 for the Supper and R12–R13 for the Treasury.
- **Pass goes to F4 when the board is full.** One careless buy into F4 sends every Pass and Hunker to the wrong unit. The Pass mark shows it.
- **The hold costs tempo the model doesn't fully charge.** Held Larder is gold you didn't spend, and the scripted lines buy on schedule anyway. A real Supper at R7–R8 is likely weaker than the model's.

### Highroll moments a player will remember

1. **The Michaelmas Feast (R12).**
   - Dozey has slept two turns at about 125/135. You've held 16 gold, and the Partner has seven Hedgerow folk touching it.
   - On the third turn you feed him all 16 (+8/+8), and Hayward gives every Hedgerow unit +16/+16 this game.
   - The Partner's 7 Acorns fire 7 Beadle Passes, and then he wakes: 262/282.
   - The board goes from 299 to 885 in one turn.
   - Next morning Lollop gives the other six +26/+28 each.
2. **The Great Cash-Out (R14, the Treasury).**
   - You've held everything since round 1. The Treasurer is 191/193, Mast has paid her limit every turn, and the Larder reads 54 gold.
   - With Hayward down, you play it all. Every Hedgerow unit you own, and every one you'll ever buy, gets +64/+64. Then you have 54 gold to spend.
   - The board goes from 586 to 1,926.
3. **The Sergeant's Great Hoard (R14).**
   - The scout shows a 1,200-stat carry in your next opponent's B2.
   - You cash two loose Acorns so your smallest item is a Great Hoard, and put the Sergeant in B2.
   - At Start of Combat he lobs 16 gold of acorns across, and their carry is 0/1 before anyone swings.
4. *(Rarer.)* **The Dormitory.** Two Dozeys sleep in B1 and B3 on staggered clocks, fed on alternate feasts. The third copy shows up the turn after one woke. The golden keeps both stacks, eats twice as fast and starts a fresh sleep.
5. *(Rarer.)* **Three Mallows and a golden Committee.** Every runt doubles, every member gets two fifths of the runt, and the Parish goes from 1.7× typical at R12 to 5.8× at R15.

---

## Boards at R6, R9, R12 and R15

From `hedgerow-pass3-model.out.txt`. Units are listed biggest first. "Late" is the same line one round slower from R4.

### Supper (engine and carry)

| Round | On time: board (biggest first) | Total, ×typ | Late: total, ×typ | Mean ×typ | 3-round mean |
|---|---|---|---|---|---|
| 6 | Crumb 11/12 (B3), Pym 4/8, Sorrel 4/6, Mallow 3/6, Urchin 2/5, Partner 2/4 | 67, 1.29 | 68, 1.31 | 1.30 | 1.21 |
| 9 | Dozey 90/98, Beadle 6/10, Urchin 4/10, Partner 4/8, Sorrel 4/6, Mallow 3/6 | 249, 1.58 | 133, 0.84 | 1.21 | 1.15 |
| 12 | Dozey 262/282, Hayward 28/36, Beadle 26/32, Lollop 26/29, Urchin 24/32, Partner 24/30, Committee 25/29 | 885, 1.66 | 351, 0.66 | 1.16 | 1.12 |
| 15 | Dozey 686/728, Hayward 159/174, Lollop 157/167, Committee 156/167, Urchin 155/170, Mast 127/134, Treasurer 109/114 | 3,203, 1.79 | 1,526, 0.85 | 1.32 | 1.28 |

Every round, mean of on time and late: R6 1.30, R7 1.29, R8 1.08, R9 1.21, R10 1.17, R11 0.86, R12 1.16, R13 1.35, R14 1.18, R15 1.32, R16 1.34.

**Layout at R12** (on time; Dozey moved to F4 on R10, the turn after his wake):
```
F1 Beadle Warrenby    F2 Dr Urchin       F3 Squire Lollop      F4 Alderman Dozey
        B1 Sleeping Partner   B2 Standing Committee   B3 Goodman Hayward
```

### Parish (wide)

| Round | On time: board | Total, ×typ | Late: total, ×typ | Mean ×typ | 3-round mean |
|---|---|---|---|---|---|
| 6 | Mallow 2/5, Sorrel 3/4, Crumb 2/4, Burdock 2/4, Clover 2/4, Kit 2/2, Burdock 1/2 | 39, 0.75 | 51, 0.98 | 0.87 | 0.90 |
| 9 | Hayward 10/18, Clover 8/16, Urchin 9/14, Sorrel 8/15, Mallow 5/14, Mallow 5/14, Committee 6/10 | 152, 0.97 | 111, 0.70 | 0.83 | 0.82 |
| 12 | Lollop 48/62, Hayward 40/68, Urchin 31/48, Mallow 25/52, Mallow 32/40, Mallow 22/47, Committee 26/41 | 582, 1.09 | 418, 0.79 | 0.94 | 0.98 |
| 15 | Mallow 214/404, Mallow 214/398, Hayward 204/336, Urchin 156/248, Lollop 153/228, Committee 146/234, Mallow 127/188 | 3,250, 1.81 | 2,046, 1.14 | 1.48 | 1.49 |

The biggest unit's share is 18–21% throughout. In play the three Mallows triple into a golden, which doubles two runts and frees two slots. The model keeps them as three copies.

### Treasury (hold)

| Round | On time: board | Total, ×typ | Late: total, ×typ | Mean ×typ |
|---|---|---|---|---|
| 6 | Mallow 13/16, Sorrel 4/6, Urchin 2/5, Pym 2/4, Partner 2/4 | 58, 1.12 | 59, 1.13 | 1.12 |
| 9 | Treasurer 73/75, Mallow 13/16, Partner 4/8, Sergeant 6/6, Sorrel 4/6, Beadle 3/5, Urchin 2/5 | 226, 1.43 | 194, 1.23 | 1.33 |
| 12 | Treasurer 191/193, then six bodies of 6–14 (Larder 48 gold) | 448, 0.84 | 400, 0.75 | 0.80 |
| 15 | Treasurer 401/403, six bodies of about 133/135 (after the R14 cash-out) | 2,410, 1.34 | 1,818, 1.01 | 1.18 |

### Fights, every round, mean of on time and late

Each cell is 500 fights.

| Line | Field | R6–R8 | R9–R11 | R12–R16 |
|---|---|---|---|---|
| Supper | median | 87% | 42% | 71% |
| Supper | strong | 42% | 13% | 43% |
| Supper | strong+answer | 34% | 9% | 37% |
| Parish | median | 13% | 21% | 75% |
| Parish | strong | 0% | 0% | 42% |
| Treasury | median | 97% | 64% | 47% |
| Treasury | strong | 49% | 19% | 17% |

**What the fights say:**
- **Concentration is back to the audit's rule.** The on-time Supper beats even boards 20% smaller every time. Against even boards its own size, it wins only 3–32% at R6–R12. The breaker found the old design beating every even board up to its own total, so that problem is gone.
- **Variance.** 14 of the Supper's 22 round-cells against median and strong boards sit between 20% and 80%. The plan wants the smaller board to win a set share of R10–R14 fights. Here the strong field (more stats) beats the Supper about 57% of the time from R12. That is the smaller side winning about 43%, above Battlegrounds' 14–26%. The field is plain boards, so the real figure will be lower.
- **No common snowball at the checkpoints.** No ordinary line reaches 2× typical at R9, R12 or R15. The on-time Supper peaks at 1.79× on its wake rounds, and the late line is at 0.66–0.85× on the same rounds. The Parish on time does reach 2.11× at R16 (weak points).

### Against the target

- All three lines are level with today's shape to R5. The Supper and Treasury run 1.1–1.4× through R6–R9 on early Pass carries. The Parish is at 0.8–0.9×.
- From R12:
  - **Supper:** about ×1.4 a round in pulses every 3 turns, ending 1.3× typical.
  - **Parish:** level to R12, then about ×1.75 a round, ending 1.5–1.7×.
  - **Treasury:** a lean R12–R13, then a spike at the cash-out.
- **The tail** (on-time Supper, board ÷ typical):

| Goldens | R12 | R15 | R16 |
|---|---|---|---|
| Golden Dozey (R10) | 1.79 | 1.94 | 1.85 |
| Golden Lollop (R14) | 1.66 | 2.06 | 2.32 |
| Golden Dozey, Hayward and Lollop | 2.41 | 2.88 | 3.20 |
| Two Lollops plus all three goldens | 2.41 | 2.89 | 3.62 |
| Parish: golden Mallow (R9) and golden Committee (R12) | 1.74 | 5.79 | 8.58 |

- The owner's bar is a rare top 1% up to 10× the median. The Supper's tail is short, at about 3×. The Parish's golden pair is the longest, at 8.6× by R16 and still climbing. It needs a golden T5. If it shows up in the harness's top 5%, not its top 1%, the golden Committee drops from two fifths to a third.

---

## Where it could run away, and the lever for each

| Risk | Why it's bounded | Lever if the harness shows it |
|---|---|---|
| Two Lollops (common at T6 with no recruit timer) | The biggest never gains, so copies spread and don't compound. Supper R15: 1.53× with two, 1.32× with one | A twentieth (two Lollops: 1.19×) |
| Two Committees, or Committee plus three Mallows | Pay depends on the runt, and one runt stops it. Parish R15: 1.90× with two Committees | A sixth; then "Hedgerow folk touching this, except itself" |
| Mast's Larder loop | Up to 5 a turn per copy (rate limit) | Show the hand limit beside the Larder. Don't lower the 5 before the harness reports the Larder distribution at R12–R16 |
| Hayward's feast or cash-out | Linear in gold. The biggest single play is the Treasury's cash-out (+64/+64 to each unit) | Per 2 gold (Supper R15 1.09×) |
| The Treasurer on a long hold | Linear in the Larder; Mast is capped | Per 2 gold (Treasury R12 0.53×: too weak, so try this only if the harness shows a snowball) |
| The golden Sergeant | Two throws, each its own share; a Great Hoard still wipes | Golden "a fifth per gold" with one throw |
| Partner bursts with a full Line | 7 Acorns every 3 turns, about 2.3 gold a turn | "every 3 turns: get an Acorn per 2 Hedgerow units touching" |
| Hunker on a huge carry | An aura that ends when Urchin dies, and Urchin is a 2/5 | Hunker only in the back row |

There are no per-card size caps. The only rate limit is Mast's "Up to 5", on a loop. The structural limits stay: the 3-turn wait, one Sergeant throw a fight (two if golden), and Lollop's share worked out once a turn.

---

## Harness lines

Card ids are the `content/units/*.json` ids. Spells: `acorn`, `stash`, `great_hoard`, `squirrel_away`, `harvest_supper`, `pinch_of_dust`. The plan asks for two lines per tribe: `hedgerow_parish` (tempo, wide) and `hedgerow_supper` (engine and carry). `hedgerow_treasury` is a third, **optional** line, which I'd run if the harness has room (breaker point 6). The model's arrival rounds stand in for the shop; the harness uses the priority lists.

```json
{
  "hedgerow_supper": {
    "tribe": "hedgerow_folk",
    "role": "engine",
    "engine_flag": true,
    "buy_priority": ["alderman_dozey", "dr_urchin", "squire_lollop", "goodman_hayward", "sleeping_partner", "mr_pym",
                     "mrs_sorrel", "mrs_mallow", "beadle_warrenby", "mr_crumb", "standing_committee", "old_mother_mast",
                     "honorary_treasurer", "sergeant_at_conkers", "mrs_burdock", "mrs_clover"],
    "buy_rules": {
      "squire_lollop": "buy every copy",
      "sleeping_partner": "rounds 1-3 only",
      "mr_pym": "rounds 1-6 only",
      "alderman_dozey": "buy a second copy whenever offered; keep it in hand or asleep in B1/B2 on its own clock; buy the third copy only on a turn right after a wake (the triple forms at once and restarts the wait)"
    },
    "sell_first": ["mrs_burdock", "kit", "mr_crumb (on the turn alderman_dozey takes B3, or once mr_crumb is at least a fifth of Dozey's size)",
                   "mr_pym (from tier 4)", "mrs_sorrel (once old_mother_mast is down)",
                   "sleeping_partner (from tier 6, on the turn after it pays)"],
    "climb": {"T2": 2, "T3": 4, "T4": 7, "T5": 10, "T6": 12},
    "save_rule": "Spend out every turn, except keep what next turn's scheduled Tier up needs beyond next turn's income (rounds 3, 6, 9 and 11). Hold every Larder item: cash one only to pay a scheduled Tier up, or to buy alderman_dozey, dr_urchin, squire_lollop or goodman_hayward. From round 12, refresh freely with spare gold.",
    "larder_policy": {
      "default": "hold",
      "wake_turn": "on Dozey's wake turn (3rd, 6th, 9th End of Turn in his slot) play every Larder item on him, then aim stat spells at him, before ending the turn",
      "sergeant": "if sergeant_at_conkers is on board and the scout shows an enemy over 3x your median unit across him, cash loose Acorns so the smallest item is a Stash, or a Great Hoard if that enemy holds over a third of its board"
    },
    "placement": {
      "sleeping_partner": "B1, never moved",
      "alderman_dozey": "B3 with F4 empty; move to F4 on the turn right after a wake, once he is at least 3x the median unit and dr_urchin is on board; then fill B3",
      "mr_crumb": "B3 until alderman_dozey arrives",
      "dr_urchin": "a back slot if one is free, else F2",
      "mrs_sorrel": "B2 (back row: every summon Spills)",
      "rule": "never place anything in F4 except alderman_dozey; keep the Line gapless once he is in F4"
    },
    "spells": "stat spells on alderman_dozey on his wake turn; before he arrives, on your last unit"
  },
  "hedgerow_parish": {
    "tribe": "hedgerow_folk",
    "role": "tempo",
    "engine_flag": false,
    "buy_priority": ["mrs_mallow", "standing_committee", "squire_lollop", "goodman_hayward", "mrs_clover", "mrs_sorrel",
                     "mrs_burdock", "dr_urchin", "mr_crumb", "beadle_warrenby", "sergeant_at_conkers", "honorary_treasurer",
                     "mr_pym", "old_mother_mast", "sleeping_partner", "alderman_dozey"],
    "buy_rules": {
      "mrs_mallow": "buy every copy toward the triple",
      "standing_committee": "buy a second copy toward the triple",
      "neutrals": "to round 6, buy the biggest neutral body in the shop over a Hedgerow unit two tiers lower"
    },
    "sell_first": ["kit (once standing_committee is down, unless mrs_mallow will double it this turn)", "mr_crumb (his stats Pass to F4)",
                   "mrs_burdock", "mr_pym", "sleeping_partner", "the smallest unit that isn't Hedgerow folk"],
    "climb": {"T2": 2, "T3": 4, "T4": 6, "T5": 8, "T6": 10},
    "save_rule": "Spend out every turn; keep only what next turn's scheduled Tier up needs beyond next turn's income. Refresh up to twice a turn, more only to find standing_committee at tier 5 or squire_lollop at tier 6.",
    "larder_policy": {"default": "cash every Larder item as soon as you get it"},
    "placement": {
      "rule": "keep the Line gapless, so all seven touch the Committee and Lollop",
      "biggest_unit": "F4 (the Pass and Hunker slot)",
      "dr_urchin": "a back slot",
      "mrs_sorrel": "front, with a back slot behind it free until the board fills; then F4 or F3",
      "mrs_burdock": "front, with a free back slot behind"
    },
    "spells": "stat spells on your smallest unit before End of Turn"
  },
  "hedgerow_treasury": {
    "optional": true,
    "tribe": "hedgerow_folk",
    "role": "economy",
    "engine_flag": true,
    "buy_priority": ["honorary_treasurer", "old_mother_mast", "goodman_hayward", "sergeant_at_conkers", "dr_urchin",
                     "sleeping_partner", "mrs_sorrel", "beadle_warrenby", "mr_pym", "mrs_mallow", "squire_lollop",
                     "standing_committee", "mr_crumb", "mrs_burdock", "mrs_clover", "alderman_dozey"],
    "buy_rules": {"old_mother_mast": "buy every copy", "sleeping_partner": "rounds 1-3 only"},
    "sell_first": ["mrs_burdock", "kit", "mr_pym (from tier 4)", "mrs_mallow (from tier 5)", "mr_crumb"],
    "climb": {"T2": 2, "T3": 4, "T4": 7, "T5": 10, "T6": 12},
    "save_rule": "Spend income only; never cash a Larder item except to pay a scheduled Tier up or a priority buy. Cash out the whole Larder once: on the first turn from round 13 with goodman_hayward on board, or at once if the hand would pass 9 cards. Then hold again.",
    "larder_policy": {
      "default": "hold",
      "sergeant": "as hedgerow_supper; otherwise keep one loose Acorn as his item"
    },
    "placement": {
      "honorary_treasurer": "F4 (last unit: every Pass and Hunker)",
      "sergeant_at_conkers": "across the scouted biggest enemy (a back slot faces the same back slot)",
      "dr_urchin": "a back slot",
      "sleeping_partner": "B1, never moved"
    },
    "spells": "stat spells on honorary_treasurer"
  }
}
```

**Bot needs for these lines:**
- the hold-and-feast policy with wake pips;
- "move only on the turn after a wake";
- cash management for the Sergeant;
- the cash-out turn;
- runt selling under the Committee.

Bots never hold today (the audit found a Hedgerow Larder p90 of 2 gold at R8), so without these the Supper and Treasury will read weak for the wrong reason.

---

## The breaker's points: accepted and rejected

| # | Breaker point | Call | How or why |
|---|---|---|---|
| 1 | Two Lollops plays like golden | **Accepted** | "Except your biggest", so copies don't compound. "Buy every copy" is in the line. A tenth stays the default: two Lollops are 1.53× at R15 in my model, and a twentieth is the sweep's next step |
| 2 | A golden Sergeant deletes any carry for 5 gold | **Accepted** | The golden throws your two smallest items, each its own share. Two Stashes leave a quarter; only a Great Hoard wipes |
| 3 | R6–R11 is the Supper's strongest window | **Accepted, fixed another way** | My model charges gold and still finds it, worse: 1.6× at R6 with the swap. The cause is the first wake on R6 doubling a stack built since R1, not Hunker alone. Dozey moves to tier 4 and Mallow to tier 3, and Urchin stays at tier 3. Hunker became an aura, which cut the Supper's R9–R11 wins against median boards from 81% to 42%. I rejected the Urchin/Mallow swap itself: modelled with this pass's texts, it gives 1.61× at R6 and 1.55× at R9 |
| 4 | The late curve rests on one card | **Accepted** | With no Lollop the Supper is 0.98× at R15, inside the band. Hayward, the Committee and Mallow are the outlets, all at tier 5 or below. I agree with the breaker that a share on the wake is the wrong lever, so it isn't used |
| 5 | Checkpoints sit on the wakes | **Accepted** | Every round is reported, plus a 3-round mean, for both schedules, and fights are scored at every round. The harness should snapshot by wake phase |
| 6 | The Treasurer and Mast are dead in the Supper; the Treasury isn't a line | **Accepted** | The Treasury is its own route, modelled, with a third, optional harness line. The claim that the Treasurer is the Supper's insurance is dropped: the insurance is Lollop and the Committee's spread |
| 7 | Two Masts loop the Larder | **Accepted** | "Up to 5", a rate limit on a loop. The Larder and hand limit show beside the hand |
| 8 | The Sleeping Partner is neutral economy | **Accepted** | An Acorn per Hedgerow unit touching. That's 1 on another tribe's board and 7 on a full Line, and it adds a placement choice |
| 9 | The Committee is too small | **Accepted the diagnosis; different text** | The breaker's text (the smallest touching gains your biggest unit's Attack) fed the carry. It added 2–26% to the Supper, which was already over the target, and left the Parish at 0.95–1.31× at R15. "Gain a fifth of the smallest one's stats" gives the Parish an engine (1.48×) and keeps the Supper at 1.32× |
| 10 | Two orders on one board | **Accepted, and finished** | Lollop moves to Start of Turn. Dozey wakes after your other End of Turn effects, so the feed-before-the-wake rule needs no reading order |
| 11 | Words that mean two things | **Accepted** | "Larder item" for the family, and "Acorn" for the 1-gold item. One rule for "get". The Sergeant's text names what loses what. "This game" on Hayward. "A tenth" and "a fifth", never "%" |
| Note | The feast leans to "cash" once Hayward is down | **Accepted** | The pitch says feeding is mostly a R7–R11 decision. Food stays per 2 gold: per gold is +15% at R15 |
| Note | "Play the third copy" should be "buy" | **Accepted** | Fixed in the line |
| Note | The Parish line contradicts Hayward | **Accepted** | The order note is gone. The bonus covers units this game, so the order doesn't matter |
| Note | Crumb and Hayward's bonus | **Accepted** | His tribe bonuses stay behind (12.1.5) |
| Note | Clover for Hedgerow summons | **Accepted** | |
| Note | Beadle and Pym fade after R10 | **Accepted, and leaned into** | Both are pre-wake feeders. Beadle drops to +1/+1 because his early Passes are doubled several times |
| Note | The model charges no gold | **Accepted** | The new model does |
| Rank | Parish third, "cash every Acorn removes the tribe's decision" | **Accepted, partly fixed** | The Parish now has its own question ("who's the runt?") and its own engine. Its early game is the open problem |

---

## Cross-tribe notes

- **Lollop and the Oozes carry's Elder Ooze** ("your other Oozes permanently gain a tenth of your biggest Ooze's stats") share a verb and a rate.
  - Lollop now differs in three ways: Start of Turn, the touching gate, and the biggest excluded.
  - Lollop has two passes of history as the Line's patron, so I'd keep "share the biggest with the Line" here.
  - The cross-tribe synthesis decides. If Oozes keep theirs, Lollop's fallback is "After your biggest unit doubles: Hedgerow folk touching this gain a tenth of it." That ties him to Dozey's wakes and Mallow.
- **The timed double** matches the Fairies carry's Queen ("doubles your biggest Ring every third turn"). Hedgerow has the oldest claim (pass 2's "After 3 turns in this slot") and the plainest fiction, a dormouse asleep. The Queen should take another clock or verb.
- **"Leave it alone and it grows"** now appears in four tribes:
  - Fairies' empty Ring;
  - Oozes' simmering Belly;
  - Birds' trips (now one doubling at homecoming, `birds-pass3.md`);
  - Hedgerow's sleep.

  Birds have already moved off it. Hedgerow keeps the sleep.
- **"Smallest" is Hedgerow's word.** Mallow and the Committee both read your smallest unit. Other tribes use "biggest" (Birds, Oozes, Lollop). The Committee is the only card that pays a board by its weakest member, which is a clean identity line for the cross-tribe check.
- **Hunker** is on Sett Warden (Hunters) and Urchin. It stays a keyword, and Hedgerow's use is an aura on the last unit.
- **Acorns elsewhere:** Mrs Jay (Birds) and the `sample_hoarder` hero make Acorns. Under the Larder rule they are 1-gold Acorns, so nothing changes for them.
- **Other Hedgerow-tagged units:** `hazel_dormouse`, `hedgerow_elder`, `hoglet_mother`, `field_vole`, `hedgehog_twin`, `marmot_lookout` and `wood_mouse_guard`, from the prototype pool, sit outside these 16. They count as Hedgerow folk for touching, the Committee, Hayward, Mallow and the Partner. Whether they stay is the cross-tribe synthesis's call. Any 1/2–2/3 among them would be a Committee runt.
- **The answer budget:** Hedgerow adds one aimed-across answer (the Sergeant) and no any-row answer.

---

## Engine support needed

**Data only (mechanisms exist):**
1. **Alderman Dozey:** tier 4, 3/6. `turns_in_slot every: 3` (as the Partner uses) with `multiply 2`. Drop `once`, `most` and `permanent_buff_cap`, and the rulebook's 12.1.1a ceiling for him. Feeding at +1/+1 per 2 gold is today's text.
2. **Mrs Mallow:** tier 3, 2/5. The smallest Hedgerow unit, `stat_fraction gain 1/1`. Golden picks two.
3. **Beadle Warrenby:** drop `limit`; body 3/5. **Mr Pym:** `stats: 3`.
4. **Mrs Clover:** drop `limit`; Hedgerow summons only; `stat_fraction gain 1/2` of the source's stats.
5. **Rate overlay keys:** Mast's "up to 5" is `limit` (RATE), so the caps-off sweep can switch it off.

**New, in order of need:**
1. **Dozey's wake resolves after your other End of Turn effects.** Recruiting Passes land before any End of Turn text, as 12.1.6 already implies.
2. **`stat_fraction` from another unit:** the recipient gains a share of a different unit's stats.
   - Lollop: the friendly biggest (the shared `pick: biggest`), recipients touching Hedgerow folk except that unit, at Start of Turn.
   - The Committee: the smallest Hedgerow unit in the touching run, recipients the whole run, at End of Turn.
   - Clover: the source.
3. **An aura on "your last unit"** (Urchin's Hunker; golden: the last two). It's recalculated as units die, and it ends when Urchin dies.
4. **The Partner:** `add_card acorn`, count = Hedgerow units in its touching run.
5. **Pass with a variable amount** (Crumb: his own stats on sell, without the tribe-bonus layer).
6. **Hayward:** `on_item_played` (exists for pass 2's Hayward), feeding a tribe bonus with `per: gold` and no cap, kept apart from Harvest Supper's capped layer.
7. **The Sergeant:** a per-gold share, `stat_fraction reduce` with numerator 10% × the thrown item's gold value, onto the enemy across. Golden: two throws.
8. **The Treasurer:** an `end_of_turn` permanent buff, `per: larder`.
9. **Mast:** `start_of_turn add_card acorn`, count = floor(Larder ÷ 5), `limit: 5` (golden ×2).
10. **The Larder:** a reminder term, and a number beside the hand that shows the hand limit.

**Screens:**
- Wake pips on Dozey. Highlight his slot when a move would restart the count.
- The Larder number beside the hand, with "9/10 cards" when it's nearly full.
- The Pass mark and the Hunker shield on the last unit (the Pass mark exists).
- Lollop's preview of this morning's share, and the Committee's preview with its runt circled.

---

## What changed from pass 2

| Card | Pass 2 | Pass 3 | Why |
|---|---|---|---|
| Mrs Burdock | — | unchanged | Already a clean slot decision |
| Mr Crumb | Played or sold: Pass +1/+1 | Played: Pass +1/+1. Sold: Pass its stats | A concentration tool that stays useful late |
| Sleeping Partner | 2 Acorns every 3 turns, three times | An Acorn per Hedgerow unit touching, every 3 turns, no lifetime | Tribe-only economy; fuel at the new scale |
| Mrs Clover | +1/+1 to any summon, twice a turn | Half her stats to Hedgerow summons, no limit | Scales; tribe-only |
| Mr Pym | Pass +2/+2 per Stash | Pass +3/+3 per Stash | An early feed, doubled by the wakes |
| Mrs Sorrel | — | unchanged | The tribe's fuel; already scale-free |
| Mrs Mallow | T4; smallest +1/+1 | T3; double your smallest Hedgerow unit | The Parish's compounder; arrives by R4–R5 |
| Dr Urchin | Bristle 2; after this pricks, Pass +1 Attack | Bristle 2; your last unit has Hunker | The hold-its-stats piece, which ends when he dies |
| Sergeant-at-Conkers | 3 damage per gold | A tenth of the target's stats per gold; golden throws two | Answers must scale with carries |
| Alderman Dozey | T3; double once, up to +8/+8; +12/+12 ceiling | T4; double every 3 turns, no caps | The engine, online at R9 |
| Beadle Warrenby | 2/4; Pass +1/+1 per Acorn, once a turn | 3/5; Pass +1/+1 per Acorn | Rate limit removed |
| Honorary Treasurer | Aura +1/+1 per 3 gold held, up to +8/+8 | End of Turn: +1/+1 per gold in your Larder, permanent | Cap removed; she keeps what holding earned |
| Goodman Hayward | +1/+1 to touching per Stash played | +1/+1 per gold to Hedgerow folk, this game | "This game" growth; new buys feel like progress |
| Standing Committee | Fight aura +1/+1 or +2/+1, any tribe | End of Turn: touching Hedgerow folk gain a fifth of the smallest one's stats | The Parish's engine; Hedgerow only; permanent |
| Squire Lollop | Fight aura +1/+1 or +2/+2, any tribe | Start of Turn: touching Hedgerow folk, except your biggest, gain a tenth of it | Hedgerow only; permanent; spreads the carry |
| Old Mother Mast | An Acorn after your first buy (2 with a Great Hoard) | An Acorn per 5 gold in your Larder, up to 5 | Interest on the hoard: holding pays |

Portraits: no creature changes. Mr Pym, Mrs Clover, Mrs Mallow, Goodman Hayward and Squire Lollop still use the tribe portrait (`content/portraits_pending.json`).

---

## Calls for the orchestrator to log

1. Alderman Dozey moves to tier 4 and Mrs Mallow to tier 3; Dr Urchin stays at tier 3. The breaker's Urchin/Mallow swap is not taken.
2. Urchin's Hunker is an aura on your last unit, and it ends when he dies.
3. The Standing Committee pays the Line a fifth of its smallest member. The breaker's "your biggest unit's Attack" is not taken.
4. Squire Lollop shares at Start of Turn, a tenth, except to your biggest.
5. Dozey wakes after your other End of Turn effects.
6. "Larder item" is the family word, and "Acorn" means the 1-gold item.
7. Old Mother Mast is "up to 5 a turn", the tribe's one rate limit, on a loop.
8. The Sleeping Partner pays per Hedgerow unit touching it.
9. Beadle Passes +1/+1, and Dozey's food stays at per 2 gold.
10. The Treasury is a modelled route and a third, optional harness line.

## Model limits

- **Scripted arrivals** stand in for the shop, so lines are path-sensitive. Differences under about 15% are noise. A Mallow-at-R3 Parish probe moved by more than that in both directions.
- **No neutrals, and no spells beyond +1/+1 per spare gold.** The Parish's early game likely reads low, and every line's R4–R7 too.
- **No fight summons.** Shrewlets and Hoglets don't fight, which undercounts the Parish and front-row Sorrel.
- **Plain fields.** The field boards have no text and never move their carry away from a Sergeant. The answer field halves the biggest unit in one fight in three.
- **The hold's tempo cost is only partly charged.** Lines buy on schedule whatever they hold, so the Supper and Treasury at R7–R9 may read high.
- **Triples aren't merged:** the Parish's three Mallows stay three. Goldens appear only in the tail runs.
- **It isn't a lobby:** no pool depletion, no second Hedgerow player, no hero Health, no ghosts. Whether the Parish survives its R6–R11 losses to reach its late game needs Health, which only the harness has.
