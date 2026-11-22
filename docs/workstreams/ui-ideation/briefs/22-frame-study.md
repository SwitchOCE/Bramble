# Frame study: how other card games build a card frame

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). You do one piece of research: look closely at how published card games, and real stained-glass windows, build a frame around a picture, and write down what can be measured and reused. Two art directors will design Bramble's new card frame from it, and the owner will read it. Everything outside the quotation marks is my reading or proposal.

Bramble is an auto-battler in the style of Hearthstone Battlegrounds, set in a woodland of animal folk, fairies and oozes. Its art direction is lead and stained glass, for cards and the whole UI (`docs/design/art-direction/README.md`). A unit card is a tall hexagon, 0.56 wide to 1 tall, pointed top and bottom. On screen a board card is small: about 112 to 128 px wide at 1920x1080.

## The owner's words (22 Nov 2026)

*[Transcribed from dictation: filler removed, punctuation added. Words I am unsure of are kept as heard with my guess in brackets.]*

The owner's idea for the frame, earlier today:

> "We keep the majority of the frame lead, but have maybe the bottom third or so, I'm not sure exactly the proportion, be the stained glass pattern in the correct colour with the ornamentation. That should hopefully be less busy, but still make the higher-tier cards more obvious, right?"

On the first attempts at it, which cut today's frame off at a third:

> "But those card frames are not adequate, right? They're very sloppy. They're just the current stuff trimmed. You haven't taken that and actually done a proper pass on it, trying to make it the best version of that concept, trying to think, how do I do this to its highest level? How do I make this look the best? And have it go through a review process. So, you know, serving the purpose of a frame, does it feel like a card from other card games? Do I look at a Magic card and kind of the ratio of card to water *[probably "art to border"]*? What's the right amount? How do other games do artistic flourishes on their borders when they want to do them? What's the right way of blending between the two zones? And how do the states look when it's golden versus not golden? And how well do the colours match in those situations, and that kind of thing. I do not think this has been a good job on the card borders."

## What to study

At least ten cards from at least six published games, chosen to differ: Magic: The Gathering (a normal frame and a showcase or borderless one), Hearthstone and Hearthstone Battlegrounds (normal and golden), Legends of Runeterra, Gwent, Marvel Snap (and its frame-break variants), Slay the Spire, and others you think teach more. Add three or four real stained-glass windows where a figure panel sits above or inside an ornamental border, base panel or canopy: that is the craft Bramble's look borrows from.

Find the pictures on the web. Search in general terms only: never put the name Bramble, the owner, or any detail of this project in a web request. Save what you study under `/data/ui-ideation/frames/study/img/` with a line per file in `/data/ui-ideation/frames/study/sources.md` (file, game, where it came from). These are other studios' pictures: they stay there and never go into Git.

Also look at Bramble's own: today's six frames in `docs/design/art-direction/frame-lab/final/`, and the rejected attempt at real size in `/data/ui-ideation/concepts/A/p2r5/cards.png`.

## What to answer

Write `docs/workstreams/ui-ideation/frames/study.md`, 700 words at most plus tables, in plain language:

1. **How much is frame.** For each reference card, measured from the picture: the share of the card's area that is art, frame, and text or stat furniture; and the frame's thickness as a fraction of the card's width, at the top, sides and bottom. One table. Then the same numbers for Bramble's present frame and for the rejected attempt.
2. **Where the ornament goes.** Where each game puts its flourishes (corners, top crest, a base, around the stats, breaking the outline), how many places carry ornament on one card, and what stays plain. What separates a flourish that reads as rich from one that reads as noise, especially when the card is drawn small.
3. **How rank or rarity shows.** What changes between the lowest and highest rank in each game (a gem, a colour, material, added structure, silhouette), and which of those still read when the card is about 120 px wide.
4. **Joining two zones.** How frames that have a plain part and an ornate part join them: a hard line, a moulding or joint, a taper, ornament that climbs and thins out. Which look made and which look cut off, and why.
5. **Golden and premium states.** How each game shows a premium card over the normal one (material change, a second border, glow, animation), how the premium colour is kept from clashing with the rank colour, and how it survives at small size.
6. **Ten rules for Bramble's frame**, each one line, each tied to a reference by name, written so a designer could follow it.

Where a question needs motion to answer (a foil or animated premium), say "not judged from stills".

## Rules

Write only `docs/workstreams/ui-ideation/frames/study.md`, `/data/ui-ideation/frames/study/` and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/frame-study`; create it). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. If the web is not reachable from where you run, say so at once in your reply and use the pictures already on this machine under `/data/ui-ideation/gallery/` (see its `index.md`).

About 25 minutes is right.

## Report

In under 150 words: how many cards you studied, the three findings that matter most for Bramble, and a **Disk** line (what you wrote outside the repo, with sizes).
