# Plan: card frames for tiers 1 to 6 (part of step 2 of the glass dial-in)

<!-- status -->
- **In short:** The card frames are decided: the owner locked in the thinner frames with a small hanging diamond under the top accent ("take 1" of the last run), and they have gone to the art session.
- **Status:** done
- **Last step done:** The owner locked in take 1 of the hanging-diamond run (15 Nov 2026).
- **Next step:** A clean high-resolution redraw of the six frames when the game needs them; the art session carries on from these.
- **Waiting on you:** Nothing.
<!-- /status -->

Parent plan: [glass-dial-in.md](glass-dial-in.md), step 2 (card anatomy). This plan covers the unit frame by tier. The rest of step 2 follows once a frame is chosen: spells, the Ring slot, can and cannot afford, selected or held, and the contrast check.

Status: approved by the owner, 15 Nov 2026. Asked "Approve the frames-only plan?", the owner said: "Approve it".

## The problem, in the owner's words (15 Nov 2026)

Said while comparing the chosen concept (two foxes, [glass-concept.jpg](../design/art-direction/examples/glass-concept.jpg)) with the mock-up's card sheet ([glass-cards.jpg](../design/art-direction/examples/glass-cards.jpg)):

> "I think the current ones don't capture the beauty of what the left did. I think that I really liked the idea of starting off pretty plain at the lower tiers and going with more segments and more color tinting as the tiers rose. But I do not feel that the ones on the right strike that correctly. And I want to improve and get a good set of options for all of the different tiers. I want to get the six card borders for every tier done. The key things it has to have is, just like on the left, has to have attack and health. And I liked that it was minimal. I liked that we didn't change the coloring and stuff to try and evoke it. It can just be attack and health. It doesn't need that. The left is better than the right in terms of the styling on that. ... So the other thing that the foxes do, the inspiration did, that the right doesn't, is it changed the aspect ratio of the cards to be a bit more narrow. I'm open to exploring that. So yeah, can we get some sort of way of experimenting with this stuff? What do you recommend in terms of me being able to see some options and get a feel for how things would look at various different choice levels?"

On tier 1's colour:

> "The white stuff can be gray. I think white's a bit too bright and it kind of draws the eye more than the stuff that's supposed to be more important than it. or a light grey or an off-white or something. It's supposed to feel common and mundane."

On scope:

> "The artwork is irrelevant. We're just focusing on the frame. The fox is not part of what we're doing here. The art will be separate from card frames. Card frames will be consistent across all arts. So we are just focused on the frame. We don't even need to worry about what fills in it. What fills it in? It can be blank. We're completely transparent. We're just focused on the frame that surrounds the cards."

## What the frames must do

From the owner's words above:

- **Frame only.** The window is empty. One frame for each tier, used with every unit's art.
- **Glass like the fox concept's border:** textured, back-lit glass with uneven pieces, not even bands of flat colour.
- **Tier 1 is plain** and grey (light grey or off-white), so it feels common and doesn't pull the eye. This holds for every ladder and every shape.
- **Higher tiers get more segments and more colour tint.**
- **Attack and Health only.** Two plain roundels like the fox's: cream glass, black serif numerals. No tribe emblem or tier badge.
- **Try a narrower card,** as in the fox concept.
- **Tint colours** follow the owner's order from earlier on 15 November: "white, then green, then blue, then that purple, then like yellow for legendary and red for mythic". White is now grey.

## Steps

Codex draws the frames, with the fox concept attached as a style reference for the glass and lead only. Each frame is drawn with its window filled flat charcoal, as an empty window. Each step ends at a decision by the owner.

1. **First ladder: segments and tint together.** This is the owner's own description and the fox concept's progression. Six frames at the fox's shape (about 1 wide to 2 tall), tier 1 in light grey, plus a second tier 1 in off-white: 7 frames. The roundels show Attack 3 and Health 5.

   **Checkpoint:** the six frames side by side, next to the fox concept, and the two tier 1 greys. Does it capture the fox's border, and which grey?
2. **The other variants.** Two ladders that each push one half harder, to show the range:
   - **Tint first:** the panes stay few, and the colour creeps in tier by tier, up to full jewel colour with a glow at tier 6.
   - **Segments first:** the colour stays quiet, and the panes multiply, from one long pane per side at tier 1 to six small panes with jewel insets at tier 6.

   Plus a shape trial: the first ladder's tier 1 and tier 6 at about 2 wide to 3 tall, and at the current hexagon. That's 16 frames.
3. **The frame lab.** One page in `docs/design/art-direction/frame-lab/`, run from `.claude/launch.json`. It shows:
   - each ladder as a row of tiers 1 to 6, at game size and at 1.6 times
   - a shape switch
   - a board view: empty frames on the 4-3 board with mixed tiers, at each shape, to see the shape and whether tier 1 stays quiet beside higher tiers.

   Check: screenshots of each view, and a scope review before it merges into this branch.
4. **Owner picks** a ladder (or a mix, in words), a shape and the tier 1 grey. Plus one greyscale screenshot, to check that tiers still differ without colour.
5. **Round 2.** Codex redraws the chosen ladder as one consistent set: the same window outline at every tier, with the chosen tier 1 as the base for the others. The window is cut out to transparent for use over any art. The owner locks the set or asks for another pass.
6. **Write-up.** The locked frame goes into a spec with measurements (window, roundel size and position, lead weight). Then step 2 of the parent plan carries on.

## Risks

- **The window may drift from tier to tier.** Codex may not keep the window outline the same across six images. In round 1 that's fine, since you are judging the look. Round 2 fixes it by giving Codex tier 1 as the base for each tier.
- **Codex adds a picture in the window,** because the fox reference has one. The prompt says the window is flat charcoal and empty, and any frame that ignores this is redrawn.

## Not in this plan

Spell and Ring-slot frames, card states, the tribe emblem's place, and the contrast check. These follow in step 2 of the parent plan once this frame is locked.

## Where the work lives

On `design/stained-glass-direction`. Nothing goes to `main` without the owner's say-so for that merge.

## Round 1 feedback (owner, 15 Nov 2026)

On the first ladder ([sheet](../design/art-direction/frame-lab/r1a/sheet.jpg)):

> "Tier 1 and gray is great. And tier 5 and 6 are great. I'm very happy with those. My issue right now is tiers 2, 3, and 4. I think the green one needs to have more green and feel more like an uncommon. The more uncommon color, it's too light of a green. There's too much gray in it. The purple one, the tier 4 one, is for some reason vertically, I don't like the vertical symmetricality, I guess. For some reason, there's a rhombus that's the accent rather than the trapezoid. And that also throws off like the vertical symmetry. I like the symmetry, and I think we should keep the symmetry of the accenting. And yeah, I feel like I think just the region and the depth of color can do most of the work in terms of highlighting, like the fact that there's more regions and smaller segments can do most of the work in terms of highlighting the specialness. Also, what we lost from the reference images was some non-regular shapes. If you look at the reference images, there's the border is like not parallel on the segments at the top and the bottom, which creates this thickening to a point kind of thing. And none of our borders so far are as good as any of the ones in the reference images from a shape perspective. From a color and region perspective, they're pretty cool. Not as good as reference images still, but pretty cool. have another go with those."

What the redraw ([glass-frames-r1b.txt](../../tools/art/prompts/glass-frames-r1b.txt)) changes:
- Tier 1 grey is chosen. Tiers 1, 5 and 6 keep their colour and pane cut.
- Tiers 2 to 4: the border is all the tier colour, no grey panes. The colour deepens and the panes get smaller as the tier rises; that does the highlighting.
- Accents are mirror-symmetric left to right, with trapezoids, not slanting rhombuses.
- All six tiers get the reference's shape: the border thickens towards the top and bottom points, with wedge-shaped panes whose edges are not parallel. *[Editor note: redrawing tiers 1, 5 and 6 too is the agent's call, so the set shares one shape. The round 1 versions are kept for comparison.]*

## Code-drawn lead, Codex glass (owner, 15 Nov 2026)

After the redraw, the owner asked whether frames could be drawn by code instead, for finer control: "I think the new shape is better. I don't want to go back to the old shape. ... Maybe we do some sort of programmatic stuff and use a gradient rather than relying on the image generation models, because it gives us more control to fine-tune things." A code-drawn version went into the [frame lab](../design/art-direction/frame-lab/index.html) ([comparison](../design/art-direction/frame-lab/code-vs-codex.jpg)). The owner's verdict:

> "I think the textures that Codex does are way better. I think I really like the basic, the way you drew the lead lines in terms of having them all be diagonal and just increasing the number of the divisions was better Right. So can you tell Codex to use the positioning of the LED *[lead]* that you showed in your kind of programmatic only for 1 through to 5? I actually prefer Codex's 6 a little bit, or it can take inspiration from your 6, but your 6 is not better than its. And I like how it does the bottom and top diamonds more than how you've done it with the code. Those diamonds are far better. How it keeps them as one continuous shape and has it sit in the front, those are way cooler. I like that a lot on, and actually I kind of wonder if we should have that for every card, even the common, for the bottom only, maybe. Maybe bottom and top. I don't know. We can look at both."

What follows: Codex redraws tiers 1 to 5 with the code's lead layout and its own glass, and Codex's tier 6 stays. Every tier is drawn twice: with Codex-style point diamonds at the bottom only, and at top and bottom. Prompt: [glass-frames-r1c.txt](../../tools/art/prompts/glass-frames-r1c.txt).

## Card shape: 0.56, not yet locked (owner, 15 Nov 2026)

After seeing the ratios side by side ([shapes](../design/art-direction/frame-lab/shapes.jpg), [0.50 to 0.56](../design/art-direction/frame-lab/aspects.jpg)), the owner said: "I think everything we want to do from now on is 0.56, and that's how the borders need to be." The card outline is 0.56 wide to 1 tall, the new shape from round 1b. Every frame prompt from here on attaches that outline and keeps it.

The method isn't locked yet. The owner, later the same day: "We're not 100% sure yet. This stuff will still move, potentially. I mean, if it works and I'm happy with it, we can lock it in. But yeah, let's not be too rigid on anything yet until I'm absolutely certain that this method's going to work."

The owner also asked about the art space inside it: "because we've got the borders being having this the shouldering being non-uniform at the top, the internal art space is less than it's shaped differently to the external border, and I want I want to know about that space." See [art-space.md](../design/art-direction/frame-lab/art-space.md).

## Decided: take 1 (owner, 15 Nov 2026)

After the size-locked runs ([outline guide](../design/art-direction/frame-lab/loose-e/sheet.jpg), then [accent colours](../design/art-direction/frame-lab/loose-f/sheet.jpg)), the owner first said "Take three is clearly the best. ... I'm locking it in. We've decided that is the future", then corrected it: "Or I meant take one, not take three. My apologies. Can you rectify that?" The decision is **take 1** on the accent-colour sheet.

Take 1 is `frame-lab/masters/loose-f1/accent-1.png` (JPEG: [loose-f/f1-accent-1.jpg](../design/art-direction/frame-lab/loose-f/f1-accent-1.jpg)), from [glass-frames-loose-f.txt](../../tools/art/prompts/glass-frames-loose-f.txt) with the outline-only guide [six-0.56-outline.png](../design/art-direction/frame-lab/guides/six-0.56-outline.png). What it is:
- The 0.56 card with the spec border: the same shape and width at every tier, thickening into a wedge at the top and bottom points.
- Tier 1 pearly white; tiers 2 to 6 green, blue, purple, gold, red. Tiers differ by colour depth, finer panes, and petals and a small jewel at the points.
- One borrowed accent colour per tier: teal in the blue, small cyan jewels on the purple, green leaves on the gold, amber jewels with red and orange together at tier 6.
- Roundels: a glowing gold disc with a dark numeral, ringed by small pieces of the tier's own glass.

Each frame cut out on its own, in card space with a clear window: [frame-lab/final/](../design/art-direction/frame-lab/final/).

How the frames were prompted, for any later redraw: a short, loose prompt in the style of the first fox prompt, plus one strict rule, enforced with an outline-only size guide (thin lines on black, no fills). A grey-filled guide washed the colours out, and words like "calm" and "soft glow" flattened them.

## Thinner, and locked again (owner, 15 Nov 2026)

On screen the take 1 frames looked too busy. The owner: "I think they're too busy now that I see them on screen. We need to reduce the width. ... I think it needs to come down by about 30% or so." Three more rounds, each attaching the previous chosen sheet as the look to keep (the owner chose that) beside a thinner outline guide:
- [thin-a](../design/art-direction/frame-lab/thin-a/sheet.jpg): about 30% thinner. Take 4 was the thinnest at every tier.
- [thin-b](../design/art-direction/frame-lab/thin-b/sheet.jpg): the owner asked to "go 20, 30% thinner again", give tier 1 "a little bit more detailing", and put the small crystal diamond "on everything ... in its correct color". The border came out about 13% thinner. The crystal was misread as one on the top point.
- [thin-c](../design/art-direction/frame-lab/thin-c/sheet.jpg) ([tops close-up](../design/art-direction/frame-lab/thin-c/tops.jpg)): the owner clarified that the diamond is the one hanging under the top accent into the window, as on tier 3, and the one "added to the top" should go. Prompt: [glass-frames-thin-c.txt](../../tools/art/prompts/glass-frames-thin-c.txt).

The owner then said: "Take one. Okay, let's lock take one in. I'm happy with it. Send it to the other session." **The decided frames are take 1 of thin-c**: `frame-lab/masters/thin-c1/drop-1.png` (JPEG: [thin-c/take1.jpg](../design/art-direction/frame-lab/thin-c/take1.jpg)). This replaces the earlier take 1 above. The six frames are cut into [frame-lab/final/](../design/art-direction/frame-lab/final/) with [tools/art/frame_cut.py](../../tools/art/frame_cut.py).

Its window is bigger than the [art-space](../design/art-direction/frame-lab/art-space.md) spec, which was for the thicker border. Art should be made to the thin guide's window, which contains the drawn window on every tier: in 560 x 1000 units, (280, 52.5), (529.1, 188.4), (529.1, 811.6), (280, 947.5), (30.9, 811.6), (30.9, 188.4).

## Sharper frames (owner, 15 Nov 2026)

The first cut of the locked frames had "a lot of black stuff at the edges", so the cutter was rebuilt ([tools/art/frame_cut.py](../../tools/art/frame_cut.py)): the outer edge is the card outline fitted to the drawing, the window edge is smoothed, and soft edges take the frame's colour. The frames were still soft, because each was cut from a small slot on a six-card sheet and scaled up about 3.6 times. The owner: "If you can get a better result, try to do so and show it to me."

Each tier was then redrawn by Codex as one large card (about 1450 px tall instead of 560), with the locked sheet attached as the design to copy and a single-card outline guide ([prompt](../../tools/art/prompts/glass-frames-hires.txt)). Two takes; [close-ups](../design/art-direction/frame-lab/hires-closeups.jpg) and [overview](../design/art-direction/frame-lab/hires-overview.jpg). Take 1 matched the locked design most closely. The owner approved replacing the frames with it: "Yes, i approve".

The frames in [frame-lab/final/](../design/art-direction/frame-lab/final/) are now large take 1 (sources: `frame-lab/masters/hires1/tier1.png` to `tier6.png`, kept locally). Their windows sit inside the art window above, except tier 5's top corners, which reach up to 4.9 units past it, inside the art's 18-unit bleed.
