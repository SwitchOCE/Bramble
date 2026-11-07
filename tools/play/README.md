# tools/play: play the real game by commands

Each call is one action. The save file holds only the seed and action list, and every call replays them through the real rules. Source `/opt/bramble/env.sh` first. On a fresh checkout the first call runs Godot's import, which takes a little longer.

```
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

The screen shows gold, tier, health, the hero, what you must choose, the shop and board with rules text, slot effects, what's in each Belly, Nests, who's away and when they land, your hand, what each keyword means, the lobby, your next opponent and the board they fought with last round, the last fight event by event, and what you may do now.

Every game uses the current full-strength bot lobby. There is no bot-strength setting.

Old saves containing retired bot settings are refused without rewriting the file. Old full-strength saves may replay with their obsolete metadata ignored, but all action lists use today's rules. If an old action no longer works, loading stops with its action number and reason; start a new game. A successful action rewrites an accepted old save in the seed/actions format.

Use the `@handle` printed beside each hand card, for example `play @123 B2` or
`play @456` to cash an Acorn. Handles stay with that card when buying adds units
before the items in hand. Old numeric hand positions remain accepted for saved
replays, but shift as the hand changes. A handle removed by a combine is refused.
