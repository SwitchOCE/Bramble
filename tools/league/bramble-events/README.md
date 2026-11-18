# League replay events

Build `bramble-events` from the league workspace. The extractor uses the checkout's
frozen content and the system's `gzip`. Give it a completed match directory.

```sh
target/release/bramble-events /path/to/match
python3 analysis/events.py /path/to/match
```

The extractor verifies the format, build fingerprint, initial and round state
hashes, action results, pre-fight boards and game completion using the engine's
record replay. It publishes `events.jsonl.gz` only after every record has passed.
Add `--example` to print the first Gorger eat and sale with both board snapshots.
The extractor also prints the final-board Gorger reconciliation. A seat's final
board is the board at its last pre-fight checkpoint, as in `games.jsonl`.

Each line carries `type`, `game`, `round` and `seat`.

- `eat` gives the eater, the eaten unit, the permanent Attack and Health
  `gain`, and `trigger`. Eaten units carry both displayed `stats` and
  `own_stats`. Eat uses own stats, which exclude the slot and auras.
- `slot_growth` gives the slot, signed Attack and Health `amount`, source
  unit, trigger and whether the growth is permanent. Combat rows carry
  `fight_players`. A ghost row carries its owner's seat and `ghost: true`.
  Combat sources carry the game UID for units that came from recruit, or a
  fight-local UID for combat summons. Colour Ensign's fight-only slot copy
  also appears here. Keyword-only changes are excluded.
- `sale` gives the unit sold, direct sale `gold`, first board round and
  number of round boundaries crossed on the board. A unit sold in the same
  round it entered has `rounds_on_board: 0`. `fed` lists the eat and slot
  growth caused by that sale.
- `unit_round` records each Gorger, Glutton, Colour Sergeant and Sergeant
  Major observed on the recruit board during a round, once per game UID.
  It supplies denominators including units that never triggered and units
  sold or tripled away before combat.

When a Sergeant Major amplifies a slot buff, `amplification` gives the extra
stats and all sources tied for the strongest give-time multiplier. The
Python report credits the printed increment to the direct source and
splits the extra evenly across tied sources. Ghost rows are excluded from
team totals.

The Python report prints a Markdown summary and writes `events.json`,
including by-round results and 95% intervals clustered by seed pair. Each
by-round per-game rate uses games that reached that round. Per-unit rates
use the relevant unit-round observations. Attack plus Health is reported as
total stats. The denominators and contributing pair counts are included.
