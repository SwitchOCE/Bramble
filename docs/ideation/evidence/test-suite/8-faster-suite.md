# A faster suite with the same guards (test-suite plan step 4)

**Branch:** `ideation/c-faster-suite`, from ideation/main 814793b9, merged with 001460b9 and then 3d96ce3f (wave 2b); final branch tip 3deb96f2, integrated with play tools at da20e53e. **Original local measurement:** 814793b9 against 4c572c86, both with a full `./scripts/check.sh` in the same cloud session (4 cores, Godot 4.7.2), one Godot process at a time. This machine is about 1.7× slower than Actions (931 s here against Actions' 559 s for the same tree).

## Criterion 1: the tests step's junit total

**Actions: 773.404768 s → 363.772793 s, −53.0%**, exceeding the 25% bar. Both gates succeeded. Retrieved with `gh run list --branch ideation/gate/6888ee1ce861`, `gh run view` and `gh run download` on 10 Nov 2026. Each total sums the `<testsuite time>` attributes in all four `gut-junit-{1,2,3,4}/gut.xml` artifacts (equivalently the testcase times), rather than adding parallel job wall times.

| Gate | Commit tested | JUnit shard totals (s) | Total (s) | JUnit cases |
|---|---|---|---|---|
| [Last ideation/main gate before the faster suite](https://github.com/SwitchOCE/Bramble/actions/runs/42732753045), push `ideation/gate/6888ee1ce861` | `6888ee1ce8617f72a5b821f6d1f195d47ef48a0c` | 251.798005 + 140.206283 + 151.983107 + 229.417373 | **773.404768** | 2,393 |
| [Merged play tools and faster suite](https://github.com/SwitchOCE/Bramble/actions/runs/42741514510) | `da20e53ea017e7350119fce099539990ebbf6911` | 113.269508 + 79.634960 + 75.025165 + 95.843160 | **363.772793** | 2,404 |

These are one run per tree, with intervening content/tests and play tools changes; they measure the integrated gate improvement, not an isolated estimate for each optimization. JUnit cases include parameterized cases, so exceed the number of `func test_` declarations.

Earlier local evidence, retained for context: **931.0 s → 508.7 s, −45.4%** on 814793b9 → 4c572c86. Tests step wall time 953 s → 527 s. 2,158 tests → 2,160, all passing. Those numbers were pre-wave-2b and are not the Actions criterion.

## Criterion 2: three planted bugs

The planted-bug base is inferred to be the measured faster-suite tree `4c572c86f9382f69074e3b9f35d807ce3cf9488e`, the parent of evidence commit `cafdc88018c91df57cfc8b17ece9603701465229`. Each was planted on a throwaway local branch (never pushed, deleted after) and the whole GUT suite run. The surviving evidence identifies the measured tree and the results, but contains no individual throwaway branch SHAs; the base attribution follows that commit history. They were not rerun on da20e53e for this follow-up.

| Planted bug | Where | Failing tests | Caught by (among others) |
|---|---|---|---|
| Pool leak: a sold unit's copies don't go back | `RecruitRules.sell` | 8 | test_recruit_rules `test_sell_returns_pool_copies_5_3_4`; test_full_games' new `test_the_shared_hard_lobby_ends_with_places_and_conserves_the_pool_5_3` and `test_bot_games_end_with_one_winner_1_1_3`; test_triples; test_bog_folk; test_fly_south; the field regression |
| Nondeterminism: an unseeded coin for the first attacker | `Combat._first_side` | 21 | test_bot_brain `test_a_seed_replays_exactly` (now 8 rounds); test_full_games `test_same_seed_same_game_determinism`; test_fight_capture; test_field_mode; test_upset_combat; the field regression |
| Quiet and logged fights differ (quiet fights flip the first attacker) | `Combat.run` | 4 | test_combat_logging `test_last_blow_credit_and_results_are_identical_without_event_logging`; test_feedback5_log; test_upset_combat; the field regression |

## What changed, by payoff

1. **The library cache (5a), the largest saving.** One build measured first: `UnitLibrary.load_dir()` 74 ms, `LegacyWave1.library()` 192 ms, a deep copy 3.7 ms. A `full_game()` kit also built the configured overlay twice (`UnitPool.create` and `RecruitRules.create`, ~125 ms each), so a kit took 329 ms. `tests/core/library_cache.gd` (`TestLibraries`) builds each library once a run and hands out deep copies; RecruitKit gets a copy of the configured overlay, which `ScaleOverlay.library_for` then returns as it is. The 877 tests in the 0.2–0.5 s band (277 s) mostly dropped under 0.05 s. A cached build is rebuilt when the effect schema or the pass-3 rates change, and the three tests that edit the rates and then parse still call `UnitLibrary.load_dir()`; so do test_unit_library's.
2. **One shared Hard lobby a run** (`tests/core/shared_lobby.gd`): balance_2's seed-5 `full_game()` lobby with real Hard budgets, played once, read as deep copies. It records per-turn pool totals (via `PlayerState.all_units`, which counts away Birds, doorstep and poached units).
3. **Cheaper bots where Hard's choices aren't the subject:** the UI playthrough seats Hard as `hard:varied@search=4` (an existing bot-name arm; no game code changed). The Hard pins keep the real budget: the field regression, `test_a_pinned_bot_plays_its_strategy`, the placing-bar probe, bot_held, pass3_bots.
4. **Iteration cuts**, re-ranked by junit time.

## Per-script times (s), changed scripts

| Script | Before | After | Change |
|---|---|---|---|
| test_bot_brain | 127.2 | 82.4 | Hard half of the full-game test → shared lobby; seed replay 8 rounds |
| test_playthrough | 30.4 | 24.3 | Hard with a 4-fight search |
| test_wave1_lines | 27.6 | 15.6 | lines reloaded once per test (before_all + after_each), not twice |
| test_bot_held | 23.9 | 16.9 | real-game test 40 turns → 12 rounds |
| test_balance_2 | 22.1 | 14.5 | reads the shared lobby |
| test_pass3_bots | 18.3 | 5.8 | real Hard lobby 12 → 8 rounds |
| test_round4_bugs | 9.0 | 1.7 | 40 sessions share a configured library |
| test_game_session | 6.1 | 1.9 | the same |
| test_full_games | 4.9 | 3.5 | 5 → 2 seeds, skeleton 2 → 1; new pool check on the shared lobby |
| test_screens_smoke | 4.1 | 2.2 | playback stepped by hand instead of 2 s of waiting |
| test_game_log | 3.0 | 0.9 | plays seed 7 once per script |
| test_field_normal_regression | 58.0 | 71.9 | unchanged (frozen library; machine noise) |
| test_placing_bar_probe | 31.1 | 32.0 | unchanged |

Unchanged scripts gained from the cache alone, e.g. test_big_numbers 17.4 → 2.9, test_overlay_text 16.7 → 1.5, test_birds 13.9 → 1.1, test_oozes 13.5 → 1.2.

## Removed and added tests

- **Removed:** `test_bot_brain::test_best_and_naive_profiles_play_full_games`, split into `test_naive_profiles_play_a_full_game` (the naive game, as before) and `test_hard_profiles_play_a_full_game` (reads the shared lobby). Hard whole games are still played by the shared lobby and `test_field_normal_regression` (four pinned games).
- **Added:** `test_full_games::test_the_shared_hard_lobby_ends_with_places_and_conserves_the_pool_5_3` (pruning row 9's per-turn pool check on the real config).
- **Deleted fixture:** `tests/fixtures/field/normal-9af89c2.json` (row 27; nothing reads it; DECISIONS.md had kept it).
- **Shrunk, with what still guards:** seed replay (row 3) → whole-game determinism stays in test_full_games and the field regression's hashes; bot_held (row 6) and pass3_bots (row 7) still assert swallow, fly_south, home and rings within the shorter run.
- **Kept:** row 13's quiet-fight test (critic's cut).

## Not cut (cost under 1 s each after the cache)

Rows 11 (field_mode 200 deals, 0.6 s), 12 (combat_logging 32 seeds, 0.4 s), 14 (legal_actions game over, 0.25 s), 18 (aimed hero seeds, 0.4 s). Cutting them saves under 2 s and thins guards; the plant above shows row 12's test is the one that names a quiet/logged split. Not changed: `tools/sim/line_policies.gd` parses the library inside `normalize_wave1` per line, which is most of what remains in wave1_lines, line_bans and committed_lines; that is tools code, outside this brief.


## S10b review follow-ups

- `test_a_seed_replays_exactly` now runs two whole current-content games with eight `SharedLobby.QUICK_HARD` seats, asserts that both finish, and compares their full logs. The comments above describing the original eight-round cut are historical.
- `test_library_cache.gd` mutates nested unit, spell-stat and hero data plus errors, then compares a new cached copy with a fresh parse. It also checks every script variable against the copied value, asserts the complete field inventory so a new field requires an explicit decision, and checks the copied unit index points into the copied units.
- Combat playback still steps frames by hand and now asserts `combat.is_processing()` first.
