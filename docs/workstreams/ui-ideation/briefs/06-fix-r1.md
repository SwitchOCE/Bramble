# Fix brief, round 1: your concept is on the council's shortlist

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). A council of three models (Claude Opus, GPT Sol, Gemini Neon) reviewed all six concepts, discussed them and voted. Three are shortlisted, yours among them. I relay the council's agreed list word for word; I did not judge your concept and I add nothing to the list.

## The owner's words (unchanged)

> "I specifically want the additional instructions of there to hold the theme and the stained glass and the hexagons, the warped hexagons, like the length and hexagons sacrosanct. Everything else is up for debate. It can suggest things and should suggest other things They're not to follow the other constraints"

The last test of this run is still ahead, in the owner's words: the council sees your screens mixed into the gallery of games players love and answers whether "our design feels like it belongs here. It's one of the better ones here, or it's at least the average kind of level".

## What to do

1. Read `docs/workstreams/ui-ideation/council/r1-agreed.md`: the section for your letter under "Agreed fix lists (blocking)", and "Non-blocking". Read nothing else in that folder: the members' full answers discuss the other designers' concepts, which you still must not see.
2. Fix every blocking item for your concept, in `concept.html` in your folder. Keep your concept: same direction, same layout idea. Do not redesign it into something else and do not add features the list does not ask for. Where an item cannot be done without harming the concept, do the nearest thing and say so. The non-blocking items are optional: do one only if it costs you almost nothing.
3. The three fixed things and every rule in the design brief (`briefs/04-designer.md`) still hold, including the visual quality pass. Run the whole pass again on every view: a fix in one place often breaks another.
4. Render every view again at 1920x1080 over the old files in `/data/ui-ideation/concepts/<your letter>/` (`mid.png`, `first.png`, `fight.png`, `after.png`, any extras). Your round-1 renders are kept in the `r1/` folder there for comparison: leave them. Open every new render and look at it.
5. Add a section "Round 1 fixes" to your `notes.md`: one line per item number, saying done (and what you did), or not done (and why). Update the rest of the notes where the fixes change them (the glance-tier counts, the reversed rows). The 500-word limit does not cover this new section.

## Rules

As before: write only in your two folders; no commits; `TMPDIR=/data/ui-ideation/tmp/<your letter>`; never run a delete command anywhere, list what should be removed; never read token or `auth.json` files; start no subagents. From stills, motion, timing, hover feel and sound are "not judged".

## Report

Reply with: one line per fix item (done, or not done and why), the paths of the new renders, anything you could not fix, and a **Disk** section (every folder you wrote into outside your concept folder with its `du -sh` size, what can be deleted, and `df -h /data /` at the start and the end).
