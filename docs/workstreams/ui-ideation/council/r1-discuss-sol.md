# Round 1 discussion · Sol

## Fixed requirements

I’m revising my first-round ruling. I applied “tier frames as the base of every card” literally. The six existing tier files are unit frames, and applying them unchanged to spells gives the player empty Attack and Health discs, as A and F demonstrate. I would require the exact existing frames for units and a consistent tall, leaded treatment using today’s spell art for spells. The baseline already uses a separate lead outline for spells. [Designer brief](/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/docs/workstreams/ui-ideation/briefs/04-designer.md), [Current spell renderer](/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/src/glass/glass_spell.gd)

| Concept | Ruling on the disputed fixed requirement |
|---|---|
| B | **Disagree with exclusion.** The blue edges around Sharpen and Seek in *mid* are custom, but they read as tall leaded hexes and fit the lattice. The spell treatment passes. The price placement on the shared cell vertices is a reading defect. |
| C | **Disagree with exclusion.** The two Sharpen pieces and Seek in *mid* use the tall silhouette and the same blue lead surrounds. The spell treatment passes. The separation of the spell alcove from unit offers is a layout concern. |
| D | **Disagree with exclusion.** Sharpen and Seek in *mid* use a dark lead outline around the original art. The silhouette passes. Their edges need the same material finish as the rest of the bench before handoff. |
| E | **Disagree with exclusion.** Sharpen and Seek in *mid* are tall leaded pieces in the same woodland as the units. The silhouette passes. Refine the soft black edge and preserve the art’s aspect ratio inside it. |
| F | **Disagree with the material failure.** The beveled hinge, inset lead outlines, diagonal facets and leafy green glass continue from *first* through *after*. The opaque bands across the figures and the flat shop and scout chips in *mid* are real finish defects. I would keep the material pass and treat those as fixes if F advances. |

## Revised shortlist

**A, D, E.** A remains first. Its big, unobstructed art, named standings and calm recruit screen make the strongest whole. D moves into second after the spell ruling. Its aligned offer rules and bench staging make the strongest case for a different daily play experience. E moves ahead of F for third. I initially put too much weight on the current number of inspections and too little on how much of E’s reading problem can be addressed locally. The gap below the hanging shop, the two existing board rows and the right-hand lanterns give labels natural places to go. E advances with the requirement to demonstrate that those labels fit while keeping the clearing open. F’s side-by-side fight and explanation remain strong, but its shop asks the art to share too much space with text.

- **B look stays 6.5.** In *mid*, the brass seam and full-cell controls make the lattice coherent. The cold open cells on the right and the bands and gold discs squeezed together in the center still divide the screen’s visual weight poorly. I see the originality Neon rewarded and less finish in the actual play area.
- **D look stays 7.5.** The *mid* shop really looks like light coming through a workshop window. In *fight*, the repeated dark diamond grid on near-white panes and the identical white discs have comparable visual weight to the artwork. I would want that hierarchy corrected before awarding a 9.
- **F look moves from 7.5 to 7.** The glass leaves and hinge are stronger than Neon’s 4 suggests. On a second look at *mid* and *fight*, the same opaque treatment dominates the shop, formation and hand. The frame alone cannot carry all that surface.

## A · Review of the other fixes

- **Opus 1, Neon 1–2 — Agree.** In *mid* and *fight*, the rows read as one zigzag. In *mid*, the back captions reach the sill and the bottom-point marks on Blackberry Sprawl and Hedge Lancer crowd the label tops. Give rows their own bands and consistent labels. Preserve a readable half-slot offset.
- **Opus 2, Neon 5 (tier and prices) — Agree.** *Mid* makes the player inspect Home Guard to see its tribe, and the inline coin crowds longer names. A quiet tribe crest and a readable tier cue can sit in the lead. The five prices already share a horizontal line. Give them a fixed position within each offer so their spacing from the name stays consistent.
- **Opus 3, Neon 5 (control grouping and stability) — Agree.** Refresh stock reads like a fourth line of Upgrade metadata in *mid*. In *fight*, the player identity and live counters jump below the reader. Attach stock to Refresh and hold a consistent left-light anchor for the health and counters.
- **Opus 4 and 7, Neon 3 — Agree with a different fix.** Both Sharpen pieces in *mid* have vacant stat discs and one shared label. Give each spell its own label and a clean spell edge. Size the spell and hand art for legibility and seven-slot fit, without a fixed half-unit minimum. Seek needs its effect visible or directly reachable. Its spent purchase price is secondary once it is in the hand. Keep room for longer text in the fixed reader.
- **Opus 5 — Disagree with the data error, agree on clarifying the stage.** A’s right light matches the completed match in *game-end-result.png*, including March Hare first and everyone else at zero. Opus’s order is visible in the separate turn-9 defeat capture. The cue to fix is the juxtaposition of a fight recap with already-final match standings. [Fight-end standings](/data/ui-ideation/baseline/shots/fight-mid-t9-result-defeat.png), [Final match standings](/data/ui-ideation/baseline/shots/game-end-result.png)
- **Opus 6, Neon 4 — Agree with a narrower fix.** *Fight* names only the selected card. *After* names the starting Gorger but leaves the fight explanation in the reader. Add names and a short set of marked outcome callouts. The decorated, quiet right light can stay. A reserves feature to fill it is non-blocking.
- **Opus 8 and Neon’s notes check — Agree with clarification.** Record row 20 for the always-visible information beside the face and row 40 for the always-visible roster.

### A · Proposed blocking fixes

1. In *mid*, *first* and *fight*, group each side’s front and back rows on clear shared guides. Align their labels, maintain clearance around marks and captions, move the back row inside the sill, and aim the first-turn cue at an actual empty slot. Keep Renown on its slot.
2. In *mid* and *first*, use fixed price positions, readable tribe and tier cues, and clear purchase summaries. Clarify Sweetbriar’s trigger on each unit added to Compost. Attach “10 at this price” to Refresh.
3. In *mid* and *first*, replace empty spell stat discs with a consistent lead edge, give each shop spell its own label and effect, and keep hand cards and their effects readable through the fixed inspector.
4. In *fight* and *after*, keep health and live counters in a stable place where present, name the fighters, identify survivors, and pair one or two decisive threats with the existing 10 + 3 explanation. Label the right light “Final match standings” for the data currently shown.
5. Against *mid*, add rows 20 and 40 to the notes and specify that the names and effects sit beside the faces.

## D · Review of the other fixes

- **Opus 1, Neon 6 (spell edge) — Agree with a different fix.** In *mid*, Sharpen and Seek have plain black edges. Finish a consistent leaded edge for spells and leave the unit stat wells off it.
- **Opus 2–4 and 8, Neon 6 (card size) — Agree with a different fix.** Tone down the bright backing and pattern and give the cream plaques glass depth. The 172 px cards in *mid* have broad margins, but two 240 px rows with captions exceed the current table’s height. Reclaim some of the oversized offer-label space and test a modest enlargement. Reserve the right margin for the *extra1* reader so it stays inside the frame and clears the board.
- **Opus 5, Neon 1 — Agree.** In *mid*, Freeze is nearly the brightest action in the economy stack and the Next and You rows share the End turn treatment. Quiet these surfaces and keep the first-turn cue legible when it is the active step.
- **Opus 6, Neon 2–3 — Agree.** In *mid* and *fight*, the gold Renown diamonds read like shoulder prices and the identical white stat discs cover the native wells. Etch Renown into the slot and distinguish Attack, Health and modified values by shape or a mark as well as by colour.
- **Opus 7–9, Neon 5–6 (hand, positioning, tier) — Agree with a different fix.** An empty part of the tray is expected at one card. Prove seven cards fit. In *fight*, use edge space for the existing undersized reserve thumbnails, which show empty discs, and make the kill threshold legible. Keep Menu and Turn in one place. Use a quiet non-colour tier cue. Filling the remaining side space and changing the damage animation are non-blocking.
- **Neon 4 — Agree.** In *mid*, Granary Glutton and Squadron Leader carry only names. In *fight*, Wing Commander says Charge 4 with no indication of charges left. Show short cues for the main triggers and a remaining-charge indicator.
- **Opus 10 — Agree.** *After* precedes “See results,” and Pipkin still has his recruit-state 31. Use the end-of-turn standings. Label starting values as such wherever the result uses them for its threat comparison.

### D · Proposed blocking fixes

1. In *mid*, *first*, *fight* and *after*, soften the backlight and diamond grid, give the plaques glass depth and reserve the strongest action lighting for the active cue. Keep the bench and light table recognizable.
2. In *mid* and *extra1*, make room for larger board pieces and 18 px purchase effects by tightening the shop labels. Keep the reader inside the table perimeter with clearance from all slots.
3. In *mid* and *fight*, distinguish Attack and Health, mark modified values, attach labeled Renown to the slot and add a readable tier cue. Give triggered units a short effect line and show remaining Charge in the fight.
4. In *mid* and *first*, finish the spell edges and make the hand tray fit seven. In *fight*, give the existing reserve pieces readable names and stats and the stakes plaque a clear kill threshold. Keep Menu and Turn anchored across views.
5. In *after*, update the right standings to the turn-9 result. Keep the numbered threat links and 10 + 3 arithmetic, and label any comparison of starting board values.

## E · Review of the other fixes

- **Opus 1, Neon’s names/rules defect — Agree.** *Mid* is still a portrait memory test. Fit short lead-set labels beneath the hanging offers and along the two board rows. Keep detailed rules in the existing inspector. This preserves the low-chrome route, provided the labels and row spacing work together at full board.
- **Opus 2, Neon’s rank and contrast defect — Agree.** In *mid*, March Hare’s lantern has a ring but no name, and rank sits directly on bark. Give the lantern data readable backing and label the next opponent where the player ends the turn.
- **Opus 3 and 7, Neon’s discs and glow defect — Agree.** In *mid*, the 4 below Home Guard has much the same treatment as the 3 and 11 on the card. Give prices distinct tags and let the tribe crest carry tribe recognition. Ease the halos so tier rims read clearly.
- **Opus 4–5, Neon’s controls observations — Agree.** The purse dominates *mid*, the Refresh coin sits on the control border, and Compost and Tide are bare icons. Reserve the strongest amber accent for End turn, put the Refresh cost inside its control and name both counters.
- **Opus 6, Neon’s small type and clipping defects — Agree with different evidence.** Seek’s tip in *mid* is visible. The rail itself runs into the screen edge, and in *fight* it collides visually with the hand badges. The hand stats are below 18 px. The keyword-count badges are crowded, and the style specifies 14 px. I would fix their clearance and rendered legibility without calling them below 14 px on the available evidence.
- **Opus 8, Neon’s fight and popup defects — Agree with a narrower fix.** In *fight*, back-row badges crowd front-row Renown and the tally lacks a threshold label. In *after*, some living units look fallen, and the lanterns still show pre-fight health. Fix those cues and give the result and inspector the same lead and glass finish as the scene. Judge the hit motion separately.

### E · Proposed blocking fixes

1. In *mid* and *first*, give shop offers names and short effects in individual lead-set tags and put names and brief trigger cues along the board rows. Keep the art visible. In *extra1*, move the existing inspector clear of the units it names as synergy partners.
2. In *mid*, *first* and *fight*, use consistent spell edges, distinguish gold prices from both stats, and tone down tribe halos. Put Refresh cost in its button, label Compost and Tide, and give the single strongest action accent to End turn in recruit.
3. In *mid* and *after*, back lantern ranks and health with readable glass, separate threads from neighboring portraits, and label the players. Name March Hare at End turn. Update the lanterns to the turn-9 result.
4. In *mid* and *fight*, fit the hand inside the screen with at least 18 px stats and clear badge spacing. In *fight*, separate marks from adjacent Renown and label the tally’s threshold. In *after*, visibly distinguish survivors from fallen slots, keep the numbered threat links and carry the forest’s glass finish onto their recap.

## Non-blocking

Opponent scouting, functional replay or a full fight log, adding new content to quiet side panels, and changes to attack animation can be considered separately. Motion, timing, hover and drag feel, sound and other resolutions were not judged.

## Disk

I wrote only [this discussion reply](/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/docs/workstreams/ui-ideation/council/r1-discuss-sol.md). The six comparison copies from round 1 remain in [council-sol](/data/ui-ideation/tmp/council-sol/), 2.2M total. The orchestrator can remove that folder once the comparison work is finished.

JOINT PROPOSAL: SHORTLIST A D E
