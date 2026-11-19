# Combat port proof — 18 November 2026

Godot `4.7.2.stable.official.ed1daf0bf`, Rust/Cargo `1.100.0`. The pinned GDScript source is
`c0d7db795bcb63ff38de8a5da941f96fb00aeba3`. Its `src` tree remains byte-identical
(`8e12b55d36c722a455753ba90210f8dd5909b465`). No game source, tests, scripts, addons or card
JSON were edited. Recruit/session commit `db1db9cb` was merged for the real `_fight` and
`after_fight` path; no substitute session implementation was used in this proof.

| Check | Result |
| --- | --- |
| Stand-in isolated fights | **20,000 / 20,000 match**, zero rejections or mismatches |
| Compared fields | winner, loser, damage, reason, exact state string, SHA-256 |
| State bytes compared | **331,020,428** |
| Complete Godot/Rust JSONL files | Byte-identical, **379,677,314 bytes** each |
| Full Rust repeat | 20,000 / 20,000; byte-identical complete output |
| Godot repeat | 100 / 100 cases and outputs byte-identical, also matching the full corpus prefix |
| Invalid/malformed inputs | 51 / 51 exact error objects match; subsequent lines continue |
| Explicit `folders=shared` recipe | 100 / 100 full-state fights match |
| All-tribe source corpus parsing/validation | 100,000 / 100,000 accepted by the Rust case validator; gameplay awaits tribe mechanics |
| Snapshot round trips | 103 cards × plain/golden = 206; stats, origin, counters, own/aura grants, null slots and UID preservation |
| Direct combat tests | 10 pass, including 500 fights comparing repeat event logs and unchanged recruit units |
| `CARGO_BUILD_JOBS=2 cargo build --offline --locked` | Pass |
| `CARGO_BUILD_JOBS=2 cargo test --offline --locked` | **38 passed, 0 failed** |
| `CARGO_BUILD_JOBS=2 cargo clippy --offline --locked --all-targets -- -D warnings` | Pass |
| Release fight-runner build, offline/locked | Pass |
| Owned Rust formatting, GDScript lint, `git diff --check` | Pass |
| Godot import/generation/repeat/validation logs | No script errors, errors or warnings |

Direct tests also check complete result dictionaries, simultaneous deaths, starting survivor
identity, summons, one Reborn return, Shield/Venomous interaction, Stealth/Taunt, Cleave,
Windfury, and distinct `no_attacks`, `attack_limit` and `trigger_limit` ties. The random corpus
ended with `board_empty` in all 20,000 cases; the other halt reasons are covered directly.
Combat event logs are **retained in full**, including held return events and aura `after`
indices. Trigger counting is unchanged. No log-elision optimization is claimed.

## Corpus and planted bug

Generator seed `20261118`, content `{"folders":[]}`. Both boards and hands cover every size
0–7; all 26 loaded ids appear (25 stand-in definitions plus system Triple Reward). Coverage:
70,294 golden units, 93,121 slots with stat buffs, 56,273 slots with keywords, 90,437 units with
grants, and 21,480 spells in hands. Every round 1–50 appears. Player tier counts 1–6 are
6,797 / 6,710 / 6,648 / 6,589 / 6,647 / 6,609. Seeds include signed int64 limits, zero and -1;
9,927 are negative and 10,073 nonnegative.

`--plant-attack t1_plain` increased only the loaded card definition's Attack by one in memory.
The same comparison rejected **8,870 / 20,000** cases: 8,870 state/hash changes, 41 winner/loser
changes and 66 damage changes. The first diagnostic was case 0, state byte offset 6,364,
`$["players"][4]["hand"][1]["stats"]["base_attack"]`, expected 4, got 6 (a golden unit).
The normal command then remains unchanged; no card JSON or engine rule was patched.

Artifacts are outside Git in `.copies/standin-proof/`: cases, oracle, two normal Rust runs,
planted output, coverage, timings, logs and artifact hashes. The comparison streams these files.

| Artifact | SHA-256 |
| --- | --- |
| `cases.jsonl` (49,442,020 bytes) | `b8dcc3eaa38a5230cfc422abaa2d39f26d518fd2cc09da3646b6bc7fc0f2fc1f` |
| `gd.jsonl`, `rust.jsonl`, `rust-repeat.jsonl` | `bea689d616766122295332b92296ebe8429241db39fdaf4931971aa723645255` |
| `rust-planted.jsonl` | `563f67bca717d8fd3139a92f457668505569a798995d7071f494be4d7f90f723` |
| Generator | `ac01f17f0777a4aec9bfacf5bbcc83676d904b354a653d7f555fb1a17326ceb0` |
| GDScript runner | `e590f266f0dc9d72dd824c356039b7ba4bb567a430adaab033dafc6d320b1f1e` |

The Godot generator/oracle took 269.601 seconds (13,480 μs/case); the release Rust runner took
23.936 seconds (1,197 μs/case), including fresh sessions, full state serialization and output.
These are tool timings under shared-machine load, not the later harness performance benchmark.
All Godot processes and full-corpus fight runs had time limits. At most two heavy jobs ran
concurrently; all have exited.

## Handoff

Implemented snapshot restore first (`2c296e63`), core combat keywords/effects (`8fdfbafc`),
combat flow/bridges/deaths/returns/arrivals/auras and direct tests (`e0584e18`), and fight tooling
(`da71c5be`). [README.md](README.md) gives reproduction commands and ordered folder recipes.
[DESIGN.md](../bramble-engine/DESIGN.md#combat) documents the required FightSide associated
calls, borrowing rules, return/arrival handling, vector boundaries and snapshot UID ownership.

No action was denied. Git index writes required approved sandbox escalation. No push was made.
No mismatch or blocker remains in this combat tranche. The all-tribe fight execution proof
belongs after those mechanics are implemented; this report makes no all-tribe gameplay claim.
