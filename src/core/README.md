# Rules core

A headless rules engine for the second ideation track, following [rulebook v0.8](../../docs/design/rulebook.md) with no heroes or hero powers. Every class is `RefCounted`; nothing here is a Node. Nothing in it is decided for the real game (`CLAUDE.md`, "Main and its archive").

## Layout

| Folder | What |
|---|---|
| `util/` | `CoreUtil` typed conversions; `Rng`, the core's own FNV-1a hash and xoshiro128** generator |
| `rules/` | `GameConfig` (every Appendix A number), `Rules` (named rule queries: base answer, then unit text, then caps) |
| `board/` | `BoardGeometry` (chapter 8 as instance data), `Selectors` (positional selectors, written once) |
| `units/` | `UnitDef` (card data), `UnitLibrary` (JSON loader and checker), `Unit` (a held card), `StatBlock` (stat layers), `CardPool` (the shared pool), `UnitText` (card text with golden numbers) |
| `state/` | Lasting and shared state: `CardHeap` (a named list of card entries), `SlotState` (8.5 slot effects), `AuraContext` (what an aura may read), `FightReport` (what after_fight learns) |
| `mechanics/` | `Mechanic` (the hook interface), `MechanicParams` (typed parameters), `MechanicRegistry`, and the built-in keywords and effects |
| `recruit/` | `PlayerState`, `Recruit` (the Recruit Phase and its actions), `RecruitContext` (what recruit hooks may do), `LegalActions` |
| `combat/` | `Combat` (one fight and its log), `CombatUnit`, `FightSide` (one side's bridge to its player) |
| `session/` | `GameSession` (the lobby and round flow), `Matchmaking` |
| `bots/` | `Bot`, `SimpleBot` (greedy), `RandomBot` (random legal play, for the soak) |

Content loads through `ContentSet` (`content/`) from folders: `src/content/<tribe>/` for the game, `tests/core/content/neutral/` (neutral test units) and `tests/core/content/test/` (the bridge test cards, one script per mechanic, ids prefixed `test_`). Test folders are not content. Adding a tribe: `docs/ideation-track-2/ADDING-A-TRIBE.md`.

## Phase order

A round, driven by a bot, a test or a UI:

1. `GameSession.start_round()`: round + 1; pairing (2.3: a seeded round-robin while all 8 live, then the least-repeating pairing over the last 3 rounds); the ghost for an odd player out (2.1.2); then each living player's start of turn (3.2.1): gold = carried + income, the upgrade discount from turn 2, the refresh count reset, the shop refilled (a frozen shop keeps its cards), gold earned in the last fight added, `Unit.turn_counters` cleared, start-of-turn triggers in reading order and then the player's standing mechanics.
2. `GameSession.act(player, action)` as often as the player likes (3.3). Actions are dictionaries: `buy`, `sell`, `play` (units and spells), `move`, `refresh`, `freeze`, `upgrade`, `pick` (a Discover choice, the only legal action while one is open), `ability` (a board unit's activated ability, 3.3.1), `end_turn`. `act` returns `""` or why the action is illegal, and an illegal action changes nothing. `GameSession.legal_actions(player)` lists every legal action. After each action, triples form (7.3.1, after all summons) and auras and slot effects are recomputed (12.2.1, 8.5). A unit entering the board (played, after its own `on_played`, or summoned) is heard by `on_board_enter`; any sale by `on_any_sold`.
3. `end_turn` (3.4.1): End of Turn triggers, "this turn" ends, an unfrozen shop goes back to the pool, gold is kept.
4. `GameSession.finish_round()`: ends any open turn; every pair fights (chapter 9), and right after each fight its live players' boards hear `after_fight` with a `FightReport`; the loser takes the round's small or big loss (10.1); eliminations after all fights, placed by health (10.2); cards of eliminated players go back to the pool (5.3.8); the game ends with one player left or at round 50 (2.1.3).

Inside a fight (`Combat.run`): copy boards, slot effects, and the players' counters and heaps (`FightSide`) → auras → `on_combat_begin` → `combat_start` → first attacker (9.2.1) → Start of Combat (9.3; deaths after each effect) → alternate attacks with the attack pointer (9.4.5). A unit whose turn comes may take it `instead_of_attack` (counted as an attack); otherwise each attack (9.6.1): step 1 `on_attacked` (an attacker it kills doesn't attack: no step 2, no exchange); step 2 `on_attack`, then `on_friendly_attack` for the attacker's friends (a `hit` here that kills the defender ends the attack); step 3 the exchange (cleave splash, `Q_STRIKES_FIRST`); step 4 `after_attack`, `after_friendly_attack` (even when a friend's hit killed the defender); step 5 death resolution (9.7): dying units leave → step 1 `on_kill`, `on_any_death` → step 2 own death effects (`Q_DEATH_EFFECT_TIMES` times) and `on_friendly_death` counters → step 3 `after_friendly_death` → step 4 returns (`Q_RETURN_HEALTH`, `return_health`, `on_returned`) → step 5 `after_friendly_return` → waiting summons land → new deaths repeat. Then end (9.9) or a limit (9.10, a tie). Every board change recalculates auras on both boards.

## Event schema

Every event is a JSON-shaped Dictionary with a `type`. Slots are 0–6 in reading order (`F1`–`F4` are 0–3, `B1`–`B3` are 4–6); `side` is 0 or 1; `uid` names one unit for the whole fight. Fights record `GameSession.fights[i].events`; everything else goes to `GameSession.events`, each event with `round` and, for player events, `player`.

**Fight log** (`Combat.events`):

| type | fields |
|---|---|
| `combat_start` | `players` [a, b], `first` side, `boards` [[unit view], [unit view]], `slots` [[slot view] × 7, ...], `counters` [{key: n}, {key: n}] and `heaps` [{name: size}, {name: size}] (each side's player numbers), `reserve` [[unit view], [unit view]], `outnumbered_by` [n, n]; unit view = `uid, recruit_uid` (the recruit card it copies; -1 for one made in the fight)`, id, side, slot, label, attack, health, golden, bought, keywords, grants` (mechanics with numbers an aura gave, `{"mechanic", <param>}`)`, counters, text`; slot view = `attack, health, keywords` |
| `trigger` | `side, slot, uid, mechanic` (a hook acted; `return` for a unit coming back) |
| `attack` | `side, slot, uid, target_side, target_slot, target_uid` |
| `instead_of_attack` | `side, slot, uid, mechanic` (the unit took its turn another way; counts toward the attack limit, 9.10.1) |
| `damage` | `side, slot, uid, amount` (> 0), `health` after, `source_uid` (-1 for none) |
| `destroy` | `side, slot, uid, source_uid` (the unit whose effect destroyed it) |
| `buff` | `side, slot, uid, attack, health` (new values), `source_uid`, `permanent` (also written to the recruit unit) |
| `stats` | a unit view: its Attack, Health or keywords changed through an aura or slot effect. One follows every aura or slot change that changes what a unit shows (auras are recalculated after every board, buff, counter, heap or slot change) |
| `hit` | `side, slot, uid, target_side, target_slot, target_uid` (followed by its `damage`; not attack damage) |
| `move` | `side, uid, from, to` (an effect moved it, 8.3.5) |
| `keyword` | `side, slot, uid, keyword, on`, `source_uid` |
| `counter` | `side, slot, uid, key, value, permanent, source_uid` (a unit's lasting number) |
| `player_counter` | `side, key, value, source_uid` |
| `heap_add` / `heap_remove` | `side, heap, id` / `ids`, `size` after, `source_uid` |
| `slot` | `side, slot, attack, health` (the change), `total` (slot view), `permanent`, `source_uid` |
| `gold` | `side, amount, next_turn` (gold earned in the fight) |
| `summon_waiting` | `side, id, source_uid` (no room yet; it lands after a death resolution, as a `summon` with `waited` true and its `payload`) |
| `reserve` | a unit view plus `source_uid` -1: a hand unit stepping into a slot a friend died in (`combat_start` lists each side's waiting `reserve`) |
| `heap_use` | `side, heap, count, unused, source_uid` (entries used for this fight; the heap doesn't change) |
| `status` | `side, slot, uid, status, on, source_uid`. `on` false: a one-use keyword is used up, so the screen drops its pill (Divine Shield after its block, Venomous after its kill, Stealth ending, Reborn on the returned copy, a tribe's spent charge). The source is the unit whose damage it stopped, or that used it |
| `death` | `side, slot, uid` (the slot it left), `killer_uid` (whose damage or destroy effect last hit it; -1 for none) |
| `summon` | a unit view (with `keywords`) plus `source_uid`, so a screen can draw it |
| `summon_failed` | `side, id` |
| `return` | a unit view of the new unit (its real Attack, Health and keywords, after `on_returned`), `from_uid` |
| `pass` | `side` |
| `combat_end` | `winner` (side, or -1 for a tie), `reason` (`board_empty`, `no_attacks`, `attack_limit`, `trigger_limit`), `starting` [n, n], `killed` [n, n] (starting units killed, 10.1.2), `attacks`, `triggers`, `survivors` [[uid], [uid]] |

**Game log** (`GameSession.events`): `round_start` (`pairs`), `turn_start` (`gold`, `shop`), `buy`, `sell`, `play`, `cast`, `move`, `refresh`, `freeze`, `upgrade`, `discover` (`options`), `discover_queued` (`waiting`), `pick`, `gain`, `card_lost`, `summon`, `summon_failed`, `triple`, `trigger`, `buff`, `gold`, `ability`, `shop_take`, `counter`, `player_counter`, `heap_add`, `heap_remove`, `slot`, `keyword`, `turn_end`, `fight` (`players`, `winner`, `loser`, `damage`, `reason`), `eliminated` (`placement`, `health`), `game_end` (`placements`). `PlayerState.view()` and `Unit.view()` give the state a UI shows; `GameSession.view_for(player)` adds prices (refresh, upgrade, each shop card, each sell), the round, the current opponent and the legal actions in one call. Views include unit `counters`, `effects` and `text`, and the player's `counters`, `heaps`, `slots` and `standing`, under the names the mechanics chose, so a screen can show medals, a heap or slot buffs without knowing any tribe. The screens read these and the fight log, not the game log, which stays small. What `after_fight` changes on the real boards is in each fight's `after` list (`GameSession.fights`), so the screen after a fight can show it.

**Golden text (7.3.5).** Card data writes numbers as `{param}` placeholders ("+{amount}/+{amount}"). `Unit.view()["text"]` fills them from the bound parameters, already doubled on a golden for `NUMBER` and kept for `THRESHOLD`, so one text serves both.

## How a mechanic plugs in

1. Write a script that `extends Mechanic` and overrides only the hooks it needs; `mechanic.gd` lists every hook with its rule step. Self hooks run for the unit's own text. Listener hooks ("a friendly unit …", "any …") run for every unit on that board in reading order and then for the player's standing mechanics with `unit = null`.
2. Declare its parameters once in `param_kinds()`: `NUMBER` (doubled on a golden, 7.3.5), `THRESHOLD` (never doubled) or `TEXT`. The library rejects card data with an unknown, missing or wrongly typed parameter.
3. Act only through the context. Recruit hooks get a `RecruitContext`: `trigger`, `buff` (this turn or permanent), `summon`, `gain_gold`, `discover`, `select`, `random_of`, `add_counter` / `add_unit_counter`, `heap_add` / `heap_spend` / `heap_take`, `slot_buff` (with an optional keyword), `give_keyword` / `remove_keyword`, `take_from_shop`, `run_death_effects`, `add_standing`, and `target_index` for a slot or shop target. Combat hooks get `Combat`: `trigger`, `buff` (`permanent` writes back), `deal_damage`, `destroy`, `hit`, `attack_now`, `move_unit`, `summon` (`wait` for no room), `run_death_effects`, `side_query`, `select`, `random_enemy`, `units`, `unit_at`, `show_status`, `effect_rng`, and `bridge(side)` (a `FightSide`: `counter` / `add_counter`, `add_unit_counter`, `heap` / `heap_add` / `heap_spend` / `heap_take`, `slot` / `slot_buff`, `give_keyword` / `remove_keyword`, `add_gold`, `deaths`, `state`, `real_unit`, `player`, `writes_back`). Call `trigger(unit, id)` first: it logs the trigger and counts it against the limits (9.10.2). Keep no state on the script, since one instance serves every unit: a fight's state goes in `CombatUnit.state` or `FightSide.state`, a game's in `Unit.counters`, `Unit.turn_counters` or `PlayerState.counters`.
4. Register it: add it to `MechanicRegistry.BUILT_IN`, or call `registry.register(&"id", MyMechanic.new())` from the game's set-up. Card data then names it: `"effects": [{"mechanic": "id", ...params}]`, or `"keywords": ["id"]` for one without parameters. `"combines": false` keeps a card out of triples. A rule every player has (a heap that every sale feeds) is a standing mechanic: `GameSession.give_standing(&"id")` after `create`.

**The bridge (12.1.1, 9.1.1).** A fight's side writes back when it is a live player; the ghost and bare test fights work on copies. `Combat.buff(..., permanent = true)`, `FightSide.add_unit_counter(..., permanent = true)`, `slot_buff(..., permanent = true)` and `give_keyword(..., permanent = true)` reach the recruit unit, slot or player. Player counters and heaps are the real ones in a live fight ("fights use the real heap"). After the fight, `after_fight(ctx, unit, report, params)` runs on the real board with a `FightReport` (`outcome`, `survived(unit)`, `deaths`, `opponent`).

Rule queries have one layer for now, unit text; game- and player-level layers (an anomaly, a quest) come back when something needs them. `Rules.SLOT_BUFF_PERCENT` ("buffs you give to slots are doubled") is asked of the recruit board, in fights too.

The Battlegrounds-style keywords and the stand-in effects stay in the registry as vocabulary the tribe cards may use. Any still unused at the end of the track get removed.

### How to add a tribe card: one worked example per capability

Each line is a real test card in `tests/core/content/test/units.json`, with its script in `tests/core/content/test/mechanics/` (ids `test_` + file name) and a test in `tests/core/test_bridge.gd`.

| Capability | Example card | How |
|---|---|---|
| After the fight, lasting unit numbers | Veteran (`medal_after_fight`) | `after_fight`: `ctx.add_unit_counter(unit, &"medal", n, unit)` and a permanent `ctx.buff` |
| Permanent change from a fight | Berserk (`fury_gain`) | `on_attack`: `combat.buff(unit, 1, 1, unit, true)` |
| An aura that sees the fight | Berserk (`outnumbered_aura`) | `aura(view, ...)`: `view.outnumbered()`; also `view.counter`, `view.heap_size`, `view.count_tribe` |
| A friend's attack | Piler (`pile_on`) | `on_friendly_attack`: `combat.hit(unit, defender)` |
| Slot buffs | Driller (`drill_slot`), Slot Gift (`slot_gift`) | `ctx.slot_buff(slot, a, h, unit)`; a play or ability with `Target.SLOT` reads `ctx.target_index` |
| An ability with a cost and a target | Officer (`order_slot`) | `has_ability`, `ability_cost`, `ability_target`, `on_ability`; the slot gives Taunt through `slot_buff(..., &"taunt")` |
| An ability on a shop card | Burier (`bury`) | `Target.SHOP_UNIT`; `ctx.take_from_shop(i, unit)` then `ctx.heap_add` |
| A heap every sale feeds | `heap_on_sale` (standing) | `on_any_sold` with `unit = null`; given by `GameSession.give_standing` |
| Reading and spending the real heap in a fight | Grower (`grow`), Seeder (`seed_heap`), Rooter (`root`) | `combat.bridge(side).heap(...)`, `heap_add`, `heap_spend`; a paid return through `return_health` and `on_returned` |
| A player number that lasts the game | Tider (`tide_on_death`, `tide_rider`) | `bridge(side).add_counter(&"tide", 1, unit)`; the aura reads `view.counter(&"tide")` |
| Side rules | Dirge (`death_twice`) | `side_query` answers `Q_DEATH_EFFECT_TIMES` |
| Attacks immediately (9.4.12) | Charger (`charge`) | `combat.attack_now(unit)` |
| Targeting override (9.5.7) | Raider (`back_row_raider`) | `combat_query` answers `Q_TARGET_ROW` with `ROW_BACK` |
| Waiting summons | Swarm Mother (`swarm_spawn`) | `combat.summon(..., wait = true)` |
| Effect moves (9.4.9) | Stepper (`step_up`) | `after_friendly_death`: `combat.move_unit(unit, dead.slot)` |
| An aura that gives a keyword | Lender (`lend_keyword`) | `aura_keywords` |
| Any sale; death effects in the Recruit Phase | Eater (`eat`) | `on_any_sold`: permanent `ctx.buff`, `ctx.run_death_effects(sold)` (`on_recruit_death`) |
| Entering a board, both phases | Greeter (`greet`) | `on_board_enter`, `on_fight_enter` |
| Damage from attacks only; first strike | Plated (`plate`), Lancer (`first_strike`) | `absorb_damage(..., from_attack, ...)`; `Q_STRIKES_FIRST` |
| Thorns, "whenever this attacks", "after this attacks" | Thorny (`thorns`), Crier (`war_cry`, `after_strike`) | `on_attacked`: `combat.deal_damage(unit, attacker, n)`; `on_attack`; `after_attack` |
| Instead of attacking | Slinger (`sling`) | `instead_of_attack` returns true |
| Reserve, a fill-first slot, after a round of deaths | Reservist (`reserve`), Post (`fill_first`), Sergeant (`sergeant`) | `combat_query` `Q_RESERVE`; `side_query` `Q_FILL_FIRST`; `after_death_round` |
| Start of Combat set-up pass | Setup (`setup_summoner`) | `start_of_combat_priority` returns `SOC_SETUP` |
| An aura giving a mechanic with a number | Thornlender (`thorn_grant`) | `aura_grants` returns `[{"mechanic": "test_thorns", "amount": 1}]` |
| Slot multipliers | Drillmaster (`slot_doubler`), Edge (`edge`) | `modify_int` `Rules.SLOT_BUFF_PERCENT` (give time); `side_query` `Q_SLOT_ATTACK_PERCENT` (fight time) |
| Summoning during an attack | Captain (`captain`) | `on_friendly_attack`: `combat.summon`; the new unit hears the same attack |
| A permanent gain while dying | Ace (`ace`) | `on_kill`: `combat.buff(unit, 1, 1, unit, true)` |
| Not counted for Outnumbered | Squire (`squire`) | `combat_query` `Q_UNCOUNTED`; read `combat.outnumbered_by(side)`, `view.outnumbered_by`, `report.outnumbered_by` |
| An attack that takes no damage | Tilter (`tilter`) | `combat.attack_now(unit, null, true)` |
| Returning as it stands (Root) | Oak (`root_full`) | `combat_query` `Q_RETURN_AS_RECRUIT` and `Q_RETURN_HEALTH` |

Context methods shown in `tests/core/test_arrivals_and_slots.gd` without a card of their own: `ctx.give_card` (a Created card to hand), `ctx.slot_clear_keyword` / `FightSide.slot_clear_keyword` (moving a Guard post), `FightSide.slot_set` (a copy, not a buff given), `FightSide.heap_use` / `heap_unused` (entries used for this fight), `combat.hit(unit, target, percent)`, `combat.choose_target`, `Unit.has_death_effect` / `CombatUnit.has_death_effect`, `StatBlock.own_attack` / `own_health` (own stats, SHARED-RULES 43), `CombatUnit.bought`, `AuraContext.unit_counter`, and the sell event's `slot` (the sold unit keeps the slot it was sold from in `on_any_sold`).

Not shown by a test card but there: `Q_CANT_ATTACK`, `Q_HAND_RESERVE`, `FightSide.add_gold` (paid next turn), `Unit.grant_effect` (give a unit a mechanic with parameters, 'Give a unit "Fury: +3/+3"'), `on_heap_added` / `on_heap_added_in_fight`, `after_friendly_return`, `on_any_death`, and a golden from a triple adding up its copies' counters.

**Kept until the end of track 2, removed then if unused** (no tribe design asked for them yet): `Q_STRIKES_FIRST`, `move_unit`, `on_board_enter` in the Recruit Phase, `after_friendly_attack`, `Unit.grant_effect`, `remove_keyword`, `AuraContext.outnumbered()` (the live count; the rule is `outnumbered_by`, fixed at fight start), `ROW_ANY`.

## Taken from the first run and left behind

Taken from the tag `archive/branches/ideation/main`, rewritten to the prototype lessons' "What to carry into real development" list: the session/recruit/combat split and the round flow; `CoreUtil`; `BoardGeometry`'s relations and summon table (now built from instance data); `UnitPool`'s draw (now `CardPool`); round pairing with avoidance; the attack pointer, death passes and limits; the event log as the UI contract; the soak with fight counting and planted faults.

New against the lessons: stat layers, rule queries with a unit layer, combat queries in place of keyword names in `Combat`, status state on the unit, the selector library, combat sub-streams (`first`, `soc`, `target`, `effect`) over an owned hash and generator, geometry as instance data, typed mechanic parameters declared once.

Left behind: all tribe code (`pass3_*`, the per-tribe combat and bot files, tribe recruit helpers), all unit content and libraries, heroes and hero rules, slot effects, the effect-schema engine, scale overlays and field libraries.

## Checks

- `scripts/check.sh` runs the GUT tests (`tests/core/`, named by rule number) and a 10-game soak with the planted-fault proof (about 20 s). The soak plays the neutral and bridge test cards, with every player's sales feeding a heap.
- The soak's invariants also cover the new state: every heap entry is a unit card; each player's heap size and slot-buff total equal what their logged events add up to (game log plus the live side of each fight), so a leak or a duplicate shows; and every unit that dies in a fight log was last shown at 0 Health or destroyed, so a replay never shows stale numbers. Planted faults: `pool_leak`, `empty_library`, `heap_dup`.
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
- **`SLOT_BUFF_PERCENT` reads the recruit board,** so in a fight a slot doubler that died still doubles (SHARED-RULES 14).
- **Losing aura or slot Health** (a lender dies, a slot buff is set lower) never takes a unit below 1 Health.
- **Who fills an emptied slot** (SHARED-RULES 6): own death-effect summons and returns, then Reserve (fill-first slot, then reading order, hand order), then waiting summons in one line, then `after_death_round`, then the end check. Units in hand never count for Outnumbered.
- **A second Discover opened while one is shown** waits and is drawn when the first is picked (5.3.3 holds: only shown options are out of the pool).
- **Ending a turn with a Discover open or waiting** takes the first option of each, End of Turn ones included.

## Not done

- No UI and no tribe content.
- Conceding; player-level "after an attack" effects (9.6.1 step 6; no heroes or player modifiers).
- Free and effect refreshes (4.4.5–4.4.6); shop-wide buffs (12.1.3).
- Deaths are checked after each attack or effect, not after each damage event (9.6.3).
- A golden placed on the board by 7.3.7 loses its Triple Reward when the hand is full.
- A keyword an aura or slot gives mid-fight doesn't run its `on_combat_begin` (a Divine Shield given that way starts down); at the start of the fight it does.
- `Q_HAND_RESERVE`, `grant_effect` and `on_heap_added_in_fight` have no test yet.
