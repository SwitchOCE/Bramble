# Bramble Rust engine skeleton

The source build is pinned in `docs/workstreams/bot-league/run-notes.md`.
Read [PORTING.md](PORTING.md) before changing the port, and
[DESIGN.md](bramble-engine/DESIGN.md) for shared references, hook signatures and file ownership.
Gameplay bodies marked `todo!("port ...")` deliberately belong to the next workers.
Full replay currently reaches the `start_round` TODO; header reconstruction is implemented.

From `tools/league/`, using Rust 1.100:

```sh
export PATH="$HOME/.cargo/bin:$PATH"
CARGO_BUILD_JOBS=2 cargo build --offline --locked
CARGO_BUILD_JOBS=2 cargo test --offline --locked
CARGO_BUILD_JOBS=2 cargo clippy --offline --locked --all-targets -- -D warnings
cargo fmt --all --check
target/debug/bramble-replay initial /home/alex/league/records/gd/c0 /home/alex/league/records/gd/c1 /home/alex/league/records/gd/c2
```

`bramble-engine` depends on indexmap and sha2; serde_json is used by tests. All dependencies
and their licenses/checksums are vendored. `.cargo/config.toml` replaces crates.io with vendor.
The source-shaped module nesting, argument counts and explicit defaults have documented
Clippy allowances; other warnings are denied.

## State dumps

Run Godot from the repository root, always with `timeout -k 10`. Use an absolute log path
inside the worktree to avoid writes to the shared Godot user directory. Import once if class
names have not been cached (`timeout -k 10 120 godot --headless --import`).

```sh
mkdir -p .copies
timeout -k 10 60 godot --headless --log-file "$PWD/.copies/dump.log" \
  -s res://tools/league/gd/dump_state.gd -- \
  record=/absolute/game.jsonl op=0 out="$PWD/.copies/gd.json"
tools/league/target/debug/bramble-replay dump --record /absolute/game.jsonl \
  --op 0 --out .copies/rust.json
python3 tools/league/diff_state.py .copies/gd.json .copies/rust.json
```

The header is operation zero. `op=N` / `--op N` includes operation N; `turn=T` / `--turn T`
includes all available operations through turn T. The Godot tool can dump any checkpoint now.
The Rust tool calls the completed replay driver and will support later checkpoints as soon
as the gameplay TODOs are filled. Without a record, `seed=N` / `--seed N` dumps a fresh game.
Both dump tools write the exact JSON text with no trailing newline. The diff tool reports
the first differing JSON path or the first text byte when only formatting differs.

## Regenerating the Godot oracles

These scripts read the pinned game; they never edit its source or card data:

```sh
timeout -k 10 60 godot --headless --log-file "$PWD/.copies/fields.log" \
  -s res://tools/league/gd/dump_fields.gd
timeout -k 10 60 godot --headless --log-file "$PWD/.copies/util.log" \
  -s res://tools/league/gd/prove_util.gd -- out="$PWD/.copies/util-raw.json"
timeout -k 10 60 godot --headless --log-file "$PWD/.copies/planted.log" \
  -s res://tools/league/gd/prove_planted.gd -- out="$PWD/tools/league/gd/planted_vectors.json"
timeout -k 10 60 godot --headless --log-file "$PWD/.copies/recipes.log" \
  -s res://tools/league/gd/prove_recipes.gd
timeout -k 10 60 godot --headless --log-file "$PWD/.copies/content.log" \
  -s res://tools/league/gd/prove_content.gd
```

Godot emits raw low control characters and `\\v`; `gd/util_vectors.json` stores that oracle
with ordinary JSON escapes, preserving each `text` string byte-for-byte after parsing.
The four real-state fixtures were produced by `gd/dump_state.gd` for seeds 1, 42, -8172 and
9223372036854775807. Field tests compare all 62 core classes against Godot property lists,
including actual serialized keys and inherited fields. Static variables are not instance
script variables in Godot. Source coverage also checks every core module and function.
The five recipe headers additionally cover both factories, tribe filtering, stand-in cards,
custom configuration, and signed seed limits; each is also tested with a planted wrong hash.
The content oracle covers all 103 loaded cards, 206 plain/golden unit states, and 274 bound
mechanic metadata rows. It compares the byte count and SHA-256 of the complete JSON document
without committing a second large copy of the card data.

An in-memory card attack change cannot alter an empty initial state's hash. The library is
skipped and no units exist yet. The planted tests agree with Godot on this, detect the attack
change after creating a unit, and detect a card tier change in the initial hash.
