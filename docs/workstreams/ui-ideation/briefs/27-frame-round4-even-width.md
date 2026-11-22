# Frame pass, round 4: the owner on round 3

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). For art director M. The owner has looked at round 3. The owner's words are below; the rest is my reading, and where it differs from the words, the words win.

## The owner's words (22 Nov 2026, on round 3)

> "I think that the border needs to blend way more evenly. Like, I feel like they need to be of a similar, what's the word for it? Width."

## My reading

"They" are the two parts of the border: the lead above and the stained glass below. In round 3 the lead is about 6 px wide at 112 px, and the glass band below the join is two to three times that, with the stat discs and the crest on top of it. So the border jumps in width where the lead ends, and the two parts read as two different borders. The owner wants one border of about one width all the way round, in which the lead gives way to glass evenly.

## What to do

1. **Make the glass part about as wide as the lead part.** Build two versions so the owner can compare:
   - `even`: the glass band is the same width as the lead, all the way round the lower card.
   - `near`: the glass band is a little wider than the lead, about one and a half times, widening gradually from the join and never stepping.
   In both, the change from lead to glass must be gradual: no jump in width, no shoulder. Keep what the council praised in your join (the rails parting, the leaf tip, the solder knot) if it survives at these widths; if it does not, design the join again for a border of one width and say what you did.
2. **Decide what happens to everything that made the glass wide:** the stat discs, their rings, and the bottom crest. They are yours to redesign. The discs may sit on the border, overlap the art, or shrink; the crest may shrink, change or go. Whatever you choose must not bring the width jump back.
3. **Keep the tier ladder readable.** With less glass, a higher tier must still be more obvious than a lower one at 112 px. Say how: how far the glass climbs, the colour, the crest, anything else.
4. **Keep what round 3 fixed:** one lead, one ivory stat disc for every tier, gold meaning only golden, no pieces under 6 px at 112 px.
5. **Your own open items** from round 3 where they still apply: tiers 3 and 4 close in greyscale; golden tier 1 pairing gold with silver glass; stat rings paler than the band glass; the spells' joins.
6. How you get there is yours: code, new pictures, or both. If you need pictures, write `prompts-4.txt` (up to 12 items) and say so at once, before fitting; the orchestrator runs it and messages you.

## What to deliver

Round 3's renders are kept in `/data/ui-ideation/frames/M/r3/`. Render into `/data/ui-ideation/frames/M/`:

- `board.png`: the seven-card board at 112 px (one golden) on the teal ground, three times side by side: round 3, `even`, `near`.
- `sheet.png`: for your recommended version, tiers 1 to 6 at 112 and 128 px, normal and golden, blank and with today's art; spells; the greyscale check; a 300 px hover.
- `large.png`: tiers 1 to 6 and golden at about 300 px, your recommended version; and tier 3 and tier 6 of the other version beside them.

Look at every render at full size, at 112 px first. Update "What I would still fix" in `spec.md`.

## Rules

As in `briefs/23-frame-art-director.md`.

## Report

In under 150 words: the border's width in px at 112 px for the lead and for the glass in each version, how the tiers are told apart now, which version you recommend and why, what falls short, whether you need pictures, and a Disk line.
