# Review 2: `ideation/measure` (plan-triage-redesign step 2)

Fresh cloud review, 9 Nov 2026, of `origin/ideation/main...origin/ideation/measure` at `59d9629`. Scope: plan step 2 and the owner's "fix weak tribes in the cards, never in bot routing."

**Counts:** 1 cut, 2 ask, the rest fine. **Ready to merge: no**, until the one-line cut is reverted. The measurements are sound and honestly labelled. The plain arm reverses the Birds pick result: 1.3% with hints, 21.1% without. That is the step's most useful finding. It points at the card hints, not the cards.

- **cut:** Revert the deleted comment line in `src/core/combat/combat.gd`. It is a game file, and the deletion wasn't needed.
- **ask:** In the report, name the bespoke valuators the plain arm keeps: Barn Owl, Redwing, Charcoal Burner and `BotCommitment.future_bonus`.
- **ask:** The rerun predates the pass 1 fixes now on `ideation/main` (`c1864d2`). Rerun it before pass 2 uses it as the baseline, or label it as pre-fixes.

## What I ran

- `./scripts/check.sh` on the branch: all 11 steps pass, with 1,499/1,499 Godot tests and 50 Python tests. The parity step prints `WARN` and passes.
- `check_parity.gd`: exits 0 by default and 1 with `PARITY_STRICT=1` (`FAIL: off target: Bog folk, Fairies, Hedgerow folk, Hunters, Oozes`).
- Recomputed both after-pass-1 tables from `free_choice*.players.csv.gz`: 3,200 seats in 400 lobbies each. Seats, mean place, first rate and the `no_tribe` split (937/511 and 872/498) all match.
- `gdlint` on `ideation/main`'s 1,000-line `combat.gd` passes.
- A trial merge into the current `ideation/main` (`9e3d80f`) is clean.
- **Not run:** the 400-lobby arms, the 72,000-fight benchmark, the interval method, or the gate on the merged tree.

## (1) The earlier cuts and asks

| Earlier item | Now |
|---|---|
| cut: qualify the report | **fine.** The report names the limited boards by tribe, marks the Fairies and Hedgerow R12 claims, cites the four clean Birds boards and says pick reflects hints. |
| ask: hint-free arm | **fine**, with the disclosure ask below. `free_choice_plain` was added. |
| ask: label fixes | **fine.** Tokens are excluded from numerator and denominator. The CSV gains plurality, share, `lobby_tribes` and the no-majority reason, and the tables give 95% intervals plus a `no_tribe` breakdown file. *[The brief says tokens are "credited to their producer". The report and STEP2 instead say tokens are excluded. Both fix the Egg problem.]* |
| ask: strict when pass 2 merges | **fine (deferred).** There is a TODO in `check.sh`, and plan step 4 already says "The parity check now fails the gate." |
| ask: rerun after the Birds redesign | **fine for Birds pass 1.** The rerun is on `8895189`. It is now stale; see the second ask. |
| ask: STEP2 local-only | **fine (deferred).** STEP2 now says it isn't a cloud recipe. |

## (2) Does the plain arm bypass the hints without touching the default bots?

- **Bypass: fine within its stated limits.** `plain_eval.gd` overrides `BotEval._hint_number` for `buy` and `keep` only. Those are the sole hint reads behind `buy_value`, `keep_value` and `text_value`. The test injects new hint data and checks that the three values don't change. Without the override that test would fail.
- **Default bots: fine.** The swap happens only in `BenchSuites.create_bot` when the alias is `free_choice_plain`. `free_choice.gd` is selected only by the two new suite names. Under `src/`, the only change is the comment line. The game's `Bot.create` path is untouched, and other suites gain only new CSV columns.
- **ask (disclosure):** the arm still uses hand-written per-card code in `BotEval`: `BotContent5.owl_value` and `redwing_value` (two Birds cards), `BotBurner` (Charcoal Burner), and `BotCommitment.future_bonus`. "Live mechanic evaluation retained" covers these only vaguely. They matter because the arm's headline is about Birds. Other text is a flat 1.5 × tier. So the arm also undervalues text-heavy cards, as STEP2 admits ("not a policy-independent strength estimate").

## (3) Are the evidence tables honest?

**Fine.**
- Every row gives its seat count. Rare rows get wide intervals: Birds in the hinted arm, 41 seats, first 9.8% [0.5, 19.0].
- Lobby pick is conditioned on the tribe being offered.
- Outcomes are conditioned on the label, and the report says so.
- The report doesn't hide the gaps:
  - `no_tribe` is still 43–45% of seats.
  - The 72 benchmark snapshots are the old boards, and the report says they "do not represent newly designed optimal Birds boards."
  - The post-pass-1 benchmark has no summary table and makes no claims; the reader has to open the CSV.
  - The first section's tables are labelled pre-redesign.

The intervals are exploratory. The report says so.

## (4) Gate and parity

**Fine.** The gate is green. The parity check reads `UnitLibrary.pool_units(full_game().card_set())` and only warns unless `PARITY_STRICT=1`. Its unit tests cover counting and the exit status.

## (5) Scope

- **cut:** `59d9629` deletes `## Mechanics act through the public methods below; their changes are logged.` from `src/core/combat/combat.gd`, taking it from 1,000 to 999 lines. The report gives "999 lines" as if it mattered. But the lint limit is `max-file-lines: 1000`, and the 1,000-line file passes on `ideation/main`. The change touches game code for no reason. Restore the line.
- **Everything else is fine:** the suites, labels, parity step, benchmark harness, evidence and tests are all step 2. Nothing touches bot routing or content. The arms exist to measure the cards, in line with the owner's words.
