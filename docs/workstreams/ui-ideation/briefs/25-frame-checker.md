# Frame checker: measure two card frames

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). You are the checker for a council of three voting members reviewing two designs (takes M and N) for the card frame of Bramble, an auto-battler drawn in lead and stained glass. You measure; the voting members judge. You have no vote, give no scores, no ranking and no opinion on looks.

A unit card is a tall hexagon, 0.56 wide to 1 tall. On screen a board card is about 112 px wide.

## The owner's words (22 Nov 2026) that you measure against

> "We keep the majority of the frame lead, but have maybe the bottom third or so, I'm not sure exactly the proportion, be the stained glass pattern in the correct colour with the ornamentation. That should hopefully be less busy, but still make the higher-tier cards more obvious, right?"

> "Do I look at a Magic card and kind of the ratio of card to water *[probably "art to border"]*? What's the right amount? [...] And how do the states look when it's golden versus not golden? And how well do the colours match in those situations"

## Inputs

- Take M: `/data/ui-ideation/frames/M/r2/sheet.png`, `large.png`; its fitted frame pictures and code under `/data/ui-ideation/frames/M/` and `docs/workstreams/ui-ideation/frames/M/` (`frame.html`, `fit2.py`).
- Take N: `/data/ui-ideation/frames/N/r2/sheet.png`, `sheet-2.png`, `large.png`; its fitted frame pictures and code under `/data/ui-ideation/frames/N/` and `docs/workstreams/ui-ideation/frames/N/` (`frame.html`, `assemble_r2.py`).
- For comparison: today's frames, `docs/design/art-direction/frame-lab/final/`; the study's numbers for other games, `docs/workstreams/ui-ideation/frames/study.md` section 1.

Do not read `docs/workstreams/ui-ideation/council/`. Measure the fitted frame pictures where you can, and the sheets where you cannot.

## What to measure, for each take and each tier 1 to 6

1. **Shares of the card's area:** art window, lead, coloured glass, stat discs. One table per take.
2. **Lead width** in px at 112 px wide: at the upper sides and at the top slopes. Say whether it is the same on all six tiers.
3. **Where the glass starts:** the height of the join as a fraction of the card's height, per tier, and the step between neighbouring tiers in px at 112 px wide.
4. **Stat discs:** diameter and centre position in px at 112 px wide, per tier. Say whether they match across tiers within 1 px.
5. **Smallest ornament:** the size in px, at 112 px wide, of the smallest separate ornament piece on each tier (a bead, jewel, petal).
6. **Telling tiers apart without colour:** convert each tier's blank frame at 112 px to greyscale and give the mean absolute pixel difference between each pair of neighbouring tiers (1–2, 2–3, 3–4, 4–5, 5–6).
7. **Golden:** for each tier, the mean colour of the gilt metal and the mean colour of that tier's glass, and the difference between them (CIE ΔE, and the difference in lightness). Flag any tier where ΔE is under 20. Also the mean absolute pixel difference between each tier's normal and golden frame at 112 px.
8. **Defects you can point at**, at most six per take: a frame that does not line up with its window, a visible seam or halo from fitting, stretched or squeezed glass (with the scale factor), art showing outside the frame, a card that is not 0.56 wide to 1 tall.

## Out of scope

Taste, and whether anything looks good. Never propose adding text, labels or numerals to a card.

## Answer

Small tables, one set per take, then the defects, one line each with the place. Write your answer to `docs/workstreams/ui-ideation/council/frames-r2-sol-check.md` FIRST, then reply with it in full. Work read-only apart from that file and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/check-sol-frames`; create it). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. End with a **Disk** line: anything you wrote besides your answer file, with path and size.
