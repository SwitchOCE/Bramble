# Locust port proof — 18 November 2026

> These seed-20261118 stand-in results predate pool removal (record format 3) and Reworks S9 (9250d7a3). Both changes shifted the generator’s RNG draws.

All 20 mechanic modules and the shared `lib/locust.rs` helper are implemented. All 60
GDScript function names (52 mechanic functions, eight helpers) are mirrored; no locust
`todo!()` or `TODO(port mechanics)` remains. Hook order, selection order, live-array loops,
trigger timing and RNG draw order follow the source. No engine helper was missing.

Implementation commit: `7f377599`. Finished recruit and record tools were integrated from
`origin/league/p0-core` by merge `9e4ce341`. The source engine is unchanged, running Godot
`4.7.2.stable.official.ed1daf0bf`; the ordered content recipe is **shared, locust** throughout.

## Full-game records

`standin_records.gd games=300 seed=1 folders=shared,locust` generated seeds 1–300 under
`/home/alex/league/records/locust/`, with a `.legal.jsonl` sidecar per game. Godot's own replay
passed every game without bot refusals or script errors.

| Check | Matched |
| --- | --- |
| Complete games, production `bramble-replay replay` | 300 / 300 |
| State checkpoints, both Rust replay drivers | 14,289 / 14,289 |
| Action results, production `RecordReplay::_step` via `check_records` | 267,769 / 267,769 |
| Ordered turn-one legal-action lists | 16,153 / 16,153 |
| Turns | 4,763 |
| `fight_boards` payloads | Every payload equal |

Every locust card occurs in the records. Recruit activity includes 17,771 sales and 1,856
board/hand snapshots with Gorger's `locust_ate` turn counter set; Tide and Hopper-bonus
counters are exercised too. The sidecars are excluded from ordinary record globs.

## Isolated fights

| Corpus | Matched | Exact state-string bytes |
| --- | --- | --- |
| Canonical `standin_fights.gd`, seed 20261118 | 20,000 / 20,000 | 360,478,904 |
| Supplemental heaps and initial locust counters | 1,000 / 1,000 | 18,362,291 |
| Total | **21,000 / 21,000** | **378,841,195** |

Every result field, including winner, loser, damage, reason, state string and hash, matches.
Both Godot batches accepted every candidate with zero rejections and no script errors.
The main corpus covers every locust card, 69,726 golden snapshots, 93,410 slot buffs,
92,027 grants and hands containing both units and spells.

The supplemental fixture subclasses the unchanged folder-aware generator and overrides only
`_make_case`. For case `i` and participant `j` (0 or 1), it supplies Tide `(i+j)%23`, Hopper
bonus `(3*i+j)%17`, and a `locust_proof_heap` of `(i+j)%9` Hopper entries. Entry sequence
numbers are `2*n+1`, with `_next_n = 2*entry_count+4`. Every case has a nonempty heap on at
least one side. The ordinary fight oracle and rules engine remain unchanged.

The direct saved-case tool `tools/league/gd/fight_run.gd::_initialize` always loads default
content and ignores case recipe metadata. Using it directly for the supplemental corpus
first differed at case 0, `$["players"][0]["standing"].length` (Godot 4, Rust 1). It was left
unchanged. The folder-aware generator supplies the correct oracle content for both corpora;
there is no remaining locust mismatch.

## Planted mechanic bug

Temporarily changed Rust Molt's `GROWTH` from 2 to 3 (+3/+3 instead of +2/+2), then rebuilt
the comparison binaries. No GDScript, card data or hash code was changed.

| Check | Cases detecting the plant |
| --- | --- |
| Main fight corpus | 9,006 / 20,000 |
| Supplemental fight corpus | 462 / 1,000 |
| Total fights | **9,468 / 21,000** |
| Production `bramble-replay`, complete record corpus | **300 / 300** |

209 fights also changed winner, loser, damage or halt reason. The first fight mismatch is
case 2, `$["players"][3]["board"][1]["stats"]["perm_attack"]`: Godot 2, planted Rust 3.
The first record failure is seed 1, operation 55 (`finish`), turn 1. The batch checker dumped
the actual state; `gd/dump_state.gd op=55` and `diff_state.py` identified
`$["players"][4]["board"][0]["stats"]["perm_attack"]`: Godot 2, planted Rust 3.

The plant is removed: Molt's `GROWTH` is 2, and the release tools have been rebuilt.
The restored binaries pass all 21,000 fights and all 300 records again, including every
checkpoint, action result and ordered legal-action list.

## Gates and artifacts

With `CARGO_BUILD_JOBS=1`, from `tools/league`:

- `cargo build --offline --locked`: pass.
- `cargo test --offline --locked`: 42 passed, zero failed.
- `cargo clippy --offline --locked --all-targets -- -D warnings`: pass.
- `cargo fmt --all --check`: pass.
- `cargo build --release --offline --locked --workspace --bins --examples`: pass.
- `git diff --check`: pass.

All heavy runs were serial and bounded by `timeout -k 10`; no push or PR was made. No
approval was denied. Git-index writes and the requested external records directory required
approved sandbox escalations.

Ignored artifacts are under this worktree's `.copies/locust/`: corpus reports, Godot and Rust
outputs, `check-records.log`, `replay-records.log`, `record-coverage.json`, planted failure
counts and dumps, fixture scripts, Cargo logs and SHA-256 fingerprints. Records remain in
the requested external directory. No comparison repo copy or large artifact was put in `/tmp`.

Reproduce the main checks from the repository root after bounded Godot import:

```sh
timeout -k 10 7200 godot --headless -s res://tools/league/gd/standin_records.gd -- games=300 seed=1 out=/home/alex/league/records/locust/ folders=shared,locust
timeout -k 10 14400 godot --headless -s res://tools/league/gd/standin_fights.gd -- cases=.copies/locust/cases.jsonl out=.copies/locust/gd.jsonl count=20000 seed=20261118 folders=shared,locust
timeout -k 10 1800 tools/league/target/release/bramble-fight cases=.copies/locust/cases.jsonl out=.copies/locust/rust.jsonl
python3 tools/league/bramble-fight/compare.py .copies/locust/gd.jsonl .copies/locust/rust.jsonl
timeout -k 10 1800 tools/league/target/release/examples/check_records /home/alex/league/records/locust full 300
```
