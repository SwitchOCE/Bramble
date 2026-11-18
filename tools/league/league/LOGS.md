# Match output, file by file

`league match ... --out <dir>` writes these. Every file except `cpu.jsonl` and `timing.json`
is byte-identical for the same seeds, bots, content and `--secret`, at any `--threads`, as
long as no seat's result depends on its CPU clock (a bot that reads `clock_left_ns` to stop a
search, or a clock-out, can change its own play from run to run). JSON lines are in game order.

Seats are player ids 0..7. A game index `g` plays seed line `g / 2` of the seeds file; odd `g`
is the same seed with the colours swapped.

## `records/game-<g>.jsonl`

Each game as a format-2 record, the same lines `GameRecord` writes: `header` (with the pinned
GDScript build's fingerprint, `league/build.json`), then per round `start`, every `act`, each
`end`, `fight_boards`, `finish`. `scripts/records.sh record=<file>` replays it in GDScript;
`target/release/bramble-replay replay --record <file>` in Rust.

## `games.jsonl`: one line per game

```
{"game": 0, "seed": "123", "swapped": false, "rotation": 5, "rounds": 17, "round_limit_hit": false,
 "seats": [ {seat line} x 8 ]}
```

A seat line:

| Field | Meaning |
|---|---|
| `seat`, `colour`, `bot` | player id, `red`/`blue`, registered bot name |
| `place` | final placement, 1..8 |
| `clock_out` | null, or `{round, call, used_ms}`: the call (`new_bot`, `choose`, `report`) that ended over the clock. Its result was discarded; SimpleBot played the rest |
| `panic` | null, or `{round, call, message}` (message with file:line) |
| `fault` | null, or `{round, index, legal}`: an index outside the legal list |
| `refused`, `last_refusal` | actions the engine refused (the turn then ends, as `Bot.take_turn`) |
| `final_board` | the board at the seat's last fight: `[{card, golden, slot, attack, health}]` |
| `main_tribe` | of the final board: most units; ties to higher total attack+health of that tribe's units, then the name. A unit of tribe `All` counts for every tribe. `null` with no tribal unit |
| `commit_round` | first round with 4+ units of the final main tribe, or null |
| `pivots` | `[{round, from, to}]`: after the commit round, a round whose main tribe (with 4+ units) differs from the last such main tribe |
| `rounds` | per round the seat was alive, after all turns and before the fights: `{round, tribes: {tribe: units}, attack, health, tier, gold_left, triple, golden, slot_buff}` |

In `rounds`: `attack`/`health` are board totals (unit attack and health as the engine reports
them, slot buffs included); `gold_left` is gold unspent at the end of the turn; `triple` is a
`triple` event for the player that round; `golden` means the number of golden cards held (board
and hand) went up since the last round; `slot_buff` means the slots' state (stats or keywords)
changed since the last round.

## `decisions.jsonl.gz`: one line per decision

Every decision every seat made, with the full list of legal actions it chose from, in the
engine's order:

```
{"game", "seat", "colour", "bot", "by": "bot"|"fallback", "round", "step", "gold", "tier",
 "legal": [{"type", ...the action's fields..., "card", "price"}], "chosen": index, "result"}
```

- `legal` entries carry the action's own fields (as in the record) plus `card`: the card bought,
  sold, played, picked, or whose ability it is. Buys also carry `price`. Moves, refresh, freeze,
  upgrade and end turn have no card.
- `by` is `fallback` once the seat's bot has clocked out, panicked or faulted and SimpleBot
  plays on.
- `step` counts decisions within the seat's turn, from 0. `result` is the engine's answer to
  the chosen action: empty when it was accepted.
- The lines match the record's `act` lines one for one, in game order.

The file is gzipped (`gzip -n`, so it stays byte-identical) when the match ends, from about
1.7 GB to about 40 MB for 1,000 games. Read it with `zcat` or Python's `gzip.open`.

## `cpu.jsonl`: one line per game (not deterministic)

`{"game": g, "seats": [{"seat": 0, "cpu_ms": 41.2}, ...]}`: each seat's thread CPU time spent in
its bot (construction, every `choose` and `report`, and its Sim work), the fallback bot excluded.

## `shops.jsonl`: one line per shop a bot saw

A new line starts at the seat's first decision of each turn (`reason: "turn_start"`), after a
refresh (`"refresh"`), and whenever the shop changed other than by the bot buying from it
(`"changed"`: an ability, a Discover, an upgrade that changed it). While a Discover is pending
no shop line is started (those decisions are in `discovers.jsonl`).

```
{"game", "seat", "colour", "bot", "round", "reason", "gold", "tier",
 "offers": [{"card", "spell", "index", "buyable"}], "bought": [{"card", "spell", "index"}]}
```

`buyable` is true when a buy of that slot was in the legal list when the shop was seen:
affordable, with room in the hand. `bought` lists what the seat bought from this shop before it
changed.

## `discovers.jsonl`: one line per Discover choice

`{"game", "seat", "colour", "bot", "round", "options": [card ids], "pick": index, "card": id}`.

## `reports.jsonl`: one line per `report()` that returned something

`{"game", "seat", "colour", "bot", "round", "kind": "shop"|"discover", "offered": [card ids],
"strategy", "values": [[card id, value], ...]}`. `report` is called (on the seat's clock) when a
shop line starts and at each Discover choice. Values are on the bot's own scale.

## `summary.json`, `timing.json`, `private/secret.txt`

`summary.json`: games, bots, clock, content, each colour's average placement over all its
seats, and the gap. `timing.json` (not deterministic): wall seconds, threads, seconds a game.
`private/secret.txt`: the match secret the bots' seeds come from (see README). Don't give it to
the teams; with it, the bots' seeds of every game can be worked out.

## `analysis.json` (written by `league analyze <dir>`)

The score with 95% intervals over the seed pairs, placement by seat and by colour, and the
health counts. See README.
