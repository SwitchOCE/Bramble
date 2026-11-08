**1. Last Blow: change.** It ends stalemates, but the code credits the last attack declared, not the blow that emptied the boards.
**2. Last Four: change.** It cures stalled endings but overshoots: four players became two in one round, and the duel was one fight.
**3. Formation: change.** It pays for tribe, but on a mono-tribe board it's a flat buff of about +50% to the most-cast card, and the best layout is always "clump the kin".
**4. Hand-me-down: change.** Rounding up on each sale passes +1/+1 gains on whole, and several sales stack onto one unit.
**5. Supper at tier 3: keep.** It was the clearest reward for committing to a tribe.

## Games (Hard)
| # | Flags | Seed | Build | Place |
|---|---|---|---|---|
| 1 | pkg | 7 | Bog folk (Jenny, golden Hopkin) | 5 |
| 2 | pkg,supper3 | 11 | Hunters (golden Russet, Old Brocks) | 8 |
| 3 | pkg | 23 | Hedgerow (Dozeys, golden Committee, golden Hasty Pudding, Whirligig) | 2 |
| 4 | unset | 23 | same plan | 2 |

## Details
**Last Blow.** Mutual wipes now cost 4-5, so early rounds hit harder. In game 4, round 4 was a tie for 1 damage; in game 3, the same round was a loss for 5. The bug: `combat.gd` sets `last_attack_side` when an attack is declared. If Mrs Posset's death damage empties the attacker's board, the attacker still wins. *Counter:* credit the side whose damage killed the last unit, death triggers included.

**Last Four.** In game 3, with 4 alive, I knocked Pipkin out from 9 with a 14-damage win, and Hoolet took 15 in the same round. The duel was me on 2 against Jill on 15. One loss for 17 ended it. With the cap (game 4), the duel was 18 against 26 at 12 per loss. I needed 3 straight wins, so it was foregone. The package trades a foregone ending for one coin-flip fight. *Counter:* step the cap: 15 with four alive, 20 with three, uncapped in the duel.

**Formation.** In a mono-tribe board each slot touches 3 kin, so Stand Behind Me gives two units +3/+3 each: +6/+6 for 2 gold, up from +4/+4. I cast it twice in one turn. Off-tribe tech (Whirligig, Hasty Pudding, Charcoal Burner) gains nothing and lowers its neighbours' count, so it taxes the interesting neutrals. *Counter:* cap the gain at +2/+2 and require the aimed unit's tribe.

**Hand-me-down.** `recruit_rules.gd` rounds up half of each sale and adds the sales together. Selling Mr Crumb (+1/+1) gave its Pass plus +1/+1 whole to Alderman Dozey. Selling Sexton Beetle (+1/+1) passed it whole to Charcoal Burner. It isn't broken (half is lost, and bodies), but it feeds Dozey's doubling and survives a triple. *Counter:* add the sales up, halve at play time rounding down, and cap the gift at twice the receiving unit's tier. Cut the Heir Apparent: "all of it" doubles a funnel that already stacks.

**Supper at tier 3.** +5/+5, then +7/+7, across my Hunters for 3 gold in rounds 8-9. Watch it next to formation: both scale with kin count.

**Did build and placement beat stat piles?** Partly. In game 3 I won round 11 on text and placement: the golden Hasty Pudding swallowed two units, and Whirligig Beetle pulled an enemy off its Ring. Every loss, though, went to a stat pile. Jill had a golden Mrs Sorrel at 32/35, 19 of it from a Ring, and a 19/20 Sleeping Partner. Hedgerow Pass and Ring stacking on tier-1 and tier-2 bodies is untouched by this package, and it beat both of my 2nd places.
