# Rules core

A headless rules engine for the second ideation track, following [rulebook v0.8](../../docs/design/rulebook.md) with no heroes or hero powers. Every class is `RefCounted`; nothing here is a Node. Nothing in it is decided for the real game (`CLAUDE.md`, "Main and its archive").

## Layout

| Folder | What |
|---|---|
| `util/` | `CoreUtil` typed conversions; `Rng`, the core's own FNV-1a hash and xoshiro128** generator |
| `rules/` | `GameConfig` (every Appendix A number), `Rules` (named rule queries: base answer, then unit text, then caps) |
| `board/` | `BoardGeometry` (chapter 8 as instance data), `Selectors` (positional selectors, written once) |
| `units/` | `UnitDef` (card data), `UnitLibrary` (JSON loader and checker), `Unit` (a held card), `StatBlock` (stat layers), `CardPool` (the shared pool) |
| `mechanics/` | `Mechanic` (the hook interface), `MechanicParams` (typed parameters), `MechanicRegistry`, and the built-in keywords and effects |
| `recruit/` | `PlayerState`, `Recruit` (the Recruit Phase and its actions), `RecruitContext` (what recruit hooks may do), `LegalActions` |
| `combat/` | `Combat` (one fight and its log), `CombatUnit` |
| `session/` | `GameSession` (the lobby and round flow), `Matchmaking` |
| `bots/` | `Bot`, `SimpleBot` (greedy), `RandomBot` (random legal play, for the soak) |

The neutral test units are in `tests/core/data/neutral_units.json`. They are not content.

## Phase order

A round, driven by a bot, a test or a UI:

1. `GameSession.start_round()`: round + 1; pairing (2.3: a seeded round-robin while all 8 live, then the least-repeating pairing over the last 3 rounds); the ghost for an odd player out (2.1.2); then each living player's start of turn (3.2.1): gold = carried + income, the upgrade discount from turn 2, the refresh count reset, the shop refilled (a frozen shop keeps its cards), start-of-turn triggers in reading order.
2. `GameSession.act(player, action)` as often as the player likes (3.3). Actions are dictionaries: `buy`, `sell`, `play` (units and spells), `move`, `refresh`, `freeze`, `upgrade`, `pick` (a Discover choice, the only legal action while one is open), `end_turn`. `act` returns `""` or why the action is illegal, and an illegal action changes nothing. `GameSession.legal_actions(player)` lists every legal action. After each action, triples form (7.3.1, after all summons) and auras are recomputed (12.2.1).
3. `end_turn` (3.4.1): End of Turn triggers, "this turn" ends, an unfrozen shop goes back to the pool, gold is kept.
4. `GameSession.finish_round()`: ends any open turn; every pair fights (chapter 9); the loser takes the round's small or big loss (10.1); eliminations after all fights, placed by health (10.2); cards of eliminated players go back to the pool (5.3.8); the game ends with one player left or at round 50 (2.1.3).

Inside a fight (`Combat.run`): copy boards → `on_combat_begin` → `combat_start` → first attacker (9.2.1) → Start of Combat (9.3; deaths after each effect) → alternate attacks with the attack pointer (9.4.5): `on_attacked`, `on_attack`, damage exchange with cleave splash, death resolution (9.7: dying units leave first; kills; own death effects and death counters, active side first then reading order; returns) → end (9.9) or a limit (9.10, a tie).

## Event schema

Every event is a JSON-shaped Dictionary with a `type`. Slots are 0–6 in reading order (`F1`–`F4` are 0–3, `B1`–`B3` are 4–6); `side` is 0 or 1; `uid` names one unit for the whole fight. Fights record `GameSession.fights[i].events`; everything else goes to `GameSession.events`, each event with `round` and, for player events, `player`.

**Fight log** (`Combat.events`):

| type | fields |
|---|---|
| `combat_start` | `players` [a, b], `first` side, `boards` [[unit view], [unit view]]; unit view = `uid, id, side, slot, label, attack, health, golden, keywords` |
| `trigger` | `side, slot, uid, mechanic` (a hook acted; `return` for a unit coming back) |
| `attack` | `side, slot, uid, target_side, target_slot, target_uid` |
| `damage` | `side, slot, uid, amount` (> 0), `health` after, `source_uid` (-1 for none) |
| `destroy` | `side, slot, uid, source_uid` |
| `buff` | `side, slot, uid, attack, health` (new values), `source_uid` |
| `status` | `side, slot, uid, status, on` (a shield popping, stealth ending) |
| `death` | `side, slot, uid` (the slot it left) |
| `summon` | `side, slot, uid, id, attack, health, golden, source_uid` |
| `summon_failed` | `side, id` |
| `return` | `side, slot, uid` (the new one), `from_uid`, `health` |
| `pass` | `side` |
| `combat_end` | `winner` (side, or -1 for a tie), `reason` (`board_empty`, `no_attacks`, `attack_limit`, `trigger_limit`), `starting` [n, n], `killed` [n, n] (starting units killed, 10.1.2), `attacks`, `triggers`, `survivors` [[uid], [uid]] |

**Game log** (`GameSession.events`): `round_start` (`pairs`), `turn_start` (`gold`, `shop`), `buy`, `sell`, `play`, `cast`, `move`, `refresh`, `freeze`, `upgrade`, `discover` (`options`), `discover_queued` (`waiting`), `pick`, `gain`, `card_lost`, `summon`, `summon_failed`, `triple`, `trigger`, `buff`, `gold`, `turn_end`, `fight` (`players`, `winner`, `loser`, `damage`, `reason`), `eliminated` (`placement`, `health`), `game_end` (`placements`). `PlayerState.view()` and `Unit.view()` give the state a UI shows. The screens read `PlayerState.view()` and the fight log, not the game log, which stays small.

## How a mechanic plugs in

1. Write a script that `extends Mechanic` and overrides only the hooks it needs. Each hook names its rule step: `on_played`, `on_start_of_turn`, `on_end_of_turn`, `on_sold` (recruit); `on_combat_begin`, `on_start_of_combat`, `on_attacked`, `on_attack`, `on_damage_dealt`, `absorb_damage`, `on_kill`, `on_death`, `on_friendly_death` (combat); `combat_query` (taunt, untargetable, cleave, attacks per turn, return Health); `aura` with `has_aura`; `modify_int` (the unit layer of any rule query, such as sell value or refresh cost).
2. Declare its parameters once in `param_kinds()`: `NUMBER` (doubled on a golden, 7.3.5), `THRESHOLD` (never doubled) or `TEXT`. The library rejects card data with an unknown, missing or wrongly typed parameter.
3. Act only through the context: `RecruitContext` (`trigger`, `buff`, `summon`, `gain_gold`, `discover`, `select`, `random_of`) or `Combat` (`trigger`, `buff`, `deal_damage`, `destroy`, `summon`, `select`, `random_enemy`, `show_status`, `effect_rng`). Call `trigger(unit, id)` first: it logs the trigger and counts it against the limits (9.10.2). Keep no state on the script, since one instance serves every unit; per-fight state goes in `CombatUnit.state`.
4. Register it: add it to `MechanicRegistry.BUILT_IN`, or call `registry.register(&"id", MyMechanic.new())` from the game's set-up. Card data then names it: `"effects": [{"mechanic": "id", ...params}]`, or `"keywords": ["id"]` for one without parameters.

Rule queries have one layer for now, unit text; game- and player-level layers (an anomaly, a quest) come back when something needs them. `tests/core/test_mechanic_interface.gd` plugs in a mechanic and a unit-level rule from outside the core.

The Battlegrounds-style keywords and the stand-in effects stay in the registry as vocabulary the tribe cards may use. Any still unused at the end of the track get removed.

## Taken from the first run and left behind

Taken from the tag `archive/branches/ideation/main`, rewritten to the prototype lessons' "What to carry into real development" list: the session/recruit/combat split and the round flow; `CoreUtil`; `BoardGeometry`'s relations and summon table (now built from instance data); `UnitPool`'s draw (now `CardPool`); round pairing with avoidance; the attack pointer, death passes and limits; the event log as the UI contract; the soak with fight counting and planted faults.

New against the lessons: stat layers, rule queries with a unit layer, combat queries in place of keyword names in `Combat`, status state on the unit, the selector library, combat sub-streams (`first`, `soc`, `target`, `effect`) over an owned hash and generator, geometry as instance data, typed mechanic parameters declared once.

Left behind: all tribe code (`pass3_*`, the per-tribe combat and bot files, tribe recruit helpers), all unit content and libraries, heroes and hero rules, slot effects, the effect-schema engine, scale overlays and field libraries.

## Checks

- `scripts/check.sh` runs the GUT tests (`tests/core/`, named by rule number) and a 10-game soak with the planted-fault proof (about 20 s).
- `scripts/soak.sh 300` is the long soak: 300 bot-only games, about 13,500 fights, about 4 minutes on one core. `scripts/soak_plant.sh` alone proves the planted faults.

## Rules this core settles

The rulebook leaves these open or silent; the core takes the simplest reading. None is decided.

- **2.1.4–2.1.5 async play:** a live 8-player lobby, as 2.1.1–2.1.3 are written.
- **5.1.4 pool or set chances:** the shared pool with HSBG copy counts.
- **6.1.7 tier weighting:** flat, by copies left (6.1.3). Shop odds stay flat for this build.
- **5.2.2, 5.2.5 tribes:** a lobby takes a list of tribes (empty = all); the test units have none.
- **6.1.6 shop slots as an upgrade, 5.2.8 traits, 8.3.2 minimum front row, 11.5.3 back-row access, 7.3.8 multiple-copy levels:** not added.
- **2.2.3 hero choices:** no heroes on this track.
- **A cast Tavern spell's pool copy** returns to the spell pool, reading 5.3.7 for spells.
- **Divine Shield against Venomous (11.2.5):** the shield takes the hit, so no damage is dealt and the Venomous stays unused.
- **A tripled golden placed on the board by 7.3.7** gains its Triple Reward at once; with the hand full it is lost (7.1.2).
- **Auras** in the test set give Attack only, so losing a Health aura never comes up yet.
- **A second Discover opened while one is shown** waits and is drawn when the first is picked (5.3.3 holds: only shown options are out of the pool).
- **Ending a turn with a Discover open or waiting** takes the first option of each, End of Turn ones included.

## Not done

- No UI and no tribe content.
- Slot effects (8.5); a unit that attacks immediately (9.4.12); "after this attacks" and player-level "after an attack" hooks (9.6.1 steps 4 and 6); conceding.
- Permanent changes from inside a fight (12.1.1).
- Gaining or losing a keyword (11.1.1) beyond `Unit.grant`.
- Activated abilities (3.3.1).
- Targeting overrides (9.5.7).
- Free and effect refreshes (4.4.5–4.4.6).
- Shop-wide buffs (12.1.3).
- Effect moves (9.4.9, 8.3.5).
- 9.7.2: "whenever a unit dies" triggers and returns; step 3 shares a hook with step 2.
- Deaths are checked after each attack or effect, not after each damage event (9.6.3).
- A golden placed on the board by 7.3.7 loses its Triple Reward when the hand is full.
