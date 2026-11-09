# Follow-up scope review: the harness (f7a30eb..9af89c2)

Fresh scope-reviewer, 9 Nov 2026. Saved by the orchestrator from the reviewer's hand-back.

## Summary

**Counts:** 29 items: 19 keep, 2 cut, 3 simplify, 5 ask.

**Original problem:** partly moved. Line strength is now tested fairly, and the test can fail. Hedgerow tempo beats blind Hard by +0.89 places (95% CI +0.65 to +1.13). No scale lever has been read yet, so the owner's "far too low" is untouched.

**Previous review:** cuts 1, 2 and 4 are fixed. Cut 5 is fixed, but two new owner credits appeared. Cut 3 is only partly fixed.

**Cut**
1. `HARNESS.md:353` titles an orchestrator call "Owner ruling", and `:359` says "the owner merged shared mechanics". The orchestrator did both.
2. The real null still can't fail: null and reference are the same inert 1/1 under two ids, and the dominance check never runs on the null arm.

**Ask**
1. The lever-build gate opens on hedgerow tempo alone. The engine-line mixture never blocks it, though the 9 Nov call names the lever build "the real test of" engine lines. Decide before those comparisons finish, about 1.5 h after 20:53.
2. The gate runs from uncommitted `/tmp` scripts that write its inputs and commit on their own.
3. Nothing reads the forced dose ladder.
4. Designed setups (owner, 9d) have a reader but no boards.
5. The curvature check has no interval. The baseline sits at 1.19 against a 1.25 limit, and all eight 8-lobby runs read "not flat".

**Merge:** merges cleanly; 1,697 GUT and 94 Python tests pass. For players, only the BotBurner fix changes anything, and it does nothing with caps on. Safe once the cuts are fixed. Fix HARNESS.md now. Make the null fix outside the sweep's worktree, because editing `tools/sim/*.py` there stops the sweep.

---

## Full review (to save)

### Brief and range
- I had all three inputs: the owner's words, the approved plan and DECISIONS entries, and the orchestrator's requests (treated as proposals).
- **The harness's own work is `eb571ba..9af89c2`:** 70 files, +132,392 / −12,716 lines. 119,597 of the added lines are one JSON file.
- **`f7a30eb..eb571ba` is the merge of ideation/main** (the mechanics work, reviewed separately). A diff check shows the merge adds nothing to `src/` or `content/` beyond what its two parents already had.
- **Against the merge base `efa31f2`:** 120 files, about 6.0 MB.
- **ideation/main since `efa31f2`** has changed only `docs/`, with no file overlap with the harness. So the code of the merged tree is the code at `9af89c2`.

### What I ran and what I didn't
All of this ran on a temporary copy of `9af89c2` in `/var/tmp`, now deleted.
- **Python suite:** all 94 harness tests pass.
- **Full GUT suite:** import, then a run under `flock /tmp/bramble-godot.lock … MemoryMax=3G timeout 900`. Result: 1,697/1,697 tests, 29,037 asserts, strict hook ok, no errors in the log.
- **Break probes (Python):** I broke one check at a time and reran its tests. Results are under Probes below.
- **Break probes (Godot):** same method, for the exact re-fight.
- **Artifact probe:** a re-sealed shard result with its `captures` entry removed is rejected ("incomplete or unexpected result artifacts").
- **Curvature numbers:** I applied the new curvature check to the baseline's committed medians and to the eight committed dose runs.
- **Not run:** `scripts/check.sh` format, lint, parity and export steps; any lobby, field or sweep shard. I didn't read `build/` or any commit after `9af89c2`.
- **The `/tmp` drivers:** I read them only after checking that their hashes match the ones sealed in the committed ledger.
- **Lock incident:** my first Godot probe used a wrong test filter. It ran the full suite twice and held the shared lock for about 8 minutes, so a wave 1 GUT run waited behind it. I stopped it and reran with a narrow filter.

### Probes
| Check | Broken how | Result |
|---|---|---|
| (a) exact re-fight | replay without the session overlay | caps-off re-fight test fails |
| (a) | `matches` always true | "event verification is enforced" fails |
| (b) head-to-head | pass always | `test_line_tools` and `test_strength_gate` fail |
| (b) lever gate | always pass | fails |
| (b) lever gate | "both builds" changed to "either build" | **no test fails** |
| (c) null | always pass | 24 failures |
| (c) broken engine | win-rate, round-6 tail or field-rate bar deleted (any one) | **no test fails** |
| (d) curvature | always flat | fails |
| (d) | either half of the rule dropped alone | **no test fails** (the 15% control fails both halves) |
| shards | duplicate result, missing result, missing or duplicate field pair, changed shard | each fails a test |

### Previous review's items
| Item | Now |
|---|---|
| Cut 1–2: a fair (b) against `hard_field` | Fixed. Fresh 80-seed blind comparisons; the pass needs a positive lower bound (`check_lines.py:72`). `hard_floor_passes` is null. |
| Cut 3: real null | Partly fixed (cut 2 above) |
| Cut 4: stratified field, board-cluster intervals, placement ranking | Fixed (`field.py:299`, `:392`; `metrics.py:190`) |
| Cut 5: owner credit | That one is removed, but two new ones were added in `0aa053b` (cut 1 above) |
| Reader for post-Start-of-Combat stats | Done |
| Knob tuning dropped | Done. The `line_tune` suite is left over (simplify) |
| Lever-build gate | Built (ask 1) |
| Dose ladder and pool-planted engine | Run. The pool half is read; the forced half isn't (ask 3) |
| Upsets split by cause | Done |
| Designed-board input | Added, but no boards yet (ask 4) |
| Curvature test replaces R² | Done, with no interval (ask 5) |
| One metrics format | Done. CSV exports deleted |

### Items
| # | Item | Verdict | Evidence | Action |
|---|---|---|---|---|
| 1 | Fresh blind (b) runs (best-hedgerow and frozen-mixture results) | keep | Previous cuts 1–2; `check_lines.py:72`; the probe fails when broken | — |
| 2 | Field rank is descriptive only (`HARNESS.md:8-24`) | keep | Previous cut 1 | — |
| 3 | Equal field quotas, board-cluster bootstrap, placement ranking | keep | Previous cut 4 | — |
| 4 | Post-start stats reader | keep | Orchestrator's call on an ask | — |
| 5 | Curvature check (`metrics.py:155-187`) | **ask** | Baseline medians give a 1.19 ratio against a 1.25 limit. 3% compounding a round passes; 5% fails. All 8 committed 8-lobby runs read `flat: false` (ratios 1.30–2.40), including nearly unplanted ones. Late medians count survivors only. | Add a seed-bootstrap interval (`clustered_rate` exists) and report the baseline's value before the sweep reads "compounds" |
| 6 | JSON as the one metrics format | keep | Previous simplify | — |
| 7 | Tuner and v1/tuned tables archived in `evidence/` | keep | Knob tuning dropped | — |
| 8 | `line_tune` suite (`bench_suites.gd:91,105,176`) | simplify | Its only user is the retired tuner | Delete it |
| 9 | Real null (`planted_engine.gd:12,48`; `check_plants.py:66-114`) | **cut** | Null and reference are identical inert 1/1s apart from the id. `check()` (`:117`) runs the tail, win and field bars only on the broken arm. The check can fail only if some code reads the id. | Run `check()`'s three bars on the null arm and require them to fail. Optionally give the null the engine's End-of-Turn mechanic at +0/+0. |
| 10 | Forced dose ladder (+1 to +64) | **ask** | Nothing reads its dose response. In the committed metrics, the planted seat's round-6 median is 56 / 94.5 / 228.5 / 803.5 against a pool median of 46 / 48 / 48.5 / 45, so it shows clearly from +4. | Who reads it, and when (the engine-dial step)? |
| 11 | Pool dose ladder and acquisition/retention reader (`lever_sweep.py:353`) | keep | Read by `shop-pool-dose-summary.json` | — |
| 12 | `review-run-progress.json` | simplify | 3.5 MB of pretty-printed JSON (311 KB gzipped), rewritten in 5 commits; only the summary is cited | Gzip it, or keep the summary plus hashes |
| 13 | Upset reader (`upset_combat.gd`, `upset_probe.gd`, `upset_report.py`) | keep | Plan step 2 bar; the orchestrator's call; 12 Godot controls pass | — |
| 14 | Designed-only field input (`field.py:142-250`) | **ask** | No setups exist and no frozen plan uses one. Owner (9d): "setups of things you think might be strong" | Who builds them, and in which step? |
| 15 | `sweep_shards.py` (plan, run, merge-lobbies, merge) | keep | Orchestrator's request; cloud VMs owner-agreed 8 Nov; rejection probes pass | — |
| 16 | `lever_sweep.py` local runner (`prepare`, `execute`, `check_gate`, `run`, `:636-970`; second `godot_command` at `:567`) | simplify | No committed result came from it. The caps screen ran locally through `sweep_shards`. Its default `line_profiles.sweep.json` doesn't exist. | Keep the analysis and report helpers; delete the runner and its CLI |
| 17 | `strength_gate.py` and the lever-build plan | **ask** | The pass is `results["best"]["passes"]` only (`strength_gate.py:118`). In today's mixture, birds_engine took first 0/36 times and bog_engine 0/33. The driver also pre-writes "wins and placement describe different aspects of variance" before any result exists. | Decide whether the mixture gates engine and tribe reads. Do it before the results land. |
| 18 | `/tmp/bramble-{caps-checkpoint,lever-head-checkpoint,caps-gates-supervisor}.py` | **ask** | No committed code writes the gate's `.run.json` inputs. The scripts live on tmpfs, and the repo holds only their hashes (`scale-run-execution.json`). | Commit them under `tools/sim/evidence/`, which the fingerprint doesn't cover (`tools/sim/*.py` doesn't match subfolders), or run the comparisons as shard `head` jobs |
| 19 | Caps-off screening (plan, manifest, runs) | keep | Plan step 2, first lever; orchestrator's order | — |
| 20 | BotBurner fix, its test, the cap-reader audit | keep | Matches `recruit_context.gd:289`. Content always sets `most` above 0 with caps on, so capped play is unchanged. | — |
| 21 | Godot logs with script errors rejected even on exit 0 | keep | Part of the crash fix `ad96d30` | — |
| 22 | Overlay restored in re-fights and field fights | keep | Needed for (a) under levers; the probe fails without it | — |
| 23 | `bench.gd` options `config`, `plant_mode`, `plant_pool` | keep | Used by the caps screen and the null and dose runs | — |
| 24 | `TRIBAL_MIXTURE` in BenchSuites | keep | Frozen mixture comparison | — |
| 25 | Harness-only lock `/tmp/bramble-harness-godot.lock` | keep | One Godot per lock keeps the machine at two or fewer | Log it in DECISIONS |
| 26 | Records of excluded attempts | keep | Small; they show what was thrown out and why | — |
| 27 | `lever-sweep.md` and the rest of HARNESS.md | keep | Accurate apart from #28 | — |
| 28 | Owner credits (`HARNESS.md:353,359`) | **cut** | The owner made neither call | Change both to "orchestrator" |
| 29 | Sealed manifests and source fingerprints (`sweep_shards.py:217`) | keep | They make the running sweep stop safely if its source changes | — |

### Gaps
- No test makes `check()` fail on a weak engine, makes the lever gate fail when only one build passes, or covers either half of the curvature rule alone.
- The caps screen has no caps-on arm at the same source. It will be compared, unpaired, with the 500-lobby baseline built at an older commit. The mechanics step's seed traces showed default play unchanged, so the risk is small.
- `planted-result.json` still says `passes: true` from the invalid empty null. Only HARNESS.md marks it as historical.
- 96 of the 640 "hedgerow tempo" seats were `line_fast` fallbacks, because Hedgerow folk weren't in those lobbies. This is reported and doesn't change the pass.

### Merge
- The running sweep lives in `/home/alex/code/Bramble-ideation-sol`. Before every shard it re-hashes `src`, `content`, `tools/sim/*.gd`, `tools/sim/*.py`, `project.godot` and `versions.env`, and it stops on any change.
- Merging into ideation/main from another worktree doesn't touch it.
- Its later evidence commits will need a second merge.
- Branch size is reasonable: the tree grows from 137 to 141 MB (+3%). The only binaries are 4 gz files of about 450 KB; captures stay in `build/`.
