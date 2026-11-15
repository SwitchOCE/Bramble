# Plan: dialling in the stained glass direction (v2, after an independent check)

<!-- status -->
- **In short:** Card art now has a process you like: a loose prompt, made to the shape of the frame's window, with the frame laid on top. It is written up as a recipe you approved. Card frames are locked in their own plan. Screen changes still wait on your list.
- **Status:** active
- **Last step done:** The card art recipe was approved and merged into the stained glass branch (PR 56, 16 Nov 2026).
- **Next step:** A fresh agent makes cards from the recipe alone, to check it stands on its own.
- **Waiting on you:** What the "few more things" in the UI are, and which spacing you want locked.
<!-- /status -->

Status: approved by the owner, 15 Nov 2026. Asked "Approve the smaller plan, with card frames and UI first?", the owner said: "Yes, approve it".

## The problem, in the owner's words (15 Nov 2026)

"We are doing this stained glass lead thing. This is where the game is going now. ... what I want to do now is create a plan with you to dial in art reference and art direction and guidelines to pursue this direction fully. ... what we need to do is get ready to lock in a bit more about how the card frames and stuff will look and a bit more of the spacing. The UI is very close, so I just want to refine a few more things."

## What changed from the first draft

A fresh agent checked the draft against the owner's words. It found that the draft put the two things the owner named, card frames and the UI, behind a day and a half of reference and style work, that it had no step for spacing, and that several items were the agent's additions. This version puts the owner's asks first and shrinks or defers the rest.

## Steps

Art is made by Codex. Agents are Opus. Each step ends at a decision by the owner.

1. **Ask the owner (today).** What the "few more things" in the UI are, and which spacing they want locked. Steps 2 and 3 do not start on guesses.
2. **Card anatomy.** *[Editor note, 15 Nov 2026: the card frames part of this step moved to its own plan, [glass-frames.md](glass-frames.md), where the owner locked the frames.]* Start from the mock-up's card sheet (`scratchpad\concept\glass\cards.png`) *[Editor note: a copy is in the repo at `docs/design/art-direction/examples/glass-cards.jpg`; the full working files are on the Optiplex at `/data/bramble-art/stained-glass/glass/`.]*. Make variants only where it is weak or unsettled: a tier cue that works without colour at game size, the Ring slot's colour (it is close to End turn's amber), roundel size and place, and two states not yet drawn (can or cannot afford; selected or held). Check number and tier contrast with the repo's accessibility-review skill. The owner locks it; it is written up as a spec with measurements.
3. **Screen refinements, alongside step 2.** The owner's list plus spacing, on the frozen layout. The owner locks it; it is written up as a layout spec.
4. **Style rules, alongside steps 2 and 3.** *[Editor note, 15 Nov 2026: the trials and style rules in this step are replaced. Two rounds of trials were run, and the owner preferred the first loose-prompt picture to all of them. The owner then asked for the process that made it to be kept as it is: "I just want the existing process captured. I don't want it changed. If previous stuff I've said overrides it, call it out like that. And let's get rid of it because it's wrong. This process is producing what I like." So no style rules are written. The process is in [../design/art-direction/card-art-recipe.md](../design/art-direction/card-art-recipe.md). The reference board was made and is on the Optiplex, for study only. The two owner rules at the end of this step still hold.]* A small reference board (about ten real windows, study only, never in git) and a list of what Codex gets wrong against real glass. Side-by-side trials on the same two fighters for the three open questions only: painted detail or lead and colour only; lead weight; glass texture and glow. Two things are already the owner's and are written in as rules, not trialled: fighters are warriors shown full body, not cute or zoomed in; each tribe's glass shows its biome.
5. **Guide, then a blind test.** The guide goes in `docs/design/art-direction/` through a PR the owner approves, with prompt recipes in `tools/art/`. A fresh agent given only the guide redraws four to six existing units. The owner judges whether they match. If not, fix the guide, not the pieces.

## Deferred, with what would bring each back

- A fight screen in glass: when the owner asks for it.
- New window architecture (tracery, side-light contents): only if it is on the owner's list.
- Card states beyond afford and selected: when the rulebook names one.
- A design critique of the blind-test results: if the owner wants a second opinion.

## Checkpoints

- After step 2: are the card frames locked?
- After step 3: is the UI done?
- After step 5: are the guidelines good enough to carry the direction?

## Open, not blocking

Whether "the setting" means the look only, or the game's world too.
