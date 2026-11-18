# Skeleton handoff — 18 November 2026

Source: `c0d7db795bcb63ff38de8a5da941f96fb00aeba3`, Godot
`4.7.2.stable.official.ed1daf0bf`, Rust/Cargo 1.100.0. Only `tools/league/**` and the
league target entry in the root `.gitignore` changed. No push or PR was made.

## Results

| Check | Result |
| --- | --- |
| `CARGO_BUILD_JOBS=2 cargo build --offline --locked` | Pass |
| `CARGO_BUILD_JOBS=2 cargo test --offline --locked` | 20 passed, 0 failed |
| `CARGO_BUILD_JOBS=2 cargo clippy --offline --locked --all-targets -- -D warnings` | Pass |
| `cargo fmt --all --check`, `git diff --check` | Pass |
| Fresh archive of committed workspace, empty `CARGO_HOME`, offline locked build | Pass; no registry cache required |
| Record headers in `/home/alex/league/records/gd/c0`, `c1`, `c2` | **1,000 / 1,000 initial hashes matched** |
| Additional Godot header recipes | 5 / 5: game/core, subsets, stand-ins, custom config, signed seed limits |
| Real initial-state JSON | 4 / 4 byte equal; 69,131 bytes total |
| JSON edge oracles | 4 / 4: escapes/control characters, Unicode keys, 19 numeric cases, nested empty containers |
| RNG oracle | 30 / 30 streams: six seeds, four derived labels plus direct seeding; words, draws, ranges and shuffles |
| Godot tied sort oracle | 4 / 4 arrays: sizes 17, 24, 64, 257 |
| Godot script field oracle | 62 / 62 core classes, 287 / 287 fields; declarations and serialized keys |
| Core source coverage | 62 / 62 source modules, 527 / 527 function names/signatures present |
| All loaded card states | 103 cards; 206 plain/golden units; 274 bound metadata rows; 188,923 JSON bytes matched |
| Record checkpoint dump tools | Header dump byte equal (17,277 bytes); Godot turn-1 dump matches recorded finish hash |
| Diff helper planted field | Correctly identifies `$["players"][0]["health"]` |

The real-state seeds are 1, 42, -8172 and 9223372036854775807. The all-card JSON digest is
`28048266412c11393cad337cdd5497bf2606029624e8bcb692d6ca852ceb9f91` in both engines.
The source-shaped module nesting, argument counts and explicit default declarations have
documented Clippy allowances. All other Clippy warnings are denied.

## Acceptance conflict: planted attack in an empty initial session

The requested attack-change initial-hash failure cannot occur in the pinned engine.
`RecordState.SESSION_SKIP` excludes the library, CardPool stores ids/counts/tiers/order,
and newly created players have no units. An in-memory attack change therefore leaves the
true initial hash unchanged. Changing the hash schema to make this fail would break the port.

`gd/prove_planted.gd`, `gd/planted_vectors.json` and `tests/initial_states.rs` prove the source
behavior and match its exact hashes: attack +1 is detected after a real unit is instantiated;
card tier +1 is detected immediately in the initial hash. Every additional recipe test also
rejects a planted wrong initial hash. No other field or hash mismatch remains.

## What the next workers use

[DESIGN.md](bramble-engine/DESIGN.md) defines the signatures and file boundaries. In particular:

- Objects and containers alias via `Rc<RefCell<_>>`; `.duplicate()` copies containers shallowly.
- Recruit functions receive `&RecruitRef`; mutating session flow functions receive `&GameSessionRef`.
  Release RefCell borrows before callbacks. Combat helpers receive explicit `&mut Combat`.
- Mechanic hooks receive mutable phase contexts, nullable owning-unit handles for standing
  effects, and `&MechanicParamsRef`. `Hook` plus `HookArgs` replaces dynamic notification calls.
- Aura hooks receive `&mut AuraContext`; stat reads set `read_stats`.
- There are 120 registered mechanic implementations (100 content, 20 built-ins), plus six
  mirrored content helpers. Their metadata is ported; gameplay overrides are clearly marked.
- `ToState::script_state` exposes complete script fields for the field oracle; `to_state`
  performs the source's special UnitDef-id and BoundMechanic conversions.

The replay phase/operation validation and driver are implemented. Full replay and later Rust
checkpoint dumps await the deliberate gameplay TODOs in combat, recruit, session round flow
and mechanics. Record writing, FightSnapshot restore and presentation-only GameContent helpers
also retain explicit TODOs. No full-game parity or combat result claim is made at this stage.

Implementation commits before this report: `37a4c65a`, `84fd33a3`, `dff72b08`, `94e3fbf9`,
`c426808e`. There were no denied actions. Git index writes and installation of the missing
rustfmt/Clippy components required sandbox escalation and were approved. Temporary comparison
copies and tool caches are confined to the ignored `.copies/` directory.

## Combat tranche

See [the combat proof](bramble-fight/RESULTS.md): 20,000 stand-in fights match complete JSONL
byte for byte, repeat output is identical, and the in-memory Attack plant is caught by 8,870
cases. Build/test/Clippy pass offline/locked (38 tests); source files and card JSON are unchanged.

# Recruit handoff — 18 November 2026

The recruit worker ported action handling, Discover/triples, recruit hooks and core recruit
effects, rule-query borrowing, legal-action order, session round flow, matchmaking, placement
and ghost handling, and format-2 record writing. Shared gameplay signatures are unchanged.
`RecordState` and the rules-affecting `GameContent` bodies were already complete. The writer
proof also corrected the skeleton's informational engine label to Godot's actual
`4.7.2-stable (official)` string. No `src/`, root `tests/`, `scripts/`, `addons/` or card data
changed. Presentation-only `GameContent` TODOs remain outside the rules port.

Combat branch `league/p0-combat` at `de374e27` is integrated by merge `283f9e4a`; both interface
sections in DESIGN.md were preserved. No combat implementation was changed by the recruit
worker, and no combat mismatch was found.

| Recruit check | Result |
| --- | --- |
| GDScript stand-in generation and `RecordReplay.read` | **500 / 500 games**, seeds 1–500; **23,829 checkpoints**, **7,943 turns** |
| Rust turn-1 replay | **500 / 500 records**, **1,000 state checkpoints**, **27,180 act results**; all `fight_boards` payloads equal |
| Ordered `LegalActions.of` at every turn-1 bot decision | **27,180 / 27,180 lists equal**, including order |
| Rust complete replay after combat merge | **500 / 500 records**, **23,829 / 23,829 checkpoints**, **491,019 act results**, every fight payload equal |
| Crafted recruit oracle | **4 cases / 56 checkpoints**: full state SHA, ordered legal-action SHA, exact result; 19 actions (9 accepted, 10 refused) |
| Session oracle | **9 full state hashes**; tied eliminations/pairings/placements, pool returns, ghost hand and shallow object/container aliases |
| Recruit-context oracle | Two state hashes, player-view SHA and ordered-action SHA match Godot |
| Rust-written full game -> GDScript | **1,051 / 1,051 operations** equal to the source record; GDScript validates all **48 checkpoints**, final state hash `f340e6e9d417e5f00180479d865b9437b90ec86346146353c39e57da7f8519b6` |
| Single-tribe recipe (`folders=shared,badger`) | GDScript game/replay: **15 turns / 45 checkpoints**; Rust reconstructs the same recipe and matches the **initial hash**. Tribe gameplay remains the tribe worker's proof. |
| Planted `Rules.refresh_cost` +1 | Rejected by production `bramble-replay` on **turn 1, act operation 31** (zero-based; line 32), player 3's buy after refreshing: expected `""`, actual `"not enough gold"`; before the `fight_boards` hash. Restored code passes. |
| Offline locked Cargo gates, `CARGO_BUILD_JOBS=2` | Build pass; **42 tests pass**; Clippy all-targets with `-D warnings` pass |
| Formatting and whitespace | `cargo fmt --all --check`, `git diff --check` pass |

Records and ordered legal-action sidecars are outside Git at
`/home/alex/league/records/standin/`. Exclude `*.legal.jsonl` from ordinary record globs.
The generator accepts `folders=shared,badger` (ordered `src/content` folder names), with an
empty list loading stand-ins. Every header carries the content paths for the replay factory.
The 500-game run used even-seat FlowBot, odd-seat RandomBot, and
`Rng.derive(seed, "bot:%d" % seat)` exactly as the source record check does.

Reproduce from the worktree root after the required bounded headless import:

```
timeout -k 10 7200 godot --headless -s res://tools/league/gd/standin_records.gd -- games=500 seed=1 out=/home/alex/league/records/standin/ folders=
```

From `tools/league`, build the optimized comparison tool and replay the batch:

```
CARGO_BUILD_JOBS=2 cargo build --release --offline --locked --examples
target/release/examples/check_records /home/alex/league/records/standin prefix 500
target/release/examples/check_records /home/alex/league/records/standin full 500
```

`check_records` uses the production `RecordReplay` header validation and operation driver.
On mismatch it reports record/seed/operation and writes the actual state under the worktree's
`.copies/recruit/`; `gd/dump_state.gd` and `diff_state.py` provide the source state and first
field path. `write_record SOURCE.jsonl OUT_DIR full` writes the same action stream through
GameSession and the Rust writer, then compares every emitted operation. The writer regression
test covers a recorded full round and all three checkpoint writes; hashes are calculated
before taking the mutable writer borrow.

Recruit interfaces and hook/borrow/settling details for tribe workers are under
[Recruit in DESIGN.md](bramble-engine/DESIGN.md#recruit). No mismatches or requested work remain
for the stand-in recruit proof. There were no approval denials, pushes or PRs.

# Bounded speed pass — 18 November 2026

The complete replay/fight/selfcheck and tribe proofs still pass after the speed changes.
See [proof/SPEED.md](proof/SPEED.md) for every result, timings, equivalence notes and the
remaining shortfall against the fight-speed target.

## GDScript match replay

Run from the checkout that matches the records' rules fingerprint. On a fresh checkout,
build Godot's project cache once before starting parallel replays.

```sh
timeout -k 10 120 godot --headless --import
tools/league/proof/replay_match.sh /path/to/match 4
```

The script requires Bash 5.1 or later and defaults to four jobs. It requires a complete
replay for each `records/game-*.jsonl`, reports the first problem for each failure and
exits nonzero if any replay fails or the match has no records. Each Godot process has
private user, config and cache directories under `.copies/` that are removed after use.
`GODOT` and `RECORDS_TIMEOUT` select the executable and per-record time limit as in
`scripts/records.sh`.
