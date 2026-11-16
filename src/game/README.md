# Game flow

Joins the rules core (`src/core/`) and the screens (`src/screens/`) into one game against bots, on the ideation track 2. Nothing here is decided for the real game. The contract with the screens is `docs/ideation-track-2/SCREEN-CONTRACT.md`.

| File | What |
|---|---|
| `game_content.gd` | The content seam: registry, card library, art and display names. Today the STAND-IN cards in `data/stand_in_units.json` (the core's neutral test cards with text and the mock-ups' art); switches to the core's tribe loader when it lands. |
| `game_flow.gd` | Headless: one `GameSession`, the human in seat 0, a `SimpleBot` in seats 1-7. `start_round`, `act`, `finish_round` (bots play, the human's fight is snapshot, every pair fights), `play_out` (bots finish the game once the human is out), `standings`. Stand-in names and portraits are the mock-ups' eight. |
| `view_adapter.gd` | `view_for` to the screens' view state; the fight screen's base state and catalog. |
| `recruit_seam.gd` | Passes the recruit screen's `action_requested` through, or turns its older index signals into the same actions. |
| `game_controller.gd` | On screen: recruit, the human's fight, the round's leaderboard, the next round, the end. |
| `ui/` | The plain screens: start, result, pause panel, and a stand-in Discover picker. Each matches its page in `docs/ideation-track-2/mockups/` (`python3 tools/glass/compare.py res://tests/game/start_compare.tscn docs/ideation-track-2/mockups/start.html --local`). |

## How a game runs

1. **Start screen:** Play (and, once tribes load, which tribes are in the lobby; all by default).
2. **Recruit:** the human acts at their own pace. **There is no turn timer in this build**; End turn (the next opponent's portrait) ends the turn. A refused action shows the core's reason as the screen's message.
3. **Fight:** the bots take their turns, every pair fights, and the human's fight plays from its log. Space, any key or a click skips to the result. The other fights are not shown. After the fight the leaderboard shows everyone's Health for 4 seconds, or until a click or key.
4. **End:** when the human is out, the bots play the game to its end so all eight places are known; when the human wins, the game ends there. The result screen shows the places; Play again or Quit.

Escape opens the pause panel (Resume, Quit to start, Quit). F11 toggles fullscreen. The 1920 x 1080 stage is letterboxed in any window.

**Testing aids:** F8 in a debug build turns autoplay on or off (a `SimpleBot` plays your turns and fights are skipped); `godot -- --autoplay` starts a game at once with autoplay on.
