# Plan: card frames for tiers 1 to 6 (part of step 2 of the glass dial-in)

<!-- status -->
- **In short:** Codex is drawing the first ladder of card frames, tier 1 to 6, with an empty window.
- **Status:** active
- **Last step done:** The plan was approved (15 Nov 2026).
- **Next step:** Step 1, the first ladder, then a checkpoint with you.
- **Waiting on you:** Nothing yet.
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
