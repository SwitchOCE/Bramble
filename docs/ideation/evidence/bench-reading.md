# Reading the bench: bot or game?

A person's reading of `bench-latest.md` at commit 1d12de0, before the scope review's changes. Later numbers, on smaller runs: `balance-1.md`. A rerun overwrites that report, not this file, so check the numbers still match before leaning on it. Before and after: `balance-1.md`.

## The bars

- **Win spread: 8 of 9 strategies inside 6-25%, none above, 2000 games.** The report says TOO CLOSE because economy's margin (24.6% ±2.0) crosses 25%.
- **Hard among Normal: average place 3.41 ±0.18, bar 3.5.** TOO CLOSE: the margin crosses the bar, and the point estimate passes.
- **Search over shuffled placing: 0.57 ±0.22, bar 0.5.** TOO CLOSE. It fell from 0.91, and the two suspects tested aren't the cause (`balance-1.md`). The cause is unknown.
- **Hard among Naive: PASS,** 100% wins.
- **Reviewers see 3+ builds:** waiting on fresh reviewers.

## Each strategy near the edge

- **neutrals_economy, 24.6%, near the top: game and bot.** It's named Spend Late and it doesn't save: it climbs on a fast curve and spends what it has, so its strength says nothing about saving. The owner expects economy to be strong at high level. It has a low 52% top 4, the shape of a risky line.
- **fairies_rings, 3.9%, too weak: mostly bot, some game.** It ends on 5.6 units, the fewest of any build, and the cause isn't measured. Reel-Mistress looks hard for a bot to play. A person may do far better; reviewers should check.
- **neutrals_purse, 6.9%, top 4 30.5%: untested by hand.** The bot holds gold on a set schedule that doesn't react to the shop, so this doesn't show saving is or isn't a real line. The next reviewers test it. Interest stays on cards (DECISIONS).
- **fairies_help, 7.4%:** depends on the Queen, and the bot's handling of her tithe is a simple rule.

## Do the strategies differ?

All 9 are distinct on the report's overlap test at 2000 games, closest 0.56 (economy and purse, the two money lines). That's a measure of which cards end on boards. It says nothing about how they feel, so reviewers still decide.

## Who's on boards

Of 16000 final boards: Belladonna 49.0%, Queen 40.7%, Wisp 39.5%, Dozey 28.2%. Belladonna and Wisp are spread across several Fairy lists and win at or under an even share (11.1% and 5.7%, against 12.5%); Queen wins 14.9%. Mast is the one to watch: 17.1% of boards at 26.4% wins, the highest rate, and the step cut her after this for that reason.

## Cards that hardly get played

Under 5% of boards: Pipistrelle Echo, Pennywort Snail, Cradle Fetch, Turnip Scarecrow, Lamp Moth, Earwig Mother, Hob-in-the-Hearth, Cricket Busker. The bots have no plan for most of these, so this says little about the cards. A designer should still look at them.

## Limits

Curves, `power` priors and card hints are hand-set, some after seeing bench results, so a strategy's result measures those too. The bots use Jill rarely (8 times in 40 games) and don't plan around Echo or Fetch.
