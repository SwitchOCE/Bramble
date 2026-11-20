# Bot league match analysis

Run these Python 3 commands from this directory. Report commands print Markdown and save JSON beside the match logs. For reports that also save Markdown, use `--out-dir DIR` to change the destination. The team export takes its own output directory. Run the Rust harness's `league analyze MATCH` once before exporting the score or building the ladder. Its `analysis.json` remains the source for the official score, timing and health. The referee keeps the full reports.

| Command | Outputs |
|---|---|
| `python3 split_team.py MATCH red RED_DIR` (or `blue`) | `team.md`, `team.json`, `decisions.jsonl.gz` in the specified directory |
| `python3 cards.py MATCH` | `cards.md`, `cards.json` |
| `python3 tribes.py MATCH` | `tribes.md`, `tribes.json` |
| `python3 behaviours.py MATCH` | `behaviours.md`, `behaviours.json` |
| `python3 events.py MATCH` | `events.json` and Markdown on stdout |
| `python3 combat.py MATCH` | `kills_by_card.tsv`, `summons_by_source.tsv`, `kill_shares.tsv` |
| `python3 agree.py MATCH` | `agree.md`, `agree.json` |
| `python3 ladder.py MATCH [MATCH ...] [--trends]` | `ladder.md`, `ladder.json` beside the first match |

**Shared loader.** `match_data.py` is an importable module. It accepts a completed schema 1 manifest, reads the card library, streams one JSON line at a time and transparently uses plain shops or decisions when gzip output is absent. It joins events to final tribe and colour by game index and seat id, and checks event bot and colour against that seat. The second game of each seed pair already contains its swapped seat colours. The scripts count play as it actually took place, including fallback play. The health log and the decision log's `by` field identify affected seats and decisions.

**Team export.** `split_team.py` takes a match, a colour and a new or empty destination. It publishes the harness's score, intervals and game counts, that team's card results calculated solely from its seats, and pooled final-tribe shares and mean placements. The gzip file contains the original lines for that team's decisions, including their legal alternatives. The exporter assembles the files in a private staging directory and publishes the directory only after all joins succeed. The referee supplies the two method summaries and the next-round announcement separately.

**Cards.** `cards.py` reports every library unit for red, blue and both together. A buy opportunity is one shop displaying at least one buyable copy of the unit at opening. Any purchase of that identity before the shop changes counts once. Duplicate offers and buys count once per identity per shop. Rates are available overall, by round band (1–3, 4–6, 7–9, 10–12, 13+), by **final** main tribe and at their intersection. A missing intersection has zero opportunities. “Never” means strictly below 2%. The approved brief's `always_bought` means strictly above 80% in **each** library tribe, using all buyable shops. `always_among_buying_shops` applies the same cutoff only to eligible shops with a purchase of any unit or spell. A missing tribe denominator leaves the verdict unknown unless a measured tribe already fails it. Discover uses choices offering the identity. Golden rate uses golden copies divided by all final-board copies. An optional shop report gives rank 1 plus the number of distinct reported, offered identities valued strictly higher, including scored spells. Ties share rank. Conflicting scores for the same identity invalidate the ranking for that report. `value_rank_when_buyable` additionally requires an unambiguous shop and a buyable focal unit. Placement lift counts a final board once per identity. For each such board it subtracts its placement from the mean for its own final main tribe and exact last-fight round, within the same team scope. A lift of +0.5 means half a place better than that matched baseline. It measures association.

**Round-band card verdicts.** For each team and for both together, `always_bought_in_band` requires a buy rate strictly above 80% in every final main tribe with at least 30 buyable shops for that card in that band. At least three tribes must reach 30. `band_evidence` records each named tribe's rate and count, the excluded tribes (including zero offers), and the minimum among qualifying tribes. The minimum is null when fewer than three qualify. The “High everywhere” tables rank up to 15 eligible cards by that minimum, breaking ties by card id. They include cards below 80% so broadly bought early units remain visible. Pooled band evidence includes `team_share` with each colour’s count and fraction of all buyable shops for that card in that band, including excluded tribes. Pooled all-round verdicts give team shares for the shops used in the displayed rate. A team supplying strictly more than 90% is flagged in JSON and Markdown. The all-round rows show the buy rate and purchase count over the applicable shop count. Table cells show purchase hits / buyable shops, using purchasing shops only for the conditional all-round verdict.

**Tribes.** `tribes.py` reports distributions for places 1–8, wins (place 1), top four, and final main-tribe shares over all seats, including an explicit tribe-less group. It uses the harness's recorded commitment and pivots. Commit round averages cover seats that reached four units of their final tribe. Pre-commit event rates use committed seats with a preceding round and record whether a triple, net golden gain or slot change occurred in that round. Pivot rate counts seats with any logged pivot. Mixed boards have a main tribe and at least two units outside it. The report includes placement for pivoted and mixed boards and wins for mixed boards. Fight stages use the **current** main tribe, determined by unit count, then total attack plus health, then ascending name. Each live side contributes one observation, including against a ghost. A draw contributes zero wins. A separate stage rate covers fights against other live tribes. Round 7+ head-to-heads use two live boards. Per-round medians cover total logged board attack plus health and tier among surviving seats. Gold left and gold from cards are seat-round means. Strategy shares weight each nonempty report call (shop or Discover) once. Highest-value buying compares purchases with the top reported offered identity, ties included, and gives a second denominator restricted to purchasing shops. Optional shop reports are joined in turn order by their entire offered lists. If repeated offer lists permit several valid alignments, that observation is omitted from the purchase comparison and counted in join coverage.

**Behaviours.** `behaviours.py` measures Colonel hand size both as all cards and as eligible reserve units (spells excluded), with fight wins by size. For current Briar boards it reports Compost size by round (absent heap means zero) and wins by heap size. It groups friendly deaths and fight wins by the number of Gleaners, both across all fights and within current Locust boards. Badger fights use the engine's actual `outnumbered_by` for the observed side. Accepted sells are counted per game and per seat-game, including seats with zero sells. The report counts sales from a full seven-slot board and sales offered to a remaining Gorger or, for a sold Locust, a remaining Glutton. The two opportunity counts can overlap. If the decision log was omitted, sale metrics are absent. When `records/` is present, live pre-fight snapshots provide the net change in total slot attack plus health since the last snapshot (starting at zero), grouped by which of the two Sergeants are currently on board. Snapshots also show the share of surviving Gorgers with a `locust_ate` mark. The game log alone provides the rate of any slot change, which includes keyword changes.

**Replayed events.** Run [`bramble-events MATCH`](../bramble-events/README.md) first to produce
`events.jsonl.gz`. `events.py` reports exact Gorger and Glutton eats, stats gained per eat
by round, fed sale rates, and rounds on board for fed and unfed sales. It shows the units eaten
by tier and by card, including a top 15 ranked by count. Diet shares use all eats in the team
scope as the denominator. Slot growth by source card totals the actual signed deltas, including
any amplification. Ghost growth is shown separately under the ghost owner's team. The individual
Sergeant summaries credit the original buff to its source and the extra stats to the amplifiers.
When `events.json` is present, the behaviour Markdown links to it and labels the snapshot and
sale-opportunity stand-ins.

**Recorded, not yet summarised.** Sale proceeds and exact board-entry rounds, eaten units'
displayed and own stats, per-unit UIDs and golden flags, individual slots, trigger kinds,
permanent flags, and combat pairings remain available on the event rows.

**Agreement.** `agree.py` lists units both teams almost never buy or always buy under either all-round denominator. For each band, `both_always_in_band` requires each team to satisfy its own band verdict. The teams can have different qualifying tribes, and the report names each team’s exclusions. For cards with opportunities on both sides it orders all red-minus-blue buy-rate differences by absolute size, shows counts and intervals for each team's underlying rate, and breaks ties by card id. Tribe shares and commit rounds are side by side. The full agreement report stays with the referee.

**Ladder.** `ladder.py` preserves the order of supplied matches and their manifest labels so earlier tags, strength checks and practice matches can appear together. It reads team placements, red-minus-blue gap and 95% half-widths from each harness analysis. Negative gaps favour red. `--trends` adds each match's per-unit buy rates and tribe results by colour and pooled, so the referee can track changes across versions. The reported label identifies the bot version at the referee's discretion.

## Combat TSVs

`tools/league/analyse_match.sh MATCH` writes these three tables from `games.jsonl` and
`library.json`. They pool both sides of every fight, including ghosts. Matches recorded
before kill origins were logged skip these tables.

- `kills_by_card.tsv` groups by library tier, card id and golden flag. `fights_present` counts
  a fight once for the group, even if multiple copies or both sides are represented.
  `total_kills` sums all their kills and `kills_per_fight` divides by `fights_present`.
  Purchase-turn breakdowns require linking individual purchases to units and tracking
  transformations. The decision and shop logs identify purchases by card.
- `summons_by_source.tsv` groups by source card id and summoned card id. `total_summoned`
  counts landed summons and `games` includes every game in the match, including games
  with zero summons for that pair. `summoned_per_game` divides those two columns.
- `kill_shares.tsv` has `overall` rows by origin and `source` rows for summon kills by
  their summoning card. `share` is the fraction of all credited kills across the match
  in either kind of row, and is blank when there are no credited kills. `(none)` in
  either source table represents a summon without a source unit.

## Counts and uncertainty

Rate objects include hits, observation count (denominator), contributing seed-pair count and a 95% interval. Mean objects carry the observation and pair counts and interval. Median objects give the number of seat-rounds. An empty denominator yields null. A rate observed at zero still has a denominator. The reports preserve sparse groups and generally show counts alongside percentages.

Each independent cluster is the seeds-file line, indexed by `game // 2`. Repeated seed text on different lines stays separate, as in the harness. Estimates weight individual observations. For a mean or rate `v = sum(x) / sum(n)`, accumulate each contributing pair's total and count `x_i, n_i`. The 95% half-width is `1.96 * sqrt(k/(k-1) * sum((x_i - v*n_i)^2)) / sum(n_i)` for `k` contributing pairs. Intervals are approximate, particularly for rare units. Rate intervals stay within [0, 1]. With all hits or all misses we use a Wilson boundary interval with effective pair count `sum(n_i)^2 / sum(n_i^2)`. With fewer than two contributing pairs the interval is null. Lift uses the same clustered linearization with the estimated stratum baselines included in its uncertainty. The harness supplies the score intervals in their original half-width form.

## What the logs can establish

Replay recovers the exact eater, sold unit and gained stats for every eat, and the source and signed stat deltas for each slot-growth event. A surviving Gorger's mark and net slot changes from snapshots remain useful as stand-ins when replayed events are unavailable. Sale intent has no log field. Full-board sales describe board pressure. A commit event can identify the preceding round's changes but cannot establish the bot's reason. Replay mismatches come from the referee's replay check, and team effort on a tribe comes from the teams' notes. Referee health and strength assessments should use those sources as well.

## Verification

Run `python3 -m unittest -v` here. The fixtures specify the expected observations by hand, exercise both colours of a swap and check the team export against changes to opposing purchases. The intentional mutation removed the buyability filter. `test_buyable_only_per_shop` then reported 3 buys in 5 shops, against the expected 2 in 4. Restoring the filter makes the test pass.


On cores 4 and 5 of the referee machine, the commands (including both colours of the team export and ladder trends) took under 174 seconds on a 1,000-game volume fixture with two Python processes at a time. The largest analysis process used 42 MiB RSS. The fixture repeated the real 200-game FlowBot–TribeBot logs five times with distinct game indices, reusing the original records for slot snapshots. It was used only for timing. Runtime will vary with the number of decisions, offers, reports and games supplied for comparison.

The commands also ran on the original 20- and 200-game matches. A byte-for-byte check of the decompressed team exports against the original decisions found 100,170 red and 76,361 blue lines in the 200-game match. Both team card files matched their own section of the referee report.

## `winscore.py <match-dir> ...`

The win-weighted score the owner asked for beside average placement (18 Nov 2026): 9, 7, 6, 5, 4, 3, 2, 1 points for 1st to 8th, higher is better. It prints each team's average per seat and the red-minus-blue gap with a 95% interval over seed pairs. The two teams' scores always add up to 9.25. The league is still decided on average placement.
