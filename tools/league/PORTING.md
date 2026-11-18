# Porting rules for the Rust engine

Every worker on `bramble-engine` follows these. The approved plan is
`docs/workstreams/bot-league/brief.md`, section 5b. The GDScript engine at the pinned commit
(`docs/workstreams/bot-league/run-notes.md`) is the truth: where the port and it differ, the port
is wrong. Never change anything in `src/`, `tests/` or the card data.

## The bar

The port must give the same SHA-256 state hash as `RecordState.state_hash` at every record
checkpoint, the same refusal strings from `act`, and the same `fight_boards` payloads. "Close" is
a failure. If a field truly can't be matched, stop and say so; don't approximate.

## Shape: mirror the GDScript, file for file

- One Rust module per GDScript file, same names in snake case (`src/core/combat/fight_side.gd`
  -> `bramble-engine/src/core/combat/fight_side.rs`; content mechanics under
  `bramble-engine/src/content/<tribe>/...`). Same function names, same argument order, same
  field names. A reviewer must be able to read the two side by side.
- Translate the logic line by line, in the same order, including loop order, early returns and
  the order of random draws. Don't "simplify" a loop, merge two passes, or reorder hooks.
  Performance comes second to exactness; optimise only after the hashes match, and only where a
  profile says so.
- Keep every comment that states a rule number (`## 9.7.2 step 2 ...`) as a `//` comment.

## Godot semantics the port must copy

- **Objects are shared by reference.** A GDScript `RefCounted` object (Unit, PlayerState,
  CombatUnit, StatBlock, CardHeap, SlotState, BoundMechanic, MechanicParams, Rng, ...) that can be
  reached from two places is `Rc<RefCell<T>>` in Rust (type aliases such as `UnitRef`). Never
  replace a shared object with a copy. `ghost_board = board.duplicate()` is a shallow copy: the
  same unit objects. `ghost_player` is the eliminated player's own object.
- **Arrays and Dictionaries are reference types too.** `var a: Array = x.list` then `a.append(...)`
  changes `x.list`. `duplicate()` is shallow, `duplicate(true)` deep. Copy that behaviour where a
  container is aliased.
- **Dictionaries keep insertion order**, and `erase` keeps the order of the rest. Use
  `indexmap::IndexMap` with `shift_remove`, never `HashMap`, wherever GDScript uses a Dictionary.
- **Loops over an array that changes mid-loop.** `for x in arr` in GDScript iterates by index over
  the live array: an element removed ahead is skipped, one appended is visited. Copy exactly what
  Godot does in each such loop (read Godot 4.7's `for` over Array if unsure).
- **Sorting.** `Array.sort()` and `sort_custom()` use Godot's `SortArray` (introsort, insertion sort
  under 16 elements). Port `SortArray` itself (`core/templates/sort_array.h`, Godot 4.7.2) in
  `util/godot_sort.rs` and use it for every sort, so ties break exactly as in Godot.
- **Integers are 64-bit** (`i64`). Integer division and `%` truncate toward zero like C.
  `mini`, `maxi`, `clampi`, `floori`, `posmod` as Godot defines them.
- **Strings:** `"%d|%s" % [...]`, `str()` and `String(StringName)` give exact text, because seeds
  are derived from it (`Rng.derive`, `Rng.hash32`). StringName and String are both `String` in
  Rust, or an interned id with an exact text form.
- **Variants.** Action dictionaries, results, events and mechanic `raw` dictionaries are
  JSON-shaped Godot Variants. Use one `Variant` enum (Nil, Bool, Int, Float, String, Array,
  Dictionary as IndexMap) for these, with `CoreUtil.to_int` / `to_text` / `to_bool` /
  `to_array` / `to_dict` ported exactly (records give numbers as floats).
- **Random numbers:** `util/rng.rs` is a bit-for-bit port of `Rng` (xoshiro128**, FNV-1a, the
  seeding loop, `range_int` rejection, Fisher-Yates `shuffle`). `Rng._s` is in the hash.

## The state hash

`RecordState.state_hash` is `JSON.stringify(session_state(game)).sha256_text()`.
- `session_state` takes every script variable of GameSession except `SESSION_SKIP`, plus
  `recruit_rng` (Recruit's variables except `session` and `_session_ref`), each through
  `RecordState.value`. Every script variable of every object it reaches is included, private ones
  too: `_next_uid`, `_rr_order`, the pools' `_copies`, `_start`, `_tiers`, `_order`, `Rng._s`,
  MechanicParams' `_ints`, `_texts`, `_kinds`, `_golden_ints`, StatBlock's `UNSET` (-1) values,
  heaps' `_next_n`.
- Each Rust state type has a `to_state(&self) -> Variant` that lists exactly the GDScript script
  variables, by the GDScript names, converted as `RecordState.value` converts them (UnitDef -> its
  id, BoundMechanic -> `{id, params, granted}`, Vector2i -> `[x, y]`, integral floats -> ints,
  dictionary keys -> `str(key)`, null objects -> `null`).
- `util/godot_json.rs` reproduces `JSON.stringify(value)` of Godot 4.7.2 exactly: compact, keys
  sorted the way Godot sorts them, Godot's string escaping, Godot's number formatting (ints,
  floats, `inf`/`nan` if they can occur). Prove it against Godot on real state dumps.
- When a field is added to a GDScript class, the hash changes, so the Rust `to_state` must list
  every script variable; a test compares the Rust field list with Godot's
  `get_property_list()` for each class (`tools/league/gd/`).

## Speed without changing results

Combat event logs and the game log are outside the hash and nothing in the league reads them. The
port may skip building them **only** where no rule reads them (check each place: a rule that
counts events, reads `combat.events.size()`, or reads `fight["after"]` must still see the same
values). Triggers still count against the trigger limits exactly as in GDScript.

## Layout

```
tools/league/
  Cargo.toml          workspace; dependencies vendored in vendor/, builds --offline --locked
  PORTING.md          this file
  bramble-engine/     the port (library)
  gd/                 GDScript tools that drive the pinned game (state dumps, fight runner)
```

`tools/league/` is outside the Godot export; nothing here is loaded by the game. Never edit
`src/`. GDScript tools in `tools/league/gd/` are run with
`godot --headless -s res://tools/league/gd/<tool>.gd -- ...` from the repo root.

## Checks every worker runs before handing back

- `cargo build --offline --locked` and `cargo test --offline --locked` in `tools/league/`
  (with `CARGO_BUILD_JOBS=2`; the machine is shared).
- `cargo clippy` warnings fixed or explained.
- The part's own comparison against GDScript, with the number of cases it ran and one planted
  bug it caught.
- Rust is in `~/.cargo/bin` (`export PATH=$HOME/.cargo/bin:$PATH`).
