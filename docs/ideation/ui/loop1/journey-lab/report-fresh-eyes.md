# Fresh eyes: layout B

## 1. Beside the references

Layout B is a strong base, but its simplicity currently depends partly on leaving difficult states unresolved.

Compared at original resolution: lab recruit stops 1, 3 and 5; fight stops 3 and 5; phone recruit; shapes and layout studies. Reference filenames below are under `/data/bramble-reference/<game>/`.

- **The Bazaar:** `merchant-shop-choice--steam-shop-0004.jpg`, `main-play-busy--bek-ending-0004.jpg`, `fight--steam-trailer-0034.jpg`. B makes ownership and shop controls clearer through separate contained zones. Its large portraits are easy to scan. However, Bazaar packs a busy board into a continuous horizontal reading path; B spreads attention between shop, left hand and right actions. The huge End turn button and awning consume attention and space without improving board reading.
- **Battlegrounds:** `recruit-full--podmates-rounds-0036.jpg`, `fight-big-moment--podmates-rounds-0040.jpg`, `opponent-board--android-rounds-0041.jpg`, `card-inspect--android-rounds-0007.jpg`. B has calmer surfaces and clearer front/back placement. Battlegrounds shows specific statuses, mixed card types and substantial inspection text; B's generic ability symbols conceal distinctions needed for decisions. Less visible information is not automatically greater clarity.
- **TFT:** `recruit-full--pajos-rounds-0031.jpg`, `fight-start--pajos-combat-0005.jpg`, `card-inspect--android1080-deaths-0009.jpg`. B avoids competing trait, bench and detail panels and exposes individual stats better. TFT gives combat an open shared field and inspection a dedicated surface. B's tightly contained boards make crossing attacks harder to stage.

Our supplied recruit/fight frames already separate shop and board. B's valuable improvements are shop-local controls and a stable board, rather than an entirely different arrangement. Our full-hand row and separate reader solve needs B still has open.

## 2. Real game states

- **Ten-card, mixed hand:** the left tray works for one or two. In a temporary browser-only ten-unit probe, four appeared, with the second row touching the screen bottom; six were below view. The lab itself caps purchases at four hand cards. Keep the left-side direction, but design an expandable or overlapping hand with reliable selection, a count, and visible unit/spell differences. Scrolling alone hides choices during buying.
- **Seven versus seven:** stop 5 fits clearly at rest. Animated hits and deaths preserve surviving units' positions, helping tracking. Back-row attacks must cross friendly cards and both frames; damage effects need room beyond the packed silhouettes. Keep board anchors fixed while allowing attack effects across boundaries. Real triggers and simultaneous effects remain untested.
- **Scouting during recruit:** the portrait strip provides a natural entry, but no scouting interaction is implemented. Temporarily use the upper zone for a clearly named inspected board, keep your board fixed, and provide an obvious return to market. Preserve purchase context and distinguish scouting from combat.
- **Large stats, golden, keywords:** golden borders remain readable. Replacing board stats with 999 in the browser visibly overflowed the badges and crowded adjacent values. Reserve wider number space. A bolt or generic ability ring cannot distinguish several active keywords; expose decision-relevant statuses without requiring repeated inspection.
- **Inspection:** PC hover produced a readable separate tooltip, although it covered part of End turn. Phone tap flipped the card into tiny rules text with a Sell action. Use a larger persistent reader, retaining the selected unit's identity and clearly separated actions; test long text and keyword explanations.
- **1688×780:** the main zones remain separated, but boards shrink while spare width becomes broad side areas. Tap inspection suffers especially. Create rules for this aspect ratio rather than treating uniform stage scaling as the solution. Physical phone comfort was not tested.

## 3. The twelve rules

1. **Clean Arena base:** yes; preserve its hierarchy, with capacity work still required.
2. **Board never moves:** strong rule for the frame and slots. Do not interpret it as forbidding attack motion.
3. **Board centred:** a useful stable anchor; costs flexibility when hand and inspection need room.
4. **Equal unit sizes everywhere:** excellent object continuity; conflicts directly with ten-card hand capacity. Test overlap or expansion before sacrificing readability.
5. **Contained board:** yes; clear ownership. The frame must not clip combat effects.
6. **Shop-local controls:** yes; connects spending to its target. Oversized buttons are not required.
7. **Height to boards:** yes; competes with readable hand and inspection space, particularly on phones.
8. **Right, vertically centred leaderboard:** workable. Small portraits cost names and scouting detail; selection must reveal them.
9. **B's specific placements:** coherent starting arrangement; the left hand remains its largest unresolved cost.
10. **Rounded tall hex:** packing works. Reserve room for badges and selection outlines at the tucked corners.
11. **Offset 4–3 board:** holds at full occupancy; retain stable slots through deaths and rearrangement.
12. **Ignore placeholder art fit:** appropriate now. Information legibility and hit areas still require scrutiny.

## 4. Further ideas and play risks

Keep the background darkening in combat, opposing front rows, distinct attack/health shapes, and area changes around a stable board. These communicate state without tutorial paragraphs. Repeated card flips and lengthy arrival reveals risk delaying routine decisions; shorten them in repeat play.

Only this report was written; no commits or Godot runs. Browser probes changed temporary page state only. Screenshots and browser checks cannot establish real combat timing or touch usability.

## Three most important points

- Keep B's fixed board and shop-local controls: they make ownership and phase changes clearer.
- Resolve ten-card hands and three-digit stats before treating the layout as settled.
- Give phone inspection a readable separate surface, and prove full-board combat effects in motion.
