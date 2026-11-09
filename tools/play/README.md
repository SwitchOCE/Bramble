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

Field mode loads the library's source gameplay configuration, including any scale levers. The save stores the library path and SHA-256; keep that file in place and unchanged for replay. Scouting shows the field rival's current round board. See [strong-field mode](../../docs/ideation/strong-field.md) for library generation and limits.

The real UI accepts the same launch flag: `godot -- --field-library res://path/to/library.json`, then select Play. An invalid library produces a start-game error.

Old saves replay under today's rules; one with retired bot settings, or an action that no longer works, is refused (start a new game).

Play hand cards by the `@handle` beside them, for example `play @123 B2`, or `play @456` to cash an Acorn. Handles don't shift when you buy; hand numbers do.
