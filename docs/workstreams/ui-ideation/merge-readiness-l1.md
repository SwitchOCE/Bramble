# What a merge of the L1 buy screen takes

Written by the orchestrator of `ideation/ui-ux` on 25 Nov 2026, from a read-only survey of the working branch `ui/l1` at `0f967435` by a fresh agent, and git checks. The owner asked for this (L49). Nothing here is done yet unless it says so.

## Coordination

The fight animation rework (`ideation/fight-animation`, 101 commits ahead of `dev` on 25 Nov) will also merge into `dev`. The owner asked for a session across both (L50): "Merge coordinator: UI and fight animation", on branch `coord/ui-anim-merge`. It holds the plan for the order of the two merges and runs the checks on the two combined. A trial merge of `ui/l1` with the animation branch shows no textual conflict; the only file both change is `tests/screens/test_fight_screen.gd`. Nobody had run the checks on the combination when this was written.

### What the coordinator found and what this rework owes it (25 Nov)

- `dev` + `ui/l1` + the fight branch merges as text but did not compile: the fight branch's gain discs were built on the old card. With the coordinator's four-file port (`coord/port-gain-discs`, `9c6a7ff1`) the combination passes all of `check.sh` (1,139 tests).
- The coordinator's pick, put to the owner: the UI rework goes into `dev` first; the fight session then takes `ui/l1` plus the port. The port stays with the fight session.
- Owed by this rework: halos dim with the card's `modulate`; `GlassCard.stat_disc(stat)` and `_draw_stat(value, disc, red, pop, green)` stay as they are; `GlassPieces.disc` and `frame` and the six frame pictures stay until the coordinator says the fight branch has the port (so merge prep must not remove them before that); warn the coordinator before touching `fight_screen.gd`; tell it when light joins `ui/l1` (with how the halos are parented) and before opening the `dev` pull request, so it can rerun the combination.
- The coordinator's plan: `docs/workstreams/merge-ui-anim/PLAN.md` on `coord/ui-anim-merge`.

## Where the branch stands

- `ui/l1` is 14 commits ahead of `dev` and none behind. It merges into `dev` with no conflicts today (checked with `git merge-tree`).
- `dev` is 134 commits ahead of `main`. A merge to `main` is a merge of all of `dev`, and the owner does it.
- Built: the buy screen's room, shop, columns and the new card. The new card shows on every screen that draws a card, because they all go through `GlassCard`.
- Not built: light (running as step 6), the auras and heap panels (designed, approved L48), about 30 states that keep the old look as stand-ins (spec section 11), the fight screen's room.

## Card art

The existing unit art carries over unchanged. All 108 pictures in `assets/units/` are 560 x 1000; the new card crops them slightly (source x 28 to 532, y 52 to 952) and its Attack and Health discs sit within a few pixels of the old tier-1 places. Nothing was found that needs remaking because of the border.

What changes is the process around the art:

| Thing | What is wrong now | Change |
|---|---|---|
| `docs/design/art-direction/card-art-recipe.md` | describes art made to a tier frame's window, with per-tier margins and disc places | rewrite the "pieces", margins and safe-area text for the one lead frame and its crop |
| `tools/art/glass-art/assemble.py` | lays a tier frame over preview cards | draw the L1 card instead, or drop the overlay |
| `tools/art/` frame tools (`frame_cut.py`, `frame_measure.py`, `frame_blank_roundels.py`) | exist only for the tier frames | retire |
| `.claude/skills/bramble-art/SKILL.md` | "The six tier frames are finished" | say the card is a code-drawn lead frame |
| `docs/workstreams/glass-frames.md`, `docs/design/art-direction/frame-lab/` (14 MB) | the tier frame work | mark superseded; archive |

Separate from the border: the owner's L6 (calmer backgrounds, a colour guide per tribe) would mean remaking art. It is not started and changes the approved recipe.

## Old-look leftovers the branch still ships

- `assets/glass/frames/` (six tier frame pictures, 460 KB): drawn by nothing now.
- `assets/glass/card_data.json`'s per-tier disc data, and `GlassPieces.frame`, `disc`, `art_polygon`: no callers.
- `tools/glass/pull_mockups.py` still writes those from the old mock-ups branch, and `tests/glass/test_glass_pieces.gd` hash-checks them, so removing them means changing the pull, `source.json` and that test.
- Two unreferenced emblem pictures in `assets/glass/ui/`.

## Two layout sources

The buy screen and the card read the new hand-kept `assets/glass/l1/layout.json`. The fight screen, the library, Compost and the other screens still read the generated `assets/glass/layout.json`, pulled from the old mock-ups branch (`design/glass-mockups`). Until the fight screen is redone, both live side by side.

Every entry in the new layout file cites `buy-screen-l1.md`, which exists only on `ideation/ui-ux`. The spec, and the decisions it rests on, have to travel with the merge.

## Mixed look

- The fight screen keeps its old room with the new card; its slot outline differs slightly from the card's (17% shoulders against 16.2%).
- The stand-in states (frost, slots, sell area, keyword marks, Discover, pause) are in the old style on the new room.

## Documents that would be out of date

`docs/STATUS.md` (says the look is being dialled in on the mock-ups branch and "the frames are done"); `CLAUDE.md` Layout (`assets/glass/` described as the mock-ups' frames; `assets/glass/l1/` missing); `docs/design/art-direction/README.md` (lists "card frame details" and "how tier is marked" as not decided; example pictures show old cards); `.claude/skills/design-critique/SKILL.md` (card outline); `docs/CLOUD_SETUP.md` (the pull row; the stage's source); `docs/AGENT-BLIND-SPOTS.md` section 7 (the mock-up match number); `docs/ideation-track-2/HANDOVER.md` and its mock-up pages (still load tier frames); `tools/glass/compare.py` and its compare scenes (the buy screen no longer matches the old page).

## Gaps a merge would carry

- Tier in the shop is told by colour and strength alone, and off the shop only by hover words. Both project design skills say colour should not be the only cue. Not designed.
- No test checks that the room draws, beyond the layout file's own test.

## A merge-prep step

One worker task, after light and the panels: remove the leftovers; stop the pull writing frames; bring the spec and the decision rows into the branch; update the documents above; archive the frame work. Then the PR into `dev`.
