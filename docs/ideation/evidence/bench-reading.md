# Reading the bench: bot or game?

A person's reading of `bench-latest.md` at commit 1d12de0. A rerun overwrites that report, not this file, so check the numbers still match before leaning on it. Before and after: `balance-1.md`.

## The bars

- **Win spread: 8 of 9 strategies inside 6-25%, none above, 2000 games.** The report says TOO CLOSE because economy's margin (24.6% ±2.0) crosses 25%.
- **Hard among Normal: average place 3.41 ±0.18, bar 3.5.** TOO CLOSE: the margin crosses the bar, and the point estimate passes.
- **Search over shuffled placing: 0.57 ±0.22, bar 0.5.** TOO CLOSE. It fell from 0.91. Bots now keep their units in place, so a shuffled board loses less to rule-placed boards around it, and cards reward position less than the first slice's did. Unmeasured beyond that.
- **Hard among Naive: PASS,** 100% wins.
- **Reviewers see 3+ builds:** waiting on fresh reviewers.

## Each strategy near the edge

- **neutrals_economy, 24.6%, near the top: game and bot.** The owner expects economy to be strong at high level, and the fast climb pays now late bodies are big. It has a low 52% top 4, which is the right shape for a risky line. Watch it, but not over-tuned to one number.
- **fairies_rings, 3.9%, too weak: mostly bot, some game.** It plays with 5.6 final units, as the bot leaves Rings empty for Wisps and doesn't plan which unit stands on each Ring. Reel-Mistress is a hard card for a bot to play. A person may do far better; reviewers should check.
- **neutrals_purse, 6.9%, top 4 30.5%: game and bot.** The bot's saving schedule is hand-set and doesn't react to the shop. Interest stays on cards (DECISIONS), so saving gets no base reward.
- **fairies_help, 7.4%:** depends on the Queen, and the bot's handling of her tithe is a simple rule.

## Do the strategies differ?

All 9 are distinct on the report's overlap test at 2000 games, closest 0.56 (economy and purse, the two money lines). That's a measure of which cards end on boards. It says nothing about how they feel, so reviewers still decide.

## Who's on boards

Belladonna 61% and Queen 60% of the final boards in the spread, with Wisp at 46%. They're high because four of nine strategies are Fairies and they sit in several lists, yet they win about their share (11%, 17% against 11% for an even share). Mast has the best rate: 30% of boards, 30% of those win. Watch it first if Hedgerow pulls ahead.

## Cards that hardly get played

Under 5% of boards: Pipistrelle Echo, Pennywort Snail, Cradle Fetch, Turnip Scarecrow, Lamp Moth, Earwig Mother, Hob-in-the-Hearth, Cricket Busker. The bots have no plan for most of these, so this says little about the cards. A designer should still look at them.

## Limits

Curves, `power` priors and card hints are hand-set, some after seeing bench results, so a strategy's result measures those too. The bots use Jill rarely (8 times in 40 games) and don't plan around Echo or Fetch.
