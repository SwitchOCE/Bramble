# Card power measures: definitions

Fixed on 25 Nov 2026, before any of this session's match data was read for card results. A change after that date is listed at the bottom with its reason.

Already seen when these were written: the blue team's fight table of 18 Nov (a fresh copy of each card added to recorded boards), in which Old Brock ranks first, Sword-heir eighth and Brock Cub 93rd of 95 at rounds 7 to 9; and the league's 22 Nov final-board shares (Sword-heir 96%, Brock Cub 88%, Old Brock 51% of the Badger bot's boards).

## The ladder: cheap first, costly only where pointed

The owner, 25 Nov: "there should be some sort of escalation ladder ... if we ran [a 2,000-game test] for every card always, it would be extremely, extremely prohibitive in terms of development speed."

| Step | What | Kind | Cost, measured 25 Nov | Run on |
|---|---|---|---|---|
| 1 | Pick rate, bought against passed, stat growth | Reading games already played | Under a minute for every card | Every card, after any match with records |
| 2 | Abilities off, keyword on and off, Overrun swings, stat worth of the text | Experiment on recorded fights | About 5 minutes for every card | Every card, after any match with records |
| 3 | Left out of the shop | Experiment over whole games | About 10 minutes a card | Only cards marked worth a look in steps 1 and 2, cards the owner names, and cards that are new or just changed |
| 4 | A read of the card, then a line of explanation or a proposal to the owner | Judgement | Minutes | Cards that step 3 puts over the line, or that stay unexplained |

Steps 1 and 2 need one match with records kept (2,000 games, 10 to 20 minutes), which a balance pass plays anyway. Step 3 is the only costly one, and it is spent only where a cheaper step points.

## Worth a look (every measure)

The owner, 25 Nov: "there's going to be a statistically significant threshold where it's worth looking into for every measure we develop ... we might get some false positives, but we should figure out when we make a measure what exactly a threshold is where that single measure would be worth a look".

- **The rule:** a card is worth a look on a measure when it sits three or more spreads from the middle card of the same table (same stage, same bot), and its own interval is clear of the middle. The spread is 1.4826 times the median distance from the middle, which is about one standard deviation and is not pulled by the outliers themselves. One measure is enough.
- **A floor beside the rule**, so the process still works when the game is well balanced (owner, 25 Nov: "it would be nice if our process would work when the game's in a better balanced state as well"). In a tight table three spreads can be a tiny amount, so a card must also clear a fixed amount: its text turns at least 5 fights in 100; it gains at least three permanent stats a turn; it reads at least 0.3 places from the typical card on bought against passed. When nothing clears both, nothing is marked, and that is the expected result for a balanced game.
- **No step assumes which bot buys what.** Whether a bot's games are played for a card in step 3 is decided from how often that bot bought it in the baseline match, not from a list.
- **Pick rate** has no useful spread (most cards are almost never bought), so its line is fixed: bought on nine offers in ten or more by any bot.
- **What a look is:** the left-out-of-the-shop test for that card (about ten minutes), and a read of the card by a person or a fresh agent. The card is then either explained in a line or brought to the owner. A look is cheap, so false alarms are accepted: in a table of 60 cards about one false alarm is expected every few tables.
- **"Over the line"** is kept for the whole-game test. Worth a look says where to look; it does not say a card is too strong.
- Every new measure states its worth-a-look line when it is defined.

Stages of the game, used everywhere: rounds 1–4, 5–8, 9–12, 13 on. Cards are compared inside one stage, never across stages.

## Bought against passed

**A hint, not a measure of power** (found 25 Nov, on the first match). The typical card reads 0.12 to 0.20 places worse when bought, whatever is controlled for (a full board, board strength, Health left, how many units were bought that turn): a bot that is buying is mostly a bot that needs to. The owner, 25 Nov: it "would only be a particularly good measure of strength if the bots were perfect players ... we can still find hints in the data." So each card's number is read against the typical card's number in the same table, and the table shows that typical value. Worth a look: the rule at the top of this file, in either direction.

- **Data:** the live seat's `shops.jsonl.gz` and `games.jsonl` of a ghost match.
- **One observation:** one turn of the live seat in which the card was in at least one shop view with `buyable` true.
- **Bought:** the card is in the `bought` list of any shop view that turn. Otherwise passed.
- **Group:** the bot, the round, and whether the card's tribe was the seat's main tribe when the turn began (the tribe with the most units on the board at the end of the round before, three or more; a card with no tribe is always "off tribe").
- **Number:** mean final place when bought minus mean final place when passed, taken inside each group that has at least five of each, then averaged over groups with weight n_bought × n_passed / (n_bought + n_passed). Negative means buying goes with better finishes.
- **Interval:** 95%, by resampling whole games 1,000 times.
- **Too few:** under 100 bought or under 100 passed turns in all.
- **Cannot see:** cause. A bot buys a card when it suits the board, so the number mixes the card's power with the boards that wanted it. A card a bot nearly always buys has few passed turns. Each row of the report shows both counts.

## Pick rate

Bought observations divided by all observations, as defined above, per bot and pooled. A bot's pick rate is read only when it saw the card on at least 100 offers; under that the report shows the count and no mark.

## Text off (how much of a unit's fight power is in its own text)

The owner, 25 Nov: "It doesn't tell you whether it's overpowered, but it does tell you how much of its power comes from its abilities ... this test will be specifically good at measuring one thing, and as long as it's used for that purpose and not overused or misunderstood, I'm okay with it existing." So this number is never called card power, in the report or anywhere else. It is the in-fight worth of the text.

- **Data:** the `fight_boards` of every fight in the match records, live seat and ghosts.
- **One observation:** one unit standing on one side at the start of one recorded fight.
- **The change:** that unit keeps its stats, its slot and anything other cards gave it. Its own card's effects and printed keywords are switched off for the fight.
- **Fights:** the board as recorded and the changed board are each fought on the same two seeds (the recorded one and one derived from it). Score for the unit's side: win 1, draw ½, loss 0.
- **Number:** mean score as recorded minus mean score with the text off. Also the change in damage dealt, and the share of recorded results that change.
- **Sample:** at most 500 observations per card per stage, picked by a hash of game, round, side and slot. Under 200, "too few". The owner's budget (25 Nov): about 20 seconds of machine time a card, and "two or three percent margin of error" is enough. The first run measures the spread; the cap is then set to the smallest number that gives about ±3 points, and written here.
- **Interval:** 95%, grouped by game.
- **Worth a look:** the rule at the top of this file, inside each stage across all tiers.
- **Cannot see:** anything outside the fight (gold, shop effects, growth over turns, what a Recruit effect already gave other units). Boards are the ones bots built, and each was built around the card. A card with no fight text reads about zero.

## Stat worth of the text

The owner's idea, 25 Nov: "if I take away all of its abilities and keywords ... and replace it with a plain unit of stats, how much stats would I have to give that unit for the fight to have the same ... expected value ... it would give you a more precise measure of how powerful the [card's in-fight] effects are."

- **The change:** as text off, and the unit's own Attack and Health as recorded are both multiplied by the same number, so it keeps its shape. Rungs: ×1 (plain text off), ×1.5, ×2, ×3, ×4, ×6, ×8.
- **Number:** per card per stage, the multiplier at which the mean score over the card's observations equals the mean score as recorded, read between the two nearest rungs. Reported as the multiplier and as the Attack and Health it adds to the card's average recorded stats at that stage.
- **Solved over the sample, not per fight:** one fight is a win, a draw or a loss, so only the average over many fights can be matched. Draw rates are not matched, only the average score.
- **Edges:** ×1 when the plain unit already does as well. "More than ×8" when no rung reaches the recorded score; that happens for a unit whose text helps other units, or that stands where plain stats do little.
- **Sample, seeds, interval, cannot see:** as text off. The interval comes from resampling games and solving again.

## Keyword off

- **The change:** one keyword's mechanic does nothing for one side of the fight, on every unit that has it, printed or given.
- **Run for:** Overrun, with Cleave and Fury for comparison. Observations are sides that hold at least one unit with the keyword.
- **Fights, score, interval:** as text off, per keyword per stage.
- **Sample:** at most 3,000 observations per keyword per stage, so each Health third can reach the 200 it needs. Three keywords, so this stays cheap.
- **Split:** by the enemy board's median unit Health at the start of the fight, in thirds, with the cut points taken from all fights of that stage.
- **Also counted, for Overrun:** for each attack by a unit with Overrun, how many enemy units it kills, the carried damage included: the share of attacks that kill two or more, three or more, and the whole enemy board.

## Stat growth (permanent stats gained per turn held)

The owner's idea, 25 Nov: "stats generated per turn compared to the source of the stat gain compared to the average unit of that tier ... [Brock Cub is] growing a lot per turn ... it's getting consistently bigger every turn ... It's a tier one unit that scales a bit too well."

- **Data:** every board in a match's records (`fight_boards`), all eight seats. Each unit carries its uid and its permanent gains.
- **One observation:** one unit seen on the same player's board on two turns in a row, with the same uid and not golden. The number is what it gained in permanent Attack and Health in between.
- **Number:** mean permanent stats gained per turn held, per card per stage, with a 95% interval grouped by game. Also Attack and Health apart, the share of turns on which it grew, and the permanent stats it holds on average.
- **Above its board-mates:** the gain minus the average gain of the other units on the same board that turn. A buff that hits the whole board is taken off; what is left is growth that follows the card.
- **Too few:** under 200 observations.
- **Worth a look:** the rule at the top of this file, on "above its board-mates", inside each stage. And a second line, the owner's framing: raw growth three or more spreads above the middle card of the same tier at that stage (tiers with five or more cards measured).
- **Cannot see:** where a gain came from. The record keeps one total of permanent gains per unit, so a gain another card gave only to this unit counts as its own. In-fight stats (this fight only) and stats lent or given by auras are not in it. Golden units are left out, because they double their numbers.
- **Seen before this was defined:** one golden Brock Cub at round 9 holding +68/+83.

## The card report (one row per card)

`tools/league/card_report.sh <match dir>` runs steps 1 and 2 on one played match and writes `card-report/cards.csv`: every measure side by side, the marks, and two columns of context.

- **Boards holding the card, by stage:** of the live seat's boards at the end of each round in the stage, the share with at least one copy, per bot. It shows when a bot keeps a card, which a pick rate cannot (red-c14 holds Gleaner on 87% of its boards from round 9, when the card's text has stopped paying).
- **In the shop:** how the bots that could use the card treat it, for every card, whether or not it has fight data (the fight data often comes from opponents' boards). A bot plays a tribe when it ends on it in one game in twenty or more; a card with no tribe counts every bot.
  - *tribe not played*: no bot plays its tribe.
  - *seldom offered*: the bots that play its tribe saw it on under 100 offers each.
  - *refused*: a bot that plays its tribe saw it enough, and every bot that saw it enough bought it on under one offer in a hundred. This is the only one of the four that is a sign about the card, and the report lists these cards.
  - *bought*: otherwise.
- **Why a card has no fight data:** a card has fight data when it has enough observations for text off in at least one stage. Otherwise the reason is its shop reading: tribe not played, seldom offered, offered and refused, or bought but held too briefly.
- **Keywords:** the report prints each keyword's value by stage, on all boards and against low- and high-Health boards. Worth a look: it turns at least 5 fights in 100 at a stage, the same floor as a card's text. With three keywords there is no table to take a spread from, so the line is fixed.
- A match without records gets the shop readings only, and the report says so. So the report is run before a match's records are deleted.

## Left out of the shop (what a card is worth over a whole game)

The owner called replacing a unit with a made-up plain unit "pretty unrealistic" (25 Nov), and that swap is dropped. This test takes its place.

- **Data:** two ghost matches with the same bots, seeds, secret and field runs. In the second, the card is never offered to the live seat: it is taken out of the game's unit draw list, for the shop and for Discover. Everything else is the same, so the shop shows other cards in its place and the bot builds what it would.
- **One observation:** one game index, played with the card and without it.
- **Number:** the live seat's final place without the card minus its place with it, averaged, per bot. Positive means the bot finishes worse without the card.
- **Interval:** 95%, on the paired differences, grouped by seed.
- **Games:** 500 a bot for each card, to be raised only if the first runs show that cannot tell half a place. The match with every card present is played once and serves every card.
- **Which cards:** a whole game cannot be made cheap (about ten minutes a card), so this test is run on a short list, not on every card: the cards the owner named, and any card the cheaper measures point at (text fights above its tier, better when bought, or bought nearly every time it is offered).
- **Too few:** the card was bought in under 100 of the bot's games with it present. Then the bot does not use the card and the number says little.
- **Flag:** over the line when the bot finishes half a place or more worse without it, with the interval clear of zero. A first guess; the first report shows where it falls.
- **Cannot see:** what a bot that had re-learned without the card would do. A bot tuned around a card loses more than the card's own worth. The number is the card's worth to that bot. Measured 25 Nov: both bots finish better with every Badger and Locust unit left out (red 4.65, blue 5.57) than with only Sword-heir left out (4.97, 6.24), so for a card a bot is built around the number is an upper bound.

## Checks on the measures

- Every recorded fight is first replayed with nothing changed. A fight that does not replay to its recorded result is left out of every fight measure, and the report gives the count per card. (First match, 25 Nov: 37 of 101,061 fights did not replay; all 37 have Hazel Coppicer and Blackthorn Sapling on a board, so the fight record misses something those two cards do together.)
- Switching off the text of a card that has none must change nothing.
- A card with its Attack raised a lot in a test copy of the card data must come out over the line on left out of the shop.
- Leaving out a card the bot never buys must read about zero.
- The match split in two halves by game number must rank cards alike; a flag in one half only is reported as noise.

## Changes

- 25 Nov, before any card result was read: the plain-unit swap is dropped and "left out of the shop" added, and text off is a pointer and no longer a flag, both on the owner's words quoted above.
- 25 Nov, before any card result was read: stat worth of the text added, on the owner's idea quoted in its section.
- 25 Nov, before any card result was read: smaller samples (500 observations and two seeds a fight test; 500 games a bot and a short list for left out of the shop), on the owner's budget quoted under text off.
- 25 Nov, before any card result was read: keyword off samples 3,000 per keyword per stage, because 500 leaves each Health third under the 200 a number needs.
- 25 Nov, AFTER the first fight tables were read: the text-off pointer also needs a card to be above the top quarter of its own tier. Reason: in rounds 1–4 the median tier 1 text (+0.07) is worth more than the median tier 3 text (+0.05), so a tier 1 card below its own tier's median (Brock Cub) was being pointed at.
- 25 Nov, AFTER the first table was read: bought against passed is a hint read against the typical card, and raises no flag alone. Reason and the owner's words are at the top of its section.
- 25 Nov, AFTER the first tables were read: one worth-a-look rule for every measure (three spreads from the middle), on the owner's words quoted in its section. It replaces the text-off pointer (median two tiers up), which missed Sword-heir in rounds 1 to 8 because no tier 5 card was on a board that early.
- 25 Nov: stat growth added, on the owner's idea quoted in its section, before its table was read.
- 25 Nov, AFTER the growth table was read: a second worth-a-look line for stat growth, against cards of the same tier. Reason: "above its board-mates" cannot mark a card on a board where everything grows (Brock Cub on a Badger board), and the owner asked for the comparison with "the average unit of that tier".
- 25 Nov: the ladder written down, on the owner's words quoted in its section. It states what definitions.md already did (left out of the shop on a short list only).
- 25 Nov: a fixed floor beside the worth-a-look rule, and no step may assume which bot buys a card, on the owner's words quoted in the rule's section.
- 25 Nov: the owner answered the two review questions "Yes to both": the real-game checks on left out of the shop run before the full report, and the unused damage-taken fields are dropped from the refight output.
- 25 Nov: the card report's two context columns added (boards holding the card by stage; why a card has no fight data), after the Gleaner result showed a bot holding a card long after its text stopped paying, and the owner's remark that a bot ignoring a card is itself a finding.
- 25 Nov, AFTER the tribes-missing match was read: left out of the shop is stated as an upper bound for a card a bot is built around. Reason: the comparison quoted in its section.
- 25 Nov, AFTER the report was read, on a fresh reviewer's questions: the pick rate's 100-offer minimum is written into its definition (the code already had it); "refused" is reported for every card, not only for cards without fight data (29 refused cards on `r1` had fight data from opponents' boards and showed nothing); "seldom offered" now means seldom offered to the bots that play the tribe (tier 6 Locust cards had read "tribe not played" because only the Badger bot saw them 100 times); keyword off gets a fixed worth-a-look line.
