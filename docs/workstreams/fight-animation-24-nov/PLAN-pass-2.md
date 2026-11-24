# Fight animation, pass 2: plan (24 Nov 2026)

Follows `PLAN.md`. Same branch, same limits: nothing reaches `dev` or `main`; what is built into the game is the owner's call.

## The owner's words (24 Nov, after watching the page; dictated, filler removed)

> "I think I like this honestly. It's very hard for me to tell, like I notice small differences, right? And the quad ease-in of the speed along the strike, I noticed a difference. I noticed a difference in terms of where stuff stops. I think I prefer shallower, right, it's like less into the card, in terms of decision two: the shallow stuff or the medium stuff, maybe C *[probably "B", the medium option]* is good. I'm not sure, it's tough. Galaxy's past-centre thing is too much for me. I think I like your proposals."

> "One thing that I would definitely like to see is the card to rotate more. I feel like the card should tilt or rotate to point at what it's hitting, right? At least on the flat axis. I think in Battlegrounds maybe they even do some z-axis stuff rather than just x-y, or maybe it's y-axis rather than x-z, I can't remember what the term is in 3D. But the point is that it gives a more 3D feel because the thing actually rotates a bit. I think we need to introduce some form of rotation at least. The sharp point of the bottom of the hex should probably rotate towards the thing it's hitting. That should probably happen maybe during the wind-up and the speed-up phase. I'm not sure exactly when; you should investigate that and come up with proposals to try to improve it."

> "In terms of how to communicate one trigger many times, I do like the proposal a lot. I think we should probably borrow from fighting games in terms of the combo. I like the cumulative damage. Maybe we could have like a ×11 if something triggers 11 times, and you can see the cumulative damage. But you also get this little hit splat whenever the speed-up triggers and you're getting multiple instances of something stacking: a little fighting-game-esque hit splat coming up."

> "Take those into consideration as ideas. These aren't a firm steering. I don't know what's right. I'm just trying to give you my guesses as to what's wrong, because it doesn't feel right yet. My answers are not necessarily the right way, but they are something you should look into."

So: ideas to investigate, not specs. The test is whether the fight feels right, not whether these exact suggestions are built.

## Three threads

1. **Rotation (the main one).** The card turns to aim at its target. Questions to answer with evidence: does Battlegrounds rotate in plane, tilt in 3D, or both, and when (lift, hold, strike, return)? How far? Which point of our hexagon leads? Our cards face up whichever side they're on, so for an attack upward the leading point is the top one; *[the owner said "the bottom of the hex"; to check with the owner which point he means, shown on a picture]*. Can Godot 2D fake a 3D tilt on our glass card (a perspective shader, a squash)?
2. **Stop depth.** The owner leans shallower (A or B). Rotation changes how depth reads (a tilted tip reaches further), so stop depth gets re-filmed with rotation on, not decided alone.
3. **Combo look.** A fighting-game combo: a "×N" count with cumulative damage, plus a small hit splat per stacked hit. These are new visual elements, so they get a proper visual pass (owner rule, 22 Nov): a reference study (fighting games and others), an art director in lead and stained glass, generated art, review, then pictures to the owner for a yes before anything is filmed with them.

## Steps

1. **Measure rotation** (one agent): Battlegrounds and Galaxy footage still on disk (`/data/fight-anim-ref/`): in-plane angle and any 3D tilt per frame through lift, hold, strike, contact, return, for near and far targets. Plus Godot feasibility of a fake 3D tilt on our card shader.
2. **Rotation and depth treatments** (one builder, on the clip branch): two or three rotation options (e.g. in-plane aim only; in-plane plus a fake 3D tilt; aim timing during lift vs during strike), each filmed with stop depth A and B. Side-by-side clips, aligned, measured against claims, as before. A picture first showing which hexagon point leads, to confirm with the owner.
3. **Combo visual pass** (in parallel): reference study and art direction, then generated pictures of a ×N counter with cumulative damage and a hit splat in the glass style. Pictures to the owner. Only after a yes: filmed on CB7's ten-hit fight.
4. **Page update** with the new clips and pictures; report.

No council in this pass (the owner asked for one, and it ran). Each code step still gets its checks and a scope review.

## What no agent can check

Whether rotation makes it feel more 3D, or whether a combo counter feels good. Pictures and films are checks of what is drawn; feel is the owner's.

## Changed after the plan review (24 Nov)

A fresh agent questioned this plan. Taken:
- Rotation measuring shrinks to what is missing: Galaxy's wind-up tilt is already measured (24–40° on diagonals); Battlegrounds' angle was searched but never saved, so the tracker is re-run with it saved, and 3D tilt is read from stills.
- No shader study up front: `src/screens/card_carry.gd` already leans the card and narrows it to fake a turn (tuned by the owner, 17 Nov). Rotation options start from that; a perspective shader only if that proves too flat.
- Stop depth: film rotation at B (medium), with A (shallow) the only alternative; today's 0.62 and Galaxy's past-centre stop are dropped.
- The hexagon-point question goes to the owner now, with a picture, before anything is built.
- Rotation clips go to the owner as soon as they exist, not with the combo pictures.
- Open for the owner: which hexagon point leads; whether the hit splat shows on every repeated hit or only once the combo speeds up; whether the strike curve stays constant.

## The owner's second reply (24 Nov, dictated, filler removed)

> "Additional feedback as well is that I don't see all the animations. When you give a video clip of seven things side by side, it's very hard for me to pinpoint. Maybe build some sort of tool that lets me pick just two animations to compare, and I can slow or speed them up in the video viewer. I'm not sure if that's possible. Investigate and get back to me, or have a sub-agent investigate."
> "The videos are not aligned well in the artifact page. They go off to the side."
> "I think our animations for non-hits are potentially pretty poor. When Brock gets stats it's very hard to tell what happened. I should at least get something numerical to communicate that. I should be focused on the part of the card that's changed. How many stats did Brock gain from the card dying? … When we look at the two Gleaners triggering next to one another, they start off slower, then speed up more as the sequence continues. But I don't get that same feeling in number six, where a bunch of units die: all six cards play their dying animations at once, which is fine I guess, but if we had some way of staggering them a little bit, even though game-wise they died simultaneously, it would feel more realistic if they dropped off one at a time, and more impactful. How does Battlegrounds handle multiple units dying at the same time? … That's another thing I'd like to investigate."
> "I do think that we need to do buff animations way better. When something gets additional stats, we need animations for that, and they need to feel clear and interesting. We shouldn't just draw from Battlegrounds in this regard, because I don't think it does it particularly well."
> "In terms of the question, I agree: it changes for your board and their board. The bottom of their card attacks yours, and the top of yours attacks theirs. The hit splat stuff, I'm not sure of the answers. The strike speed that speeds up, yeah, I did like that. I didn't realise we're already doing it; maybe even a slower speed-up would be better, I'm not sure, it's hard to tell until I see it. … The constant, linear stuff, I noticed that was very bad. I didn't like that."

## Threads added

4. **A comparison viewer on the page:** pick a decision, pick any two options, play them side by side in sync, slow or speed them, step frame by frame. Needs one clip per option (builder). Page layout bug fixed (a margin rule cancelled the centring of wide clips).
5. **Strike speed:** the owner liked the speed-up into contact and disliked constant speed. Constant is dropped; options become today's strong speed-up, the mild one, and a gentler one, filmed with rotation.
6. **Several deaths at once (R5):** measure how Battlegrounds and others show a board of deaths; options for staggering falls (order, gaps, accelerating like the combo); film on the fixture's six-death moment.
7. **Buff animations (design job):** reference study beyond Battlegrounds; three treatments that draw the eye to the changed stat and show the amount; parts using existing pieces are filmed, new pieces (a floating +N, a disc flare) go to the owner as pictures first.
8. **Leading point: settled.** The point facing the target leads: the top of your cards, the bottom of theirs.
