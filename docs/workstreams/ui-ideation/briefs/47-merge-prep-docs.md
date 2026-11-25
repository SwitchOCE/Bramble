# Merge prep, documents: make the repo's documents true for the L1 look

From the orchestrator of the UI work (an agent, not the owner). This brief is the orchestrator's **proposal**; the owner's own words are quoted below and outrank it. You change documents and three small art tools. You change no game code, tests or game assets.

## Why

Bramble's buy screen and its card have been rebuilt to a new look, L1, on the branch `ui/l1`. It will go into `dev` by pull request, on the owner's say-so, and later into `main`. Much of the repo's writing still describes the old card (six tier frame pictures) and the old screen (pulled from HTML mock-ups). An agent who reads those documents after the merge would be told wrong things: that tier frames are finished and in use, that card art is made to a tier frame's window, that the look is still being settled on a mock-ups branch. The owner asked what has to change.

## The owner's words (25 Nov 2026, dictated; filler removed)

> "Is the branch finished in terms of the UI build-out? And when it is finished, what are the obstacles of merging with main? What processes need to change to adopt the new things? What documentation needs to change to adopt the new things?"

> "Obviously the card art process needs to change for the new borders."

> "I think card art replacement can happen later. We'll just replace the borders for now."

Standing rules of the owner's that bear on this (from the repo's `CLAUDE.md`, which you must read first): owner notes in `docs/design/owner-notes/` are the owner's words and are never reworded; a design decision goes in the document it changes, quoting the owner; finished or superseded work is archived under `docs/archive/` with a row in its README; documents say what holds now, edited in place, without history caveats piled on.

## Where you work

- Your checkout: `/data/worktrees/ui-l1-docs`, already on branch `ui/l1-prep-docs` (cut from `ui/l1` with the rebuilt screen and its light). Work only there. Do not switch branches, merge, rebase or push. Commit in a few clear commits.
- Scratch, if you need any: `TMPDIR=/data/ui-ideation/tmp/prep-docs`.
- Another worker is building two panels on the same base in a different checkout. It touches `src/`, `tests/` and `assets/glass/l1/`. You stay out of those.

## What to read first

- What the survey found, with paths: `/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/docs/workstreams/ui-ideation/merge-readiness-l1.md`. Treat it as a lead list, not as the truth: open each file and judge it yourself, and look for others it missed.
- What was built and why: in that same folder, `spec/buy-screen-l1.md` (the build spec), `owner-decisions.md` (rows L1 to L51 are the owner's decisions on this look, each with their words), `looks/L1/look.md`, `looks/L1/panels/panels.md`, `build-plan-l1.md`.
- The built game in your checkout: `src/glass/glass_card.gd`, `l1_card_face.gd`, `assets/glass/l1/`, `src/screens/recruit/`.

## What to do

1. **Bring the look's record into the branch.** The game's new layout file cites `buy-screen-l1.md` section by section, and a test enforces it, but the spec lives only on the ideation branch. Put the spec, its rectangles file and the script that makes them, and the owner's decision rows L1 to L51 (verbatim, with their quotes) where a design record belongs in this repo, and make the citations resolve. Say in one line at the top of each what it is and where it came from. Fix paths inside them that point at the ideation checkout or at `/data`.
2. **Make each out-of-date document true.** For every document that describes the card, tier frames, the buy screen's layout, where layout numbers come from, or what is decided about the look: edit it in place so that it says what holds on this branch. Start from the survey's list (`docs/STATUS.md`, `CLAUDE.md`'s Layout section, `docs/design/art-direction/README.md` and its "not decided" list, the card art recipe, `.claude/skills/bramble-art/SKILL.md`, `.claude/skills/design-critique/SKILL.md`, `docs/CLOUD_SETUP.md`, `docs/AGENT-BLIND-SPOTS.md`, `docs/ideation-track-2/`), and search for more. Where a document is wholly about superseded work (the tier frame work, for instance), archive it the way `CLAUDE.md` says instead of patching it.
3. **The card art process.** The art itself does not change now (the owner: "card art replacement can happen later"). What changes is what the recipe and tools say the art is made to fit: one code-drawn lead frame, its crop of the 560 x 1000 picture (source x 28 to 532, y 52 to 952), and where the Attack and Health discs sit (the spec's section 6). Rewrite the recipe's frame, margin and safe-area parts for that. `tools/art/glass-art/assemble.py` lays a tier frame over preview cards: make its preview show the new card's outline, crop and disc places instead, or drop the overlay if that is the honest state, and say which you did. The frame-only tools retire.
4. **Say what is still two-sided.** The fight screen keeps its old room and still reads the old generated layout; the old mock-up pull still runs for it. Documents must say this plainly, so nobody deletes the old path or trusts it for the buy screen.
5. **Record the open gaps where the repo keeps such things** (`docs/design/review-queue.md` or the place you find is right): tier in the shop is told by colour and strength alone; about thirty states of the buy screen keep the old look as stand-ins (the spec's section 11 lists them); the fight screen has no design in this look; the calmer card art the owner asked for on 24 Nov (decision L6) is not started.

## What not to do

- No change under `src/`, `tests/`, `assets/`, `project.godot`, `scripts/`, or to any tool other than the art tools named above. In particular do **not** delete `assets/glass/frames/`, `assets/glass/card_data.json` or anything the old pull writes: another session's branch still reads them, and their removal is a separate, later step.
- Do not reword, summarise or "improve" any file in `docs/design/owner-notes/`.
- Do not change rules in `CLAUDE.md`: only its descriptive Layout section and any line that states a fact now false.
- Do not write history into documents ("previously", "as of the L1 change"): say what holds.
- Do not read token or `auth.json` files. Start no subagents.

## Done means

- Every document you touched is true for this branch, and you have searched for stragglers: say what you searched for and what you found.
- `./scripts/check.sh` steps that do not need Godot pass for your changes (the script's header lists its steps; run what covers formatting, shell, Python and version drift, and say exactly which you ran and their result). The full gate is run by the orchestrator after your branch is joined with the panels.
- Nothing under the forbidden paths changed: show `git diff --stat` against `ui/l1`.

## Report

Under 300 words: where the look's record now lives; each document changed or archived, in a line each; what you did to the art tools; what you chose not to change and why; anything that needs the owner's decision; and a **Disk** line (what you wrote outside your checkout, with sizes; delete nothing outside your checkout).
