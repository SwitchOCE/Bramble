# Game flow mock-ups

HTML mock-ups for the screens the glass mock-ups (`design/glass-mockups`) do not have: `start.html`, `result.html`, and `pause.html` (the pause panel, and `?panel=hint` for the fight's skip hint). Plain on purpose, made only of the glass mock-ups' own pieces. Ideation track 2; nothing here is decided.

- `stage.css` and `stage.js` are copied unchanged from `docs/design/art-direction/mockups/` on `design/glass-mockups` at `8279442b`. `assets` links to the game's `assets/glass`, which holds the same pictures and fonts.
- `menus.js` and `menus.css` hold the shared helpers; the places are mirrored in `src/game/ui/`.
- Compare with the game: `python3 tools/glass/compare.py res://tests/game/start_compare.tscn docs/ideation-track-2/mockups/start.html --local` (also `result_compare`, `pause_compare`, and `hint_compare` with `--query panel=hint`). On 17 Nov all four were under 2 of 255 mean difference.
