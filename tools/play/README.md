# tools/play: play the real game by commands

Each call is one action. The save holds the seed and action list; every call replays them through the real rules. Source `/opt/bramble/env.sh` first. The first call on a fresh checkout is slower (Godot's import).

```
tools/play/play.sh help            # the guide and card terms
tools/play/play.sh new --seed 5    # prints "Save: <path>" (build/play/ unless --save)
tools/play/play.sh <save>                            # show the screen again
tools/play/play.sh <save> choose 1                   # a hero, or a Discover option
tools/play/play.sh <save> buy 2                      # shop numbers run on through units and spells
tools/play/play.sh <save> play 0 F2                  # hand numbers too; slot only if the card needs one
                                                     # an Acorn: "play 3" for gold, "play 3 F2" onto a unit that eats it
                                                     # Shake the Tree: "play 3 1" keeps shop number 1
tools/play/play.sh <save> move F1 B2                 # swaps if B2 is taken
tools/play/play.sh <save> sell B1                    # a bird flies south unless it was played this turn
tools/play/play.sh <save> swallow 2 F1               # Belly: buy shop number 2 straight into the Ooze on F1
tools/play/play.sh <save> swallow h0 F1              # from hand number 0, or: swallow B2 F1 from the board
tools/play/play.sh <save> refresh | freeze | tier | end
tools/play/play.sh <save> power F1                   # hero power; slot only if it needs one
tools/play/play.sh <save> log                        # boards by round, placements, tribes
```

Add `--json` to any of them for the same thing as data. A refused action prints `REFUSED: why`, exits 3 and isn't saved.

Slots are `F1 F2 F3 F4` and `B1 B2 B3`. Numbers shift after each buy or play, so read the screen rather than batching on old numbers.

The screen shows what a player can see: gold, tier, health, hero, shop, board, hand, Bellies and Nests, keyword meanings and card details, the lobby, your next opponent's last board, the last fight and your legal moves.

Games use the full-strength bot lobby by default. Start a strong-field game with:

```sh
tools/play/play.sh new --seed 5 --field-library res://path/to/library.json
```

Field mode loads the library's source gameplay configuration, including any scale levers. It defaults to top-four source seats; add `--field-strength all` for all finishes. The save stores the library path, SHA-256 and strength; keep that file in place and unchanged for replay. Scouting shows the rival's previous-round board, with nothing shown in round one. See [strong-field mode](../../docs/ideation/strong-field.md) for library generation and limits.

The source-tree UI accepts the same launch flag: `godot -- --field-library res://path/to/library.json`, then select Play. With the `strong_field` feature enabled, Settings also offers the touch-accessible Bots / Strong field choice. An invalid library produces a start-game error. Player exports currently disable the feature and contain no library, pending the full new pool.

Old saves replay under today's rules; one with retired bot settings, or an action that no longer works, is refused (start a new game).

Play hand cards by the `@handle` beside them, for example `play @123 B2`, or `play @456` to cash an Acorn. Handles don't shift when you buy; hand numbers do.

## Blind variants (checkpoint testers)

```sh
BRAMBLE_VARIANT_MAP=/path/to/map.json tools/play/play.sh new --seed 5 --variant X
```

The map is JSON the tester never sees. Each of `X` and `Y` names a preset in `content/pass3/rates.json`, or a preset with its field library:

```json
{"X": "C", "Y": "B"}
{"X": {"preset": "C", "field_library": "res://build/fields/x.json", "field_strength": "top4"}, "Y": "B"}
```

Use neutral library filenames such as `x.json`: paths can appear in diagnostics, so a preset name in the filename would unblind testers. `--variant` always refuses `--field-library`; the orchestrator supplies the library through the map.

With no map, `--variant` is refused. A library captured on another preset is refused too, without naming either preset.

The save keeps the variant letter and seals both the preset and any field-library reference in base64, so it replays without the map and doesn't change if the map does. Nothing a tester is shown names the preset: not the screen, `log`, `--json`, nor the save's path. The seal hides the preset from a glance, not from a tester who decodes their own save, so testers play through the commands and don't open saves.

The orchestrator reads it with:

```sh
tools/play/play.sh <save> reveal     # "Variant X plays preset C", plus the field library if any
tools/play/play.sh <save> hash       # the state hash (SHA-256 of the player's state)
```

## Rendering a played game on the real UI

```sh
tools/play/render.sh <save> [--turn N | --all]     # default --all
```

Replays the save through the real `CorePort` on the current commit and draws the real screens under xvfb and Mesa, at 1688×780 and 1920×1080 (`RENDER_SIZES="1688x780"` for one). For each turn:

- `rNN-start`: the recruit screen as the turn starts;
- `rNN-end`: the recruit screen just before End turn;
- `rNN-fight-1` to `-6`: a frame strip of that turn's fight, the last at the result;
- `over`: the game-over screen, if the game ended (`--all` only).

Files go to `build/render/<save stem>/` with an `index.md` that names the commit (marked if the tree has uncommitted changes), each moment's state hash and its files, and a `manifest_<size>.json` per size with the full hashes and what each fight screen was given. A save can't be drawn if one of its actions no longer replays.

A turn takes about 30 seconds per size on one Mesa thread; `LP_NUM_THREADS=4` is quicker where the cores are free. `tools/play/test_render.sh` is its test: it renders a short game twice and checks the hashes, the file lists, and each strip against `log`.

## Game logs from the UI

When a game ends, the UI writes `user://games/<timestamp>-<seed>.json`: the seed, the settings (preset, field library path and SHA-256, strength, Ask for kin), the hero, the placement, the final state hash, the build commit, and every action in the words above. Replay one with:

```sh
tools/play/play.sh replay-log <file> [--save path] [--field-library path]
```

It prints the final screen and state hash and keeps a save (`build/play/replay-<stem>.json` unless `--save` says), which `render.sh` can draw. `--field-library` points at the library when it isn't at the recorded path; its SHA-256 must still match. Replay refuses a different build commit, final state hash, placement or hero, with a message naming the mismatch. Source-tree games read the commit from Git; `build/export.sh` stamps `application/config/build_commit` into its archived project for all exports. Without a source commit, development games record `dev`; replay explicitly refuses this unverifiable id, as well as a missing build id.

**The UI hook** (`src/ui/game_record_log.gd`, `GameRecordLog`):

1. Keep an `actions` array per game, emptied when a game starts.
2. Before each GamePort call that changes the game (`buy`, `buy_spell`, `sell`, `move`, `play`, `play_item`, `swallow`, `refresh`, `ask_for_kin`, `toggle_freeze`, `tier_up`, `use_power`, `choose`, `end_turn`, `dev_add_gold`, `dev_spawn_to_hand`, `dev_set_tier`, `dev_skip_turn`), take `var before := port.get_state()`. If the call returns `""`, append `GameRecordLog.words(method, args, before)`. The screens call the port from several places, so `CorePort`, which every call passes through, is the natural place for this.
3. When the game ends (the game-over screen), call `GameRecordLog.write(port, actions)` once. It returns the path, or `""` if the file couldn't be written.

Dev-panel calls are recorded under their own names, and replay refuses them by name: a game that used the dev panel can't be replayed.
