# L1: art for each zone of the buy screen, at the game's own card ratio

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). For the art director of look L1. This is a picture order only: you write it, a separate worker paints it, and the orchestrator builds the screen in `screen.html`. Do not edit `screen.html` this time.

## Where things stand

- The owner has seen the polished screen and layout b (`/data/ui-ideation/looks/L1/polish/layout-b.png`) and wireframes at five card ratios. Zone names are in `looks/L1/zones.html`: Left column, Right column, Shop (Shop 1 to 5, Shop left wing, Shop right wing), Board (with Table left and Table right), Hand.
- The card ratio goes back to the game's own: 0.56, a card of 140 x 250 on screen. The side columns stay 244 wide. The orchestrator is now building this as `layout=c`.

## The owner's words (25 Nov 2026)

*[Transcribed from dictation: filler removed, punctuation added, clear dictation errors fixed. My guesses are in brackets.]*

> "Let's keep the current ratio and go with different assets for the different areas. If two areas are treated as one, obviously we'll want to keep an asset for that area, but let's generate different artwork assets for the different areas of the screen, and we'll get some pre-existing assets that are free from the internet and have a go with those. When I say keep the current ratio, I mean let's not change the ratio that's already in the current game build that all the artwork is generated for. I'm happy to keep the 0.56."

> "For all of the cost buttons, if they're going to be a circle, they should have a little [coin] either on the bottom right of the circle overlapping the circle's corner, or on the top right. It's a small change, so just pick one of the two."

> "If you look at earlier builds, the player's health was a circle that was to the right of their portrait, but it should have overlapped and it should have been red. At some point that was lost. I'll give you a reference image from before it regressed. How the player's HP is displayed is how the gold cost should work on the re-roll buttons and how the health should work on the leaderboard portraits, and how it used to work on the [tier] buttons, in fact. So I like all of those."

> "I do not think we need an archway little shelf for the spells. That helps for the cards, but I don't think we want it for the spells. At least not in the same style. It doesn't fit. And the archway needs a bit more negative space, which we'll definitely be able to have now that we've gone with the older aspect ratio, so that the lighting effect has a way of glowing, like in the original mock-up. The original arches we had to house the cards in the very first reference image had the arches bigger than the cards themselves."

> "I think the player's health should go not on their portrait necessarily. I'm not even sure if we should display it twice. [The portrait] is going to be there to activate the player's hero power. I'm thinking that it maybe is a rectangle rather than a circle, and it would go in the left bottom zone from the wireframes and fill that left bottom [under] the leaderboard. Everything [else] stays as the circles, though."

The two pictures the owner attached:

- `/data/ui-ideation/looks/L1/ref-25nov/earlier-build.png`: an earlier build. The owner points at the red health circle overlapping the portrait's lower right, and the cost coins overlapping the round buttons' lower right. Note also its side columns: stained-glass lancet windows, quite unlike the stone shop wall.
- `/data/ui-ideation/looks/L1/ref-25nov/first-arches.png`: your first concept. The owner points at the arches being bigger than the cards, so the tier light has room to glow.

Standing, from earlier: quiet backgrounds; no dimming filters over art; "Don't be too stringent. We're trying to do good design, right? That's the number one priority."

## The problem

In layout b the two side columns, the shop wall and its wings are all the same grey stone, so the screen reads as one wall with things stuck on it. The owner wants each zone to have its own artwork, so that each reads as its own place, while two zones that are really one thing (the table under Board, Table left and Table right, for instance) share one piece.

What sits on each zone, for you to design a ground for:

- **Left column**: Turn at the top, the scoreboard (eight round portraits, each with a red health circle overlapping its lower right), and at the bottom the player's own health as a rectangle.
- **Right column**: gold, the player's portrait (pressed for the hero power), up to four counter plates, card library and settings, End turn.
- **Shop**: five cards, each in an arch that is clearly bigger than the card (on screen the opening is about 188 wide and 300 tall round a 140 x 250 card, arches about 20 apart). Code lights the back of each arch in the tier's colour, so the recess must be dark and plain.
- **Shop left wing**: two round spells, one over the other, with no arch and no shelf. If they need some setting of their own, propose one in a different style from the card arches.
- **Shop right wing**: three round buttons (tier up, refresh, freeze).
- **Board and table sides**: the oak table. **Hand**: the ledge.

## What to do (about 20 minutes)

1. Decide what each zone is made of. The orchestrator's view, for you to test or overturn: the columns should not be more of the shop's stone; the lancet windows of the earlier build did separate them, but whatever you choose must stay quiet enough behind portraits, plates and numerals.
2. Write `docs/workstreams/ui-ideation/looks/L1/prompts-5.txt`: up to 9 items in the format of `prompts-4.txt` (pieces and plain surfaces, blank and empty, not finished screens). Reuse an existing piece where it already does the job (`/data/bramble-art/uiid-looks/L1/`: `l1r-arch.png`, `l1r-lancet.png`, `l1r-wall.png`, `l1p-oak-top.png`, `l1r-leather.png` and the rest) and say so. The tool makes 1:1, 2:3 and 3:2 pictures best; a column is 244 x 1080 on screen, so say how a piece should be tiled or stretched. Include the player's health rectangle (about 212 x 110 on screen, red glass, a numeral goes on it in code).
3. Add a section "Zones" to `looks/L1/polish.md`, 200 words at most: what each zone is made of and why, and for each new piece where it goes and at what size.

## Rules

Write only `docs/workstreams/ui-ideation/looks/L1/prompts-5.txt` and `polish.md`, and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/look-L1`; create it). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. Make no pictures with an image model yourself.

## Report

Under 150 words: what each zone is made of, the pieces ordered, anything you could not solve, and a **Disk** line (what you wrote outside the repo, with sizes).
