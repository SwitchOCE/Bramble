# Test suite and Godot lock plan (10 Nov 2026)

**Status:** approved 10 Nov in the reordered form below (DECISIONS, "Test-suite plan approved"). The step list further down is the draft the interrogation reordered, kept for its reasoning; where the two differ, **Approved order** decides. **Owner's words:** `docs/design/owner-notes/2026-11-10a-godot-lock-and-test-suite.md`. **Evidence:** `evidence/test-suite/` (1 run history, 2 suite profile, 3 scheduling design, 4 pruning, 5 first plan, 6 critic). This plan is the first plan with the critic's four cuts fixed.

## What the last four days show (6–9 Nov)

- **Godot time:** about 54 hours. Sims 58%, gates and GUT about 31%. 307 full gates used about 15.5 hours of lock time.
- **Failures:** 337 runs failed:
  - 28 real regressions caught, about 19 incidents;
  - 41 re-pins after an intended change;
  - 40 environment or flaky failures;
  - 136 deliberate red runs while writing code.
- **Which tests caught them:** all the catches came from UI, contract and content-consistency tests (cards, core port, polish, phone layout, portraits, playthrough). The slow whole-game and balance tests caught none. A golden hash can only ever show up as a re-pin, so "caught none" doesn't prove those tests are useless.
- **Fewer runs would have done:**
  - About 30 of the 307 gates re-ran an unchanged tree, or one where only docs had changed.
  - The orchestrator ran 41 gates and they caught nothing.
  - 11 of 17 merges since 9 Nov changed nothing outside docs/ compared with the tip the worker had already gated.
- **The suite is getting slower fast:** the tests step on ideation/main took 69 s on 7 Nov, 228 s on 9 Nov and 347 s on 10 Nov. Wave 2a's takes 498 s.
  - A full bot game went from 381 ms to 3.9–5.7 s (soak logs).
  - The unit library is rebuilt about 1,100 times per run.
- **The queue:** in the sampled window someone was almost always waiting. The lock was held through about 36 s of non-Godot steps per gate.
- **Stopgaps already in place today:**
  - `--docs-only` (a200e88f);
  - the two-slot wrapper;
  - a routine cloud gate: about 7 min, no local lock, 3 passes so far.

## Approved order (after plan-interrogate, `evidence/test-suite/7-plan-interrogate.md`)

Codex workers can't push (CLOUD.md), and changing that is the owner's call. So the orchestrator sends each worker's tip to the cloud gate when the worker hands off, at the same time as the scope review. Workers stop running local full gates.

1. **Today (working rules):**
   - **The merge rule:** ideation/main moves only on a full cloud pass for that exact commit, or on `--docs-only` against a commit that has one.
   - **The orchestrator** runs no local full gates.
   - **Workers** run only targeted test files locally, through the slot wrapper, and hand off without a full gate.
2. **Gate plumbing (one cloud session):**
   - The slot wrapper moves into the repo as `scripts/godot_slot.sh`, with a wait/hold/exit log.
   - `check.sh` takes a slot only from import through tests.
   - GUT writes junit.
   - `--docs-only --base <sha>` is added.
   - An **unsharded** Actions gate runs on push to `ideation/gate/**`.
   - `scripts/cloud-gate.sh` pushes, watches with `gh`, and prints the verdict.
   - **Criteria:**
     1. Actions and the session's own gate give the same verdict and test count on 3 commits, one with a planted failing test.
     2. The logged hold is at most the Godot steps plus 5 s.
   - Push-to-verdict time is reported; it should be at most 7.5 min.
3. **In parallel (cloud, no lock):**
   - Per-test junit times, from the running profile routine and then from every Actions gate.
   - The per-game slowdown: profile one Hard lobby at HEAD first, and bisect only if the profile names nothing. Time-boxed at 90 min.
   - **Criteria:**
     1. The hot path is named with its share of time.
     2. Any fix leaves fight results and event hashes identical on 12 seeds.
4. **A faster suite (5a library cache, 5b iteration cuts and a shared read-only lobby, plus the three deletes), ranked by junit times.**
   - **Criteria:**
     1. The Actions junit time of the tests step drops by at least 25%.
     2. Three planted bugs (a pool leak, nondeterminism, quiet and logged fights differing) each still fail.
   - Every deleted test names what still guards its behaviour.
5. **Re-pin rewrites, after wave 2a merges:** only the five count and key-list tests plus benchmark_boards (32 of the 88 re-pin failures). Card-number asserts come later.
   - **Criteria:**
     1. A dummy unit fails none of them.
     2. A missing portrait, a wrong state key, and a unit file that fails to load each still fail.
6. **Shard the Actions gate** only if the verdict takes more than 7.5 min.

**Deferred:**
- `--fast`, until a need shows;
- the WARN budget line, until the tests step passes 450 s (`GODOT_TIMEOUT` is 600 s);
- a nightly run, until a test leaves the default run;
- `--impact`;
- a third slot, after the owner's RAM upgrade.

**Checkpoints (the owner's problem in numbers):**
- the slot log's median wait, waits over 5 min, and flock timeouts: a baseline now, again after step 2, and a day later;
- local full gates a day, which should be near 0 after step 2;
- the tests step's time against 347 s, after step 4.

## The draft steps (superseded by the approved order above)

Each step names at most two deciding criteria (09i). Everything else it reports.

### Step 1: find the per-game slowdown (cloud routine, read-only on game code until the cause is named)
A full bot game got about 10× slower in three days. Tests, gates and sims all pay for this, and sims are 58% of Godot time. Doing step 5's trims while this cost keeps growing would be wasted.
- Time one fixed-seed Hard lobby, same config, at a 7 Nov commit and at ideation/main. The soak mixes configs, so measure like for like first. If there is a jump, bisect it, then profile the hot path.
- If the cause is a code inefficiency that can be removed without changing results, fix it.
- **Criteria:**
  1. Per-game time at both commits on the same config, with the cause named.
  2. If a fix lands: fight results and event hashes are identical on 12 fixed seeds, and time per game drops.

### Step 2: lock only Godot, time every test, keep a budget, add a fast tier (one worker or routine: `scripts/check.sh`, new `scripts/godot_slot.sh`, `.gutconfig.json`)
- **The slot:** the wrapper moves into the repo, with a class label and a wait/hold/exit log. `check.sh` takes a slot only from import through tests. If `BRAMBLE_SLOT_HELD` is set, it doesn't lock itself.
- **Timing:** GUT writes `build/check/gut.xml` (junit) and the gate prints the 20 slowest scripts. Over 420 s for the tests step, or over 20 s for one script, it prints a WARN line; it doesn't fail.
- **The fast tier:** `--fast` skips the scripts listed in `tools/checks/slow_tests.txt`, for worker iteration only. The default `check.sh` still runs every test. Nothing becomes cloud-only.
- **Criteria:**
  1. The logged hold is at most the Godot steps plus 5 s.
  2. gut.xml has a time for every test, and the default run's test count equals today's.

### Step 3: GitHub Actions gate, and the merge rule (one worker: `.github/workflows/ci.yml` on ideation branches only, new `scripts/cloud-gate.sh`)
- **Trigger:** `ci.yml` gets `push: branches: ["ideation/gate/**"]`, a 4-way shard matrix balanced by step 2's junit times, and the static steps on shard 1. It builds no exports.
- **The script:** `cloud-gate.sh` pushes HEAD to `ideation/gate/<sha>`, watches the run in the background, and prints the verdict plus the failure tail.
- **Why Actions:**
  - It's free for a public repo, and the owner is near the Claude budget.
  - It notifies when a run finishes.
  - It runs in parallel.

  The Claude routine stays as the fallback.
- **Who pushes:** check first whether Codex workers may push `ideation/gate/**`. If they can't, the orchestrator pushes. Never `main`.
- **The merge rule:** ideation/main moves only on a full cloud pass for that exact commit, or on `--docs-only` against a commit that has one, checked with `gh run list --commit`. That replaces the separate hash cache, which could have passed a tree whose checked inputs changed (critic cut 2).
- **Criteria:**
  1. On 3 commits, one with a planted failing test, Actions and a local gate give the same verdict and the same test count.
  2. The median time from push to verdict is at most 6 min over the first 5 runs.

### Step 4: stop re-pinning counts (one worker, after wave 2a merges, to avoid conflicts)
- Rewrite these to derive from the data, not fixed numbers:
  - the count and key-list pins: unit_library, portraits, fixture_port, slice_keywords, benchmark_boards;
  - game_session's key list, read from `engine.md`;
  - the card-number asserts in balance_1/2, belly, fly_south, slice_fairies and bot_held.
- They caused 32 of the 88 re-pin failures.
- **Criteria:**
  1. Adding a dummy unit fails none of them.
  2. A missing portrait, a wrong state key, and a unit file that fails to load each still fail.

### Step 5: a faster suite, same guards (after steps 1 and 2; re-rank by junit times)
- **5a, the library cache:** measure one library build first, and check that a deep copy beats a parse. Then parse once per run and give each kit a deep copy.
- **5b, iteration cuts and a shared lobby:**
  - One shared Hard lobby per run, read-only or deep-copied.
  - test_game_log plays its game once.
  - Cuts: full_games 5→2 seeds, combat_logging 32→8, field_mode deals 200→50, bot_held 40→12 rounds, pass3_bots 12→8, screens_smoke steps by hand instead of waiting 2 s.
- **Criteria:**
  1. The junit time of the tests step drops by at least 25% on the same machine.
  2. Three planted bugs (a pool leak, nondeterminism, quiet and logged fights differing) each still fail the suite.

### Step 6: moves and deletes (after step 2's timings and step 5)
- **Delete:**
  - `normal-9af89c2.json`, which nothing reads;
  - the Hard half of bot_brain's full-game test, covered by the shared lobby and the field regression.
- **Keep:**
  - the quiet-fight test (milliseconds, and the only check that a quiet fight logs nothing);
  - the field regression in the default run. It guards step 5's refactor.
- **Slow tests:** they go in `slow_tests.txt` (skipped by `--fast`), not cloud-only.
- **Criteria:**
  1. Every deleted test names the test that still guards its behaviour.
  2. The planted bugs from step 5 still fail.

## Applied in order, what changes

- **Fewer gates:**
  - The docs-only rule and the merge rule remove about 30 of 307 gates on four days' volume, and stop merge re-gates.
  - Step 3 moves the remaining full gates (about 35 a day) off the local lock.
  - Workers keep local `--fast` and targeted runs.
- **Local lock:**
  - About 326 lock-minutes a day falls to about 80. Workers' fast runs remain.
  - Step 2's 36 s per gate saves only about 6 min a day once gates are in the cloud. It's done for the timings.
  - Step 2's log checks this after a day.
- **Suite time:** step 1 is the only lever bigger than one day's growth. Steps 5 and 6 save roughly 55–110 s of today's 350 s.
- **Removing tests:** the data supports moving and re-scoping tests, not mass deletion. There are three small deletions, about 13 files of re-pin rewrites, and a fast tier.

## What stays

- The UI and contract tests: they made every catch.
- Red-first test runs: they are the normal development loop and cheap.
- The two-Godot-process cap and MemoryMax=3G. The owner is adding RAM; revisit after that, and after the cloud profile measures memory per GUT process.
- Sims keep the harness slot. Heavy sweeps keep going to the cloud.
- Automatic test-impact selection is deferred. 59% of commits needed no Godot tests and 16% needed all of them, and workers already pick targeted files.

## Risks and backstops

- **Shrinking whole-game tests misses a bot or rules bug.** Backstops: one shared Hard lobby every run; the field regression every run; sims playing these paths hundreds of times a day; a nightly `--keep-going` cloud run plus the 200-seed soak.
- **Cloud and local disagree.** The fresh cloud checkout decides, and a local gate is the fallback when Actions is down.
- **Something merges untested.** ideation/main moves only on a cloud pass for that commit, or a docs-only diff from one (step 3).
- **The failure classes are judgement calls,** and about 45 failed gates don't show which files failed. Nothing is deleted before step 2's timings exist.
