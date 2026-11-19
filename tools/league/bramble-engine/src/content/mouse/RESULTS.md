# Mouse port proof — 18 November 2026

> Made before the pool removal (record format 3). The stand-in fight generator draws differently since then, so the seed-20261118 commands here no longer reproduce these numbers.

The [dev reference proof](../badger/PROOF.md#dev-reference-at-6fe0439c) covers the Kin roster,
including counted Pile on, the damage-before-buff order, and the Widow Thimble split.

Source: `c0d7db795bcb63ff38de8a5da941f96fb00aeba3`, Godot
`4.7.2.stable.official.ed1daf0bf`. Content is exactly the ordered folders
`shared,mouse`. Implementation: `9571c670`; finished core integrated by `02e1c375`.

All mouse mechanic hooks and `lib/mouse_rules.rs` helpers are implemented.
The two parameter-only mechanics retain their existing metadata. No gameplay TODOs remain
in this folder. No missing engine helper was needed, and no GDScript, card data or engine
implementation outside this folder was edited. The core merge was explicitly requested.

## Exact comparisons

| Check | Result |
| --- | --- |
| GDScript record generation and replay, seeds 1–300 | 300/300 games; 13,311 checkpoints; 16,153 turn-one decisions |
| Rust production replay driver, complete games | 300/300 games; 13,311 checkpoints; 268,458 action results; every `fight_boards` payload; 4,437 turns |
| Ordered turn-one legal actions | 16,153/16,153 lists equal, including order |
| Random isolated fights, seed 20261118 | 20,000/20,000 complete payloads and state strings equal; 346,608,210 state bytes; zero rejected candidates |
| Supplemental populated-heap fights | 200/200 complete payloads and state strings equal; 3,516,317 state bytes; zero rejections |
| Offline locked build/test/Clippy, one Cargo job | Pass; 42 tests; Clippy all targets with `-D warnings` |
| Mouse Rust formatting and whitespace | Pass |

The random corpus includes 69,726 golden board/hand units, 93,410 buffed slots,
92,025 units with grants and 23,378 spells in hands. All board and hand sizes 0–7 occur.
The generator emits empty heaps for mouse content, so the supplement takes the first
200 cases and adds `mouse_probe` heaps with varied card tiers, entry counts and sequence
numbers. A temporary wrapper loads `shared,mouse` and calls the unchanged `fight_run.gd`
oracle. Every supplemental case has a populated heap on at least one side.
All 19 purchasable mouse unit definitions occur on recorded pre-fight boards.

Records and legal-action sidecars: `/home/alex/league/records/mouse/`.
Fight fixtures, full oracle/Rust outputs, coverage, gate logs and temporary supplemental
harness: `build/league-mouse/` in this worktree, outside Git.

## Planted bug

Only the Rust Needle Pikeman gain in `MouseRules::_pikeman_grows` was changed:
`params.num("attack")` became `params.num("attack") + 1`. The same compiled plant was
checked against both unchanged Godot corpora:

- **2,575/20,000 fights caught it.** First: case 5,
  `$["players"][4]["board"][4]["stats"]["perm_attack"]`, expected 8, actual 10.
- **227/300 full records caught it.** First: seed 1, turn 5, operation 321 (`finish`).
  Godot/Rust state dumps and `diff_state.py` identify
  `$["players"][2]["board"][4]["stats"]["perm_attack"]`, expected 9, actual 12.

The plant was removed before the final Cargo gates and restored-code replay.
Isolated planted binaries and complete counts remain under `build/league-mouse/`;
normal debug and release runners contain the restored implementation.

## Reproduce

From the worktree root, after a bounded Godot import:

```sh
timeout -k 10 7200 godot --headless -s res://tools/league/gd/standin_records.gd -- games=300 seed=1 out=/home/alex/league/records/mouse/ folders=shared,mouse
timeout -k 10 1800 godot --headless -s res://tools/league/gd/standin_fights.gd -- cases="$PWD/build/league-mouse/cases.jsonl" out="$PWD/build/league-mouse/gd.jsonl" count=20000 seed=20261118 folders=shared,mouse
```

Build the optimized runners from `tools/league` with
`CARGO_BUILD_JOBS=1 cargo build --release --offline --locked --bins --example check_records`.
Then, from the worktree root:

```sh
tools/league/target/release/examples/check_records /home/alex/league/records/mouse full 300
tools/league/target/release/bramble-fight cases=build/league-mouse/cases.jsonl out=build/league-mouse/rust.jsonl
python3 tools/league/bramble-fight/compare.py build/league-mouse/gd.jsonl build/league-mouse/rust.jsonl
```

No outstanding mismatch, helper request or unfinished mechanic remains. No push or PR was
made. There were no approval denials.
