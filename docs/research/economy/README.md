# Economy research

The findings so far on Bramble's economy and tier-up prices, and how to check them again. Update this page when better evidence comes in: new sims, real units, playtests.

- **How the 12 Nov decision was reached,** step by step and with the owner's words: [2026-11-12-economy-and-tier-prices.md](2026-11-12-economy-and-tier-prices.md).
- **The sims, and how to run them:** [tools/research/economy/](../../../tools/research/economy/README.md).
- **Saved outputs:** [results/](results/).
- **Linked:** damage (rulebook 10.1). The Damage Lab is archived in `docs/archive/damage-lab/` on `main`.

## Decided

Owner, 12 Nov 2026; rulebook v0.7, source C13.

| Rule | Value | Rulebook |
|---|---|---|
| Income | 5 on turn 1, +2 a turn until 15, then +1 a turn | 4.1.1 |
| Unit price | tier + 1 (tier 1 costs 2, tier 6 costs 7) | 4.2.1 |
| Sell value | half the tier, rounded up, for each bought copy; tokens add nothing (a tier-5 triple sells for 9) | 4.3.3 |
| Refreshes | the first 10 of a turn cost 1, then +1 every 5 | 4.4.2 |
| Shop | 5 units and 2 spells at every tier; tiers change only the odds | 6.1.1 |
| Tier-up base prices (to tiers 2–6) | **8 / 12 / 16 / 19 / 26** | 4.6.2 |
| Tier-up discount | 1, then 2, 3, 4, 5 off for each turn waited; back to 0 at every tier-up | 4.6.3 |

Tier-up price by turns waited:

| To tier | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| 2 | 8 | 7 | 5 | 2 | 0 | 0 |
| 3 | 12 | 11 | 9 | 6 | 2 | 0 |
| 4 | 16 | 15 | 13 | 10 | 6 | 1 |
| 5 | 19 | 18 | 16 | 13 | 9 | 4 |
| 6 | 26 | 25 | 23 | 20 | 16 | 11 |

## What the evidence says

From `lobby-v2`, the adaptive and evolved bots, averaged over 3 seeds:

| | At 8/12/16/19/26 |
|---|---|
| Players reaching tier 5 | 88%, usually by turn 7–8 |
| Players reaching tier 6 | 29% (about 2.3 a lobby), usually around turn 14 |
| Reaching tier 6: top four / bottom four | 53% / 4% |
| A player who rushes | places about 6.5 of 8 |
| Fights per game (10th / 50th / 90th percentile) | 14 / 16 / 18 |

**What holds in every sim and fudge setting:**
- **Rushing loses.** Rushers end up with thin boards, take heavy losses and miss out on scaling.
- **Dearer tiers 4–5 shut players out of tier 5 fast.** 8/12/17/22/27 already cuts it to about half of players.

**What depends on guesses (re-check these first):**

| Guess | Value used | Why it matters |
|---|---|---|
| Power gap between tiers | 1.5× per tier | Moves results more than any price change: 1.35× makes tiering up hardly worth paying for, 1.7× makes it easy |
| Economy units | 14% of offers, half power, 0–3 gold a turn | Strong ones lift tier 5 by about 30 points; then 8/12/16/19/31 is the safer set |
| Scaling | +1 and 5% of tier power a turn | More scaling favours staying low |
| Spells | 3 gold for 36% of a unit of your tier, no board slot | May let players skip tier-ups |
| Fight luck | σ 0.082 (90 vs 85 wins about 68%) | More luck slightly helps weaker plans |
| Shop odds | the TFT-like table (not decided) | Shapes how fast a tier pays off |
| Units per tier in a lobby | 14, 14, 14, 12, 12, 10 | Sets how often a pair or triple turns up; lobby unit counts matter as much as the odds |

**Weak signals:**
- **Staying on tier 4 as the safer plan.** Capping at tier 4 gives a slightly steadier placing (spread ±1.95) than pushing to tier 5 (±2.4). The averages are close.

## Open

- **Shop odds** (rulebook 6.1.7 and 5.1.4): the owner asked to revisit them now that the economy is set.
- **Damage:** games run about 16 fights against the 13–14 target. Less health also shuts players out of tiers (at 34 health, tier 5 drops to 40% at the old prices), so damage and tier prices have to be tuned together. See [the record](2026-11-12-economy-and-tier-prices.md#damage-is-the-linked-lever).
- **Proposed default, not yet confirmed by the owner:** the discount stays at 5 a turn after the fifth turn (4.6.6).
- **Shop layout:** 7 cards at once (5 units and 2 spells) needs a layout check; the size itself is settled (owner, 13 Nov).

## When to redo this

- **Once real units exist:** measure the actual power gap between tiers, set `growth` to it, and rerun the round-2 sweep.
- **Once economy units are designed:** set `econShare`, `econPow` and `econGold` from them.
- **If damage or income changes:** any change to 10.1 or 4.1 should go through `lobby-v2` before it is decided.
- **Once the game is playable:** check real games against the targets: most players reach tier 5, and tier 6 goes mostly to the top 3–4 late in the game.

To rerun the decided set, from the repo root (it only prints; about 2 minutes per seed):

```bash
node tools/research/economy/lobby-v2/lobby2.js '{"tierBase":[8,12,16,19,26]}' "decided"
```
