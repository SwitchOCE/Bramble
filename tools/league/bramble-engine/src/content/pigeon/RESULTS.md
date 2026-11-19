# Pigeon port proof — 18 November 2026

> Made before the pool removal (record format 3). The stand-in fight generator draws differently since then, so the seed-20261118 commands here no longer reproduce these numbers.

The 22 mechanics and the Medals helper mirror `src/content/pigeon/` line by line.
All gameplay TODOs in this folder are implemented. Setup/main priorities, loop order,
trigger short-circuiting, permanent write-back and random draws retain source order.
No engine helper was missing or changed. No source GDScript or card data was changed.

Implementation: `62321f20`. Finished core merged from `origin/league/p0-core` in
`1cdd8b84`. Only this folder contains worker-authored tracked changes.

## Fight corpus

`standin_fights.gd` ran with `folders=shared,pigeon`, `seed=20261118`, `count=20000`.
All **20,000 / 20,000** results match winner, loser, damage, reason, SHA-256 and the
complete state string byte for byte (**360,886,064 state bytes**). Neither runner
rejected a case. Godot reported no script errors or warnings.

Coverage includes every Pigeon card, **69,726 golden units**, **93,410 buffed slots**,
**56,277 keyword slots**, and hand sizes 0–7 (native Reserve and Colonel hands).
The generator leaves lasting unit counters and heaps empty, so **300 additional
cases** add 0–6 Medals, a Guard post on each side, and heaps with 0–7 valid entries
and nondefault `_next_n`. Those cases also match in full (**5,661,404 state bytes**).
Their temporary runner extends the unchanged `fight_run.gd` and selects the exact
shared/pigeon content before calling its existing `_run`.

Artifacts, commands and supplemental fixture generation are under the ignored
`.copies/pigeon-fights/` directory. Neither cases nor dumps are committed.

Main case SHA-256: `f05b7f1aa3968c0588e39820bd6758f6bb119ce1bd0d323f01fb144d16a381e6`.
Godot output SHA-256: `604368b3a7c826661bc0558f5903a5128e9777e0089142f7392e4c3d1efc93cc`.

## Full records

`standin_records.gd` ran `games=300 seed=1 folders=shared,pigeon` and wrote to
`/home/alex/league/records/pigeon/`. GDScript replayed all **300 / 300** games itself,
with no bot refusals, errors or warnings. Rust's optimized `check_records ... full 300`
then matched all **300 initial hashes**, **13,824 checkpoints**, **271,145 action
results**, **16,153 ordered turn-1 legal-action lists**, and **4,608 fight payloads**
over **4,608 turns**. The records include **4,989 Grenadier Orders** and **821 Lance
Corporal Orders**. No mismatch was found.

## Planted mechanic bug

Temporarily changed `lib/medals.rs`'s `STATS` from 2 to 3, leaving GDScript and all
hashing unchanged, and rebuilt both production runners.

- **9,007 / 20,000 fights** caught the plant. The unchanged `compare.py` rejected
  line 5, case 4. The first differing JSON path was
  `$["players"][3]["board"][6]["stats"]["perm_attack"]`: Godot 30, Rust 34.
- **300 / 300 full records** caught it through production `bramble-replay replay`.
  Seed 1 first fails at turn 2, zero-based operation 88 (`finish`). The checker wrote
  the Rust state; `gd/dump_state.gd` at operation 88 and `diff_state.py` identified
  `$["players"][0]["board"][1]["stats"]["perm_attack"]`: Godot 4, Rust 6.

Restored `STATS = 2`; the file is byte-identical to the implementation commit.
The plant was never committed. Detailed counts and diagnostic dumps remain under
`.copies/pigeon-fights/` (the checker's automatic Rust dump is in `.copies/recruit/`).

## Final gates

With the plant removed and `CARGO_BUILD_JOBS=1`, all passed:

- `cargo build --offline --locked`
- `cargo test --offline --locked`: **42 passed, 0 failed**
- `cargo clippy --offline --locked --all-targets -- -D warnings`
- `cargo build --release --offline --locked --workspace --bins --examples`
- `cargo fmt --all --check` and `git diff --check`

The restored optimized runners also reran the full 20,000-fight and 300-record
comparisons successfully. No mismatches, missing helpers or unfinished work remain.
All Git/record-directory sandbox escalations were approved; no actions were denied.
No push or PR was made.

Reproduce from the repository root (Cargo commands run in `tools/league`):

```sh
timeout -k 10 1800 godot --headless -s res://tools/league/gd/standin_fights.gd -- cases="$PWD/.copies/pigeon-fights/cases.jsonl" out="$PWD/.copies/pigeon-fights/gd.jsonl" count=20000 seed=20261118 folders=shared,pigeon
timeout -k 10 7200 godot --headless -s res://tools/league/gd/standin_records.gd -- games=300 seed=1 out=/home/alex/league/records/pigeon/ folders=shared,pigeon
timeout -k 10 600 tools/league/target/release/bramble-fight cases=.copies/pigeon-fights/cases.jsonl out=.copies/pigeon-fights/rust.jsonl
python3 tools/league/bramble-fight/compare.py .copies/pigeon-fights/gd.jsonl .copies/pigeon-fights/rust.jsonl
timeout -k 10 600 tools/league/target/release/examples/check_records /home/alex/league/records/pigeon full 300
```
