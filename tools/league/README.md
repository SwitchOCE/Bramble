# Bramble's rules engine in Rust, and the league harness

A bit-exact Rust port of the GDScript rules engine (`src/core`, `src/content`, `src/game`) at
the build pinned in `docs/workstreams/bot-league/run-notes.md`, and the match harness the bot
league runs on. The plan is `docs/workstreams/bot-league/brief.md`.

The port plays exactly like GDScript on everything checked: 1,000 GDScript games replay with
every state hash equal, Rust games replay in GDScript, and 100,000 fights give the same full
state. The figures are in the run notes.

```
tools/league/
  bramble-engine/   the engine, file for file like the GDScript (DESIGN.md: conventions)
  bramble-replay/   replays a GDScript record and checks every hash; dumps any checkpoint
  bramble-fight/    runs fight cases (fights/FORMAT.md) and compares full states
  league-api/       what a bot sees: Bot, BotView, Sim, Sandbox, Action, Report
  league/           the harness binary: match, analyze, selfcheck, check-crate, bench
                    (league/README.md: commands, clock, seeds, crate rules; LOGS.md: log formats)
  bots/             the bot registry, baselines' test bots and planted cheat crates
  gd/               GDScript tools that make the reference data (records, fights, oracles)
  fights/           how the 100,000 fight cases were made and checked
  proof/            scripts that rerun the port checks
  vendor/           every Rust dependency, so builds run offline
```

[PORTING.md](PORTING.md) holds the porting rules. Read it before changing the engine.
[CHECKS.md](CHECKS.md) is the skeleton worker's hand-off, kept as history.

## Build

From `tools/league/`, with Rust 1.100 (`tools/versions.env`):

```sh
export PATH="$HOME/.cargo/bin:$PATH"
CARGO_BUILD_JOBS=2 cargo build --offline --locked --release
CARGO_BUILD_JOBS=2 cargo test --offline --locked --release --workspace
CARGO_BUILD_JOBS=2 cargo clippy --offline --locked --all-targets -- -D warnings
cargo fmt --all --check
```

`.cargo/config.toml` replaces crates.io with `vendor/`. Nothing is downloaded.

## Rerunning the port checks (after a port fix)

```sh
timeout 3600 tools/league/proof/recheck.sh            # every check in brief 5b step 2
timeout 1800 tools/league/proof/plant_refresh.sh      # the record checks catch a planted bug
```

`recheck.sh` builds and tests the workspace. Then it runs these checks:
- it replays the 1,000 GDScript records in Rust (`proof/replay_all.sh`);
- it runs the 100,000 fight cases and compares them with the GDScript results;
- it runs the baselines' `selfcheck`;
- it plays 50 Rust games and replays each one in GDScript (`scripts/records.sh`).

It prints one PASS or FAIL line per check. Both scripts read the phase 0 reference data under
`/home/alex/league/` (or `LEAGUE_DATA`).

A planted fight bug needs no copy of the code:
`target/release/bramble-fight --plant-attack lone-hawthorn ...` changes one card's Attack.

## Debugging a hash mismatch

Run Godot from the repository root, always with `timeout -k 10`. If class names aren't cached,
import once: `timeout -k 10 120 godot --headless --import`.

```sh
mkdir -p .copies
timeout -k 10 60 godot --headless --log-file "$PWD/.copies/dump.log" \
  -s res://tools/league/gd/dump_state.gd -- \
  record=/absolute/game.jsonl op=12 out="$PWD/.copies/gd.json"
tools/league/target/release/bramble-replay dump --record /absolute/game.jsonl \
  --op 12 --out .copies/rust.json
python3 tools/league/diff_state.py .copies/gd.json .copies/rust.json
```

Operation zero is the header. `op=N` (or `--op N`) dumps the state after operation N.
`turn=T` (or `--turn T`) dumps it after turn T. With `seed=N` (or `--seed N`) and no record,
the tools dump a fresh game. Both write the exact JSON text the hash is taken over. The diff
tool prints the first JSON path that differs.

## Regenerating the GDScript oracles

These scripts read the pinned game. They never edit its source or card data:

```sh
timeout -k 10 60 godot --headless -s res://tools/league/gd/dump_fields.gd
timeout -k 10 60 godot --headless -s res://tools/league/gd/prove_util.gd -- out="$PWD/.copies/util-raw.json"
timeout -k 10 60 godot --headless -s res://tools/league/gd/prove_planted.gd -- out="$PWD/tools/league/gd/planted_vectors.json"
timeout -k 10 60 godot --headless -s res://tools/league/gd/prove_recipes.gd
timeout -k 10 60 godot --headless -s res://tools/league/gd/prove_content.gd
```

They check:
- the fields of all 62 core classes;
- JSON, Rng and sort, byte for byte;
- the session recipes;
- all 103 cards in plain and golden form.

A changed card Attack can't change the hash of a game that has just started, because no units
exist yet and the hash leaves out the card library. The planted tests check this matches Godot.
