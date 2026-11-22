# Pass 2, round 4: the council on your layout

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). The council looked at round 3 on layout only: two Claude Opus voters and Gemini Neon, with GPT Sol measuring. I relay what they asked for; I did not judge your concept. The owner has not yet reacted to round 3; when they do, their words outrank this.

Everything in `briefs/13-pass2-round3.md` still holds, with the owner's words quoted there: no card art, no filters, card size is yours to choose, nothing at rest explains a card.

## What to do

1. Read `docs/workstreams/ui-ideation/council/p2r3-agreed.md`: "One spacing rule", "For all three concepts" and the section for your letter. Read no other section and no other file in that folder.
2. Do every "Agreed" item for your letter. Apply the spacing rule, or say in your notes why your layout needs something else. The "One voter each" items are optional.
3. Keep your concept's idea and scene. Where an item cannot be done without harming it, do the nearest thing and say so.
4. Render at 1920x1080 into `/data/ui-ideation/concepts/<your letter>/`, over the old files: `mid`, `first`, `fight`, `after`, `hover-shop`, `hover-board`, `hover-spell`, `keywords-off`, `cards`. Render `mid-b` only if you have a second layout you would really put to the owner; otherwise leave the old `mid-b.png` where it is. Rounds 1 to 3 are kept in `p2r1/`, `p2r2/`, `p2r3/`: leave them. Open every render and look at it.
5. Add "Pass 2, round 4" to `notes.md`, 150 words at most: the size-and-gap table again with the new numbers, each gap also as a fraction of the card's width, and one line per agreed item.

About 20 minutes is right.

## Rules

As before: write only in your concept folder and `/data/ui-ideation/concepts/<your letter>/`; no commits; `TMPDIR=/data/ui-ideation/tmp/<your letter>`; never run a delete command anywhere; never read token or `auth.json` files; start no subagents; do not look at another designer's folder or renders. From stills, motion, timing, hover feel and sound are "not judged".

## Report

In under 120 words: what changed, the board card's size and gap, anything you could not do, and a **Disk** line.
