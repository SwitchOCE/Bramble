# Pass 2 design brief: the owner has looked, and changed the direction

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). The owner looked at the three shortlisted concepts on 22 Nov 2026 and gave the direction below. Everything outside the quotation marks is my reading or my proposal. Where my reading and the owner's words differ, the words win.

This pass runs in short loops. The owner is awake and looks at every round directly, so a clear first cut in about 30 minutes is worth more than a polished one in two hours.

## The owner's words (22 Nov 2026)

*[Transcribed from dictation: filler removed, punctuation added, clear mishearings fixed. "Seoul" is read as "Sol", "CardA" as "card art".]*

> "We've got, I think, tooltips for cards should be handled as on hover states, right? All this, the direction that Sol continually gave in a lot of these committees, I think, was pretty poor in terms of having all these tooltips on screen, especially having the front and back row labeled, right? The game needs to not be visually cluttered and telling experienced players what cards they recognize do is not what we want. And I've given the steering in the past, and I will continue to give it in future."

> "We're too busy with the card frames, right? I told you to hold the card frame sacrosanct. I'm releasing you from that constraint. I want the stained glass to be kept, but I think I've gone too over the top with a lot of the visual indication in terms of rarity in the framings. And I give permission to make variations on that theme. The shape I still like. Spells can have a different shape. I could tell that agents struggled to make the spells work well, and the shape for spells is allowed to change."

> "What I liked from a lot of the design passes were a lot of the visual spacing and changes to the backgrounds. I think that's really good. But yeah, the colours are incredibly noisy because of partially how the card art is done, right? Which limits us in terms of the contrast we're able to generate and what draws the eye. The eye just doesn't know where to go in these images, because the cards are so bright and draw so much focus. I do think a lot of the other ideas are good."

> "I want more visual iteration, more loops here. I want to get more frequent feedback because I'm awake and it's not an overnight run. [...] It's enough of a change that I'm gonna enjoy looking at it and find it different."

> "We will not, however, be showing our next opponent's board ever."

> "I do not like a lot of the changes that were made to accommodate the spacing of the tooltips, and I still want to reiterate this: that I feel like the tooltips should be hover states, like modals or toasts or whatever they're called. And keyword reminders should not be anchored or rendered in the same way as the tooltip that follows the cursor. They should go in some consistent part of the screen. Either they're at the top or the side or out of the way, essentially, like the keyword stuff, because [it's] an option that players can turn off in the settings, and even if they don't, it sits in some part of the screen the player can move their eyes towards that isn't the active state. So they're available but not obtrusive. If a design can't be represented on one page, right, the agents are allowed to represent past a few frames or multiple screens to the council to represent hover states and explain how they would work."

## My reading of what changes

1. **Nothing at rest explains a card.** Take out the name plates, cue lines, rules text and effect captions on or beside cards, in recruit and in the fight, and the "Front row" / "Back row" labels. The screen is for a player in their hundredth game who knows the cards. What stays at rest is what that player needs to act and cannot infer: you decide what that is, and say why in your notes.
2. **Give back the room.** Undo layout changes that were made to fit those labels (cards shrunk, rows pushed, fixed reader panes) and spend the space on what the owner liked: spacing and the background.
3. **Card details are a hover state.** Hovering a card shows its details in a tooltip by that card. Draw it as its own frames.
4. **Keyword reminders are a separate thing in a fixed place.** They are not part of the tooltip and do not follow the pointer. They appear in one consistent, out-of-the-way part of the screen (top, side: your call), the same place every time, and a setting turns them off.
5. **The card frame is yours to change.** Stained glass and lead stay. The tall stretched hexagon for units stays. The tier and rarity ornament in today's frames is too much: propose a calmer frame, and how it tells tiers apart. You may draw frames in SVG or CSS. Spells may take another shape.
6. **Give the eye an order.** Today every card is bright and nothing leads. Decide what a player should see first, second and third on each screen, and make the screen do that. Today's card art files are what you have; how the art is framed, matted, lit or dimmed on screen is yours to change. A change to how card art is painted is a labelled suggestion only.
7. **Never show the next opponent's board.** Their name and health are fine.
8. The theme (woodland animal folk, fairies, oozes) holds. Rules and flow changes stay labelled suggestions.

## What to do

Keep your concept's idea, background and spacing. Change it as far as the direction above asks, and do not hold back: "enough of a change that I'm gonna enjoy looking at it and find it different."

In your `concept.html`, keep the four views (`?view=mid|first|fight|after`) and add:

- `?view=hover-shop`: mid-game, the pointer over a shop unit that has keywords. The tooltip, and the keyword reminders in their fixed place.
- `?view=hover-board`: the pointer over one of your own board units near an edge of the screen, to show where the tooltip goes when room is short.
- `?view=hover-spell`: the pointer over a spell.
- `?view=keywords-off`: `hover-shop` again with keyword reminders turned off.
- `?view=cards`: a close-up sheet of your frame. One unit per tier (1 to 6) at rest, a golden unit, a spell, and one unit hovered, at the size they have on the board and at twice that size.
- Any further frame you need to explain a state. Number them `extra1`, `extra2`.

Then:

1. Render every view at 1920x1080 into `/data/ui-ideation/concepts/<your letter>/`, over the old files. The pass-1 renders are kept in `p1-final/` there: leave them. Open every render and look at it. Run the visual quality pass from `briefs/04-designer.md` on each, with one change: the 18 px floor applies to text a player acts on, and removing text is a better fix than shrinking it.
2. Add a section "Pass 2, round 1" to `notes.md`, 250 words at most: what a card shows at rest and why; the order the eye should take on the mid-game screen; your frame and how it tells tiers apart; where keyword reminders live; any earlier owner decision you reverse (by row number in `owner-decisions.md`); your suggestions.

## Rules

As before: write only in your concept folder and `/data/ui-ideation/concepts/<your letter>/`; no commits; `TMPDIR=/data/ui-ideation/tmp/<your letter>` (create it); never run a delete command anywhere, list what should be removed; never read token or `auth.json` files; start no subagents; do not look at another designer's folder or renders. From stills, motion, timing, hover feel and sound are "not judged": describe how a hover should behave, do not claim it feels right.

## Report

Reply with, in under 200 words: what changed, the paths of the renders, anything you could not do, and a **Disk** section (every folder you wrote into outside your concept folder with its `du -sh` size, and what can be deleted).
