# Bramble's rules engine in Rust, and the league harness

A bit-exact Rust port of the GDScript rules engine (`src/core`, `src/content`, `src/game`) and
the match harness the bot league runs on. Shops draw independently from fixed weights by tier.
Discover uses the same unit weights and excludes cards already in the current offer. Format 4
records store the unit and spell weight rows in the header config. The GDScript fingerprint
is pinned in [`league/build.json`](league/build.json). The plan is `docs/workstreams/bot-league/brief.md`.

The port plays exactly like GDScript on everything checked: 1,000 GDScript games replay with
every state hash equal, Rust games replay in GDScript, and 100,000 fights give the same full
state. The figures are in the [dev reference proof](bramble-engine/src/content/badger/PROOF.md#dev-reference-at-6fe0439c).

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
CARGO_BUILD_JOBS=8 cargo build --offline --locked --release
CARGO_BUILD_JOBS=8 cargo test --offline --locked --release --workspace
CARGO_BUILD_JOBS=8 cargo clippy --offline --locked --all-targets -- -D warnings
cargo fmt --all --check
```

`.cargo/config.toml` replaces crates.io with `vendor/`. Nothing is downloaded.

## Rerunning the port checks (after a port fix)

```sh
export LEAGUE_DATA=/home/alex/engine-data/dev-rework
JOBS=6 timeout -k 10 3600 tools/league/proof/recheck.sh
JOBS=6 timeout -k 10 1800 tools/league/proof/plant_refresh.sh
```

`recheck.sh` builds the workspace and then runs these checks:

- Replay the 1,000 GDScript records in Rust (`proof/replay_all.sh`).
- Compare all 100,000 fight outcomes and full state strings with GDScript.
- Run workspace tests, including the small Badger and rework fight vectors.
- Run the mixed-baseline and TribeBot `selfcheck`.
- Play 50 live Rust games and replay each one in GDScript.
- Play 50 async Rust games and replay them in Godot with `--ghost-store`.
- Play 25 async Godot games and replay them in Rust with `bramble-replay replay --record FILE --ghost-store DIR`.
- Swap a run ID and change a run byte to prove Rust replay rejects both.

The record and fight comparisons must pass before the bot-driven tests start.

It prints one PASS or FAIL line per check. Use the same `LEAGUE_DATA` for the refresh and proof.
The scripts retain their phase 0 default for existing league runs.

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

Run from the repository root after a GDScript rules or card-data change.

```sh
export LEAGUE_DATA=/home/alex/engine-data/dev-rework
JOBS=6 timeout -k 10 3600 tools/league/proof/refresh_reference.sh "$LEAGUE_DATA"
JOBS=6 timeout -k 10 3600 tools/league/proof/recheck.sh &&
  JOBS=6 timeout -k 10 900 tools/league/proof/smoke_final_bots.sh
```

The smoke plays the final league bots (`bots/red`, `bots/blue`), unchanged, for 200 games on the
1 s clock and fails on any clock-out, panic, fault or refused action.

The refresh uses the current checkout's GDScript. It generates 1,000 FlowBot and RandomBot
games (seeds 1–1000), 200 TribeBot games (seeds 1–200), 100,000 mutated fights with full
GDScript outcomes, and the 25 seeds for the Rust-to-GDScript proof. It also generates three stand-in records for
the optional Cargo self-check. It rewrites the Rust test
fixtures for script fields, initial states, session recipes, card data, utility functions,
recruit actions and planted changes. It pins the build fingerprint from a generated GDScript
record header in `league/build.json`. Review the resulting fixture and pin changes together.

TribeBot was retired as a player on 20 November 2026; its 200 games remain only as the engine
check above. Its tribe-locked soak and the frozen v1 were removed
([archive entry](../../docs/archive/README.md)).

The optional directory defaults to `LEAGUE_DATA` or `/home/alex/engine-data/dev-level`.
Use a dedicated reference directory with several GiB free for the corpora and temporary fight
shards. The script rejects paths into the live `/home/alex/league` directory. Reference logs
are kept under the staging directory named at startup. The refresh can take longer than the
proof, since it runs and records every case in Godot.

A changed card Attack first appears in the state hash once a unit of that card exists.
The planted vectors exercise that boundary and show a changed card tier affecting the first
shop draw while leaving the initial hash equal.
