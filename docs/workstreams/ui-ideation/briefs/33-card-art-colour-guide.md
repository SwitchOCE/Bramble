# Card art colour guide: calmer backgrounds, a palette per tribe

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). You are an art director for one job: write the colour guide for Bramble's card art and prove it with test pictures. You direct; a separate worker with an image tool paints what you order.

Bramble is an auto-battler set in a woodland of animal folk, fairies and oozes, drawn in lead and stained glass. Its cards are small (about 112 to 150 px wide on the board). The owner has just chosen a screen look, "L1": every card is a small leaded window in a dim room of stone and oak, with a plain dark lead border and no coloured frame. Tier shows as coloured light behind a card in the shop; a golden card has a gilt border and a warm glow.

## The owner's words (24 Nov 2026)

*[Transcribed from dictation: filler removed, punctuation added, clear dictation errors fixed.]*

> "I agree with calmer card backgrounds. We need less bright backgrounds. Maybe not as washed out as this, but definitely we need to set guidelines for background colours that are allowed per tribe, and I'd like a full colour palette guideline thing made up. Calmer backgrounds. Maybe not too plain."

Earlier the same day: "I'm continually noticing that the UI is being held back a lot by the art and the card borders." And: "I really love stained glass. The stained glass thing feels like the art style that I want to use, and I know that is core."

22 Nov, when a screen was calmed by dimming the art: it "sucked all the joy out of the scene". The fix is in how the art is painted, never a filter over it.

22 Nov, on instructions: "Don't be too stringent. We're trying to do good design, right? That's the number one priority."

## What "this" was

"Not as washed out as this" refers to `/data/bramble-art/uiid-looks/L1/l1-art-mid.png`: the same card with today's loud background (left), a quiet woodland behind a vivid figure (middle), and flat colour (right). The owner wants calmer than the left, not as grey as the middle may read, and never as plain as the right. See the look in use: `/data/bramble-art/uiid-looks/L1/l1-buy-c.png`, `l1-cards.png`.

## What exists

- Today's art, by tribe: `assets/units/` (badger, locust, mouse, pigeon, and `shared`). The owner accepted it on 17 Nov and still likes its figures; the trouble is that every background is at full strength, so on a board of seven nothing leads.
- How it is made: `docs/design/art-direction/card-art-recipe.md`. Read it. Two things in it bear on this job. The owner approved its loose prompt ("This process is producing what I like"). And it records that on 15 Nov "palette limits" written into the prompt as rules were followed literally "and the pictures came out flat". So a guide that works must reach the painter in a way that keeps the pictures alive: a place and a time of day, a reference picture, a few named colours, or whatever you find works. Finding that way is part of the job.
- An earlier, unfinished look at calmer art styles: `docs/workstreams/ui-ideation/art-style/recommendations.md` and `/data/ui-ideation/art-style/`.
- The tribes and their flavour: `docs/ideation-track-2/` and `docs/STATUS.md`.

## The job

1. **Find the level.** Paint two or three well-known cards at several strengths between today's and the quiet middle, and choose the one where the figure leads and the picture is still joyful glass. Check it small: seven cards side by side at 130 px wide on dark oak, beside today's seven.
2. **A palette per tribe.** For each tribe: the background colours it may use (a home family of hues, with how dark and how strong), the colours kept for figures, and what it must avoid. Each tribe should be recognisable by its backgrounds at a glance, and the tribes should sit well together on one board. Neutral units need an answer too.
3. **The whole system.** The screen's own materials (stone, oak, leather, lead), the six tier lights (off-white, green, blue, purple, orange, red) and golden: say which colours card backgrounds must leave alone so that tier light and gold stay readable.
4. **How the painter is told.** The wording or reference that carries the guide into the recipe's prompt without flattening the pictures, shown working on at least two cards per tribe.

## Stage 1 (about 20 minutes)

Write `docs/workstreams/ui-ideation/palette/plan.md` (200 words at most: how you will find the level and test the palettes) and `docs/workstreams/ui-ideation/palette/prompts.txt` in the format of `tools/art/prompts/` (a fixed header, then numbered `filename -- description` items; `tools/art/prompts/glass-art-window.txt` is the card art prompt). Up to 12 pictures. You may give reference pictures by path, and the shape guide `tools/art/glass-art/guide.png`. Reply when written; the orchestrator runs the order and messages you when the pictures are in `/data/bramble-art/uiid-palette/`.

## Stage 2

Look at every picture at full size and at 130 px. Order more if needed (`prompts-2.txt`, up to 12; one further order after that if you must). Then write:

- `docs/workstreams/ui-ideation/palette/guide.md`: the guide itself, plain language, 600 words at most plus tables. Colours as names and hex values.
- `/data/ui-ideation/palette/sheet.png`: the swatches per tribe, the test cards before and after at full size, and the two boards of seven at 130 px (today's art and the new).
- In your report, say plainly what the guide costs: which of today's cards would need repainting.

## Rules

Write only `docs/workstreams/ui-ideation/palette/`, `/data/ui-ideation/palette/` and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/palette`; create it). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. Make no pictures with an image model yourself; swatches and sheets drawn in code are yours. In web requests, search in general terms only: never put the name Bramble, the owner, or any detail of this project in a request.

## Report

Each stage, in under 150 words: what you decided, what falls short, what you need next, and a **Disk** line (what you wrote outside the repo, with sizes).
