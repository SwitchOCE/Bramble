# Brief: the Actions sim job, then the soak rework (plan to Done, stream S4)

Written by the orchestrator on 10 Nov 2026 for the sharding session. It follows that session's gate-shards work, which merged with no cuts.

Plan: `docs/ideation/plan-to-done.md`. Read §1 item 5, §2 rows A1b, A3.5 (with "A3.5 in detail") and A4, §3 row S4, and §4 criterion 1. You own:
- `.github/workflows/sim.yml`;
- `tools/checks/soak.gd`, `soak.sh`, `soak_plant.sh`, `soak_content.gd`, `soak_bot.gd`, `soak_coverage.gd`, `soak_seed_trace.gd`, `soak_copy_check.gd`, and their tests;
- `scripts/cloud-gate.sh`, `.github/workflows/ci.yml` and `scripts/check.sh` (shared with the faster-suite session; keep your changes small and merge `ideation/main` first);
- `tools/checks/test_shards.py` and its tests.

Don't edit `tools/sim/**` except to add a thin entry point the job calls. The measurement worker owns `tools/sim/**`. If you need a change there, say so in your report and keep it to the smallest one.

Work on a new branch `ideation/c-sim-job` from `ideation/main` and push it. Never push to or merge into `main`, and open no PR. Don't edit `docs/ideation/DECISIONS.md`.

## Part 0: the gate-shards follow-ups (first, small)
From the scope review (`docs/ideation/evidence/review-gate-shards.md`) and DECISIONS "Look-alike portraits and gate shards: review calls":
1. **`test_committed_times_cover_the_real_suite`:** a printed warning, not a failure.
2. **`cloud-gate.sh` on a failure:** print the failing jobs' check.sh lines, not `tail -n 40`. That means `FAIL`, `failed:`, `Failing Tests`, the test names under it, and the GUT totals. Prove it on a planted failing shard.
3. **The Godot cache restore steps on gate jobs:** drop them. Fix `CLOUD_SETUP.md` (cache wording; "fewer" against "not equal" for the script-count check; the "last 40 lines" promise).
4. **`test_times.json`:** refresh it from the newest passing gate's junit artifacts once the faster suite (`ideation/c-faster-suite`) has merged into ideation/main. If it hasn't merged when you finish part 1, refresh it from ideation/main as it stands and say so.

## Part 1: the sim job (A1b and A3.5 need it)
**Why:** sims and soaks move off the two local Godot slots (owner note 10a: "the cloud is an option always... tests can run on the cloud, and you can figure out smart ways of scheduling tests"). The repo is public and Actions is free for it.

**What:**
- A push of `ideation/sim/<id>` whose tree holds a run config at `sim/<id>.json` starts `.github/workflows/sim.yml`.
- The config names:
  - a run kind: line lobbies (the committed-line harness in `tools/sim/`, as `tools/sim/HARNESS.md` describes), field fights, or designed setups;
  - the preset, the seed list and the lobby count;
  - optional `rates.json` overrides, for A3.5's t-paths;
  - the shard count.
- The job shards the seeds across runners, runs the same Godot entry points the local runs use, merges the shard outputs, and commits **compact** results back to `ideation/sim/<id>`:
  - the summary JSON;
  - the per-lobby compact records the harness already writes (`*.lobbies.json.gz`);
  - a `README.md` with the commit, the config, the timing and any dropped trials.
  - Raw fight captures stay as workflow artifacts (7 days), never in git.
- A small `scripts/sim-run.sh <config.json>` pushes the branch, and `scripts/sim-run.sh --wait <id>` waits for the job and prints the summary's path, so the orchestrator and workers can use it like `cloud-gate.sh`.
- Use the existing harness's own outputs and readers. Don't write a second analysis path.

**Done when:**
- A 32-lobby B line run on today's ideation/main gives the same per-line R12 medians and growth as the same seeds run locally through the harness. Use any committed baseline with the same commit and seeds, or run a small local one through the slot wrapper. Equal means identical medians for identical seeds.
- Push to results takes under 20 minutes for 32 lobbies.
- Shards respect GitHub Free's 20-concurrent-job limit, since gate runs share it. Use at most 8 sim runners at once.

## Part 2: the soak rework (needed before A4, not before A3.5)
`soak.sh N --preset P [--library L]` plays N real `full_game` lobbies:
- The mix is about 60% on the default preset, 20% on the other preset, and 20% with a field seat. Field seats are skipped and counted when no library is given.
- Synthetic cards run only behind a flag, counted separately.
- Every lobby is checked by the existing rules checks.
- A new check fails the soak if any unit without a `set` appears in a `full_game` lobby.

It runs on the sim job (kind `soak`).

**Done when:** 200 games on today's tree show 0 violations and 0 crashes, run through the sim job.

## Checks and report
- Run `./scripts/check.sh` before each push that changes code, plus `ruff check`, `ruff format --check`, and gdlint on src, tools and `(cd tests && gdlint .)`.
- Keep files under the 1,000-line lint cap.
- Report in under 250 words: the branch tip after each part, the parity numbers for part 1, the timing, and anything you declined.
