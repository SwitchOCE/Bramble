# Status

Last updated 12 November 2026. The project is in pre-production. `main` holds the design docs, research, the toolchain and one placeholder Godot scene. The playable prototype builds are on the ideation branches; see [Elsewhere](#elsewhere-ideation-and-other-branches).

**Current phase on `main`: fundamentals.** Research, then the rulebook, then power budgeting. Content design waits until those exist.

## What exists

**Owner direction** (`docs/design/`)
- Owner notes from 27 October and 1 November 2026. Fourteen later notes, from 6 to 11 November, are only on `ideation/main` so far.
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

**Art style: decided 1 November 2026.** Ink + flat color, take B ("Bold and clean"), chosen from the style trials. See `docs/design/owner-notes/2026-11-01-art-style-decision.md`. A mood board of reference artists was tried and dropped: in a blind test it made no visible difference to the images. See `docs/design/owner-notes/2026-11-01c-mood-board-test.md`.

**Engine and language: decided 2 November 2026.** Godot with GDScript, statically typed as strictly as possible, chosen after the research in [archive/engine-language.md](archive/engine-language.md).

**Toolchain: built and proved in the cloud, 6 November 2026.** A minimal Godot project, the quality gate, export presets for Windows, Android (APK and AAB) and Linux, CI, and the cloud setup. See [CLOUD_SETUP.md](CLOUD_SETUP.md) and [the proof log](archive/cloud-toolchain-proof.md). The cloud environment is `Bramble Cloud`. Not proved:
- the Windows and Android builds have been built and inspected, never launched, and all are debug builds;
- no single AAB run combined the mirror, an empty Gradle cache and a fresh template;
- the gate has only run on 2 tests;
- updating an existing `screens` branch from a session, and the screenshot tool and its Action aren't built.

`main` has a ruleset since 6 November 2026: PR required, no force push, no deletion. It can't stop a session merging a PR. The owner approved the worker and orchestrator rules on 7 November 2026: [orchestration/WORKER.md](orchestration/WORKER.md) and [orchestration/ORCHESTRATOR.md](orchestration/ORCHESTRATOR.md). One worker has run the whole loop under them, on one small task; see [the proof log](archive/cloud-toolchain-proof.md), "Pilot". Cloud work on this track is paused until the owner chooses a piece from ideation to bring in. Not proved yet (from the pilot, 7 November 2026):
- an orchestrator running from the server;
- an orchestrator merging on its own under O1;
- the owner pressing Stop on a busy worker, or a worker obeying `Orchestrator: STOP`;
- a task that brings a chosen piece across from ideation;
- more than one small task, or a task that took several rounds of review.

**Archive:** [archive/](archive/README.md) holds finished docs kept as history.

## Foundations (v0, awaiting owner review)

- **Rulebook:** [design/rulebook.md](design/rulebook.md) and [design/rulebook-deltas.md](design/rulebook-deltas.md). 212 rules: 130 from Battlegrounds, 21 owner decisions, 55 proposed defaults, 6 open.
- **Power budget:** [design/power-budget.md](design/power-budget.md), with the evidence in `research/battlegrounds/power-analysis.md` and `analysis/`.
- **Research:**
  - `research/battlegrounds/`: rules (patch 36.6.3), patch history, keywords, card library (patch 37.0.0, pool history since 2019).
  - `research/galaxy/`: rules, patch history, all 698 cards, design notes.

## Elsewhere: ideation and other branches

Work that isn't on `main`. Nothing from these branches comes to `main` without the owner's say-so. Each plan's status block says where that work stands; the date is when the plan was last updated.

| Work | Branch | Plan | Plan updated |
|---|---|---|---|
| Ideation loop (UI, UX, look and feel): build 9 is waiting for the owner's playtest | `ideation/main` | `docs/ideation/PLAN.md` | 12 Nov 2026 |
| Prototype | `proto/main` | `docs/prototype/PLAN.md` | 4 Nov 2026 |
| Design lab | `design-lab/main`, `design-lab/journey` | `docs/design-lab/PLAN.md` | 4 Nov 2026 |
| Portal (the owner's site on the Optiplex) | `portal/main` | `docs/portal/PLAN.md` | 4 Nov 2026 |

Builds are in `/data/bramble-builds` on the Optiplex and on the portal's builds page.

## Next

The owner is re-evaluating the next steps (12 November 2026), which are "somewhat entangled" between `main` and the ideation branches. The steps planned before that:

- the owner works through the power-budget review points B1–B7 in [design/review-queue.md](design/review-queue.md), then the remaining proposed defaults;
- the answers are recorded as owner notes and the rulebook moves to v1;
- a headless rules simulation validates the power budget, in GDScript.

## Open decisions

- Everything in [design/review-queue.md](design/review-queue.md). Fixed slots on a 4–3 grid is the working board.
- Which woodland species make the cut; the tribe list (fairies and oozes are in).
- Whether to add a TFT-style trait system (the owner is leaning no).

## Pending in the folio

Character lineups for the faction seeds the owner stars, in the chosen ink + flat B style. On hold until the seeds are reviewed against the new direction.
