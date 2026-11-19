# Screens and game flow: who does what

The orchestrator's proposal for how the screens and the rules core meet. Three pieces, each owned by one place, so workers don't overlap.

## The pieces

- **The rules core** (`src/core/`): `GameSession` holds the game. `act(player, action)` takes an action dictionary and returns `""` or the reason it was refused. `view_for(player)` gives that player's state, prices, round, opponent and legal actions. A fight returns a fight log. The core knows nothing about screens.
- **The screens** (`src/screens/`): draw a plain view-state dictionary and report what the player did. No rules logic: a screen never decides whether a move is legal.
- **The game flow** (`src/game/`): owns the `GameSession`, the human's seat and the bots. It turns the core's views into the screens' view state, passes the player's actions to the core, and moves the game from recruit to fights to the next round to the end.

## What crosses between them

- **Screen to flow: one signal, `action_requested(action: Dictionary)`.** The dictionary is in the core's own action format (`buy`, `sell`, `play` with slot and target, `move`, `refresh`, `freeze`, `upgrade`, `pick`, `ability`, `end_turn`; `src/core/README.md` gives the fields). The flow passes it to `GameSession.act` unchanged and shows the refusal text if there is one. The earlier index-based signals (`buy_requested` and the rest) go.
- **Flow to screen: `show_state(state: Dictionary)`.** The state carries the core's `legal_actions` as given, so the screen can light valid targets and dim what can't be afforded without knowing any rule. Units and slots are named by the core's `uid` and slot ids.
- **The flow fills in what the core doesn't have:** each card's name, tier, text and art file (from the tribes' card data), player names and portraits, and the display table for keywords and counters (name, reminder text, icon, hidden).
- **Fights:** the flow snapshots both players' views before the fight, then hands the fight screen the two boards, the fight log and the result. `FightReplay.build(...)` turns the log into steps; `playback_finished` tells the flow to move on.

## View state (recruit), one shape (17 Nov, screens pass 2)

There is one shape for each thing. The screens read nothing else, and `ViewAdapter` (`src/game/view_adapter.gd`) is the only converter from the core's recruit views; the tests run real states through it. A unit's shown mechanics and numbers are read in one place, `CardTerms.unit_terms` (printed mechanics, plus the view's `effects`, `grants` and `totals`), which `ViewAdapter` and the fight's `FightReplay` both call, so a unit shows the same pills in the shop and in a fight.

`turn`, `gold`, `tier`, `refresh_cost`, `refreshes_left`, `frozen`, `health`, `hand_limit`; `upgrade_cost` (absent means no tier-up button); `hero` {name, portrait}; `counters`; `next_opponent` {name, portrait, health}; `message`; `shop_units` and `shop_spells` (unit, spell or null for a hole); `hand`; `board` (7 entries, unit or null); `slots`; `players`; `legal_actions` (the core's, as given); `display`; `discover` while one is open.

- **`refreshes_left`**: paid refreshes remaining in this turn at the current step, including the next one. Computed by `Rules` from the configured first step and step length. Free refreshes leave it unchanged.

- **A unit:** {id, uid, name, tier, art, attack, health, max_health, base_attack, base_health, text, golden, keywords, mechanics, amounts, counters, reminders, price or sell_value, spell: false, target_kind, abilities}.
  - `keywords` and `mechanics`: lists of ids, looked up in `display` by id only. A display name is never a key: names repeat across tribes ("Hopper" is five ids).
  - `amounts` {mechanic: n}: the core's summed number for each mechanic with one number (from the unit view's `totals`). A pill shows it when it differs from the printed one, and a given numbered term the text doesn't name gets a pill of its own ("Fury 2" on a unit given Fury).
  - `counters` [{id, value}].
  - `base_attack`, `base_health`: what the card prints; a number above is drawn green, below red (STAND-IN).
  - `text`: the core's view text, golden text included.
- **A spell:** {id, uid, name, art, cost, text, spell: true, target_kind}. A hand card with `spell: true` is drawn as a spell.
- **`target_kind`:** what a play or an ability aims at: `none`, `unit` (a friendly unit's uid), `enemy`, `slot` (a board slot id), `shop` (a shop index). The action the screen sends puts the picked target in the core's `target` field as that kind expects.
- **`abilities`** [{id, name, cost, usable, poor, used, target_kind, reminder}]: `name` is the display table's name (Bury), or empty for an Active, which shows only its gold cost: a coin holding the number (0 when free), as its card text starts "1: ...". `poor`: the gold is short (the coin shows the cost in red); `used`: its uses this turn are spent (the button dims). `reminder` (what it does, its N filled; for an Active the shared hidden `active` entry's) is the button's own hover. A button shows while `legal_actions` lists an `ability` with that uid and id, and is dimmed when `usable` is false.
- **`slots`:** 7 entries, each {attack, health, keywords [{id}], label, percent} or {}. `percent` (an Edgewright's 200 in a fight) scales the Attack the slot gives; absent means 100.
- **`counters`** (the player's): [{id, value}], drawn as named plates by the portrait. A heap also carries `entries` [{id, name, tier}]; hovering its plate lists them, the same ones counted ("Bramble Runner ×2 · tier 1").
- **`display`** {id: {name, reminder, icon, hidden}}: keywords, mechanics, counters, heaps, abilities. A term is drawn when the table has it and `hidden` is not true. `icon` names a plate's emblem (`assets/glass/ui/tr-<icon>.png`). A reminder with N is filled with the card's number; with no number it reads as the general rule ("gain Attack", not "gain N Attack").
- **`players`** [{name, portrait, health, tier, you, next, alive}]: `alive` false draws the eliminated look.
- **`discover`** {prompt, options, waiting}: options are full unit or spell entries with text; `waiting` is how many more Discovers wait.
- **`sources`** on a unit: lines saying where its numbers come from, drawn green in its hover: "Printed 6/5.", then each part by name ("Lancer +0/+8.", "Tide +2/+0.", "Its slot +1/+0."). Absent when it shows its printed numbers.
- **`leaving`** {card id: {to: "unit", uid} or {to: "heap", id}}: where cards that left in the player's last action went (a sold unit eaten, a shop unit buried), so they move there as they fade.
- Buttons are dimmed when their action is missing from `legal_actions`; nothing is dimmed when the state has no `legal_actions`.
- Answer `action_requested` with `show_state` from inside the handler: a dropped card then moves from where it was let go.

## Fight view state

The recruit state's `turn`, `health`, `hero`, `counters`, `players`, `display`, plus `opponent` {name, portrait, health}, `you_side`, `boards` [side 0, side 1] and `slots` [side 0, side 1], in the shapes above. `FightReplay.build(base, events, catalog, damage)` adds `boards`, `slots`, `counters` and `moment` per step:

- `moment`: `lunge` {side, slot, target_side, target_slot}; `splashes` [{side, slot, amount, blocked}] (amount 0 with no `blocked`: destroyed; `blocked` true: a hit that was prevented, drawn as a 0); `trigger` {side, slot} (the unit whose effect is acting); `joins` [{side, slot}] (units joining the attack, as Pile on: they move with the lunge); `result` {winner, damage}. At the result the loser's Health (badge and leaderboard row) has the damage taken off.
- `outnumbered` [side 0, side 1]: combat_start's outnumbered_by. Each unit of an outnumbered side carries `outnumbered` n; one whose terms name Outnumbered (Fury, Grudge) says "Outnumbered by n." in its hover.
- On a fight unit: `spent` [mechanic ids] (a keyword used up this fight, its pill dimmed) and `sources` (as in the recruit state, plus "X +a/+h this fight." and "Damage taken n.").
- Fight uids are the fight's own; a recruit card matches its fight copy by side and slot only.
- What the replay shows from the fight log: `trigger`, `attack`, `damage`, `destroy`, `death`, `summon`, `reserve` and `return` (a unit placed in its slot), `keyword`, `status`, `counter`, `uses`, `slot`, the unit numbers any event carries (`buff`, `stats`), `prevented` (the 0 burst), `slot_percent` (the slot's Attack scaled), `effect` (a mechanic given mid-fight, added to the unit's `amounts` and pills), `player_counter`, `heap_add` and `heap_remove` (the plate's number).
- Left silent: `turn_counter` is not a fight-log event; the attack flags `out_of_turn` and `takes_no_damage` show already as the lunge, the trigger glow and the 0 burst.
