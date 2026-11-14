# Status

Last updated 2 November 2026. The project is in pre-production: no code yet.

**Current phase: fundamentals.** Research, then the rulebook, then power budgeting. Content design waits until those exist.

## What exists

**Owner direction** (`docs/design/`)
- Owner notes: the owner's instructions that still hold.
- A plannable summary with open questions.
- An architecture recommendation.

**The Woodland Folio** (`docs/folio/woodland-folio.html`)

Part I, ideas:
- tone compass
- 16 world zones on a map
- 36 faction seeds
- 24 species with 3–4 takes each
- theme-to-mechanic hooks
- idea shuffler
- 13 art styles tested and scored for artist difficulty, animation cost and readability
- style trials: three finalist styles, three takes each, on six subjects

Part II, research:
- Root, Everdell and Redwall
- a 60-species field guide with photos
- auto-battler lessons and the wider shelf of influences
- a mood board

The folio's faction seeds predate the Battlegrounds direction. They are idea material for tribes, not a roster.

**Art direction: decided 15 November 2026.** "Flat figure": a flat, hard-edged, full-colour fighter shown full body against a soft layered background of its tribe's biome. The owner: "Okay, that's our new art direction." See [design/art-direction/README.md](design/art-direction/README.md) and `docs/design/owner-notes/2026-11-15a-art-direction.md`. It replaces the 1 November choice (ink + flat colour, take B; `docs/design/sources/2026-11-01-art-style-decision.md`). Which tribe gets which biome is not decided. Earlier, a mood board of reference artists was tried and dropped: in a blind test it made no visible difference to the images. See `2026-11-01c-mood-board-test.md` (removed 13 Nov 2026, in git history).

## Foundations (v0, awaiting owner review)

- **Rulebook:** [design/rulebook.md](design/rulebook.md) and [design/rulebook-deltas.md](design/rulebook-deltas.md). 212 rules: 130 from Battlegrounds, 21 owner decisions, 55 proposed defaults, 6 open.
- **Power budget:** [design/power-budget.md](design/power-budget.md), with the evidence in `research/battlegrounds/power-analysis.md` and `analysis/`.
- **Research:**
  - `research/battlegrounds/`: rules (patch 36.6.3), patch history, keywords, card library (patch 37.0.0, pool history since 2019).
  - `research/galaxy/`: rules, patch history, all 698 cards, design notes.
  - `research/economy/`: the 12 Nov economy and tier-price research, with re-runnable sims in `tools/research/economy/`.

## Next

1. The owner works through the rest of [design/review-queue.md](design/review-queue.md). Combat shape, economy and the power-budget basics are answered; next are the power-budget review points B1–B7, then the remaining proposed defaults.
2. Record the answers in the rulebook, quoting the owner's words, and move it to v1.
3. Build a headless rules simulation to validate the power budget. Engine choice comes first, unless the sim is built as a throwaway prototype.

## Open decisions

- Everything in [design/review-queue.md](design/review-queue.md). Fixed slots on a 4–3 grid is the working board.
- Which woodland species make the cut; the tribe list (fairies and oozes are in).
- Whether to add a TFT-style trait system (the owner is leaning no).
- Engine and language.

## Pending in the folio

Character lineups for the faction seeds the owner stars, in the flat-figure art direction (`design/art-direction/README.md`). On hold until the seeds are reviewed against the new direction.
