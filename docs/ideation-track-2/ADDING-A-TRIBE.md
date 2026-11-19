# Adding a tribe to the rules core

Ideation track 2. Nothing here is decided for the real game. The core is `src/core/` (its README has the phase order, the event schema and every hook). A tribe is files only: you never edit `src/core/`, `tools/checks/soak.gd` or another tribe's folder. If your design needs something the core lacks, ask the orchestrator; don't reach past a context into the core's state.

## 1. The folder

```
src/content/<tribe>/
  tribe.json      {"prefix": "<tribe>_", "standing": ["<tribe>_..."]}
  units.json      {"cards": [...]}
  display.json    {"<id>": {"name": ..., "reminder": ..., "icon": ..., "hidden": false}}
  mechanics/      one script per mechanic, `extends Mechanic`
  lib/            helper scripts that are not mechanics (optional)
tests/content/<tribe>/test_<tribe>_*.gd   (GUT tests for the tribe; see 5)
```

`ContentSet` (`src/core/content/content_set.gd`) finds every folder under `src/content/` with a `tribe.json`. It registers each `mechanics/<name>.gd` as the id `<prefix><name>` (`mechanics/fury.gd` in the badger folder becomes `badger_fury`), loads the cards, merges the display tables and gives every player the `standing` mechanics. Tests, the soak and the game all build through it. Any problem — a duplicate id, a card naming an unknown mechanic or a bad parameter, a display id used twice, a standing id that doesn't exist — lands in `ContentSet.errors`; the content test and the soak fail on it.

The loader also refuses: a `tribe.json` with no `prefix` (only `shared/` has none), a prefix another folder already uses, and a script in `mechanics/` that does not extend `Mechanic` ("put helper code in lib/"). Helpers go in `lib/`; preload them by path.

## 2. Naming rules

- **Mechanic ids** come from file names and always carry your prefix. A name clash between two tribes is impossible; a clash with the core's built-ins is refused.
- **Counters, heaps, state keys, custom query names and `side_query` names** you choose must also start with your prefix: `&"locust_tide"`, `&"thorn_compost"`, `&"badger_fury_times"`. The core checks the names it is handed (`add_counter`, `add_unit_counter`, `add_turn_counter`, `heap`, `set_state`, a non-core `side_query`): a name with no loaded prefix (and not `core_`) lands in `registry.errors`, once per name, and fails the soak.
- **`class_name` is global** across all tribes: don't declare one in a tribe script. Preload helpers by path (`const BadgerRules := preload(...)`); two scripts declaring one `class_name` fail when both load.
- **Shared keywords** (the ones SHARED-RULES names, used by more than one tribe) live in `src/content/shared/` with no prefix. Don't copy one into your folder; if a shared keyword is missing, ask.
- **Card ids** are unique across the game; use your tribe's ids from your design (`sett-shield-bearer`).
- **Display ids**: every mechanic in your folder needs an entry in your `display.json` (the loader reports a missing one), and so does every counter or heap a screen may show; every id there carries your prefix. Helper mechanics that are not keywords get `"hidden": true`. A slot's Attack and Health buff shows under the shared id `slot_buff`; use it, not your own.

## 3. A card

```json
{"id": "brock-cub", "name": "Brock Cub", "tier": 1, "attack": 2, "health": 3,
 "tribes": ["Badger"], "keywords": ["badger_fury_gain"],
 "text": "Fury: gain +{attack}/+{health} permanently.",
 "effects": [{"mechanic": "badger_fury_gain", "attack": 1, "health": 1}]}
```

- Numbers go in `effects` parameters and in the text as `{param}` placeholders. Declare each parameter in `param_kinds()`: `NUMBER` doubles on a golden (7.3.5), `THRESHOLD` doesn't, `TEXT` is a string. The screen shows `Unit.view()["text"]`, already filled; it is the printed text, so a number given or granted later (+1 Fury from the Master-at-Arms) shows in `Unit.view()["totals"]` instead: one number per parameter for each mechanic, printed, given and granted together.
- `"keywords"` lists mechanics with no parameters. `"combines": false` keeps a card out of triples. `"token": true` keeps it out of shops and Discover.
- **When golden is not a plain doubling**, give a parameter its own golden value and the card a golden text:

```json
{"id": "b2_herald", "text": "Thorns {amount}.", "golden_text": "Thorns {amount}, golden.",
 "reminders": ["Only one pays each fight."],
 "effects": [{"mechanic": "test_thorns", "amount": 2, "golden": {"amount": 3}}]}
```

  A golden copy shows `golden_text` (filled the same way) and binds `amount` to 3, not 4. `"reminders"` adds card-specific reminder lines to `Unit.view()["reminders"]` (for a term no keyword's display entry explains, such as the Relic Seeker's).

## 4. A mechanic, one worked example per capability

Every row is a real test card in `tests/core/content/test/` (ids `test_` + file name) with a test in `tests/core/test_bridge.gd` or `tests/core/test_core_pass4.gd` (named by rule). Copy the pattern, not the card.

| You need | Look at | The pattern |
|---|---|---|
| Something after the fight on the real board | `mark_after_fight.gd` | `after_fight(ctx, unit, report, params)`; `report.survived(unit)`, `report.won()` |
| A number on a unit for the game | `mark_after_fight.gd` | `ctx.add_unit_counter(unit, &"<prefix>mark", n, unit)` |
| A permanent buff from inside a fight | `fury_gain.gd` | `combat.buff(unit, a, h, unit, true)` |
| An aura that reads the fight, a counter or a heap | `outnumbered_aura.gd`, `tide_rider.gd` | `has_aura()` true; `aura(view, ...)` reads `view.outnumbered_by` (fixed at fight start), `view.counter()`, `view.heap_size()`, `view.count_tribe()` |
| Lends: an aura from the source's own Attack or Health | `lend.gd` | `view.attack_at(source_slot)`, `view.max_health_at(source_slot)`: what the unit shows, permanent buffs and Renown included (an Armsbearer with +5 lends 8). Read these, never `view.units[i].stats` |
| An aura that gives a keyword | `lend_keyword.gd` | `aura_keywords(...)` |
| Joining a friend's attack | `pile_on.gd` | `on_friendly_attack(...)`: `combat.geometry.neighbours(unit.slot)` (up to four slots), `combat.hit(unit, defender)`. Every friend hears the attack first, then all the hits land together, so a second hit still lands on a target the first one killed |
| A slot keyword (the Guard post) | `src/content/pigeon/mechanics/grenadier.gd` | `ctx.slot_keyword(slot, keyword, unit)`. Slots hold keywords and Renown only; stat slot buffs were retired on 19 Nov 2026 |
| An ability the player uses (an Active, Bury) | `order_slot.gd`, `bury.gd` | `has_ability`, `ability_cost`, `ability_target` (`SLOT`, `SHOP_UNIT`, `FRIENDLY_UNIT`), `on_ability`; the target is `ctx.target_index` |
| A heap all players fill | `heap_on_sale.gd` | a standing mechanic (`tribe.json` `"standing"`), `on_any_sold` with `unit == null`, `ctx.heap_add` |
| Reading or spending the real heap in a fight | `grow.gd`, `seed_heap.gd`, `root.gd` | `combat.bridge(side).heap(...)`, `heap_add`, `heap_spend` |
| Copying a heap entry for this fight only (Old Stump) | `test_a9_heap_marks_name_entries_...` | `combat.bridge(side).heap_use_highest(&"<prefix>heap", unit)` returns the entry it marked (`{"id", "n"}`) or `{}`; the next call skips it. `heap_use(heap, count)` marks the highest `count` |
| An entry added in a fight | `fight_heap_watch.gd` | `on_heap_added_in_fight` |
| A player number for the game | `tide_on_death.gd` | `combat.bridge(side).add_counter(&"<prefix>tide", 1, unit)` |
| "Your X trigger twice" | `death_twice.gd` | `side_query` answering a query name |
| Attacks immediately | `charge.gd` | `combat.attack_now(unit)` |
| A targeting rule | `back_row_raider.gd` | `combat_query` answering `Q_TARGET_ROW` |
| Summons that wait for room | `swarm_spawn.gd` | `combat.summon(..., wait = true)` |
| Any sale; death effects in the Recruit Phase | `eat.gd` | `on_any_sold`; `ctx.run_death_effects(sold)` runs `on_recruit_death` |
| Joining the fight (summoned, or stepping in from Reserve) | `greet.gd` | `on_fight_enter` |
| Less damage from attacks | `plate.gd` | `absorb_damage(..., from_attack, ...)` |
| Thorns; "whenever this attacks"; "after this attacks" | `thorns.gd`, `war_cry.gd`, `after_strike.gd` | `on_attacked`, `on_attack`, `after_attack` |
| Instead of attacking | `sling.gd` | `instead_of_attack` returns true (counts as an attack) |
| Reserve; a Guard post filled first; after a round of deaths | `reserve.gd`, `fill_first.gd`, `sergeant.gd` | `Q_RESERVE`; `side_query` `Q_FILL_FIRST`; `after_death_round` |
| Start of Combat set-up pass | `setup_summoner.gd` | `start_of_combat_priority` returns `SOC_SETUP` |
| An aura giving "Thorns 1", "Grow 1" | `thorn_grant.gd` | `aura_grants`: `[{"mechanic": id, "amount": n}]`; grants of one id add up by default |
| Grants that take the lowest (a cost) | `low_cost.gd` | `grant_combine(param)` returns `Combine.MIN`; the default `SUM` is what Fury needs. A unit view's `totals` combines the same way |
| Giving a mechanic with a number (Fury onto a unit with none) | `arms.gd`, `fury.gd` | Recruit: `ctx.give_effect(target, &"<prefix>fury", {"amount": n}, unit)`. Fight: `combat.bridge(side).give_effect(target, id, raw, permanent, unit)`. Not doubled on a golden target (the giver's number is already golden) |
| A summon that joins the same attack | `captain.gd` | summon in `on_friendly_attack` or `on_attack`; it hears that attack |
| A permanent gain while dying (Flying Ace) | `ace.gd` | `combat.buff(..., true)` in `on_kill` |
| Outnumbered | `squire.gd`, `outnumbered_aura.gd` | `Q_UNCOUNTED`; `combat.outnumbered_by(side)`, `view.outnumbered_by`, `report.outnumbered_by` (fixed at fight start) |
| An attack that takes no damage | `tilter.gd` | `combat.attack_now(unit, null, true)` |
| Overrun | `overrun.gd` | `on_damage_dealt`: `combat.damage_from_own_attack()` is true only for this unit's own attack on its target (not its strike back, a Cleave splash, a Hit or an effect; `damage_from_attack()` is true for all of the exchange); `combat.choose_target(unit)` never returns a dying unit |
| "The weakest enemy" (Ballista) | `test_9_5_choose_target_never_returns_a_dying_unit_...` | `combat.weakest_enemy(unit)` |
| Returns: Molt and Root | `molt.gd`, `root.gd`, `root_full.gd` | the return protocol (below) |
| "5 a fight", "once a fight" | `molt.gd`, `root.gd` | `unit.fight_count(&"<prefix>key")`, `unit.add_fight_count(...)`; `combat.show_uses(unit, key, left, source)` shows uses left |
| Deaths counted as each resolves (Eighth Plague) | `count_deaths.gd` | `after_friendly_death`: `combat.bridge(side).deaths` is 1 for the first death of a batch, 2 for the second |
| Hand Reserve | `colonel.gd` | `side_query` answering `Q_HAND_RESERVE` |
| An Order usable only from some slots (Lance Corporal) | `corporal.gd` | `ability_usable(player, unit, params)` false makes it illegal; `game.recruit.ability_error(player, unit, bound)` says why, for a screen to grey it |
| "Next turn" numbers (Gorger) | `test_item_32_a_turn_counter_is_logged` | `ctx.add_turn_counter(unit, &"<prefix>key", n, unit)` logs a `turn_counter` event |
| A recruit summon into the source's own slot (an eaten death effect) | `test_item_33_...` | `ctx.summon(card_id, source_slot, true)`; `golden` is the next argument, in recruit and fight (`combat.summon(..., golden)`) |

Context methods without a card (see `tests/core/test_arrivals_and_slots.gd`): `ctx.give_card`, `ctx.slot_clear_keyword`, `FightSide.slot_set` / `slot_clear_keyword`, `combat.hit(unit, target, percent)`, `has_death_effect()` (return true from your death-effect mechanic), `StatBlock.own_attack()` / `own_health()` for anything that copies, keeps or takes stats (SHARED-RULES 43), `CombatUnit.bought`, `AuraContext.unit_counter(slot, key)`.

Card data: the design folders' `units.json` (SHARED-RULES section 6) map onto the engine's cards as `tribe` -> `tribes`, the words of `type` -> `types`; `implementer` says how each unit works.

### The return protocol

A unit that dies may come back once per death. Each mechanic on it can offer:

- `return_offer(combat, unit, params) -> int`: above 0 to offer (check your charges and costs here; pay nothing yet).
- `return_priority(params) -> int`: the highest offer wins; `RETURN_FIRST` (Root) beats `RETURN_PLAIN` (Molt, the default). Molt and Root on one unit: Root fires when the Compost can pay, else Molt.
- `return_as_recruit(params) -> bool`: true comes back as it stands on the recruit board (Root); false is a plain copy of the card, with no counters, buffs or given mechanics.
- `pay_return(combat, gone, back, params)`: runs for the chosen mechanic only. Spend the heap, count the charge on `back`, buff it.
- `on_returned(...)`: runs for every mechanic on the returned unit, after `pay_return`.

`fight_counts` and `uses` carry across a return, so per-fight limits hold (SHARED-RULES 21). The log shows one `return` event (the unit as it now stands, with `mechanic` and `from_uid`), then what the hooks logged. A return is not a summon: `on_fight_enter` doesn't hear it; listen with `after_friendly_return`. This is the only way to return: the core's Reborn offers through it too.

### Rules for every hook

- Call `ctx.trigger(unit, id)` / `combat.trigger(unit, id)` before acting, and do nothing if it returns false.
- Listener hooks run for standing mechanics with `unit == null`: check it. In a fight, `combat.listening_side` says whose standing mechanic is running (use it with `combat.trigger_side`).
- Keep no state on the script (one instance serves every unit). Per-fight state: `CombatUnit.state` or `combat.bridge(side).state`. Per-game: `Unit.counters`, `PlayerState.counters`, heaps. Per-turn: `Unit.turn_counters`.
- Change state only through `RecruitContext`, `Combat` and `FightSide` methods, so every change has an event (the soak checks heaps and slots against their events, and that every unit an event names was placed first). Don't reach into engine state; if a method is missing, ask.
- **Dying units** (0 Health or destroyed, waiting for the death check after the attack or effect) are left out of `combat.units()`, `select`, `random_enemy`, `weakest_enemy` and `choose_target`. Count and target through these and you never pick one. `unit_at(side, slot)` still returns them.
- **Contracts nothing enforces:** every death effect answers `has_death_effect()` true (the locusts' War-drummer copies only those); Seed implements `on_recruit_death` (or an eaten briar adds nothing to the Compost).
- When a one-use keyword or charge is used up (a Molt or Root charge spent), call `combat.show_status(unit, &"<prefix>keyword", false, source)` so the screen drops its pill.

## 5. Running only your tribe

- Tests: put GUT tests in `tests/content/<tribe>/` and build sessions with `CoreKit.content(["<tribe>"]).session(seed)` (`tests/core/core_kit.gd`). Run one folder: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/content/<tribe> -gexit`.
- Tribes together: `tests/content/cross/` loads every shipped tribe (`CoreKit.all_tribes()`, no test or neutral cards) and tests each SHARED-RULES ruling between tribes with real cards. A new card that meets another tribe's mechanic gets its test there, through `tests/content/cross/cross_kit.gd`.
- Soak: `scripts/soak.sh 20 tribes=<tribe>` (add `test_cards=0` to leave out the bridge test cards, `neutral=0` to leave out the neutral units). With no `tribes=` it loads every tribe.
- The gate: `scripts/check.sh` runs every test folder and a short soak of everything; it must pass before you push.
