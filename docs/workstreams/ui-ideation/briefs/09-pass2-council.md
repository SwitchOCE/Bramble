# Pass 2 council brief: one short pass per round

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). The owner looked at three screen concepts for Bramble (A, D, E) on 22 Nov 2026 and changed the direction. The designers have redrawn them. You are one of three voting members of a new council for this pass: two separate Claude Opus members with different lenses, and Gemini Neon. A fourth agent (GPT Sol) checks measurable defects only and has no vote.

This is one short pass: one answer from you, no discussion rounds. The owner looks at the same pictures at the same time, and the owner's reactions outrank the council's. Everything outside the quotation marks is my reading or my proposal; where it differs from the owner's words, the words win.

Bramble is an auto-battler in the style of Hearthstone Battlegrounds, set in a woodland of animal folk, fairies and oozes, drawn in lead and stained glass. `docs/workstreams/ui-ideation/map/state.md` describes the game moment every picture shows.

## The owner's words (22 Nov 2026)

*[Transcribed from dictation: filler removed, punctuation added, clear mishearings fixed.]*

> "We've got, I think, tooltips for cards should be handled as on hover states, right? All this, the direction that Sol continually gave in a lot of these committees, I think, was pretty poor in terms of having all these tooltips on screen, especially having the front and back row labeled, right? The game needs to not be visually cluttered and telling experienced players what cards they recognize do is not what we want. And I've given the steering in the past, and I will continue to give it in future."

> "We're too busy with the card frames, right? I told you to hold the card frame sacrosanct. I'm releasing you from that constraint. I want the stained glass to be kept, but I think I've gone too over the top with a lot of the visual indication in terms of rarity in the framings. And I give permission to make variations on that theme. The shape I still like. Spells can have a different shape. I could tell that agents struggled to make the spells work well, and the shape for spells is allowed to change."

> "What I liked from a lot of the design passes were a lot of the visual spacing and changes to the backgrounds. I think that's really good. But yeah, the colours are incredibly noisy because of partially how the card art is done, right? Which limits us in terms of the contrast we're able to generate and what draws the eye. The eye just doesn't know where to go in these images, because the cards are so bright and draw so much focus. I do think a lot of the other ideas are good."

> "We will not, however, be showing our next opponent's board ever."

> "I do not like a lot of the changes that were made to accommodate the spacing of the tooltips, and I still want to reiterate this: that I feel like the tooltips should be hover states, like modals or toasts or whatever they're called. And keyword reminders should not be anchored or rendered in the same way as the tooltip that follows the cursor. They should go in some consistent part of the screen. Either they're at the top or the side or out of the way, essentially, like the keyword stuff, because [it's] an option that players can turn off in the settings, and even if they don't, it sits in some part of the screen the player can move their eyes towards that isn't the active state. So they're available but not obtrusive. If a design can't be represented on one page, right, the agents are allowed to represent past a few frames or multiple screens to the council to represent hover states and explain how they would work."

## Inputs

- The brief the designers worked from: `docs/workstreams/ui-ideation/briefs/08-pass2-designer.md`.
- Each concept: `docs/workstreams/ui-ideation/concepts/<A|D|E>/notes.md` (the newest "Pass 2" section) and `concept.html`.
- The renders, 1920x1080, in `/data/ui-ideation/concepts/<A|D|E>/`: `mid`, `first`, `fight`, `after`, `hover-shop`, `hover-board`, `hover-spell`, `keywords-off`, `cards`, and any `extra*` (`.png`). Look at every one at full size. The end of pass 1 is in each folder's `p1-final/`, for comparison only.
- Do not read `docs/workstreams/ui-ideation/council/` from pass 1 (files starting `r1` to `r5`): that council asked for the on-screen labels the owner has now rejected.

## What to answer

For each of A, D and E, in 300 words at most:

1. **Against the owner's direction.** At rest, is anything left on screen that explains a card or labels a zone? Name it by view and place. Does the hover tooltip work as a hover state, and do the keyword reminders sit in one fixed, out-of-the-way place across the hover frames? Is the frame calmer, and can tiers still be told apart? Is the next opponent's board shown anywhere?
2. **Where the eye goes.** On `mid`, what do you see first, second and third? Is that the right order for a player choosing what to buy?
3. **Defects.** At most five, each with the view and the place: overlap, clipping, misalignment, text too small to act on, weak contrast, a card stretched out of shape.
4. **Next round.** At most three changes, the most important first.

Then, once:

5. **Rank** A, D and E as they stand now, with one line of reason each, and name the one idea from each that the others should borrow.

A rule for every item you write: never ask for more text, labels, captions, names or reminders on screen at rest. If a player in their hundredth game could not tell something they need, say what they could not tell and leave the fix to the designer.

From stills, motion, timing, hover feel and sound are "not judged": say so; never pass them.

## Rules

Write your answer to the file named in your task message and reply with it in full. Work read-only apart from that file and your scratch folder (`TMPDIR` in your task message; create it). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. Do not read another member's answer file. End with a **Disk** line: anything you wrote besides your answer file, with path and size.
