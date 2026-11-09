# Scope review: gate plumbing (`49366332..origin/ideation/c-gate-plumbing`)

**Target:** commits e5d3d41e, 2184f1ff and debef85c: 8 files, +342 −14.

**Inputs:** I had the owner's words (`2026-11-10a`), the approved plan text (step 2 of "Approved order") and the session's report. I did not have the orchestrator's brief to the session. Anything not in the approved step text is therefore marked "none stated", or traced to the superseded draft steps.

## Summary

- **Counts:** 19 keep, 0 cut, 3 simplify, 3 ask.
- **Does it move the original problem?** Yes, partly.
  - It builds the way to take full gates off the local Godot lock. Actions gave the right verdict in 4–5.5 min with no local lock. A local gate takes 10–15 min plus the queue (DECISIONS, 10 Nov).
  - But it saves no lock time until the orchestrator actually gates through `cloud-gate.sh`, and that script's push-and-watch half has never run.
  - One transition hazard (ask 1) can make local locking worse.
  - The suite itself is no faster; that is steps 3 and 4.
- **Ask items:**
  1. **Retire the old stopgap and the outer-`flock` gate recipes before merging.** Under them, the new `check.sh` takes a second slot. Two gates at once deadlock until killed, and so does the recorded "our gate also holds the harness lock" recipe (probes D, E and F below).
  2. **`--docs-only --base` accepts any commit.** `--base HEAD` lets a committed `src/` change skip the Godot steps (probe). Either tie it to a commit that `cloud-gate.sh --check` passes, or write the two-command order into the merge rule.
  3. **`scripts/godot_slot.sh <command>` applies no 3 GB cap.** Its own example for workers' GUT runs drops the `MemoryMax=3G` that the stopgap's example carried. After step 1, those runs are the main local Godot use.
- **Cut items:** none.
- **Gaps before relying on it:**
  - Run `cloud-gate.sh <sha>` once for real, for example on the merge commit.
  - A flaky Actions failure can't be retried through it. Document `gh run rerun <id>`.
  - Merging into ideation/main conflicts in `step_tests` (ideation/main added `GUT_TIMEOUT` and a private `XDG_DATA_HOME`). Keep both sides.

---

## Part 1: what the change does (pr-report)

**Sources of intent:**
- The owner's words (scope).
- Approved step 2 (scope).
- The superseded draft steps 2 and 3. These are a proposal, not approved scope.
- The commit messages. These describe the change; they don't justify it.

### 1. Schema / data

- **`godot-slots.csv`**
  - **What:** one line per slot hold: `start_utc,class,slot,wait_s,hold_s,exit,command`. Stored at `${XDG_STATE_HOME:-~/.local/state}/bramble/godot-slots.csv` (`scripts/godot_slot.sh:15`, `:43-55`).
  - **Used by:** nothing in code.
  - **Stated reason:** "with a wait/hold/exit log" (approved step 2). Checkpoints: "the slot log's median wait, waits over 5 min, and flock timeouts: a baseline now, again after step 2, and a day later" (plan).
- **`cloud-gates.csv`**
  - **What:** one line per gate: `start_utc,label,sha,verdict,push_to_verdict_s,url` (`scripts/cloud-gate.sh:16`, `:78-80`).
  - **Used by:** nothing in code.
  - **Stated reason:** "Push-to-verdict time is reported" (step 2); "Shard the Actions gate only if the verdict takes more than 7.5 min" (step 6).
- **`build/check/gut.xml`, uploaded as the `gut-junit` artifact**
  - **What:** GUT's JUnit output (`scripts/check.sh:284`, `:291-293`). Push runs upload it and keep it 14 days (`.github/workflows/ci.yml:95-103`).
  - **Used by:** `tools/checks/junit_slowest.py`, called at `check.sh:297`. Nothing reads the artifact yet.
  - **Stated reason:** "GUT writes junit" (step 2); "then from every Actions gate" (step 3); "ranked by junit times" (step 4).
- **`ideation/gate/<12-char sha>` branches on origin**
  - **What:** one branch per gated commit on the public remote (`cloud-gate.sh:55`, `:61`). Nothing deletes them. The three cited runs left three, including `ideation/gate/planted-1`, whose commit says "never merge".
  - **Used by:** the push trigger. `--check` also filters runs by this branch prefix (`cloud-gate.sh:29-32`).
  - **Stated reason:** "runs on push to `ideation/gate/**`" (step 2). For deleting them: none stated.

### 2. Scheduled / background

- **Actions push trigger**
  - **What:** `push: branches: ["ideation/gate/**"]` (`ci.yml:9-10`). Push runs have no `paths-ignore`. Only the `check` job runs on a push: the `exports` job's `if` (`ci.yml:115-117`) is false, and all three runs show it skipped.
  - **Used by:** `cloud-gate.sh`.
  - **Stated reason:** step 2.
- **Slot wait loop**
  - **What:** `godot_slot_acquire` tries both locks, then sleeps 5 s, with no limit (`godot_slot.sh:19-40`).
  - **Used by:** `check.sh:153` and the wrapper at `godot_slot.sh:74`.
  - **Stated reason:** "The slot wrapper moves into the repo" (step 2). The stopgap used the same loop.
- **`cloud-gate.sh` polling**
  - **What:** checks up to 30 times, 4 s apart, for the run to appear (`:65-71`). Then `gh run watch --interval 15` (`:73`).
  - **Used by:** the orchestrator.
  - **Stated reason:** "pushes, watches with `gh`, and prints the verdict" (step 2).

### 3. Features

- **`check.sh --docs-only --base <sha>`**
  - **What:** resolves the argument to a commit and passes it to `docs_only_paths.py` as the base (`check.sh:43-50`, `:79-83`). The old upstream mode stays (`:84-93`).
  - **Used by:** `docs/CLOUD_SETUP.md:106` and the test at `test_docs_only_paths.py:132`.
  - **Stated reason:** "`--docs-only --base <sha>` is added" (step 2), plus the merge rule's "or on `--docs-only` against a commit that has one".
- **The 20 slowest test scripts printed after GUT**
  - **What:** `check.sh:297` runs `tools/checks/junit_slowest.py`.
  - **Used by:** people reading gate logs.
  - **Stated reason:** only the superseded draft step 2 ("the gate prints the 20 slowest scripts"). Approved step 2 doesn't mention it.
- **GUT totals in the Actions job summary**
  - **What:** `ci.yml:79-92`, push runs only.
  - **Used by:** whoever opens the run page.
  - **Stated reason:** none stated.

### 4. External

- **`gh` CLI:** now required by `cloud-gate.sh`. It is the local orchestrator's tool; per `CLOUD.md` it fails in cloud sessions.
- **`actions/upload-artifact@v7`:** a second use in the `check` job. It was already used at `ci.yml:105-112`.
- **`systemd-run --user`:** probed on each `check.sh` run (`check.sh:149`).
- No new libraries.

### 5. Config

- **`GODOT_SLOT_CLASS`**
  - **What:** gate, review, worker or probe, default `other`. It only fills the log's class column (`godot_slot.sh:52`).
  - **Stated reason:** the draft's "with a class label".
- **`BRAMBLE_SLOT_HELD=1`**
  - **What:** the wrapper sets it for its child (`godot_slot.sh:75`), and `check.sh` sets it after taking a slot (`:155`). When it is set, `check.sh` doesn't lock (`:152`).
  - **Stated reason:** the draft's "If `BRAMBLE_SLOT_HELD` is set, it doesn't lock itself."
- **`XDG_STATE_HOME`**
  - **What:** where both CSVs go.
  - **Stated reason:** none stated.
- **`cloud-gate.sh [label]`**
  - **What:** free text written into the CSV (`:54`, `:80`).
  - **Used by:** nothing.
  - **Stated reason:** none stated.

### 6. Public interfaces

- **`scripts/godot_slot.sh <command...>`:** if the command is `check.sh`, it execs it without taking a slot (`:70-72`). Otherwise it holds a slot for the command (`:74-78`). When sourced, it provides `godot_slot_acquire` and `godot_slot_release`.
- **`scripts/cloud-gate.sh <commit> [label]`:** prints `GATE <sha> PASS|FAIL <url>` and exits 0, 1 or 2. `--check <commit>` prints `PASSED <url>` or `NONE`.
- **`check.sh` arguments:** it now rejects any second argument, except in `--docs-only --base <sha>` (`:61-64`). Extra arguments used to be ignored. No caller passes two flags; the only matches are the new usage lines themselves.
- **`tools/checks/junit_slowest.py <gut.xml> [count]`.**

### 7. Internal machinery

- **`slot_take` / `slot_give` with an EXIT trap** (`check.sh:148-165`, `:338`, `:343`). The slot is held from just before import to just after tests.
- **fd 9 closed for every Godot command** (`check.sh:239`, `:257`, `:272`, `:293`; wrapper `:75`). Stated reason: none; there is only a code comment.
- **`MEMCAP`:** each Godot step runs under `systemd-run --user --scope -q -p MemoryMax=3G` when that works (`check.sh:142`, `:149-151`). Stated reason: the plan's "What stays: The two-Godot-process cap and MemoryMax=3G."
- **`rm -f` of `gut.xml` before each run** (`check.sh:291`).

**Tests and docs:**
- Tests: `test_docs_only_paths.py:118` (a moved base) and `:132` (a bad base is refused; this runs the real `check.sh`).
- Docs: `docs/CLOUD_SETUP.md:100-111` and `docs/ideation/CLOUD.md:46`.

**None:** nothing is deleted or deprecated.

**Unrequested:**
- the GUT totals job summary;
- the `label` argument;
- the `XDG_STATE_HOME` location;
- closing fd 9;
- the slowest-20 printout (draft only);
- gate branches that are never deleted;
- a Godot cache saved on every gate branch.

Neither CSV nor the `gut-junit` artifact has a reader in code yet.

**Size:** 8 files, +342 −14. Items by section: data 4, scheduled 3, features 3, external 3, config 4, interfaces 4, machinery 4.

---

## Part 2: interrogation (pr-interrogate)

### The four questions in the brief

**1. Does `--docs-only --base` keep the safety of `docs_only_paths.py`? Can `--base` let an unsafe change through?**

- **The checks are intact.** `check.sh` resolves `--base` to a commit (`:80`) and passes only the sha on.
  - `docs_only_paths.py` still lists committed, staged, unstaged and untracked paths with `--no-renames`.
  - It still refuses anything outside `docs/`, any `.gdignore`, and any `docs/` path that the `src/`, `tests/` or `tools/` GDScript names as `res://docs/...`.
  - Probe in a temp clone with a committed `src/` change: `--base HEAD~1` gave `refused ... src/core/board_geometry.gd: outside docs/`.
  - The diff is tree to tree (`git diff base HEAD`), so a base that isn't an ancestor still flags any code difference.
- **Yes, `--base` can let an unsafe change through. Nothing checks that the base has a cloud pass.** The same clone with `--base HEAD` went straight to `==> tools` and skipped the Godot steps. A worker's own ungated tip works the same way.
  - The old upstream mode has the same hole once a branch is pushed (the merge-base is then HEAD), so the hole isn't new.
  - What is new: `--base` makes it one word, and the merge rule leans on it. `CLOUD_SETUP.md:106` says "against a gated commit", but nothing enforces that.
  - The new test at `:118` asserts exactly this behaviour: "a code change before <sha> isn't counted".
  - This is ask 2.

**2. Does the `ideation/gate/**` trigger change anything on main or on PRs to main?**

- **The workflow logic doesn't.**
  - main's `ci.yml` is untouched, and nothing here goes to main.
  - The push filter matches `ideation/gate/**` only; tag pushes and main don't match it.
  - Both new steps run only when `github.event_name == 'push'`.
  - `exports` can't run on a push.
  - The concurrency group is per ref, so a gate can't cancel a PR run.
- **One shared resource changes: the repo's 10 GB Actions cache.**
  - A gate branch can read only its own caches and main's, and main has no Godot cache.
  - So all three runs logged `Cache not found`, downloaded Godot (1 s) and saved a 72 MB cache (3 s) that no later gate can read.
  - Usage is 2.76 GB now. At the plan's roughly 35 gates a day, the quota fills in about 3 days.
  - After that, GitHub evicts the least recently used caches, including PR caches (export templates are 381 MB). PR runs get slower; their verdicts don't change.
  - This is simplify 1.
- Gate branches pile up on the public origin, including the planted "never merge" commit.

**3. Does the slot logic leak the lock fd into Godot, or deadlock when `check.sh` runs through `godot_slot.sh`?**

- **No leak.** Every Godot command closes fd 9, and so does the wrapper's child. Probe: the child's fds were `0 1 2 3` under the wrapper and `0 1 2 255 3` in a `check.sh`-style step, with no fd 9. Short helpers between steps (grep, sed, python) do inherit it, and exit.
  - **The trade-off:** the stopgap passed fd 9 down, so a Godot that outlived its parent kept the slot. Now a Godot orphaned by a SIGKILLed `check.sh` or wrapper runs outside the two-slot count. A normal `timeout` kills the whole process group, so this needs a targeted kill. Keep; noted only.
- **No deadlock through the in-repo wrapper.**
  - `godot_slot.sh ./scripts/check.sh` execs `check.sh`, which takes its own slot (probe B: slot a, exit 0).
  - `godot_slot.sh timeout 10 check.sh`: the wrapper holds the slot and `check.sh` skips locking (probe C). In that form the hold also covers the static steps.
- **Deadlock with callers that already hold a lock without setting `BRAMBLE_SLOT_HELD`: yes.** Probes in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/slot2` used copies pointed at scratch locks, not the live ones.
  - **D:** one gate under the stopgap holds both locks for its whole run, so sims wait.
  - **E:** two gates under the stopgap at once both print `godot_slot: both Godot slots are busy; waiting` and wait until killed (exit 124 at the probe's 20 s limit).
  - **F:** `flock godot.lock flock harness.lock check.sh` waits until killed.
  - **These callers are still current instructions:**
    - DECISIONS, 10 Nov: "Gates, tests and probes run through `/tmp/bramble-godot-slot <command>`".
    - The stopgap's own usage line: `/tmp/bramble-godot-slot systemd-run --user --scope -q -p MemoryMax=3G ./scripts/check.sh`.
    - `tools/sim/HARNESS.md:837-839`: "Our gate also holds the harness lock".
    - `finalize-wave1-rebase.py:167`.
  - Step 1's "no local full gates" makes this rarer, but the plan keeps "a local gate is the fallback when Actions is down".
  - This is ask 1.

**4. Is anything more than the step asked for?** Nothing large:
- the slowest-20 printout (draft text only);
- the job summary step;
- the `label` argument;
- `GODOT_SLOT_CLASS` (draft text only).

The 3 GB cap, `--check`, the gates CSV and the extra-argument check each support an in-scope item (see the table).

### Criteria

1. **Same verdict and test count on 3 commits.** I checked the Actions side with `gh run view`:

   | Run | Commit | Verdict | Tests |
   |---|---|---|---|
   | 42696545119 | 2184f1ff | success | 1910, 1910 passing |
   | 42696549685 | debef85c | success | 1910, 1910 passing |
   | 42696555037 | 6a165c61 | failure; only the tests step failed | 1911, 1 failing |

   The third commit plants `assert_eq(1, 2)` in `tests/core/test_planted_failure.gd`. The session's own gate counts aren't committed anywhere, so the "same as Actions" half rests on its report.
2. **Hold at most the Godot steps plus 5 s.** This is met by construction: the slot is taken just before import (`check.sh:338`) and released just after tests (`:343`), with only Godot steps and their log greps between. I can't re-check the session's 399.9 / 409.9 / 415.1 s against 400 / 410 / 415 s from here.
3. **Push to verdict.** From run creation to completion: 4m56s, 5m23s and 4m12s, all under 7.5 min. Through `cloud-gate.sh` it adds up to about 4 s to find the run and up to 15 s of watch interval.

### Main path, end to end

**Never run.** The path is: `cloud-gate.sh <sha>` → push (`:61`) → find the run (`:65-71`) → watch (`:73`) → verdict and CSV line (`:74-81`) → failed log tail (`:84-86`).
- The session pushed by hand, since `gh` doesn't work in cloud sessions. That's also why the planted branch is named `planted-1` rather than by its sha.
- No test covers `cloud-gate.sh`, `godot_slot.sh`, the slot path in `check.sh`, or `junit_slowest.py`.

**`--check` works against real runs.** I probed it from a temp copy:

| Commit | Output | Exit |
|---|---|---|
| 2184f1ff | `GATE … PASSED …/runs/42696545119` | 0 |
| 6a165c61 | `NONE` | 1 |
| e5d3d41e | `NONE` | 1 |

e5d3d41e predates the trigger. As the docs say, only commits that carry the trigger can be gated, so in-flight worker branches must take ideation/main first.

**A flaky failure can't be retried through the script.** Re-gating the same sha is a no-op push (`:58-59`), so the script finds the old failed run and prints FAIL again. The plan counts 40 environment or flaky failures in four days, so the retry path (`gh run rerun <id>`, then `--check`) belongs in the docs.

**Merge note:**
- ideation/main changed `step_tests` after the base: `GUT_TIMEOUT=1200`, and `XDG_DATA_HOME` set to a temp dir. The GUT line will conflict. Keep `MEMCAP`, `-gjunit_xml_file` and `9>&-` together with both of those.
- `GUT_TIMEOUT=1200` s equals the job's `timeout-minutes: 20`. That's fine at today's roughly 220 s tests step on Actions.

### Verdicts

| # | Item | Verdict | Evidence | Action |
|---|---|---|---|---|
| 1 | `godot_slot.sh` wrapper, two-lock acquire | keep | step 2 "moves into the repo as `scripts/godot_slot.sh`"; `godot_slot.sh:19-40`, `:62-79` | none |
| 2 | `godot-slots.csv` | keep | the plan's checkpoints name its reader and when; `godot_slot.sh:43-55` | at the checkpoint: a waiter killed before it gets a slot writes no line; the 30 s lock sampler covers those |
| 3 | `check.sh` holds a slot from import through tests | keep | step 2; `check.sh:338`, `:343`; probe B | none |
| 4 | `check.sh` locking while its caller already holds a lock | **ask** | probes D, E, F; the stopgap's usage line; DECISIONS 10 Nov; `HARNESS.md:837-839` | before merge: make `/tmp/bramble-godot-slot` set `BRAMBLE_SLOT_HELD=1` for its child; move the DECISIONS and HARNESS recipes to `scripts/godot_slot.sh`; optionally add a wait limit to `godot_slot_acquire` |
| 5 | `BRAMBLE_SLOT_HELD` | keep | draft step 2; without it the probe C form would take both slots | none |
| 6 | `GODOT_SLOT_CLASS` | keep | draft "class label"; changes only a log column | none |
| 7 | fd 9 closed for Godot | keep | `check.sh:239/257/272/293`; fd probe | none (orphan trade-off above) |
| 8 | 3 GB scope per Godot step in `check.sh` | keep | "What stays: ... MemoryMax=3G"; without it the documented `godot_slot.sh ./scripts/check.sh` runs uncapped | none |
| 9 | the wrapper's own command runs uncapped | **ask** | `godot_slot.sh:75`, example at `:4`; the stopgap's usage line included `systemd-run ... MemoryMax=3G` | probe for `systemd-run` in the wrapper and run the command under it, or put it in the example and docs |
| 10 | GUT JUnit to `build/check/gut.xml` | keep | step 2; on Actions it parsed 182 test scripts | none |
| 11 | `junit_slowest.py` and the slowest-20 printout | keep | draft step 2 only; its reader is step 4's "ranked by junit times"; 38 lines | none |
| 12 | `--docs-only --base` | keep | step 2; `check.sh:43-50`, `:79-83`; refusal probe | none |
| 13 | `--base` accepts any commit | **ask** | probe: `--base HEAD` passes a committed `src/` change | tie it to `cloud-gate.sh --check <base>`, or write "check the base first" into the merge rule |
| 14 | `check.sh` rejects extra arguments | keep | `:61-64`; stops `--docs-only --bse X` silently running against the upstream; no caller passes two flags | none |
| 15 | push trigger on `ideation/gate/**` | keep | step 2; `ci.yml:9-10`; exports skipped in all 3 runs | none |
| 16 | Godot cache saved on every gate push | simplify | `Cache not found` in all 3 runs; 72 MB each, readable only by its own branch | add `&& github.event_name != 'push'` to Save Godot (`ci.yml:67`) |
| 17 | `gut-junit` artifact | keep | step 3 "from every Actions gate", step 4; artifacts of about 57 KB present | none |
| 18 | GUT totals in the job summary | simplify | none stated; `check.sh:295` already prints the same Run Summary into the step log | drop `ci.yml:79-92` and read counts from the log |
| 19 | `cloud-gate.sh` push, watch, verdict | keep | step 2 | gap: run it once for real; document `gh run rerun` |
| 20 | `cloud-gate.sh --check` | keep | approved step 1 merge rule; probe | none |
| 21 | `cloud-gates.csv` | keep | "Push-to-verdict time is reported"; step 6 | none |
| 22 | `cloud-gate.sh [label]` | simplify | none stated; nothing reads it | drop it (sha and url identify a gate), or leave it: 2 lines |
| 23 | the two new unit tests | keep | `test_docs_only_paths.py:118`, `:132` | none |
| 24 | docs (`CLOUD_SETUP.md`, `CLOUD.md`) | keep | describe the new paths | the stale DECISIONS and HARNESS lines are fixed under row 4 |
| 25 | gate branches left on origin | keep | they are the trigger; `--check` keys on them | open question below |

### Cut

None.

### Simplify

1. Skip `Save Godot` on push events (`ci.yml:67`). Each gate saves 72 MB of shared cache that no other run can read.
2. Drop the job-summary step (`ci.yml:79-92`). The same totals are already in the check.sh step log.
3. Optionally, drop `cloud-gate.sh`'s `label` argument.

### Gaps

- `cloud-gate.sh`'s push, watch and verdict path has never run.
- There is no retry for a flaky Actions failure; document `gh run rerun <id>`.
- The session's local gate counts and slot log for the criteria aren't committed as evidence.
- The merge conflict in `step_tests` with ideation/main (see the merge note).

### Original problem

The owner called the lock "very wasteful" and wanted tests run in the cloud with smarter scheduling. This step moves that: it proves Actions gives the same verdict in 4–5.5 min without the local lock, and it cuts a local gate's hold to the Godot steps.

Lock time only drops once gates actually go through `cloud-gate.sh`. Until the stopgap is retired (ask 1), a local gate can hold both slots or deadlock. The plan's checkpoints (median wait, local full gates a day) haven't been taken yet.

### Open questions

- Asks 1–3 above.
- Delete gate branches after the verdict? First check that `--check` still finds a run once its branch is gone.
