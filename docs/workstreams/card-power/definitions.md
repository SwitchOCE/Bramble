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

## Text off (fight value of a card's own text)

- **Data:** the `fight_boards` of every fight in the match records, live seat and ghosts.
- **One observation:** one unit standing on one side at the start of one recorded fight.
- **The change:** that unit keeps its stats, its slot and anything other cards gave it. Its own card's effects and printed keywords are switched off for the fight.
- **Fights:** the board as recorded and the changed board are each fought on the same four seeds (the recorded one and three derived from it). Score for the unit's side: win 1, draw ½, loss 0.
- **Number:** mean score as recorded minus mean score with the text off. Also the change in damage dealt, and the share of recorded results that change.
- **Sample:** at most 1,000 observations per card per stage, picked by a hash of game, round, side and slot. Under 200, "too few".
- **Interval:** 95%, grouped by game.
- **Flag:** over the line when the low end of the interval is above the median card two tiers up at that stage (for tiers 5 and 6: above the top quarter of tier 6). On watch when above the median card one tier up. A card under the median card one tier down is listed as weak.
- **Cannot see:** anything outside the fight (gold, shop effects, growth over turns, what a Recruit effect already gave other units). Boards are the ones bots built, and each was built around the card. A card with no fight text reads about zero.

## Keyword off

- **The change:** one keyword's mechanic does nothing for one side of the fight, on every unit that has it, printed or given.
- **Run for:** Overrun, with Cleave and Fury for comparison. Observations are sides that hold at least one unit with the keyword.
- **Fights, score, sample, interval:** as text off, per keyword per stage.
- **Split:** by the enemy board's median unit Health at the start of the fight, in thirds, with the cut points taken from all fights of that stage.
- **Also counted, for Overrun:** for each attack by a unit with Overrun, how many enemy units it kills, the carried damage included: the share of attacks that kill two or more, three or more, and the whole enemy board.

## Swapping the unit itself

Not settled. The first plan replaced the unit with a plain unit of its tier's average stats; the owner called that unrealistic (25 Nov) and the session agrees. The proposal with the owner: drop it, and add a whole-game test in which the card is never offered to the live seat. Its definition is written here before it is run.

## Checks on the measures

- Every recorded fight must replay to its recorded result before any change is applied.
- Switching off the text of a card that has none must change nothing.
- A card with its Attack raised a lot in a test copy of the card data must come out over the line.
- The match split in two halves by game number must rank cards alike; a flag in one half only is reported as noise.

## Changes after 25 Nov

None.
