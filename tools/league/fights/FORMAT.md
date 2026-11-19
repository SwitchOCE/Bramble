# Isolated fight cases, version 1

The oracle is the pinned GDScript engine, unchanged. These cases exercise one fight and its
permanent write-back, damage and `after_fight` hooks. They are synthetic pre-fight states made
by mutating real format-2 `fight_boards` payloads, not continuations of the source games.
There is no recruit phase, End of Turn, elimination, matchmaking or placement pass.

## Input JSONL

One UTF-8 JSON object per line, terminated by a newline:

```json
{"id":0,"game_seed":"-9223372036854775808","round":9,"a":{},"b":{},"mutations":["golden:a:sentry=true"]}
```

The `{}` placeholders above must be complete player payloads. The required keys are `id`
(unique nonnegative integer), `game_seed` (canonical signed int64 decimal **string**), `round`
(integer 1..50), `a`, `b`, and `mutations` (array of descriptive strings). Seeds have no leading
zeroes or plus sign; zero is `"0"`. All JSON numbers must be integers exactly representable as
IEEE-754 doubles (absolute value at most 9,007,199,254,740,991). The seed uses text to avoid
that restriction. Unknown top-level fields do not affect the fight.

`a` and `b` have exactly the shape emitted by `RecordState.fight_players` for living players:

| Field | Shape and restoration |
| --- | --- |
| `id` | Distinct seat indices 0..7. No ghosts (`-1`). Preserve the input seat indices; do not remap to 0 and 1. |
| `tier` | Integer 1..6. Set `PlayerState.tier`. |
| `board` | Seven entries, null or `FightSnapshot.unit` dictionaries. Restore each non-null entry with `FightSnapshot.restore_unit(saved, game, slot_index)`, preserving empty positions. |
| `hand` | Zero to seven `FightSnapshot.unit` dictionaries, no nulls. Restore with `FightSnapshot.restore_unit(saved, game, -1)`, preserving order. Ordinary units, Reserve units and valid spell snapshots are allowed here. |
| `slots` | Seven objects `{attack, health, keywords}`. Create/set `SlotState.attack`, `.health` (nonnegative integers) and `.keywords` (ordered `Array[StringName]`). Keyword ids must exist and require no parameters. |
| `counters` | Dictionary of integer values. Deep copy to the player; retain key insertion order. |
| `heaps` | Dictionary of heap name to `{entries, _next_n}`. Create `CardHeap` objects, preserving names and entry order. Each entry is `{id: <card id>, tier: <card tier>, n: <sequence number>}`. Convert `id` to `StringName`, `tier` and `n` to int. Names must have a registered content prefix or `core_`. Card ids must be non-spell cards in the library, with the card's exact tier. Each heap's `n` values strictly increase, are positive and below `_next_n`; gaps are valid. Restore `_next_n` exactly, including for empty heaps. |
| `standing` | Ordered array of `{id, params, granted}` as serialized by `RecordState.value(BoundMechanic)`. Replace the factory's standing array, do not append to it. See below. |

All eight payload fields are required; empty arrays/dictionaries are explicit. Health, armor,
gold and other recruit fields are **absent from the payload** and use the defaults below.
Do not infer them from the source record or introduce extra payload fields for them.

For each standing effect, look up `id` in the registry and construct a `BoundMechanic` with
that mechanic, the saved `granted` boolean and a new `MechanicParams`. Restore the params'
`golden` boolean and all four dictionaries (`_ints`, `_texts`, `_kinds`, `_golden_ints`)
exactly. Integer parameter values/kinds remain integers, text values remain strings. Do not
use `bind_given` or reparse applied values: these are full serialized parameter internals,
not the compact unit-grant representation.

Unit snapshots have required `def`, positive `uid`, and boolean `golden`. Every board and
hand UID must be unique **across both players**. `FightSnapshot.restore_unit` supplies all
omitted defaults from `Unit.create`: card mechanics, golden base stats, `stat_max`, unset
set-layers, zero delta layers, origin flags/copy counts, and empty counters/grants. It applies
optional `stats`, `bought_copies`, `pool_copies`, `counters`, `turn_counters`,
`grants`, and `aura_grants` as that function does. `stats` keys must be in
`FightSnapshot.LAYERS`. Grants are `[id]` or `[id, applied_values]`; aura grants bind as given,
and parameterized own grants bind as given without doubling for the recipient's golden flag.
An own grant `[id]` uses `Unit.grant`, which binds with the recipient's golden flag and skips
duplicates. These details matter to the complete state hash.

## Session construction (normative)

1. Load `GameContent.load_default()` once per process (all five tribes, default library,
   registry and stand-in spells). For **every case**, create a fresh
   `content.new_session(int64(case.game_seed))`. Do not start a round or replay source actions.
2. Set `game.keep_fight_events = false` and `game.round_number = case.round`.
3. Restore player `a.id`, then player `b.id`, as above. Keep the other six players and their
   factory-provided standing effects intact. Do not remove payload cards from any pool.
4. Start `_next_uid` at its fresh-session value (1). After every restored board/hand unit,
   assign `_next_uid = max(_next_uid, unit.uid + 1)`. The final value is at least one greater
   than every input UID, including hand units. Do not allocate UIDs during restoration.
5. Set `game.pairings = [[a.id, b.id]]`. Do not append opponent history or advance `_rr_index`.
6. Call `game._fight(a.id, b.id)` **once**, directly. Never call `start_round`, `end_turn` or
   `finish_round`: the payload was already captured after End of Turn. `_fight` handles loss
   damage and both players' `after_fight` hooks. Do not call `_eliminate` or `_check_end`.
7. Immediately serialize `JSON.stringify(RecordState.session_state(game))`. This exact string
   is the comparison state, including all eight seats, pools, RNG caches and private fields.

Defaults, beyond the explicitly restored fields:

- All eight players start with `health = 40`, `armor = 0`, `gold = 0`, `gold_next_turn = 0`,
  `turns_waited = 0`, `refreshes_paid = 0`, `freezes_used = 0`, `frozen = false`,
  `alive = true`, `turn_ended = false`, `eliminated_round = 0`, `placement = 0`.
  Shop arrays, discover arrays/queue, hands and opponent histories are empty. Unrestored
  players have tier 1, seven null board slots, seven zero/empty slot states, and empty
  counters/heaps. Their standing effects are those supplied by the default factory.
- `config` is an unmodified `GameConfig`; geometry is four front and three back slots.
  Unit/spell pools are fresh, complete default pools with their factory insertion order,
  tiers, `_copies`, `_start` and `_order`. No shop draws occur.
- `seed_value` is the case seed; `_rr_order` is the factory's seed-derived shuffle,
  `_rr_index = 0`, `_any_eliminated = false`, `over = false`. Ghost board and hand are empty,
  ghost tier is 1, ghost id/of is -1, and ghost player is null. Recruit RNG caches start empty
  (the `after_fight` contexts initialize both participants' effect RNG streams even when no
  ability fires; hooks may also draw from or populate these caches during `_fight`).
- Record recipe/display/dependencies stay as the factory created them, and `record` is null.
  No record file is opened because no round starts. These fields and event/fight logs are
  excluded by `RecordState.SESSION_SKIP`. The engine still builds temporary `Combat.events`;
  `keep_fight_events = false` prevents retaining them in the session's fight history. This
  runner does not override or patch combat to suppress their construction.

The current defaults are listed to make cross-engine construction explicit. The pinned
engine's constructors and `RecordState` remain authoritative; a content/rules change needs
a fresh corpus/proof. This format does not assert that synthetic boards are recruit-reachable.

## Output JSONL

Exactly one object per selected input line, in input order:

```json
{"id":0,"winner":1,"loser":3,"damage":10,"reason":"board_empty","state":"{...}","hash":"<64 lowercase hex digits>"}
```

- `winner` is the combat **side index**: 0 for `a`, 1 for `b`, -1 for a tie. It is not a seat id.
- `loser` is the losing **player id**, or -2 for a tie (the `_fight` convention).
- `damage` is `_fight`'s total damage before armor absorption. `reason` is the combat halt
  reason (`board_empty`, `no_attacks`, `attack_limit`, or `trigger_limit`).
- `state` is a **string**, not a nested JSON object. Its bytes are precisely the UTF-8 encoding
  of `JSON.stringify(RecordState.session_state(game))`, with Godot's default key sorting,
  escaping and numeric formatting. `hash` is SHA-256 of these bytes, lowercase hex. Do not
  parse/reserialize this string before hashing or comparing. Compare winner/loser/damage/
  reason, the state string, and its hash. Combat event logs are never compared.

A case that cannot be built produces `{"id":0,"error":"a: duplicate uid 1"}` (example).
Malformed JSON/non-object lines use `id: -1` and include the one-based line number in the
error. Errors do not stop later cases; file/content/usage failures exit 2. The generator drops
and counts error results, records full rejected candidates and reasons, and generates
replacements until the requested count is accepted. Godot script errors, warnings, crashes,
timeouts, missing results or mismatched ids fail the generation job; they are not silently
treated as valid case results.

## Commands and reproducibility

From the worktree root (every Godot process must have a time limit):

```sh
timeout -k 10 14400 godot --headless -s res://tools/league/gd/fight_run.gd -- \
  cases=/home/alex/league/fights/cases.jsonl out=/home/alex/league/fights/gd-part.jsonl \
  first=0 count=33334
```

`first` is a zero-based **physical line offset**, not a case id. `count` is a number of lines;
omitted or -1 reads to EOF. A final newline does not create an extra case. Invalid nonfinal
blank lines are error cases. The runner loads content once, streams input/output, flushes
every 1,000 results, and reports elapsed microseconds and microseconds/fight on stderr.
Use an absolute `--log-file` path in restricted environments if the default Godot user log
directory is not writable. If classes do not resolve, run `godot --headless --import` first
with a time limit and writable XDG config/data directories.

Generate and validate (run long jobs in the background with an outer time limit):

```sh
nohup timeout -k 10 43200 python3 tools/league/fights/make_cases.py \
  --count 100000 --seed 20261118 --jobs 3 \
  --out /home/alex/league/fights/cases.jsonl \
  --results /home/alex/league/fights/gd.jsonl > build/league-fights/make.log 2>&1 < /dev/null &
```

The default source directories are `/home/alex/league/records/gd/c0`, `c1`, `c2`.
`--records <dir>...` overrides them. The generator snapshots each sorted source file's complete
line prefix, ignores/counts trailing partial lines and ghost payloads, and indexes non-ghost
payloads by tribe and turn. Each case cycles its first requested tribe, samples a turn
uniformly from that tribe's available turns, then a real payload in that bucket. The second
payload comes from a different record and turn. Source paths/turns are recorded in `pair:`
mutation strings; colliding player ids are repaired and reported.

The generator forces one of six mutation kinds per case, cycles through them, and independently
adds each kind with probability 0.45. Mutations execute in fixed order: swap board units,
toggle golden, change slot stats (0..40), toggle a parameterless slot keyword, resize Compost
(remove entries or add 1..20 valid unit entries), resize the hand (remove cards or add real
Reserve snapshots up to seven cards). A swap on an empty board uses a recorded donor unit.
Golden toggles preserve explicit recorded stat overrides; omitted base layers rebuild with
the new golden flag. All board/hand UIDs are then renumbered consecutively, `a` board, `a`
hand, `b` board, `b` hand. Case seeds span signed int64; the round is one of the source turns.

`cases.report.json` beside the corpus records the RNG seed, source paths, consumed byte
lengths, SHA-256 of those prefixes, build fingerprints, source bucket counts, rejected reasons,
accepted coverage, and shard timings. Pass `--manifest <previous cases.report.json>` to reuse
exactly those source prefixes even after more records appear or files grow. Reusing that
manifest, seed and count with the same script, content and Python RNG implementation reproduces
the cases. Reports measure cases containing each tribe in either board/hand, golden units,
nonempty heaps/hands, native Reserve cards in hand, slot buffs/keywords, and cases per mutation
kind. The `reserve_hands` feature counts hands containing a card whose definition has Reserve;
it does not additionally count ordinary hand units that the Colonel makes eligible in combat.

Validation allows up to eight concurrent processes and at most 35,000 cases per process.
`--jobs` defaults to three. `--timeout` sets the time limit per process and `--batch-size` controls how many cases are generated at once. Shard
files, logs and `rejected.jsonl` live beside the corpus in `cases.work/`; accepted output is
concatenated in original order. Rejected candidate ids can leave gaps in accepted ids.
Neither cases nor state dumps belong in Git.

Run the bounded runner contract checks separately, when a Godot process slot is free:

```sh
timeout -k 10 600 python3 tools/league/fights/check_runner.py
```

They check known empty-board outcomes/damage, signed int64 seed boundaries, restoration of
stat layers/origin flags/standing parameters/heaps/slots, UID allocation above hand UIDs,
the absence of a second Sentry End of Turn buff, malformed input rejection followed by valid
cases, and line slicing across a multimegabyte UTF-8 prefix. Every spawned Godot has its own
90-second limit. These fixtures are checks of the importer, not members of the real-record
proof corpus.
