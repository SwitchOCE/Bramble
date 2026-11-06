# Reading the bench: bot or game?

A person's reading of `bench-latest.md`, run at commit 38f2fa1 (2 cores, seeds from 1). A rerun overwrites that report, not this file, so check the numbers still match before leaning on it. Card numbers weren't changed.

## Failed bars

**Hard among Normal: average place 3.70 ±0.21 (bar 3.5).** Bot-limited. Hard and Normal share evaluations, and search adds little: the search over the rule layout is +0.04 ±0.16 places, and 200 fights over the budget of 20 is +0.04 ±0.35 (100 seeds). Hard's edge is its build pick and curve. Weighting Hard harder toward the low-roll build (`power` 35, not 20) gave 3.90 ±0.20 over 500 games, no better, so it was reverted. An earlier 150-game sample at budget 30 read 3.29; that sample was small, and 3.70 is the number to use.

**Win spread, 2000 games: 4 of 8 inside 6-25%, 1 above.** low_roll 26.4%, hag 23.5%, parish 17.8%, rings 13.6%, help 9.7%, treasury 3.5%, economy 3.0%, rainbow 2.6% (each ±0.7-1.9).

## Each strategy outside the band

- **neutrals_low_roll, too strong: mostly game.** It went 55%, then 29%, then 26.4% as the others' climbing curves were slowed, so curves are part of it. It still leads on stats at every turn (turn 12: 102/137 against about 85/115 for climbers). Tiers look overpriced against tempo. Cheap buffs at low tiers are the line to watch.
- **fairies_rainbow, too weak: mostly game, some bot.** The pot pays at most 5 gold. The bot's bands also pin the board.
- **hedgerow_treasury, too weak: game and bot.** Acorn supply in the slice is thin (the Larder stays under 1 gold, Acorns per fight 0.110, parish 0.303). The bot also feeds the Alderman and cashes rather than holds.
- **neutrals_economy, too weak: can't be cleared.** It dies on tempo: 92 of 2000 seats are alive at turn 15, and they win about .47 of the time from there. Bots never hold big banks: no turns at 60, against rule shop counts of 13/22/31 at banks 12/30/60. **The bots may be hiding the economy, as the owner warned. A low result here is not evidence that economy is weak. Reviewers must check it by hand.** Dame Farthing's 6.0% wins is bot-limited for the same reason.

## Features the bots under-use

Results for these say little about the cards:

- Jill's power is never used, Shake the Tree is never bought, and Hob borrows only for a climb.
- The Queen's tithe slot isn't planned.
- Curves and card hints are hand-set, so a strategy's result measures those choices too.

## Limits of the time figure

Hard: mean 38.7 ms per turn, 95th percentile 85.9, worst 161.7. A lobby of 8 Hard takes a mean of 241 ms, 95th percentile 506, worst 735. The phone figures (0.72 s, 1.52 s) assume a core 3x slower. No device was tested, and the desktop numbers were measured with shards running.
