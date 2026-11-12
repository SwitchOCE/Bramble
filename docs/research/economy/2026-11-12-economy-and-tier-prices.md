# Economy and tier prices: how they were set (12 Nov 2026)

This is the full record of one day's economy work, from the owner's first brief to the decided tier-up prices. It sets out what was asked, each model built, what it showed, and where the owner changed course. It is here so the work can be checked, rerun and redone when better evidence comes in, such as real games.

- **Decided** (rulebook v0.7, source C13): income, unit prices, sell values, refreshes, shop size, tier-up prices and discount. See [the summary](README.md#decided).
- **The sims:** [tools/research/economy/](../../../tools/research/economy/README.md).
- **Saved outputs:** [results/](results/).
- **Linked work:** the damage system was set the same day (rulebook 10.1, source C12) with the Damage Lab, archived in `docs/archive/damage-lab/` on `main`. The two systems are tied together; see [Damage](#damage-is-the-linked-lever) below.

The owner's words are quoted from chat, with dictation errors removed.

---

## 1. The brief

The owner's starting rules:

> Okay, so for economy changes, I want A, the player to start turn one with 5 gold. And I'm thinking that it increases by 3 every turn instead of 2 or 1. 2 or 3 are up in the air…

> I want the shop to always have 5 units and 2 spells… It will not change with tier. What will change is the shop odds and the chances of finding effects of specific rarities.

> …operating on the assumption that we are [6 tiers]. Units are going to cost 1 plus their tavern tier and sell for 1 less than the total gold the player spent acquiring the unit. If a unit is created from an effect it's considered a token… they don't count as having money spent on them. So they don't increase the sell price, even if they're combined into a triple.

And the questions:

> …how much should we charge for tavern tiering up… look at the systems from other games like TFT… Battlegrounds… pool odds… probably we just have a concept of… the way TFT does it with rarities… with 5 slots… do we need to reduce the number of higher tier units… how much gold will the player have… Maybe assume some supplemental economy… and look at the case without… propose some approaches, propose some like rough models…

## 2. Round 1: shop odds and gold models

**Shop odds.** Battlegrounds odds per shop slot were worked out from the card library ([minions.csv](../battlegrounds/data/minions.csv)) for a 5-tribe lobby. They come from copies left in the pool, so they are approximate. Units with two tribes are slightly undercounted, because the tribes column uses `|`.

| Shop tier | T1 | T2 | T3 | T4 | T5 | T6 |
|---|---|---|---|---|---|---|
| 2 | 40 | 60 | | | | |
| 3 | 25 | 37 | 39 | | | |
| 4 | 17 | 25 | 27 | 31 | | |
| 5 | 14 | 20 | 22 | 25 | 19 | |
| 6 | 13 | 19 | 20 | 23 | 18 | 8 |

TFT draws a rarity first, then a champion of that rarity. Its long-standing odds table was used. **It was not checked against the current set (Set 18):** the web pages that list it are client-rendered and couldn't be fetched. From the two, a "TFT-like" table for Bramble was drafted. It leans towards your own tier, and low tiers fade out. Every sim since uses it.

| Shop tier | T1 | T2 | T3 | T4 | T5 | T6 |
|---|---|---|---|---|---|---|
| 1 | 100 | | | | | |
| 2 | 60 | 40 | | | | |
| 3 | 35 | 40 | 25 | | | |
| 4 | 20 | 30 | 32 | 18 | | |
| 5 | 12 | 20 | 28 | 27 | 13 | |
| 6 | 7 | 13 | 22 | 27 | 21 | 10 |

A steeper table, with tier 6 at 3/8/17/27/28/17, was also tried. Full output: [results/shop-odds.txt](results/shop-odds.txt).

- **Finding a specific unit.** Its chance per slot is its tier's odds divided by the number of units of that tier in the lobby. On the TFT-like table at tier 6, finding one particular tier-6 unit takes about 16, 24 or 32 shops, with 8, 12 or 16 tier-6 units in a lobby. How many high-tier units a lobby holds matters as much as the odds.
- **The shop odds are not decided.** The owner asked to come back to them after the economy (section 9).

**Gold models** (`gold-models/model.js`, `sweep.js`, `test2.js`, `test3.js`; output in [results/gold-models-round1.txt](results/gold-models-round1.txt)). One player, gold only, with a simple buy-and-refresh policy.

- **Tier-up prices.** Three ways of pricing them all gave the same rule of thumb: a tier-up taken on pace should cost about one turn's income. That rule reproduces Battlegrounds: a rush reaches tier 6 on turn 8, and by turn 10 tier-ups take about 46% of all gold.
- **+3 income** left gold piling up late in the game.

## 3. Round 2: the owner's changes

> I think we need to change the refreshes to the first 10 post one. And then after that, they go up by 5, one every 5, like before.

> Let's change it so units sell for half It's tier rounded up. As a result, a triple of a 5 would actually sell for 9, not 8.

> Let's go with the Plus 2 income per turn. Let's say that once you get to 15 total income, it increases by 1 per turn after that.

> …discounted by 2, then 3, then 4, then 5…

> …make the shops more expensive at first, so that we're intending that the player can't level 2 turns in a row. They'd have to make a lot of sacrifices…

Income became 5, 7, 9, 11, 13, 15, 16, 17…: 130 gold in total by turn 10, and 216 by turn 14.

Model: `gold-models/model2.js` and `v2test.js`; output in [results/gold-models-round2.txt](results/gold-models-round2.txt).

- **Gold lost on a sale** at tiers 1–6 is 1, 2, 2, 3, 3 and 4.
- **The late-game pile-up was gone.**
*[The numbers in the next three bullets come from runs reported in chat that day. Their outputs weren't saved; `v2test.js` reruns the same price sets with different summary columns.]*

- **The 2-3-4-5 discount barely separated two pacings:** tiering up 2 turns in a row was only 3 gold dearer than every other turn. To make back-to-back hurt, the on-pace price had to be about a whole turn's income.
- **Prices of 9/14/18/21/23** left a back-to-back player 3 gold short, and put 48% of all gold into tier-ups by turn 10. A rush still reached tier 6 on turn 8.
- **The rhythm:** players alternated a tier-up turn with a buying turn, and their boards lagged about 1.7 tiers behind their shop tier mid-game.

## 4. The discount starts at 1

> …the discount because I think I should start at 1, not 2 discount… So it goes 1, then 2, then 3, then 4… if it's always discounting you no matter what, 2 turns in a row, you're already getting 1 discount. So the price isn't really the price… So yeah, 1, then 2, then 3, then 4, then 5

The total discount after waiting 1–5 turns is 1, 3, 6, 10 and 15. The owner later confirmed that it resets at every tier-up:

> The discount should reset back to 0.

Base prices of **8/12/16/19/21** were set so that tiering up every other turn costs about a whole turn's income: 7 on turn 2, then 9, 13, 16 and 18, against incomes of 11, 15, 17 and 19. Tiering up 2 turns in a row leaves a player 2 gold short of that turn's income.

**The calculator.** The owner asked for a calculator to play turns by hand ([tools/research/economy/shop-calculator.html](../../../tools/research/economy/shop-calculator.html)), and found it over-complicated:

> I'm not a big fan of the calculator. The UI was a bit over much for me. You kind of overcomplicated it rather than focusing on the stuff that really mattered and keeping it simple.

**Lesson:** for this owner, a short talk-through with tables beats a tool with many controls.

## 5. The fastest route to tier 6, and the burst

The owner asked:

> What is the fastest strategy you could get to the max tavern tier with this? And how much gold would you have to spend on units? Then what's the next best strategy that's like a turn slower?…

`schedule-search/rush.js` tries every tier-up schedule. "Unit gold" is all the gold not needed for tier-ups, up to the turn tier 6 is reached. Full output: [results/schedule-search.txt](results/schedule-search.txt).

| Tier 6 on turn | Best tier-up turns (tiers 2→6) | Tier-up gold | Unit gold |
|---|---|---|---|
| 7 | 2, 7, 7, 7, 7 | 63 | 13 |
| 8 | 3, 3, 8, 8, 8 | 58 | 35 |
| 9 | 4, 4, 9, 9, 9 | 55 | 56 |
| 10 | 4, 4, 4, 10, 10 | 51 | 79 |
| 11 | 5, 5, 5, 11, 11 | 49 | 101 |
| 12 | 2, 6, 6, 6, 12 | 45 | 126 |

**The burst.** Every best line waits while the discount builds up, then tiers up several times in one turn. A 5-turn wait takes 15 off, which makes the tier-3 tier-up free. With at most one tier-up a turn (`--one-per-turn`), tier 6 is still possible on turn 7, at 5–8 more gold for each speed.

## 6. Higher prices, judged on gold alone

> 79 unit gold is actually quite a bit, isn't it? I think we need to increase the tavern costs by quite a lot. They could easily be more than a turn worth of gold.

`schedule-search/prices.js` tested higher sets. The table shows the best unit gold for each turn tier 6 is reached; "—" means that turn can't be reached.

| Set (tiers 2→6) | T7 | T8 | T9 | T10 | T11 | T12 |
|---|---|---|---|---|---|---|
| Now 8/12/16/19/21 | 13 | 35 | 56 | 79 | 101 | 126 |
| A 8/14/22/30/38 | — | — | 22 | 44 | 66 | 92 |
| B 9/16/25/34/43 | — | — | 5 | 29 | 54 | 78 |
| D 8/16/26/36/46 | — | — | 2 | 26 | 49 | 72 |
| C 10/18/28/38/48 | — | — | — | 14 | 39 | 64 |

- **The discount's shape drives the burst.** Because it grows the longer you wait, one long wait collects more discount than several short ones. Under A, saving up and then bursting still beat tiering up every other turn: 44 gold against 31 by turn 10.
- **A flat discount (`--flat=3`) removes the edge.** Every route to tier 6 by a given turn then costs the same.

The owner rejected judging prices on gold alone:

> I think you need to consider that every turn you're not having access to higher tier units, you're losing quite a bit of power… staying multiple turns on one tavern tier needs to be given some money back in return. That's what it's for… we're looking at the economy system in isolation… Anyone who spent 22 unit gold and rushed there, like 9 turns of taking bad losses would put you on basically 1 HP. And then you'd have 1 turn at tier 6 to try and stabilize, and you would have lost a lot of scaling.

The owner was then leaning towards B or C.

## 7. Lobby sim v1: power, fights and damage

The owner asked for a simple "number comparison game":

> …let's say a T2 unit is 50% more powerful than a T1, and if you happen to get a triple… is more powerful by, like, about twice as much… a player who spends some money on spells and stuff gets a little bit of power… Add a tiny bit of RNG… I don't think a 90 should ever be beaten by a 60 in any situation, but if there's a 90 and an 85, maybe the 90 is favored… Remember, it should be very hard because, like, there's going to be economy units that give the player additional money… The player will have more money than our sim will indicate.

The sim is `lobby-v1/lobby.js`; full output in [results/lobby-v1.txt](results/lobby-v1.txt). Its judgement calls, all in `CFG`:

- **Unit power:** a tier-N unit is worth 10 × 1.5^(N−1). A triple is worth 2 copies, plus a free token unit one tier above the shop.
- **Growth:** each unit gains +1 plus 5% of its tier's power every turn it stays on the board. Selling a unit loses its growth.
- **Spells:** 3 gold for +36% of a unit of the player's tier, 2 per shop.
- **Fights:** board power times log-normal luck (σ 0.082). A 90 practically never loses to a 60, and beats an 85 about 68% of the time. A loss is big when the loser had under 65% of the winner's power. Damage, health and draws follow rulebook v0.6.
- **Players:** 8 bots with fixed plans:
  - Hyper-rush (tiers up whenever it can);
  - Burst (4, 4, 10, 10, 10);
  - Fast (2/4/6/8/10);
  - Standard (3/5/7/9/11);
  - Slow (3/6/9/11/13);
  - Stay low (4/8/11/14/16).
- **The stopping rule:** below 12 health, all but the two rushes stop tiering up and spend everything.

Average placing (1 is first, 8 is last; 4.5 is average):

| Prices | Hyper-rush | Burst | Fast | Standard | Slow | Stay low | Tier 6 per lobby |
|---|---|---|---|---|---|---|---|
| Now | 7.8 | 6.3 | 3.3 | 3.1 | 3.9 | 4.5 | 3.7 |
| A | 7.7 | 6.1 | 4.0 | 3.8 | 3.6 | 3.5 | 1.9 |
| A, +2 gold from turn 4 | 7.8 | 6.4 | 3.6 | 3.6 | 3.6 | 3.7 | 2.1 |
| A, +4 gold from turn 4 | 7.9 | 6.4 | 3.3 | 3.5 | 3.7 | 4.0 | 2.6 |
| B | 7.8 | 5.7 | 4.5 | 3.9 | 3.5 | 3.1 | 1.2 |
| C | 7.9 | 5.3 | 5.3 | 3.7 | 3.4 | 2.9 | 0.7 |

- **Rushing loses at every price, as the owner said.**
- **Prices decide who wins.** Tempo plans dominate at today's prices, staying low wins under B and C, and A sits in between.
- **The power gap between tiers flips it.** At 1.35× apart staying low is clearly best; at 1.7× Fast is.

**The flaw** (found in section 8): these bots are made to tier up on schedule. That made A look playable.

## 8. Lobby sim v2: adaptive, evolved players

The owner's target:

> …most players are making it to tier 5, right? You know, tier 5 is like you can expect to get there, but like, you know, it's going to be risky, and maybe it's more safe to stay on tier 4 and just try and, you know, play for placement and just lose, but not lose horribly. Or you could make a riskier play and go for like tier 5 and potentially get much more powerful, but it's riskier kind of thing. And tier 6, like the kind of like the top 3, the top 4 getting there in the end game kind of thing. And if we need to change the damage numbers or the economy numbers or the tier-up numbers. The tier-up numbers are the main focus, but if one of those things is really wrong… have it flag, like, which of the things would be best to move.

The work was given to a Fable advisor, which handed the coding and the runs to cheaper models. The sim is `lobby-v2/lobby2.js`.

**The players.** Each bot has a set of genes:
- **greedEarly and greedLate:** the largest share of its gold it will spend on a tier-up, early and late;
- **L:** a danger threshold, as a number of losses' worth of health; below it, the bot stops tiering up and spends everything;
- **relMin:** it tiers up only when its board is at least this share of the median of opponents' last boards;
- **save:** how much of next turn's tier-up shortfall it saves;
- **rollCap:** how many refreshes it allows itself;
- **econW:** how much it values economy units;
- **cap:** the highest tier it will go to: 4, 5 or 6.

**How they're tuned.** For each rule set, a population of 24 bots plays 12 generations of 500 lobbies. The best 12 are kept and mutated each generation. The survivors are then scored over 4,000 lobbies.
- **"Free" evolution** lets the cap evolve too.
- **"Strata" evolution** evolves separate groups capped at 4, 5 and 6. This measures how risky stopping at each tier is.
- **The rush check** puts one fixed rusher into lobbies of evolved bots.

**Economy units** are 14% of shop offers. They have half power and pay 0–3 gold a turn by tier (`econShare`, `econPow`, `econGold`).

**Round 1** (35 configs, one seed each; [results/lobby-v2-round1.md](results/lobby-v2-round1.md)). Given the choice, players under A, B and C mostly won't pay. They wait for the discount instead.

| Prices | Reach T4 | Reach T5 | Reach T6 | Tier 6 per lobby |
|---|---|---|---|---|
| Now 8/12/16/19/21 | 99.6% | 84% | 38% | 3.1 |
| A | 68% | 12% | 0% | 0 |
| B | 60% | 5% | 0% | 0 |
| C | 40% | 1% | 0% | 0 |

**Noise is large:** one seed moved "reach T4" under A by 25 points (seeds 7, 11 and 23 are in [results/](results/)).

**Round 2** (15 configs × 3 seeds; [results/lobby-v2-round2.md](results/lobby-v2-round2.md)). These are means over the seeds.

| Prices | Reach T5 | Reach T6 | Tier 6 per lobby | Usual tier-6 turn | Reach T6: top four / bottom four |
|---|---|---|---|---|---|
| Now 8/12/16/19/21 | 85% | 33% | 2.6 | 12 | 57% / 9% |
| **8/12/16/19/26** | **88%** | **29%** | **2.3** | **14** | **53% / 4%** |
| 8/12/16/19/31 | 81% | 17% | 1.3 | 15 | 32% / 1% |
| 8/12/17/22/27 | 53% | 11% | 0.9 | 14 | 21% / 1% |
| 8/13/19/25/31 | 40% | 3% | 0.2 | 15 | 5% / 0% |
| A 8/14/22/30/38 | 17% | 0.2% | 0 | 18 | 0% / 0% |

- **8/12/16/19/26 met the target best.** Nearly 9 in 10 players reach tier 5, around turn 7–8. Tier 6 comes late, about 2 a lobby, almost all of them in the top four.
- **Tiers 4 and 5 are sensitive.** Adding just 1 to tier 4's price and 3 to tier 5's (8/12/17/22/27) cuts tier 5 from 88% to 53%.
- **Risk, a weak signal.** Bots capped at tier 4 placed 4.7–4.9 with a spread of ±1.95. Bots capped at 5 placed 4.3–4.4 with ±2.4. The averages are close; the spread is the only consistent difference.

**The decision** (owner, 12 Nov):

> Option A, 8, 12, 16, 19, 26.

*["Option A" here is the first of the two choices offered, 8/12/16/19/26. It is not price set A, 8/14/22/30/38.]*

> …I'm happy to have those go into the rulebook as is now.

## 9. What is still open

- **The shop odds.** The TFT-like table is a working assumption. The owner wanted to revisit it after the economy:

  > recontextualize the shop odds stuff again with me after we go through this economy stuff, and then I can change the economy stuff again if the shop odds stuff doesn't work out.

  To revisit: TFT-like against Battlegrounds against steep; how many units each tier has in a lobby; hit rates for specific units; and whether 5 units plus 2 spells fits the shop UI.
- **The power gap between tiers.** This decides whether tiering up is worth paying for at all. In v2, setting tiers 1.7× apart instead of 1.5× lifts tier 5 from 53% to 83% (at 8/12/17/22/27); 1.35× drops it to 18%. **Prices can't be final until real units set this gap.**
- **Economy units.** Strong ones (`econStrong`) lift tier 5 from 53% to 84% at 8/12/17/22/27. If they turn out strong, 8/12/16/19/31 is the safer price set.
- **Spells.** They add power without taking a board slot, which may let players skip tier-ups. Halving them under A changed little (reach tier 5 went from 17% to 21%).
- **A proposed default written into the rulebook, not yet confirmed by the owner:** the discount stays at 5 a turn after the fifth turn (4.6.6).
- **Shop size is settled.** Asked whether 5 units and 2 spells ends the 3–7 card experiments of 8 Nov (N11 §5.2), the owner said on 13 Nov: "Yes, it's settled". The layout of 7 cards at once still needs checking.

### Damage is the linked lever

- **Games run long.** Games ran about 16 fights in every sim, against the damage system's aim of 13–14 for the winner (rulebook 10.1.3).
- **Less health hurts tiering.** Cutting starting health to 34 removes only about 1 fight, and players can then afford far fewer tier-ups: at the old prices, tier 5 drops from 85% to 40%. A big-loss extra of 5 had a similar, smaller effect.
- **What follows:** shortening games will likely need cheaper tiers alongside, or a damage ramp late in the game rather than less health. Any change to damage should be rerun through `lobby-v2`.

## 10. Lessons for next time

- **Don't judge prices on gold alone.** Rushing looks strong until damage and scaling are counted.
- **Fixed-plan bots mislead.** They prove prices are affordable, not that players would choose to pay them. Use adaptive bots that can refuse.
- **Run several seeds.** Single-seed results moved by up to 25 points.
- **Settle the unit power gap between tiers early.** It moves results more than any price change tried.
- **For the owner:** tables and a talk-through rather than a tool with many controls.
