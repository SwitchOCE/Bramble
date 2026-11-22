# Frame pass: design Bramble's card frame properly

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). You are an art director for one job: design the card frame the owner has described, to the highest level you can, and see it through to a finished sheet. You design and assemble; a separate worker with an image tool makes the pictures you ask for. A second art director is doing the same job independently; do not look for their work. Everything outside the quotation marks is my reading or proposal, and where it differs from the owner's words, the words win.

Bramble is an auto-battler in the style of Hearthstone Battlegrounds, set in a woodland of animal folk, fairies and oozes. Its art direction is lead and stained glass, for cards and the whole UI (`docs/design/art-direction/README.md`).

## The owner's words (22 Nov 2026)

*[Transcribed from dictation: filler removed, punctuation added. Words I am unsure of are kept as heard with my guess in brackets.]*

Earlier in the day, releasing the frame:

> "We're too busy with the card frames, right? I told you to hold the card frame sacrosanct. I'm releasing you from that constraint. I want the stained glass to be kept, but I think I've gone too over the top with a lot of the visual indication in terms of rarity in the framings. And I give permission to make variations on that theme. The shape I still like. Spells can have a different shape."

The owner's idea for the frame:

> "Okay, give me more quiet borders, right? Let's say we still want to keep the colour scheme and have an element of the card border that expresses the story *[probably "tier"]*. But we want it sized for the card sizes that we think we're going to use. I mean, obviously, we can change size as needed. And we keep the majority of the frame lead, but have maybe the bottom third or so, I'm not sure exactly the proportion, be the stained glass pattern in the correct colour with the ornamentation. That should hopefully be less busy, but still make the higher-tier cards more obvious, right?"

> "My idea for the card is, you know, the bottom third of the card would be the current stuff, and the top two-thirds would be what was proposed, kind of the same kind of styles as we did in the other sessions."

> "I like the circular stuff for spells."

On the first attempts, which cut today's frame off at a third and put plain lead above it:

> "But those card frames are not adequate, right? They're very sloppy. They're just the current stuff trimmed. You haven't taken that and actually done a proper pass on it, trying to make it the best version of that concept, trying to think, how do I do this to its highest level? How do I make this look the best? And have it go through a review process. So, you know, serving the purpose of a frame, does it feel like a card from other card games? Do I look at a Magic card and kind of the ratio of card to water *[probably "art to border"]*? What's the right amount? How do other games do artistic flourishes on their borders when they want to do them? What's the right way of blending between the two zones? And how do the states look when it's golden versus not golden? And how well do the colours match in those situations, and that kind of thing. I do not think this has been a good job on the card borders. You may need to generate art using Sol, but yeah, stuff needs to be done."

## What is fixed, and what is yours

Fixed: the unit card is a tall hexagon, 0.56 wide to 1 tall, pointed top and bottom. It is lead and stained glass. It carries Attack and Health and a way to tell its tier (1 to 6). No words on the card. Spells are round. The frame's idea is the owner's: mostly lead, with the tier's stained glass and ornament in about the lower third.

Yours: everything else. The proportion, the lead's weight and profile, where ornament sits, how the lead and the glass join, how a tier grows richer, how golden looks on each tier, the stat holders, the tier mark, the art window. If you change the art window, say what it does to card art already painted to today's window (`docs/design/art-direction/card-art-recipe.md`).

The card is used small: a board card is about 112 to 128 px wide at 1920x1080, a hand card about 84 px. It is seen large only on hover (about 300 px wide). Design for the small size first.

## Read and look first

- `docs/design/art-direction/README.md`; `docs/workstreams/glass-frames.md` (how today's frames were made, and why they were thinned); today's six frames, `docs/design/art-direction/frame-lab/final/`.
- The rejected attempt: `/data/ui-ideation/concepts/A/p2r5/cards.png` (real size, blank and with art) and `/data/ui-ideation/concepts/A/p2r5/mid.png` (in the screen it must live in).
- Today's card art, which the frame must live with: `assets/units/`.
- Other card games, first-hand. Before you draw anything, look closely at six or more published cards (for example Magic: The Gathering, Hearthstone normal and golden, Legends of Runeterra, Gwent, Marvel Snap, Slay the Spire) and two real stained-glass windows with an ornamental base or border. A separate study is being written to `docs/workstreams/ui-ideation/frames/study.md` with pictures in `/data/ui-ideation/frames/study/img/`; use it if it is there when you start, and look for yourself either way. In web requests, search in general terms only: never put the name Bramble, the owner, or any detail of this project in a request. Other studios' pictures you download stay in your scratch folder and never go into Git.

## Stage 1: the design and the picture order (about 20 minutes)

Write `docs/workstreams/ui-ideation/frames/<your take>/spec.md`, 500 words at most, answering the owner's questions in order:

1. **What the frame is for**, and what you took from which reference.
2. **Art to border.** The share of the card that is art, lead and glass, set against the references you looked at.
3. **Ornament.** Where it goes, where it never goes, and how it stays readable at 112 px.
4. **The join.** How the lead and the glass meet so it looks made, not cut.
5. **The tier ladder.** What changes from tier 1 to tier 6, so a higher tier is more obvious at a glance at 112 px.
6. **Golden.** How a golden unit looks on each tier, and how gold is kept from clashing with each tier's colour (tier 5 is already amber).
7. **Stats, tier mark, spell.**

Then order the pictures. Write `docs/workstreams/ui-ideation/frames/<your take>/prompts.txt` in the format of `tools/art/prompts/` (a fixed header, then numbered `filename -- description` items; `tools/art/prompts/glass-concept-frames.txt` and the recipe show it). The image worker follows it literally and sees nothing else, so say exactly what each picture is: the whole frame or a piece, the canvas, what must stay empty, the colours. You may give it reference pictures by path (today's frames, or a shape guide you draw with code into `/data/bramble-art/uiid-frames/<your take>/guide/`). Ask for what the design needs, up to 16 pictures in this first order: the six tiers and their golden versions come first.

Reply when stage 1 is written. The orchestrator then starts the image worker and messages you when the pictures are in `/data/bramble-art/uiid-frames/<your take>/`.

## Stage 2: assemble, look, and improve (after the pictures arrive)

Cut and fit the pictures with code (the tools in `tools/art/` show how today's frames were cut and measured). Build `docs/workstreams/ui-ideation/frames/<your take>/frame.html` and render at 1920x1080 into `/data/ui-ideation/frames/<your take>/`:

- `sheet.png`, real size on a dark, quiet ground: tiers 1 to 6 at 112 px and at 128 px, blank panes and with today's card art; each tier's golden version beside its normal one; a round spell; a hovered card at about 300 px; and seven cards of mixed tiers in two nested rows with one 28 px gap everywhere, one of them golden.
- `large.png`: tiers 1 to 6 and their golden versions at about 300 px wide.
- `compare.png`: your tier 3 and tier 6 beside today's frame and beside two of your reference cards scaled to the same height, so the art-to-border ratio can be seen.

Look at every render at full size. Judge it against your own spec and against the references, and say plainly what falls short. If pictures need redoing, write a second order (`prompts-2.txt`) and say so in your reply; you get at least one more round.

Add to `spec.md` a section "What I would still fix", 100 words at most.

## Rules

Write only `docs/workstreams/ui-ideation/frames/<your take>/`, `/data/ui-ideation/frames/<your take>/`, `/data/bramble-art/uiid-frames/<your take>/guide/` and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/frame-<your take>`; create it). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. Make no pictures with an image model yourself; drawing guides and assembling with code is yours. From stills, motion and glow timing are "not judged".

## Report

Each stage, in under 150 words: what you decided or built, what falls short, what you need next, and a **Disk** line (what you wrote outside the repo, with sizes).
