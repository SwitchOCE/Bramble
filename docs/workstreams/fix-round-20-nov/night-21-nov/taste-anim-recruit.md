# Taste log: the recruit batch of animations (plan step 12), night of 21 Nov

Made by the animation worker while the owner slept. Each entry is a call the accepted prototypes (`docs/design/mockups/fix-round-20-nov/anim-recruit/`) left open, or a place where the game differs from them. None of these is the owner's decision. The prototype was not changed to fit the build.

Code: `src/glass/glass_motion.gd` (the prototype's easings and paths), `src/glass/glass_timeline.gd` (its timeline), `src/screens/recruit/recruit_motion.gd` (the batch), with small changes in `recruit_board.gd`, `recruit_input.gd`, `recruit_shop.gd`, `recruit_waiting_pile.gd`, `recruit_turn_start.gd` and `recruit_screen.gd`.

## Shared

**1. How to copy the prototype's easing.**
- Deciding: the prototype runs Web Animations, where one easing bends a whole run of keyframes and each pair of keyframes is joined in a straight line; its flights instead bend the place along the path and run linear in time. The build's tweens did neither exactly, so the same numbers moved differently.
- Weighed: Godot's own Tween transitions (close, not the same curves); re-creating both rules exactly.
- Chose: exact copies. `GlassMotion.bezier` solves the same CSS cubic-bezier curves (out .2,.8,.2,1; inout .45,0,.25,1; in .55,0,.9,.45), `keyframes` joins keyframes straight on the bent progress, `flight` copies `fly()` (named curve on the place, arc `lift·4k(1−k)`, lean `lean·sin πk`).
- Rests on it: every animation in this batch, and the fight batch can use the same two files.

**2. When a move starts: the click, or 40 ms after.**
- Deciding: the prototypes press a button at one moment and change the state 40 ms later; the game gets its new state when the click is let go, so there is nothing to wait for.
- Weighed: start everything at the let-go; keep the prototype's 40 ms gap between the button's own press and the rest.
- Chose: the button's press plays from the let-go, everything else 40 ms later, so the relative timing is the prototype's.
- Rests on it: refresh and tier-up.

**3. A press finishes any of these moves at once.**
- Deciding: the prototype only says the start-of-turn queue can be cut short by a press (NOTES "Needs a person to judge" 5). The new moves are 0.3 to 0.75 s.
- Weighed: let them run under the player's next press; finish them.
- Chose: finish them, as the start-of-turn queue and the triple already do, so a card is never carried while it is still moving somewhere else. Hover detail waits until a move is over.
- Rests on it: a fast player sees moves snap to their end; the owner should feel this.

**4. Gold counts down for every spend, not only the batch's.**
- Deciding: the prototype counts gold down for buys (18, 19), refresh (24) and tier-up (26). The counter is one piece, so counting for some spends and jumping for others would be odd.
- Weighed: count only in tonight's actions; count every spend.
- Chose: every drop in gold within a turn counts down over 0.26 s and dips the gold button (buy to hand too, and an Active's cost). Gains are unchanged (the sale's coin is not tonight's).
- Rests on it: the sell batch, when built, adds the count-up.

**5. The price tag travels with a carried shop card, pending the owner.**
- Deciding: the two sources the owner approved disagree. The buy-to-board mock-up (`recruit/NOTES.md` §2, item 2): "The price coin travels with the card, so you see what you'll pay". Prototypes 18 and 19: the tag drops off when the card is lifted.
- Chose: nothing; only the owner can. Until they do, the build keeps what they approved and have on dev: the tag is hidden at the press and comes back on the card once the press is a drag, so a plain click looks as before.
- The switch: `RecruitInput.SHOP_TAG_TRAVELS` in `src/screens/recruit/recruit_input.gd`. Set it to false for the prototype's drop: the tag falls 14 px as it fades over 0.14 s, easing in, left where the card was (`RecruitMotion.drop_tag`). `test_recruit_drag` checks whichever the switch says.

**6. Lit slots fade as the card is let go.**
- Deciding: prototypes 19, 32, 39 and 41 fade the lit slots over 0.15 s (ease in) at the let-go; the build dropped them at once.
- Weighed: fade only after a successful drop; fade on every redraw.
- Chose: every redraw fades the slots' rims (a refused drop too). Rims on cards (targets being chosen) still go at once, as no prototype fades them.
- Rests on it: nothing else.

## Buy to board (prototype 19)

**7. The drop and hop stay the build's own.**
- Deciding: prototype 19 says "Same as playing a unit: drop 4 to 6 frames, hop 0.2 s", and NOTES says the build's own motion is the reference for re-created moves. The prototype's re-created drop (90 ms, ease in) and hop (peak at 45%) differ a little from the build's (4 to 6 frames eased out, a sine hop of 12 frames).
- Weighed: copy the prototype's re-creation; keep the build's.
- Chose: keep the build's drop and hop; add what the prototype changes: the tag (5), the lit slots fading (6), the gold counting down (4).
- Rests on it: playing a unit and buying onto the board feel the same, as the prototype asks.

## Swap (prototype 39)

**8. The preview is the owner-approved swap look, with the prototype's lift.**
- Deciding: the owner approved `recruit/swap.html` and `recruit/NOTES.md` §3: "An occupied slot under the card lights a cool blue instead, so a swap never looks like a plain play. The unit standing there dims and lifts toward the hand, and a pale copy of it waits in the gap the hand card left." Prototype 39 adds the motion: "that unit lifts a little to show it will move" (12 px up, to 0.94, 0.14 s eased out). The prototype page shows only how things move (`anim-recruit/index.html`: "these show only how they move"), so it does not replace the look.
- Chose: both. The occupied slot's rim is blue (`RecruitBoard.SWAP_BLUE`), the pale copy waits in the hand gap (`SwapGhost`), as PR 241 built them. The unit itself lifts as the prototype does (not a copy drawn in its place, as PR 241 had), and dims to PR 241's blue tint (`RecruitMotion.SWAP_TINT`) where the prototype dims it grey to 0.85. Let go, it flies into the hand from the lifted place and clears from the blue on the way.
- Rests on it: `test_recruit_drag` checks the blue rim, the hand copy, the lift and the tint.

**9. Moving off the slot puts the lifted unit straight back.**
- Deciding: the prototype never shows the pointer leaving.
- Weighed: ease back over 0.14 s; snap back.
- Chose: snap back. It keeps the unit's resting place exact for the next hover and drop with no second tween to cancel. A close call: if it reads as a flicker, an ease back is a few lines in `RecruitBoard.clear_drop_preview`.
- Rests on it: nothing else.

**10. The unit that leaves hops with the prototype's hop, the one that arrives with the build's.**
- Deciding: the arriving card is a let-go card (the build's drop and hop, as 7); the leaving one is not let go, so it needs its own flight and hop.
- Weighed: the build's sine hop; the prototype's hop (peak at 45%, ease in-out).
- Chose: the prototype's flight (0.28 s, 120 px arc, "arrive" curve, leaning −6°, dimming back over 0.2 s) and its hop, both from `GlassMotion`. The two hops differ by about a pixel at their peak.
- Rests on it: nothing else.

## The waiting stack (prototype 41, and 40's count)

**11. The stack stays where PR 232 put it; the motion follows the prototype.**
- Deciding: the prototype's stack is marked PROPOSED (70% cards right of the hand). The build's (PR 232) is full-size cards turned 9° at (1380, 972), mostly below the sill, with a "+N" chip.
- Weighed: move the stack to the prototype's place; keep it.
- Chose: keep it (NOTES says another item may decide its place and look; this one is motion). The slide is the prototype's: the joining card leaves the stack 0.12 s after the let-go, arcs 40 px over 0.32 s (in-out) and hops; the rest of the hand closes round the played card in 0.2 s and opens again from 0.2 s over 0.22 s; "Hand 6/7" then "Hand 7/7" as it lands. Its stack tint fades to clear on the way. A card deeper than the three drawn starts from the top of the stack (replaces PR 232's `arrive_from` flight for those). A card that joins and is at once held up to choose its Recruit target does not slide: it stands where it is held, as PR 232 had it.
- Rests on it: a later move of the stack needs no motion change; the flight starts wherever the card is drawn.

**12. The count chip.**
- Deciding: the prototype only shows the last card leaving (the count shrinks away, 0.16 s, ease in) and a card arriving (the count pops in from 1.8 times, 0.26 s, eased out, as the card lands).
- Weighed: pop on every change; only those two.
- Chose: those two. When cards remain after one joins, the number just changes.
- Rests on it: nothing else.

## Refresh (prototype 24)

**13. Every place sinks and drops in, even one that rolled the same card.**
- Deciding: the build keys shop cards by place and card, so a place that rolled the same card did not move (the prototype's "Now" calls that out).
- Weighed: move only changed places; move all.
- Chose: all: the old shop sinks card by card (25 ms apart, 24 px to 0.94 as it fades over 0.15 s, ease in; tags fade over 0.1 s) and the new one drops in (from 40 px up at 1.04, 4 px past at 90 ms, settled at 220 ms, eased out, 50 ms apart from 0.18 s), each tag swinging in from −28° through 10° 0.14 s after its card. The "N left at this price" line pops (1.15 and gold, 0.3 s) and the gold counts down.
- Rests on it: the start-of-turn new shop (prototype 10) can reuse the same two moves.

**14. Spells' turn in the sink and the drop.**
- Deciding: the prototype has five units and two spells; spells sink after the fifth unit and drop in beside the middle units. The game's shop has 3 to 5 units.
- Weighed: the prototype's fixed numbers; after however many units there are.
- Chose: spells sink after the last unit (25 ms on per spell) and drop in on the prototype's numbers (the gap they hang in: 50 ms times that gap, plus 20 ms).
- Rests on it: nothing else.

## Tier up (prototype 26)

**15. The button's flash and the tiers rolling over.**
- Deciding: the prototype brightens the button 1.7 times with a warm drop-shadow glow and rolls the tier numbers over on their horizontal axis (a 3D turn). The glass button has no glow filter and Godot's 2D has no 3D turn.
- Weighed: a shader for each; plain stand-ins.
- Chose: the brightening and swell (to 1.06 at 30%, 0.42 s eased out) without the glow, and the roll as the line squashing to nothing and opening again (its height times the cosine of the turn: 0.11 s in, then 0.18 s out). The cost coin changes when the line turns over.
- Rests on it: the owner should look at the flash on a real screen.

**16. The sweep of light.**
- Deciding: the prototype's band is a horizontal gradient (clear, rgba(255,236,180,.6), clear) screened over the shop and blurred 8 px.
- Weighed: a texture; a small shader.
- Chose: a shader, added on top (close to "screen" on a dark window), its top and bottom edges softened to stand for the blur. 260 px wide, the card's height + 60, from 300 px left of the shop across its width + 340 px, 80 ms after the click, over 0.48 s in-out, showing over its first and last fifth.
- Rests on it: on a bright card the band may look stronger than the prototype's.

**17. At the top tier.**
- Deciding: the build draws no tier-up button once there is no next tier.
- Chose: the last tier-up plays the sweep and the gold count only.

## Start-of-turn effects (prototypes 12, 13, 14 and 17)

**18. Kept PR 221's queue; matched each effect's curves and pieces.**
- Deciding: PR 221 already plays Grudge, Relic Seeker and Old Campaigner at the start of a turn in the prototype's order and gaps (0.42 s, each gap 0.86 of the last). Its pieces were close copies with straight-line segments.
- Weighed: rebuild on the new timeline; correct in place.
- Chose: correct in place, no change to which effects play or when. The Grudge gain now runs its keyframes (0, 90, 330, 430 ms) under one ease-out as the prototype does; the ring is 4 px with a glow and runs the prototype's keyframes; the gain pill is the prototype's green glass (44 px, 26 px figures); the Relic Seeker's coin is a plain coin with "+N" beside it and flies to the coin on the gold button, not the button's middle; the Renown star is the prototype's 60 px gold disc (gold from its upper left, a 3 px dark rim, a warm glow, the star in dark line) with its "+N" at its lower right, where it was the pale Renown keyword icon; the Renown pill pops down from 1.7 (it grew and shrank before); the Grudge mark and the gold button brighten as they swell.
- Rests on it: step 8 (Grudge N, the rules move) changes no motion.

**19. Where Grudge's gain rises from.**
- Deciding: the prototype starts the gain at a fixed point low on the card (where its mock-up draws the mark); the build draws the Grudge mark where the keyword layout puts it.
- Chose: from the real mark, as PR 221 did (the prototype says "rises from its Grudge mark").
