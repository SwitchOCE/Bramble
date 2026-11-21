# Council brief, round 2: re-check the fixes, then the gallery check

From the orchestrator (an agent, not the owner). The designers of A, D and E have worked through the fix lists you agreed (`council/r1-agreed.md`). This round has two parts. Do both, in order.

Opus and Sol go first; Neon is asked once both of them say good to go. Write your answer to `docs/workstreams/ui-ideation/council/r2-<opus|sol|neon>.md` and reply with it in full. Do not read another member's `r2-*` file. Work read-only apart from your answer file and your scratch folder; do not commit; never run a delete command; start no subagents.

## The owner's words (unchanged)

> "I specifically want the additional instructions of there to hold the theme and the stained glass and the hexagons, the warped hexagons, like the length and hexagons sacrosanct. Everything else is up for debate. It can suggest things and should suggest other things They're not to follow the other constraints"

> "I think you need to offer more variety in designs. Use different styles and different layouts. Have the council pick which ones are the best."

> "I would say the final check for the council should be that they are presented with the full gallery of all of the images of other UIs that we found. Pick some good references from that gallery and have the council go: is our design as good The task is done when they go, our design feels like it belongs here. It's one of the better ones here, or it's at least the average kind of level"

## Inputs

- The agreed fix lists: `docs/workstreams/ui-ideation/council/r1-agreed.md`.
- The fixed concepts: `docs/workstreams/ui-ideation/concepts/<A|D|E>/` (`concept.html`, `notes.md` with a "Round 1 fixes" section) and the new renders in `/data/ui-ideation/concepts/<A|D|E>/` (`mid.png`, `first.png`, `fight.png`, `after.png`, extras). The round-1 renders are in each folder's `r1/` for comparison.
- Side by side: `/data/ui-ideation/concepts/compare-mid.png`, `compare-first.png`, `compare-fight.png`, `compare-after.png` (today's game and A, D, E as fixed; B, C and F as they were in round 1).
- The gallery, with our screens mixed in: `/data/ui-ideation/gallery/gallery.html`, the contact sheets `sheet-1.jpg` (close in structure), `sheet-2.jpg` (one material through the whole UI) and `sheet-ours.jpg` (today's game and A, D, E), `index.md`, and every image at full size in `images/` and `ours/`.

## Part 1. Re-check the fixes

For each of A, D and E:
1. Go through its agreed list item by item against the new renders at full size: fixed, partly fixed, or not fixed, with the view and the place. Where the designer says an item could not be done, say whether you accept the reason.
2. Run the visual-defect pass again on every view, since a fix in one place can break another (alignment, icon matches action, text a player acts on at least 18 px and no text under 14 px, contrast at least 4.5:1, overlap, overflow, clipping, uneven spacing, dead areas, more than one accent, a card distorted or not a tall hexagon in its frame, anything that is not glass, lead or their surround).
3. Give new scores out of 10 for the look and for reading the game at a glance, and pass or fail on the three fixed things.
4. List what still blocks showing it to the owner: numbered, each with evidence and the fix. Keep to defects and misses against the agreed list; anything else is non-blocking.

## Part 2. The gallery check

Look at the whole gallery, then for each of A, D and E:
1. Pick the references from the gallery that are the right comparison for that concept (three to six images, by file name), and say why those.
2. Judge it as a player would see it, beside those references: flavour, clarity, polish. Answer: does it belong among them: **one of the better ones**, **about average**, or **below**?
3. Say whether it places above today's game (`ours/bramble-today--*`), and by how much.
4. If it is below, say what stands in the way, as specifically as a designer could act on.

The run is done when the members agree that at least one concept "feels like it belongs here" at average or better.

From stills, motion, timing, hover feel and sound are "not judged": say so; never pass them.

## Answer format

- First line: `VERDICT: GOOD TO GO` (nothing blocks showing the shortlisted concepts to the owner, and at least one belongs in the gallery at average or better) or `VERDICT: CHANGES NEEDED`.
- Second line: `GALLERY: A <better|average|below>, D <better|average|below>, E <better|average|below>`.
- A score table: A, D, E by (the look, reading at a glance, the three fixed things), with your round-1 scores beside the new ones.
- Part 1 per concept: the item-by-item check, new defects, and the numbered blocking list (or "none").
- Part 2 per concept: the references chosen and why, the answer, and where it stands against today's game.
- At most 3 non-blocking notes.
- Not judged.
- A Disk section: anything you wrote besides your answer file, with paths and sizes, and what can be deleted.
