# Pass 2 checker brief: measurable defects only

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). Three screen concepts for Bramble (A, D, E) have been redrawn on the owner's new direction. A council of three voting members judges them. Your job is narrower: you are the checker. You find defects that can be measured or pointed at, and the voting members decide which of them matter. You have no vote, give no scores and no ranking.

Bramble is an auto-battler in the style of Hearthstone Battlegrounds, drawn in lead and stained glass. `docs/workstreams/ui-ideation/map/state.md` describes the game moment every picture shows.

## The owner's words (22 Nov 2026)

*[Transcribed from dictation: filler removed, punctuation added, clear mishearings fixed.]*

> "We've got, I think, tooltips for cards should be handled as on hover states, right? All this, the direction that Sol continually gave in a lot of these committees, I think, was pretty poor in terms of having all these tooltips on screen, especially having the front and back row labeled, right? The game needs to not be visually cluttered and telling experienced players what cards they recognize do is not what we want. And I've given the steering in the past, and I will continue to give it in future."

> "We will not, however, be showing our next opponent's board ever."

> "I feel like the tooltips should be hover states, like modals or toasts or whatever they're called. And keyword reminders should not be anchored or rendered in the same way as the tooltip that follows the cursor. They should go in some consistent part of the screen. Either they're at the top or the side or out of the way, essentially, like the keyword stuff, because [it's] an option that players can turn off in the settings, and even if they don't, it sits in some part of the screen the player can move their eyes towards that isn't the active state. So they're available but not obtrusive."

## Inputs

The renders, 1920x1080, in `/data/ui-ideation/concepts/<A|D|E>/`: `mid`, `first`, `fight`, `after`, `hover-shop`, `hover-board`, `hover-spell`, `keywords-off`, `cards`, and any `extra*` (`.png`). The source is `docs/workstreams/ui-ideation/concepts/<A|D|E>/concept.html`. Do not read `docs/workstreams/ui-ideation/council/`.

## In scope

Report only what you can measure or point at in a render:

- Two things overlapping, or one clipped by a frame or the screen edge.
- Text that overflows its box.
- Things meant to line up that are off, with the pixel difference.
- Text a player acts on (a number, a price, a button) under 18 px, or any text under 14 px, with the size.
- Text contrast under 4.5:1, with the two colours and the ratio.
- A unit card that is not a tall stretched hexagon, or art stretched out of proportion.
- A number or unit that contradicts `state.md`.
- The tooltip running off screen or covering the card it describes.
- The keyword reminders sitting in different places in different frames, or still visible in `keywords-off`.
- The next opponent's board shown anywhere.
- Text at rest on or beside a card that says what the card does, or a label naming a board row: report where it is. That is a defect under the owner's words above.
- A view missing or failing to render.

## Out of scope

Taste, layout preference, colour preference, and whether something is clear enough. Never propose adding text, labels, captions, names, reminders, legends, icons or explanation of any kind, at rest or anywhere else. If you think a player could not tell something, leave it out: the voting members judge that.

## Answer

At most eight items per concept, the worst first. Each item is one line: the view, the place (pixel coordinates), what is wrong, the measurement. No fixes beyond what the measurement implies. If a concept has none, write "none found".

Write your answer to `docs/workstreams/ui-ideation/council/p2r1-sol-check.md` and reply with it in full. Work read-only apart from that file and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/check-sol`; create it). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. End with a **Disk** line: anything you wrote besides your answer file, with path and size.
