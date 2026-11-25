# Card power measures: definitions

Fixed on 25 Nov 2026, before any of this session's match data was read for card results. A change after that date is listed at the bottom with its reason.

Already seen when these were written: the blue team's fight table of 18 Nov (a fresh copy of each card added to recorded boards), in which Old Brock ranks first, Sword-heir eighth and Brock Cub 93rd of 95 at rounds 7 to 9; and the league's 22 Nov final-board shares (Sword-heir 96%, Brock Cub 88%, Old Brock 51% of the Badger bot's boards).

Stages of the game, used everywhere: rounds 1–4, 5–8, 9–12, 13 on. Cards are compared inside one stage, never across stages.

## Bought against passed

- **Data:** the live seat's `shops.jsonl.gz` and `games.jsonl` of a ghost match.
- **One observation:** one turn of the live seat in which the card was in at least one shop view with `buyable` true.
- **Bought:** the card is in the `bought` list of any shop view that turn. Otherwise passed.
- **Group:** the bot, the round, and whether the card's tribe was the seat's main tribe when the turn began (the tribe with the most units on the board at the end of the round before, three or more; a card with no tribe is always "off tribe").
- **Number:** mean final place when bought minus mean final place when passed, taken inside each group that has at least five of each, then averaged over groups with weight n_bought × n_passed / (n_bought + n_passed). Negative means buying goes with better finishes.
- **Interval:** 95%, by resampling whole games 1,000 times.
- **Too few:** under 100 bought or under 100 passed turns in all.
- **Flag:** half a place or more better when bought, with the interval clear of zero.
- **Cannot see:** cause. A bot buys a card when it suits the board, so the number mixes the card's power with the boards that wanted it. A card a bot nearly always buys has few passed turns. Each row of the report shows both counts.

## Pick rate

Bought observations divided by all observations, as defined above, per bot and pooled.

## Text off (how much of a unit's fight power is in its own text)

The owner, 25 Nov: "It doesn't tell you whether it's overpowered, but it does tell you how much of its power comes from its abilities ... this test will be specifically good at measuring one thing, and as long as it's used for that purpose and not overused or misunderstood, I'm okay with it existing." So this number is never called card power, in the report or anywhere else. It is the in-fight worth of the text.

- **Data:** the `fight_boards` of every fight in the match records, live seat and ghosts.
- **One observation:** one unit standing on one side at the start of one recorded fight.
- **The change:** that unit keeps its stats, its slot and anything other cards gave it. Its own card's effects and printed keywords are switched off for the fight.
- **Fights:** the board as recorded and the changed board are each fought on the same two seeds (the recorded one and one derived from it). Score for the unit's side: win 1, draw ½, loss 0.
- **Number:** mean score as recorded minus mean score with the text off. Also the change in damage dealt, and the share of recorded results that change.
- **Sample:** at most 500 observations per card per stage, picked by a hash of game, round, side and slot. Under 200, "too few". The owner's budget (25 Nov): about 20 seconds of machine time a card, and "two or three percent margin of error" is enough. The first run measures the spread; the cap is then set to the smallest number that gives about ±3 points, and written here.
- **Interval:** 95%, grouped by game.
- **Pointer, not a verdict:** a card is listed as "text fights above its tier" when the low end of the interval is above the median card two tiers up at that stage (for tiers 5 and 6: above the top quarter of tier 6). The list says where to look; it does not say a card is too strong.
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
- **Fights, score, sample, interval:** as text off, per keyword per stage.
- **Split:** by the enemy board's median unit Health at the start of the fight, in thirds, with the cut points taken from all fights of that stage.
- **Also counted, for Overrun:** for each attack by a unit with Overrun, how many enemy units it kills, the carried damage included: the share of attacks that kill two or more, three or more, and the whole enemy board.

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
- **Cannot see:** what a bot that had re-learned without the card would do. A bot tuned around a card loses more than the card's own worth. The number is the card's worth to that bot.

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
