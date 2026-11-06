# tools/play: play the real game by commands

Each call is one action. The save file holds only the seed, difficulty and action list, and every call replays them through the real rules. Source `/opt/bramble/env.sh` first. On a fresh checkout the first call runs Godot's import, which takes a little longer.

```
tools/play/play.sh new --seed 5 --difficulty hard    # prints "Save: <path>" (build/play/ unless --save)
tools/play/play.sh <save>                            # show the screen again
tools/play/play.sh <save> choose 1                   # a hero, or a Discover option
tools/play/play.sh <save> buy 2                      # shop numbers run on through units and spells
tools/play/play.sh <save> play 0 F2                  # hand numbers too; slot only if the card needs one
                                                     # an Acorn: "play 3" for gold, "play 3 F2" onto a unit that eats it
                                                     # Shake the Tree: "play 3 1" keeps shop number 1
tools/play/play.sh <save> move F1 B2                 # swaps if B2 is taken
tools/play/play.sh <save> sell B1
tools/play/play.sh <save> refresh | freeze | tier | end
tools/play/play.sh <save> power F1                   # hero power; slot only if it needs one
tools/play/play.sh <save> log                        # boards by round, placements, tribes
```

Add `--json` to any of them for the same thing as data. A refused action prints `REFUSED: why`, exits 3 and isn't saved.

Slots are `F1 F2 F3 F4` and `B1 B2 B3`. Numbers shift after each buy or play, so read the screen rather than batching on old numbers.

The screen shows gold, tier, health, the hero, what you must choose, the shop and board with rules text, slot effects, your hand, what each keyword means, the lobby, your next opponent, the last fight event by event, and what you may do now.

Difficulties are today's bot personalities, not a measured ladder (see `docs/ideation/DECISIONS.md`). A call takes about 0.7 s of CPU at the end of a game, so no cache is needed.
