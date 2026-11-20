# Game flow

The game flow joins the [rules core](../core/README.md), [ghost store](../ghosts/README.md)
and screens. The [screen contract](../../docs/ideation-track-2/SCREEN-CONTRACT.md)
defines the view data.

| File | Role |
|---|---|
| `game_content.gd` | Loads all tribe folders and builds the card library, mechanic registry and display table. It supplies the async session with the lobby's cards and standing mechanics. |
| `game_flow.gd` | Picks seven ghost runs with the local matchmaker, seats the human at 0, drives the round and saves the human's run. The stand-in names and portraits belong to seats. |
| `view_adapter.gd` | Builds recruit and fight views, including the next opponent, the lobby's simulated health and the boards that entered the fight. |
| `game_controller.gd` | Drives recruit, fight playback, past boards and the result. |
| `ui/` | Start, result, pause and game settings. |

## How a game runs

1. **Start.** All five tribes are in the lobby. The local matchmaker picks seven completed bot
   runs from the field for this rules hash. An app session uses each run at most once, across
   Play again and returns to Start. Restart Bramble to play again after the session uses up
   the field.
2. **Recruit.** The player acts at their own pace. The next opponent's portrait and health are
   shown. End turn starts combat.
3. **Fight.** Each ghost brings its recorded board for the current round. If its run ended
   earlier, it brings its last board. The lobby fights and applies damage normally. Space,
   Enter or a click can skip the player's playback to the result. **Past boards** in recruit lets
   the player browse the starting boards of the fights they played.
4. **End.** If the human is eliminated, the remaining ghosts play out for the final eight
   placements. The player's record is cut and saved in `user://ghosts` with source kind
   `player`. Only finished games become ghosts. The shipped bot field supplies the opponents.

Escape opens the pause panel during play and closes Past boards. F11 toggles fullscreen.

## Development field and records

The exported game uses the verified field at `res://ghosts/field`. The presets preserve
GDScript source so the exported runtime computes the same rules hash as the editor.
An editor run without a field shows “Error G1: this build has no ghosts to play against.”
Use `--ghost-field` with an indexed field cut at the current rules hash for local development.
From the repository root, `tools/league/proof/make_field.sh /absolute/path/to/field` makes
a field from 1,000 live games between the final red and blue bots.

```sh
godot -- --seed 7 --ghost-field /absolute/path/to/field
godot --headless -- --autoplay --seed 7 --ghost-field /absolute/path/to/field
godot --headless -- --replay-record /absolute/path/to/record.jsonl --ghost-field /absolute/path/to/field
```

`--seed` sets both the rules seed and the matchmaking draw. The record in `user://records`
names the exact ghost run IDs and replays with their store. Keep the original field to replay
the record. The replay command also accepts `--ghost-store <folder>` to read directly from a
single folder.

Autoplay uses a SimpleBot for the human seat and skips fight playback. It prints the record path
at the result and exits when started headlessly. F8 toggles autoplay in a debug build.
