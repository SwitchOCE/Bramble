# Ideation learnings

Gotchas, setup problems and what went wrong. Format as in `docs/prototype/LEARNINGS.md` (read that first: it covers this machine and the toolchain). Newest at the bottom.

## Godot UI (UI worker, 6 Nov)

- A Label with autowrap that was laid out at a narrow width keeps its tall minimum, so later sizes do nothing and its text drifts out of its box. Set `clip_text = true` when the box sets the size.
- Strict GDScript flags a private variable used only by a subclass as unused, in the base class. Declare it in the class that uses it.

- A child's `size` set while it is outside the tree emits no `resized`. A widget that places its own children on `resized` then sits at (0,0) until something else moves it. Connect the same function to `ready` too.
- A Control with PRESET_FULL_RECT anchors and a `size` set by hand logs "non-equal opposite anchors", and GUT fails on it. Pick one: anchors or `size`.
- `Button` draws before the script's `_draw`, so a hand-drawn button (leaf, token, latch) needs StyleBoxEmpty faces, a transparent size-1 font for its own `text` (tests read it) and child labels as its face.
- `_set` isn't called for native properties such as `disabled`. Check the value in `_draw` (Button redraws when it changes).
- Grenze's line height is very tall (about 1.5 em). A two-line name needs `line_spacing` about -16 at 34 px.
## Engine worker (6 Nov)

- **Strict typing and `[] if x else [y]`.** The ternary gives an untyped array; assigning it to `Array[BoardUnit]` fails at run time, not at compile. Build the typed array by hand.
- **RefCounted cycles fail the gate.** RecruitRules and its RecruitEvents pointed at each other: "1109 ObjectDB instances leaked" at exit, and the tests step goes red with every test green. One side holds a `WeakRef`.
- **`pgrep -f` matches your own shell.** `pgrep -f soak` from a command containing that word kills the command. Test `readlink /proc/$p/cwd` and the process name, or use `pgrep godot`.
- **`godot --quiet` silences `print`.** A `-s` script run with it prints nothing. Filter the banner with grep instead.
- **A script with a parse error can hang a headless run.** `soak.sh` sat for over three minutes on one. Compile first (`tools/checks/compile_all.gd`) and put `timeout` on every Godot call.
- **`tribes_in_rotation` reads the content.** Today it finds seven tribes, one of them (Hive) with one unit, so `full_game()` can draw Hive into a lobby of five. That's for the content workers to settle.
### 6 Nov 16:10 — Codex hangs on an open stdin; one image takes about 45 s

**What happened:** `codex exec` run from a background shell with a prompt argument produced nothing in 400 s. The same call with `</dev/null` made a 1.5 MB PNG in 43 s.
**Why:** it waits on stdin when stdin is left open, even with the prompt given as an argument. Closing stdin was the only change, so this is the likely cause rather than a proven one.
**Next time:** always `codex exec --skip-git-repo-check -s workspace-write -C <dir> "<prompt>" </dev/null`. `tools/art/run-codex-image.ps1` needs PowerShell, which this machine doesn't have. At 45 s each, 100 portraits take about 75 minutes one at a time; a few parallel runs are fine, since the work is remote.
