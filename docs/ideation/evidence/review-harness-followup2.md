# Harness follow-up review 2: 9af89c2..ab4adeb (scope reviewer, 9 Nov 2026)

## Summary

**Counts:** 30 items: 23 keep, 1 cut, 2 simplify, 4 ask.

**Calls landed:** all eight.
- The owner credits are fixed.
- The null now fails all three dominance bars (0/8 tails, 1/8 wins, 45% field points).
- The drivers are committed byte for byte.
- The local runner and `line_tune` are gone, and the progress JSON is gzipped.
- Curvature has a seed interval.
- Each new negative test fails when I break its check.
- Nothing in the range changes the game.

**Bars before runs:** no. The first designed field froze its inputs, seeds and fight counts, but no bars, so its results are descriptive. v3's bar was written after the run started.

**Cut**
1. **Merge blocker:** 3 `test_upset_combat` tests fail on the merged tree. UpsetCombat checks the whole library, and wave 1's `pass3_bird` and `pass3_fairy` aren't on its audited list (34 unsupported, against 2 expected).

**Ask**
1. v3's concentration bar is undefined on these boards. At R12, a carry with Shield, Damage Reduction or Cleave beats a plain even board 100% of the time without an answer, and 0% against one biggest-enemy answer. Pin the answer and the number of keyword copies.
2. In the current phase, the curvature check calls today's pool not flat (1.44, CI 1.37–1.56, against a 1.25 limit), yet HARNESS.md keeps the (d) pass. v3's growth bars don't name a phase.
3. Nothing loads wave 1's `tools/sim/lines/*.json`, though the wave 1 call put that in this merge.
4. The generator builds only Mouse-token boards. v3 needs real-card wave 1 boards and Granny and Whistlers setups.

**Merge:** not clear yet. The text merges cleanly and the Python tests pass. Fix the cut, then run the full gate on the merged tree.

---

## Full review: `9af89c2..ab4adeb` (70 files, +104,340 / −119,747; no changes to `src/` or `content/`)

**What I ran:**
- **Python, on a trial merge** of `ab4adeb` into ideation/main `f574eaf`, in a temp clone (since deleted):
  - the 117 tests in `tests/sim` and the 57 in `tools/checks/tests`: all pass;
  - 8 break probes (each engine bar, "null fails only one bar", the gate opening on either build, each half of the curvature rule, the clamp guard): each one fails its tests.
- **GUT, on the same merged tree,** under the shared lock with a 3G cap and narrow filters:
  - 18 scripts: the harness tests, the bot and session tests, and the pass 3 tests;
  - 282 tests, 3 failing, all in `test_upset_combat` (lines 62, 123, 146).
- **Not run:**
  - the other 146 GUT scripts on the merged tree;
  - `scripts/check.sh`;
  - any lobby, field or designed run.
- I relied on the worker's full gate at `adc6bf6`: 1,697 tests. `ab4adeb` adds only evidence on top of it.
- **Merge mechanics:**
  - both sides changed `bot_brain.gd` and `game_session.gd`, and both auto-merge;
  - no file overlaps with `ideation/strong-field` since `9af89c2`.

| # | Item | Verdict | Evidence | Action |
|---|---|---|---|---|
| 1 | HARNESS.md credits now say "orchestrator" (`:353`, `:359`) | keep | Previous cut 1 | — |
| 2 | `dominance()` on both arms, the null field, `real-null-dominance-result.json` | keep | Previous cut 2. The null fails 3/3 bars; the engine passes 3/3. Each bar mutation fails tests. | — |
| 3 | `planted-result.json` and `real-null-result.json` marked historical | keep | Previous gap | — |
| 4 | `/tmp` drivers archived in `evidence/drivers/` | keep | Call 2. Hashes match the ledger. | — |
| 5 | `run_designed_first.py`, committed before its run, no auto-commit | keep | Commit `1206ae0` at 22:43; refreeze `fbeb2a8` at 22:44 | — |
| 6 | Progress JSON gzipped (3.5 MB → 314 KB) plus summaries | keep | Simplify taken | — |
| 7 | Forced-dose calibration in `review-run-summary.json` | keep | Call 3. v3 drops the engine-dial step, so it is now a record only. | — |
| 8 | `line_tune` removed | keep | Simplify taken | — |
| 9 | Local runner removed; `SweepReport`; corrected default profile | keep | Simplify taken; `sweep_shards` is the only runner | — |
| 10 | `curvature_with_intervals` and `baseline-curvature.json` | keep | Call 5. Both halves are now tested. | See ask 2 |
| 11 | New negative tests | keep | My probes confirm them | — |
| 12 | Shell-quoting test in `test_sweep_shards` | keep | 3 lines, test only | — |
| 13 | Caps screen complete; `lever-sweep.md` | keep | Plan v2 step 2; the evidence behind v3 | — |
| 14 | Four lever-build comparisons and the gate (passes on g25 and g50) | keep | Read as the pre-result call said | — |
| 15 | `lever-read-qualifications.json` | keep | Record of call 1. No code reads it, and v3 cancelled the reads it qualifies. | — |
| 16 | `designed_setups.py` generator | keep | Call 4; v3 "from the harness generator"; clamp guard tested | See ask 4 |
| 17 | `designed_report.py`, Hoeffding intervals, `designed-*.md` | keep | Needed to read the field | — |
| 18 | First designed field (192,000 fights) | keep | Descriptive only: `designed-first-plan.json` has no bars. The v3 review noted this too. | Read nothing from it as pass or fail |
| 19 | Boundary and analogue fields for the owner's 500M/2.1B example | keep | Call 4 names it. The 1B clamp is recorded, not changed. | — |
| 20 | `designed-config.json` | keep | Shared config for the designed boards | — |
| 21 | Verification, mutation and gate-log evidence | keep | — | — |
| 22 | `scale-run-execution.json` updates | keep | — | — |
| 23 | No change to the game in the range | keep | No changes under `src/` or `content/` | — |
| 24 | Large evidence stored as pretty-printed JSON | simplify | `caps-screen-results.json` 1.57 MB, `designed-screen-input.json` 652 KB, `designed-screen-result.json` 613 KB | Gzip them, as was done for the progress file |
| 25 | `designed_fights.gd` | simplify | A near copy of the `field_fights.gd` loop, with output per seed | Add a per-seed mode to `field_fights.gd` |
| 26 | UpsetCombat audits the whole library (`upset_combat.gd:195-216`) | **cut (blocks merge)** | 3 merged-tree failures; `pass3_bird` and `pass3_fairy` (40 entries) aren't in `AUDITED_NATIVE` | Audit whether they target the biggest enemy, then add them, or check only the fight's own cards. Rerun the full gate on the merged tree. |
| 27 | v3 concentration bar | **ask** | Carry plus a keyword against a plain even board: 100% with no answer, 0% against a 50% biggest answer. v3 says "today 0–15%". | Fix the even board's answer, the answer percent and the keyword copies before the pass 3 run |
| 28 | (d) and phase | **ask** | Post-start ratio 1.44 [1.37, 1.56]; pre-start 1.19 [1.13, 1.26] | Rule on (d), and name the phase for v3's growth and size bars |
| 29 | Wave 1 line files | **ask** | No code reads `tools/sim/lines`, and their schema differs from `line_profiles.committed.json` | Load them at merge, or log the deferral |
| 30 | Real-card designed boards | **ask** | The generator writes Mouse tokens only. `field.py` accepts real cards. | Who writes v3's step 4 and step 5 boards? |

**Gaps**
- `strength_gate.py` hard-codes g25/g50 and the two candidates. v3 step 5's gate on the new lines will need a general plan format.
- `real-null-dominance-result.json`, `baseline-curvature.json` and `lever-read-qualifications.json` came from one-off commands that weren't committed. Their inputs are hashed, but the commands aren't recorded.
