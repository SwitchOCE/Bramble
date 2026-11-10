*[Saved verbatim from the scope-reviewer's hand-back, 10 Nov: `ideation/c-faster-suite` `3d96ce3f..3deb96f2` (S10). Calls: DECISIONS (ideation/main) "Faster suite (S10): review calls".]*

**Counts:** 16 keep, 0 cut, 0 simplify, 3 ask.

**Does it move the owner's problem?** Yes, the "more performant suite" half of it. A full run's junit time fell about 45%, but that was measured once each, in the cloud session, on a tree before the last merge. The three planted bugs still fail the suite. I found one real narrowing of a guard (ask 1). "Fewer runs" and "smarter scheduling" belong to other plan steps, not this one. It removes 1 test and 1 unused fixture, which fits the plan's finding that the data supports re-scoping tests, not mass deletion.

**Ask items:**
1. `tests/core/test_bot_brain.gd:95-104`: the seed replay now stops at 8 rounds, so nothing replays a whole current-content Hard game any more. The comment at :97 overstates the remaining guards.
2. `docs/ideation/evidence/test-suite/8-faster-suite.md:3-7`: the 45% was measured at 4c572c86, not at the tip 3deb96f2, and not on Actions, which is what the approved criterion names. It also doesn't say which commit the planted bugs ran on.
3. `tests/core/library_cache.gd:80-89`: no test checks that a cached copy equals a fresh parse, so nothing pins the cache's correctness.

All three inputs were given (target, owner's words, plan text). I read the plan docs at 3d96ce3f, the change's base. On origin/ideation/main they differ only in plan-to-done.md lines unrelated to S10. I didn't look at Actions results or anything after 3deb96f2. I ran no Godot, so the timings and planted-bug counts are checked for consistency, not re-run.

---

## Answers to your four questions

**Can the shared cache leak state between tests?** Reading the code, I found no path. It is still unproven by any test (ask 3).
- **Copies are deep and are the only thing handed out.** `copy()` (`library_cache.gd:80-89`) deep-copies each unit and points `_by_id` at the copy. `_cards` and `_heroes` are deep-copied too.
- **Nothing compiles into the stored libraries.** `MechanicRegistry.compiled` writes `_compiled` into unit dicts, but only copies ever reach a game. `ScaleOverlay.card_for` drops `_compiled` when it builds an overlay (`scale_overlay.gd:82`).
- **No metadata is shared.** The only library metadata in src is `scale_overlay_key`, `reference_quilboar` and `scale_overlay_source`. The first two are plain values, and the third is replaced with a fresh copy (`library_cache.gd:50-53`). Nothing else calls `set_meta` on a library.
- **Rebuild checks:** a stored library is rebuilt when the effect schema is swapped (`:63`) or the pass-3 rates change (`:74-76`). Those are the only static inputs the parse reads; ScaleText's `_patterns` is derived from the schema. No test edits the schema in place; field_frozen_content swaps it.
- **Overlay key:** it is production's own `ScaleOverlay._key` plus the base library's id (`:44`). I checked every config field read by card_for and its helpers (ScaleText, ScaleLeverText, Pass3Text, Pass3RowSwap, ReferenceQuilboar). All are in the key, and Pass3Text's rate keys go through `Pass3Rates.resolved`. `detect_pool` runs before the key is built, as `RecruitRules.create` does.
- **No test writes unit files.**
- **Order:** the shared lobby is played by its first reader, test_balance_2, which is where that game was played before.

**Does any cut remove the only guard of a behaviour?** Two do.
- **Seed replay (ask 1).** Before, `test_a_seed_replays_exactly` replayed a whole full_game lobby (Hard and Naive seats, current content). Now it stops at 8 rounds. The comment names two remaining guards, and neither covers this case:
  - test_full_games' replay uses `GameConfig.defaults()`: the old library and greedy/wide/tribe/balanced bots (`test_full_games.gd:15-25`, `game_config.gd:87`).
  - The field regression replays content frozen at 0946909 (`test_field_normal_regression.gd:13`), which predates wave 2b.

  So a nondeterminism bug that only shows after round 8, in current content, has no guard. The cut is approved (pruning row 3), so this is an ask, not a cut. Two options:
  - replay the whole game with the cheaper Hard seats from `SharedLobby.QUICK_HARD`; or
  - accept the gap and correct the comment.
- **Combat playback (small).** `test_screens_smoke.gd:100-110` now calls `_process` by hand. Nothing checks any more that the combat screen advances on real frames. One line, `assert_true(combat.is_processing())`, would keep that guard.
- **Bare "hard" seats (minor).** The removed Hard half played bare `"hard"` seats; the shared lobby plays `"hard:varied"`, which is what real lobbies use. Bare `"hard"` now runs only 8 rounds.

**Is `src/` untouched?** Yes. The diff from 3d96ce3f to 3deb96f2 touches only `tests/` (94 files) and the one evidence doc. Nothing changed in src/, content/, tools/, scripts/, `.github/` or project.godot, and neither merge resolution altered a non-test file. `hard:varied@search=4` is an existing bot-name option (`bot_brain.gd:58-65` at 3d96ce3f). `TestLibraries` and the shared lobby are used only by tests, and `tests/*` is excluded from exports.

**Do the evidence's numbers follow from what was measured?** Mostly.
- **What checks out:**
  - The arithmetic: (931.0 − 508.7) / 931.0 = 45.4%.
  - The test counts: `func test_` counts are 2,158 at 814793b9, 2,160 at 4c572c86, 2,317 at 3d96ce3f and 2,319 at 3deb96f2.
  - The split of the saving: the changed scripts save about 107 s, which leaves about 315 s from the cache alone, consistent with the 877 tests in the 0.2–0.5 s band.
- **What doesn't (ask 2):**
  - The before and after are single runs. An unchanged script, the field regression, moved +13.9 s (58.0 to 71.9), so per-script changes under about 14 s can't be told from noise. That includes the playthrough's −6 s, which is the whole case for its cheaper bot. The total holds with a wide margin.
  - The measured tree is 4c572c86. The tip adds the wave-2b merge (159 more tests) and the cache's merge fixes, and is unmeasured.
  - The approved criterion is "The Actions junit time of the tests step drops by at least 25%" (`plan-test-suite.md:54`). The brief changed it to a same-machine run in the session.
  - The doc header still lists only the 001460b9 merge.
  - Fix: when the tip's cloud gate runs, compare its junit total with 3d96ce3f's, and write both into the doc along with the commit the planted bugs ran on.

---

## What the change does

**Sources of intent:**
- the owner note of 10 Nov;
- `plan-test-suite.md:52-56`, step 4: "5a library cache, 5b iteration cuts and a shared read-only lobby, plus the three deletes, ranked by junit times";
- the pruning rows in `4-pruning.md`;
- the brief (orchestrator proposals);
- the commit messages.

1. **Schema / data:** none.
2. **Scheduled / background:** none.
3. **Features:** none. Tests only.
4. **External:** none.
5. **Config:** no new keys. The playthrough sets the existing `bots` value to 7 × `hard:varied@search=4` (`test_playthrough.gd:37-41`, `shared_lobby.gd:13,27-31`).
   - Used by: test_playthrough only.
   - Stated reason: brief item 1, "a cheaper bot, such as a smaller board-search budget set through the game config" (orchestrator).
6. **Public interfaces (test-only):**
   - The global class `TestLibraries`, with `current`, `cached`, `configured` and `copy` (`library_cache.gd:17-89`).
   - `LegacyWave1.build` and the `current_with_*` helpers (`legacy_wave1.gd:13,44,70,77`); `LegacyBog.build`; `LegacyHunters.build`.
   - Used by: about 80 test files. Direct `UnitLibrary.load_dir()` calls in tests went from 181 to 31.
   - Stated reason: 5a, "parse the library once and give each kit a deep copy" (pruning row 19).
7. **Internal machinery:**
   - **Library cache:** a static `_cache` that rebuilds on a schema swap or a rates change, with overlays keyed by their base build (`library_cache.gd:13,31-76`).
     - Used by: RecruitKit (`recruit_kit.gd:21`), CombatKit (`combat_kit.gd:8`), and the 40-game hero tests (`test_round4_bugs.gd:17`, `test_game_session.gd:135`).
     - Stated reason: 5a.
   - **Shared Hard lobby:** a static `_played` holding seed 5, full_game, real Hard search; each read gets a deep copy (`shared_lobby.gd:15-67`).
     - Used by: balance_2 :48, bot_brain :86, full_games :66.
     - Stated reason: 5b, "a shared read-only lobby".
   - **Seed 7 played once per script** (`test_game_log.gd:7-13`). Row 10.
   - **Combat screen stepped by hand** (`test_screens_smoke.gd:108`). Row 17.
8. **Deleted or shrunk:**
   - `tests/fixtures/field/normal-9af89c2.json` (row 27; nothing in tests, tools or src reads it).
   - `test_best_and_naive_profiles_play_full_games`, split into a Naive test plus a shared-lobby Hard test (row 2).
   - Seed replay cut to 8 rounds (row 3).
   - bot_held cut from 40 turns to 12 (row 6).
   - pass3_bots cut from 12 rounds to 8 (row 7).
   - full_games cut from 5 seeds to 2, and skeleton from 2 seeds to 1 (row 9).
   - wave1_lines: `before_each` became `before_all` (no pruning row; the worker's own).

**Unrequested:** the wave1_lines hook change (the worker's), the playthrough's cheaper bot (orchestrator brief), and the `current_with_*` helpers (needed to resolve the merge).

**Size:** 95 files, +530 / −912 lines (713 of the deletions are the fixture).

---

## Verdicts

| Item | Verdict | Evidence | Action |
|---|---|---|---|
| Library cache | keep | Approved 5a. Biggest saving (about 315 s). Leak analysis above. | none |
| RecruitKit gets a configured copy | keep | `recruit_kit.gd:21`. Pool and rules now share one overlay, as in GameSession. | none |
| Legacy helpers split into `library()` / `build()` | keep | Same keys and builders as `configured()`'s legacy base ("wave1:true"). | none |
| Call-site swaps in about 80 files | keep | Mechanical. The parses left are parse tests, levers, and the newly merged Quilboar tests. | none |
| Configured copy per game in the hero tests | keep | 9.0 s to 1.7 s and 6.1 s to 1.9 s. | none |
| Shared Hard lobby | keep | Approved 5b. Real Hard search, deep copies. | none |
| New pool check on the shared lobby | keep | `test_full_games.gd:66`. Adds a guard on the real config (row 9). It caught the planted pool leak. | none |
| bot_brain Hard half moved to the shared lobby | keep | Row 2, approved. `test_bot_brain.gd:75,86` still check over, no errors, 8 players, builds. | none |
| Seed replay cut to 8 rounds | **ask** | `test_bot_brain.gd:95-104`; comment at :97 is inaccurate. | Replay the whole game with the cheaper Hard seats, or fix the comment and accept the gap. |
| full_games seeds 5 to 2, skeleton 2 to 1 | keep | Row 9. The shared lobby covers the real game. | none |
| bot_held 40 turns to 12 | keep | Row 6. Its "> 0" checks still pass. | none |
| pass3_bots 12 rounds to 8 | keep | Row 7. | none |
| game_log plays seed 7 once per script | keep | Row 10. Its readers only read (`test_game_log.gd:25-71`). | none |
| wave1_lines `before_all` | keep | `after_each` already reloads the lines, so the old `before_each` was a duplicate. 27.6 s to 15.6 s. | none |
| screens_smoke steps frames by hand | keep | Row 17. Small gap, above. | Optionally add `is_processing()`. |
| Playthrough cheaper Hard seats | keep | Orchestrator proposal. Hard's choices aren't what this test checks. An explicit config turns off CorePort's saved-settings path (`core_port.gd:25`) for this test; test_cards, test_polish and test_field_settings still use that path. The −6 s is within noise. | none |
| Delete `normal-9af89c2.json` | keep | Row 27. Reverses DECISIONS.md:728 "Kept", as the brief asked. No speed effect. | none |
| Evidence doc numbers | **ask** | Above. | Compare the tip's Actions junit time with 3d96ce3f's; update the doc. |
| No test of the cache itself | **ask** | `copy()` lists UnitLibrary's five private fields; a field added later would be dropped silently from every test library. The rebuild checks are exercised only indirectly. | Add one test: mutate a copy, then check that `TestLibraries.current()` matches `UnitLibrary.load_dir()` in units, cards, heroes and errors. |

**Cut:** none.
**Simplify:** none worth the churn.

**Gaps:**
- Whole-game determinism for current content (ask 1).
- Real-frame combat playback (one-line fix).
- A self-test for the cache (ask 3).

**Original problem:** a full run's junit time is about 45% lower (one run each, pre-merge tree), with the planted bugs still caught. Lock and scheduling work stays with the other steps.

**Open questions for the orchestrator:**
1. Should whole current-content games still be replayed for determinism? The cheap version is the 4-fight Hard seats for a whole game.
2. Is a pass on the tip's Actions gate, read against 3d96ce3f's junit total, enough to count as criterion 1?

Files: `/home/alex/code/Bramble-ideation/tests/core/library_cache.gd`, `/home/alex/code/Bramble-ideation/tests/core/shared_lobby.gd`, `/home/alex/code/Bramble-ideation/tests/core/test_bot_brain.gd`, `/home/alex/code/Bramble-ideation/tests/ui/test_screens_smoke.gd`, `/home/alex/code/Bramble-ideation/docs/ideation/evidence/test-suite/8-faster-suite.md`. All read at 3deb96f2 through `git show`; nothing checked out.
