# Red team notes (round 1)

For the referee only until the league ends.

## How the bot plays

A rule-driven engine with a learned card table and simulated fights for positioning. Each call it picks one action, in this order:

1. **Discover:** the option with the highest value.
2. **Play:** the best unit from the hand into an empty slot in its preferred row. Spells go on the best unit. The Triple Reward waits until after a level-up when one is due.
3. **Level:** when the tier is below a target tier for the round, or the upgrade costs 3 gold or less. Not if it would leave too little to buy a triple's third copy that is in the shop. The target curve is slow: tier 2 at round 5, 3 at 8, 4 at 11, 5 at 13, 6 at 15, and earlier whenever the waiting discount brings the upgrade down to 3 gold. Self-play found it by hill-climbing from the first curve (tier 2 at round 2, then one tier every two rounds). A faster curve lost 0.2. The next slower ones won 1.62, then another 1.0. Slower still lost 0.13, and moving the top tier later made no difference.
4. **Buy:** the best-value shop unit when there is room, or when it beats the weakest board unit by a margin plus the gold lost on the sale. A second copy of a held unit gets a pair bonus (8 value points; raising it from 4 gained 0.28), and a third copy (a triple) is always bought. Sharpen gets bought when there is a board.
5. **Sell:** the weakest board unit when the hand holds something better. Never a unit bought this turn. Hoppers are cycled out of a clogged hand.
6. **Abilities:** the Lance Corporal's Order, the Grenadier's Guard post (once, on the front unit with the most health), and Bury (on the shop card it values least).
7. **Tactics** (`src/tactics.rs`): feed the Gorger and the Granary Glutton by selling, sell non-Briars for the Compost when 3 or more Briars are on the board, and stock the hand under the Colonel.
8. **Cycle** for the Compost or the Glutton: when a Compost entry is worth 2 or more stats to the board (Grow, Sweetbriar, Elder Mother, Briar King), buy, play and sell cheap units.
9. **Freeze** a shop holding a triple piece it can't afford. Otherwise **refresh** while gold allows, up to 12 times.
10. **Position**, at the end of the turn: a heuristic layout first (Guards in front, units whose effects work from behind in the back), then a hill-climb of swaps scored by Sim fights against the latest boards seen of the next opponent and two others, within a CPU budget per round. The layout rules hold: Guards stay in front and back-row units stay behind while there is room.

**Card value** = the unit's stats (less any slot buff, which stays with the slot) + its effect's worth from `data/cards.tsv`, doubled if golden. On top come growth × turns left × 0.15, a synergy term (its tribe count × the card's tribe dependence), a main-tribe bonus, and a late-game discount for cards that don't keep. There is no hard tribe commitment: the main tribe is whichever has the most units on board and in hand, and it only adds a bonus.

**The card table** started as an Opus judgment table from the card text. It was then corrected four times by regression. The bot played 2,000 self-play games with a random per-card bias each game; placement was regressed on which cards were on board at rounds 4, 7 and 10, centred within each tier and round; and the coefficients were moved into `power`. The first correction gained 0.45 places and the second 0.23. After the curve change, a third fit on games with the new curve gained 0.62. A fourth fit (2,000 games on curve C) gained another 0.32. The largest moves in it were Orchard Stripper +4.3, Needle Pikeman +3.8 and Hawthorn Warden +2.8, and Old Stump −2.6.

## Practice results

Red minus blue in average placement (lower is better for red): s0 +2.45, s1 +2.80, s2 +1.98. s2 had the slow curve and the third table fit. `red-m1` adds the fourth table fit and pair bonus 8, which together beat the s2 bot by 0.25 places in self-play (4.37 against 4.63; separately they had tested at 0.32 and 0.28). Then growth was weighted less. Cutting the weight from 0.5 to 0.3 (value = growth × turns left × weight) won by 0.86 in self-play (4.07 against 4.93), and 0.8 had lost by 0.54. Against 0.3, a weight of 0.15 won by 0.60 and 0 by 0.49, so the hand-in uses 0.15. The bot was paying too much for units that grow later. This was the last change, made at 01:27 and tested only in self-play. Self-play gains carried over only partly: from s1 to s2 they came to roughly 3 places against s1, but only 0.8 against blue.

## Cards valued most and least

The table's `power` is an effect's worth on top of the unit's stats, so these are the cards it pays most for beyond their bodies (after three regression corrections):

**Most valued**
- **Elder Mother (Briar, 43), Briar King (33), The Old Hedge (29), Mother Midden (29 + growth):** the Compost engine. Start-of-fight copies and per-Compost growth scale with every sale for the rest of the game, so late Briar boards outgrow everything else.
- **Regimental Sergeant-Major (Pigeon, 40 + large growth), Field Marshal (30), The Colonel (30), Lieutenant (27):** slot buffs stay with the slot and stack each turn; the Colonel's Reserve hand adds up to 7 bodies.
- **Orchard Stripper (Locust, 41):** dies twice, 5 damage to every enemy each time. The regression raised it the most (+4.3 in the last fit).
- **Tourney Champion (37), The Oakfeller (33), Old Brock (30):** the Badger carries. The Champion's free start-of-fight hit removes the enemy's best attacker.
- **Needle Pikeman (Mouse, 30 + growth), Lone Hawthorn (Briar, 31):** a back-row growth engine, and a 6/22 Guard with Thorns 8.

**Least valued**
- **Hedge Knight (−1), Brock Cub (0), Horde Runner (0), Nettle Sprout (2), Relic Seeker (2):** small bodies whose effects rarely fire. Brock Cub only grows when outnumbered; Horde Runner's free Hoppers clog the hand.
- **Old Stump, Grudge Keeper, Territorial, Dormouse Cook, Colour Sergeant:** the regression cut these most (−2.3 to −2.6). The Dormouse Cook needs seven Mice on board, which almost never happens.
- Spells other than Sharpen: the bot buys only Sharpen (1 gold, +2/+2). Seek and Forage cost 3 and 5 gold for a Discover, and it spends that gold on shop units instead. This wasn't tested.

## Where the effort went

Most of the work went into tribe-neutral parts: the card table, the tier curve, positioning, and the regression loop. The bot has no fixed tribe; it leans toward whichever tribe it holds most of. By main tribe at the end (red against the `red-s1` snapshot, 200 games), placements were Mouse 2.37, Briar 2.49, Locust 2.49, Badger 3.00 and Pigeon 3.21.

- **Briar:** the most code. `tactics.rs` sells non-Briars into the Compost when 3 or more Briars are on board, and `cycle()` buys, plays and sells cheap units when a Compost entry is worth 2 or more stats (Grow, Sweetbriar, Elder Mother, Briar King). Its high-tier engine units carry the late game.
- **Locust:** feeding the Gorger and the Granary Glutton (selling Locusts and Hoppers into them) and moving Hoppers out of a clogged hand. Locust is the main tribe most often after Pigeon.
- **Pigeon:** slot buffs are counted without the slot's buff, so a unit isn't overvalued for where it stands. Lance Corporal's Order and the Grenadier's Guard post are used every turn. The Colonel stocks the hand.
- **Badger:** no special code beyond the table and positioning (Guards in front, Old Brock kept behind).
- **Mouse:** no special code. The table rewards Pikeman and Parish Standard-Bearer, and the regression cut the cards that need a full Mouse board.

## Bugs and exploits found

- Possible game bug (not port): the Twice-shed Veteran's script never checks that the returning unit is "another" unit, as its text says. Not checked in Rust; not exploited on purpose.

## Incidents

- **21:20–22:00, 18 Nov: a sub-agent read the referee's s0 practice logs.** The Opus agent briefed to "find broken strategies" read `/home/alex/league/matches/s0/` (both teams' seats) without being asked, and reported blue's method. The brief didn't forbid that folder, which was my mistake. I reported it to the referee straight away, adopted nothing from it, and `red-s1` was tagged before the report arrived. Since then every brief forbids `/home/alex/league/matches` and any referee folder. **Referee's ruling:** no penalty, and `red-s1` stands. Red must not adopt anything the summary described about blue (tier schedule, triples and pairs, spell buying, tribe choices, late-game gold) or build counters to it this round. Nothing under `/home/alex/league/` but our own clone may be read. The referee removed `out/broken/`. Later the owner loosened this: anything we were already on the way to finding ourselves is fair. What I used under that: slower tier curves (a slower-curve test had been queued at 21:09, before the report, after the faster curve tested worse) and the spell buying that v1 already had. I copied no schedule from the summary; the curves tested are the ones queued before it. Pair and triple handling: the pair and triple bonuses have been parameters since v1. Near the end I swept them the same way as every other parameter (pair 4 to 8 won, triple 12 to 24 lost). Nothing in that came from the summary.

## Models used and what we learned

- **gpt-6.2-sol, high** — task 1: a Python log analyser (`tools/analyze_cards.py`) from a precise spec. Done in about 10 minutes, correct on the first try. It did the two hand spot-checks it was asked for and reported them briefly. Good at following a spec with a clear finish line.
- **gpt-6.2-sol, high** — task 2: `src/tactics.rs` (feeding Locust eaters, Compost sells, Colonel hand stocking) as one new file with a fixed signature, wired in by me. It checked each mechanic's GDScript and proved the build in a scratch copy, leaving lib.rs untouched as asked. Task 3: `src/lookahead.rs` (a Sim buy evaluator) to a given signature; it also measured the fight cost. Brief that worked: one file, an exact signature, crate rules spelled out, "prove it compiles in a scratch copy", and a word limit on the report.
- **claude-opus-5-5, high** — task 1: a judgment-heavy card value table (`data/cards.tsv`) from the card text and mechanics. Its table alone gave the largest jump of the night: 1.9 places, v2 against v1.
- **claude-opus-5-5, high** — task 2: a rules review of the bot (read-only). It found six real defects (an Order skipped below 3 gold, the Guard post target read as a uid, a freeze/upgrade loop, swap buys stuck in hand, Lance Corporal moved forward). The fixes plus tactics gave 0.31 places against v2.
- **claude-opus-5-5, high** — task 3: a misplay hunt through 20 logged games. It found hand-clogging Hoppers, same-turn buy-and-sell (116 times), back-row units in front and Guards behind.
- **claude-opus-5-5, high** — task 4: tribe analysis of 2,000 self-play games. Its key finding: Briar's apparent lead comes from labelling boards at the end of the game (long-lived seats drift into the Briar tier-4 to 6 engine), not from Briar early.
- Open-ended analysis went to Opus and specified code to Sol, which matched the owner's guidance. Both were quick; none stopped early, so xhigh wasn't needed.

## Tokens and Codex runs

- **Codex:** 3 runs, all gpt-6.2-sol at high effort (the log analyser, `tactics.rs`, `lookahead.rs`). No Astra.
- **Claude sub-agents:** 6 runs of claude-opus-5-5 at high effort: the card table, the rules review, the misplay hunt, the tribe analysis, the broken-strategies hunt (see Incidents), and one more analysis run. No more than 2 ran at once.
- **Tokens:** not metered from inside the session. A rough estimate: a few million tokens for the lead session (with one context compaction), and a few hundred thousand for each sub-agent and Codex run.
- **Compute:** about 30 A/B and regression runs of 120 to 2,000 games each, on 2 cores throughout.

# Round 2 (19 Nov, 06:00–10:15)

## Incidents (round 2)

- **06:10: blue-m1's report rows in practice output.** `reports.jsonl` from `play.sh` held blue-m1's own value for each card. My first analyst read them and compared them with ours (a script, `value_ranks.py`) before I had decided anything. I asked the referee, and it ruled them off limits. I removed the rows from every practice folder and deleted the script and its output. Two card changes in our first patch rested only on those rows, Prophet of the Dust (6→12) and Armsbearer (15→8), and I reverted both before any test used them. The second analyst was told to ignore the rows and confirmed its script never opened `reports.jsonl`. Every later card change comes from what blue's seats bought, sold and fielded, from fights and from placements.

## Frontier reviewers (owner's allowance, round 2)

- **gpt-6.2-astra, high, about 06:25.** Question: what in our code makes the bot buy too few units and keep weak early units in rounds 7–12, and which three code changes would fix it? Its findings:
  1. Grown stats count fully, so grown cheap units (Husk Sentry, Old Campaigner) look too good to replace.
  2. Buying and selling are judged separately rather than as one swap.
  3. Refreshes leave too little gold to buy what they find.

  It also listed two smaller bugs: in tribe counts, hand units count toward their own synergy, and `cycle()` can refresh away a third copy. Acted on: settings `grown_discount` (1) and `refresh_keep` (3), tested against blue-m1.
- **Fable, about 06:25.** Question: where is the bot losing placement against blue-m1, and what three changes are most likely to gain it? Its findings:
  - Placement is lost in fights in rounds 8–12.
  - Win rate falls with each tier 1–2 unit kept on the board.
  - Gold goes on refreshes and Sharpen instead of units, and levelling costs more than it should.

  It proposed three changes:
  1. Combine the card patch, swap margin −3 and a lean away from Pigeon, with card corrections from red's own fights (`cards_p3.tsv`).
  2. Start the late discount at round 7 (`late_round`).
  3. A slower curve to tier 4.

  Acted on: all three, tested as candidate c1 and its variants.

## Practising against blue-m1 (round 2)

All runs are 200 games (100 seed pairs) on one fixed seed set, our live bot against blue-m1. The figure is red minus blue in average placement, ±0.2 to 0.25 at 95%.

| Run | Change | Red − blue |
|---|---|---|
| base | `red-m1` | +0.48 |
| lean_pig | lean away from Pigeon (−3) | +0.34 |
| p1swap | card patch p1 (11 cards, from the first analyst's buy and fight data) + swap margin −3 | +0.28 |
| **p2swap** | **card table p2 (34 cards, from fight, placement and buy-rate evidence) + swap margin −3** | **−0.41** |
| lean | p2swap + Pigeon lean | −0.14 |
| p4 | p2swap with a second-pass table p4 | −0.28 |
| sell | + sell the weakest unit to afford a better one (Astra) | −0.41 |
| late7 | + late discount from round 7 (Fable) | −0.13 |
| grown | + grown stats count half from round 7 (Astra) | −0.30 |
| rkeep | + keep 3 gold after a refresh from round 5 (Astra) | −0.31 |
| curve | + tier 4 at round 12 (Fable) | −0.45 |
| refresh5 | + at most 5 refreshes a turn | −0.20 |
| g03 | + growth weight 0.3 instead of 0.15 | +0.12 |
| p5 | card table p5 (third pass, pooled over 1,400 games of p2 runs) | −0.20 |
| nosharp | + never buy Sharpen | −0.04 |
| g0 | + growth weight 0 | −0.08 |

On a third seed set: p2swap −0.24, p5 −0.26. Across three seed sets p2 averages −0.25 and p5 −0.28, a tie, so the hand-in keeps p2. It is the table that beat `blue-s3` in practice, and p5 pushes further in the same direction on one opponent's data, which risks fitting blue-m1 too closely.

**`red-m2`** = `red-s3` (card table p2, swap margin −3, the rest as in `red-m1`) plus these notes, the pipeline scripts, and new settings that are all off by default (`tribe_lean`, `offtribe_late`, `discover_round`, `grown_discount`, `refresh_keep`, `late_round` at 10 as before, `sell_to_buy`).

On a second seed set: `red-m1` +0.42, p2swap −0.10, p5 −0.38. Practice match s3 (`red-s3` = p2swap, against blue's current `blue-s3`, 1,000 games): red 4.274, blue 4.726, red ahead by 0.45 ± 0.10.

So the p2 gain over `red-m1` held up (0.52 there against 0.89 on the first set), and p2 and p5 tie across the two sets.

p2 with swap margin −3 became the default. The swap margin lets a full board take a better shop unit with no extra margin. Before, a shop unit had to beat the weakest board unit by 5 points.

## What carries over to changed cards (owner's question, 19 Nov)

**Carries over on its own:**
- The priority list (play, level, buy, swap, sell, abilities, freeze, refresh).
- Valuing a unit by its current stats.
- Tribe synergy, counted from the cards' tribes.
- The level curve and the waiting-discount rule.
- Positioning by simulated fights. It uses the engine's own fight, so it adapts to any numbers.
- Every setting in `Params`, although the best values may move.

**Rebuilt by re-running a script:**
- The `power` and `keep_late` columns of `data/cards.tsv`. They are measured by self-play regression (round 1, four passes) and by practice-game fight models (round 2, three passes). Both pipelines and the recipe are in `tools/pipeline/`, and a pass takes about 2 hours of CPU (self-play) or 10 minutes per 200 practice games.
- The settings, which we tune by A/B against a fixed opponent with `practice_queue.sh`.

**Needs a person or a model when cards change:**
- The starting reading of a new card's text: `row`, `syn`, `pair`, `growth`, and a first `power`. A card missing from the table falls back to its stats plus 2 per tier, and the regression then corrects `power`.
- The card-specific code in `tactics.rs` and `cycle()`: Locust eaters, the Compost payoffs of named Briar cards, the Colonel.
- The two hand checks in the practice script, Brood Mother and Gleaner. Its re-runnable copy leaves them out.
