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

`turn`, `gold`, `tier`, `refresh_cost`, `frozen`, `health`, `hand_limit`; `upgrade_cost` (absent means no tier-up button); `hero` {name, portrait}; `counters` [{key or label or icon, value}]; `next_opponent` {name, portrait, health}; `message`; `shop_units` and `shop_spells` (unit, spell or null for a hole); `hand`; `board` (7 entries, unit or null); `slots` (7 entries, {buff, buff_name} or {}); `players` [{name, portrait, health, tier, you, next}]; `legal_actions` (the core's, as given); `display` (below); `discover` {prompt, options: [unit or spell]} while one is open.

A unit: {id, uid, name, tier, art, attack, health, max_health, text, golden, keywords, counters [{key or label, value}], price, sell_value, target, abilities}. A spell: {id, uid, name, art, cost, text, spell: true, target}. A hand card with `spell: true` is drawn as a spell.

- `target`: what the card's play aims at, `"unit"`, `"slot"` or `"shop"`; absent when it aims at nothing. `legal_actions` give the numbers but not their kind (a uid, a slot or a shop index), so the screen needs this to light the right things.
- `abilities` [{mechanic, target}]: the unit's own abilities. A button shows only while `legal_actions` lists an `ability` with that uid and mechanic; it is named from `display`.
- `display` {id: {name, reminder, shown}}: keywords, counters, abilities. A keyword or counter is drawn when the table has it and `shown` is not false (`hidden: true` also hides it); one the table lacks is not drawn. Ids or the flow's display names both work. Reminders are listed in the hover. With no table in the state, keywords and labels are drawn as given.
- Buttons are dimmed when their action is missing from `legal_actions`; nothing is dimmed when the state has no `legal_actions`.
- Answer `action_requested` with `show_state` from inside the handler: a dropped card then moves from where it was let go.

## Fight view state

The recruit state's `turn`, `health`, `hero`, `counters`, `players`, `display`, plus `opponent` {name, portrait, health}, `you_side`, `boards` [side 0, side 1] and `slots` [side 0, side 1]. `FightReplay.build(base, events, catalog, damage)` adds `boards` and `moment` per step: `lunge` {side, slot, target_side, target_slot}, `splashes` [{side, slot, amount}] (amount 0: destroyed), `trigger` {side, slot} (the unit whose effect is acting), `result` {winner, damage}. At the result the loser's Health (badge and leaderboard row) has the damage taken off. Fight uids are the fight's own; a recruit card matches its fight copy by side and slot only.

## Added 17 Nov, after the game flow's review

The first real tribe cards need three things the state did not carry. The flow fills them from the core's views and card data; the screen only draws them.

- **Abilities on a unit:** `abilities` [{id, name, text, cost, uses_left, usable, target_kind}]. `usable` false (can't afford, used up) still draws the button, dimmed.
- **What a target is:** `target_kind` is one of `none`, `unit` (a friendly unit's uid), `enemy`, `slot` (a board slot id), `shop` (a shop index). A hand card carries `target_kind` for playing it; each ability carries its own. The action the screen emits puts the picked target in the core's `target` field as that kind expects.
- **Slots:** each of the 7 entries is {attack, health, keywords [{id}], label} or {}: the real buff numbers, not only a name.
- **Counters and heaps:** each chip is {id, value}; the display table gives its name, reminder, icon and whether it is hidden. A heap chip also carries `entries` [{id, name, tier}] for its hover.
- **Fights:** the fight state carries both hands' Reserve units (so a unit stepping in has a card to draw), and the slots as the fight log changes them. Every fight-log event type that changes what is on the board (`summon`, a Reserve step-in, `move`, `keyword`, `slot`, `stats`, statuses spent) is replayed.
- **Discover:** `discover` {prompt, options, waiting}; options are full unit or spell entries with text.
- **Leaderboard rows:** `alive` false draws the eliminated look.
