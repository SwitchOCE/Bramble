# Status

Last updated 16 November 2026.

## Where we are

Pre-production. The look is decided, lead and stained glass, and is being dialled in. Tribes are being shaped from the species seeds. The rules and economy are drafted to v0.7. There is no game code on `main`: one placeholder Godot scene and the toolchain.

## Live now

| Work | Where | Plan or notes |
|---|---|---|
| Dialling in the glass look: card art from the recipe, screen mock-ups | `main`, and the branch `design/glass-mockups` for the mock-ups | [workstreams/glass-dial-in.md](workstreams/glass-dial-in.md) |
| Species seeds and tribe shells | Outside Git: the species seeds page, https://claude.ai/artifact/L7QD6ka8LzD22mnGsgA4SY, and its work folder on the owner's PC. A 16 Nov snapshot is in Cloudflare R2 ([tools/assets/README.md](../tools/assets/README.md)) | Design work uses the `bramble-design` skill |
| Rules and economy | `main` | [workstreams/rules-and-budget.md](workstreams/rules-and-budget.md); waiting on the owner |

## Decided

- **Art direction: lead and stained glass,** cards and the whole UI (owner, 15 Nov 2026: "That is the direction we're going with" and "this is authoritative"). See [design/art-direction/README.md](design/art-direction/README.md), which also lists what is still open, and the owner note [2026-11-15b](design/owner-notes/2026-11-15b-stained-glass-direction.md). The six card frames are done ([workstreams/glass-frames.md](workstreams/glass-frames.md)) and the card art recipe is approved ([design/art-direction/card-art-recipe.md](design/art-direction/card-art-recipe.md)).
- **Engine: Godot with GDScript,** typed as strictly as possible (2 Nov 2026; research in [archive/engine-language.md](archive/engine-language.md)).
- **Rules: [rulebook](design/rulebook.md) v0.7** (12 Nov 2026), with the owner's economy. 100 rules from Battlegrounds, 43 owner decisions, 47 proposed defaults, 11 open, 26 examples; [rulebook-deltas.md](design/rulebook-deltas.md) lists every difference.
- **Costing: the [tier guide](design/tier-guide.md)** (12 Nov 2026): one job per tier and rough targets as ratios, in place of strict per-card budgets. The earlier power budget and its review points B1–B7 are archived ([archive/power-budget/](archive/power-budget/ARCHIVED.md), 16 Nov 2026).
- **Board:** fixed slots on a 4–3 grid is the working board.
- **Toolchain: built and proved in the cloud** (6 Nov 2026): the Godot project, the quality gate, exports for Windows, Android and Linux, and CI. See [CLOUD_SETUP.md](CLOUD_SETUP.md). What was not proved is in [the proof log](archive/cloud-toolchain-proof.md).
- **`main` is protected** (6 Nov 2026): PR required, no force push, no deletion. Outside `docs/archive/`, nothing comes to `main` without the owner's say-so; the rule is in `CLAUDE.md`.
- **Cloud workers:** the owner approved the worker and orchestrator rules on 7 Nov 2026 ([orchestration/](orchestration/WORKER.md)). One worker has run the loop once. The track is paused.

Drafts that are not decided: [archetypes](design/archetypes.md), [owner taste](design/owner-taste.md), [effect taxonomy](design/effect-taxonomy.md), [economy bounding](design/economy-bounding.md) and [positioning sim](design/positioning-sim.md). Research on Battlegrounds, Once Upon a Galaxy and the economy is in `research/`. The Woodland Folio (`folio/woodland-folio.html`) holds early ideas and research with art; its faction seeds predate the Battlegrounds direction and are idea material, not a roster.

## Next

The order, confirmed by the owner on 16 November 2026:

1. **Progress the tribe shells with mechanic ideas.** "I'd be happy to have those shells progressed a bit more. Not to fully fleshed out yet, but like progressed a bit more with mechanic ideas and stuff."
2. **Finish dialling in the glass look:** the card art recipe and the mock-ups. The frames are done.
3. **The shop-odds talk** the owner asked for once the economy was set (rulebook 6.1.7 and 5.1.4).
4. **Later:** the remaining rule defaults, rulebook v1, then game code.

**A new ideation build track will start soon.** The owner, 16 Nov 2026: "I'd like to resume ideation builds at some point. Like the current ideation build will clear, but we'll start a new ideation track soon. ... now they've got more rigor in place, I want to see what we can do." It has no plan yet. The first run's rules engine, test gate, sim jobs and tools may be worth reusing; none of that is decided.

## Waiting on the owner

- Everything in [design/review-queue.md](design/review-queue.md): the hand, hand size, the pillars page, and the remaining proposed defaults.
- The glass look: what the "few more things" in the UI are, which spacing to lock, and the open list in the art direction README.
- Which woodland species make the cut, and the tribe list (fairies and oozes are in).
- Whether to add a TFT-style trait system (the owner is leaning no).

## Retired work

Finished and outdated docs are in [archive/](archive/README.md). Old branches are kept as tags, not branches:

- **Ideation, the first run** (6 to 14 Nov 2026), retired 16 Nov 2026. The owner: "ideation served its purpose. It showed me that I couldn't be that hands-off with agents and get what I wanted." Tags `archive/branches/ideation/main` and `archive/branches/ideation/tribe-run`. The owner's words that were only there are in `design/sources/`.
- **Prototype:** tag `archive/proto-2026-11-13`.
- **Design lab:** tag `archive/design-lab-2026-11-12`, and [archive/design-lab/](archive/design-lab/ARCHIVED.md).
- **Portal:** tags `archive/portal-2026-11-16` and `archive/branches/portal/pilot-review-page`, and [archive/portal/](archive/portal/ARCHIVED.md).

Builds from those runs are in `/data/bramble-builds` on the Optiplex.
