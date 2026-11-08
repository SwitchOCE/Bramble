# Review: `ideation/measure` (plan-triage-redesign step 2)

Fresh cloud scope review, 8 Nov 2026, of `git diff origin/ideation/main...origin/ideation/measure` (commits `4965d3e`, `a05f105`). The branch predates the Birds redesign now on `ideation/main`.

**Counts:** 0 cut on code, 1 cut on the report text, 5 ask, the rest fine. **Verdict: partly.** The parity check and the benchmark harness are sound. The free-choice numbers measure the Hard policy's hand-written card hints as much as the cards. Several benchmark claims rest on boards whose own mechanics didn't load.

## What I ran

- `check_parity.gd` on the branch: reproduces the report's table exactly (98 units). Warn mode exits 0; `PARITY_STRICT=1` exits 1.
- The full GUT suite on the branch: 1,472/1,472 pass.
- Recomputed every benchmark cell, the fight count (72,000) and draws (8 board-sides, so 4 fights) from `benchmark.boards.csv` and `benchmark.fights.csv.gz`: all match the report. Birds is last in 10 of 12 cells: correct.
- Cross-tabbed `benchmark.limitations.json` by tribe, and the bot card hints in `content/bots/cards.json` by tribe.
- Not run: the 400-lobby free-choice run or the 72,000-fight benchmark (hours of compute). I didn't re-derive the boards from the audit prose by hand.

## (1) Free-choice bots

- **Free of named steering: fine.** `free_choice.gd` overrides `_choose_build` to clear `pinned_strategy` and `value.strategy`. This removes strategy tribes and units, curve, saves, rows, `power` and heroes in one step. `_profile_strategy_fit` is never called. I found no other tribe-keyed code in `src/core/bots/` outside strategies.
- **"Buys by board value": partly.** Purchases use `BotEval`. It reads the per-card `buy`/`keep` hints in `content/bots/cards.json`, and every pool card has one. The hints are hand-authored. Measured as mean `buy`/`keep` minus 3×tier, they are lowest for Oozes (−4.4) and Birds (−4.3) and highest for Hunters (−1.4) and Bog folk (−1.8). Pick rates follow the hints, not the results: Hunters 26% pick with a 4.73 mean place, Fairies 3% with 3.51, Hedgerow 4% with 3.85. The report says hints are retained, but its pick column reads as tribe appeal. **ask**: either label it a policy measurement, or add a hint-free arm that values cards by `text_value` only.
- **The strict-majority label: ask.** It's reproducible and independent of declared build, but:
  - Eggs count as untribed occupied slots, so an Egg-heavy Birds board can't win a majority. Birds' 1 seat (0.03%) partly reflects the rule. This is moot for the redesigned Birds, but it will bite any token-making tribe.
  - The 41% `no_tribe` group is unexplained, and it places like the field (4.49).
  - The CSV has no lobby-tribes column, so pick rate conditional on the tribe being offered can't be computed.
  - There are no intervals. Fairies' 21.4% first rate on 103 seats is about ±8 pp.
  - Suggestion: add plurality tribe and share, a lobby-tribes column and 95% intervals.

## (2) Parity check

**Fine.** It counts `UnitLibrary.pool_units(GameConfig.full_game().card_set())`, the same source `UnitPool.create` uses for the full game, before rotation and the skeleton filter. The skeleton filter doesn't apply to `full_game`. There are no dual-tribe units, and 16+14+14+11+14+16+13 = 98.

**ask:** "fail once pass 2 lands" is only an environment flag. Nothing turns it on. Pass 2's merge should make strict the default in `check.sh`, or the warning stays forever.

## (3) Benchmark fidelity and the 27 limited boards

- **Harness: fine.** It covers 180 cross-tribe same-cell pairs, both orientations and 200 seeds. Supplied stat totals are kept, and auras are stripped then rebuilt by the real combat engine. Tests cover all 72 starting boards and aura removal.
- **The limited boards are not spread evenly.** They are all 12 Fairies boards (missing Ring layouts and amounts, paint identities), 8 of 12 Birds boards (Nest triggers that can't load, away Birds at printed bodies), 4 Bog folk (prior kisses) and 3 Hedgerow (Acorn values, no Conkers ammunition). Hunters and Oozes have none.
  - The missing state is mostly in-fight triggers: Nests, Conkers, Rings rebuilt from slots. So the affected tribes are probably understated in their own mechanics, not just noisy.
  - The four clean Birds boards are R3 high, R3 low, R9 low and R12 low. They still rank 6, 1, 6 and 6, so "Birds weakest" survives on clean data.
  - "Fairies fall to fourth at R12" uses only limited boards. So does the "Hedgerow R12 low" claim. "Oozes 91% at R12" has no limitations, but it's one hand-built snapshot.

## (4) The report's claims

The numbers are faithful to the raw data. The interpretation sentences are not qualified enough. **cut:** `baseline-step2.md` must name which tribes the 27 limited boards belong to, and must mark the Fairies R12 and Hedgerow R12 claims as resting on limited boards. The Birds claim should cite the four clean boards. One more line should say the free-choice pick column reflects card hints (see the hints item in (1)).

## (5) Scope

**Fine.** Nothing under `src/` or `content/` changed, and no rules or content changed. These additions fall within plan step 2:
- the `parity` step in `check.sh`;
- a `final_tribe` column appended to every suite's player CSV (backward-compatible for `DictReader`);
- a `free_choice` suite and its summary section.

**ask:** `STEP2.md` hard-codes the owner's machine (`/opt/bramble/env.sh`, systemd scopes, `/home/alex/...` in the log). That's acceptable for local reproduction, but it isn't cloud-reproducible.

**ask:** the baseline predates the Birds redesign. Before step 3 uses it, rerun the parity check on `ideation/main`, and the free-choice and benchmark runs if the boards change.

## Items

- **cut:** Qualify the report. Name the limited boards by tribe (all 12 Fairies, 8/12 Birds, 4 Bog folk, 3 Hedgerow), mark the Fairies and Hedgerow R12 claims as resting on limited boards, and note that pick rates reflect card hints.
- **ask:** Add a hint-free free-choice arm (or relabel the pick column as a policy measurement).
- **ask:** Label: count Eggs/tokens by producer or exclude them; add plurality share, a lobby-tribes column and 95% intervals; break down `no_tribe`.
- **ask:** Make `PARITY_STRICT` the default when pass 2 merges.
- **ask:** Rerun parity, and the free-choice and benchmark runs if needed, on post-Birds-redesign `ideation/main` before step 3.
- **ask:** Note that `STEP2.md`'s commands are local-machine only.
