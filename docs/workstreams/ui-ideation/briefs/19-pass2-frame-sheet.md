# Pass 2, round 5: a frame sheet only

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). The owner has looked at rounds 3 and 4. For the screen layout the owner chose another concept's window, so your concept's screens rest for now. The owner liked round spells. The owner also described a new card frame and is unsure of its proportions, so I am asking each designer for their own take on that frame, on one sheet. The owner's words are below; the rest is my reading and proposal, and where they differ the words win.

## The owner's words (22 Nov 2026)

*[Transcribed from dictation: filler removed, punctuation added. Words I am unsure of are kept as heard with my guess in brackets.]*

> "Okay, give me more quiet borders, right? Let's say we still want to keep the colour scheme and have an element of the card border that expresses the story *[probably "tier"]*. But we want it sized for the card sizes that we think we're going to use. I mean, obviously, we can change size as needed. And we keep the majority of the frame lead, but have maybe the bottom third or so, I'm not sure exactly the proportion, be the stained glass pattern in the correct colour with the ornamentation. That should hopefully be less busy, but still make the higher-tier cards more obvious, right?"

> "I also like trying to keep both the vertical, like the 45-degree... I like to keep the padding vertically between the top and the bottom row and side to side equal, right? The padding in every direction should be equal, both along both 45-degree axes and the vertical lines, essentially."

> "I like the circular stuff for spells. That's cool."

> "My idea for the card is, you know, the bottom third of the card would be the current stuff, and the top two-thirds would be what was proposed, kind of the same kind of styles as we did in the other sessions. And let's do a pass with that."

## My reading

1. **A frame in two parts.** Most of the frame is plain lead: the quiet frame you proposed in this pass. About the bottom third carries "the current stuff": the game's present frame for that tier (`assets/glass/frames/`), its stained-glass pattern in the tier's colour with its ornament. The proportion is open: propose one, and show a quarter, a third and a half side by side for one tier.
2. **Made for the size it is used at.** Board cards in this pass are between 112 and 128 px wide at 1920x1080 (your own card's proportions). Design the frame at that size, not as big art shrunk down. If the present frame's ornament turns to noise at 112 px, redraw it simpler in the same colours and spirit, and say so.
3. **The owner's test.** Less busy than today's frame; a higher tier is more obvious than a lower one at a glance at board size; the tier's colour scheme is kept. A golden unit must still be unmissable.
4. **Equal gaps.** Where you show cards next to each other, use one gap everywhere: the same between upright sides in a row and between the facing slanted edges of two nested rows.
5. **Nothing on the card explains it.** Attack, Health and your tier mark as before; no words.

## What to deliver

A new page `docs/workstreams/ui-ideation/concepts/<your letter>/frame.html`, rendered at 1920x1080 into `/data/ui-ideation/concepts/<your letter>/`:

- `frame.png`, everything at the real on-screen size, on a dark, quiet ground:
  - tiers 1 to 6 at 112 px wide, panes blank (one plain glass tone);
  - tiers 1 to 6 at 128 px wide, panes blank;
  - the same six holding the game's present card art (`assets/units/`), unfiltered;
  - a golden unit, a hovered unit and a round spell;
  - seven cards in two nested rows (four over three) of mixed tiers with your gap, to show how a full board reads.
- `frame-2x.png`, at two or three times size: tiers 1 to 6 and golden; and one tier with the glass part at a quarter, a third and a half of the card's height.

Leave every other file in that folder as it is. Open both renders and look at them.

Add "Pass 2, round 5 (frame)" to `notes.md`, 120 words at most: the proportion you chose and why; how each tier differs; what you kept from the present frame and what you redrew.

About 20 minutes is right.

## Rules

As before: write only in your concept folder and `/data/ui-ideation/concepts/<your letter>/`; no commits; `TMPDIR=/data/ui-ideation/tmp/<your letter>`; never run a delete command anywhere; never read token or `auth.json` files; start no subagents; do not look at another designer's folder or renders.

## Report

In under 100 words: the proportion, how tiers differ, anything you could not do, and a **Disk** line.
