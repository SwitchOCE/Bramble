# L1: the health heart, the hero rectangle, and options for the End turn button

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). For the art director of look L1. A picture order and short design notes; the orchestrator builds in `screen.html`, so do not edit it.

## Where things stand

Your zone pieces are in and the owner has seen the result: `/data/ui-ideation/looks/L1/c/c-zones.png` (`screen.html?view=polish&room=zones`). The owner is happy for the screen to be built from our own painted pieces, one per zone or one per group of joined zones.

## The owner's words (25 Nov 2026, after seeing that picture)

*[Transcribed from dictation: filler removed, punctuation added, clear dictation errors fixed. My guesses are in brackets.]*

> "I do want things built from their sub-elements, so they use their own textures. Generate our own; it makes more sense."

> "The bottom left for the health and the hero's portrait: I want that swapped. The health should be at the top right and can stay as whatever, maybe like a heart with a little [number] inside of it. And your portrait should go down the bottom left, as a rectangle, and use a bit more height to be in line with the hand. It's where the hero power will activate when we turn hero powers back on."

> "The next turn button should probably be like [crossed] swords, I would guess, and probably have a red texture because you're going to a fight, and maybe that button changes depending on what's happening, or maybe you have red [crossed] swords over the icon of the opponent you're fighting. Do some different options for the next turn button."

> "Go with whatever textures you think are good. You don't have to composite additional images for every different zone if zones are being connected to be treated as one."

Standing: numerals and clear icons, very few words; no dimming filters over art; "Don't be too stringent. We're trying to do good design, right? That's the number one priority."

## What is needed

1. **Health** in the right column, under the gold coin, where the portrait was (about 130 px across): the owner suggests a heart with the number on it. Code puts the number on.
2. **The hero's portrait as a rectangle** at the foot of the left column, about 212 wide and 144 tall, its top level with the top of the hand ledge. The picture inside is the hero's existing portrait art, placed by code; what is needed is the frame, and it should look pressable, since it will fire the hero power.
3. **End turn, three or four options**, each about 144 px across, at the foot of the right column. Today it is an amber glass roundel with an arrow. The owner's ideas are above; add your own if you have a better one. Think about what the button says in each state the game has: you still have gold to spend, you are done, the fight is about to start. For each option say what it looks like in those states, in a line.

## What to do (about 20 minutes)

- Write `docs/workstreams/ui-ideation/looks/L1/prompts-6.txt`: up to 7 items in the format of `prompts-5.txt`. Icons that code can draw cleanly (crossed swords as a line icon, for instance) need no picture, unless you judge that a painted one, leaded into the glass, would be clearly better; that is your call.
- Add a section "Heart, hero and End turn" to `looks/L1/polish.md`, 200 words at most: each End turn option in a line or two with its states, which one you recommend, and where each new piece goes and at what size.

## Rules

Write only `prompts-6.txt` and `polish.md` in `docs/workstreams/ui-ideation/looks/L1/`, and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/look-L1`). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. Make no pictures with an image model yourself.

## Report

Under 150 words: the End turn options and your pick, the pieces ordered, anything unsolved, and a **Disk** line (what you wrote outside the repo, with sizes).
