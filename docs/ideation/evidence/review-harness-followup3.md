# Harness follow-up review 3: 06c918b..cfdc37c (scope reviewer, 10 Nov 2026)

## Harness follow-up 3: `06c918b..cfdc37c`, plus the HARNESS.md rewording in `c297785`

**Counts:** 11 items: 8 keep, 0 cut, 0 simplify, 3 ask.

**Merge:** clear to merge, but it can't be a fast-forward. ideation/main has moved to `234f78d` ("C preset", 3 docs files), and `cfdc37c` doesn't contain it. There's no file overlap, so merge `234f78d` into the harness and then fast-forward, or do a normal merge. Nothing else blocks it. None of the asks blocks the merge, but ask A must land before step 5.

### Your four questions
1. **Is the cut fixed? Yes.**
   - The audit allows each Bird and Fairy ability by name (32 in all). An unknown or missing ability still marks the fight unsupported.
   - I read the pass 3 combat code and agree with the audit: none of the 32 picks the largest enemy.
     - Tom Tit, Hob, Fetch and Dunnock pick the biggest friendly unit.
     - Jack Daw, Witch, Belladonna, Changeling and Mag Pye pick by position.
     - Whistlers hits the enemy across, or all enemies.
   - The worker's merged-tree gate log shows 1,846/1,846 tests, and its hash matches the verification record.
   - I didn't rerun GUT. My narrow run sat behind two other sessions' full gates on the shared lock, so I cancelled it.
   - **Wave 2 will break this the same way.** The audit covers the whole library, so any unaudited ability makes every fight unsupported and fails the 32-ability test. Put the audit update in the wave 2 briefs.
2. **Do the gzips and the fold keep behaviour? Yes.**
   - I checked all three gzips: each restores the original bytes exactly, and the frozen designed-input hash still matches.
   - In the old aggregate mode, the fold keeps the seed formula and the row keys in the same order.
   - In the new per-seed mode, it keeps the old designed driver's seeds and rows. Tests cover this, and the worker's byte comparison on the merged code matches.
   - The 35 rows that changed since the first designed run come from wave 1's combat code, not the fold (ask B).
3. **Does the rewording match the plan? Yes.**
   - HARNESS.md gives the plan's two criteria: logged progress moments, and median growth of ×1.3 or more a round from R8 to R14 on pre-start boards. Everything else is marked as reported only.
   - The known-answer tests (a)–(d), the planted-engine and null checks, and the upset controls are all still there, relabelled as checks that the measurement itself is correct. Nothing was dropped.
   - "Withdrawn" for losses with no agency matches the plan.
4. **Fast-forward:** blocked only by `234f78d` (see Merge).

### Table
| # | Item | Verdict | Evidence / note |
|---|---|---|---|
| 1 | Wave 1 upset audit: list per ability, whole library still checked (`upset_combat.gd:129-168, 367-373`; `wave1-upset-audit.json`) | keep | Matches the call; fails closed |
| 2 | `field_fights.gd` per-seed mode; `designed_fights.gd` removed; `test_field_fight_output.gd` | keep | Seed formulas and row keys preserved |
| 3 | Gzip pointer files, `evidence_io.py` and its callers | keep | Exact bytes restored; 124 Python tests pass at `cfdc37c` |
| 4 | `rebuild_followup_evidence.py` and its README | keep | The one-off commands are now committed, as called |
| 5 | Edits to `run_designed_first.py` | keep | It was changed after its run. The bytes that ran are at `1206ae0`; the README should say so. |
| 6 | Verification record and merged-tree gate log | keep | Log hash matches |
| 7 | `c297785`: "What decides checkpoint 1", and the tests relabelled as correctness checks | keep | Matches the plan |
| 8 | HARNESS.md section for follow-up 2 | keep | — |
| A | Deciding number not computed | **ask** | `metrics.py` reads post-start stats for its main series, growth ratio and curvature (`:65-88`); pre-start appears only as a per-round distribution. "×1.3 a round" isn't pinned: every round, or the average over R8–R14? Add a pre-start R8→R14 reader with a seed interval before step 5. |
| B | Combat code changed under the old evidence | **ask** | On the merged tree, pass 3 combat timing switches on whenever the slice pool holds Bird or Fairy cards, whatever `pass3_content` says (`pass3_combat.gd:6-30`). That is why 35 of 384 designed rows changed. So the baseline, caps screen, lever builds, first designed field and null were all measured on pre-wave-1 combat. Label them so, and don't compare them with step 5 numbers or expect exact re-fights; HARNESS.md says this only for the designed archive. Also check with wave 1 that changing fights without Birds or Fairies was intended: v3 says players see nothing new until `pass3_content` is on. |
| C | Wave 1 line files (call 3) | **ask** | Not in this range, and HARNESS.md says it hasn't started. Confirm "first commit after the merge" means after the harness lands on ideation/main. |
