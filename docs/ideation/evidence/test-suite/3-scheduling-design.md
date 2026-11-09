# Test scheduling design: tiers, a cloud gate, a result cache, test selection and fair locking

## What the logs show

All figures cover 9 Nov UTC, which is 10 Nov local (00:35 to 19:53 UTC). They come from 64 gate logs that are still on disk, so they are a lower bound because overwritten logs are missing. The extraction is in `/tmp/claude-1000/gatedesign.cYUE/gates.txt` and `gates.json`, built by `mine2.py` from `/tmp/bramble-*.log` and `~/code/Bramble-ideation*/build/**`.

- **Volume:** 51 runs reached the tests step. They used 285 Godot-minutes. Another 41 minutes of format and lint ran while holding the lock.
- **Times:** a full run's median is 318 s, and the tests step's median is 270 s (p90 492 s, max 750 s). In one day the suite grew from 1,608 to 2,092 tests and its time doubled.
- **Repeats:** 16 runs had the same test count as an earlier run, which suggests the same code. They cost 75 Godot-minutes. Five were orchestrator gates on diffs that only touched docs/ (c74c2b9, ec19dc3 and 601965b differ only in docs/), and those are now covered by `--docs-only`. Another was `strong-field-merge` at 14:53, a 395 s rerun of the worker's `last-gate` on the same code.
- **Failures:** 11 runs failed. Five failed at compile within about 50 s. Six failed in tests after 134 to 612 s.
- **Merges:** of 16 merges into ideation/main since 9 Nov, 11 changed nothing outside docs/ compared with the merged branch's tip (from `git diff <branch-tip> <merge>`).
- **Lock queue:** the sampler shows 2 to 5 waiters behind one holder (`build/orchestrator/lock-samples.csv`, 19:49 to 19:55 UTC).
- **GitHub Actions:** job 128220985198 ran `check.sh` with 632 tests in 67 s, with about 10 s of setup.
- **Docs-only hole, being fixed:** Godot tests read `docs/ideation/engine.md` and `docs/prototype/fixtures/`. The uncommitted `tools/checks/docs_only_paths.py` closes this. Reuse its `docs_read_by_code()` below.

## 1. Tiers

| Tier | When | Command | Where | Godot |
|---|---|---|---|---|
| T0 static | Every commit | `check.sh --static` (tools without Godot, versions, shell, python, content, format, lint; about 40 s) **[check.sh]** | Local, no lock | No |
| T1 impact | Worker iteration | `GATE_CLASS=worker check.sh --impact`: import, compile, parity, then only the selected tests **[check.sh]** | Local, in a Godot slot | Yes |
| T2 full | Before merge, on the branch tip after merging ideation/main into it | `scripts/cloud-gate.sh <worktree>` **[new script]** | GitHub Actions | Yes |
| T3 merged | After merging into ideation/main, before pushing | Cache lookup. On a miss, T2 runs on the merged tree. Push only on PASS, in the same command. | Cache, else Actions | On a miss |
| T4 nightly | Daily | ideation/main and active branch tips, `--no-cache --keep-going`, plus the UI run, soak and export smoke | Actions, plus a scheduled cloud routine for the xvfb runs | Yes |

Only import, compile, parity and tests need Godot. The tools step calls `godot --version`, which loads no project and needs no lock.

**Rule:** only a full-mode pass on the exact key can merge a tree. Reviewers cite the cache entry and run targeted probes only.

## 2. Cloud gate

`cloud-gate.sh` does four things:
1. Computes the key and stops if it is already cached.
2. Runs `git push -f origin HEAD:ideation/gate/<topic>`.
3. Runs `gh run watch <id> --exit-status`, in the background so it notifies on exit.
4. On PASS, writes the cache entry. On FAIL, prints `gh run view --log-failed | tail`.

`ci.yml` gets `on: push: branches: ["ideation/gate/**"]` and a 4-way shard matrix: `check.sh --shard i/4`, with the static steps on shard 1 only **[check.sh + ci.yml]**.

**Why Actions rather than Claude routines:**
- Actions minutes are free while the repo is public, and the owner is near the Claude budget.
- It notifies on exit; routines must be polled.
- It has no 2-minute session setup.

Claude routines stay as the fallback, and they do the nightly UI run and soak.

**Latency (an estimate, to check on the first run):** about 1 minute to queue and set up, plus about 4 to 5 minutes unsharded or about 2 minutes sharded. There is no local lock wait.

**Failure modes and what to do:**

| Failure | Response |
|---|---|
| Actions is down or slow | Fall back to a local `GATE_CLASS=merge` gate |
| Codex workers can't push | The orchestrator pushes gate branches, as it already pushes their commits |
| Push events use the pushed commit's `ci.yml` | Branches must merge ideation/main first |
| `on: schedule` runs only on main | Nightly is a push from a scheduled cloud routine |
| Pass in the cloud, fail locally (stale `.godot` import cache) | The fresh cloud checkout is authoritative |

**Local is still better for:**
- compile failures (about 50 s);
- docs-only changes;
- T1 iteration;
- screenshots the orchestrator looks at;
- exports to `/data/bramble-builds/`.

## 3. Gate-result cache [check.sh + `tools/checks/gate_key.py`]

**Key:** sha256 over these parts:
- the `git ls-tree HEAD` lines except `docs`, which covers versions.env, check.sh, .gutconfig.json and ci.yml;
- the blob IDs of the docs paths Godot reads, plus every `docs/**/.gdignore`;
- the mode;
- `godot --version`.

Nothing is read from or written to the cache if anything outside docs/ is uncommitted or untracked.

**Where it lives:** `~/.cache/bramble-gate/<key>.json`, shared by all worktrees. Each entry holds the result, sha, host, run URL and time.

**How check.sh uses it:** a hit prints `cached PASS <sha> <url>` and exits 0. `--no-cache` forces a run. Only full-mode passes are written.

**Effect on merges:** a fast-forward merge, or any merge that changes only docs/ relative to the gated tip, reuses the worker's pass. That was 11 of the 16 recent merges. Nightly `--no-cache` runs catch flaky tests that a cached pass would hide.

## 4. Test-impact selection [`tools/checks/test_impact.py`, used by `--impact`]

This replays history through a static GDScript graph built from `class_name` and `res://` references (`deps.py` and `select.py` in the scratch dir).

**Rules:**
- **Full suite:** `src/core/`, `content/`, `project.godot`, `addons/`, `assets/`, `tests/fixtures/`, test helpers, `tools/checks/*.gd`, and docs that Godot reads.
- **`src/ui`, `src/main`:** `tests/ui/**` plus the 12 core tests that reach src/ui.
- **`tools/sim`, `tools/play`:** their static dependents, at most 9 and 12 scripts.
- **A `test_*.gd` file:** that file alone.
- **Other docs:** nothing.

**Replay of 404 ideation commits since 9 Nov:**
- 16% needed the full suite.
- 25% got a partial selection, with a median of 19% of test functions.
- 59% needed no Godot tests.
- On average, 22% of test functions were selected.

**Safety:** src/core loads code dynamically (its files have a median of 0 static test dependents), so core always means the full suite. String-built paths could still be missed. Four things guard against that:
- T1 never qualifies a merge;
- every merge needs a full pass on its key;
- nightly runs the full suite on every active branch tip;
- a selection audit logs any full-run failure in a test that `--impact` skipped for that diff, and widens the map.

## 5. Lock hygiene [check.sh + `scripts/godot_slot.sh`]

- **Lock only the Godot steps:** check.sh takes the slot once, from import through tests, and puts each Godot call under `systemd-run --scope -p MemoryMax=3G`. The 40 s static block runs outside the lock.
- **No self-deadlock:** today's callers wrap `flock … check.sh`. If check.sh then took the lock itself, it would wait on itself forever. `godot_slot.sh` sets `BRAMBLE_SLOT_HELD=1` so check.sh skips its own lock. Retire the raw-flock wrapper in briefs the same day **[rule]**.
- **Queue:** a waiter writes `/tmp/bramble-godot-queue/<ns>-<class>-<pid>` and acquires only when it is at the head. Priority runs merge, then review, then worker, then sim, first come first served within a class. Waiters move up one class every 15 minutes so nothing starves. Dead entries are removed.
- **Wait log:** each acquisition appends time, class, label, wait, hold and exit code to `~/.local/state/bramble/godot-waits.csv`.
- **Two slots for anyone:** the two existing lock files become a pool, and sims may use only the harness slot. The limit stays at two Godot processes.
- **Possible third slot:** only if the profiling routine measures peak test memory near 1 GB.

## 6. Expected savings per day (assumptions in brackets)

| Item | Godot-minutes saved locally | Lock-hold minutes saved |
|---|---|---|
| Docs-only (already shipped) | 25 | 25 |
| Cache, repeats on unchanged code | about 50 (11 runs) | about 50 |
| Full gates moved to the cloud (about 35 runs) | about 210 moved out, about 80 added back as T1 [1.5 T1 runs per moved gate, 22% selection, 10 s import and compile] | about 130 net |
| Static steps outside the lock | – | 41 |
| **Total** | **about 285 → about 80 (−70%)** | **about 326 → about 80 (−75%)** |

Lock wait has not been measured. The DECISIONS entry estimates 2 to 4 worker-hours lost per 8 hours. With the slot about 90% busy, a simple queue model puts the mean wait at about 9 jobs, about 45 minutes. At about 30% busy it falls to about 2 minutes, and merges never queue because they go to the cloud. This is a model, not a measurement; `godot-waits.csv` checks it after one day.

## Summary by kind of change

| Kind | Items |
|---|---|
| Changes to check.sh | `--static`, `--impact`, `--shard`, the cache lookup and write, and the lock around the Godot steps only |
| New scripts | `gate_key.py`, `test_impact.py`, `godot_slot.sh`, `cloud-gate.sh` |
| CI | the `ci.yml` push trigger and the shard matrix |
| Working rules only | tier use, merge needs a full pass on the key, reviewers cite the cache, the orchestrator pushes gate branches, merge ideation/main into the branch before T2, the nightly routine, the fallback order, and retiring raw-flock wrappers |

Files are in `/tmp/claude-1000/gatedesign.cYUE`:
- `gates.txt`
- `gates.json`
- `mine2.py`
- `deps.py`
- `select.py`
- `rev.json`
