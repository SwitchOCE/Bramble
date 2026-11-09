# Static profile of the Bramble test suite and gate (10 Nov 2026)

Tests take 84–93% of every gate, and gate time is growing fast. Paths are relative to /home/alex/code/Bramble-ideation; `-balance`, `-sol` and `-tribes2` are the sibling worktrees. Churn data is in /tmp/claude-1000/profile.GzWk/churn2.json, made by /tmp/claude-1000/profile.GzWk/churn2.py.

## 1. Where gate time goes

From 39 unique gate logs (`build/orchestrator/gates/*.log`, `docs/ideation/evidence/**/*gate*`, sibling copies), median seconds per step:

| step | median s |
|---|---|
| tools, versions, shell, python, content (together) | ~1 |
| format | 17 |
| lint | 18 |
| import | 5 |
| compile | 5 |
| parity | 1 |
| tests | 245 |
| **total** | **291** |

- **Latest gates:** 395–398 s on main (`gates/strong-field-merge.log`, `gates/funprobe-docs.log`). The second one was a docs-only change that still ran the full gate. On wave2a, 551–805 s (`-balance/docs/ideation/evidence/wave2a/*gate*.log`).
- **Godot launches per gate:** 4 real ones (import, `compile_all.gd`, `check_parity.gd`, GUT), plus `godot --version` in the tools step. Import runs a second time only if the first logged problems (`scripts/check.sh` step_import). Godot work outside GUT is about 11 s.
- **Lock held while Godot is idle:** gates run as `flock /tmp/bramble-godot.lock … ./scripts/check.sh` (`tools/sim/evidence/wave1-followup-verification.json:11`). So the steps from tools through lint (median about 36 s) hold the lock without using Godot. `build/orchestrator/lock-samples.csv` shows no Godot running, the lock held, and 3–4 waiters for a minute (19:51:41–19:52:41Z).
- **Cost per test is rising:**
  - 0.135 s (1,655 tests in 223 s, `gates/gate-c74c2b9.log`)
  - 0.18 s (1,894 in 340 s, `build/check/gut.log`)
  - 0.355 s on wave2a (2,092 in 743 s, `-balance/build/check/gut.log`)
- **Full bot games got about 10× slower:** soak cost per game went from 381 ms (`build/check/soak.log`, 7 Nov) to 3.9–5.7 s (`-tribes2` and `-balance` `build/check/soak.log`). Tests that play full games scale with this.
- **No log has times per test or per script.** GUT runs at log_level 1 with no junit output.

## 2. Heavy tests (estimated from the code)

Units used below:
- **H** = one full 8-seat Hard lobby, about 60 fights (`tests/fixtures/field/normal-0946909.json` records 58–61 fights per game). Roughly 2–5 s.
- **S** = one simple-bot `defaults()` game, roughly 0.4 s.
- **K** = one full library build. `UnitLibrary.load_dir` reads 197 JSON files with no cache (`src/core/unit_library.gd:34`). Its cost is unmeasured.

| # | file | work per run | est. s |
|---|---|---|---|
|1|ui/test_playthrough.gd|3 Hard games played through the App; ≥200 tile layout checks|10–30|
|2|core/test_bot_brain.gd|4 full games (naive, hard, 2 replays)|8–20|
|3|core/test_field_normal_regression.gd|4 H; every fight deep-copied and SHA-hashed|8–20|
|4|core/test_field_mode.gd|2 field games; 200 lobby deals; builds a synthetic field library|6–15|
|5|core/test_full_games.gd|9 S; checks the pool every turn|4–8|
|6|core/test_legal_actions.gd|random-action H (≤800 actions) + 1 S|3–7|
|7|core/test_line_policies.gd|1 full + 1 eight-round line lobby|3–7|
|8|ui/test_core_port.gd|1 H through the App + 6 rounds replayed|3–8|
|9|core/test_balance_2.gd|1 H; 200 shop fills; 26 K|3–6|
|10|core/test_fight_capture.gd|1 lobby, every fight captured and replayed|2–6|
|11|ui/test_milestone_b.gd|42 fights through model and log; 1 greedy game|2–5|
|12|core/test_bot_held.gd|≤40-turn legacy Hard game; 24 K|2–5|
|13|core/test_game_log.gd|the same seed-7 game played 4×|2–3|
|14|core/test_pass3_bots.gd|12 Hard rounds; 20 K|1–3|
|15|ui/test_full_game.gd|up to 2×29 `start_game`|1–4|
|16|core/test_combat_logging.gd|320 fights|1–3|
|17|core/test_wave1_lines.gd|4 lobbies × 3 rounds|1–2|
|18|core/test_overlay_text.gd|every card × 4 overlay configs|1–3|
|19|ui/test_cards.gd|1 App game; combat screen up to 3,000 frames|1–3|
|20|ui/test_screens_smoke.gd|6 `start_game`; 2.0 s of real waiting (:99, :103)|≥2|
|21|ui/test_phone_layout.gd|20 frame awaits; loops until 8 offers|1–2|
|22|core/test_birds.gd|70 K (kit built in before_each)|1–3|
|23|core/test_upset_combat.gd|14 K inside tests; 19 capture replays|1–2|
|24|core/test_pass3_combat.gd|43 K; 49 fights|1–2|
|25|core/test_oozes.gd|58 K|1–2|

Across 104 scripts, a run builds the full library about 1,100 times. Most of these come from `RecruitKit` in before_each (`tests/core/recruit_kit.gd:15`).

## 3. Redundancy

- **"The game ends with places 1–8":** about 25 full games across 9 scripts assert this (rows 1–9, 11, 13). The soak (`tools/checks/soak.gd`, 200 seeds) covers it outside the gate.
- **Determinism is checked 4 times:** paired replays in test_full_games (seed 99), test_bot_brain (seed 21), test_field_mode (seed 71) and test_core_port (typed seed). The SHA regression also implies it.
- **The same game played repeatedly:** test_game_log plays the seed-7 game 4 times (`_played_game`, test_game_log.gd:7). Playing it once in before_all saves 3 games.
- **Quiet vs logged fights:** checked by both test_combat_logging (320 fights) and test_bot_brain `test_quiet_fight_has_the_same_result`.
- **Fight capture and replay:** covered by test_fight_capture, test_field_mode `test_captured_fight…`, test_upset_combat's baseline test and the field regression.
- **Golden fixtures that get re-pinned:**
  - The field-regression fixtures were re-pinned 5 times in about 36 hours (15371752, 9cfe2ecd, 04e87b3d, 1bca085c, 44c73292). Content is frozen (`tests/core/field_frozen_content.gd`), so these pins guard code changes and must be re-recorded on every rules or AI change.
  - `normal-9af89c2.json` is unused (`docs/ideation/DECISIONS.md:316`).
  - `tests/core/data/real_designed_recipes.json` changed 3 times in one day; 3fbe34bd only refreshed its pinned hashes after wave2a.
  - `tests/ui/data/recruit_slice.json` changed 8 times.
  - `docs/prototype/fixtures/combat_nightshade.json` changed 8 times, 6 of them since 6 Nov.
- **Count and shape pins:**
  - test_unit_library re-pinned its unit counts in 11 of 12 commits. The content and parity gate steps already report the same counts.
  - test_game_session pins exact state key sets, so its allow-list was edited in 24 commits. Asserting a subset would stop this.

## 4. Churn (non-merge commits since 6 Nov, all ideation/* branches, deduplicated)

Almost every commit that touched data also touched `src/`, so "+data" alone doesn't separate re-pin tests from guards. Re-pins are commits whose only edits in the test were changed numbers, with no new tests.

| file | commits | +data | re-pins (with data) | new tests |
|---|---|---|---|---|
|core/test_game_session.gd|24|11|0 (key-set edits)|1|
|core/test_balance_2.gd|18|8|2 (1)|47|
|ui/test_combat_declutter.gd|18|0|0|26|
|core/test_bot_brain.gd|17|6|0|50|
|ui/test_round4_guide.gd|13|4|0|9|
|core/test_unit_library.gd|12|9|**11 (8)**|0|
|ui/test_portraits.gd|12|8|**7 (6)**|6|
|core/test_slice_keywords.gd|11|7|**7 (6)**|29|
|core/test_balance_1.gd|11|10|4 (4)|42|
|core/test_slice_fairies.gd|11|7|2 (1)|27|
|core/test_belly.gd|11|5|1|36|
|core/test_fly_south.gd|11|5|1|37|
|core/test_bot_held.gd|11|7|0|37|
|ui/test_phone_layout.gd|10|1|0|13|
|ui/test_cards.gd|10|1|0|32|
|ui/test_polish.gd|10|1|0|21|
|ui/test_fixture_port.gd|9|8|**6 (5)**|0|
|ui/test_followup_tribes56.gd|9|6|0|11|
|ui/test_commitment.gd|8|7|2 (2)|6|
|ui/test_engines.gd|8|1|1|15|

## 5. Speed-ups that keep coverage

1. **Measure first.** Add `-gjunit_xml_file=build/check/gut.xml`; GUT already writes each test's time (`addons/gut/junit_xml_export.gd:45`). Alternatively, have `tools/checks/gut_strict_hook.gd` print the 20 slowest tests.
2. **Take the lock only around import→tests.** That frees about 36 s of lock time per gate. Format and lint can also run in parallel.
3. **Split into two tiers.** A fast tier (core and UI unit tests) for worker and reviewer runs. A slow tier (rows 1–17 plus the fixtures) for merge gates and the cloud, selected with `-gtest=`/`-gdir`.
4. **Shard into several Godot processes** using `-gtest` lists balanced by junit times. Two things today make this unsafe:
   - `user://` is shared by every worktree (`/opt/godot-data/godot/app_userdata/Bramble`, per the gut.log header), so `test_*.cfg` files can collide. A separate `XDG_DATA_HOME` per shard fixes this.
   - `res://build/field-test-library.json` (`tests/core/field_test_data.gd:6`) is shared too.

   Memory per GUT process is unmeasured; the only figure is 1.17 GB for loading the real field library (`docs/ideation/strong-field.md:150`).
5. **Cache the parsed library** and give each kit a deep copy (`recruit_kit.gd:89` changes the library). This removes about 1,100 rebuilds per run.
6. **Cut iterations:**

   | test | now | proposed |
   |---|---|---|
   | test_full_games | 5 seeds | 2 |
   | test_combat_logging | 32 seeds | 8 |
   | test_field_mode deals | 200 | 50 |
   | test_bot_brain | naive full game | drop it |
   | test_playthrough (fast tier) | 2 seeds | 1 |
   | test_game_log | 4 games | 1, shared |
7. **Fewer launches and faster cloud setup.** Fold parity into GUT (`tests/core/test_check_parity.gd` exists) to save one launch. In the cloud, cache `.godot/` keyed by a hash of the project files.
