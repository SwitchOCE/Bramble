VERDICT: GOOD TO GO
GALLERY: A better, D average, E better (unchanged from round 2)

# Council round 3: opus

I checked every new render at full size (A: mid, first, fight, after; D: those plus extra1 and extra2; E: those plus extra1). I sampled pixels at A's sill and E's dimmed lanterns, and read the CSS for type sizes.

## Item check against `r2-agreed.md`

### A
1. **Renown tabs: fixed.** In mid, fight and after every tab sits on its own card's top-left shoulder, inside the frame. No tab touches a plaque any more: Wing Commander's "Renown 3" is clear of the front-row captions, and the enemy front row's tabs are clear of the back-row plaques. Briar King's empty slot keeps "Renown 4" in after.
2. **Back row above the sill: fixed.** Pixel column at x 720, 960 and 1200 in mid: the plaque border ends at y 1041, then 4 px of window glass, then lead and the sill from y 1046. There is a visible gutter, and the marks stay clear of the plaques. The three back-row frames are slightly smaller, but the shape is kept and they are undistorted.

### D
1. **Changed-value marker in recruit: fixed.** In mid, green chevrons and green digits sit on Famine-caller 15/11, Bell-ringer 5/7, Granary Glutton 7 and Wing Commander 11/17. Unchanged values stay plain.
2. **18 px hand and reserve digits: fixed.** In extra2 all seven hand cards have readable digits (hand cards are 94 px). The fight's reserve stones are larger.
3. **Renown and effect lines at 18 px; Squadron Leader cue: fixed.** `.rtab` and `.boardlabel .kw` are both 18 px. The labels hang from the card tips with about 10 px above the back row's Renown tabs, and about 25 px above the divider in fight. The cue reads "Ahead: Sortie, +3 Attack".

### E
1. **After follows the record: fixed.** Briar King is dark and marked "Fell". Six survivors keep their end stats: Gorger 38/57, Holly Knight 24/27, Weasel 9/2, Greatsword Bearer 7/10. The panel reads "You killed 1 of 7". The lanterns run Dame Hoolet 23, Pipkin 21, Little King Wren 18, Old Mother Mousewife 18, March Hare 16, Hob Mumblecrust 16, then you and Brother Bracken out. The panel shows "10 turn 9 + 3 big loss" and keeps the numbered markers.
2. **Text sizes, cues and contrast: fixed.**
   - Names, cues, lantern names and tally labels are 18 px (`.e-np`, `.e-pname`, `.e-tally-label`).
   - The cues are corrected: Sweetbriar "Compost in: +1/+1", Hedge Lancer "First attack: unhurt", Bell-ringer "Hand-me-downs +3".
   - Dimmed lantern health now measures 6.4:1 on ruby (fight and after, x 1805 to 1832); it was 4.0:1. "Fell" measures 12:1.

## What the fixes broke

Nothing that blocks. Moving E's controls 90 px left didn't collide with anything. The spell plates now share the unit baseline, and extra1's pane ends above Fight March Hare. D's new light-table glow doesn't wash out the cards.

## Blocking

None.

## Non-blocking (for the owner's report, not fixes)

1. **E after:** the result plaque's right frame (about x 580 to 595, y 480 to 530) runs under the Greatsword Bearer name plate. This overlap was there in round 2 and I missed it then. Moving the plaque about 20 px left clears it.
2. **A mid:** the hand's seven slots are still 3, 2, 2.
3. **D:** the light table is still full width, with plain margins either side of the board, and that is what keeps D at about average in the gallery. The designer's reason for not narrowing it (the picture's own lit table lies under the margins, and extra1 docks there) is fair.

## Scores (moved)

| | Look | Reading |
|---|---|---|
| A | 8.5 | 8.5 (unchanged) |
| D | 8 | 9 (unchanged) |
| E | 8.5 | 7.5 → 8 (18 px plates, correct cues) |

The three fixed things pass for all three.

## Not judged

Motion, timing, hover and drag feel, sound, and screen sizes other than 1920x1080.

## Disk

New this round: `/data/ui-ideation/tmp/council-opus/r3/` (7 PNG crops, 2.6 MB). The whole folder `/data/ui-ideation/tmp/council-opus/` (15 MB) can be removed now that the council's checks are done. Nothing else was written besides this file.
