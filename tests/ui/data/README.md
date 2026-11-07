# UI test fixtures

These JSON states are test data, not the game. They hold cards from the older library, Oozes and Birds among them, which aren't in any lobby a player meets. Screens rendered from them are named `fixture_*` by `tests/ui/render_screens.sh`. Screens the player really sees come from `CorePort`, and tests keep them to what's in the game (`tests/ui/test_polish.gd`).
