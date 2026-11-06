# Reading the bench: bot or game?

A person's reading of `bench-latest.md`. A rerun overwrites that report, not this file, so check the numbers still match before leaning on it. The report's last table says which commit each suite ran on; it mixes commits. The win spread and pace are from 38f2fa1, before bots stopped reading the opponent's Larder and slots. A 500-game spread after that change matched within noise on all eight strategies (low_roll 27.4 ±3.9, hag 23.6, parish 16.6, rings 13.8, help 11.0, treasury 2.8, economy 2.4, rainbow 2.4). Card numbers weren't changed.

## Failed bars

**Hard among Normal picking freely: average place 3.73 ±0.21 (bar 3.5). Hard among the varied Normal lobby a player meets: 3.49 ±0.20.** The second is too close to call, and the report now says so: it clears the bar by 0.01. It's also helped by the lobby: about three of the seven seats are dealt rainbow, economy or treasury, which average 5-6th. The focus Hard ended on fairies_hag in 97% of games, a build its hand-set `power` prior favours. Hard's search adds little: +0.05 ±0.16 over the rule.

**Win spread, 2000 games: 4 of 8 inside 6-25%, 1 above, too close to call by the report's rule:** low_roll's and hag's margins both cross 25%. low_roll 26.4%, hag 23.5%, parish 17.8%, rings 13.6%, help 9.7%, treasury 3.5%, economy 3.0%, rainbow 2.6% (each ±0.7-1.9).

## Each strategy outside the band

- **neutrals_low_roll, too strong: game and bot, not yet separable.** It went 55%, then 29%, then 26.4% purely as the other strategies' climbing curves were slowed, and those curves are hand-set bot choices. So much of its lead may be bots climbing badly. Turn 12 boards: low roll 102/137, parish 101/136, others about 75-86/105-118, so it ties the best build rather than leading everyone. From turn 15 it does win more: .62 of survivors against .47 for hag and .42 for parish. Cheap buffs at low tiers are a line to watch, but this result doesn't prove tiers are overpriced.
- **fairies_rainbow, too weak: mostly game, some bot.** The pot pays at most 5 gold. The bot's bands also pin the board.
- **hedgerow_treasury, too weak: game and bot.** Acorn supply in the slice is thin (the Larder stays under 1 gold, Acorns per fight 0.110, parish 0.303). The bot also feeds the Alderman and cashes rather than holds.
- **neutrals_economy, too weak: says nothing about economy.** `neutrals_economy` has no `save` plan, so nothing hoards. **No economy line has been tested at all.** No seat in the spread had a turn at a bank near 60, against rule shop counts of 13/22/31 at banks 12/30/60. It dies on tempo: 92 of 2000 seats are alive at turn 15, and they win .42 of the time from there, so the build isn't hopeless when it survives. This is what the owner warned about: bots may be hiding the economy. Dame Farthing's 6.0% wins is unproven for the same reason. A real hoarding line is for the balance step, and reviewers should try economy by hand.

## Do the strategies differ?

The report's overlap table marks each strategy distinct or not, at a hand-chosen limit of 0.6. At 2000 games, 3 of 8 are distinct (parish, treasury, economy) and 5 aren't. Seven of the eight sit at 0.60-0.63, right on the limit, and some flip between runs, so read it as most builds sharing about 60% of their boards. Only economy is clearly apart, at 0.39. alderman_dozey is on 70-96% of final boards in all eight strategies, 83% overall. That's a balance finding, left for the balance step. The win spread can't mean eight lines are alive while one card sits on most boards.

## The lobby a player meets

Seats are dealt different builds, so nobody meets seven of one build. Unpinned Hard still converges: 95.5% of seats in an all-Hard lobby ended on fairies_hag, so lobbies now rely on the deal for variety, not on bots choosing it. The weak builds are seated as often as the strong ones, which likely makes both Normal and Hard lobbies easier than seven strong builds would be: rainbow averages 6.0 and economy 5.8.

## Is scouting earning its place?

On this slice, with these bots, the bench can't show it is.

- Everyone scouting: placing by search beats shuffled by 0.91 ±0.19. Nobody scouting: by rule beats shuffled by 0.84 ±0.20. Nearly all of the value of placing is there without scouting.
- One seat without scouting among seven with it: seeing is worth 0.14 ±0.21 of a place, which isn't distinguishable from nothing.
- Games run 14.5 rounds with scouting and 15.2 without.

This is bot-limited as well as a finding: the bots use a scouted board through a facing rule and a search that adds little, and a person may read a board for more. It measures what these bots get from the rule, not what a player would.

## Features the bots under-use

Results for these say little about the cards:

- Jill's power is never used, Shake the Tree is never bought, and Hob borrows only for a climb.
- The Queen's tithe slot isn't planned.
- Curves, `power` priors and card hints are hand-set, some after seeing bench results, so a strategy's result measures those choices too.

## Limits of the time figure

Hard: mean 38.7 ms per turn, 95th percentile 85.5, worst 163.1. A lobby of 8 Hard takes a mean of 241 ms, 95th percentile 504, worst 707. The phone figures (0.72 s, 1.51 s) assume a core 3x slower, so the 95th percentile misses the 1 s aim on that assumption. No device was tested, and the desktop numbers were measured with shards running.
