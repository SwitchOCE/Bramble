# Adding a tribe to the rules core

Ideation track 2. Nothing here is decided for the real game. The core is `src/core/` (its README has the phase order, the event schema and every hook). A tribe is files only: you never edit `src/core/`, `tools/checks/soak.gd` or another tribe's folder. If your design needs something the core lacks, ask the orchestrator; don't reach past a context into the core's state.

## 1. The folder

```
src/content/<tribe>/
  tribe.json      {"prefix": "<tribe>_", "standing": ["<tribe>_..."]}
  units.json      {"cards": [...]}
  display.json    {"<id>": {"name": ..., "reminder": ..., "icon": ..., "hidden": false}}
  mechanics/      one script per mechanic, `extends Mechanic`
tests/content/<tribe>/test_<tribe>_*.gd   (GUT tests for the tribe; see 5)
```

`ContentSet` (`src/core/content/content_set.gd`) finds every folder under `src/content/` with a `tribe.json`. It registers each `mechanics/<name>.gd` as the id `<prefix><name>` (`mechanics/fury.gd` in the badger folder becomes `badger_fury`), loads the cards, merges the display tables and gives every player the `standing` mechanics. Tests, the soak and the game all build through it. Any problem — a duplicate id, a card naming an unknown mechanic or a bad parameter, a display id used twice, a standing id that doesn't exist — lands in `ContentSet.errors`; the content test and the soak fail on it.

## 2. Naming rules

- **Mechanic ids** come from file names and always carry your prefix. A name clash between two tribes is impossible; a clash with the core's built-ins is refused.
- **Counters, heaps, state keys, custom query names and `side_query` names** you choose must also start with your prefix: `&"pigeon_medal"`, `&"thorn_compost"`, `&"badger_fury_times"`.
- **Shared keywords** (the ones SHARED-RULES names, used by more than one tribe) live in `src/content/shared/` with no prefix. Don't copy one into your folder; if a shared keyword is missing, ask.
- **Card ids** are unique across the game; use your tribe's ids from your design (`sett-shield-bearer`).
- **Display ids**: every mechanic in your folder needs an entry in your `display.json` (the loader reports a missing one), and so does every counter or heap a screen may show; every id there carries your prefix. Helper mechanics that are not keywords get `"hidden": true`.

## 3. A card

```json
{"id": "brock-cub", "name": "Brock Cub", "tier": 1, "attack": 2, "health": 3,
 "tribes": ["Badger"], "keywords": ["badger_fury_gain"],
 "text": "Fury: gain +{attack}/+{health} permanently.",
 "effects": [{"mechanic": "badger_fury_gain", "attack": 1, "health": 1}]}
```

- Numbers go in `effects` parameters and in the text as `{param}` placeholders. Declare each parameter in `param_kinds()`: `NUMBER` doubles on a golden (7.3.5), `THRESHOLD` doesn't, `TEXT` is a string. The screen shows `Unit.view()["text"]`, already filled.
- `"keywords"` lists mechanics with no parameters. `"combines": false` keeps a card out of triples. `"token": true` keeps it out of the pool.

## 4. A mechanic, one worked example per capability

Every row is a real test card in `tests/core/content/test/` (ids `test_` + file name) with a test in `tests/core/test_bridge.gd`. Copy the pattern, not the card.

| You need | Look at | The pattern |
|---|---|---|
| Something after the fight on the real board | `medal_after_fight.gd` | `after_fight(ctx, unit, report, params)`; `report.survived(unit)`, `report.won()` |
| A number on a unit for the game | `medal_after_fight.gd` | `ctx.add_unit_counter(unit, &"<prefix>medal", n, unit)` |
| A permanent buff from inside a fight | `fury_gain.gd` | `combat.buff(unit, a, h, unit, true)` |
| An aura that reads the fight, a counter or a heap | `outnumbered_aura.gd`, `tide_rider.gd` | `has_aura()` true; `aura(view, ...)` reads `view.outnumbered()`, `view.counter()`, `view.heap_size()`, `view.count_tribe()` |
| An aura that gives a keyword | `lend_keyword.gd` | `aura_keywords(...)` |
| Joining a friend's attack | `pile_on.gd` | `on_friendly_attack(...)`: `combat.hit(unit, defender)` |
| Slot buffs | `drill_slot.gd`, `slot_gift.gd` | `ctx.slot_buff(slot, a, h, unit)`; in a fight `combat.bridge(side).slot_buff(...)` |
| An ability the player uses (Order, Bury) | `order_slot.gd`, `bury.gd` | `has_ability`, `ability_cost`, `ability_target` (`SLOT`, `SHOP_UNIT`, `FRIENDLY_UNIT`), `on_ability`; the target is `ctx.target_index` |
| A heap all players fill | `heap_on_sale.gd` | a standing mechanic (`tribe.json` `"standing"`), `on_any_sold` with `unit == null`, `ctx.heap_add` |
| Reading or spending the real heap in a fight | `grow.gd`, `seed_heap.gd`, `root.gd` | `combat.bridge(side).heap(...)`, `heap_add`, `heap_spend`; a paid return through `return_health` + `on_returned` |
| A player number for the game | `tide_on_death.gd` | `combat.bridge(side).add_counter(&"<prefix>tide", 1, unit)` |
| "Your X trigger twice" | `death_twice.gd` | `side_query` answering a query name |
| Attacks immediately | `charge.gd` | `combat.attack_now(unit)` |
| A targeting rule | `back_row_raider.gd` | `combat_query` answering `Q_TARGET_ROW` |
| Summons that wait for room | `swarm_spawn.gd` | `combat.summon(..., wait = true)` |
| Moving in a fight | `step_up.gd` | `combat.move_unit(unit, slot)` |
| Any sale; death effects in the Recruit Phase | `eat.gd` | `on_any_sold`; `ctx.run_death_effects(sold)` runs `on_recruit_death` |
| A unit entering a board | `greet.gd` | `on_board_enter` (recruit), `on_fight_enter` (fight) |
| Less damage from attacks | `plate.gd` | `absorb_damage(..., from_attack, ...)` |
| Thorns; "whenever this attacks"; "after this attacks" | `thorns.gd`, `war_cry.gd`, `after_strike.gd` | `on_attacked`, `on_attack`, `after_attack` |
| Instead of attacking | `sling.gd` | `instead_of_attack` returns true (counts as an attack) |
| Reserve; a Guard post filled first; after a round of deaths | `reserve.gd`, `fill_first.gd`, `sergeant.gd` | `Q_RESERVE`; `side_query` `Q_FILL_FIRST`; `after_death_round` |
| Start of Combat set-up pass | `setup_summoner.gd` | `start_of_combat_priority` returns `SOC_SETUP` |
| An aura giving "Thorns 1", "Grow 1" | `thorn_grant.gd` | `aura_grants`: `[{"mechanic": id, "amount": n}]`; grants of one id add up |
| Slot multipliers | `slot_doubler.gd`, `edge.gd` | give time `Rules.SLOT_BUFF_PERCENT`, fight time `Q_SLOT_ATTACK_PERCENT`; one of each stacks, the bigger of a kind applies |
| A summon that joins the same attack | `captain.gd` | summon in `on_friendly_attack` or `on_attack`; it hears that attack |
| A permanent gain while dying (Flying Ace) | `ace.gd` | `combat.buff(..., true)` in `on_kill` |
| Outnumbered | `squire.gd`, `outnumbered_aura.gd` | `Q_UNCOUNTED`; `combat.outnumbered_by(side)`, `view.outnumbered_by`, `report.outnumbered_by` (fixed at fight start) |
| An attack that takes no damage | `tilter.gd` | `combat.attack_now(unit, null, true)` |
| Root (back as it stands) | `root_full.gd` | `Q_RETURN_AS_RECRUIT` + `Q_RETURN_HEALTH`; Molt is the plain return |

Context methods without a card (see `tests/core/test_arrivals_and_slots.gd`): `ctx.give_card`, `ctx.slot_clear_keyword`, `FightSide.slot_set` / `slot_clear_keyword` / `heap_use`, `combat.hit(unit, target, percent)`, `combat.choose_target` (Overrun's next target), `has_death_effect()` (return true from your death-effect mechanic), `StatBlock.own_attack()` / `own_health()` for anything that copies, keeps or takes stats (SHARED-RULES 43), `CombatUnit.bought`, `AuraContext.unit_counter(slot, key)`.

Card data: the design folders' `units.json` (SHARED-RULES section 6) map onto the engine's cards as `tribe` -> `tribes`, the words of `type` -> `types`; `implementer` says how each unit works.

Rules for every hook:
- Call `ctx.trigger(unit, id)` / `combat.trigger(unit, id)` before acting, and do nothing if it returns false.
- Listener hooks run for standing mechanics with `unit == null`: check it. In a fight, `combat.listening_side` says whose standing mechanic is running (use it with `combat.trigger_side`).
- Keep no state on the script (one instance serves every unit). Per-fight state: `CombatUnit.state` or `combat.bridge(side).state`. Per-game: `Unit.counters`, `PlayerState.counters`, heaps. Per-turn: `Unit.turn_counters`.
- Change state only through `RecruitContext`, `Combat` and `FightSide` methods, so every change has an event (the soak checks heaps and slots against their events).
- When a one-use keyword or charge is used up (a Molt or Root charge spent, Stiff Upper Lip saving a unit), call `combat.show_status(unit, &"<prefix>keyword", false, source)` so the screen drops its pill.

## 5. Running only your tribe

- Tests: put GUT tests in `tests/content/<tribe>/` and build sessions with `CoreKit.content(["<tribe>"]).session(seed)` (`tests/core/core_kit.gd`). Run one folder: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/content/<tribe> -gexit`.
- Soak: `scripts/soak.sh 20 tribes=<tribe>` (add `test_cards=0` to leave out the bridge test cards, `neutral=0` to leave out the neutral units). With no `tribes=` it loads every tribe.
- The gate: `scripts/check.sh` runs every test folder and a short soak of everything; it must pass before you push.
