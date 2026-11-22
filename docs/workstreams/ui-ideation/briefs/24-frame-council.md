# Frame council: two takes on Bramble's card frame

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). You are one of three voting members of a council reviewing two designs for Bramble's card frame: two separate Claude Opus members with different lenses, and Gemini Neon. A fourth agent (GPT Sol) measures and has no vote. One short pass: one answer from you, no discussion rounds. The owner sees the same pictures and the owner's reaction outranks the council's.

Bramble is an auto-battler in the style of Hearthstone Battlegrounds, set in a woodland of animal folk, fairies and oozes, drawn in lead and stained glass. A unit card is a tall hexagon, 0.56 wide to 1 tall. On screen a board card is about 112 to 128 px wide at 1920x1080, a hand card about 84 px, and a hovered card about 300 px. The card carries Attack, Health and no words.

## The owner's words (22 Nov 2026)

*[Transcribed from dictation: filler removed, punctuation added. Words I am unsure of are kept as heard with my guess in brackets.]*

The owner's idea for the frame:

> "Okay, give me more quiet borders, right? Let's say we still want to keep the colour scheme and have an element of the card border that expresses the story *[probably "tier"]*. But we want it sized for the card sizes that we think we're going to use. I mean, obviously, we can change size as needed. And we keep the majority of the frame lead, but have maybe the bottom third or so, I'm not sure exactly the proportion, be the stained glass pattern in the correct colour with the ornamentation. That should hopefully be less busy, but still make the higher-tier cards more obvious, right?"

On the first attempts, which cut today's frame off at a third and put plain lead above it:

> "But those card frames are not adequate, right? They're very sloppy. They're just the current stuff trimmed. You haven't taken that and actually done a proper pass on it, trying to make it the best version of that concept, trying to think, how do I do this to its highest level? How do I make this look the best? And have it go through a review process. So, you know, serving the purpose of a frame, does it feel like a card from other card games? Do I look at a Magic card and kind of the ratio of card to water *[probably "art to border"]*? What's the right amount? How do other games do artistic flourishes on their borders when they want to do them? What's the right way of blending between the two zones? And how do the states look when it's golden versus not golden? And how well do the colours match in those situations, and that kind of thing. I do not think this has been a good job on the card borders."

You are the review process the owner asked for. Hold the work to "its highest level": the owner has already been shown inadequate frames once today.

## Inputs

Two art directors worked apart. Each designed a frame, had pictures generated, fitted them at real size and went two rounds. Look at the pictures first, at full size, before reading anyone's notes.

- Take M: `/data/ui-ideation/frames/M/r2/sheet.png` (real size: tiers 1 to 6 at 112 and 128 px, normal and golden, blank and with today's card art; spells; a greyscale check; a 300 px hover; a seven-card board), `large.png`, `compare.png`.
- Take N: `/data/ui-ideation/frames/N/r2/sheet.png`, `sheet-2.png` (board, spells, hover), `large.png`, `compare.png`.
- In both takes the round spells are still the first round's: judge the unit frames, and say only whether the spells belong to the same family.
- What the owner rejected: `/data/ui-ideation/concepts/A/p2r5/cards.png`. Today's frames: `docs/design/art-direction/frame-lab/final/`.
- The study of other games' frames, with its measurements and ten proposed rules: `docs/workstreams/ui-ideation/frames/study.md`; its reference pictures: `/data/ui-ideation/frames/study/img/`. The rules are a researcher's proposals, not decisions.
- The screen the frame must live in: `/data/ui-ideation/concepts/A/p2r5/mid.png`.
- After you have formed your own view: each art director's `docs/workstreams/ui-ideation/frames/<M|N>/spec.md` and `notes.md`.
- Do not read `docs/workstreams/ui-ideation/council/`.

## What to answer

For each take, in 300 words at most, answer the owner's questions in the owner's order. Judge at 112 px first, with art in the frame; use the large view only to judge craft.

1. **Does it serve as a frame, and does it feel like a card from a published card game?** Or does it read as a UI outline, or as art fighting art?
2. **Art to border.** Is the amount of frame right for a board piece this size, set against the references?
3. **Flourishes.** Where is the ornament, is it in the right places and the right amount, and does it survive at 112 px?
4. **The join.** Do the lead and the glass meet in a way that looks made, not cut?
5. **Tiers.** Is it less busy than today's frame, and is a higher tier more obvious than a lower one at a glance? Which neighbouring tiers could a player confuse?
6. **Golden against not golden.** Is golden unmissable on every tier, does it look like metal, and do the gold and each tier's colour sit well together (look hardest at tier 5, which is amber)?
7. **Craft.** Anything that looks unfinished, inconsistent between tiers, or machine-made: uneven disc sizes, streaks, squeezed or stretched glass, mismatched lead.

Then, once:

8. **Which take is closer** to the best version of the owner's idea, and what the other does better that it should borrow.
9. **Would you put it to the owner as a proper pass?** Yes or no for each take, and the one thing that decides it.
10. **The three changes** that would raise the leading take the most, the most important first.

Never ask for words, labels or numerals to be added to the card. From stills, glow, sheen and motion are "not judged": say so; never pass them.

## Rules

Write your answer to the file named in your task message FIRST, then reply with it in full. Work read-only apart from that file and your scratch folder (`TMPDIR` in your task message; create it). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. Do not read another member's answer file. End with a **Disk** line: anything you wrote besides your answer file, with path and size.
