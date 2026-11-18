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
