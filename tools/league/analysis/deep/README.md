# Deep balance analytics

Analyses beyond the section 9 reports (`../README.md`), for a designer rebalancing cards. Python 3, standard
library only. Built on `../match_data.py` (loader, `Stat`) and `../cards.py` (`card_stats`, `adjusted_lift`);
neither is changed.

```
python3 run.py MATCH [--out-dir DIR] [--no-records] [--no-events]   # one match -> MATCH/deep/
python3 across.py MATCH [MATCH ...] [--out-dir DIR] [--rerun]        # matches in time order -> last match's deep/
python3 -m unittest tests.test_deep_formulas                         # from tools/league/analysis
```

`run.py` writes `meta.json`, `tempo.json`, `cards.json`, `fights.json`, `synergy.json` and a `deep.md` report.
`across.py` writes `across.json` and `across.md`. It recomputes a match's deep output when it is missing, when
`meta.json` `code.source_sha256` differs from the current code (a hash of `deep/*.py`, `../match_data.py` and
`../cards.py`), or with `--rerun`.

**Logs read.** `games.jsonl` always; `decisions.jsonl.gz` (economy, upgrade prices, resales); `shops.jsonl.gz`
(buy rates); `records/` (unit tenure, and the rules config: `upgrade_costs` comes from the first record
header); `events.jsonl.gz` from `tools/league/bramble-events` when present (exact sales and eats by unit id).
`meta.json` `coverage` says which were found.

**Speed.** On cores 4 and 5 of the referee machine (one Python process, sharing the machine with the teams),
the first version took 22 s on the 200-game `s0` and 120 s with a 507 MB peak on a 1,000-game volume fixture
(the real `s0` logs repeated five times with distinct game indices, records symlinked). The second version adds
`cards.card_stats` (6 s CPU on `s0`, so about 30 s per 1,000 games) and a second lift pass; it has not been
re-timed at 1,000 games. The decision log (2.9 GB uncompressed per 1,000 games) is the slowest part.

## Conventions every table follows

- **Independent unit: the seed pair** (`game // 2`). The two games of a pair share a seed with colours
  swapped. Means and rates are ratios of sums with the clustered 95% interval of `../README.md` ("Counts and
  uncertainty"); `common.Acc` is the same formula as `match_data.Stat` but accepts observations in any order.
- **Differences over the same pairs** (`common.Contrast`, `common.Combo`) use a linearised interval: each pair's
  influence is `sum_g w_g (x_gp - v_g n_gp) / n_g`, half-width `1.96 sqrt(k/(k-1) sum influence²)`.
- **`thin: true`** when a number rests on fewer than 30 observations or 10 seed pairs. Thin numbers are kept so
  a chart can grey them out; the report marks them ⚠thin and never leads with them.
- **Scopes:** `red`, `blue`, `both`. **Read within a team.** A pooled (`both`) row mixes the two bots'
  strength into whatever it is grouped by: a tribe or card one strong bot plays looks strong. Every pooled row
  in a table that has team rows carries **`red_share`** (the red seats' share of the observations behind it)
  and **`one_team`** (true when either team supplies more than 90%); `deep.md` shows them as `red 85%` and
  `⚠one team`. Pooled lifts compare each board with its own team's stratum.
- **Fight score:** win 1, draw 0.5, loss 0. (The section 9 scripts count a draw as not a win.)
- **Rounds** are exact up to 15; rounds 15 and later share bucket 15. **Bands** are the section 9 bands
  1-3, 4-6, 7-9, 10-12, 13+.
- **Survivorship.** Per-round tables over alive seats describe the boards that lived. Where it matters there is a
  dead-as-zero version (`hp_by_round`) or a fixed horizon (`curves_at_horizon`).
- **Two bots.** Every pattern is two bots' habits meeting the game. "Nobody buys X" can be two blind spots.
  Agreement between unrelated bot pairs (for example `s0` and the naive `dev-analysis`) is the stronger sign.

**JSON shape.** Every table is a list of flat rows. Each row has its dimension columns (`scope`, `round`,
`card`, ...), a `metric` name where a table holds several, and a stat object: `{"mean"|"rate", "count", "pairs",
"ci95": [lo, hi] | null, "thin", "hits" (rates only)}`, plus `red_share` and `one_team` on pooled rows.
Lifts are `{"mean", "count", "pairs", "ci95", "thin"}` (the newer lift adds `strata_without_comparison`).
Contrasts are `{"diff", "a", "b", "count_a", "count_b", "pairs", "ci95", "thin"}`. Combos are `{"value",
"groups", "counts", "pairs", "ci95", "thin"}`. Card ids join to `MATCH/library.json`.

## `meta.json`

Match labels, games, seed pairs, team averages from the manifest, rules hash, `coverage`, the thin thresholds,
the tribe list, run time, and `code` (`git` commit of the checkout and `source_sha256` of the analysis source).

## `tempo.json`: tempo and economy

| Table | What it measures, exactly | Why a designer cares | What it can't tell you |
|---|---|---|---|
| `lobby` | Per team (`scope` red/blue): `lobby_win` = share of games one of the team's seats came first; `lobby_win_expected_if_random_among_top4` = the team's top-four seats in the game / 4, averaged over games; `lobby_win_minus_expected`; `top4_seats_per_game` | Whether a team wins the lobbies its top fours give it. Two even teams win 50% of lobbies each | — |
| `conversion` | Per scope and final main tribe (`all` too): `place`, `win`, `top4`, `win_given_top4` (wins / top-four finishes) and `place_1`..`place_8` rates | Separates tribes and bots that **win lobbies** from those that only **place**. Yardstick for `win_given_top4`: if first place fell at random among the four top-four seats, every top-four finish would be a win 25% of the time, **whatever** the number of top-four seats a team holds (its expected wins are its top-four seats / 4). A team below 25% loses the race for first more often than chance; that is not arithmetic | Final tribe is chosen by the bot, often after it is already winning or losing. Pooled rows mix team strength (see `red_share`) |
| `tribe_gap_within_team` | Per team: the worst minus the best average place over final tribes with 30+ seats (`best`, `worst`, `tribes`), as a `Contrast` over the same seed pairs | How far apart the tribes are for one bot, with an interval | Picking the extremes after looking inflates the gap a little; the interval does not correct for that |
| `outcome_by_tempo` | Outcome (`place`, `win`, `top4`, `win_given_top4`) grouped by: `tier2_round` (round the seat first ended a turn on tier 2: 2..5, `6+`, `never`); `tierN_round_alive_at_R` for N = 3, 4, 5, 6 with R = 8, 10, 12, 14 (seats alive at R; group = round tier N was reached, or `after_R_or_never`); `tier_at_round_R` (R = 4, 6, 8, 10; seats alive at R); `turns_on_tier1`; and the older `tierN_round` groups | The owner's question: does sitting on tier 1 for the discount cost first places? | When one team levels at a single round, the comparison is **between the two bots**, not between tempos. Within a team the bot chose its tempo for its own reasons. **`tierN_round` (no horizon) is kept for compatibility but its `never` group mixes seats that died before they could level; use `tierN_round_alive_at_R`** |
| `curves_at_horizon` | Per scope and horizon (`alive_at` 8: tiers held at rounds 2, 4, 6, 8; `alive_at` 11: rounds 3, 5, 7, 9, 11), among seats alive at the horizon: the ten most common curves (`curve` like `1-2-2-3`), `seats`, `alive_seats` and outcomes | Whole levelling plans compared on equal footing: every seat in the table was still alive | Seats alive at 11 are already a selected group |
| `common_curves` | **Kept for compatibility; superseded by `curves_at_horizon`.** Most common curves of the round each tier 2-6 was reached (`x` = never) | — | The label encodes how long the seat lived (a seat that died in round 9 can never show tier 6), so outcomes by label are mostly survival |
| `upgrade_prices` | Per scope and tier upgraded **from**: `paid` = gold at the upgrade decision minus gold at the next decision of the same turn; `discount` = list price minus paid; `share_of_list_paid`; `turns_waited` = rounds since the previous upgrade (since round 1 for the first, rulebook 4.6.3); `round`. `list_price` (top-level key) is `{from tier: price}` from the record header's `upgrade_costs` | Prices the discount rule as played. For example, waiting three turns takes 1+2+3 = 6 off | An effect that changes gold on the same action would be counted in the price. Without records there is no list price, and `discount` is absent |
| `by_round` | Per scope, final tribe (`all` too) and round, over **alive** seats: `alive` (its `count` is the seats), `tier`, `board_stats` (attack + health), `board_units`, `golden_units`, `hand_end_of_turn`, `gold_start`, `gold_left`, `unspent_share`, `gold_from_cards`, and from the decision log `buys`, `spell_buys`, `sells`, `refreshes`, `upgrades`, `plays`, `abilities`, `freezes`, `buy_gold` | Tier and stat curves by tribe; how much gold sits unspent (gold carries over, rulebook 4.1.2) | Late rounds are survivors only. No per-refresh cost is logged |
| `hp_by_round` | Health + armour after each round's fights, the dead counted as 0 (`hp_dead_as_zero`), and `alive_share` | Who bleeds early, without survivor bias | — |

An illustration of reading a curve (made up, not from any match): `1-1-2-3` at horizon 8 means tier 1 at rounds
2 and 4, tier 2 at round 6 and tier 3 at round 8.

## `cards.json`: cards

| Table | What it measures, exactly | Why a designer cares | What it can't tell you |
|---|---|---|---|
| `pick_rate` | `cards.card_stats` (the section 9 count, not a second copy) flattened into rows of scope, card, band (`all` too) and buyer's **final** main tribe (`all` too): shops showing a buyable copy (opportunities) and shops where the seat bought it (hits). Same values as before | The "everyone buys this tier 1 whatever their tribe" matrix | A tribe's early choices were made before the bot knew its final tribe; that is the point of the matrix |
| `pick_rate_by_card_tribe` | Summed over cards by **card** tribe and tier (an aggregate `cards.py` does not make) | Off-tribe buying at a glance: how often do eventual Badgers buy Pigeon tier 1s? | Mixes strong and weak cards of a tribe |
| `fight_lift_vs_other_boards` | **Use this one.** Per scope, band (`all` too) and card: fight score of sides holding the card minus the mean of sides of the same stratum (team, current main tribe, round) that do **not** hold it. `lift = sum_s (X_cs - N_cs b_s) / sum_s N_cs` with `b_s` the other boards' mean; strata where every board holds the card are left out (`strata_without_comparison`). The interval is clustered on seed pairs and includes the baseline's uncertainty. Positive = more fights won | A per-fight read on a card with real sample sizes; `deep.md` ranks within tier and team, needs 100+ fights, and ranks by the interval's near bound | Selection: boards that still hold a cheap card late are often undeveloped boards, so low tiers read low; boards that found a high-tier card read high. Compare cards of the same tier |
| `fight_lift` | **Kept for compatibility.** The first version: the baseline is the whole stratum, the card's own boards included (`cards.adjusted_lift`), so a card on most boards reads near zero | — | Shrinks toward zero as the card's share of boards grows |
| `board_predicts_vs_other_boards` | **Use this one.** For R = 6 and 9, seats alive at R: does holding the card on the round-R board predict final `place`, `win`, `top4`? Same estimator as above, stratum (team, main tribe of the round-R board), positive = better | Win and top-four lifts side by side, measured at a fixed time. A card whose win lift clears zero while its top-four lift does not, *and* the two differ by more than their intervals, may be a high roll; `deep.md` draws no such label on its own | The board at R also reflects the seat's luck and health so far |
| `board_predicts` | **Kept for compatibility.** The first version, baseline including the card's own boards | — | As `fight_lift` |
| `winning_boards` | Per scope and final tribe: share of **first-place** final boards that hold the card against the share of **5th-8th** final boards of that tribe | What a winning board looks like, card by card | First-place boards are the longest-lived, so late cards are over-represented |
| `tenure` | From replay records (`records/game-*.jsonl`, `fight_boards` lines), one unit = one recruit `uid`. Per card: `fights_on_board`, `kept_to_end` (on the seat's last fight board), `tripled` (gone, not sold or eaten, and the next board has a new golden copy: inferred), `left` (gone and not tripled: same meaning as before), and with `events.jsonl.gz` the exact split of `left`: `sold`, `eaten`, `left_unexplained`; `fights_before_leaving` and `left_after_one_fight` among units that left | Cards that are bought and dropped against cards that stay to the end | A unit bought and sold within one turn never reaches a fight board (see `sales`). Without events, sold units that a triple would also explain may be counted as tripled |
| `sales` | Only with `events.jsonl.gz`. Per card, exact: `rounds_on_board` (round boundaries crossed on the board), `sold_in_entry_round`, `sale_fed_something` (the sale caused an eat or a slot growth) | Quick flips, and which cards are sold as fuel | — |
| `resales` | From the decision log: buys, sells, `sells_per_buy`, and `sold_same_turn_as_a_buy` (a guess: a sell in a turn in which the seat bought a copy). **Superseded by `sales` where events exist** | — | The decision log has no unit id |

## `fights.json`: fights and game shape

| Table | What it measures, exactly | Why a designer cares | What it can't tell you |
|---|---|---|---|
| `by_round` | Per scope and round, over live fight sides: `damage_taken_per_fight`, `damage_when_losing` (before armour), `draw`, `ghost_fight`, `fight_score` | Damage curve and draw rate | — |
| `upsets` | Live fights, from the side with **fewer** total stats: its fight score by stats ratio bucket (stronger/weaker: 1-1.25, 1.25-1.5, 1.5-2, 2-3, 3+) and band; and by the weaker side's current tribe (`stat_ratio = any`). Now per team as well as pooled | How much fights are decided by stats on paper, and which tribes win beyond their stats | Stats include slot buffs and growth already applied; in-fight effects are what is left |
| `tribe_vs_tribe` | Per scope and band (`all` too): fight score of current main tribe against the opponent's current main tribe, and against `(other tribes)`, live opponents only | The matchup table by stage | Pooled rows mix bot strength into the matchup; read team rows |
| `game_shape` | Per game: `rounds`; `decided_round` = first round from which the eventual winner had the most health (ties count) at the end of every later round; `decided_share_of_game`; `winner_worst_hp_rank` (rank = 1 + alive seats with strictly more health); `winner_was_bottom_half` (worst rank 5+); `winner_min_hp` | When games are won, and how often a winner came back from behind | Health rank in the first rounds is mostly ties |
| `outcome_by_hp_rank` | Per scope, R = 4, 6, 8, 10 and health rank after round R: `win` and `top4` rates | How much an early lead is worth | — |
| `by_seat`, `seat_gap` | Average place and win by seat id; ghost-fight rate by seat; contrast of seats 0-2 against seats 5-7 (place, negative = low seats better) over the same pairs | Matchmaking fairness | With two teams, per-seat numbers mix the team layout of each game |

## `synergy.json`: card pairs

Fight sides from round 7 (`from_round`). A side's **residual** is its fight score minus the mean of its
stratum (team, current main tribe, round, over all rounds). For each card pair with at least 100 sides holding
both (`min_together`) and 50 holding each without the other (`min_apart`):

- `interaction` = residual(A and B) - residual(A without B) - residual(B without A) + residual(neither), a
  `Combo` with weights (1, -1, -1, 1). **Zero when the two cards just add up**. Sort by this.
- `excess_over_best_single` = residual(A and B) minus the better of the two singles (a `Contrast`).
- The four group residuals and counts, and `red_share` / `one_team` for the fights together.

What it can't tell you: a board holding two specific cards is often a more developed board, which the residual
does not remove. With ~300 pairs tested, about 15 will clear a 95% interval by chance.

## `across.json`: matches over time

Given match folders in order:

- `matches[]`: labels, games, rules hash, `code`, `tribe_gap_within_team` (from `tempo.json`, with intervals)
  and `series`: flat rows `{scope, metric, value, ci95, count, thin}` (plus `red_share`, `one_team` on pooled
  rows) for placement, win, top four, win given top four, lobby wins (`lobby_win`,
  `lobby_win_expected_if_random_among_top4`, `lobby_win_minus_expected`), tier / board stats / gold left /
  refreshes / buys / sells at rounds 4, 6, 8, 10, 12, health (dead as zero), upgrade round and price per tier,
  tribe shares, placement and conversion by final tribe, decided round and game length.
- **`tribe_spread` was removed** (a pooled max minus min with no interval). Use `tribe_gap_within_team`.
- `same_rules`: false when the rules fingerprint differs (then a change can be the rules, not the bots).
- `movers_first_to_last`: per scope, the 15 cards whose overall buy rate (as counted by `cards.py`) and
  per-fight lift (`fight_lift_vs_other_boards` where both matches have it) moved most between the first and
  last match, with an interval that treats the two matches as independent. `ladder.py --trends` holds each
  match's raw buy rates; this adds only the change between two matches.

What it can't tell you: a mover between two different bot pairs is a change of bots, not of bot skill; compare
tags of the same team.

## Verification

`tests/test_deep_formulas.py` checks every formula that isn't trivial against hand-worked numbers:
- the intervals: `Acc` (and that it equals `match_data.Stat`), `Contrast` and `Combo`;
- the lift against other boards (value, dropped strata, interval) against the old lift, and the lift sign for
  higher- and lower-is-better outcomes, and that pooled fight lift is within team;
- team shares;
- unit tenure with and without events, the pair interaction, decided round and health rank, stats ratio
  buckets, tier-reach rounds, fixed-horizon curves and prices from the record header.

A two-game match on disk then checks the list price from the header, upgrade price paid and turns waited, lobby
wins and their expectation, draws scoring half, sales from events, same-turn resales, a full `run.py` pass and
`across.py`'s stale-code check.

Deliberate breaks:
- removing `k/(k-1)` from `Combo`'s interval made `test_contrast_by_hand` fail (1.386 against 1.96);
- removing the baseline-uncertainty term from `lift_vs_others` made `test_lift_vs_others_by_hand` fail (0.49
  against 0.98).

Restoring each one makes the tests pass. On `s0`, `pick_rate` from `cards.card_stats` equals the first version's
own count in all 6,601 rows.

## What the logs can't answer, and the field that would unlock it

`events.jsonl.gz` (from `tools/league/bramble-events`) now answers why a unit left the board (sold or eaten, by
uid) and which copy was sold. Still open:

- **Triples**: a `triple` event naming the three uids merged and the new golden uid, to replace the inference.
- **Refresh cost paid**: the price on `refresh` legal actions, like `buy`.
- **Who a seat could have fought**: the matchmaking candidates per round, to separate a seat effect from the
  pairing rule.
- **Bot intent**: the `strategy` field of `reports.jsonl` is free text per team; a shared short vocabulary
  (e.g. `tempo`, `econ`, `tribe:<name>`) would let tempo plans be compared across teams.
- **Stats a card added** is in `events.jsonl.gz` as `slot_growth` (slot buffs); per-unit growth from other
  sources is not, so a buffer's value outside slots is still read only through fight lift.
