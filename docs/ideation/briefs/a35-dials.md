# Brief: A3.5's dials for run 1 (plan to Done, row A3.5)

Written by the orchestrator on 10 Nov 2026 for a cloud routine.

**Read first:**
- `docs/ideation/plan-to-done.md`: §2 row A3.5 and "A3.5 in detail".
- `docs/ideation/content/pass3/a35-dial-check.md`: the synthesis. Its tables and its "Checklist before run 1" are the spec.
- DECISIONS.md, entry "A3.5 step 0: dials for run 1". It is the calls, and it wins where it differs from the synthesis.
- Each tribe's critic in `docs/ideation/evidence/a35-step0/critic-<tribe>.md`. A critic's correction wins over its draft.

**Goal:** after this branch, A3.5 run 1 can set every moving dial from one rates override at any t from 0 to 3. Every card face then prints a true, readable number, and the bots value each dial as it is set.

## You own
- `content/pass3/rates.json`;
- the pass 3 text printers (`src/core/pass3_text.gd` and the tribes' `*_text.gd`);
- the Birds, Fairies, Bog, Hunters and Oozes pass 3 rule files, and their bot files, for the dials below;
- `content/schema/effects.json` (the glossary lines);
- their tests.

**Don't touch:**
- Hedgerow's files. Wave 2b owns them, and its route fixes are in progress.
- `tools/sim/**`, which belongs to the measurement worker.
- `src/ui/**`.
- `DECISIONS.md`.

## What to build
1. **The checklist in `a35-dial-check.md`**, item by item:
   - Snap a decimal to a printable value toward generous (09h). Integers round up.
   - Clamp each dial at its limit.
   - Golden twins keep their stated relation.
   - Bots read the dial wherever they now use a fixed number.
2. **Five new dials,** each with rules code, card text, golden text, a bot value and a known-answer test at t = 0 and at its cap:
   - Bog: `bog_tiddy_share` and its golden twin (B ½, C ¾, limit 1; golden B 1, C 1.5, limit 2). Give 1.5 a wording.
   - Hunters: `hunters_ermeline_pelts` and golden (B 1, C 2; whole number; golden double, capped at 10).
   - Hunters: `hunters_glutton_share` and `hunters_lodger_share` may pass 1. Golden copies need a "three times" wording.
   - Oozes: `oozes_hasty_share` (B 1/3, C 1/2, limit 1). `bot_ooze.gd:148` reads it.
   - Oozes: `oozes_aspic_bonus` (B 0.75, C 1). Golden is 1 + 2 × bonus.
   - Oozes, a new rule: `oozes_eat_printed_multiplier` (B 2, C 3; whole number; at least 1). When an Ooze eats a non-Ooze, the eater gains that unit's printed stats × the multiplier. Ooze meals are unchanged. The reminder reads "…, with a non-Ooze's printed stats × N" (`effects.json:939`).
3. **Preset B writes `birds_chiffchaff_gain: 1`** explicitly. Fix the glossary line `effects.json:916` ("double stats").
4. **A path helper** that the sim job's `rates.json` override can use. Given t, it prints the override for every moving dial on the path d(t) = B × (C/B)^t, with snapping, clamps and golden relations applied.
   - Put it in `tools/checks/` or `src/core/`, not `tools/sim/`.
   - Add a test that checks each card face at t = 0, 1, 2 and 3 against its rule's numbers: text equals behaviour.

## Done when
- At t = 0, 1, 2 and 3, every dial on a path prints a true face, and its known-answer test passes. "Golden stays above normal" holds everywhere.
- B's and C's own presets are unchanged except for the new dials and the Chiffchaff key.
- `./scripts/check.sh` passes. Push the branch and run `scripts/cloud-gate.sh <sha> a35-dials`; it must pass.
- You have merged `origin/ideation/main` before your last gate. Keep DECISIONS.md exactly as main has it.

## Rules
- Work on a new branch, `ideation/c-a35-dials`, from `origin/ideation/main`.
- Never push to or merge into `main`, and open no PR.
- Keep files under the 1,000-line lint cap, and run `ruff check`, `ruff format --check`, and gdlint on src, tools and `(cd tests && gdlint .)`.
- **Report in under 300 words:**
  - the branch tip;
  - each new dial's text at t = 0 and at its cap, normal and golden;
  - anything you declined or couldn't make true, and why.
