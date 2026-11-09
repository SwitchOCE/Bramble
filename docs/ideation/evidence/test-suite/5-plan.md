# Test suite and Godot lock plan, 10 Nov

## 1. Findings

- **Where Godot time went (6–9 Nov):** about 54 h in total. Sims used 58% (about 31 h). Gates and GUT used about 31%. There were 307 full gates, about 15.5 h of lock time. Source: `/tmp/claude-1000/runhist.Prqr/runs.csv`.
- **What the failures were:** 337 runs failed. Only 28 were real regressions, about 19 separate incidents. 41 were re-pins after intended changes, 40 were environment or flaky failures, and 136 were deliberate red runs while writing code. Source: `/tmp/claude-1000/runhist.Prqr/per_file.csv`.
- **Which tests catch regressions:** all catches came from UI and contract tests, such as test_cards, test_core_port, test_polish, test_phone_layout, test_portraits and test_playthrough. The core whole-game tests caught **none** and are the slowest: bot_brain, the field regression, balance_2, bot_held, pass3_bots and line_policies. bot_brain alone took 62 s of the 223 s tests step on 7 Nov. Source: `/tmp/claude-1000/prune.7nSA/measured.txt`.
- **Fewer runs would have done:**
  - About 30 of the 307 gates (about 2 h) re-ran a tree that was unchanged or had only docs changes.
  - 11 of the 16 merges since 9 Nov changed nothing outside docs/ compared with the tip the worker had already gated.
  - The orchestrator's 41 gates caught 0 regressions.
  - Sources: runhist §4, `/tmp/claude-1000/gatedesign.cYUE/rev.json`.
- **Most commits needed few or no tests:** a replay of 404 commits found that 59% needed no Godot tests and 16% needed the full suite. On average 22% of tests were relevant. Source: `/tmp/claude-1000/gatedesign.cYUE/select.py`.
- **Tests that fail on every content change:** five count and key-list tests caused 32 of the 88 re-pin failures (unit_library, portraits, fixture_port, slice_keywords, game_session). The field-regression fixtures were re-pinned 5 times in 36 h. Source: `/tmp/claude-1000/profile.GzWk/churn2.json`.
- **The suite is not as fast as it can be:**
  - The tests step median is 245 s.
  - Cost per test rose from 0.135 s to 0.355 s in 3 days.
  - Each run builds the unit library about 1,100 times.
  - About 25 full games check the same "places 1–8" ending.
  - No log records per-test times.
- **The lock queue:**
  - 97% of samples had someone waiting (median 3).
  - 13% of gate lock time is non-Godot steps (about 36 s per gate).
  - Measured waiting is at least 67 min, and probably 3–6 h in total.
  - Source: `/tmp/claude-1000/runhist.Prqr/lock-samples-snapshot.csv`.
- **The cloud:**
  - The repo is public, so GitHub Actions minutes are free.
  - `ci.yml` already runs `check.sh`, but only on PRs and manual runs, and manual runs also build exports.
  - The routine gate takes 7.5 min and runs one gate at a time (`docs/ideation/DECISIONS.md`, 10 Nov).

## 2. Plan

**Step 1 – Working rules (orchestrator, today, DECISIONS.md and worker briefs)**
- A merge needs no new gate if `git diff <gated tip> <merge>` touches only docs that no code reads. Otherwise it gets a cloud full gate.
- Reviewers cite the worker's gate and run only the test files they target.
- Workers run targeted test files while iterating, plus one full gate per step, in the cloud.
- The orchestrator uses `--docs-only` for its own docs commits.
- *Proof:* local full gates per day drop from 51 (9 Nov) to 10 or fewer, counted from the slot log.
- *Saving:* about 30 gates per 4 days avoided outright, and most of the rest leave the lock.

**Step 2 – Lock only the Godot steps, and time every test (one worker: `scripts/check.sh`, new `scripts/godot_slot.sh`)**
- Move `/tmp/bramble-godot-slot` into the repo. check.sh takes a slot only from import through tests.
- `BRAMBLE_SLOT_HELD=1` stops check.sh waiting on its own lock.
- Each run logs class, wait, hold and exit to a CSV.
- Add `-gjunit_xml_file=build/check/gut.xml` and print the 20 slowest scripts.
- *Proof:* (1) the logged hold is at most the Godot steps' time plus 5 s; (2) gut.xml has a time for every test.
- *Saving:* about 36 s of lock per gate (about 40 lock-minutes a day), plus the timings that steps 5 and 6 need.

**Step 3 – Cloud gate on GitHub Actions (one worker: `ci.yml` on ideation/main only, new `scripts/cloud-gate.sh`)**
- Add `push: branches: ["ideation/gate/**"]` to `ci.yml`. It runs the gate only, without exports.
- Split the tests 4 ways, balanced by junit times, with the static steps on shard 1 only.
- `cloud-gate.sh` pushes HEAD to `ideation/gate/<topic>`, watches the run in the background and prints the tail of a failure.
- The orchestrator pushes the gate branches, and branches merge ideation/main first.
- The routine trig_01Bu2zM5 and a local slot gate remain as fallbacks. main is not touched.
- *Proof:* (1) on 3 commits, one with a deliberately failing test, cloud and local give the same verdict and test count; (2) the median time from push to verdict is 6 min or less over the first 5 runs.
- *Saving:* about 35 full gates a day off the local lock (about 210 Godot-minutes on 9 Nov's volume), at no cost.

**Step 4 – Gate-result cache (one worker: new `tools/checks/gate_key.py`, check.sh, cloud-gate.sh)**
- The key is a sha256 of the tree outside docs/, plus the docs that code reads (reuse `docs_only_paths.py`), plus the mode and the Godot version.
- Only clean trees use the cache, and only full passes are written. The cloud gate writes its entry on a pass. `--no-cache` forces a run.
- *Proof:* (1) a docs-only merge of a gated tip prints `cached PASS` without starting Godot; (2) changing one byte in `src/`, and separately in `docs/ideation/engine.md`, both miss the cache.
- *Saving:* about 21 gates in 4 days (about 85 min). It also turns step 1's merge rule into a mechanical check.

**Step 5 – A faster suite with the same guards (one worker: `tests/core/recruit_kit.gd`, helpers, the listed tests). Re-rank by step 2's timings first.**
- Parse the library once and give each kit a deep copy.
- Play one shared Hard lobby per run, used by balance_2, bot_brain and full_games' per-turn pool check. test_game_log plays seed 7 once.
- Shrink:
  - full_games: 5 seeds to 2
  - combat_logging: 32 seeds to 8
  - field_mode: 200 deals to 50
  - bot_held: 40 rounds to 12
  - pass3_bots: 12 rounds to 8
  - bot_brain replay: 8 rounds
  - screens_smoke: steps the screen by hand instead of 2 s of real waiting
  - full_game: pins the seed
- *Proof:* (1) the junit tests-step time drops by at least 55 s on the same machine; (2) three planted bugs (pool leak, nondeterminism, quiet and logged fights giving different results) each still fail the suite.
- *Saving:* about 55–110 s per full run (estimated from the code).

**Step 6 – Stop re-pins; move or delete tests that never caught anything (one worker)**
- **Rewrite** the counts and card numbers to come from the data:
  - unit_library (unit count equals the unit files; the pool is part of all units)
  - portraits, fixture_port, slice_keywords, benchmark_boards
  - the card-number asserts in balance_1/2, belly, fly_south, slice_fairies and bot_held
  - game_session's key list, read from `engine.md`
- **Move to cloud-only:** field_normal_regression, bot_brain's pinned-strategy game and playthrough's second seed. They run in every cloud gate and nightly.
- **Delete, with the replacement that covers it:**
  - bot_brain's quiet-fight test, covered by combat_logging
  - the Hard half of bot_brain's full-game test, covered by the shared Hard lobby and the field regression
  - `normal-9af89c2.json`, which nothing reads
- *Proof:* (1) adding a dummy unit fails none of the rewritten tests; (2) a missing portrait, a wrong state key and a unit file that fails to load each still fail them.
- *Saving:* removes the source of 32 of the 88 re-pin failures, and about 45–75 s from local runs.

**Expected result:**
- **Suite:** the local tests step goes from 245–340 s to about 190–230 s. A cloud verdict takes about 5 min, against 10–15 min locally plus the queue.
- **Lock:** gate lock time goes from about 326 to about 80 min a day. The shared slot goes from about 90% to about 30% busy. Modelled mean wait goes from about 45 min to about 2 min. This is a model; step 2's log checks it after one day.

## 3. What stays as is

- **UI and contract tests stay:** they made every catch.
- **Red-first test runs stay:** they are the normal development loop and cheap (median 2 s).
- **The two-Godot cap and MemoryMax=3G stay:** a third slot only if step 2 measures test runs near 1 GB, or after the owner's RAM upgrade.
- **Sims stay out of scope:** they are 58% of Godot time, keep the harness slot only, and heavy sweeps keep going to the cloud. This plan doesn't change them.
- **Kept because they are cheap or guard formats the sims rely on:** test_fight_capture, test_engine_docs, test_mech_* and test_wave1_lines.
- **Automatic test selection (`--impact`) is deferred:** workers already pick their own targeted files, and src/core changes need the full suite anyway.

## 4. Risks and backstops

- **A cache pass hides a flaky or environment failure:** a nightly cloud `--no-cache --keep-going` run on ideation/main and active branch tips, plus a 200-seed soak.
- **The cache key misses an input:** the key covers everything outside docs/ plus the docs code reads, step 4 tests this with deliberate one-byte changes, and the nightly run doesn't use the cache.
- **Shrinking or moving whole-game tests misses a bot or rules bug:** one shared Hard game still runs every time, the field regression runs in every cloud gate, and sims play these code paths hundreds of times a day.
- **Cloud and local disagree** (for example a stale local `.godot` cache): the fresh cloud checkout decides. A local gate runs only when Actions is down.
- **Something merges untested:** ideation/main moves only on a full pass for that exact tree, or on a docs-only diff from such a tree, and the cache enforces it.
- **The failure classes are judgement calls:** about 45 failed gates don't show which files failed, so per-file catch counts are low. Nothing is deleted before step 2's timings exist.
