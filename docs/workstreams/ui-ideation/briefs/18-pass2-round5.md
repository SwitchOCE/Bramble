# Pass 2, round 5: the owner picks the great window, and asks for a quieter frame

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). The owner has looked at rounds 3 and 4 and reacted. The owner's words are below; the rest is my reading and proposal, and where they differ the words win. The earlier words in `briefs/08-pass2-designer.md` and `briefs/13-pass2-round3.md` still hold.

This brief is for concept A's designer. Briefs for the frame alone are in `briefs/19-pass2-frame-sheet.md`.

## The owner's words (22 Nov 2026, on rounds 3 and 4)

*[Transcribed from dictation: filler removed, punctuation added. Words I am unsure of are kept as heard with my guess in brackets.]*

> "Okay, give me more quiet borders, right? Let's say we still want to keep the colour scheme and have an element of the card border that expresses the story *[probably "tier"]*. But we want it sized for the card sizes that we think we're going to use. I mean, obviously, we can change size as needed. And we keep the majority of the frame lead, but have maybe the bottom third or so, I'm not sure exactly the proportion, be the stained glass pattern in the correct colour with the ornamentation. That should hopefully be less busy, but still make the higher-tier cards more obvious, right?"

> "I also like trying to keep both the vertical, like the 45-degree... I like to keep the padding vertically between the top and the bottom row and side to side equal, right? The padding in every direction should be equal, both along both 45-degree axes and the vertical lines, essentially."

> "And I still like the kind of window in the window the best, I think. Adding extra stuff to the background I didn't like. I preferred what we had in not this round, but the previous round, with a darker background, more like the current shot that says the stuff that's like before round three, with just the vague suggestion of lines and wind *[probably "vines"]* and leaves and stuff. I like that the most. So let's go with that, with the new sizing, the new shop layout. I like the circular stuff for spells. That's cool. And I think that would be really good."

> "Have Sol do a lot of art generation if needed. I'm not sure if he's been used for that already. It seems like he probably has."

> "My idea for the card is, you know, the bottom third of the card would be the current stuff, and the top two-thirds would be what was proposed, kind of the same kind of styles as we did in the other sessions. And let's do a pass with that."

## My reading

1. **Your concept carries on.** I read "the window in the window" as the great window: the picture the owner describes (a darker ground with only lines, vines and leaves, shown on the page as "Before: round 3") is your round-3 `mid`.
2. **The background goes back to round 3.** Use the ground of `/data/ui-ideation/concepts/A/p2r3/mid.png`: darker, with only the faint lead lines, vines and leaves. Take out what round 4 added to it: the trees, the rays, the pale sky, the amber light. That darker ground is the scene's own colour. It is not a filter, and nothing is dimmed over the cards.
3. **Keep round 4's sizing and shop layout.** The one shared column pitch, the shop's controls in the left light, the hand in one row, spells set apart from units. Card size is still yours to change.
4. **Equal padding in every direction.** My reading of the owner's words: the gap between the upright sides of two neighbours in a row, and the gap between the facing slanted edges of the two rows (measured square to those edges, on both diagonals), are the same number. That means the rows are offset by half a slot and nest like a honeycomb. This replaces the council's "never nested" rule from round 3. Use it for your board and for both armies in the fight, and give the shop and the hand the same gap across. Nested rows are shorter in total, so check whether the card can grow while the fight still fits, and say what you chose and why.
5. **A quieter frame, in two parts.** Most of the frame is plain lead: the quiet frame you proposed in this pass. About the bottom third carries "the current stuff": the game's present frame for that tier (`assets/glass/frames/`), its stained-glass pattern in the tier's colour with its ornament. The owner is unsure of the proportion: propose one, and show a quarter, a third and a half side by side for one tier. Design it at the size the card is used on screen, not as big art shrunk down. The test is the owner's: less busy than today's frame, and a higher tier is more obvious than a lower one at a glance at board size. A golden unit must still be unmissable.
6. **Spells are round.**
7. **Art generation.** If drawing the glass in code, or cutting it from the current frames, does not hold up at this size, you may generate it with your image tool. The owner allows a lot of it. Keep the pictures under `/data/bramble-art/uiid-frames/` and list them, and any copies your image tool leaves elsewhere, in your Disk line.
8. **Card art stays off the screens.** Panes stay blank in every game view. On the `cards` sheet only, add one row of the same frames holding the game's present card art (`assets/units/`), unfiltered, so the frame can be seen against art.
9. **Still true.** Nothing at rest explains a card; details on hover; keyword reminders in their fixed place, hidden in `keywords-off`; no zone titles; the next opponent's board never shown; no filters over cards or scene.
10. **The council's open items for A**, where they do not fight the owner's words above (`council/p2r4-agreed.md`, section A only): the side lights hold little and could narrow to what they hold; no lead bar runs between the two rows of one army; empty board slots are thin outlines like the hand's.

## What to deliver

Render at 1920x1080 into `/data/ui-ideation/concepts/A/`, over the old files: `mid`, `first`, `fight`, `after`, `hover-shop`, `hover-board`, `hover-spell`, `keywords-off`, `cards`, and `extra1`. Rounds 1 to 4 are kept in `p2r1/` to `p2r4/` there: leave them. Open every render and look at it.

- `cards`: at the real on-screen size, tiers 1 to 6, a golden unit, a round spell, a hovered unit; then the row with present card art; then four cards side by side with your gap, on the scene's ground.
- `extra1`: the frame at two or three times size: tiers 1 to 6 and golden, and the quarter, third and half versions of one tier.

Add "Pass 2, round 5" to `notes.md`, 200 words at most: the size-and-gap table (the gap across, the gap between slanted edges, each also as a fraction of the card's width); the frame's proportion and why; how each tier differs; what was generated and what was drawn; one line per item above done or not.

About 30 minutes is right.

## Rules

As before: write only in your concept folder, `/data/ui-ideation/concepts/A/` and `/data/bramble-art/uiid-frames/`; no commits; `TMPDIR=/data/ui-ideation/tmp/A`; never run a delete command anywhere; never read token or `auth.json` files; start no subagents; do not look at another designer's folder or renders. From stills, motion, timing, hover feel and sound are "not judged".

## Report

In under 150 words: what changed, the card size and the gap, the frame's proportion, anything you could not do, and a **Disk** line.
