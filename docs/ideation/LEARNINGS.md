# Ideation learnings

Gotchas, setup problems and what went wrong. Format as in `docs/prototype/LEARNINGS.md` (read that first: it covers this machine and the toolchain). Newest at the bottom.

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

## Bench worker (6 Nov)

- **`timeout` on a script doesn't reach its background children.** A 400 s `timeout` killed `bench.sh`, but its two Godot shards ran on, past the project's core share. `bench.sh` now traps exit and kills its jobs. Check `pgrep godot` after any killed run.
- **A planted bad bot can win.** The first plant (never climbs, 3 units) averaged 2.64th: all its gold went to refreshing for the 1-gold Sample Growth, the only tier 1 spell, to +138 Attack on three units. So that plant wasn't bad, and a cheap buff spell at tier 1 plus a 1-gold refresh is a line to watch in real content (Elderflower Cordial is also cost 1). The plant now also buys no spells and doesn't refresh.
- **A unit's Bot-placed board resets its counters.** `Bot.place` reassigns `player.board` directly, so nothing calls `move_on_board`. `BoardUpkeep.tick_turns` compares `home_slot` at End of Turn, so a bot that reshuffles each turn never reaches "After 3 turns". Keep a unit where it is if the turn count matters.
- **Spell cost is paid at the shop, not on play.** `play_item` never charges, so a test's `cast` needn't give gold. A hero or test passing a Variant to `AttackOrder` or `aims_shop` fails compile as unsafe: assign it to a typed local first.
- **`Combat.side_rules` must be set by anything running its own fight.** Without it Dame Hoolet's order and the Larder in a fight are off, silently. Use `RecruitRules.fight_rules(player)`.
- **Callables bound to a player leak.** `player.log_observer = f.bind(player)` is a RefCounted cycle; bind the id instead.

