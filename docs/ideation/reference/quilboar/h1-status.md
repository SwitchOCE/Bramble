# H1 simulation complete; offline report building

All 500 predeclared lobbies are complete: B 150, C 150, uncut 100, frozen uncut
100. Godot scope time totalled 1,726.58 seconds (28.8 minutes). Every simulation
used the harness lock only, a timeout and a 3 GB systemd scope. Reviewed revisions
`cc6d26d5..4d23628e` are unchanged; all follow-ups are new commits.

The accounting point estimates fail at R9 and R12 in both budgeted arms:

| Arm | R9 real / paper | R12 real / paper | R15 real / paper |
|---|---:|---:|---:|
| B | 77 / 167 = 0.461 | 274.5 / 1,144 = 0.240 | 1,927.5 / 3,363 = 0.573 |
| C | 78 / 203 = 0.384 | 422 / 1,942 = 0.217 | 3,383 / 6,123 = 0.553 |

Fidelity also fails: uncut's R12 Quilboar median is 825.5 (80 surviving seats),
against Birds' 271 (99 surviving seats): **3.046x [2.186, 3.965]**, below 4x.
Its ratios against Fairies/Bog/Hedgerow/Hunters/Oozes are respectively
6.350/6.822/6.766/7.679/8.644. Intervals are whole-seed bootstrap intervals;
eliminated clusters remain in resampling, with no zero board imputation.

The reference is not yet qualified as a measuring stick. A policy/model detail
is awaiting the orchestrator's call: this frozen implementation counts Created
and bought cycled units toward four, whereas the paper's four shop cycles are
separate from Created Tunneler cards. The built full-game T6 upgrade costs 13;
the authored paper uses 11. Declared paper denominators were retained rather
than changed after seeing outcomes. Roadboar is absent until Phase 2. These
are accounting qualifications, not balance findings about the native tribes.
The source tree has wave-1 Birds/Fairies and four legacy engine profiles; C
changes reference dials, with native rates fixed to the committed tree.

All arms, captures, players, receipts, accounting intervals and completed
progress are committed under `tools/sim/evidence/quilboar-h1/`. Targeted checks:
64 Godot tests, 15 Python driver/report tests. No new full gate was run, as the
orchestrator requested targeted checks only for these follow-ups.

The detached offline-only watcher is building the full per-round metrics at
`docs/ideation/reference/quilboar/h1.md` and `h1.json`. Its log/exit file are
`build/quilboar-h1/report.log` and `report.exit`. The simulation is finished;
only report completion and its final evidence commit remain at this handoff.
