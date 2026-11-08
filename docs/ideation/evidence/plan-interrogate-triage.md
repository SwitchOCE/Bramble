# Plan interrogation: triage redesign (8 Nov 2026)

Target `docs/ideation/plan-triage-redesign.md` at 8a38410. Method: `.claude/skills/plan-interrogate/SKILL.md`, step 1 skipped (brief given). Read: the plan, the audit, the case study, `damage-v05.md`, pt5 a–e, the 6 Nov review. Checked in code: bots have `pinned_strategy` and build priors (`src/core/bots/bot_brain.gd:28`), but no equal-prior free-choice mode; `scripts/check.sh` has no parity check. Nothing was run.

## Verdicts

| Step or item | Moves the problem? | Proposed by | Verdict | Why |
|---|---|---|---|---|
| 1 Damage D as default | Yes: tally 2 (n=14), all five pt5 reports | Agent (v0.5 prereg) | keep | Built, gated, 4 of 5 targets |
| 1 New 200-lobby re-run for bursts | Tally 19 (n=3) | Agent | shrink | `damage-v05/` holds per-round eliminations for 200 lobbies of D and baseline; count same-round knockouts from it first |
| 1 Burst guard "lowest out first" | Tally 19 | Agent | defer | It changes who goes out, not how many; add only if the count shows bursts persist |
| 1 Game length +4 rounds (T2 missed) | No step owns it | — | ask | Median game goes 17→21. The owner playtests that length; tally 7 (last four drag, n=6) may worsen |
| 2 Benchmark boards | Says which tribe stage is behind | Owner | keep | Owner's idea, "a guesstimate gives you at least something to triage against" |
| 2 Every sub-variety × 4 rounds × 3 rolls | Same | Agent | shrink | ~150+ boards. One main line per tribe first (72 boards); add sub-varieties for tribes that pass |
| 3 Birds, Chaser/Ring cap, gold-only | Owner's Birds problem; tally 3–6, 12 | Owner + audit | keep | Highest tally rows and the owner's case |
| 3 Hunters, Hedgerow, Oozes, Bog, Fairies T3 | Tally 8, 16; audit §3 breaks | Agent (audit) | shrink | Move to a second pass after the first slice plays (below) |
| 3 Heroes Hob, Bracken, Mousewife | Tally 13, 18 | Audit | keep | 4 and 3 reports |
| 3 Parity 20 at 4/4/4/3/3/2 | Owner's "even number… even tier distribution" | Owner (shape agent) | keep | Stage it: Birds to 20 in pass 1, the rest in pass 2 |
| 3 "Briefed without the power budget" | Unclear | Agent | ask | CLAUDE.md says content is costed against the budget; say why designers don't see it |
| 4 One Sol branch for everything | Proves step 3 | Agent | shrink | One branch per pass, so a bad tribe can't hide in a 30-card change |
| 4 Per-tribe bars on free-choice bots | Process C | Case study | keep | But no free-choice mode exists: add it as a step (below) |
| 5 Build 8, five players, Birds lens | Playtest bar | Agent | keep | Add a damage/length lens |
| Not in plan: bot adaptation (n=3) | Tally | Agent | ask | Rule E makes 3+ a must-fix; deferring it needs a logged call |

## Missing steps the evidence demands

1. **Free-choice bots.** Step 4's bars need bots on equal priors that buy what the shop offers. Today bots are pinned or steered by priors: the case study's blind spot (§2.3–4).
2. **The parity check in `check.sh`** (process D).
3. **Tally 1, clarity (n=14, the largest row).** Handed to feedback5/w20, but the plan never says it must merge before build 8. Make it a gate on step 5.
4. **Must-fix rows with no owner:** 9 scripted early rounds (6), 10 Shy (5), 11 Charcoal Burner (5), 14 thin supply (4), 15 difficulty ladder (4), 17 Hedge Witch Hex 8 (4), and Wee Wobbly/Posset in 18. Rule E says 3+ is must-fix. Each needs a step or a logged deferral.
5. **A buy-moment check on new cards.** No step plays the turn-1 shop; a fresh agent playing Birds rounds 1–6 tests the owner's question directly.

## Order and branches

Steps 1 and 2 are independent (benchmarks ignore damage), but feedback5 is already one open code branch, so they can't both open beside it. Merge damage first.

## Does step 3 design too much before play?

Yes, the 6 Nov finding again: ~30 cards and three heroes across every tribe before anything plays. Split it:

- **Pass 1:** Birds (to 20 cards, early reason to own Nests), Chaser and the Ring cap, gold-only units, the three heroes. Build, bench, one fresh agent Birds playtest.
- **Pass 2:** other tribes' breaks and parity.

## Fixed after step

- **Today:** step 5, the last; first measured at step 4.
- **Reordered:** pass 1's build (step 3 below), checked by benchmark rows, Birds' free-choice bar and an agent playtest. The owner confirms at build 8.

## Smallest plan

1. Merge damage D; count bursts from existing data.
2. Free-choice bots, benchmark boards (main lines), parity check.
3. Pass 1 design, build, bench, agent Birds playtest.
4. Pass 2 design and build.
5. Feedback5 merged; build 8; playtest round 6.

## Checkpoints

After 2 (table agrees with audit and playtests), after pass 1 (Birds bar and agent verdict), after 5.

## Open questions

- Is a 21-round median game acceptable?
- Why brief designers without the power budget?
- Defer bot adaptation and rows 9–11, 15, 17, or fix them?
