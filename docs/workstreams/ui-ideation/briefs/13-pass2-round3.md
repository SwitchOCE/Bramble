# Pass 2, round 3: a layout round, with no card art

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). The owner has looked at rounds 1 and 2 and reacted. The owner's words are below; the rest is my reading and proposal, and where they differ the words win. The earlier words in `briefs/08-pass2-designer.md` still hold.

## The owner's words (22 Nov 2026, on rounds 1 and 2)

*[Transcribed from dictation: filler removed, punctuation added, clear mishearings fixed ("card out" is read as "card art").]*

> "This was both a step forward and a step back, I feel like. So I think agents focused far too much on the colour stuff. Some of the artwork is the source of the colour issues, right? And just applying a filter on top to dial down the contrast and artwork doesn't really do it. Additionally, I think that agents need to be willing to resize the cards if they don't fit the design because they're too tall. The aspect ratio and the general shape must stay, but the size can change, and I'm okay with the size changing. And I feel like I can tell these designs have been at some point compromised because someone's refused to move on size. Like, some of the decisions here are nonsensical."

> "How about we just have builds wholly without card art, right? You can just leave a blank space shaped in the same size as a card, whatever size the build's proposing. Just don't include the card art in the build. It's intentionally left blank. And I want a good layout. Like, this vertical padding and horizontal padding being different is interesting stylistically, but I struggle with it a lot, you know, this packing, and I'm not sure what the right gaps are. I would, yeah, not a big fan."

> "And the agents dealing with the card art being very garish by just putting darkening filters on it was not the goal. I can change the card art style [...] for example, on design A, the great window refit, the background, I mean, it darkened up a bit, I guess. That's about it. And I'm not convinced that that's, you know, that's just sucked all the joy out of the scene. We still need to capture that, but we can go with other choices."

> "The removal of all the tooltips was excellent, right? That worked, and I think especially the spacing of the cards and the gloves *[probably "glows"]* in the glass in the forest instance works quite nicely. I feel like we are probably too constrained on negative space because of the card's scale. And I feel like designing around that problem rather than rescaling things a bit... I don't know how much the card should be. And this is part of the process. I think at some point, agents have decided the size is fixed, and that's absolutely not the case."

## My reading

1. **No card art this round.** Draw every unit and spell as an empty pane in its frame: one plain, quiet glass tone, the same for every card. Do not write anything in the pane. The frame, Attack, Health, the tier numeral, golden, charges and Renown stay. This round is judged on layout alone. The card art's colour is being handled separately, as a recommendation to the owner about how the art is painted; it is not yours to solve on screen.
2. **Take the filters off.** Remove every darkening, dimming, desaturating or tinting treatment you added to cards or to the scene in rounds 1 and 2 to fight the art. The scene should have its joy back. Lead the eye with layout: size, position, spacing, grouping and what the scene itself lights. A hovered or active card may still light up.
3. **Card size is yours to choose.** The unit card's shape and aspect ratio are fixed; its size is not, and it may differ by zone. Decide every size again from what the layout needs. Look for every place where an earlier round bent the layout to keep a card size (rows pushed together, zones squeezed, things tucked into corners, a hand that does not fit) and undo it. The owner believes the screens have too little empty space because the cards are too big: test that.
4. **Spacing on purpose.** The owner struggles with the hexagon packing where the gap across differs from the gap down, and is not sure what the right gaps are. Pick a spacing rule deliberately, and give two options so the owner can compare:
   - `?view=mid`: your recommended layout and spacing.
   - `?view=mid-b`: the same screen with a clearly different packing or card size (for example even gaps with rows not interlocked, or smaller cards with more air). Not a small tweak.
5. **What worked stays.** Nothing at rest explains a card; details on hover; keyword reminders in their fixed place; no zone titles; the next opponent's board never shown.
6. **The council's round-2 list.** Read the section for your letter, and "For all three concepts", in `docs/workstreams/ui-ideation/council/p2r2-agreed.md` (no other section, no other file there). Do the "Agreed" items that still apply once the art and the filters are gone. Skip any that ask for more dimming.

## What to deliver

Render at 1920x1080 into `/data/ui-ideation/concepts/<your letter>/`, over the old files: `mid`, `mid-b`, `first`, `fight`, `after`, `hover-shop`, `hover-board`, `hover-spell`, `keywords-off`, `cards` (`.png`). Rounds 1 and 2 are kept in `p2r1/` and `p2r2/` there: leave them. Open every render and look at it.

Add "Pass 2, round 3" to `notes.md`, 200 words at most, with a small table: for each zone (shop, board, hand, fight, spells) the card's width and height in px, the gap across and the gap down, and one line on why. Then what `mid-b` changes and which of the two you would pick. Then one line per council item done or skipped.

About 25 minutes is right.

## Rules

As before: write only in your concept folder and `/data/ui-ideation/concepts/<your letter>/`; no commits; `TMPDIR=/data/ui-ideation/tmp/<your letter>`; never run a delete command anywhere; never read token or `auth.json` files; start no subagents; do not look at another designer's folder or renders. From stills, motion, timing, hover feel and sound are "not judged".

## Report

In under 150 words: what changed, the sizes you chose, anything you could not do, and a **Disk** line.
