# Type line and keyword tooltip choices

- **Strip colour.** The notes offered cream or dark glass. I used the mock-up's cream texture,
  lead edges and dark ink so the type reads across the different tier frames.
- **Art overlap.** The options were a strip across the art or a frame redesign that made room.
  I used the drawn strip, covering about 20 px at board size, to match the above-stats decision.
- **One-word types.** The notes offered omitting types like Locust or Briar. I printed all types
  because the type line is where a player learns what any unit is.
- **Font and fit.** The mock-up uses Alegreya Sans at weight 800. I used the game's bundled
  Alegreya Sans Bold (700) to stay within the existing assets. Godot steps down whole pixels
  until the full type fits, and also reduces the hover kind line if a type and price fill it.
- **Missing types.** All 108 shipped units have types, including tokens. Old view dictionaries
  resolve by ID against the shipped library. For an unidentified fixture or old ID I omit the
  strip and keep the generic hover kind. I kept spell faces and spell cost wording as drawn.
- **Hand, fight and border marks.** The mock-up illustrates a board hover. I used the same
  left-light origin for shop, board, hand and fight and kept their existing card hover shapes.
  Pointing at a small mark still shows that term and its first-level references.
- **Other screens.** The card browser has filters and a card grid where the left light would
  be. I kept the existing browser hover placement and used the fixed column on the two game screens.
- **Long keyword stacks.** The page shows three boxes. I kept all eligible terms and the
  same top-left corner, scaling a tall stack together only if it would reach the hero area.
- **Live Grudge wording.** The brief defers a Grudge wording change. The requested dev base
  already contains the start-of-turn wording and numbered Grudge from commit `5aca3419`.
  I kept the data and let the live reminder render from it.

## Charge and Supply pips move above the type strip (orchestrator; the owner kept it, 22 Nov, PLAN decision 14)

- **What:** the pips sat just over the stat discs, where the new type strip now is, so on the Home Guard they covered its type. Neither mock-up shows pips.
- **Options:** pips above the strip; pips below it, which would cover the discs; or a shorter strip on cards with pips.
- **Chose:** above the strip (`CardPips.make(..., type_line)`), so both stay readable and the strip stays the same on every card. `test_pips_clear_the_type_line` checks it.
