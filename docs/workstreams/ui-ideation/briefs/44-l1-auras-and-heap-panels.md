# L1: the panel that shows all your auras, and the panel a heap opens

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). For the art director of look L1. A design with a mock-up page; you write no game code.

## Where things stand

The buy screen of your look is now built in the game (steps 1 to 4 of `docs/workstreams/ui-ideation/build-plan-l1.md`) and the owner has the first build to play. A real screenshot: `/data/ui-ideation/build/step4/buy.png`. The mock-up it was built from: `/data/ui-ideation/looks/L1/c/c8-spec.png`.

In the right column the counters are glass medallions, at most four. Two things they lead to have no design in this look:

- **The auras panel.** When a player has more counters than fit, a small plate under the medallions shows how many there are and opens "all your auras". Today nothing opens: the panel does not exist, and the plate is hidden.
- **A heap's panel.** A counter that is a heap (Compost: the units that have died) opens a panel of its contents when pressed. Today that is the old build's Compost panel (`src/screens/compost/` on the branch `ui/l1`; you can read the game at `/data/worktrees/ui-l1-step1`, read-only), which is fixed rectangles in the old style.

## The owner's words

24 Nov 2026:

> "Remember, Tide is not always going to be a mechanic. We just need some way of handling any number of other mechanics, like whatever your most important counter is determined to be. Other tribes will also have counters at some point. There may be other counter mechanics. You just need a way of being able to view all your auras, so it shouldn't be like a Tide button. It's more of a generalized thing. Same for Compost: it's a mechanic that may only be in some lobbies."

25 Nov 2026:

> "We don't have to contain everything on the static screens. We have modals as well ... it doesn't all need to be one screen, and some things can be housed on other screens ... We need to be less focused on how everything fits into one screen and being willing to handle overflow with modals. Or toasts."

> "Only your highest counters or most recently changed things could show up ... It's fine to have something and X more and you click on a button and it pops out a modal or a tooltip, right? ... That's the exact kind of solution I'd expect to see."

> "The pop-up just can't be anchored to the tooltip of the card. I think it's fine going on the left column or the right column because they're overlays." (of hover details; it tells you the owner is content for overlays to cover the columns)

Standing rules from the owner: the main screen assumes a player who knows the rules, so numerals and clear icons and very few words, with detail on hover; no dimming filters over card art; of cards in the hand, "it's a non-negotiable that the cards are the same size ... because you need to be able to drag them around" (the orchestrator's reading, not the owner's words: a panel that only lists cards, with nothing to drag, is not bound by that, but shrinking cards is not free, so say why if you do); glows are engine lighting effects, so draw none that the design depends on; "Don't be too stringent. We're trying to do good design, right? That's the number one priority."

## The problem

Design the two panels as one family, in your look, so that a player mid-turn can open one, read it and close it without losing their place.

Things a good answer has to cope with, none of them a design:

- The auras panel has to be general: it lists whatever is affecting the player in this lobby. Today that is at most Compost and Tide. Read the game to see what else already exists that a player would call "affecting me" (look at what the state gives the screen: counters, board slots with buffs, keywords such as Renown, and anything else you find), and say what you think belongs in the panel and what does not.
- From two entries to a dozen. A number of one digit and of three. An entry that is a heap (it has contents) and one that is only a level.
- A heap's panel: from empty to a few dozen units, some of them the same unit several times, some golden.
- Where the panel sits and what it covers. The player may want to see their board or the shop while it is open; argue it.
- How it opens and closes (motion is not judged from stills; write what you intend).
- The words on it. As few as the design can carry.

## What to make

1. A self-contained page `docs/workstreams/ui-ideation/looks/L1/panels/panels.html` that draws, at real size on the built screen's screenshot as its ground (`/data/ui-ideation/build/step4/buy.png`), the auras panel and the heap panel, each in its hard cases (few and many entries; an empty and a full heap). Use the painted pieces in `/data/ui-ideation/looks/L1/pieces/` where they fit, or draw in code; name any piece you would want painted. If you see two clearly different good answers, show both and mark your pick.
2. Pictures of the page's states in `/data/ui-ideation/looks/L1/panels/` (render with `/data/ui-ideation/tools/l1-scripts/render.sh` if it suits, or headless Chrome as in `briefs/37-counter-display.md`). Look at each at full size and fix what you see before you report. Check that every numeral can be read.
3. Notes `docs/workstreams/ui-ideation/looks/L1/panels/panels.md`, 300 words at most: what goes in the auras panel and why, each panel in a few lines, your pick where you showed two, what you could not solve.

## Rules

Write only inside `docs/workstreams/ui-ideation/looks/L1/panels/`, `/data/ui-ideation/looks/L1/panels/` and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/look-L1`). Change nothing in `/data/worktrees/ui-l1-step1`. No commits and no other git commands that change anything. Never run a delete command. Never read token or `auth.json` files. Start no subagents. Make no pictures with an image model. From stills, motion and hover feel cannot be judged: write "not judged".

## Report

Under 150 words: the two panels, what the auras panel holds, your pick, what falls short, and a **Disk** line (what you wrote outside the repo, with sizes).
