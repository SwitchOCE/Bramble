# Brief: a faster suite with the same guards (test-suite plan step 4)

Written by the orchestrator, 10 Nov 2026, for a cloud session. The routine's prompt points here.

You build step 4 of the approved test-suite plan: a faster suite with the same guards. Read:
- `docs/ideation/plan-test-suite.md` (**Approved order**, and the draft steps 5 and 6 for detail);
- `docs/ideation/evidence/test-suite/4-pruning.md` (the row-by-row candidates);
- `docs/ideation/evidence/test-suite/6-critic.md`;
- `docs/ideation/evidence/test-suite/game-profile/README.md` (merged into ideation/main as 66289bc5).

The owner's note is `docs/design/owner-notes/2026-11-10a-godot-lock-and-test-suite.md`: "I'm assuming that test suite performance is as good as we can get it. If that's not the case, maybe that should be a focused run... I wonder if... there are some tests that wouldn't have caught regressions anyway, and we can remove some and build a smarter, more performant test suite."

**Why now:** with wave 2a merged, the Actions tests step on ideation/main took 771 s, against 353 s before, for 13% more tests; the combat fast paths cut it to 559 s (run 42706292823). Wave 2b (Oozes) and the Quilboar reference may land on ideation/main while you work: merge ideation/main into your branch before your last measurement and say which commit you measured. `GUT_TIMEOUT` is 1,200 s. The slowest scripts on Actions after the fast paths (run 42706292823) are:

| Script | Time |
|---|---|
| test_bot_brain | 64.3 s |
| test_field_normal_regression | 31.3 s |
| test_playthrough | 17.7 s |
| test_placing_bar_probe | 17.5 s |
| test_wave1_lines | 16.4 s |

The game profile found that Hard bots' board-search quiet fights are 75–78% of a full Hard lobby: about 1,400 fights a lobby at about 10 ms each.

Work on a new branch `ideation/c-faster-suite` from `ideation/main` and push it. Rank the work by junit times measured on this tree. Run the full suite once here first for your own `gut.xml`, since the plan's estimates predate wave 2a.

**What to change, in order of payoff:**
1. **Whole-game tests that don't test the bot's skill.** Find every test that plays a full or long Hard lobby only to reach a state: game over, a log shape, pool conservation, determinism, a UI screen. For each, either:
   - share one lobby per run, played once and read-only or deep-copied; or
   - give those tests a cheaper bot, such as a smaller board-search budget set through the game config.

   Tests that pin Hard's own choices keep the real budget: the field regression, the Hard pins in bot_brain, the placing-bar probe. If a cheaper bot changes a pinned hash, that test isn't a candidate. Don't re-pin it to make it fit.
2. **5a, the library cache:** parse the unit library once a run and give each kit a deep copy (pruning row 19). Measure one build first, and confirm a deep copy beats a parse.
3. **5b, the iteration cuts in 4-pruning.md**, re-ranked by your junit times: rows 3, 6, 7, 9, 10, 11, 12, 14, 17 and 18.
4. **The deletes:** the Hard half of bot_brain's full-game test (row 2), and `tests/fixtures/field/normal-9af89c2.json` (row 27). Keep row 13's quiet-fight test (the critic's cut). Every deleted or shrunk test names, in a comment or in your report, the test that still guards its behaviour.

Don't touch `scripts/check.sh` or `.github/workflows/ci.yml`; another session is sharding the gate. Don't change game rules or bot behaviour outside tests. A game-config knob that only tests set is fine.

**Deciding criteria (only these two):**
1. **The tests step's junit total drops by at least 25%** on the same machine. Measure your branch tip against the ideation/main commit you started from, both here, one Godot process at a time.
2. **Three planted bugs each still fail the suite,** on throwaway branches you never push to your work branch:
   - a pool leak (a sold or eliminated unit doesn't return to the pool);
   - nondeterminism (an unseeded random call in a fight or a bot);
   - quiet and logged fights differing.

   Name the test that caught each one.

Also report, not as criteria: the before and after time for each changed script, and the total test count before and after, with every removed test named.

Run the full `./scripts/check.sh` before your last push. Your final message is under 300 words: the commits, the two criteria with their numbers, and anything you couldn't do or chose not to cut.
