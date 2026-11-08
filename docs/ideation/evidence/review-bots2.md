# Review 2: engines merge into ideation/bots, and the review fixes

8 November 2026. Fresh cloud reviewer. Target `c8693ae..46bd740` on `ideation/bots`. Scope: the owner's words of 8 Nov ("the best players we possibly can", "that bot get better", "No easy, no medium bot"), `BOTS.md`, and the asks of `review-bots.md`.

**Counts: 0 cut, 2 ask, 1 simplify.** **Does it move the problem? Partly.** It doesn't make the bots stronger. It does keep the promoted Hard intact on the engines rules and clears the earlier review, so the next candidate can be measured on the current ruleset.

- **Ask 1:** `tools/sim/candidates/acorn_stash.gd:1` (248 lines), its registry entry at `tools/sim/bench_suites.gd:33` and `tests/core/test_acorn_stash.gd` are still in the gate, even though Acorn Stash failed (+0.0110 ±0.0454). Ask 2 deleted the failed saving candidate on the grounds that "failed policy code need not remain in the active gate". Should that apply to every failed candidate?
- **Ask 2:** `docs/ideation/BOTS.md:47` counts a **pre-engines** trial as failure 1 toward the two-failure stop. Should a trial run on rules that have since been replaced count?
- **Simplify 1:** `tools/sim/build_release_bench.py:29-55`, `--search-events`, rewrites core source by string replacement to prove parity once. The GUT test and an editor-binary flip (below) prove the same thing. Drop it, or keep it as a scratch script outside the release builder.

**Keep:**
- **Merge resolution.** Diffed against main with whitespace ignored, `combat.gd` differs only by three `if log_events:` wraps (lines 276, 546 and 736) around payload building. `credit_lethal`, `killed_by`, RNG draws and death processing stay outside the guards.
- **`_emit_stats` → `CombatMoves.emit_stats`.** The 1,000-line lint limit forced this move, because the merge left `combat.gd` at 1,005 lines.
- **`test_combat_logging.gd`.** It guards the merge.
- **Review fixes.** The Ask 1 and Ask 2 records and Simplify 1–3 are applied as asked. Recording the Acorn Stash result is evidence, not scope.

## What I ran

- **Gate:** `./scripts/check.sh` at `46bd740` passed every step: 1,309/1,309 Godot tests, 17,902 asserts.
- **Mutation:** I gated `credit_lethal` behind `log_events` in `combat.gd`. `test_last_blow_credit_and_results_are_identical_without_event_logging` failed: winner and damage diverged. The test catches dropped engines behaviour.
- **Full-game parity:** 3 fresh spread games (seeds 174001–174003, editor binary, `trace=on`), first with `BoardSearch` fights quiet and then with them logged. The turn traces (308 turns), fight outcomes (162 fights), players, rounds and cards files were byte-identical.

**Not run:** the release-pack parity, the 100-game soak, the Acorn Stash numbers, and a timing comparison.
