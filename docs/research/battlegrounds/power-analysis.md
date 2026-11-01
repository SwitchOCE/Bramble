# Battlegrounds power analysis

What Hearthstone Battlegrounds (HSBG) charges in stats for each tier, keyword and kind of effect, what Once Upon a Galaxy charges for its positional "Support" units, and what a toy combat simulation says about stats and position on Bramble's staggered 4-3 board. This is the evidence base for [docs/design/power-budget.md](../../design/power-budget.md).

*Generated from `tools/research/power_budget.py` on 2026-10-27. Every number below is in a CSV or JSON file in [analysis/](analysis/); re-run the script to refresh them (`python -I tools/research/power_budget.py`, about 35 seconds).*

## Inputs

- HSBG card library: [data/minions.json](data/minions.json), HearthstoneJSON build 255790 (patch 37.0.0, 26 Oct 2026). 303 minions in the current pool; 986 distinct minions ever in the pool (one `lineage_primary` row per name, so reprints are not double-counted). Historical minions carry the stats from the last sampled build they were in the pool.
- 83 monthly pool snapshots from Dec 2019 to Oct 2026 in `tools/research/.cache/slim/` (made by `build_bg_library.py`; not committed). They give the power-creep tables. Without the cache the script still runs and skips those tables.
- Tavern spells: [data/spells.json](data/spells.json).
- Galaxy library: [../galaxy/data/cards.json](../galaxy/data/cards.json), 314 current, non-token characters with attack and health. Rules: [../galaxy/rules.md](../galaxy/rules.md).
- HSBG rules reference (`docs/research/battlegrounds/rules.md`) was not written yet when this ran. Economy numbers below come from the [hearthstone.wiki.gg Battlegrounds page](https://hearthstone.wiki.gg/wiki/Battlegrounds): 3 gold on turn 1, +1 per turn to 10, minions cost 3, sell for 1, refresh costs 1. **TODO:** check them against rules.md when it lands.

"SP" (stat point) means 1 Attack or 1 Health. "Stat ratio" is a card's attack+health divided by the median for its tier. A coefficient of −0.20 means cards with that feature carry 20% less stats than otherwise similar cards of the same tier.

## Headline findings

1. **Stats rise by about 1.75 SP per tier, and the tier is the real price.** The median stat total climbs from 4.5 at Tier 1 to 12.5 at Tier 6. But text explains only 15–27% of the stat spread within a tier. HSBG prices a card mostly by its tier and shop odds, not by trading stats for text.
2. **Text costs little in stats, except for a few keywords and death effects.** Divine Shield, Reborn, Venomous and Magnetic each cost 15–27% of the tier budget. Deathrattles cost 11–24%. Most recruit-phase effects, economy included, cost almost nothing in stats. Drawbacks give stats back: +36 to +46%.
3. **Printed stats barely crept. Scaling text did.** Tier means moved about +0.5 SP at Tiers 1–2 and +1.5 at Tier 5 over seven years, and stayed flat at Tiers 3 and 6. Meanwhile the share of the pool with permanent or per-turn scaling text rose from about 6% (2020) to 32% (2026). HSBG's power creep lives in text, not in base stats.
4. **On a staggered 4-3 board, back-row Attack is worth about 0.75 of front-row Attack, and Health is worth the same in either row.** Back units attack after the front row has mostly died. 85–87% of back-row attacks happen with **no** living unit in front of them. So "units behind this" effects on front units are nearly worthless, while back-row auras on the front row pay in full (toy simulation).
5. **Galaxy's Support units mostly give up 2–6 body SP to project 4–28 SP of aura onto the two front slots.** Supports in Galaxy average about 12% below their rarity's stat median. The toy simulation agrees that a back-row aura on the two front units is realised at about 100% of its nominal value on a full board.

## 1. Stats per tier

Attack + health (normal, non-golden). Mean / median / interquartile range.

| Tier | Current n | Current mean | Current median | Current IQR | All-time n | All-time mean | All-time median | All-time IQR |
|---|---|---|---|---|---|---|---|---|
| 1 | 26 | 4.3 | 4.5 | 3–5 | 73 | 4.2 | 4 | 3–5 |
| 2 | 41 | 5.4 | 6 | 4–7 | 134 | 5.6 | 6 | 5–7 |
| 3 | 53 | 6.7 | 7 | 5–9 | 190 | 6.7 | 7 | 5–8 |
| 4 | 69 | 8.7 | 9 | 7–10 | 218 | 8.5 | 8 | 7–10 |
| 5 | 62 | 10.6 | 10 | 9–12 | 206 | 10.5 | 10 | 9–12 |
| 6 | 38 | 12.8 | 12.5 | 11–14 | 138 | 12.6 | 12 | 10–15 |
| 7 | 14 | 19.1 | 19 | 14–21 | 27 | 18.0 | 16 | 12–21 |

Source: [tier_stats.csv](analysis/tier_stats.csv).

**Fitted curve, Tiers 1–6** ([stat_curve.json](analysis/stat_curve.json)):

| Fit | Current pool | All-time |
|---|---|---|
| Linear: stats = a + b × tier | 1.86 + 1.76 × tier (SE of slope 0.10), R² 0.50 | 1.94 + 1.71 × tier (SE 0.06), R² 0.45 |
| Exponential: stats = S₁ × gᵗ⁻¹ | S₁ 4.0, g 1.26 per tier, log-R² 0.51 | S₁ 4.1, g 1.25, log-R² 0.46 |
| Quadratic term | +0.13 × tier², R² 0.51 | +0.13 × tier², R² 0.46 |

Linear and exponential fit equally well over Tiers 1–6. The quadratic term is small. The half of the variance the curve doesn't explain is the card-to-card spread, not curvature. Tier 7 (14 current cards) sits well above the line (median 19 against a linear prediction of 14). It is a special tier, available only through anomalies and effects, with display-stat oddities such as The Boommobile at 30/30.

**Outliers** ([stat_outliers.csv](analysis/stat_outliers.csv), robust z ≥ 2.5 within tier) fall into three groups:

- **Over-statted cards with drawbacks or hard conditions.** Holy Vanguard (T4 10/10, "+30/+30 if you have 15 or less Health"), Incorporeal Corporal (T1 5/5, destroys itself after attacking), Bubblette, Beleaguered Battler, The Beast (gives the opponent a 3/3), Zapp Slywick and Worgen Vigilante (forced targeting).
- **Over-statted vanilla or near-vanilla bodies.** Boulderfist Ogre (T3 6/7, no text), Greedy Conniver (T3 7/7) and Tyrael (T6 10/10).
- **Under-statted engines.** 1/1s and 2/1s at Tiers 2–4: Forest Rover, Patient Scout, Generous Geomancer, Tavern Tempest, Deadly Spore (T3 1/1 Venomous).

**Attack share** ([attack_share.csv](analysis/attack_share.csv)): attack is 46–50% of stats at every tier (current pool overall 0.478; all-time 0.472). HSBG leans slightly toward health. By tribe in the current pool, Mech (0.53), Elemental (0.53) and Pirate (0.51) lean to attack, and Quilboar (0.44), Beast (0.44), Dragon (0.44) and untyped (0.44) lean to health. The tribe spread (±0.05) is small next to the card spread.

## 2. What text costs in stats

Method ([feature_costs.csv](analysis/feature_costs.csv), [feature_models.json](analysis/feature_models.json)):

- Each card's text is classified into 38 features: 8 keywords, 13 trigger types, 14 effect types and 3 conditions. Patterns are deliberately simple and can be audited card by card in [card_features.csv](analysis/card_features.csv).
- Stat ratio is regressed on all features at once, with OLS and with a Huber robust fit. Tiers 1–6 only; a feature needs at least 5 cards.
- A tier-matched grouped difference serves as a model-free check: the mean ratio of cards with the feature minus cards without it, within each tier.
- The "SP @ T3" column multiplies the OLS coefficient by the Tier 3 median (7). The absolute model (stats on tier dummies plus features) gives similar flat-SP figures in the CSV.
- The intercept (a card with none of the features) is 1.04 for the current pool and 1.13 all-time. A plain card carries about 4–13% more stats than the tier median.
- **Fit:** features explain R² 0.21 (current; Huber 0.27) and 0.15 (all-time) of the stat-ratio variance. That is a weak budget.

### Keywords

| Keyword | All-time n | All-time OLS (±SE) | Grouped | Current n | Current OLS (±SE) | SP @ T3 (all-time) |
|---|---|---|---|---|---|---|
| Divine Shield | 45 | −0.26 ± 0.05 | −0.18 | 18 | −0.17 ± 0.08 | −1.8 |
| Venomous / Poisonous | 8 | −0.25 ± 0.11 | −0.20 | 2 | — | −1.8 |
| Reborn | 21 | −0.18 ± 0.07 | −0.19 | 6 | −0.27 ± 0.13 | −1.3 |
| Magnetic | 18 | −0.15 ± 0.08 | −0.08 | 9 | −0.19 ± 0.11 | −1.0 |
| Taunt | 68 | +0.03 ± 0.04 | −0.01 | 10 | −0.04 ± 0.10 | ≈0 |
| Stealth | 6 | +0.05 ± 0.13 | +0.11 | 1 | — | ≈0 |
| Windfury | 12 | +0.31 ± 0.09 | +0.29 | 3 | — | +2.2 |
| Cleave | <5 | — | — | 1 | — | not estimable |

Reading the table:

- **Taunt is free.** That matches the old Hearthstone rule of thumb that Taunt is worth about one stat ([Blizzard forum](https://us.forums.blizzard.com/en/hearthstone/t/card-health-amounts-and-why-wild/129113?page=2)). In Battlegrounds, where the player can't choose targets, it is worth even less (see section 6).
- **Divine Shield costs about a quarter of the budget.** That is close to Elie Bursztein's least-squares estimate for 2014 constructed Hearthstone: 1.40 mana, against 0.57 per Attack and 0.40 per Health ([source](https://elie.net/blog/hearthstone/how-to-find-automatically-hearthstone-undervalued-cards)).
- **Windfury's positive sign is selection, not a discount.** Windfury cards are big bodies with little else (Zapp Slywick 11/22, Worgen Vigilante 10/20, Frantic Alarm-o-Bot 4/4). The keyword multiplies attack, so it is put on bodies that have some.

### Triggers and effects

All-time sample unless noted. Negative = paid for in stats.

| Feature | n | OLS (±SE) | Grouped | Current OLS | Note |
|---|---|---|---|---|---|
| Deathrattle (not a summon) | 102 | −0.18 ± 0.04 | −0.15 | −0.11 | Death value paid in body |
| Spellcraft | 28 | −0.18 ± 0.06 | −0.12 | −0.06 | Repeating recruit-phase buff |
| Deathrattle summon | 60 | −0.18 ± 0.05 | −0.11 | −0.24 | Body continues after death |
| End of turn | 79 | −0.14 ± 0.04 | −0.08 | −0.00 | Per-turn scaling |
| Battlecry | 158 | −0.13 ± 0.03 | −0.07 | +0.00 | |
| Choose One | 20 | −0.13 ± 0.07 | −0.05 | +0.06 | |
| Doubler (Brann-style) | 8 | −0.11 ± 0.12 | −0.10 | −0.12 | Rule-changers, low stats |
| Self-growth | 80 | −0.08 ± 0.04 | −0.02 | +0.08 | |
| Spell generation | 68 | −0.06 ± 0.04 | −0.03 | −0.12 | |
| Start of Combat | 33 | −0.05 ± 0.06 | −0.01 | +0.01 | |
| Aura | 70 | −0.05 ± 0.05 | −0.04 | +0.02 | |
| Card generation | 82 | −0.04 ± 0.04 | −0.05 | −0.04 | |
| Economy (gold, coins, cheaper refreshes) | 59 | −0.04 ± 0.05 | +0.01 | −0.06 | **Economy is nearly free in stats** |
| Recruit trigger (after you play/buy/cast) | 109 | −0.04 ± 0.04 | +0.01 | +0.00 | |
| Buffs others | 251 | −0.03 ± 0.03 | −0.02 | −0.01 | |
| Tribe-dependent text | 290 | −0.02 ± 0.02 | −0.02 | −0.09 | Condition costs little |
| Permanent / "this game" scaling | 155 | −0.02 ± 0.03 | −0.04 | −0.08 | |
| Position text (adjacent, left-most…) | 50 | −0.04 ± 0.05 | +0.01 | +0.04 | |
| Avenge | 41 | +0.02 ± 0.05 | +0.05 | +0.22 | Avenge bodies are sturdy |
| Rally (when this attacks) | 51 | +0.03 ± 0.05 | +0.08 | +0.08 | Needs to survive to attack |
| In-combat trigger (after attacks, takes damage…) | 98 | +0.04 ± 0.04 | +0.12 | +0.15 | Same |
| Shop buff (Tavern minions) | 19 | +0.06 ± 0.08 | +0.05 | +0.28 | |
| Damage / destroy | 47 | +0.07 ± 0.05 | +0.20 | +0.09 | Often self-damage |
| Activate (N) | 25 | +0.09 ± 0.07 | +0.18 | +0.09 | Effect costs gold each use |
| **Drawback** | 14 | **+0.36 ± 0.09** | **+0.46** | — | Over-statted by design |

Patterns worth carrying over:

- **What HSBG pays for in stats** is effects that act after the body is gone (Deathrattles, Reborn) and effects that make one fight harder to answer (Divine Shield, Venomous).
- **What HSBG doesn't charge in stats** is recruit-phase value: economy, card generation, per-turn buffs. Those cards are under-statted only a little. They are priced by tier, and by the fact that a recruit-phase engine wants to be *sold* before the late fights.
- **Triggers that need the unit to survive** (Rally, Avenge, "after this attacks") come on bodies at or above the tier median. The body is part of the effect.
- **Activate effects** (pay gold to use) are on above-median bodies. The gold paid is the price.
- Current-pool and all-time coefficients disagree in places (Battlecry, end of turn). The current-pool sample is small (303 cards, 289 used), and modern design moved value from printed stats into text.

### Complexity tax

Stat ratio by number of classified (non-condition) features ([stat_ratio_by_complexity.csv](analysis/stat_ratio_by_complexity.csv)):

| Features | All-time n | Mean ratio | Current n | Mean ratio |
|---|---|---|---|---|
| 0 | 27 | 1.11 | 9 | 1.09 |
| 1 | 257 | 1.04 | 62 | 1.04 |
| 2 | 420 | 1.02 | 128 | 0.97 |
| 3 | 203 | 0.99 | 71 | 0.97 |
| 4+ | 52 | 0.96 | 19 | 0.90 |

Each extra effect costs about 3–5% of the tier budget on average. "Combat only" and "recruit-phase only" cards have about the same mean ratio (0.98 and 0.99 current; 1.04 and 0.99 all-time).

### Selection bias

These coefficients measure what designers *charged*, not what effects are *worth*:

- **Engines are under-statted on purpose.** A 1/1 engine at Tier 3 shows up as "text costs 70%", but the designers may simply want it to be bad in combat.
- **Strong text gets nerfed through the tier, not the stats.** A card that is too strong usually moves up a tier or loses text (see section 5), so its stat cost never shows up.
- **The 5 vanilla or keyword-only cards in the current pool can't anchor the curve.** The plain-card intercept (1.04–1.13 × median) stands in for a "vanilla" baseline. The historical vanilla Boulderfist Ogre (T3 6/7, 1.86 × median) shows HSBG treats pure stats as weak late in the game.

## 3. Golden versus normal

([golden.json](analysis/golden.json))

- **Stats:** 977 of 981 all-time minions (300 of 303 current) have exactly double stats when golden. The exceptions are deliberate: Aureate Laureate (always golden), Dark Paradox, Sky-hatch Runaway (4/7 to 10/14) and Boulderfist Ogre (6/7 to 6/7, a joke).
- **Text numbers** (current pool, where the normal and golden texts have the same count of numbers):
  - 208 numbers double. These are effect sizes.
  - 75 stay the same. These are counters and thresholds: Avenge (3), "(35 left!)", "every 3 spells".
  - 121 texts are reworded instead, usually "twice" or "trigger twice".
- HSBG's golden rule is therefore **2× body, 2× effect size, 1× thresholds**, plus a Triple Reward (discover a minion from the next tier up).

## 4. Gold and stats

**Buff spells** ([spell_gold_to_stats.csv](analysis/spell_gold_to_stats.csv)), unconditional only:

| Spell kind | Tier 1 | Tier 3 | Tier 4 | Tier 5–6 |
|---|---|---|---|---|
| One target: SP per gold | 4 (Banana, Pointy Arrow) | 6 (Repair Job, Selfish Bounty) | 5.5 (Defender's Rites 7, Conflagration 4) | 12 (Forest's Bounty, conditional) |
| Whole warband: SP per gold per unit | — | 1–2 (Shiny Ring, Bounties) | — | 2–2.5 (Queen's Command, Wave of Gold, Azerite Empowerment) |

**Minion bodies** cost 3 gold and sell for 1, so a body buys about 1.5 SP per gold at Tier 1 (4.5 SP) and about 4 at Tier 6 (12.5 SP). A board slot comes with it.

**Conclusion:** stats on a spell are 2–3× cheaper per gold than stats on a body. What a body really buys is a slot, and the slot is the scarce resource. This is why HSBG barely charges stats for economy text on minions (section 2). The card's gold value and its board value are separate budgets.

## 5. Power creep and balance levers

From the 83 monthly snapshots ([creep_by_year.csv](analysis/creep_by_year.csv), [creep_by_build.csv](analysis/creep_by_build.csv), [stat_changes.csv](analysis/stat_changes.csv)).

**Mean printed stats in the pool, by year.** 2019 is a single build, and 2019–2020 pool membership is heuristic.

| Year | T1 | T2 | T3 | T4 | T5 | T6 | Share of pool with scaling text |
|---|---|---|---|---|---|---|---|
| 2019 | 3.3 | 4.6 | 7.1 | 7.6 | 8.6 | 12.0 | 4% |
| 2020 | 3.4 | 4.8 | 6.8 | 7.9 | 8.9 | 12.3 | 6% |
| 2021 | 3.6 | 5.3 | 6.4 | 8.2 | 8.9 | 12.1 | 12% |
| 2022 | 3.8 | 5.6 | 6.4 | 8.3 | 9.3 | 12.5 | 14% |
| 2023 | 3.8 | 5.1 | 6.4 | 7.6 | 9.1 | 12.4 | 20% |
| 2024 | 4.0 | 5.4 | 6.4 | 7.6 | 9.4 | 13.0 | 26% |
| 2025 | 3.8 | 5.5 | 6.2 | 7.8 | 9.8 | 11.5 | 30% |
| 2026 | 3.7 | 5.5 | 6.5 | 8.2 | 10.2 | 12.2 | 32% |

"Scaling text" here means permanent, "this game", per-turn, "improves" or Tavern-buff wording.

- Printed stats crept slowly: about +0.5 SP at Tiers 1–2 and +1.5 at Tier 5 over seven years, with Tiers 3, 4 and 6 flat.
- The scaling share rose fivefold. Late-game boards in modern HSBG reach hundreds of stats through text, so printed stats matter less each year.
- Cards first seen in 2026 sit 12% above the all-time tier median (cohort table, [creep_by_first_seen_cohort.csv](analysis/creep_by_first_seen_cohort.csv)). That is slight recent printed creep.

**How Blizzard tunes** (760 changes to the same card between sampled builds):

| Change | Count |
|---|---|
| Stats up, same tier | 276 |
| Stats down, same tier | 182 |
| Moved down a tier (buff) | 155 |
| Moved up a tier (nerf) | 134 |
| Attack and health reshaped, same total | 13 |

Same-tier stat changes are small. 209 changed the total by 1 SP, 142 by 2, 53 by 4, and only 23 by more than 4. Tier moves are almost as common as stat changes. **The tuning levers are ±1–2 SP and ±1 tier.** That sets the precision a budget needs. Text changes also happen but aren't counted here (a `text_changed` flag is in the CSV).

## 6. Once Upon a Galaxy

([galaxy_stats_by_rarity.csv](analysis/galaxy_stats_by_rarity.csv), [galaxy_feature_diffs.csv](analysis/galaxy_feature_diffs.csv), [galaxy_support_costing.csv](analysis/galaxy_support_costing.csv))

Galaxy has 5 fixed slots (3 front, 2 back, staggered like Bramble), and summons take the dead unit's slot. Attackers hit a random front-row enemy while one exists. All buffs are permanent, and there is no gold. See [rules.md](../galaxy/rules.md).

| Rarity (shop turn) | n | Median stats | Mean | Attack share |
|---|---|---|---|---|
| Common (T1) | 47 | 4 | 3.6 | 0.47 |
| Uncommon (T3) | 59 | 7 | 6.8 | 0.53 |
| Rare (T5) | 66 | 12 | 11.0 | 0.51 |
| Epic (T7) | 61 | 16 | 15.8 | 0.49 |
| Legendary (T9) | 65 | 35 | 33.8 | 0.51 |

Galaxy's first four rarities track HSBG Tiers 1, 3, 6 and 7 closely. Legendaries double. Galaxy accepts runaway numbers and polices loops and pace instead ([design notes](../galaxy/design-notes.md)).

**Rarity-matched stat difference by keyword** (n ≥ 3):

| Feature | n | Diff | Feature | n | Diff |
|---|---|---|---|---|---|
| Summon | 22 | −0.33 | Hunt (on kill) | 38 | −0.00 |
| Farewell (death) | 47 | −0.28 | Recruit (on buy) | 57 | +0.02 |
| **Support** | 21 | **−0.12** | Sneak (hits back row) | 6 | +0.05 |
| Text says "in front of" | 14 | −0.10 | Quest | 50 | +0.26 |
| Ranged (no retaliation) | 11 | −0.08 | Golden reward | 13 | +0.33 |
| Slot buffs | 35 | −0.08 | Text says "behind" | 3 | +0.31 |

The same pattern as HSBG: death and summon value is paid in body, and on-buy value is nearly free.

**Support costing.** A Support unit sits in a back slot and buffs "the characters in front of me", the two front slots it sits between. This is Bramble's geometry exactly.

| Card | Rarity | Body (median) | Support (per target) | Nominal aura on 2 targets | Body SP given up |
|---|---|---|---|---|---|
| Puck / Pix | Common | 1/1 (4) | +2 Attack / +2 Health | 4 | 2 |
| Lollipop Faerie | Common | 1/1 (4) | +1/+1, grows | 4 | 2 |
| Jill Sunshine / Jack Frost | Uncommon | 3/2, 2/3 (7) | +5 Attack / +5 Health | 10 | 2 |
| Faerie Dragon | Rare | 3/3 (12) | +1/+1 and Treasure Hoard | 4 | 6 |
| Sunflaerie | Epic | 7/7 (16) | +7/+7 | 28 | 2 |
| Innkeeper | Epic | 10/10 (16) | +5/+5, grows | 20 | −4 |
| Mephisto | Legendary | 6/6 (35) | +6/+6 and steals dying fronts | 24 | 23 |
| Moonshadow | Legendary | 15/15 (35) | +10/+10, supports gain Ranged | 40 | 5 |

Galaxy charges supports only 2–6 body SP for a nominal 4–28 SP aura. Two caveats:

- The aura holds only while the supporter lives *and* the front slots are filled.
- Galaxy has since nerfed early supports (Pix and Puck were cut to +2 in March 2026 for causing "more full heart losses than we prefer early in games"). It also noted that supports are "so lowly statted" that their payoff cards needed help ([patch notes](https://galaxy.fun/articles/patch-mid-november-2025/), via [design-notes.md](../galaxy/design-notes.md)).

**Lesson: Galaxy under-priced early supports and then had to correct them.**

## 7. Toy combat simulation: rows and position

`run_sim()` in the script. It plays 6,000 paired fights per cell with common random numbers, at Tier 2 and Tier 5, using random boards drawn from the current pool's real (attack, health) pairs, with text stripped.

Rules follow the HSBG baseline:

- The side with more units goes first.
- Sides alternate single attacks, in slot order.
- Targets are random, Taunt first. Damage is simultaneous.

**Bramble layout:** slots F1–F4 then B1–B3, so the order is front left to right, then back left to right. The back row can't be targeted while any front unit lives, and nobody moves. **HSBG layout:** the same seven slots as one row. Win-rate changes are converted to SP-equivalents using the layout's average value of one stat point (+0.046 win rate per SP at Tier 2, +0.028 at Tier 5).

This is a calibration aid, not a balance verdict: vanilla boards only, no effects, no summons.

### Exposure by slot (Tier 5)

| Slot | Attacks made / fight | Times attacked / fight | Survives the fight |
|---|---|---|---|
| F1 | 0.95 | 0.72 | 2% |
| F2 | 0.82 | 0.85 | 2% |
| F3 | 0.67 | 1.02 | 2% |
| F4 | 0.52 | 1.15 | 1% |
| B1 | 1.05 | 0.37 | 21% |
| B2 | 0.83 | 0.50 | 25% |
| B3 | 0.50 | 0.71 | 33% |
| HSBG P1 / P7 | 1.07 / 0.40 | 0.51 / 1.03 | 10% / 20% |

Front units almost never survive. Back units survive more than 10× as often. Tier 2 looks the same ([sim_slot_exposure.csv](analysis/sim_slot_exposure.csv)).

### Value of a stat by row

Mean SP-equivalent, Tier 2 / Tier 5 ([sim_marginal_values.csv](analysis/sim_marginal_values.csv)):

| Modifier | Bramble front | Bramble back | HSBG row |
|---|---|---|---|
| +2 Attack | 2.03 / 2.28 | 1.46 / 1.71 | 1.77 / 2.04 |
| +2 Health | 2.22 / 1.96 | 2.20 / 1.98 | 2.23 / 1.96 |
| Divine Shield | 3.00 / 4.90 | 3.02 / 4.91 | 3.00 / 4.76 |
| Taunt | 0.07 / 0.04 | 0.06 / 0.08 | −0.09 / 0.07 |

- **Attack.** Back-row Attack is worth 0.72–0.75 of front-row Attack. Within a row, earlier slots are worth more: F1 +2 Attack is 2.6 SP at Tier 5 against 2.0 for F4, because F1 attacks first and most often.
- **Health** is worth the same in either row. The back row is safe only until the front falls, and then it takes every hit.
- **Divine Shield** is worth about one enemy attack: 3.0 SP at Tier 2, where mean attack is 2.5, and 4.9 SP at Tier 5, where it is 4.9. It is worth the same in either row. HSBG charges it about 0.25 × the tier median (1.5 SP at Tier 2, 2.5 at Tier 5). In combat terms DS is under-charged, which suggests its real-game value is lower: Venomous, cleave and AoE counter it.
- **Taunt** is worth about zero on vanilla boards. It only redirects random attacks, and redirecting has no value unless something specific needs protecting. On the Bramble board, back-row Taunt does nothing while the front lives.

### Position effects

([sim_positional_effects.csv](analysis/sim_positional_effects.csv), SP-equivalent and share of nominal value realised)

| Effect | Tier 2 | Tier 5 | Realised |
|---|---|---|---|
| Back slot: "units in front of this have +2 Attack" (nominal 4 SP) | 3.8–4.0 | 4.1–4.8 | **95–119%** |
| Back slot: "when a unit in front of this dies, gain +2/+2" | 6.8–7.1 | 7.0–7.5 | about 1.9 triggers per fight |
| Front slot: "units behind this have +2 Attack" (nominal 2–4 SP) | 0.0–0.13 | 0.0–0.18 | **0–7%** |
| HSBG: "adjacent minions have +2 Attack" (nominal 2–4 SP) | 0.8–2.4 | 1.1–2.9 | 39–72% |

**Neighbour counts during a fight on a full board** ([sim_neighbours.json](analysis/sim_neighbours.json)):

- When a back unit attacks, living units in front of it: 0 in 85–87% of cases, 1 in 11–14%, 2 in 1–1.5%. Mean 0.14–0.17.
- When a front unit attacks, living units behind it: mean 1.50. It is 1 or 2 about equally, which is simply the 4-3 shape: F1 and F4 have 1 behind, F2 and F3 have 2.
- When a front unit dies, a unit behind it is alive 98% of the time. "When the unit in front of this dies" fires about 5.8 times per fight across the back row (1.9 per back unit).

**Why:** attack order is front row first, so by the time B1 attacks (its side's 5th attack) the front rows have mostly traded off. Anything a front unit gives to "the units behind it" is gone by the time those units act. Anything a back unit gives "the units in front of it" lands during the front row's attacks.

### Placement and gaps

([sim_placement.csv](analysis/sim_placement.csv), [sim_empty_slot.csv](analysis/sim_empty_slot.csv))

- **Placement.** Putting the four highest-Health units in front, or the four lowest, changes win rate by at most 1.5 points (±0.5) against random placement. With vanilla units, **row placement is almost not a decision.** Position decisions will have to come from text.
- **Empty slot.** Removing any one unit from a full board costs 21–23 points of win rate whichever slot is left empty. A gap has no defensive value of its own with vanilla units.

### Sim limits

- Vanilla units only. No Deathrattles, summons, Cleave or Venomous.
- Boards are random draws, not drafted.
- Ties and the HSBG attacker-pointer rule are approximated (the next living unit after the last attacker).
- Damage to the hero isn't modelled. Only win, draw or loss counts.
- Treat signs and ratios as robust, and absolute SP values as Tier 2 and Tier 5 snapshots.

## Caveats

- **Selection bias.** Covered in section 2: coefficients are what was charged, not value.
- **Classification is regex on rules text.** Effects that look alike in text can differ a lot in power. Audit [card_features.csv](analysis/card_features.csv) before relying on any single coefficient. Rare features (n < 20) have wide errors; the ± values are 1 standard error.
- **Historical stats are each card's last pool version.** Cards nerfed before removal look weaker. The per-build snapshot tables don't have this problem.
- **Stats aren't power in HSBG's late game.** End-game boards are driven by scaling text, so printed stats price the early and mid game. The budget for scaling effects has to come from simulation of whole games, not from printed stats.
- **Pool composition.** Tribes rotate per lobby, so a card's real availability, and the strength of its tribe text, depend on the lobby.

## Sources

Data:

- [HearthstoneJSON](https://hearthstonejson.com/) build 255790 and the [HearthSim/hsdata](https://github.com/HearthSim/hsdata) build history.
- HSBG rules: [hearthstone.wiki.gg Battlegrounds](https://hearthstone.wiki.gg/wiki/Battlegrounds).
- Galaxy: [guide.galaxy.fun](https://guide.galaxy.fun/cards/) and the [Galaxy patch notes](https://galaxy.fun/articles/patch-mid-november-2025/), via `docs/research/galaxy/`.

Card valuation:

- Elie Bursztein, a linear stat-per-mana model: [How to appraise Hearthstone card values](https://elie.net/blog/hearthstone/how-to-appraise-hearthstone-card-values) and [How to find undervalued Hearthstone cards automatically](https://elie.net/blog/hearthstone/how-to-find-automatically-hearthstone-undervalued-cards). Least squares over 134 launch cards: Attack 0.57, Health 0.40, Divine Shield 1.40, Windfury 1.19, Taunt 0.51, Stealth 0.61 mana.
- The vanilla test: about 2 stats per mana, often 2 × mana + 1. Sources: [Dot Esports](https://dotesports.com/hearthstone/news/understanding-card-value-and-stat-distribution-29647) and a [Blizzard forum thread](https://us.forums.blizzard.com/en/hearthstone/t/card-health-amounts-and-why-wild/129113?page=2).
- A community point system (1 mana = 2 points; DS −2, Windfury −4, Taunt −1): the [r/customhearthstone balance wiki](https://lr.in.psf.lt/r/customhearthstone/wiki/balance). Homebrew; the page could not be fetched directly, so the figures are from its search summary.
- Magic: [Making Magic, 2003, on vanilla creatures](https://magic.wizards.com/en/news/making-magic/lets-start-very-beginning-2003-07-14). The [MTG wiki on vanilla creatures and power creep](https://mtg.wiki/page/Vanilla). Mark Rosewater on keeping "rate" separate from colour pie ([MTG Rocks](https://mtgrocks.com/mtg-head-designer-talks-about-internal-dispute-over-sylvan-anthems-rate-its-cost-or-effect-would-be-tweaked/)).

Balancing practice:

- Blizzard: [Developer Insights: Battlegrounds Balance](https://us.forums.blizzard.com/en/hearthstone/t/87311/1). It measures by average placement, keeps heroes "in an appropriate band of power", and puts nerfs before buffs.
- HSReplay's [Tier7 Battlegrounds stats](https://hsreplay.net/battlegrounds/tier7) report minion placement impact.
- Riot: [TFT dev post](https://teamfighttactics.leagueoflegends.com/en-au/news/dev/dev-teamfight-tactics-monsters-attack-learnings/). Higher cost should mean more power at equal star level, and full trait support gave "a two cost unit the power of a four cost". Also [Upcomer on TFT patch 11.24](https://www.upcomer.com/the-three-innovators-how-the-tft-live-balance-team-built-patch-11-24/): round and lobby win rate by cost, star level, items and traits.
- Automated balancing: [Ludus: An Optimization Framework to Balance Auto Battler Cards](https://ojs.aaai.org/index.php/AAAI/article/view/21550) (AAAI 2022). Simulated playtests plus search over card parameters.
