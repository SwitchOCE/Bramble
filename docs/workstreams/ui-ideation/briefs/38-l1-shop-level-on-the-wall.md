# L1: can the shop itself show its level?

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). For the art director of look L1. Design notes and a picture order; the orchestrator builds in `screen.html`, so do not edit it.

## Where things stand

The owner has seen the buy screen with your heart, hero frame and End turn pieces and the medallion counters (`/data/ui-ideation/looks/L1/c/c4-counters.png`) and called it "almost ready to become a spec". One of the things they raised is below.

## The owner's words (25 Nov 2026)

*[Transcribed from dictation: filler removed, punctuation added, clear dictation errors fixed.]*

> "Shop level is currently not displayed. I wouldn't hate that being diegetic. Maybe the shop itself could change appearance, like the bricks could become more ornate or something. Maybe there's some way of having the shop level a bit more obvious. I mean, I guess it's displayed currently in the little button, the five. But it would be nice to have something a bit more diegetic."

> "I do want things built from their sub-elements, so they use their own textures." (earlier the same day)

> "Obviously, the glows we've got are not how the glows will look in Godot. There needs to be some sort of lighting effect in Godot rather than some sort of static asset. And the twinkles on the gold borders are going to fall into the same kind of bucket."

Standing: quiet backgrounds; no dimming filters over art; the main screen assumes a player who knows the rules; "Don't be too stringent. We're trying to do good design, right? That's the number one priority."

## The problem

The shop has six levels. Today the level is only the small "5" inside the tier-up button. The owner would like the shop wall itself to tell you its level, so that a glance at the shop (yours now, and later perhaps an opponent's) says how far it has been raised.

Facts that bound the answer, none of them a design:

- Each card's arch is lit from behind in the colour of **that card's** tier. The shop's level is a different thing and must not be confused with it, or drown it. The recess stays dark and plain.
- The arches nearly touch the top of the screen (tip about 6 px from the edge). Room exists in the spandrels between arch heads, on the colonnettes and their capitals, on the sill under the cards (20 px), and on the wall of the two wings.
- The wall is behind five cards the player is reading. Whatever changes has to stay quiet at level 6.
- It should be built from pieces that are added or swapped per level, not six whole walls.
- A level-up is a moment. Say in a line what should happen then (motion is not judged from stills; write what you intend).

## What to do (about 20 minutes)

1. Decide how the wall shows levels 1 to 6. Two or three ideas in a line each, then the one you would build and why. Say honestly if you think the wall cannot carry six readable steps and what it can carry instead (for instance three stages plus the numeral).
2. Write `docs/workstreams/ui-ideation/looks/L1/prompts-7.txt`: up to 6 items in the format of `prompts-6.txt` (pieces on a flat ground, blank, for cutting out).
3. Add a section "Shop level on the wall" to `looks/L1/polish.md`, 200 words at most: the idea, what is added at each level, where each piece goes and at what size on the 1920 x 1080 screen, and what happens at a level-up.

## Rules

Write only `prompts-7.txt` and `polish.md` in `docs/workstreams/ui-ideation/looks/L1/`, and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/look-L1`). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. Make no pictures with an image model yourself.

## Report

Under 150 words: the idea and what each level adds, the pieces ordered, anything unsolved, and a **Disk** line (what you wrote outside the repo, with sizes).
