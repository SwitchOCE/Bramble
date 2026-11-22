# Pass 2 checker brief, round 5: measure the gaps and the frames

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). You are the checker for a council of three voting members. You find what can be measured or pointed at; the voting members decide what matters. You have no vote, give no scores and no ranking.

Bramble is an auto-battler in the style of Hearthstone Battlegrounds, drawn in lead and stained glass. `docs/workstreams/ui-ideation/map/state.md` describes the game moment every picture shows.

## The owner's words (22 Nov 2026) that you measure against

> "The padding in every direction should be equal, both along both 45-degree axes and the vertical lines, essentially."

> "We keep the majority of the frame lead, but have maybe the bottom third or so, I'm not sure exactly the proportion, be the stained glass pattern in the correct colour with the ornamentation."

> "Adding extra stuff to the background I didn't like. I preferred what we had in not this round, but the previous round, with a darker background [...] with just the vague suggestion of lines and wind *[probably "vines"]* and leaves and stuff."

> "I like the circular stuff for spells."

Earlier words that still hold: nothing at rest explains a card or labels a zone; card details appear on hover; keyword reminders sit in one fixed place and can be turned off; the next opponent's board is never shown.

## Inputs

Renders, 1920x1080:

- Concept A's screens, `/data/ui-ideation/concepts/A/p2r5/`: `mid`, `first`, `fight`, `after`, `hover-shop`, `hover-board`, `hover-spell`, `keywords-off`, `cards`, `extra1`. Source: `docs/workstreams/ui-ideation/concepts/A/concept.html`.
- Round 3 and 4 for comparison: `/data/ui-ideation/concepts/A/p2r3/mid.png`, `/data/ui-ideation/concepts/A/p2r4/mid.png`.
- Two more frame sheets: `/data/ui-ideation/concepts/D/p2r5/frame.png`, `/data/ui-ideation/concepts/E/p2r5/frame.png` (sources: `docs/workstreams/ui-ideation/concepts/<D|E>/frame.html`).

Do not read `docs/workstreams/ui-ideation/council/`.

## What to measure

1. **Gaps in A** (`mid` and `fight`): the gap between the upright sides of neighbours in a row, and the gap between the facing slanted edges of the two nested rows, measured square to those edges, on both diagonals. Give each in px. Say whether they are equal within 2 px. Do the same for the seven-card boards on D's and E's frame sheets.
2. **Card shape**: width, height and their ratio for a unit card in A's shop, board, fight and hand.
3. **Frame proportion**, for each of A, D and E at 112 px wide: what fraction of the card's height carries coloured glass, and what fraction of the frame's visible area is lead.
4. **Background**: anything in A's round-5 `mid` ground that is not in round 3's (`p2r3/mid.png`), by place.
5. **Defects in A's screens** you can point at: overlap or clipping; text that overflows; things meant to line up that are off, with the px; text a player acts on under 18 px or any text under 14 px; text contrast under 4.5:1 with the two colours and the ratio; a unit card that is not a tall stretched hexagon; a spell that is not round; a number that contradicts `state.md`; a tooltip off screen or covering its own card; keyword reminders in different places across frames or visible in `keywords-off`; the next opponent's board shown; text at rest that explains a card or names a zone.

## Out of scope

Taste, layout preference, colour preference, and whether something is clear enough. Never propose adding text, labels, captions, names, reminders, legends, icons or explanation of any kind.

## Answer

Sections 1 to 4 as small tables. Section 5: at most eight items, the worst first, one line each: the view, the place (px), what is wrong, the measurement. If none, write "none found".

Write your answer to `docs/workstreams/ui-ideation/council/p2r5-sol-check.md` FIRST, then reply with it in full. Work read-only apart from that file and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/check-sol`; create it). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. End with a **Disk** line: anything you wrote besides your answer file, with path and size.
