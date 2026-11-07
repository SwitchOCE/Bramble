# Build 3: readable phone hero names

The short UI run on 730669a caught `Hob Mumblecrust` at size 30 during scouting at 1688×780. The hero plaque's desktop word-fitting loop also ran on phones, where the selected-card layout narrows the plaque to 170 canvas units. Mumblecrust needs 164 units at size 31, exceeding the old name area.

Phone names now stay at the existing minimum of 31, wrap between words, and shorten an overlong word with an ellipsis. The full name remains in the portrait's detail view and tooltip. An 8-unit inset keeps lettering off the border. Desktop fitting retains its existing minimum. The plaque and neighbouring controls keep their positions.

Regression: `test_phone_scout_hero_names_wrap_at_the_minimum_without_clipping` exercises Hob Mumblecrust and Old Mother Mousewife with scouting and Who? open. It checks font size, displayed word widths, line visibility, portrait clearance, label bounds and the full layout checks. Focused phone suite: 8/8 tests, 120 assertions.

[Inspected 1688×780 render](build3-phone-name.jpg), reproduced with `SCREEN_SIZES=1688x780 tests/ui/render_screens.sh scout_long_name`. Fixture state, with the hero name changed to exercise this layout; no real device test.
