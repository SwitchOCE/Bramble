# Scope review: sharded Actions gate, `origin/ideation/c-gate-shards` 814793b9..e6b9783f

*[Saved verbatim from the scope-reviewer's hand-back, 10 Nov. Calls: DECISIONS (ideation/main) "Gate shards merged: review calls".]*

**Inputs.** I had all three: the target, the owner's words and the plan text. One problem: the plan text in the brief is draft step 3, which the plan marks "superseded by the approved order above". The approved text is step 6: "**Shard the Actions gate** only if the verdict takes more than 7.5 min." DECISIONS logs that condition as met ("Gate plumbing merged": tests step 771 s, push to verdict 15 min). Draft step 3 is still the only detailed spec and the only criteria, so I judged against it.

**Counts:** 16 keep, 0 cut, 1 simplify, 2 ask.

**Does it serve the owner's "smarter scheduling" ask?** Yes, for how tests are scheduled. The cloud verdict drops from 11 to 15 min unsharded to a median of about 3.7 min, all on Actions, with no local lock. It doesn't change *when* or *how often* tests run (the merge rule and `--docs-only` already cover that), and it doesn't make the suite faster (that's step 4).

**Asks:**
- **Ask 1:** the unit test `test_committed_times_cover_the_real_suite` (`tools/checks/tests/test_test_shards.py:81-87`) fails the whole gate once more than 25% of scripts have no recorded time. Its own comment says correctness doesn't need it, so it fails correct trees, the same kind of wasted failure as the count pins step 5 removes. Keep it as a hard failure, or make it a printed warning?
- **Ask 2:** on a shard failure, `scripts/cloud-gate.sh:85` (`--log-failed | tail -n 40`) now prints 40 lines of git cleanup, not the failing test (planted run 42717538753). Unsharded failures still show the GUT totals (runs 42714374887, 42696555037). Fix `cloud-gate.sh` in this step or in a follow-up?

**Simplify:** the Godot cache restore in both gate jobs never hits: 20 of 20 gate jobs logged "Cache not found", and the download takes 2 s. Drop the restore steps (`ci.yml:110-115, 163-168`), or correct the comment and `CLOUD_SETUP.md:108`, which say gate jobs restore from PR runs.

**Gaps:** (1) is Ask 2. (2) Criterion 1 is shown on 2 commits, not the plan's 3; the orchestrator's brief proposed 2. (3) `test_times.json` has no times for 13 of ideation/main's 218 scripts already, and nobody is named to refresh it.

---

## Part 1: what the change does (pr-report)

6 files, +615 / −23. Commits: 7ce6c2c5 (shard map), 677573ba (`check.sh` flags), cbdacc34 (`ci.yml`), e6b9783f (`CLOUD_SETUP.md`).

**Schema / data**
- `tools/checks/test_times.json`: seconds per script for 205 scripts (sum 778 s, median 1.19 s). **Used by:** `test_shards.load_times` → `assign`, in every shard job (`check.sh:59, 326, 328`). **Stated reason:** 7ce6c2c5, "Times come from a full local unsharded run (205 scripts, 2,158 tests)"; draft step 3, "balanced by step 2's junit times".

**Scheduled / background (CI jobs)**
- **`gate-tests` matrix** (`ci.yml:145-207`): runs on push, shards 1 to 4, `fail-fast: false`, each runs `check.sh --shard i/4`. **Used by:** the run's conclusion, which `cloud-gate.sh:75-77` reads. **Stated reason:** draft step 3, "a 4-way shard matrix"; approved step 6.
- **`gate-static`** (`ci.yml:92-143`): runs on push, `check.sh --keep-going --no-tests`. **Used by:** the run's conclusion. **Stated reason:** the orchestrator's brief, "The static steps plus import, compile and parity run once". The plan says "the static steps on shard 1".
- **`check` job skipped on push** (`ci.yml:32`). **Stated reason:** the comment there, "Gate pushes run the sharded jobs below instead."
- **Gate jobs restore the Godot cache but never save it** (`ci.yml:110-115, 163-168`). **Stated reason:** cbdacc34, "Gate jobs never save the Godot cache (gate-plumbing review, simplify 1)". This was proposed by the orchestrator.
- **Artifacts:** `gut-junit-<i>` (14 days), plus `shard-<i>-logs` and `static-logs` on failure (7 days) (`ci.yml:136-143, 190-207`). **Used by:** `test_shards.py times`, run by hand (`CLOUD_SETUP.md:107`). **Stated reason:** approved step 3, "junit times … then from every Actions gate".

**Features:** a push to `ideation/gate/**` now runs 5 parallel jobs instead of 1. PR and manual runs are unchanged.

**External:** nothing new. The action versions are the ones already in the file.

**Config**
- **`check.sh --shard <i>/<n>`** (`check.sh:56-61`): unset by default. Only `ci.yml:187` sets it.
- **`check.sh --no-tests`**, also accepted after `--keep-going` (`check.sh:51-55`): off by default. Only `ci.yml:134` sets it.

**Public interfaces:** the `test_shards.py` commands `list`, `gutconfig`, `show` and `times` (`test_shards.py:96-132`).

**Internal machinery**
- `discover`, `assign` and `parse_shard` (`test_shards.py:29-79`): slowest script first onto the lightest shard; scripts with no time go after the known ones at the median time.
- In shard mode, `check.sh` writes a GUT config listing only that shard's scripts (`check.sh:325-331`). It runs only tools, import and tests (`:375-384`), and the tools step checks only Godot and python3 (`:197-215`).
- The tests step fails a shard if GUT's "Scripts" count isn't the shard's list length (`:355-362`).
- 8 Python unit tests (`test_test_shards.py`).
- `times_from_junit` (`:82-93`). Used by: the `times` command only.
- `show` (`:110-118`). Used by: nothing yet (only `CLOUD_SETUP.md` mentions it).

**Deleted**
- The "GUT totals to the job summary" step (simplify 2 in the gate-plumbing review, proposed by the orchestrator).
- The single `gut-junit` artifact, replaced by `gut-junit-<i>`.

**Unrequested:** `show`; the 25% coverage test; the tools-step trim in shard mode; the script-count check; the cache restore; and running the static steps as their own job instead of on shard 1.

## Part 2: interrogation

| # | Item | Verdict | Evidence | Action |
|---|---|---|---|---|
| 1 | `gate-tests` 4-shard matrix | keep | In plan. 205 scripts and 2,158 tests across the shards in every clean run. | none |
| 2 | `gate-static` as its own job | keep | The orchestrator proposed it; the plan says "static steps on shard 1". It finishes in 76 s while shards take 155-211 s, so it stays off the critical path. Folding it into shard 1 would add about 60 s to the slowest job. | Log the deviation in DECISIONS. |
| 3 | `check` skipped on push | keep | Without it, every gate push would also run the 11-15 min unsharded job. | none |
| 4 | Shard map (`discover`/`assign`/`list`/`gutconfig`) | keep | My probe: at e6, 205 scripts split 46/50/58/51, none repeated, union equals the full set. | none |
| 5 | `test_times.json` | keep | Read by every shard job. | none |
| 6 | `--shard` | keep | Only `ci.yml:187` uses it. | none |
| 7 | `--no-tests` | keep | `gate-static` needs it (`ci.yml:134`). | none |
| 8 | Tools-step trim in shard mode | keep | Shards don't need gdtoolkit or ruff; the trim saves a pip step in each of 4 jobs. | none |
| 9 | Script-count check | keep | It turns "every listed script ran" into a runtime check. GUT skips a script it can't load (GUT `test_collector.gd` `add_script`). It would fail loudly, wrongly, on an inner `class Test… extends GutTest` or a `skip_script`; neither exists at e6 or on ideation/main. | `CLOUD_SETUP.md:106` says "fewer"; the code checks "not equal". Fix the wording. |
| 10 | Per-shard junit artifacts | keep | Approved step 3; feeds `times`. | none |
| 11 | Job-summary step dropped | keep | Proposed by the orchestrator (gate-plumbing review simplify 2). Nothing reads it; the totals are in each shard's log. | none |
| 12 | No cache save on gate jobs | keep | Proposed by the orchestrator (simplify 1), to stay under the 10 GB cache quota. | none |
| 13 | Cache restore on gate jobs | **simplify** | 20 of 20 gate jobs logged "Cache not found"; Download Godot takes 2 s. Caches saved by PR runs belong to the PR's own ref, so a gate push can't restore them. | Drop the restore steps, or fix `ci.yml:108-109, 161-162` and `CLOUD_SETUP.md:108`. |
| 14 | `times` command | keep | The only way to refresh the times file. Nobody is named to run it. | See open question 3. |
| 15 | `show` command | keep | 8 lines of diagnostics; nothing calls it. Deleting it breaks nothing. Low stakes. | none |
| 16 | 7 correctness unit tests | keep | They cover each script in exactly one shard, the union, a new script, no times at all, and parsing. All 8 tests pass (my run). | none |
| 17 | 25% times-coverage test | **ask** | `test_test_shards.py:81-87`. A stale times file only skews shard sizes, but this test turns it into a red gate. At 218 scripts it trips at 55 untimed; 13 appeared in about 12 hours. | Make it a warning, or keep it and name who refreshes. |
| 18 | `CLOUD_SETUP.md` rewrite | keep | Mostly accurate. Two wording errors (items 9 and 13), and `:111` still promises a useful "last 40 lines". | Fix with items 9, 13 and 19. |
| 19 | Failure report through `cloud-gate.sh` with the new job layout | **ask** | For the planted run, `gh run view 42717538753 --log-failed \| tail -n 40` is upload and git-cleanup lines, every line tagged "UNKNOWN STEP". The failing test name is earlier in that output, at line 216: `- test_planted_failure_shard_3`. Unsharded failed runs give the GUT totals in that tail. The verdict itself is right. | In `cloud-gate.sh`, print the check.sh lines (for example grep `FAIL \|failed:\|Failing Tests\|^- test_`) instead of `tail -n 40`. This could be a follow-up. |

**Cut:** none.

**Simplify:** item 13. Optional: the Godot download block now appears 4 times in `ci.yml`. Making `gate-static` a sixth matrix entry would remove about 45 lines, at 3 s of pip per shard.

**Gaps**
1. Item 19.
2. Criterion 1 ("On 3 commits … same verdict and the same test count") has evidence on 2 commits: e6b9783f (three runs) and the planted 2c0a94e2. The orchestrator's brief proposed 2. The unsharded reference is run 42702428298 on 405bd57b, 2,158 tests; its `tests/`, `addons/` and `.gutconfig.json` are identical to e6's. The local unsharded run is only claimed in a commit message. The merge commit's own required gate could serve as the third commit, but only with an unsharded count to compare against.
3. `test_times.json` already lacks 13 of ideation/main's scripts (7 Quilboar, 6 Ooze). Each still lands in exactly one shard at 1.19 s (my probe on ideation/main's tree). The faster suite (C11) will shift the times too.
4. Not a problem yet: each gate now takes 5 runners against GitHub Free's 20-concurrent-job cap, which the planned Actions sim job (C3) will share. Two gates ran at once without queueing.

**Original problem:** this step moves it. The owner wanted tests on the cloud with smart scheduling, and a cloud verdict now takes about 3.7 min instead of 11-15, so every hand-off gate is cheap. The local lock was already off gates (step 2), and suite speed is step 4.

**Open questions (the orchestrator's call):**
1. Ask 1: hard failure or warning.
2. Ask 2: fix `cloud-gate.sh` now or in a follow-up.
3. Who refreshes `test_times.json`, and when (after the faster suite merges?).
4. Whether 2 commits plus reruns meets criterion 1.

## The seven probes

1. **Same verdict and count: yes.**
   - Every clean run summed to 205 scripts (46+50+58+51) and 2,158 tests (493+542+600+523), the same as the unsharded 2,158.
   - A new script with no time goes after the known ones, on the lightest shard, at the median weight (`test_shards.py:53-61`), and doesn't move the others. Scripts deleted from the tree but still in the times file are ignored.
   - The runtime count check (item 9) backs this up.
2. **Planted failure: yes for the verdict.**
   - Shard 3 failed (601 tests, 1 failing); shards 1, 2 and 4 passed; the run's conclusion was failure.
   - `cloud-gate.sh:75-77` maps the conclusion to FAIL, and `--check` only accepts runs with `--status success` (`:30`).
   - The session pushed the planted branch by hand, not through `cloud-gate.sh`, and the printed failure tail is broken (item 19).
3. **Static steps: each runs exactly once, in `gate-static`.** Its log shows tools, versions, shell, python (`ruff check`, `ruff format --check`, 88 unittests OK), content, format, lint (`gdlint src tools/checks tools/play tools/sim`, then `cd tests && gdlint .`), import, compile (583 files) and parity. Shards run only tools, import and tests. Import runs once per job, which each fresh runner needs.
4. **Time: well under the bar.**
   - The 4 sharded runs at the change's end took 221, 221, 234 and 214 s from run creation to finish; the median is 221 s against the 6-min bar.
   - A fifth run can't lift the median of five above 234 s.
   - Unsharded runs took 14:42 (405bd57b) and 10:45 (e92ab110).
   - The shard tests step varies 127-211 s on identical code. The slowest single script is 96 s.
5. **Local default: unchanged.** With no flag, `check.sh` runs the same steps, and the tests step passes no `-gconfig`. Only `ci.yml` uses `--shard` and `--no-tests`.
6. **Scope: clean.** No exports on push (the `exports` job was skipped in every run), no other workflows, the trigger is still `ideation/gate/**` only, and nothing touches `main`. The branches `ideation/gate/planted-shards-1`, `-r2` and `-r3` are still on the remote; they're harmless.
7. **Owner misattribution: none.** Grepping the diff and commit messages for owner, approved and asked found only "exports when asked".

## What I ran and didn't

**Ran**
- Read the change with `git show`, `diff` and `grep`.
- Exported the e6b9783f and ideation/main trees with `git archive` into `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/` and ran the shard map on both.
- Ran the 8 shard unit tests (OK), CLI probes (bad specs exit 2; `gutconfig` keeps `post_run_script`), and ruff, ruff format and shellcheck on the changed files (all clean).
- Read run metadata, step timings and logs for runs 42717538523, 42717538753, 42718204571 and 42718204405, plus unsharded 42702428298, 42714374887, 42714479359 and 42696555037 for comparison. Listed the file names in two run-log zips.

**Didn't**
- Run Godot or GUT.
- Run `cloud-gate.sh` (it pushes).
- See the cloud session's local unsharded run.
- Read anything about how this branch fared after its gate runs.
- Look at the faster-suite commit 4c572c86 beyond which test files it adds and deletes (it adds no `test_` scripts).
- Pin down why gh labels every line in these runs' logs "UNKNOWN STEP"; item 19 rests on the observed output alone.
