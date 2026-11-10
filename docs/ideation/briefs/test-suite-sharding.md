# Brief: shard the Actions gate (test-suite plan step 6)

Written by the orchestrator, 10 Nov 2026, for a cloud session. The routine's prompt points here.

You build step 6 of the approved test-suite plan: shard the Actions gate. Read `docs/ideation/plan-test-suite.md` (**Approved order**), the DECISIONS entries "Test-suite plan approved" and "Gate plumbing merged; gates go through Actions; next, sharding and the faster suite", and `docs/CLOUD_SETUP.md` ("The ideation gate on Actions"). The owner's note is `docs/design/owner-notes/2026-11-10a-godot-lock-and-test-suite.md`: "tests can run on the cloud, and you can figure out smart ways of scheduling tests."

**Why now:** on ideation/main (with wave 2a and the combat fast paths merged) the Actions tests step takes 559 s, and push to verdict is about 11 min (run 42706292823; it was 771 s and 15 min before the fast paths). The plan shards when the verdict takes over 7.5 min. Actions minutes are free (public repo), and shards run in parallel.

Work on a new branch `ideation/c-gate-shards` from `ideation/main` and push it. Keep each change small.

1. **Shard map.** Build `tools/checks/test_shards.py`. It assigns every GUT test script under `tests/` to one of N shards (default 4), balanced by the per-script times in a junit file. Use the `gut-junit` artifact of run 42702428298 if you can download it; the public API may refuse artifact downloads, so otherwise run the full suite here once and use your own `build/check/gut.xml`. Commit the times as a small data file. A script that isn't in the times file (a new test) is placed by a stable rule, such as a hash of its path or the lightest shard at a default weight. Add Python tests:
   - every script lands in exactly one shard;
   - the union of shards equals the full set;
   - a new script still lands somewhere.
2. **`check.sh --shard i/n`.** It runs only shard i's scripts in the tests step. GUT can take an explicit list of scripts (look in `addons/gut` for the option, such as `-gtest`). The strict hook, the parse-error check and the zero-tests backstop still apply to each shard. Without `--shard`, `check.sh` behaves exactly as today: the local and fallback gate stays unsharded. Combine it with the existing flags only as far as the gate needs.
3. **The Actions gate on `ideation/gate/**` pushes:**
   - The static steps plus import, compile and parity run once.
   - The tests run as a matrix of N shard jobs, each with import, then `check.sh --shard i/n` for the tests step only. Split the steps as fits `check.sh` cleanly, and say how you did it.
   - The run's conclusion is the verdict, so `scripts/cloud-gate.sh` needs no change, or a minimal one. Each shard uploads its junit file.
   - PR and manual runs stay exactly as they are.
4. **Two simplifications from the gate-plumbing review** (`docs/ideation/evidence/review-gate-plumbing.md`, simplify 1 and 2):
   - Don't save the Godot cache on push events. Gate branches can't read each other's caches, so each save only fills the 10 GB quota.
   - Drop the "GUT totals to the job summary" step.
   - The orchestrator's local `gh` login can't push `ci.yml` changes (no `workflow` scope), so all `ci.yml` edits happen here.

**Deciding criteria (only these two):**
1. **Same verdict and the same total test count as the unsharded gate,** on 2 commits: your branch tip, and a throwaway `ideation/gate/planted-shards-<n>` with one failing test placed in a shard other than shard 1. Never commit it to your work branch. Unsharded reference: 2,158 tests on ideation/main, or your own unsharded `./scripts/check.sh` here on the same tree.
2. **Push to verdict at most 7.5 min,** as the median of 3 gate runs. Read run times with the public REST API (curl) if `gh` doesn't work here.

Also report, not as criteria: each shard's test time, the slowest shard, and the static job's time.

Update the gate section of `docs/CLOUD_SETUP.md`. Run the full unsharded `./scripts/check.sh` before your last push. Your final message is under 250 words: the commits, the two criteria with their numbers and run URLs, and anything you couldn't do.
