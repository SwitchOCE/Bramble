# Ideation learnings

Gotchas, setup problems and what went wrong. Format as in `docs/prototype/LEARNINGS.md` (read that first: it covers this machine and the toolchain). Newest at the bottom.

## Engine worker (6 Nov)

- **Strict typing and `[] if x else [y]`.** The ternary gives an untyped array; assigning it to `Array[BoardUnit]` fails at run time, not at compile. Build the typed array by hand.
- **RefCounted cycles fail the gate.** RecruitRules and its RecruitEvents pointed at each other: "1109 ObjectDB instances leaked" at exit, and the tests step goes red with every test green. One side holds a `WeakRef`.
- **`pgrep -f` matches your own shell.** `pgrep -f soak` from a command containing that word kills the command. Test `readlink /proc/$p/cwd` and the process name, or use `pgrep godot`.
- **`godot --quiet` silences `print`.** A `-s` script run with it prints nothing. Filter the banner with grep instead.
- **A script with a parse error can hang a headless run.** `soak.sh` sat for over three minutes on one. Compile first (`tools/checks/compile_all.gd`) and put `timeout` on every Godot call.
- **`tribes_in_rotation` reads the content.** Today it finds seven tribes, one of them (Hive) with one unit, so `full_game()` can draw Hive into a lobby of five. That's for the content workers to settle.
