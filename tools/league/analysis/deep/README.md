# Deep balance analytics

Analyses beyond the section 9 reports (`../README.md`), for a designer rebalancing cards. Python 3, standard
library only. Built on `../match_data.py` (loader, `Stat`) and `../cards.py` (`adjusted_lift`); neither is changed.

```
python3 run.py MATCH [--out-dir DIR] [--no-records]     # one match -> MATCH/deep/
python3 across.py MATCH [MATCH ...] [--out-dir DIR] [--rerun]   # matches in time order -> last match's deep/
python3 -m unittest tests.test_deep_formulas            # from tools/league/analysis
```

`run.py` writes `meta.json`, `tempo.json`, `cards.json`, `fights.json`, `synergy.json` and a `deep.md` report.
`across.py` writes `across.json` and `across.md`, running `run.py` first for any match without `deep/meta.json`.

**Speed.** On cores 4 and 5 of the referee machine (one Python process, sharing the machine with the teams),
`run.py` took 22 s on the 200-game `s0` (124 MB peak) and 16 s on `dev-analysis`. On a 1,000-game volume fixture
(the real `s0` logs repeated five times with distinct game indices, records symlinked) it took 120 s with a
507 MB peak. The decision log (2.9 GB uncompressed per 1,000 games) is the slowest part: every line is parsed.

## Conventions every table follows

- **Independent unit: the seed pair** (`game // 2`). The two games of a pair share a seed with colours
  swapped. Means and rates are ratios of sums with the clustered 95% interval of `../README.md` ("Counts and
  uncertainty"); `common.Acc` is the same formula as `match_data.Stat` but accepts observations in any order.
- **Differences over the same pairs** (`common.Contrast`, `common.Combo`) use a linearised interval: each pair's
  influence is `sum_g w_g (x_gp - v_g n_gp) / n_g`, half-width `1.96 sqrt(k/(k-1) sum influence²)`. Use these
  rather than eyeballing two overlapping intervals.
- **`thin: true`** when a number rests on fewer than 30 observations or 10 seed pairs. Thin numbers are kept so
  a chart can grey them out; the report marks them ⚠thin and never leads with them.
- **Scopes:** `red`, `blue`, `both`. Pooled (`both`) lifts compare each board with **its own team's** stratum,
  so a strong team does not make its cards look strong.
- **Fight score:** win 1, draw 0.5, loss 0. (The section 9 scripts count a draw as not a win.)
- **Rounds** are exact up to 15; rounds 15 and later share bucket 15. **Bands** are the section 9 bands
  1-3, 4-6, 7-9, 10-12, 13+.
- **Survivorship.** Per-round tables over alive seats describe the boards that lived. Where it matters there is a
  dead-as-zero version (`hp_by_round`).
- **Two bots.** Every pattern is two bots' habits meeting the game. "Nobody buys X" can be two blind spots.
  Agreement between unrelated bot pairs (for example `s0` and the naive `dev-analysis`) is the stronger sign.

**JSON shape.** Every table is a list of flat rows. Each row has its dimension columns (`scope`, `round`,
`card`, ...), a `metric` name where a table holds several, and a stat object: `{"mean"|"rate", "count", "pairs",
"ci95": [lo, hi] | null, "thin", "hits" (rates only)}`. Lifts are `{"mean", "count", "pairs", "ci95", "thin"}`.
Contrasts are `{"diff", "a", "b", "count_a", "count_b", "pairs", "ci95", "thin"}`. Combos are `{"value",
"groups", "counts", "pairs", "ci95", "thin"}`. Card ids join to `MATCH/library.json`.

## `meta.json`

Match labels, games, seed pairs, team averages from the manifest, rules hash, which logs were read
(`coverage`: decisions, shops, records), the thin thresholds, the tribe list and run time.

## `tempo.json`: tempo and economy

| Table | What it measures, exactly | Why a designer cares | What it can't tell you |
|---|---|---|---|
| `conversion` | Per scope and final main tribe (`all` too): `place`, `win`, `top4`, `win_given_top4` (wins / top-four finishes) and `place_1`..`place_8` rates | Separates tribes and bots that **win lobbies** from those that only **place**. An even seat converts 25% | Final tribe is chosen by the bot, often after it is already winning or losing |
| `outcome_by_tempo` | Outcome (`place`, `win`, `top4`, `win_given_top4`) grouped by `tier2_round` (round the seat first ended a turn on tier 2: 2..5, `6+`, `never`), `tierN_round` for N = 3..6, `tier_at_round_R` (R = 4, 6, 8, 10; seats alive at R) and `turns_on_tier1` | The owner's question: does sitting on tier 1 for the discount cost first places? | Within a team the bot chose its tempo for its own reasons; between teams everything else differs too. Not a controlled trial: test a tempo with a constructed bot |
| `common_curves` | The eight most common levelling curves per scope (round reaching tiers 2-3-4-5-6, `x` = never) with seats and outcomes | Shows whole plans, not single upgrades: "4-8-12-13-14" is the wait-for-discount plan | A curve that never reaches tier 6 includes seats that died first |
| `upgrade_prices` | Per scope and tier upgraded **from**: `paid` = gold at the upgrade decision minus gold at the next decision of the same turn; `discount` = list price minus paid; `share_of_list_paid`; `turns_waited` = rounds since the previous upgrade (since round 1 for the first, rulebook 4.6.3); `round` | Prices the discount rule as played: waiting 3 turns makes tier 2 cost 2 instead of 8 | An effect that changes gold on the same action would be counted in the price. List prices are copied from the record header (`upgrade_costs`) into `LIST_PRICE` |
| `by_round` | Per scope, final tribe (`all` too) and round, over **alive** seats: `alive` (its `count` is the seats), `tier`, `board_stats` (attack + health), `board_units`, `golden_units`, `hand_end_of_turn`, `gold_start`, `gold_left`, `unspent_share` (gold left / gold at start, as a ratio of sums), `gold_from_cards`, and from the decision log `buys`, `spell_buys`, `sells`, `refreshes`, `upgrades`, `plays`, `abilities`, `freezes`, `buy_gold` | Tier and stat curves by tribe; how much gold sits unspent (gold carries over, rulebook 4.1.2) | Late rounds are survivors only. No per-refresh cost is logged |
| `hp_by_round` | Health + armour after each round's fights, the dead counted as 0 (`hp_dead_as_zero`), and `alive_share` | Who bleeds early, without survivor bias | — |

## `cards.json`: cards

| Table | What it measures, exactly | Why a designer cares | What it can't tell you |
|---|---|---|---|
| `pick_rate` | Per scope, card, band (`all` too) and buyer's **final** main tribe (`all` too): shops showing a buyable copy (opportunities) and shops where the seat bought it (hits). Same definition as `../cards.py` | The "everyone buys this tier 1 whatever their tribe" matrix: a card bought at a high rate by all five eventual tribes is a generic pick | A tribe's final shop choices were made before the bot knew its final tribe; that is the point of the matrix |
| `pick_rate_by_card_tribe` | The same, summed over cards by **card** tribe and tier | Off-tribe buying at a glance: how often do eventual Badgers buy Pigeon tier 1s? | Mixes strong and weak cards of a tribe |
| `fight_lift` | Per scope, band (`all` too) and card: over fight sides whose board holds the card (once per side), fight score minus the mean score of the stratum (team, current main tribe, round); `adjusted_lift` from `../cards.py`, sign flipped so **positive = more fights won**. `+0.10` = ten points of fight win rate | A per-fight read on a card with real sample sizes (thousands of fights), beside the final-board lift in `cards.json` of section 9 | Selection: boards that still hold a low-tier card late are often undeveloped boards, so cheap cards read low; boards that found a tier 6 read high. Compare cards of the same tier |
| `board_predicts` | For R = 6 and 9, seats alive at R: does holding the card on the round-R board predict final `place`, `win`, `top4`? Lift over the stratum (team, main tribe of the round-R board); positive = better | Separates **high-roll** cards (win lift without top-four lift) from **safe-floor** cards (top-four lift, flat on wins), measured at a fixed time so late cards don't win just by appearing on long-lived boards | The board at R also reflects the seat's luck and health so far |
| `winning_boards` | Per scope and final tribe: share of **first-place** final boards that hold the card against the share of **5th-8th** final boards of that tribe | What a winning Briar board looks like, card by card | First-place boards are the longest-lived, so late cards are over-represented. Use `board_predicts` for cause-like reads |
| `tenure` | From replay records (`records/game-*.jsonl`, `fight_boards` lines), one unit = one recruit `uid`. Per card: `fights_on_board` (snapshots it was in), `kept_to_end` (on the seat's last fight board), `tripled` (gone, and the next board has a new golden copy of the same card), `left` (gone otherwise: sold, eaten or consumed), `fights_before_leaving` and `left_after_one_fight` (among units that left) | Cards that are bought and dropped (a stopgap, or a bad card) against cards that stay to the end | A unit bought and sold within one turn never reaches a fight board and is not counted here (see `resales`). "Left" does not say why |
| `resales` | From the decision log: buys and sells per card, `sells_per_buy`, and `sold_same_turn_as_a_buy` (a sell of the card in a turn in which the same seat had bought a copy not yet sold) | Quick flips and triple fodder | The log has no unit id, so the sold copy may be an older one |

## `fights.json`: fights and game shape

| Table | What it measures, exactly | Why a designer cares | What it can't tell you |
|---|---|---|---|
| `by_round` | Per scope and round, over live fight sides: `damage_taken_per_fight`, `damage_when_losing` (before armour), `draw`, `ghost_fight`, `fight_score` | Damage curve and draw rate | — |
| `upsets` | Live fights, from the side with **fewer** total stats: its fight score by stats ratio bucket (stronger/weaker: 1-1.25, 1.25-1.5, 1.5-2, 2-3, 3+) and band; and by the weaker side's current tribe (`stat_ratio = any`) | How much fights are decided by stats on paper, and which tribes win beyond their stats (effects that don't show as stats) | Stats include slot buffs and growth already applied; in-fight effects are what is left |
| `tribe_vs_tribe` | Per scope and band (`all` too): fight score of current main tribe against the opponent's current main tribe, live opponents only | The matchup table by stage; section 9 gives only round 7+ | Pooled red-vs-blue fights mix bot strength into the matchup |
| `game_shape` | Per game: `rounds`; `decided_round` = first round from which the eventual winner had the most health (ties count) at the end of every later round; `decided_share_of_game`; `winner_worst_hp_rank` (rank = 1 + alive seats with strictly more health); `winner_was_bottom_half` (worst rank 5+); `winner_min_hp`. Rows per winner's colour and `all` | When games are won, and how often a winner came back from behind | Health rank in the first rounds is mostly ties |
| `outcome_by_hp_rank` | Per scope, R = 4, 6, 8, 10 and health rank after round R: `win` and `top4` rates | How much an early lead is worth | — |
| `by_seat`, `seat_gap` | Average place and win by seat id; ghost-fight rate by seat; contrast of seats 0-2 against seats 5-7 (place, negative = low seats better), over the same pairs | Matchmaking fairness (an earlier check found seats 0-2 placing better with identical bots) | With two teams, per-seat numbers mix the team layout of each game |

## `synergy.json`: card pairs

Fight sides from round 7 (`from_round`). A side's **residual** is its fight score minus the mean of its
stratum (team, current main tribe, round, over all rounds). For each card pair with at least 100 sides holding
both (`min_together`) and 50 holding each without the other (`min_apart`):

- `interaction` = residual(A and B) - residual(A without B) - residual(B without A) + residual(neither), a
  `Combo` with weights (1, -1, -1, 1). **Zero when the two cards just add up**; positive when they do better
  together. This is the column to sort by.
- `excess_over_best_single` = residual(A and B) minus the better of the two singles (a `Contrast`). Easier to
  read, but it rewards two good cards that merely add up.
- The four group residuals and counts.

Why a designer cares: combos worth costing together, and anti-synergies (two cards that compete for the same
slot or trigger). What it can't tell you: a board holding two specific cards is often a more developed board,
which the residual does not remove. With ~300 pairs tested, about 15 will clear a 95% interval by chance.
Treat a large interaction as a lead to test with a constructed fight.

## `across.json`: matches over time

Given match folders in order:

- `matches[]`: labels, games, rules hash, `tribe_spread` (worst minus best average place over final tribes with
  30+ seats, pooled) and `series`: flat rows `{scope, metric, value, ci95, count, thin}` for placement, win,
  top four, win given top four, tier / board stats / gold left / refreshes / buys / sells at rounds 4, 6, 8, 10,
  12, health (dead as zero) at those rounds, upgrade round and price per tier, tribe shares, placement and
  conversion by final tribe, decided round and game length. A chart of any metric across matches reads one
  `metric` from each match's `series`.
- `same_rules`: false when the rules fingerprint differs (then a change can be the rules, not the bots).
- `movers_first_to_last`: per scope, the 15 cards whose overall buy rate and per-fight lift moved most between
  the first and last match, with an interval that treats the two matches as independent.

Why a designer cares: a gap that shrinks as play improves means the weaker bots overstated it. What it can't
tell you: a mover between two different bot pairs is a change of bots, not of bot skill; compare tags of the
same team.

## Verification

`tests/test_deep_formulas.py` checks every formula that isn't trivial against hand-worked numbers: the clustered
interval of `Acc` (and that it equals `match_data.Stat`), `Contrast` and `Combo`, unit tenure classification,
the lift sign for higher- and lower-is-better outcomes, that pooled fight lift is within team, the pair
interaction (zero for additive cards), decided round and health rank, stat ratio buckets, tier-reach rounds,
and on a two-game match on disk: upgrade price paid and turns waited, draws scoring half, same-turn resales and
a full `run.py` pass. Deliberate break: removing `k/(k-1)` from `Combo`'s interval made
`test_contrast_by_hand` fail (1.386 against 1.96); restoring it passes.

## What the logs can't answer, and the field that would unlock it

- **Why a unit left the board** (sold, eaten by a Glutton or Gorger, consumed by an effect): a `sell` or
  `consume` event in the record with the unit's `uid` and the eater's `uid`.
- **Which copy was sold**: the unit `uid` on decision-log `sell` and `play` actions (and on `bought` in
  `shops.jsonl`), which would also give exact buy-to-sell lifetimes, including units sold in the turn they were
  bought.
- **Refresh cost paid**: the price on `refresh` legal actions, like `buy`.
- **Stats a card added**: per-unit stat deltas with a source uid (also asked for in `../README.md`), to price a
  buffer directly instead of through fight lift.
- **Who a seat could have fought**: the matchmaking candidates per round, to separate a seat effect from the
  pairing rule.
- **Bot intent**: the `strategy` field of `reports.jsonl` is free text per team; a shared short vocabulary
  (e.g. `tempo`, `econ`, `tribe:<name>`) would let tempo plans be compared across teams.
