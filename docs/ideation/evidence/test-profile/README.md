# Test-suite profile (cloud)

Profiler run, 9 Nov 2026, on `ideation/main` at `b5601aa`. No game code or tests changed. Brief: the owner (note 10 Nov) wants a faster, smarter suite and cloud test runs where they help. Locally, 2 Godot processes at once (14 GB RAM).

## Machine

4 vCPU Intel Xeon @ 2.10 GHz, 16 GB RAM, no swap; Godot 4.7.2.stable.official.ed1daf0bf (`machine.txt`). GNU `time` was not installed on the image; I installed it with apt.

## 1. The full gate, unchanged

`/usr/bin/time -v ./scripts/check.sh` (`gate-run1.log`, `raw/gate-run1.time`): **8:05 wall, peak RSS 1,210 MB** (1,238,840 KB). All 11 steps passed. The `.godot` cache was nearly empty at the start (1.3 MB from the image), so the import was cold.

| Step | Seconds | Share |
|---|---|---|
| tools, versions, shell, python, content | 4 | 1% |
| format (gdformat) | 23 | 5% |
| lint (gdlint) | 21 | 4% |
| import | 12 | 2% |
| compile | 7 | 1% |
| parity | 1 | 0% |
| **tests (GUT)** | **418** | **86%** |

Peak RSS is the GUT process; every other step is under 770 MB (import) or under 220 MB.

## 2. GUT alone, per-test timing

`godot --headless -s addons/gut/gut_cmdln.gd -gjunit_xml_file=...` (the option name is right): **6:27 wall, peak RSS 1,210 MB**, 180 scripts, 1,894 tests, 42,398 asserts, all pass; GUT reports 377.6 s. JUnit: `junit.xml`. Tables: `per-script.csv`, `top30.md`.

The time is concentrated in a few whole-game tests:

- **27 tests over 1 s take 254 s (68%)**. 1,697 tests under 0.15 s take 65 s in all. Median test: 0.033 s.
- Five tests take 149 s (40%): `test_normal_lobby_matches_complete_games_captured_at_0946909` (51.9 s), `test_a_seed_replays_exactly` (30.4), `test_probe_runs_two_real_paired_boards_with_held_out_fights` (22.8), `test_hard_really_swallows_and_flies` (22.3), `test_scripted_player_reaches_game_over` (21.0).
- The top 15 scripts are 71% of the time.

Slowest 5 scripts: `test_bot_brain` 60.8 s, `test_field_normal_regression` 51.9, `test_playthrough` 25.8, `test_bot_held` 24.0, `test_placing_bar_probe` 22.8.

## 3. Peak memory per script (15 slowest, each alone)

`per-script-memory.csv`, run with `-gselect=<basename>`, one at a time.

- **`tests/ui/test_playthrough.gd` peaks at 969 MB alone.** It is almost all of the suite's 1.2 GB peak.
- Every other script tested peaks at 167–275 MB (`test_field_mode` 275, `test_polish` 239, `test_big_numbers` 210). A bare GUT start with no tests is 122 MB and 1.0 s.
- Each lone run costs 2–5 s more than its in-suite time (engine start, scan, script load).

So the local 2-process limit is set by one script. Without `test_playthrough`, a Godot test process needs roughly 0.2–0.5 GB.

## 4. Sharding

Scripts split into k groups by greedy longest-first on step 2's times (`shards-k.json`; the configs used are in `raw/shard-k-i.json`, a copy of `.gutconfig.json` with `dirs: []` and `tests: [...]`, so the strict hook still runs). All shards started at once, one Godot each. `sharding-raw.txt` has every shard.

| Shards | Wall | vs 6:27 | Sum of shard peak RSS | Largest shard |
|---|---|---|---|---|
| 1 (step 2) | 387 s | — | 1,210 MB | 1,210 MB |
| 2 | **204 s** | 1.9x | 1,686 MB | 1,143 MB |
| 3 | **137 s** | 2.8x | 2,037 MB | 1,115 MB |
| 4 | **102 s** | 3.8x | 2,398 MB | 1,111 MB |

- Scaling is close to linear up to the 4 cores. The plan balanced the shards evenly (the predicted times were equal to 0.1 s) and the shards finished within 4 s of each other. The longest test (51.9 s) does not yet limit a 4-way split. It would limit splits from about 7 ways.
- Each extra shard costs about 0.35–0.45 GB and about 5 s of start-up.
- **No test failed only when sharded.** Every shard passed, `gut_strict: ok`, no error lines, and every split covered all 1,894 tests.
- **Latent shared-state risk:** `tests/ui/test_polish.gd` and `tests/ui/test_playthrough.gd` both set `Records.path = "user://test_records.cfg"`, and every process shares the project's `user://` directory. In every split they ran in different shards at the same time and passed, but a shard runner should give each process its own records file or keep the two scripts in one shard. Other `user://` names in tests are distinct per file (`test_look_records.cfg`, `test_sound_settings.cfg`, `field-once.json` and more), and I found no ports.

## 5. Import and compile

`import-compile.txt`.

| Run | Wall | Peak RSS |
|---|---|---|
| Import, cold (no `.godot`) | 11.3 s | 746 MB |
| Import, warm (cache present) | 6.0 s | 710 MB |
| compile_all (534 files) | 6.5 s | 213 MB |
| parity | 0.7 s | 143 MB |
| gdformat --check | 18.4 s | 40 MB |
| gdlint (both passes) | 19.5 s | 43 MB |

- **A second run reuses the `.godot` cache:** the warm import logs 16 lines against 1,269, and takes about half the time. It still costs 6 s because it re-scans the file system.
- **The gate imported once.** Only `import-1.log` was written. The second pass only runs when the first logs problems.
- gdformat and gdlint are single-threaded Python. Together they take 40 s (9% of the gate), use no Godot and about 40 MB, so they could run beside the Godot steps.

## What this suggests (not done)

- 4-way sharding of the tests step would take the gate from about 8 min to about 3 min on this machine (≈100 s of tests plus about 60 s of serial steps, or less with format and lint run alongside). It would need about 2.4 GB in total.
- Locally, the 2-process limit is a memory guard. `test_playthrough` (969 MB) is the outlier. Without it, 2 shards would need about 1.0 GB.
- Five whole-game tests are 40% of the suite. Moving them to a slower tier, or shortening their games, would cut the time more than any other single change.
