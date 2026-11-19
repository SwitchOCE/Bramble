# Badger port proof

## Dev reference at `6fe0439c`

The source adds the Pigeon Renown and Reserve roster on top of the Kin Mouse roster. The
four Badger and eleven rework fight vectors match GDScript state hashes. Rework traces
also match the selected events. The Lieutenant deals 2 damage across from the occupied
source slot and skips the empty opposite slot. The Bugler's first Private enters the
Guard post with Renown after four units die together.

Two [recruit vectors](../../../tests/fixtures/rework_recruit.json) match the GDScript hashes,
payloads and action results. A Sentry triple combines Supply 2, 0 and 6 into 8, then spends
one Supply and logs the golden's Renown gain. The Quartermaster picker excludes itself
and an existing reservist. Its default choice puts a permanent Reserve grant on the
leftmost eligible unit.

The reference refresh accepted all 100,000 fights with zero rejects. Commit `9f2fa38a`
records the regenerated fixtures and the [build pin](../../../../league/build.json) with
fingerprint `f9ef2c52bf3607ef96e5ab5f128d05b889a42e2677bccf8dfdade453ae1ae860`.

| Check | Result |
| --- | --- |
| GDScript records replayed in Rust | 1,000 complete records and 46,971 matching checkpoints |
| Isolated fight comparison | 100,000 matches and 2,547,146,767 equal state bytes |
| Rust workspace tests | 79 passed |
| Mixed-bot and TribeBot selfchecks | 1,000/1,000 and 200/200 exact matches |
| Rust records replayed in GDScript | 50 complete records and zero failures |
| `env -u XMODIFIERS scripts/check.sh` | All steps passed, including 932 GUT tests |
| Formatting and Clippy | Passed for bramble-engine, league-api, league, bramble-events and bramble-fight |
| Final Red/Blue smoke after recheck | 200 games, 0 clock-outs, 0 panics, 0 faults, 0 refused actions |

`recheck: PASS`. The current corpus and run logs are under `/home/alex/engine-data/dev-rework`.

## Previous S7 proof at `1eafd249`

The build pin covers one-neighbour Cleave, the Badger Fury and Grudge floors, Relic Seeker
payout, Gate Warden's split stats and Sett Sexton's capped payments. It also covers slot
Renown, the hand Reserve limit, and the Kin Mouse roster.

Four [Badger fight vectors](../../../../bramble-fight/tests/fixtures/badger_fights.jsonl) match
the GDScript state hashes on this pin. An in-memory Gate Warden Attack increase was detected
by the split-stats vector. Nine [rework vectors](../../../../bramble-fight/tests/fixtures/rework_fights.jsonl)
also match their selected combat events. They cover Renown gains, Reserve fill order and
its query, Privates, counted Pile on, simultaneous damage before Pikeman buffs, and Widow
Thimble's split.

The S7 reference refresh accepted 100,000 fights with zero rejects. The regenerated
fixtures and [build pin](../../../../league/build.json) are in `9490c48f`. The rules
fingerprint is `dd82bf70f8f68e753879d7c509e32f00aaf82492faa6d9b53a19db7b62f1e081`.

| Check | Result |
| --- | --- |
| GDScript records replayed in Rust | 1,000 complete records and 46,599 matching checkpoints |
| Isolated fight comparison | 100,000 matches and 2,515,659,157 equal state bytes |
| Rust workspace tests | 76 passed |
| Mixed-bot and TribeBot selfchecks | 1,000/1,000 and 200/200 exact matches |
| Rust records replayed in GDScript | 50 complete records and zero failures |
| `env -u XMODIFIERS scripts/check.sh` | All steps passed, including 962 GUT tests |
| Formatting and Clippy | Passed for bramble-engine, league-api, league, bramble-events and bramble-fight |

`recheck: PASS`. The subsequent smoke completed 200 games with zero clock-outs, panics,
faults or refused actions. The S7 run logs remain under `/home/alex/engine-data/dev-rework`.

## Historical pre-poolless proof

> Made before the pool removal (record format 3). The stand-in fight generator draws differently since then, so the seed-20261118 commands here no longer reproduce these numbers.

Source: `src/content/badger/mechanics/*.gd` and `lib/badger_rules.gd`, Godot
`4.7.2.stable.official.ed1daf0bf`. Rust modules mirror every source hook and helper;
no gameplay TODO remains under this folder. Core/recruit integration is merge `50738238`.
Only the badger folder is authored by this worker; the requested core merge is retained.

## Isolated fights

Exact ordered content: `folders=shared,badger`, generator seed `20261118`.
**20,000 / 20,000** accepted cases match every result field, winner, damage, hash and
full state string: **394,405,342 state bytes**. There were **zero rejected candidates**
and no script errors or warnings in the generator logs. The 100-case smoke also matched.

Coverage: all 23 loaded cards; both player board and hand sizes 0–7;
69,859 golden units; 93,163 buffed slots; 56,146 slots with keywords;
91,518 granted effects; 24,064 spells in hands. Player heap dictionaries are included
in every snapshot and state comparison (this content recipe has no heap mechanics).

From the repository root, after bounded Godot import:

```sh
timeout -k 10 14400 godot --headless -s res://tools/league/gd/standin_fights.gd -- \
  cases="$PWD/.copies/badger-proof/cases.jsonl" \
  out="$PWD/.copies/badger-proof/gd.jsonl" count=20000 seed=20261118 folders=shared,badger
tools/league/target/release/bramble-fight \
  cases=.copies/badger-proof/cases.jsonl out=.copies/badger-proof/rust.jsonl
python3 tools/league/bramble-fight/compare.py \
  .copies/badger-proof/gd.jsonl .copies/badger-proof/rust.jsonl
```

The release runners were built from `tools/league` with
`CARGO_BUILD_JOBS=1 cargo build --release --offline --locked --workspace --examples --bins`.
Logs and large fight artifacts remain in the ignored `.copies/badger-proof/` directory.

## Full records

Exact ordered content: `folders=shared,badger`, seeds **1–300**. All **300 / 300**
source games passed GDScript self-replay. The Rust production replay/checkpoint driver
then matched all **300 / 300** complete records, **13,665 checkpoints**,
**276,994 action results**, every `fight_boards` payload, and **16,153 ordered turn-1
legal-action lists** across **4,555 turns**. Initial header validation also passed for
every record. No script errors or warnings were reported.

```sh
timeout -k 10 14400 godot --headless -s res://tools/league/gd/standin_records.gd -- \
  games=300 seed=1 out=/home/alex/league/records/badger/ folders=shared,badger
tools/league/target/release/examples/check_records \
  /home/alex/league/records/badger full 300
```

The `.legal.jsonl` sidecars are excluded from record counts. Source records remain at
`/home/alex/league/records/badger/`; execution logs are in `.copies/badger-proof/`.

## Planted mechanic bug

Changed only `gate_warden.rs` from `params.num("gain")` to that value **+1**,
rebuilt the release binaries, and ran the same corpora:

- **3,554 / 20,000 fights caught it** (16,446 still matched). The first mismatch was
  case id 4, at `$["players"][6]["board"][2]["stats"]["perm_attack"]`:
  Godot 6, planted Rust 9.
- **296 / 300 records caught it** (four still passed), counted by running the production
  `bramble-replay replay --record FILE` on every record. The first failure was seed 1,
  turn 3, zero-based operation 173 (`finish`). The batch checker wrote the actual state;
  `gd/dump_state.gd op=173` plus `diff_state.py` found
  `$["players"][4]["board"][3]["stats"]["perm_attack"]`: Godot 6, planted Rust 9.

The plant was removed, the file compared byte-for-byte with its pre-plant copy,
and the tracked badger code diff was empty before the final gates. The GDScript,
card data and hash implementation were never modified. After rebuilding without the
plant, the full **20,000-fight** comparison and all **300 complete records** were
rerun and passed again with the same byte, checkpoint, action and legal-list counts.

## Final gates

With `CARGO_BUILD_JOBS=1`, from `tools/league`:

- `cargo build --offline --locked`: pass.
- `cargo test --offline --locked`: **42 passed**, zero failures.
- `cargo clippy --offline --locked --all-targets -- -D warnings`: pass.
- Rustfmt (edition 2024) on all badger mechanic/helper modules: pass.
- `git diff --check`: pass.

No engine helpers were missing or required changes outside the assigned folder.
No unplanted mismatch remains. No approval action was denied. No push or PR was made.
