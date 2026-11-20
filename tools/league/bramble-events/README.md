# League replay events

Build `bramble-events` from the league workspace. The extractor uses the checkout's
frozen content and the system's `gzip`. Give it a completed match directory.

```sh
target/release/bramble-events /path/to/match
python3 analysis/events.py /path/to/match
```

The extractor verifies the format, build fingerprint, initial and round state
hashes, action results, pre-fight boards and game completion using the engine's
record replay. It reconciles Gorgers at pre-fight checkpoints and publishes
`events.jsonl.gz` only after every check passes. On failure, the extractor exits
with an error and leaves any previously verified archive in place. A seat's final
board is the board at its last pre-fight checkpoint, as in `games.jsonl`.

Each line carries `type`, `game`, `round` and `seat`.

- `eat` gives the eater, the eaten unit, the permanent Attack and Health
  `gain`, and `trigger`. Eaten units carry both displayed `stats` and
  `own_stats`. Eat uses own stats, which exclude Renown and auras.
- `sale` gives the unit sold, direct sale `gold`, first board round and
  number of rounds since it first entered the board. A unit sold directly
  from hand without ever entering the board has `board_since_round: null`
  and `rounds_on_board: 0`. `fed` lists the eat caused by that sale.
- `unit_round` records each Gorger, Glutton, Colour Sergeant and Sergeant
  Major observed on the recruit board during a round, once per game UID.
  It supplies denominators including units that never triggered and units
  sold or tripled away before combat.

The Python report prints a Markdown summary and writes `events.json`,
including by-round results and 95% intervals clustered by seed pair. Each
by-round per-game rate uses games that reached that round. Per-unit rates
use the relevant unit-round observations. Attack plus Health is reported as
total stats. The denominators and contributing pair counts are included.
