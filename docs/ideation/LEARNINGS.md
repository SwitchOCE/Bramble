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
- **A copying unit must not copy another copier.** Two Cradle Fetches in a row recursed until the stack blew, writing 280 MB of logs per run. A stuck bench shard can fill a disk; delete `.spread.*.log` after a failed run.
- **A strong economy card looks like a strong build.** Old Mother Mast with Treasurer took Treasury to 44.6% of lobbies and pushed games to 18.7 rounds. The Larder column in the per-round table showed it long before the win table did.
- **`number` params double on golden; `threshold` params don't.** Name a new param by which one you mean, and each must be at least 1 or `check_units.py` refuses it. That's why Rainbow's zero-gold paint is its own mechanic.
- **A bot's `rule_layout` can move the unit a Pass starts from,** so where the Pass lands changes with the swap. Judge each swap by the landing after it.
- **Easy can beat Hard by climbing.** When tier 6 bodies got big, Easy's leftover gold climbed it to tier 6 by round 9, and Hard won just 5% among Easy. Look at who wins a ladder suite, not just Hard's average place.
- **A `power` prior of 25 hides everything else.** Hard took one build in 98% of seats. Keep priors small enough that what's in hand decides.
- **Don't wait with `pgrep -f`:** the loop matches its own command line and never ends. Run the long command itself in the background.
- **A comparison table's "before" must be like with like.** A ladder row quoted a mid-step number as the baseline and hid that the step had made the ladder worse. Take "before" from the committed report.
- **`--out` copies of the tree need their own `.git` or lose the report:** `bench.sh` in a copy writes CSVs but no summary. Read the CSVs directly.

## Design process (orchestrator, 8 Nov, after the owner's Birds case study)

- Checks that work on one card at a time, or on the whole game at once, miss a tribe whose early cards nobody would buy. Cost each card at the moment it would be bought, with the board you'd have then, against the other cards the shop offers at that tier. Review each tribe as a journey from round 1 to round 10+. The owner spotted Birds in ten seconds; costing, tribe review and four playtest rounds did not. `evidence/birds-case-study.md`.
- When a sim shows a tribe is weak, fix the cards. Steering the bots away from the weak route hides it.
- Tally playtest problems across rounds. A problem that's second or third every round never reaches the fix list unless someone counts it.

## Memory (8 Nov, 21:59)

- The machine has 14 GB. A 4.2 GB Godot run plus other Godot processes ran it out of memory, and systemd killed the orchestrator's whole scope with it. Run one Godot process at a time per worker, each wrapped in `systemd-run --user --scope -p MemoryMax=3G --`, and never more than two workers running Godot at once.

## Codex workers keep their first instructions (8 Nov)

A resumed Codex thread (`resume_thread`) keeps the developer instructions it started with, and a worker won't treat a later message as overriding them. w4 and w5 stopped all Godot runs while w3 held the shared lock, though the owner's rule allows one capped process each. Keep machine rules in worker instructions general ("one Godot process at a time, each under `systemd-run --user --scope -p MemoryMax=3G --`"), and don't name a specific lock unless it's needed.

## Parallel designers need a merge step (9 Nov)

Three designers who each rank against the pre-pass benchmark produce ranks that disagree and selector clashes nobody sees (pass 2: Mallow's "smallest units" picked Shy units). After a parallel pass, rebuild the competition list from all docs and put every tribe's boards on one sheet before costing.

## Gate before push, in one command (9 Nov)

A merge was pushed while its gate had failed, because the push ran after the gate in a chain that didn't check the result. Run the gate and push together, pushing only on "all steps passed". Merging a measurement branch after a balance change also breaks fixture tests that pinned the old numbers (Hedge Witch Hex 6 → 5).

## Workers' targeted checks skip ruff format (10 Nov)

Two gates failed today on Python formatting alone, after every Godot test passed: wave 2b (`check_units.py`) and the Quilboar squash (two test files). Each failure cost a ~15-minute re-gate. Workers run targeted GUT files and their Python tests, but not `ruff format --check`, which the gate's python step runs first. Every worker hand-off check now includes `ruff check` and `ruff format --check` on `tools/`.

Also: two `cloud-gate.sh` runs started in the same second can collide on the push (the second one exits with "push failed", silently if its output is filtered). Start gates a few seconds apart, and don't filter their output down to the verdict line.

## The 1,000-line lint cap bites at merges (10 Nov)

The Quilboar merge (92cbce1f) passed every test on Actions and failed lint: `game_session.gd` reached 1,006 lines and `bot_brain.gd` 1,008. Each branch had kept its own file just under gdlint's `max-file-lines` cap, so the merge of two of them went over. On ideation/main and the wave 2b tip, `game_session.gd`, `combat_screen.gd` and `recruit_screen.gd` are at 999, `bot_brain.gd` at 1,000 and `recruit_rules.gd` at 996.
**Next time:** a branch that adds code to a file near the cap moves its feature's code into its own helper and leaves one-line calls, and extracts a cohesive static helper to leave room (target about 985). Before merging two branches that both grew the same file, count its lines on the merged tree.

## A safety filter stopped three analysis agents once (10 Nov)

Three of five triage agents were stopped by Anthropic's safety filter (`reasoning_extraction`), a false positive. The prompt had asked each agent to "write your full working notes" and spell out its thinking per hypothesis. A one-off, and nothing to overlearn (owner, 10 Nov): just ask for findings, justification and evidence rather than "working notes" or step-by-step thinking.
