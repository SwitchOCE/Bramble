# Local game records

Every started game from `GameContent.new_session`, `GameContent.new_async_session` and
`ContentSet.session` (the core bot/soak runner) writes one compact JSON-lines file. Raw
`GameSession.create` is the low-level constructor for hand-built rule fixtures; it has no
content recipe and does not record. Use a content factory for games.

Records stay on the PC. Nothing uploads them. Real games default to `user://records/`:

- Windows: `%APPDATA%\Godot\app_userdata\Bramble\records`
- Linux: `~/.local/share/godot/app_userdata/Bramble/records`

Open the Windows path in Explorer, copy the folder, then zip that copy. A game in progress
is included up to its last flushed entry. Files are never silently deleted. Keep the build
that played a game alongside its records: replay uses that build's code and card data.
The Windows build's bundled README also gives the folder path.
GUT redirects every game fixture to `build/test-records` in its pre-run hook; soaks use
`build/soak-records`. These checks never add records to the owner's export folder.

## Replay and checks

From the source checkout used to play the game:

```sh
scripts/records.sh record=/absolute/path/to/game.jsonl
scripts/records.sh games=50 first_seed=1 plant=1
scripts/records.sh games=25 ghost_store=/path/to/store directory=/path/to/output
scripts/records.sh record=/path/to/async.jsonl ghost_store=/path/to/store
```

The second command plays and replays 50 full games with all shipped tribes, mixing FlowBot
and RandomBot seats, across 50 distinct seeds. It prints turns, checkpoints and median file
size. `plant=1` also copies the last record, replaces one turn-2 buy with a freeze, then
requires the checker to identify turn 2 as the first difference. Generated files default to
`build/records`; `directory=/local/folder` changes that. The shell wrapper also fails on
Godot errors, warnings, crashes and timeouts. `check.sh` includes a 2-seed version with the
planted action, as well as the record unit tests.

With `ghost_store`, the generation check runs FlowBot in seat 0 and assigns seven distinct
runs per game from the folder store, rotating through the sorted IDs. It replays each complete
game against the same store and compares every checkpoint.

An exported game includes the replay engine (no development tool or Git required):

```text
bramble.exe --headless -- --replay-record "C:\path\to\game.jsonl"
```

The equivalent source command is `godot --headless -- --replay-record /path/game.jsonl`.
For async records, append `--ghost-store /path/to/store`. The store holds the exact run bytes
at `runs/<first two hex digits>/<id>.json`. Each file's SHA-256 must equal the ID in the
record header. A missing or changed file names the run and fails before turn 1.
A match exits 0 and reports complete or unfinished. A mismatch exits 1 and names the first
differing turn and checkpoint/action. Unsupported formats/builds fail before turn 1.
The log is also in `user://logs/godot.log`. Replay rebuilds a `GameSession` without bots and
without writing another record; callers can inspect the returned session directly.
An unfinished file is explicitly reported as unfinished, even if every available hash matches.

## Format 4

One UTF-8 JSON object per line, appended and flushed as play proceeds:

| `op` | Stored data | Rebuilt data |
| --- | --- | --- |
| `header` | Format, build version/revision/engine/rules hash, seed as decimal text, ordered content folders, lobby tribes, config, initial state hash, `mode` (`live` or `async`) and `runs` (ordered `{seat, id}` entries, empty for live games) | Library, registry, fixed draw weights, players, round-robin order, standing effects, validated run files |
| `start` | Turn number, SHA-256 state hash | Pairings, income, shops, start effects |
| `act` | Turn, live player, action dictionary, result (including refused inputs) | Action effects and RNG draws |
| `end` | Turn, live player | Explicit end-turn calls, including bot action-limit fallback |
| `fight_boards` | Turn, pre-fight payloads for every living seat, SHA-256 state hash, and `run_boards` for async games | Implicit live end turns and run board restoration |
| `finish` | Turn, SHA-256 state hash, game-over flag | Fights, damage, eliminations, ghost selection, placements |

Hashes cover the full persistent rules state at turn start, after every player's end of turn
before combat, and after combat. They include private fields: all players, next UID, pairing
history, recruit RNG words, ghost state, config, run IDs by seat in async games, unit stat layers,
mechanic parameters, counters, slots and heap entry sequence numbers. They exclude UI display,
stateless dependencies whose code/data the build fingerprint identifies, and historical event
and fight logs. Run files are represented in the hash by their IDs. All-live games use the
implicit all-live seat map, preserving their checkpoint hashes. Replay rebuilds full turn
states and combat events from the record.
A different rules fingerprint is refused; changing code or content requires keeping the old
build. Windows packaging stamps the committed revision; workspace runs use `workspace` plus
the fingerprint, so uncommitted rules code still has an identity. Compiled exports and source
checkouts have different fingerprints: use the original executable for exported records.

Each living player's pre-fight payload contains `id`, `tier`, `board` (including empty slots),
`hand` (Reserve), `slots` (each slot's `keywords` and `renown`), `counters`,
`heaps` and `standing`. Units keep card id (`def`), UID,
golden and nondefault origin flags (`bought_copies`, and `copies`, 3 for a tripled golden: the sell value, 4.3.4), changed stat layers, added effects and nonempty counters. The Sentry records remaining Supply in
unit `counters["supply:pigeon_sentry"]`, including zero. Quartermaster-granted Reserve uses the
existing unit `grants` list.
Fixed base/golden stats and card mechanics are rebuilt from the card; `stat_max` comes from
config. Zero layers and unset overrides are omitted (an explicit set-to-zero is retained).
Added own and aura effects use `[id]` or `[id, applied_values]`: only dynamic values, never
parameter schemas, raw/golden templates or inherited card effects. Board index supplies the
unit's slot; hand order is preserved. `FightSnapshot.restore_unit` rebuilds a unit from this
data without allocating a new game UID. When a ghost fights, another payload
has `id: -1`, `of: <eliminated player id>`, its actual saved board and hand and its rules data.
Snapshots are taken after End of Turn and before any fight writes back permanent changes;
they do not alias live objects. This preserves the data for future ghost construction.

For each living run seat, the session restores the saved board and hand before the
`fight_boards` checkpoint and shifts their UIDs by `seat * 1,000,000`. Each async
`run_boards` entry contains `seat`, `run_turn`, and `reason` (`same_turn` or `run_ended`).
The session logs the same data as a `run_board` event. Run seats retain their last fought
board for the stand-in ghost if they are eliminated.

Replay rebuilds the draw tables from the fixed unit and spell weight rows in the header
config and the ordered content recipe. Formats 1 through 3 require the build that wrote them.

Godot reads JSON numbers as floats. Integral values are normalized for board comparison;
the 64-bit seed is text so JSON cannot round it. File names include time, process and a
per-process serial so repeat seeds and simultaneous games do not overwrite each other.
Disk errors populate `GameRecord.error` and emit a Godot error rather than silently claiming
to have saved the game.
