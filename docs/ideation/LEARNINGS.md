# Ideation learnings

Gotchas, setup problems and what went wrong. Format as in `docs/prototype/LEARNINGS.md` (read that first: it covers this machine and the toolchain). Newest at the bottom.

## Godot UI (UI worker, 6 Nov)

- A child's `size` set while it is outside the tree emits no `resized`. A widget that places its own children on `resized` then sits at (0,0) until something else moves it. Connect the same function to `ready` too.
- A Control with PRESET_FULL_RECT anchors and a `size` set by hand logs "non-equal opposite anchors", and GUT fails on it. Pick one: anchors or `size`.
- `Button` draws before the script's `_draw`, so a hand-drawn button (leaf, token, latch) needs StyleBoxEmpty faces, a transparent size-1 font for its own `text` (tests read it) and child labels as its face.
- `_set` isn't called for native properties such as `disabled`. Check the value in `_draw` (Button redraws when it changes).
- Grenze's line height is very tall (about 1.5 em). A two-line name needs `line_spacing` about -16 at 34 px.
