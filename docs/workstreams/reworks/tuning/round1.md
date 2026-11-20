# Mouse and Pigeon tuning proposal

Dev base `9182e381`. This pass restores Mouse Attack before Tier 6 and gives Pigeon two points on the curve where Renown can pay off sooner. The test targets are 4.3–4.6 for Mouse-locked seats, 4.2–4.4 for Pigeon-locked seats, and 3.3–4.4 for both in A/A. The placement targets are unmeasured.

## Changes

Costs use the median printed Attack + Health of non-token shop units on dev as a proxy for a vanilla body. T1–T6 are 7.5, 9, 12, 14, 18 and 22 stats. The costs below are for normal copies in a working board. [Tier guide](/data/wt-m-new/docs/design/tier-guide.md)

| Tribe | Card | Old → new | Reason | Tier-guide cost |
|---|---|---|---|---|
| Mouse | Harvest Piper (T2) | Recruit Attack per other Mouse **+2 → +5** | Restore early Attack that survives the shop and can be passed on. | With five to six recipients, +10–12 → +25–30 permanent Attack once, **2.8–3.3 bodies vs ~1.3**. Deliberately high. Early boards with two to three recipients get +10–15. |
| Mouse | Fencing Master (T3) | Printed Attack **4 → 10** | Give the pike line a carry that can clear a target before retaliation on the turn it is bought. | Printed body 9 → 15 stats (**1.25 T3 bodies**). Two live pile-ons from fresh purchase deal 10 + 12 damage instead of 4 + 6. That is **~2.8 in-fight bodies** at the pitch's rough 1.5× free-damage rate, vs **0.7–1.4**, before any overkill discount. It also keeps +4 permanent Attack after two triggers (**0.33 body vs ~0.8**). Deliberately high immediate damage. |
| Mouse | Dormouse Cook (T4) | End-of-turn Attack per other Mouse **+3 → +7** | Give both Mouse plans repeatable growth that pays even if their combat formation breaks. | With five to six recipients, +15–18 → +35–42 permanent Attack per turn, **2.5–3.0 bodies vs ~1.3**. Deliberately high for a 2/9 engine that needs a wide Mouse board. |
| Mouse | Parish Standard-bearer (T5) | Start-of-fight Attack coefficient **+2 → +3** per Mouse | Give established Mouse boards an immediate power spike while they find a capstone. | At six Mice, +72 → +108 Attack in fight (**4 → 6 bodies vs ~4**). At seven, +98 → +147 (**8.2 bodies**). This is the deliberate full-board ceiling for one normal copy. |
| Pigeon | Colour Sergeant (T3) | Renown per slot in its full Pigeon row **1 → 2** | Make assembling a full row matter in the midgame. The row keeps its gains when its units are replaced. | Full front row gives 4 → 8 Renown per turn, **16 raw stat growth or ~20–24 of next-fight value** with one or two refills in that row (**1.3–2.0 bodies vs ~0.8**). A full rear row gives 12 raw stats. Deliberately high when the front refills. |
| Pigeon | Regimental Sergeant Major (T6) | End-of-turn Renown per slot **3 → 4** | Give the wide plan its capstone payoff and help a late pickup strengthen every slot immediately for the next fight. | 21 → 28 Renown per turn, **56 raw stat growth or ~72–88 of next-fight value** with two to four ordinary refills (**3.3–4.0 bodies vs ~4**, or **2.5** on starters alone). |

## Diagnosis

**Mouse.** Moving Needle Pikeman from Tier 3 to Tier 6, dropping the old slot-Attack engines and capping Pile on removed early scaling and many of the hits that leveraged it. Hand-me-down can carry existing Attack through a fight. It needs a source of Attack to carry. Across 800 locked red seats per arm, average board Attack was 52 → 35 in round 6, 104 → 55 among round-8 survivors, and 135 → 77 on final boards. Final Health rose from 63 to 70. Keeping the old bot on dev still worsened placement by 0.20 and gave 77 final Attack. That puts most of the observed Attack loss on the cards. On dev, only 22% of locked seats ever fielded Needle Pikeman, while 47% of round-10 survivors had a Cook and 46% had a Standard-bearer. In A/A only 68 of 318 Mouse seats reached round 10. [Mouse pitch](/data/wt-m-new/docs/workstreams/reworks/pitch-mouse.txt)

**Pigeon.** Renown cut the old growth rates, and combat gains now pay from the next fight. The Reserve cap, The Colonel's new role, and the loss of Medals also cut the number and strength of late arrivals and attacks. The locked boards were already down from 52/78 Attack/Health to 42/68 in round 6. In round 10, surviving boards averaged 135/177 before the rework and 92/131 on dev. The new bot's Reserve and Active handling regained 0.16 placement, leaving a 0.40 deficit overall. In round 8, 340 of 399 Colour Sergeant copies had a full Pigeon row, making it a dependable midgame lever. By round 12, 182 of 334 surviving boards carried Regimental Sergeant Major, 36 carried Colour Sergeant, and 24 carried both. [Pigeon pitch](/data/wt-m-new/docs/workstreams/reworks/pitch-pigeon.txt)

Locked red seats bought Harvest Piper, Fencing Master, Cook and Standard-bearer on 46%, 51%, 61% and 84% of buyable shop offers. Colour Sergeant and Regimental Sergeant Major drew 44% and 93%. These rates establish which changes the measurements will exercise. TribeBot values tier and stats, so rates also reflect tier access and how readily a copy replaces an existing unit. [TribeBot valuation](/data/wt-m-new/tools/league/league/src/baselines.rs:70) · [Measurement records](/data/measure/reworks)

## TribeBot's Mouse play

- **Pile on gets a sensible row preference and shallow positioning.** The Godot bot and league port look for raw `Pile on {` and `Can't attack` to favor the rear. They favor the lowest-index available slot within a row, prioritize existing Renown over the slot score once a unit is chosen, and assign move actions a negative score. The search misses Drill-sergeant's wording and ignores which neighbours can attack early. At round 6, 83% of 1,692 printed Pile on copies were in the rear and only one had zero front neighbours. The row heuristic usually gives them someone to follow. At the end of the game, 118 of 237 Needle Pikemen were in front, where they can take early hits despite being unable to attack. [Godot placement](/data/wt-m-new/tools/league/gd/tribe_bot.gd:95) · [League action and slot scores](/data/wt-m-new/tools/league/league/src/baselines.rs:70) · [League row preference](/data/wt-m-new/tools/league/league/src/baselines.rs:496)
- **Hand-me-down sequencing is a larger blind spot.** The bot recognizes “Your Hand-me-downs” on Bell-ringer and Widow Thimble. Guard and most other cards default to the front, including Needle Sister. The engine gives the Attack to the nearest living Mouse by neighbour steps, with ties in reading order. Of 274 Needle Sisters in round-8 locked boards, 192 (70%) were in front, 132 (48%) had no adjacent donor, and 205 (75%) were not first in line for any adjacent donor on the starting board. This counts default single-heir routing before deaths, summons or Widow can change it. A protected Sister next to a donor with a favorable tie-break can get attacks the bot misses. [Hand-me-down targeting](/data/wt-m-new/src/content/mouse/lib/mouse_rules.gd:64)
- **Implication.** The new bot changed the Mouse result from 5.69 to 5.76 with the cards held fixed. Its positioning can understate a well-played Mouse board, especially the Sister line. The drop from 135 to 77 Attack is already present before the fight.

## Costing notes

For attack buffs, each point starts at one stat, as on an equal plain board. For example, a six-Mouse board gets 15 extra permanent Attack from the Piper change, 20 extra per turn from the Cook change, or 36 extra at fight start from the Standard-bearer change when each is considered on its own. The Piper makes an early buy pay, the Cook rewards keeping an engine, and the Standard-bearer bridges the turn it is found. Cutpurse and Hayloft Aunt support the early economy and supply bodies to receive Piper’s buff. Bell-ringer and Needle Sister compete with Fencing Master at T3 when the board can route Hand-me-down. Cook pays every shop turn even when Grandmother Hob or Drill-sergeant lack a useful combat trigger. At T5, Bodkin and Widow reward a particular combat setup, while the Standard-bearer pays for the Mice already on the board. The Standard-bearer already has a strong seven-Mouse case. The +1 coefficient is warranted by its six-Mouse case and the number of seats eliminated before a lasting engine takes over.

Hand checks for Fencing Master's Attack at purchase, with the same Health, allied board and enemy board. Its existing +2 permanent Attack applies after its first hit.

| Setup | Marginal value of +6 printed Attack |
|---|---|
| One unit each | +6 on a normal swing. No neighbour to trigger Pile on. |
| Front pair, one live trigger | +6 damage before the normal exchange. |
| Back row behind two attackers | Two timely triggers add +12 raw damage, with the Fencing Master protected. |
| Full board, one attacker's neighbours also pile on | +6 raw damage on the trigger, with diminishing value once the combined Hits exceed the target's Health. |
| Guard at 8 Health | A 10-Attack Hit kills it before the exchange. At 4 Attack, the original Hit leaves it alive and the attacker takes retaliation. |
| One 30-Health enemy | +6 softens it on the first trigger. The enemy still retaliates. |
| Wide board of 2/2s | The old Hit already kills one. Most of the increment is overkill. |
| Enemy Cleave kills the Fencing Master after one trigger | Only the first +6 Hit is realized. |
| Enemy Sortie kills it before its neighbours attack | Neither charge delivers damage. |
| Dame Bodkin doubles two hits | +24 raw damage before overkill. |

Budget roughly **6–12 extra raw Hit damage** when one or both charges do useful work. The pitch's **~1.5×** rate values the saved retaliation. Cleave in the pitch deals about **1.6×** ordinary damage on a board with a splash target. A Guard that dies to the opening Hit can make the saved retaliation worth more than either average. The Fencing Master already grows with two reliable triggers. The chosen printed-attack buff helps immediately, including on a board that only gives it one trigger.

Hand checks for **+1 Renown** on a slot, with equal plain boards. The stat-equivalent value is **+2 on each eligible body** starting in or refilling the slot.

| Setup | Value of +1 Renown in the next fight |
|---|---|
| One occupied slot, duel | +2 to the starter. |
| Occupied front slot on a full board | +2 to the starter. Attack and Health can both shift a trade. |
| Occupied protected rear slot | +2 to the starter, with the Health most relevant if the fight reaches it. |
| Empty slot | 0 this fight, +2 once a starter fills it. |
| Starter and one hand reservist | +4. |
| Starter and one Private | +4. |
| Guard post with two eligible refills | +6. |
| Starter and an ordinary summon or return in its slot | +2 total. |
| Starter and one hand reservist with The Colonel | +6. |
| Source earns +1 during combat | 0 for this fight, +2 per eligible occupant next fight. |

The pitch's **~3 stats per Renown** is a useful rough rate on a board with some refills. Colour Sergeant's row condition keeps its strongest growth in Pigeon-heavy lineups. Its front-row growth benefits more starters than Grenadier Guard’s single post and pays at the end of the turn even without Padre’s death triggers. The old Regimental Sergeant Major amount is defensible for a board with many arrivals. Raising it to 4 is the pitch's capstone dial and reaches the tier target with ordinary refills. The Colonel and Air Marshal ask for strong arrivals, while this capstone also pays on a board that has invested in filling its slots. The two Pigeon changes overlap on a few slots when both engines are live, so their full-width values should not be multiplied together. [Pigeon cost and caps](/data/wt-m-new/docs/workstreams/reworks/pitch-pigeon.txt)

Single goldens double the changed stat or Renown yield. The Mouse high roll to watch is Standard-bearer Attack becoming permanent via Old Mother Needle and reaching multiple heirs via Widow Thimble. Dame Bodkin can also double the pile-on use of the higher Attack. For Pigeon, the high roll is concentrated Renown on a copied or repeatedly refilled slot, especially with The Colonel. The Renown increases preserve the existing Reserve and Charge limits.

## Card text and patch check

These are the values the cards render. The two relevant tooltips are **Pile on** (“The first N times a neighbour attacks each fight, this hits the target first.”) and **Renown** (“The unit that starts the fight here, and any reservist who steps in, has +1/+1 for each.”).

| Card | Normal card before → after | Golden card before → after |
|---|---|---|
| Harvest Piper | Recruit gives other Mice +2 → +5 Attack | +4 → +10 |
| Fencing Master | 4/5 → 10/5. Pile on 2 and +2 permanent Attack after piling on | 8/10 → 20/10. Pile on 2 and +4 permanent Attack after piling on |
| Dormouse Cook | End of turn gives other Mice +3 → +7 Attack | +6 → +14 |
| Parish Standard-bearer | Start of fight gives Mice +2 → +3 Attack per Mouse for this fight | +4 → +6 per Mouse |
| Colour Sergeant | End of turn gives the slots in its full Pigeon row 1 → 2 Renown each | 2 → 4 each |
| Regimental Sergeant Major | End of turn gives every slot 3 → 4 Renown | 6 → 8 per slot |

Reviewed normal text, golden text and reminders in both JSON files, including spelled-out numbers. The five effect edits use `{attack}` or `{amount}` in both displays. Fencing Master's printed Attack renders from the card stat. Literal Charge counts, Cousin stats and fixed multipliers still match their cards. [Text substitution](/data/wt-m-new/src/core/units/unit_text.gd:8)

The [patch](/data/balance-endcheck/tuning/mouse-pigeon-tuning.patch) passed `git -C /data/wt-m-new apply --check /data/balance-endcheck/tuning/mouse-pigeon-tuning.patch`. The revised JSON was parsed in memory and checked against the six proposed field paths and values. Verification used static checks and existing records. The species-seed artifact was unavailable to this session, so the costing uses the accepted rework pitches, the tier guide and dev content.

## Tier check

- **T1.** Needle Page and Territorial supply early tempo. Sentry is a capped seed.
- **T2.** Piper is a deliberately strong recruit buffer for Mouse commitment. Pigeon still begins with modest growth and an early Reserve enabler.
- **T3.** Fencing Master is a deliberately strong immediate payoff for setting up neighbours. Colour Sergeant pays above target when the entire front row is Pigeon.
- **T4.** Cook rewards a wide Mouse board at roughly twice the guide's per-turn target. Pigeon supports keep their payoff through the Renown they use.
- **T5.** Standard-bearer provides a visible power spike for going wide. Seven Mice push it to about twice the in-fight target.
- **T6.** Regimental Sergeant Major reaches capstone output on an ordinary Reserve board. Mouse capstones get more Attack through their earlier pieces.
