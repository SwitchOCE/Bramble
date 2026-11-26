# Tables: the 25 Nov match and the 26 Nov trials

The numbers behind the ledger of marks (`docs/workstreams/balance/marks.csv`) and the two pages for the owner. Each measure is defined in [definitions.md](../../definitions.md). The matches themselves were deleted once these were written.

Two Heath Adder readings in `trials_26nov.csv` are kept as warnings and are not evidence about the card. In the first run blue's patch had not taken, so only red's row counts. In the second, blue valued it as Sett Shield-bearer, the card its whole plan stands on: it bought the Adder in 878 games, kept it like a Shield-bearer, and finished 0.63 worse. A peer has to be a card the bot values in an ordinary way, standing in the same row and doing the same kind of job.

The three tests named "blue told to stay on" a tribe did not work: blue's own `stay_tribe` knob gives a bot that finishes about 7th of 8, so the left-out rows played on it (Sweetbriar, Leafmould Carter, Lieutenant, Colour Sergeant, Group Captain, Needle Pikeman) say nothing about those cards.

**The match.** 2,000 games, bots red-c14 and blue-c17 against the reference field cut from their own games, rules hash `fa1d51ec`, played 25 Nov 2026 and replayed with records on 26 Nov. Places are finishing places out of 8; a positive difference means the bot finishes worse.

| File | What it holds |
|---|---|
| `cards.csv` | The card report: one row per card, every measure, and what marked it. |
| `bought_passed.csv` | Pick rate and bought against passed, per bot. |
| `text_cards.csv` | Text off and stat worth, per card and stage. |
| `fresh_copy.csv` | A fresh copy of each card on recorded boards, per stage. |
| `keywords.csv`, `overrun_swings.csv` | Keyword off (Fury, Overrun, Cleave) and Overrun's swings. |
| `stat_growth.csv` | Permanent stats gained per turn held. |
| `left_out.csv` | Left out of the shop: 18 cards and one set, with the control run. |
| `trials_26nov.csv` | Every paired reading of 26 Nov: the valued-as-a-peer matches, and the left-out readings inside each trial of a proposed fix. |
| `trial_card_reports_26nov.csv` | The card report's rows for the changed cards inside each trial: text off on held copies, and a fresh copy, by stage. |
| `hands_26nov.csv` | Share of each bot's games holding one, or two or more, Territorials and Home Guards in hand at the end of rounds 4, 6, 8 and 12: today, at 4/5, and with no text. |

**Reading `trials_26nov.csv`.** Each row is one bot in one pair of matches on the same seeds: `place_b` minus `place_a`. `rules` says which card data the pair was played on ("today", or a named trial fix). `which_games` is all 1,000 of the bot's games, or only those where it bought the card. A bot's place cannot be compared between two different `rules`: the recorded opponents change with them. For a fix tried through the valued-as-a-peer test, read the rows "where the bot bought it" before and after; the all-games rows also carry the games where the card never came up.

In the ledger's notes, a place difference beside "bought it in N games" is over all 1,000 of the bot's games unless the note says otherwise.

The trial card data and two reworks of Sword-heir's mechanic lived in a scratch copy and were never part of the game. Valued as a peer is not yet a defined measure: it was run from a scratch patch of the two bots, and its write-up waits for the owner's yes.
