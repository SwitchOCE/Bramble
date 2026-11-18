# Thorn (Briar) port proof — 18 November 2026

The 19 mechanics and both shared helpers are implemented in this folder. Every gameplay
`todo!()` and `TODO(port mechanics)` is removed. GDScript, card data, core helpers and hashes
are unchanged. No missing engine helper or mismatch outside this folder was found.

Source rules: `c0d7db795bcb63ff38de8a5da941f96fb00aeba3`, Godot
`4.7.2.stable.official.ed1daf0bf`. Every corpus uses only ordered folders `shared,thorn`.

| Check | Result |
| --- | --- |
| Godot generation and full replay, seeds 1–300 | 300 / 300 games; 13,206 checkpoints |
| Rust complete production replay | 300 / 300 games; 13,206 / 13,206 checkpoints; 280,778 / 280,778 action results; every fight payload equal |
| Ordered turn-1 legal actions | 16,153 / 16,153 lists equal, including order |
| Total replayed turns | 4,402 |
| Stock isolated fights, seed 20261118 | 20,000 / 20,000; winner, loser, damage, reason, hash and exact complete state string equal |
| Supplemental populated-Compost fights, same seed | 2,000 / 2,000; same complete comparison |
| Offline locked Cargo build/test | Pass; 42 tests, 0 failures |
| Offline locked Clippy, all targets, warnings denied | Pass |
| Cargo formatting and git whitespace | Pass |

The complete Godot and Rust result JSONL files are byte-identical for both fight corpora;
SHA-256 digests are saved in `.copies/thorn/corpus-sha256.json`.
Both fight generators had zero rejected candidates and no script errors or warnings. The
stock corpus contains golden units, stat changes, slot buffs, granted mechanics and hands.
The stock generator starts with empty heaps. `with_compost.gd` extends it without changing
its implementation or oracle, adding 0–24 random unit entries to each initial Compost using
the inherited RNG. This exercises Root spending, Grow and Holly Knight thresholds,
highest-tier copies, ties, Elder Mother's landing bonus and waiting summons. The full record
corpus also builds and spends Compost through real recruit actions and fights.

## Planted mechanic bug

Temporarily changed `Seed::_entries`' plain result from **1 to 2**, built separate release
binaries under `.copies/thorn/plant-bramble-*`, then restored the source and rebuilt the
correct binaries. The same planted mechanic was rejected by:

- **300 / 300 complete records**. First: seed 1, turn 1,
  `state hash differs at finish` from production `bramble-replay`.
- **6,869 / 20,000 stock fights**.
- **716 / 2,000 populated-Compost fights**.

First stock failure: physical line 5, case id 4, JSON path
`$["players"][3]["heaps"]["thorn_compost"]["_next_n"]`: Godot `3`, planted Rust `5`.
The plant count checks validate every result's id and state SHA and reject crashes, missing
results or usage errors. Final Cargo gates and the full positive comparisons use the restored
source. No mutation is committed.

## Artifacts and reproduction

Records and legal-action sidecars: `/home/alex/league/records/thorn/`.
Logs, cases, complete outputs, mutation binaries, per-record mutation failures and summaries:
`.copies/thorn/` in this worktree (ignored). Full positive comparison summaries:

```
PASS records=300 checkpoints=13206 actions=280778 ordered_legal_decisions=16153 turns=4402 mode=full
fight_compare matched=20000 state_bytes=373670849
fight_compare matched=2000 state_bytes=39416759
```

From the worktree root, using a writable local XDG config/data directory after a bounded
headless import, run the Godot jobs sequentially:

```sh
timeout -k 10 7200 godot --headless -s res://tools/league/gd/standin_records.gd -- games=300 seed=1 out=/home/alex/league/records/thorn/ folders=shared,thorn
timeout -k 10 3600 godot --headless -s res://tools/league/gd/standin_fights.gd -- cases="$PWD/.copies/thorn/stock-cases.jsonl" out="$PWD/.copies/thorn/stock-gd.jsonl" count=20000 seed=20261118 folders=shared,thorn
timeout -k 10 1200 godot --headless -s res://tools/league/bramble-engine/src/content/thorn/proof/with_compost.gd -- cases="$PWD/.copies/thorn/compost-cases.jsonl" out="$PWD/.copies/thorn/compost-gd.jsonl" count=2000 seed=20261118 folders=shared,thorn
```

Build from `tools/league` with `CARGO_BUILD_JOBS=1` and `--offline --locked` (release binaries
and examples), then run from the worktree root:

```sh
timeout -k 10 1200 tools/league/target/release/examples/check_records /home/alex/league/records/thorn full 300
# Repeat for corpus=stock and corpus=compost:
timeout -k 10 1200 tools/league/target/release/bramble-fight cases=.copies/thorn/stock-cases.jsonl out=.copies/thorn/stock-rust.jsonl
python3 tools/league/bramble-fight/compare.py .copies/thorn/stock-gd.jsonl .copies/thorn/stock-rust.jsonl
```

Every heavy job ran sequentially; Cargo used one build job. No push or PR was made, no
approval was denied, and no required work remains undone.
