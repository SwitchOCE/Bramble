**Verdict: approve with changes.** The structure holds up: rules first, then lock scope, cloud gate, cache, suite work and pruning. But four things need fixing before approval, and several numbers are mis-sourced or counted twice.

**Spot-checks that held** (`/tmp/claude-1000/runhist.Prqr/runs.csv`, `per_file.csv`):
- 307 gates (254 full, 49 `--keep-going`, 4 `--docs-only`).
- Gates by role 146/92/41/20/8.
- Sims 31.2 h.
- 32 of 88 re-pins came from the five pin tests.
- The repo is public (`gh repo view`).
- Rerunning `select.py` now gives 421 commits: 58% need no Godot tests, 17% need the full suite, mean 23% of tests.

1. **CUT: the cloud-only tests break "every merge passes the full gate".** The local fallback, used "only when Actions is down", would skip the field regression and the other cloud-only tests. Fix: the default `check.sh` runs every test. Add a `--fast` mode for worker iteration only.

2. **CUT: the cache can pass a tree whose checked inputs changed.**
   - The versions step reads `docs/CLOUD_SETUP.md` (`tools/checks/versions.py:24`), which the cache key leaves out.
   - A local pass on a stale `.godot` or ignored `build/` file would be cached.
   - Fix: the cache skips only the import-to-tests steps, and the static steps always run. Only cloud passes write entries.
   - Simpler: step 4 becomes `--docs-only` against the last cloud-passed SHA (checked with `gh run list --commit`). That reuses `docs_only_paths.py`, is exactly step 1's rule, and needs no new hash store.

3. **CUT: the biggest speed lever is missing.**
   - A full bot game went from 381 ms (`build/check/soak.log`, 7 Nov) to 3.9–5.7 s (`-tribes2` and `-balance` `build/check/soak.log`), at 46 vs 49 fights per game.
   - The tests step on main went from 69 s for 952 tests (`gatedesign.cYUE/gates.txt`, 7 Nov) to 228 s (`gate-c74c2b9.log`, 9 Nov) to 347 s (`funprobe-docs.log`, 10 Nov). Wave2a's tests step takes 498 s and its gates up to 805 s.
   - Step 5 saves 55–110 s, which is less than one day's growth. Sims (58% of Godot time) pay the same per-game cost.
   - Fix: first time one fixed-seed Hard lobby at a 7 Nov commit and at HEAD, with the same config. The soak's config changed in between (`soak.gd` mixes configs), so measure before blaming the code. Then profile the hot path.
   - Also add a time budget to `check.sh` (warn above N s per script or for the whole tests step), so the suite doesn't grow back.

4. **CUT: who pushes the cloud gate.** If the orchestrator pushes every gate branch, each worker's gate waits for the orchestrator's next turn. That makes the common case slower than a local gate once the queue is short.
   - Fix: workers run `cloud-gate.sh` themselves. First check that Codex approvals and cloud Claude sessions can push to `ideation/gate/**`.
   - Or use `workflow_dispatch` on ideation/main with a SHA input. That also drops the forced "merge ideation/main first", which adds merge commits to worker branches only to pick up `ci.yml`.

5. **ASK: savings are counted twice.**
   - Step 1's ~30 gates already include step 4's 21 (runhist §4: "All three (with overlap) about 30").
   - Step 2's 36 s per gate and steps 5–6's local seconds fall mostly on gates that step 3 moves to the cloud. At about 10 local gates a day, step 2 saves about 6 min a day, not 40.
   - Step 1's proof (10 or fewer local gates a day) depends on step 3.
   - Fix: give one estimate that applies the steps in order.

6. **ASK: some deletions guard more than they cost.**
   - `test_quiet_fight_has_the_same_result` (`tests/core/test_bot_brain.gd:97`) is a tier-1 fight of one unit against one. It costs milliseconds, and it is the only check that a quiet fight logs no events. Meanwhile combat_logging is cut from 32 seeds to 8. Keep it.
   - "Field regression caught none" says nothing about its value: a golden hash can only ever be classed as a re-pin. Keep it local until step 5's library deep-copy and shared-lobby refactor has passed it; it is the guard for exactly that change.

7. **ASK: steps 5 and 6 are too big for one worker each.**
   - Split step 5:
     - 5a: the library cache. Measure the cost of one library build first, and check that a deep copy is actually cheaper than a parse.
     - 5b: the iteration cuts and the shared lobby. The shared lobby must be read-only or deep-copied, because all scripts in one GUT process share it.
   - Split step 6:
     - 6a: rewrite the pins. It can start now.
     - 6b: the moves and deletes, after step 2's timings exist.

8. **ASK: fix the sourcing in the Findings.**
   - "62 s of the 223 s tests step on 7 Nov" mixes a single targeted run (`prune.7nSA/measured.txt`, n=1) with a gate from 9 Nov 18:45 (`build/orchestrator/gates/gate-c74c2b9.log`).
   - "0.135 to 0.355 s in 3 days" compares main with a contended wave2a run from the same day.
   - The 32 of 88 comes from `per_file.csv`, not `churn2.json`.
   - The "11 of 16 merges" cites `rev.json`, which is a dependency map. My own count: 11 of 17 merges since 9 Nov have no change outside docs/ against the branch tip they merged.
   - The 97% waiting figure covers a single 20-minute window.

**Does it answer the owner?**
- It answers the lock, the cloud and smarter scheduling.
- It answers "is the suite as fast as it can be?" only in part, because it misses item 3.
- On removing tests: there are only about 3 small deletions. Tell the owner plainly that the data supports moving and re-scoping tests, not mass deletion.

Scratch dir: `/tmp/claude-1000/critique.DyoS`
