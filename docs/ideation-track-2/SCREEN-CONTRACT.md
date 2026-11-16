# Screens and game flow: who does what

The orchestrator's proposal for how the screens and the rules core meet. Three pieces, each owned by one place, so workers don't overlap.

## The pieces

- **The rules core** (`src/core/`): `GameSession` holds the game. `act(player, action)` takes an action dictionary and returns `""` or the reason it was refused. `view_for(player)` gives that player's state, prices, round, opponent and legal actions. A fight returns a fight log. The core knows nothing about screens.
- **The screens** (`src/screens/`): draw a plain view-state dictionary and report what the player did. No rules logic: a screen never decides whether a move is legal.
- **The game flow** (`src/game/`): owns the `GameSession`, the human's seat and the bots. It turns the core's views into the screens' view state, passes the player's actions to the core, and moves the game from recruit to fights to the next round to the end.

## What crosses between them

- **Screen to flow: one signal, `action_requested(action: Dictionary)`.** The dictionary is in the core's own action format (`buy`, `sell`, `play` with slot and target, `move`, `refresh`, `freeze`, `upgrade`, `pick`, `ability`, `end_turn`; `src/core/README.md` gives the fields). The flow passes it to `GameSession.act` unchanged and shows the refusal text if there is one. The earlier index-based signals (`buy_requested` and the rest) go.
- **Flow to screen: `show_state(state: Dictionary)`.** The state carries the core's `legal_actions` as given, so the screen can light valid targets and dim what can't be afforded without knowing any rule. Units and slots are named by the core's `uid` and slot ids.
- **The flow fills in what the core doesn't have:** each card's name, tier, text and art file (from the tribes' card data), player names and portraits, and the display table for keywords and counters (name, reminder text, shown or hidden).
- **Fights:** the flow snapshots both players' views before the fight, then hands the fight screen the two boards, the fight log and the result. `FightReplay.build(...)` turns the log into steps; `playback_finished` tells the flow to move on.

## View state (recruit), as the screen draws it today

`turn`, `gold`, `tier`, `refresh_cost`, `frozen`, `health`, `hand_limit`; `upgrade_cost` (absent means no tier-up button); `hero` {name, portrait}; `counters` [{icon or label, value}]; `next_opponent` {name, portrait, health}; `message`; `shop_units` and `shop_spells` (unit, spell or null for a hole); `hand`; `board` (7 entries, unit or null); `slots` (7 entries, {buff, buff_name} or {}); `players` [{name, portrait, health, tier, you, next}]; to be added: `legal_actions`, `discover` {prompt, options} when one is open.

A unit: {id, uid, name, tier, art, attack, health, max_health, text, golden, keywords, counters [{label, value}], price, sell_value}. A spell: {id, uid, name, art, cost, text}.
