# Review queue

Decisions waiting on the owner, most important first. Each item points to where the full reasoning lives. Answer by number. Answers get recorded as owner notes, and the rulebook is updated to match.

Sources:
- [rulebook-deltas.md](rulebook-deltas.md): all 55 proposed defaults and 6 open rules
- [power-budget.md](power-budget.md): the costing method and its open questions
- [board-layout-options.md](board-layout-options.md): the fixed-slots decision

## 1. Combat shape (decide first; everything else builds on it)

1. **Attack order.** Keep "front row left to right, then back row left to right, repeat", or test an interleaved order? The simulation shows 85–87% of back-row attacks happen after the front row is already dead, so the back row behaves like reserves. As a result, a back unit's buff on the front pays off almost fully, while a front unit's buff on the back pays off about 5% of the time. ([power-budget.md](power-budget.md), rulebook §9.4)
2. **Single-target random effects and the back row.** Proposed: "a random enemy" also can't reach the back row while any front unit lives, while effects that hit a group hit both rows. (rulebook 9.5.6)
3. **Summons and attack order.** Proposed: a unit summoned into the slot of the unit that just attacked attacks next. A unit summoned into an earlier slot waits until the next cycle. (rulebook 9.4.8)
4. **Where summons go.** Proposed: a dying unit's first summon takes its slot. Others go to the nearest empty slot, same row first, ties to the right. (rulebook 8.4.1–8.4.2)
5. **Leftmost and rightmost.** By on-screen position (F1, B1, F2, B2, F3, B3, F4), or by reading order (front row, then back row)? (rulebook 8.2.5)
6. **Do combat buffs end with the fight** (Battlegrounds) **or persist** (Galaxy)?
7. **Keep Taunt?** It's worth about zero in the sim, because back-row protection already does its job.

## 2. Economy

8. **Units drawn from the pool by effects** (Discover, Triple Reward): do they sell for 1 like bought units, or 0 like created ones? (rulebook 4.3.2)
9. **Refresh thresholds.** Placeholder: refreshes 1–10 cost 1, 11–20 cost 2, 21+ cost 3. (rulebook 4.4.3)
10. **Do free refreshes count toward the thresholds?** Proposed: yes. (rulebook 4.4.5)
11. **Price economy and scaling text more strictly than Battlegrounds?** Battlegrounds charges almost nothing in stats for them, and that's where its power creep came from. ([power-budget.md](power-budget.md))

## 3. Power budget

12. **Plain units:** on budget (proposed 5/7/8/10/12/14 stats by tier), or below it as in Battlegrounds?
13. **Golden units:** double the stats and effect sizes, but keep thresholds unchanged?
14. **Tolerance band:** is ±10% the right margin for "on budget"?
15. **Next step:** start test cards from placeholder values, or build the whole-game bot first?

## 4. The rest

16. The other ~45 proposed defaults in [rulebook-deltas.md](rulebook-deltas.md) are mostly edge cases with sensible defaults: start and end-of-turn order, pool returns, triples with a full hand, and so on. Skim them and flag any you disagree with. Unflagged ones count as accepted.
17. **The hand.** The rulebook keeps Battlegrounds' hand: bought units go to the hand, not straight onto the board. (rulebook 7.2)
