# Status

Last updated 27 October 2026. The project is in pre-production: no code yet.

**Current phase: fundamentals.** Research, then the rulebook, then power budgeting. Content design waits until those exist.

## What exists

**Owner direction** (`docs/design/`)
- Two owner notes from 27 October 2026.
- A plannable summary with open questions.
- An architecture recommendation.

**The Woodland Folio** (`docs/folio/woodland-folio.html`)
- Part I, ideas: zones, faction seeds, species takes, mechanic hooks and the art-style tests.
- Part II, research: Root, Everdell and Redwall.
- The faction seeds predate the Battlegrounds direction. They are idea material for tribes, not a roster.

## Foundations (v0, awaiting owner review)

- **Rulebook:** [design/rulebook.md](design/rulebook.md) and [design/rulebook-deltas.md](design/rulebook-deltas.md). 212 rules: 130 from Battlegrounds, 21 owner decisions, 55 proposed defaults, 6 open.
- **Power budget:** [design/power-budget.md](design/power-budget.md), with the evidence in `research/battlegrounds/power-analysis.md` and `analysis/`.
- **Research:**
  - `research/battlegrounds/`: rules (patch 36.6.3), patch history, keywords, card library (patch 37.0.0, pool history since 2019).
  - `research/galaxy/`: rules, patch history, all 698 cards, design notes.

## Next

1. The owner works through [design/review-queue.md](design/review-queue.md). Combat shape comes first: the attack-order question affects everything built on it.
2. Record the answers as owner notes and move the rulebook to v1.
3. Build a headless rules simulation to validate the power budget. Engine choice comes first, unless the sim is built as a throwaway prototype.

## Open decisions

- Everything in [design/review-queue.md](design/review-queue.md). Fixed slots on a 4–3 grid is the working board.
- Which woodland species make the cut; the tribe list (fairies and oozes are in).
- Whether to add a TFT-style trait system (the owner is leaning no).
- Engine and language.

## Pending in the folio

Character lineups for the faction seeds the owner stars. On hold until the seeds are reviewed against the new direction.
