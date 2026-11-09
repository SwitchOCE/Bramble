**Does the plan answer the owner?** Partly. It answers three of the owner's questions:
- **Is the suite as fast as it can be?** No. Steps 1 and 5 work on that.
- **Could fewer tests have run?** Yes. About 30 of the 307 gates were redundant, and the orchestrator's 41 gates caught nothing.
- **Should tests be removed?** It answers honestly: the data supports moving and re-scoping tests, not mass deletion.

**It doesn't yet fix the lock.** The plan says lock time falls from about 326 to about 80 minutes a day, and that rests on two things it doesn't have:
1. **Workers sending their own cloud gates.** CLOUD.md says: "Codex's approval reviewer denies `git push`."
2. **Evidence 3's `--impact` tier, which runs 22% of the tests.** The plan defers it and puts `--fast` in its place. `--fast` still runs about 80% of the suite: moving rows 1, 4 and 15 out saves 45–75 s of about 350 s.

If Codex workers keep a local `--fast` run before handing off, most of their lock time stays. Also, nothing in the plan measures the owner's problem until step 2 lands:
- The `/tmp/bramble-godot-slot` wrapper logs waits only (12 starts since 20:11Z, 11 of them at 0 s, which is too few to judge).
- The sampler can't see the wrapper's waiters, because they loop on `flock -n` and `sleep 5`. Since 20:12Z it has shown 0 waiters while two Godot processes ran.

| Step or item | Moves the problem? | Proposed by | Verdict | Why |
|---|---|---|---|---|
| 1 Per-game slowdown | Yes: suite speed, and sims (58% of Godot time) | Critic (6, item 3) | Shrink | The 7 Nov soak ran prototype units (dewdrop_ooze and the like, 53 slice cards fired) against about 140 now, so a "same config at 7 Nov" may not exist. Profile one Hard lobby at HEAD first, bisect only if that names nothing, and time-box it. |
| 2 junit times, 20 slowest scripts | Yes: answers "as good as we can get", and feeds steps 5, 6 and sharding | Agent (2 §5.1) | Keep | |
| 2 In-repo slot with a wait/hold/exit log; lock only import→tests | Yes: the only working measure of the lock problem | Agent (2, 3) | Keep, move first | Workers will still gate locally, so the 36 s per gate saves more than the plan's "6 min a day". |
| 2 Time budget WARN | Indirectly | Critic | Shrink | Name who acts on it. The real cliff is `GODOT_TIMEOUT=600` in check.sh, and wave 2a's tests step is already 498 s. |
| 2 `--fast` tier | Weakly (about 20% per run) | Agent | Defer | Workers already iterate on targeted files (544 runs, median 2 s). `--fast` would become a local pre-handoff gate that keeps the lock busy. |
| 3 Actions gate on `ideation/gate/**` | Yes: the main lock fix, and it spares the Claude budget | Owner ("tests can run on the cloud"); Actions is an agent pick | Keep | The repo is public (checked). Log Actions as a deviation from "the cloud environment I set up", with the budget reason. |
| 3 Four-way shard by junit times | Latency only | Agent | Defer | Actions has never run today's 1,900-test suite (the last run had 632 tests). Ship unsharded, and relax criterion 2 to at most 7.5 min (the routine's time). Then step 3 doesn't wait on step 2. |
| 3 Who pushes | Decides whether the fix lands | Critic (cut 4) | Ask | CLOUD.md already says Codex can't push, so the critic's concern still stands: every worker verdict waits on an orchestrator turn. |
| 3 Merge rule | Yes: fewer runs | Critic (cut 2) | Keep | Today's `--docs-only` diffs against the merge-base with `@{upstream}`, so "docs-only against a passed commit" needs a base argument the plan doesn't list. |
| 4 Count and key-list re-pins | Yes: wasted reruns, and a smarter suite | Agent (4) | Shrink | Do the five pin tests plus benchmark_boards (the 32 of 88 re-pin failures). The card-number asserts come later. |
| 5a Library cache | Yes | Agent | Keep | Measure first, as planned. |
| 5b Iteration cuts, shared lobby | Yes | Agent | Keep | Judge the 25% drop in Actions junit times; a "same machine" local run needs the lock. |
| 6 Deletes and moves | Yes ("remove some") | Owner's aim; agent picks the specifics | Keep, fold into 5 | Three tiny items don't need their own worker. |
| Nightly `--keep-going` run and 200-seed soak | Backstop | Agent | Ask | No step builds them, and `on: schedule` runs only on `main`. |
| Two-process cap, MemoryMax=3G | No | Owner (RAM) | Keep | |
| `--impact` deferred | No | Agent | Keep deferred | |

**Fixed after step**
- **As written:** the lock is fixed at step 3, and only if worker gates move to the cloud. With local `--fast` runs, no step fully fixes it. Suite speed improves at step 5, or at step 1 if it finds a fix.
- **Reordered:** after step 2 below.

**Smallest plan**
1. **Today:**
   - adopt the merge rule;
   - the orchestrator stops running local gates;
   - move the wrapper into the repo with the wait/hold/exit log;
   - lock only import→tests.
2. **Unsharded Actions gate:** add `cloud-gate.sh` and settle who pushes. Workers run only targeted files locally.
3. **junit times from Actions** (free, no lock) and the per-game profile in the cloud, in parallel.
4. **Steps 5a/5b** plus the three deletes, ranked by junit times.
5. **Re-pin rewrites,** after wave 2a merges.
6. **Shard** only if the verdict takes over 7.5 min.

**Deferred**
- `--fast`, until Actions outages or workers show a need for a local near-full run.
- The WARN line, until the tests step passes about 450 s.
- Sharding.
- The nightly run, until a test leaves the default run.
- `--impact`.
- A third slot, after the owner's RAM upgrade.

**Checkpoints**
- After step 1, a day of the slot log: median wait, waits over 5 min, and flock timeouts. That is the owner's problem in numbers, and the baseline after the stopgaps.
- After step 2, the same log. Local full gates and Claude routine gate runs should be near 0.
- After step 4, the tests step's time against today's 347 s.

**Open questions**
1. Will the owner let Codex push to `ideation/gate/**`? That is a change to the owner's Codex approval rules, so agents can't make it on their own. If not, the orchestrator relays every worker verdict, at a Claude-budget cost.
2. What to tell the owner, in plain words:
   - about 2 of 15.5 gate hours were redundant;
   - sims, not tests, used most of the Godot time;
   - tests get moved and re-scoped, with three small deletions.
