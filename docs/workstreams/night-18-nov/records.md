# Game records — brief 8

Every started owner/autoplay game and core bot game now writes one local `.jsonl` record.
Seed + ordered actions rebuild the game; three SHA-256 state checkpoints per turn verify it.
Fight snapshots keep the board and Reserve hand of every player, with slots, heaps, counters,
standing mechanics and the actual ghost when one fights. No data leaves the PC.

## Review fixes (format 2)

GUT now routes every fixture game to `build/test-records`; soaks use `build/soak-records`.
Normal game-flow/autoplay defaults stay in `user://records`; the replay sweep keeps its
explicit output folder. The separate isolation suite verifies both kit and UI-test games.
Disabling the setup hook in a fresh temporary profile made that test fail all four assertions;
the two deliberately created records were removed afterward.

Fight snapshots now store card id, UID, golden flag, only nondefault stat layers and variable
unit fields, and only added own/aura effects with their applied values. Card/golden mechanic
templates, parameter schemas, `stat_max`, zero layers and unset overrides are rebuilt.
Golden-card and dynamic-grant tests round-trip the compact units through disk-shaped JSON.
Full-state hashes still include every rules field. `taste-records.md` now attributes the hash
suggestion to the orchestrator and the implementation choice to the worker.

The repeated **50-game / 50-seed sweep (1–50)** matched **774 turns / 2,322 checkpoints**.
Every checkpoint hash also equals the original format-1 run, confirming unchanged game
states across the format change. The one changed turn-2 buy again reported **first differing
turn 2**. Focused tests: **12/12, 338 assertions**, including the isolation regression and
compact-unit reconstruction.

| Typical record across the same 50 seeds | Raw bytes | Zipped bytes |
| --- | ---: | ---: |
| Before (format 1) | 543,286 | 26,811 |
| After (format 2) | 234,098 | 10,668 |
| Reduction | 56.9% | 60.2% |

For a controlled same-seed comparison (seed 22, same ZIP entry name), the old middle record
fell from **543,286 / 26,811 bytes** to **239,859 / 11,971 bytes**, raw / zipped respectively.
Snapshot encoding skips base mechanic/parameter construction entirely and emits only changed
stat layers; full hash construction is unchanged.

Review `./scripts/check.sh`: **all 12 stages passed**, **732/732 tests, 12,011 assertions**,
**366 files compiled / 0 failures**, normal soaks **0 violations**, and the preserved records
stage matched **2 additional seeds (1001–1002), 30 turns / 90 checkpoints**, detecting its
planted change on turn 2. The successful command used the same temporary XDG and `FEEL_TMP`
settings documented below.

The temporary `user://records` folder had exactly **1,980 files before and after** the sweep
and gate: **0 added**, filename list unchanged. Previously generated files were retained;
this verifies the fix without deleting records. New fixture and soak output is under `build/`.
Evidence was under `media/records/review/`, separate from the original run: sweep and
gate logs, isolation-failure proof, size data and the new typical ZIP. It was removed on 18 Nov once the night was merged; it was not kept in R2.

## Try it

1. Play a game (or quit partway through).
2. On Windows, paste `%APPDATA%\Godot\app_userdata\Bramble\records` into Explorer.
3. Copy and zip that folder. Keep the executable that played the game.

Replay an exported record with that executable:
`bramble.exe --headless -- --replay-record "C:\path\game.jsonl"`.
The result also goes in `%APPDATA%\Godot\app_userdata\Bramble\logs\godot.log`.
From its source checkout, use `scripts/records.sh record=/path/game.jsonl`.
Instructions and format: [records README](../../../src/core/records/README.md).
Choices: [taste-records.md](taste-records.md).

## Verification (format 1, before review)

- `scripts/records.sh games=50 first_seed=1 plant=1`: **50 full games / 50 distinct seeds (1–50)**, **774 turns / 2,322 state checkpoints**, all matched. All shipped tribes; FlowBot and RandomBot seats.
- Those files contain **45,726 actions**, all **8 seats**, **774 pre-fight snapshots**, and **170 ghost-opponent payloads**. Actions include buys, plays, sales, moves, upgrades, refreshes, freezes, abilities, Discovers and end turns.
- Deliberately replaced **one turn-2 buy with freeze** in a copy of seed 50. The checker reported **“first differing turn 2: action result differs for player 1: no card at that hand position”**. The original record matched through turn 16.
- A typical record (the sweep's middle file) is **543,286 bytes (531 KiB)**; zipped alone it is **26,811 bytes (26.2 KiB)**. No full turn states or combat event logs are stored.
- Focused GUT: **9/9 tests, 310 assertions**. Includes disk readback across 5 seeds (including max signed 64-bit), incomplete human games, refused actions, explicit end-turn calls, nondefault core bot config, ghost snapshots, hidden-state hash coverage, unique files and build mismatch rejection.

- Compiled Linux release export: autoplay seed **42** wrote a **622,720-byte** record, and that same release executable replayed **15 turns / 45 checkpoints**, complete, exit **0**, with no Godot errors. This checks recording and replay with compiled scripts, without Git or development tools.

- `./scripts/check.sh`: **all 12 stages passed**, including **729/729 GUT tests / 11,983 assertions**, compile **364 files / 0 failures**, film **126 frames / 60 fps**, normal soaks **0 violations**, and all planted invariant faults detected. Its replay stage matched **2 more full games / 2 distinct seeds (1001–1002), 30 turns / 90 checkpoints**, and caught its changed action on turn 2.
- The compiled executable also rejected a copy with one turn-2 upgrade changed to freeze: **first differing turn 2**, exit **1**.
- The first gate run passed all tests, then its film check hit the sandbox's read-only `~/.cache`. The successful final run was `XDG_CONFIG_HOME=/tmp/n18-records-config XDG_DATA_HOME=/tmp/n18-records-data FEEL_TMP=/tmp/n18-records-feel ./scripts/check.sh`. No approval request was denied.

Local evidence was removed on 18 Nov once the night was merged; it was not kept in R2.
The 50 records and changed-action copy are in `games/`; `replay-50.log` contains the complete sweep report. `check-final.log`, the compiled export, its record and its replay logs are alongside it.

## Limits

Native Windows and Explorer export have not been exercised on the owner's PC. Linux checks
can verify written files and executable replay, but cannot establish that experience.
Ghost rules data is preserved and checked; this item adds no full ghost importer or matchmaking.
Replay requires the original build. Records from compiled exports are replayed by that
executable; their code fingerprint differs from a source checkout's.
Hand-built unit-test fixtures using raw `GameSession.create` are outside game recording;
all game entry points and the bot/soak content factory record automatically.
