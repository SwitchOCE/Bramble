# Card power measures: definitions

Fixed on 25 Nov 2026, before any of this session's match data was read for card results. A change after that date is listed at the bottom with its reason.

Already seen when these were written: the blue team's fight table of 18 Nov (a fresh copy of each card added to recorded boards), in which Old Brock ranks first, Sword-heir eighth and Brock Cub 93rd of 95 at rounds 7 to 9; and the league's 22 Nov final-board shares (Sword-heir 96%, Brock Cub 88%, Old Brock 51% of the Badger bot's boards).

## The ladder: cheap first, costly only where pointed

The owner, 25 Nov: "there should be some sort of escalation ladder ... if we ran [a 2,000-game test] for every card always, it would be extremely, extremely prohibitive in terms of development speed."

| Step | What | Kind | Cost, measured 25 Nov | Run on |
|---|---|---|---|---|
| 0 | First-sight read: the owner, or a fresh agent, marks any card that looks too strong or too weak on sight | Judgement | Minutes | Every card, when it is designed or changed |
| 1 | Pick rate, bought against passed, stat growth | Reading games already played | Under a minute for every card | Every card, after any match with records |
| 2 | Abilities off, keyword on and off, Overrun swings, stat worth of the text, fresh copy | Experiment on recorded fights | 8 to 13 minutes for every card, by how busy the machine is (4 without stat worth and fresh copy) | Every card, after any match with records |
| 3 | Left out of the shop; handed a copy, for a card no bot buys; trial rules, for a proposed change | Experiment over whole games | About 10 minutes a card (8 for handed a copy and trial rules, 26 Nov) | Only cards marked worth a look in steps 1 and 2, cards the owner names, cards that are new or just changed, and changes about to be proposed |
| 4 | A read of the card, then a line of explanation or a proposal to the owner | Judgement | Minutes | Cards that step 3 puts over the line, or that stay unexplained |

Steps 1 and 2 need one match with records kept (2,000 games, 10 to 20 minutes), which a balance pass plays anyway. Step 3 is the only costly one, and it is spent only where a cheaper step points.

## Edge cases

Cases the ladder does not handle on its own, each with its route (approved by the owner, 26 Nov, with the [proposals](proposals.md)).

| Case | Sign | Route | Built? |
|---|---|---|---|
| A card no bot buys | "refused" in the report: bought on under 1 offer in 100 by every bot that sees it, with its tribe in play | A fight test that adds a fresh copy to recorded boards; then a whole-game test with the card forced in; then a design read. Unexplained after that: to the owner as "weak or unfound" | The report names the cards and runs the fight test ([fresh copy](#fresh-copy-a-cards-fight-text-on-boards-that-do-not-hold-it)). The whole-game test is [handed a copy](#handed-a-copy-a-cards-worth-when-the-bot-holds-it), run by hand per card |
| A card a bot is built around | Left out of the shop reads far above every other card | Treat the number as an upper bound. Compare with leaving out the card's whole tribe | Yes (`--without` takes a list) |
| A card whose worth is outside fights | Bought a lot, little fight text | Left out of the shop is the only measure; run it | Yes |
| A card that grows over turns | Marked on stat growth | Left out of the shop, alone and with the cards that share its mechanic | Yes |
| A tier the bots rarely reach | "seldom offered" in the report: under 100 offers to every bot that plays the tribe | Say "not tested". Do not read it as weak or fine | The report says it |
| Two stages disagree | A design estimate and a measurement point opposite ways | The measurement on a strong field wins; both are shown to the owner | A rule, no tool |
| A balanced game | Nothing clears a worth-a-look line | Expected. The report says "nothing marked worth a look" and stops | Yes |

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

- **The change:** as text off, and the unit's own Attack and Health as recorded are both multiplied by the same number, so it keeps its shape. "Own" is its printed stats plus what the unit holds itself; what auras and its slot's Renown add in the fight is left as it is. Rungs: ×1 (plain text off), ×1.5, ×2, ×3, ×4, ×6, ×8.
- **Number:** per card per stage, the multiplier at which the mean score over the card's observations equals the mean score as recorded, read between the first rung that reaches it and the rung before. Reported as the multiplier and as the Attack and Health it adds to the card's average recorded stats at that stage.
- **Rounding:** each stat is rounded to the nearest whole number, so on a 1/1 the ×1.5 and ×2 rungs are the same fight. Read a number between ×1 and ×2 on a very small unit as rough.
- **Solved over the sample, not per fight:** one fight is a win, a draw or a loss, so only the average over many fights can be matched. Draw rates are not matched, only the average score.
- **Edges:** ×1 when the plain unit already does as well. "More than ×8" when no rung reaches the recorded score; that happens for a unit whose text helps other units, or that stands where plain stats do little.
- **Sample, seeds, interval, cannot see:** as text off. The interval comes from resampling games and solving again.
- **Worth a look:** none of its own. It is the text-off number in another unit, so the mark stays on text off; a second line on the same fights would mark the same cards twice.
- **Run with:** `league refight --stat-worth` (the card report does), about three times the fights of text off alone.

## Fresh copy (a card's fight text on boards that do not hold it)

The owner, 25 Nov: "a lack of data due to bots ignoring the card, when my estimate is that it's bad, is probably [a] finding [in] of itself ... not getting data on cards because bots completely ignore them is maybe an issue". Text off needs the card on boards; a card the bots refuse is on few or none. This test puts it there. It is the text-off measure pointed at a card no board holds, so it measures the same one thing: how much a fresh copy's own text is worth in a fight. It is never called card power. It is not the dropped plain-unit swap: both fights below hold the same copy in the same slot, so the body, and whatever unit it displaced, are the same in both and cancel out.

- **Data:** the `fight_boards` of every fight in the match records, live seat and ghosts.
- **Boards it fits:** a side whose player's shop tier is at least the card's tier minus one (a triple's reward offers a card one tier up; on `r1`, 13% of board units sit one tier above their player and none two), and which holds three or more units of the card's tribe. A card with no tribe fits any side its tier allows.
- **One observation:** one side of one recorded fight that the card fits.
- **The change:** a fresh copy of the card (base stats, not golden, nothing given) goes in the side's lowest free slot. On a full board it takes the slot of the side's weakest unit (lowest own Attack plus Health; the lower slot on a tie), which leaves the fight. Displacing is the usual case, not the exception: on `r1` a unit is displaced on 82%, 99%, 99% and 100% of boards by stage, because most sides are full from round 3 or 4. The row says which unit, and the table and the printed summary give the share of boards where a unit was displaced.
- **Fights:** the changed board is fought twice on the same two seeds as text off: once with the copy's text on, once with it off (its own card's effects and printed keywords switched off, as text off does it). The recorded board is also fought, as for every fight measure, and a fight that does not replay is left out.
- **Number:** mean score with the copy's text on minus mean score with it off, for the copy's side. Also the change in damage dealt, and the share of results that change.
- **Sample, interval, too few:** as text off: at most 500 observations per card per stage, picked by a hash of card, game, round and side; 95% interval grouped by game; under 200, "too few".
- **Worth a look:** the rule at the top of this file, inside each stage, against the fresh copies of every card at that stage (ten cards or more measured), with the text floor (5 fights in 100). A fresh copy is never read against held copies: a held copy carries the stats it gathered and reads higher (Sword-heir on `r1`, rounds 5–8: +0.154 fresh, +0.273 held).
- **Reading per card**, over its stages: *too few boards* (no stage has 200); *no fight text* (every measured stage's interval includes zero); *fight text worth under 5 in 100* (every stage under the floor, some clear of zero); otherwise *has fight text worth*. The reading describes; it routes nothing. Every refused card goes on to the whole-game step whatever it reads. A refused card that has fight text worth is the closest case to the owner's "I am surprised they're not using" it; one whose fight text does nothing has its worth, if any, outside fights.
- **Cannot see:** as text off, and more: the copy has none of the stats a held copy gathers over turns, nothing an effect that works when the card is bought or played would have done, and no say in how the board was built. The boards are ones the bots built without the card.
- **Run with:** `league refight --fresh-copy all` (the card report does, with stat worth), or `--fresh-copy <id>[,<id>...]` for named cards; a new or changed card that no recorded board holds yet is the same case. A card is read against the fresh copies of the other cards, so the table needs every card: run `all`. Cost on `r1` (2,000 games, 4 threads): 121 seconds for all 104 cards, about one second a card; 31 seconds for the 17 refused cards alone.

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
- **Fresh copy, for refused cards:** the fresh copy's value and board count per stage, its reading, and a mark when a stage is worth a look. The printed summary gives each refused card's line. Other cards' fresh copies are in `fresh_copy.csv`, where they serve as the table the refused cards are read against.
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

## Handed a copy (a card's worth when the bot holds it)

The owner, 26 Nov, told that the bots' fixed card values mean a weak card they do not value is never bought, so whole-game tests say nothing about it: "if there are processes that like bots are not a good test, right, we need to find good tests. You can't just be like, okay, the bots don't value the card." And 25 Nov: "There are real pros and cons to approaches in terms of forcing bots to adopt cards, which could give us worse data because the bots become worse players". So the bot is not changed and is not made to buy anything: the harness hands it the card and, for a few rounds only, does not let it throw the card away.

- **Data:** three ghost matches with the same bots, seeds, secret and field runs: the baseline, with nothing handed over; the card handed over; and a reference card of the same tier that the bots do buy, handed over the same way (same round, same keep). The reference match serves every card of that tier and round.
- **The change:** at the start of the live seat's shop turn in the grant round, before its bot acts, one fresh copy (base stats, not golden) joins its board as a bought card played from the hand does, without the price. On a full board the weakest unit (lowest own Attack plus Health, the lower slot on a tie) leaves the game first, as for the fresh copy. For the keep rounds (the grant round and the ones after it) the bot is not shown the actions that take the copy off its board: selling it, returning it to the hand, swapping a hand card into its slot. Moving it, and merging it into a golden by buying two more, stay allowed. `league ghost-match --grant <card>@<round> --keep <rounds> --no-records`; what it can and cannot hold is in `tools/league/league/README.md`, "Handing a card over".
- **Round:** the round by which most of the bots' games have reached the card's tier in the baseline: tier 3, round 7 (on `r1`, red is at tier 3 in 69% of its games at round 7, blue at round 8); tier 5, round 13 (both bots).
- **Keep:** 3 rounds, so the copy fights three times on the bot's board, and the bot then plays its own way. The game line says how long the copy actually stayed.
- **Reference:** a card of the same tier the bots buy and hold, named with its reason where the result is written. It takes the same free copy and the same displaced unit, so those cancel in the comparison with the reference; they do not cancel against nothing.
- **One observation:** one game index in which the copy was handed over (in both matches, for the comparison with the reference). Before the grant round the matches do not differ, so a game in which the live seat is out before then carries only the bots' noise.
- **Numbers, per bot:** *better than nothing*, the mean place with nothing minus the place with the copy; *better than the reference*, the mean place with the reference minus the place with the card. Positive means the card helps more. 95% interval on the paired differences, grouped by seed line. Also the mean rounds held, the share of games held through the keep, the share in which a unit was displaced, and the share sold after the keep.
- **Control:** a second run of the baseline (the bots' CPU-clock noise), in the same table.
- **Stall check** (set AFTER the first results were read; see "Changes"): the gold left and the cards in hand at the end of the keep rounds, minus the same rounds of the same games with nothing handed over. A bot that cannot sell a card it does not want does not sell something else instead: it buys into its hand until the hand is full (7 cards) and then banks its gold. Held for three rounds on `r1`, Shrew Harrier and Bumblebee left both bots 10 to 15 more gold and 4 more cards in hand each round; Sword-heir and Gate Warden under half a gold. A card whose bots bank 3 gold or more reads *the bot stalled while holding it: says little*: the number is then the bot breaking, not the card.
- **Reading, per bot** (fixed before any result was read, but for the stall check): *stronger than the reference* when the card is at least 0.3 places better than the reference with the interval clear of zero; *weaker than the reference* when at least 0.3 places worse with the interval clear of zero; otherwise *no clear difference from the reference*. *Not held through the keep: says little* when under 80 in 100 games kept it through the keep window. The 0.3 is the floor bought against passed uses. A reading says how the card does in the bots' hands; with the other measures and a design read it goes to the owner.
- **Cannot see:** what a bot that valued the card would build around it; the bot holds it but does not seek its tribe or its partners, and may sell it as soon as the keep ends (the share sold says how often). Anything the card does when it is bought from the shop other than through its Recruit effect. A card with a Recruit effect that needs a target is refused. Late tiers reach only the games still running at the grant round (on `r1`, 61% of red's and 43% of blue's games reach round 13).
- **Run with:** `league ghost-match` as above, then `python3 tools/league/analysis/card_grant.py BASELINE CARD... --reference REF --control RERUN`. Cost on `r1` (2,000 games, 4 threads): about 8 minutes a match.

## Trial rules (trying a proposed card change before proposing it)

A proposed fix has to "actually fix the problems while keeping the game interesting" (owner, 26 Nov). Changing a card's numbers moves the rules hash, and a field is cut at one rules hash, so until now a change could be tried in whole games only after remaking the field (about an hour). This plays the changed card against the existing field.

- **Data:** a ghost match on a scratch copy of the card data with the change, against the baseline's field, with the baseline's bots, seeds and secret: `league ghost-match ... --trial-rules --repo-root <changed card data>`. The changed card data is never committed.
- **What changes where:** the live seat plays the changed card in its shop, on its board and in every fight. A recorded opponent's board is rebuilt through the changed card data: its copies of the card take the new text and keywords and, where the record kept the printed stats (it nearly always does), the new printed stats, plus the gains the record saved. What the recorded players bought and kept was chosen under the old card.
- **Number, per bot:** the live seat's mean place with the change minus its place without it, by game index. Positive means the bot finishes worse with the change. 95% interval grouped by seed line, with the control row beside it. `python3 tools/league/analysis/card_trial.py BASELINE TRIAL --control RERUN`.
- **Reading:** none of its own. A trial is read against the problem it is meant to fix: the card's own measures, run again on the trial (records are kept, and the card report runs on them given the same `--repo-root`), should move towards a typical card of its tier, and the place change should be the size the fix is meant to make.
- **Cannot see:** the field as it would be under the change. Recorded players built their boards with the old card, so a card the field uses a lot changes both sides at once (a weaker card also weakens the recorded boards that hold it), and the live seat's place change understates what the change does to the bot that relies on it. A change worth proposing is then checked once on a field cut under the new rules.
- **Cost:** about 8 minutes a trial (2,000 games, 4 threads), against about an hour to cut a new field first.

## Checks on the measures

- Every recorded fight is first replayed with nothing changed. A fight that does not replay to its recorded result is left out of every fight measure, and the run prints the count. For a ghost match, give the tools the field it was played against (`card_report.sh --field`, `league refight --field`): its recorded seats then fight as recorded, and every fight replays (`r1`, 26 Nov: 105,198 of 105,198; without the field, 4 did not). The cause, found by the Ghost Build Orchestrator: the refight fought recorded seats as live seats, so Hazel Coppicer's permanent buff reached the recruit board, and a Rooted Blackthorn Sapling came back bigger. The engine was right. The first match's 37 of 101,061 (all with those two cards) fit the same cause; that match is deleted and was not run again.
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
- 25 Nov, before any stat-worth number was read: "own" stats spelled out (auras and Renown are not multiplied), and no separate worth-a-look line for stat worth, for the reason in its section.
- 26 Nov: the owner said yes to the proposals and to the open review questions ("I was happy with all of the proposals so proceed"; "I was pretty happy with all your ideas"). So these stand: the pick rate is read only above 100 offers; "refused" is reported for every card; "seldom offered" means seldom offered to the bots that play the tribe; stat worth has no worth-a-look line of its own; the plain refight keeps its `summary.tsv`.
- 26 Nov: step 0 (the first-sight read) added to the ladder, from the approved proposals.
- 26 Nov, AFTER the first fresh-copy numbers on `r1` were read: fresh copy added, the fight test on the approved route for a card no bot buys. Two parts of it were set after reading. The tier rule allows one tier above the player, because held Sword-heirs stand on tier 2 boards in rounds 3 and 4 (a board count, not a fresh-copy result). And a fresh copy is read against the fresh copies of every card, not against the text-off table as first proposed, because fresh copies read lower than held copies (Sword-heir is marked on text off in every stage but would not have been as a fresh copy against that table). Already seen before it was written: the blue team's 18 Nov fight table of fresh copies, noted at the top of this file.
- 26 Nov: refight attaches a ghost match's recorded runs when given `--field`, so recorded seats fight as recorded. Not a change to any measure's definition; the handful of fights that did not replay now do. The tables made before it carry that error: at most 4 fights in 105,198 left out.
- 26 Nov, before any handed-a-copy result was read: handed a copy added, the whole-game test on the approved route for a card no bot buys, on the owner's words quoted in its section. Its round, keep, references and reading lines were set before the matches were read. Already seen: the first six game lines of a 40-game test run (Shrew Harrier at round 7), read only to check the tool worked, and the tier each bot holds by round on `r1` (used to set the rounds).
- 26 Nov, AFTER the first handed-a-copy results were read: the stall check added to handed a copy. Reason: Shrew Harrier and Bumblebee read about 1.7 to 1.9 places worse than the reference, and the games showed why (the bots filled their hand and banked 10 to 15 gold a round while they could not sell the copy). The owner's warning of 25 Nov about forced cards making the bots worse players, measured.
- 26 Nov, before any trial result was read: trial rules added. A ghost match now also refuses card data whose rules hash differs from the build's unless `--trial-rules` is given; before, such a match played silently under the build's name.
