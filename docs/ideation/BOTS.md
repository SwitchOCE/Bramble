# Plan: the best bots we can make

The owner, 8 Nov 2026 (`docs/design/owner-notes/2026-11-08a-bots-and-data.md`, `2026-11-08b-remove-easy-medium.md`):

> "I think if we make bots, we should make them the best players we possibly can."
> "if one strategy is consistently beating other strategies, we should have that bot get better"
> "I think that we should be designing around the best bots we can. Maybe have different flavors of them with different strategic quirks."
> "human players will find stuff the bots haven't because our bots are pretty immature."
> "Remove altogether. No easy, no medium bot."

Everything below this quote is the orchestrator's plan.

## Steps (after interrogation: `evidence/bots-plan-interrogation.md`)

1. **Remove Easy and Normal** everywhere players and docs see them, with their bench suites. Keep the old Hard record as the one record. Naive stays as a 300-game floor check in tools.
2. **Head-to-head.** 4 candidate against 4 current best in `bench_suites.gd`, seats shuffled by seed, paired seeds, with an A/A run that must read 0 within its margin. "Clearly better" means a positive gain whose 95% margin excludes 0, on fresh seeds, at no meaningful turn-time cost. There is no 0.15-place floor (orchestrator revision, 8 Nov). Any future post-result rule change requires fresh-seed confirmation before counting that result or promoting the candidate.
3. **Baseline** on one commit: spread, A/A, Hard turn time, bench cost, in cloud VMs. Profile why a turn went from 35 ms to 87 ms and cut what's waste. The phone aim remains 7 bots in about 1 s; it's an assumption until a device is timed.
4. **Rank the known gaps** from one code read and `bench-reading.md` (reactive saving, the Acorn Stash, Rings, the economy lines). Each round of hand play adds one question: what did you do that the bots don't?
5. **Fix the top 5**, one worker run each, each through step 2, with turn time and bench cost reported. Stop when the list is done or after two failed promotions in a row. Anything after that is a new plan.
6. **Re-measure the spread** with the promoted bot. Mark older conclusions that rest on Easy or Normal data as stale; re-argue only those a later step needs.

**Rule for imbalance:** when a strategy keeps winning, improve bots on both sides for one pass of the top 5. Then change cards only with hand play or stronger bots confirming it.

**Flavours:** a lobby already deals each seat a different one of the 21 strategies; those are the flavours for now, one strength throughout. New quirk axes wait until step 5 ends.

**Deferred:** fight simulations for buying and tiering, until the fall in placement search's value is explained and the cheap gaps are spent. Running bot turns during the player's recruit phase, unless the profile can't reach the phone aim.

## Done-means changes

- "Easy, Normal, Hard with a measured ladder" and "1 Hard among 7 Normal" are removed (owner's words). The bot bars become: 1 best bot among 7 Naive places top 4 at least 85% and wins at least 45%, and the current best beats the previous best in head-to-head play on fresh seeds.
- Expert bot is no longer deferred: this work is it, under one name.


## Branch implementation facts (8 Nov 2026)

The active steps above are main's newer interrogated plan. Strength removal is already implemented on this branch (7529183): one game opponent policy, no strength menu, Naive only in tools/tests. Its existing safe record migration aggregates the known legacy Easy/Normal/Hard sections and retains their source data. That implementation differs from the Hard-only legacy-record wording in step 1 above; this documentation merge records the distinction and does not rewrite saved data. The prior proposal and completion note remain in [the historical branch plan](evidence/bots-plan-before-main-merge.md). Later plan steps and their new baseline/promotion runs are not executed by this integration. Existing validation is in [bots-step1.md](evidence/bots-step1.md); current merge validation/head stamps are in build/sim/commit-followup-merge/.


## Promotion rule revision and current baseline (8 Nov 2026)

Orchestrator's call: drop the 0.15-place floor. It was meant to avoid chasing noise; the 95% margin already serves that purpose. This rule is an orchestrator choice in service of the owner's quoted best-player direction, not a new owner quote. Promote a positive fresh-seed gain whose 95% margin excludes zero and that has no meaningful turn-time cost.

**Independent confirmation accepted (orchestrator, review Ask 1):** the fresh reviewer measured **+0.048 ±0.042 places** on **500 paired seeds, 161001–161500** (1,000 games), with about 1% timing overhead. This confirms carrier after the post-result rule revision. Future post-result rule changes require fresh-seed confirmation **before counting or promotion**.

**Promoted:** `carrier_upgrade`, +0.0465 ±0.0415 places on 500 paired seeds / 1,000 games (131001–131500). Mean turn time 71.58 versus 70.94 ms; p95 154.22 versus 153.36 ms: accepted as no meaningful cost. The player-facing `hard` policy now includes exactly this carrier replacement behavior. Saving stays out: +0.0475 ±0.0860 includes zero. Its failed candidate, tests and registry entry are removed by the orchestrator’s review Ask 2 decision; the measured evidence remains historical. The carrier bench alias points directly at the promoted core brain. **Consecutive failures reset to 0**. The old two-failure stop recorded under the former floor is superseded by this promotion; two successive failures from the new baseline still stop the pass.

Ranked gap **#2, Acorn Stash**, was tested on promoted Hard with saving excluded: **+0.0110 ±0.0454** on 500 fresh paired seeds, so no promotion. This was a **pre-engines** trial. It is the first failed promotion since carrier; the consecutive-failure count is **1**. For that trial, a predeclared practical timing limit is at most 5% overhead in both mean and p95 versus Hard in the same release pack; this is a descriptive cost limit, not a timing significance test. Numerical success still awaits review before changing the player-facing policy.

The completed Acorn Stash trial used an immutable **pre-engines** runtime. The subsequent engines merge does not change those frozen packs; its results describe that older ruleset, not the merged engines baseline. Do not inspect partial results or tune from them.

**Orchestrator, review 2:** the pre-engines Stash trial counts as failure **1** toward the two-failure stop because it is evidence the idea is weak; its failed candidate and tests are deleted, while its result stays in evidence.
