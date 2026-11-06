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

## Bench worker (6 Nov)

- **`timeout` on a script doesn't reach its background children.** A 400 s `timeout` killed `bench.sh`, but its two Godot shards ran on, past the project's core share. `bench.sh` now traps exit and kills its jobs. Check `pgrep godot` after any killed run.
- **A planted bad bot can win.** The first plant (never climbs, 3 units) averaged 2.64th: all its gold went to refreshing for the 1-gold Sample Growth, the only tier 1 spell, to +138 Attack on three units. So that plant wasn't bad, and a cheap buff spell at tier 1 plus a 1-gold refresh is a line to watch in real content (Elderflower Cordial is also cost 1). The plant now also buys no spells and doesn't refresh.
- **Keyword reminders on screen come from `src/ui/keyword_rules.gd`, not from a view's `keyword_text` (UI, 6 Nov).** For the old library, `keyword_text` is the unit's `source.note`, which holds designers' notes. The screens read only the keyword's name from it. A new keyword goes in the schema's `keywords`.
- **A `stats` combat event can have zero deltas (UI, 6 Nov).** Aura recalculation emits them. The log and floats skip them.
- **A unit's Bot-placed board resets its counters.** `Bot.place` reassigns `player.board` directly, so nothing calls `move_on_board`. `BoardUpkeep.tick_turns` compares `home_slot` at End of Turn, so a bot that reshuffles each turn never reaches "After 3 turns". Keep a unit where it is if the turn count matters.
- **Spell cost is paid at the shop, not on play.** `play_item` never charges, so a test's `cast` needn't give gold. A hero or test passing a Variant to `AttackOrder` or `aims_shop` fails compile as unsafe: assign it to a typed local first.
- **`Combat.side_rules` must be set by anything running its own fight.** Without it Dame Hoolet's order and the Larder in a fight are off, silently. Use `RecruitRules.fight_rules(player)`.
- **Callables bound to a player leak.** `player.log_observer = f.bind(player)` is a RefCounted cycle; bind the id instead.
- **More search doesn't make Hard stronger.** With everyone scouting, the placing rule gets +0.90 places over a shuffled board and search adds about +0.04 at 20 or 200 fights. Look for Hard's edge in what it buys, not in more fights.
- **Small samples misled here.** Hard among Normal read 3.29 over 150 games at budget 30, and 3.70 over 500 at budget 20. Compare ladder changes at 500 games or more.
- **The bench's seat 0 is `human_bot`, not `bots`.** Anything that rewrites bot names has to cover both. `BotLobby.resolve` missed it once; the bench's error check caught it on its first varied run.
- **A scripted player's depth isn't a bot measure.** A plain greedy player beats Naive by about turn 16 and is out by turn 9 at Easy and above. Capping it at 3-4 units gives Naive games of turn 13-16, for UI coverage only.
- **A grid's height can go stale when its columns change.** The hand grid stayed shorter than its tiles for good, seen only by the layout check. `reset_size.call_deferred()` after filling it.
- **A count isn't an effect.** "play spell" fired 219 times in one 7-turn game: the driver retried Bread from the Back with no back-row unit, and that held card stopped it buying. Now a press must change the game or be refused aloud, and a card with no target isn't retried.
- **A freed overlay still takes taps until the frame ends.** `queue_free` is deferred; hide it first.
- **A click test must sort grids first.** A GridContainer places new tiles deferred, so a real click in the same frame as a render misses. `PlayerDriver` sends `NOTIFICATION_SORT_CHILDREN`; a person's tap comes frames later.
- **Don't wait with a pgrep loop.** `until ! pgrep -f "<words>"` matches its own command line and never ends; one sat idle for over an hour after the run had finished. Run the long command itself with `run_in_background: true` and wait for its notification.
- **A real click isn't proof by itself.** A button can take the click with its handler unhooked, so the scripted run also checks what each press did.
- **A partial bench rerun mixes commits.** Each suite now writes a stamp, and the report's last table says what ran on what. Check it before comparing suites.
