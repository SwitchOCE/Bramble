# Write the build spec for the L1 buy screen

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). You write one document. You write no game code.

## Why

The owner has chosen a look for the game's buy screen from HTML mock-ups and asked for it to be built in the game. Workers who have never seen this conversation will build it in Godot from your spec, one step at a time. If a number, a state or a piece of art is missing from the spec, a worker will guess.

## The owner's words (25 Nov 2026)

*[Transcribed from dictation: filler removed, punctuation added.]*

> "Everything else is basically perfect. I really like this. I think this is almost ready to become a spec and start real work."

> "Lanterns are good. Let's go with that and build it out in-game."

> "Obviously, the glows we've got are not how the glows will look in Godot, and that needs to be documented. There needs to be some sort of lighting effect in Godot rather than some sort of static asset. And the twinkles on the gold borders are going to fall into the same kind of bucket."

> "We don't have to contain everything on the static screens. We have modals as well ... We need to be less focused on how everything fits into one screen and being willing to handle overflow with modals."

> "Only your highest counters or most recently changed things could show up ... It's fine to have something and X more and you click on a button and it pops out a modal or a tooltip."

Every other decision is a row in `docs/workstreams/ui-ideation/owner-decisions.md` (L1 to L44, each with the owner's words). Where the spec states a decision, cite its row.

## What to read

All paths are in this checkout unless they start with `/data`.

- The design, which is the source of truth for every number: `docs/workstreams/ui-ideation/looks/L1/screen.html`, drawn with `?view=polish&room=zones` (layout c is the default; follow the `C` and `ZONES` branches of `polish()`). Its picture: `/data/ui-ideation/looks/L1/c/c7-chosen.png`. You can render any variant with `/data/ui-ideation/tools/l1-scripts/render.sh "<query>" <out.png>`, and you may load the page in headless Chrome to read out the rectangles of its elements instead of working them out by hand (each element is tagged with a part name as it is drawn).
- Notes: `looks/L1/look.md` (read all of it; later sections override earlier ones), `looks/L1/polish.md` (the art director's intent, including each End turn state and the level-up moment).
- The art: `/data/ui-ideation/looks/L1/pieces/` (34 files; `looks/L1/zone-pieces.py` shows how each was cut and where openings sit).
- The plan this spec is step 0 of: `docs/workstreams/ui-ideation/build-plan-l1.md`. Its "What the game has today" section is a survey of the game's code.
- The game's code on `dev`, read-only, at `/data/worktrees/l1-dev-read`: `src/screens/glass_screen.gd`, `src/screens/recruit/`, `src/glass/`, `assets/glass/layout.json`, `tests/`.
- The skill `design-handoff` in this repo (`.claude/skills/design-handoff/`): follow it for the shape of the spec.

## What the spec must let a builder do

Build each of the plan's steps 1 to 4, 6 and 7 without seeing the mock-up's code and without asking a design question. So it needs at least:

- every element's rectangle on the 1920 x 1080 stage, and the rule behind it where the rule matters more than the number (for instance "the arch opening is the card plus 24 each side");
- for every element: which piece of art, at what size, or how it is drawn if it has no art; what in today's game it replaces (file and function);
- the states the game really has and what each looks like. Find the states in the game's code (cannot afford, frozen shop, full hand, empty slot, golden, shop level 1 to 6, counters from none to more than four, End turn's states, a hovered or carried card and so on). Where the mock-up does not show a state, **do not design it**: list it under "Not designed" so the owner can be asked;
- every light as an effect, not a picture (the owner's words above): what it is for, where, its colour and strength per tier, and what must be judged in the engine. Motion, timing, hover feel and sound are "not judged";
- what is out of scope (the plan lists it);
- where the new layout numbers should live in the game: the plan leaves open whether to hand-edit the generated, hash-tested `assets/glass/layout.json` or add a new file. Look at how that file is made and tested and recommend one, with the reason.

How you organise it is yours to decide; a builder working on one step should be able to find that step's material without reading the rest.

## What to make

- `docs/workstreams/ui-ideation/spec/buy-screen-l1.md`. Plain language, short sentences, tables for numbers.
- If you read the rectangles out of the page, keep the data as `docs/workstreams/ui-ideation/spec/buy-screen-l1.rects.json` and say in the spec how it was made.
- Check your numbers against the picture before you report: pick ten elements across the screen and confirm each rectangle lands on the thing it names.

## Rules

Write only inside `docs/workstreams/ui-ideation/spec/` and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/spec-l1`; create it). Change nothing in `/data/worktrees/l1-dev-read`. No commits and no other git commands that change anything. Never run a delete command. Never read token or `auth.json` files. Start no subagents. Make no pictures with an image model.

## Report

Under 200 words: what the spec covers, the "Not designed" list, your recommendation on where layout numbers live, anything you could not establish, and a **Disk** line (what you wrote outside the repo, with sizes, and what can go).
