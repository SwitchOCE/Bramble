# Rules core

A headless rules engine for the second ideation track, following [rulebook v0.8](../../docs/design/rulebook.md) with no heroes or hero powers. Every class is `RefCounted`; nothing here is a Node. Nothing in it is decided for the real game (`CLAUDE.md`, "Main and its archive").

## Layout

| Folder | What |
|---|---|
| `util/` | `CoreUtil` typed conversions; `Rng`, the core's own FNV-1a hash and xoshiro128** generator |
| `rules/` | `GameConfig` (every Appendix A number), `Rules` (named rule queries: base answer, then unit text, then caps) |
| `board/` | `BoardGeometry` (chapter 8 as instance data), `Selectors` (positional selectors, written once) |
| `units/` | `UnitDef` (card data), `UnitLibrary` (JSON loader and checker), `Unit` (a held card), `StatBlock` (stat layers), `ShopOdds` (fixed draw weights), `UnitText` (card text with golden numbers) |
| `state/` | Lasting and shared state: `CardHeap` (a named list of card entries), `SlotState` (8.5 slot effects), `AuraContext` (what an aura may read), `FightReport` (what after_fight learns) |
| `mechanics/` | `Mechanic` (the hook interface), `MechanicParams` (typed parameters), `MechanicRegistry`, and the built-in keywords and effects |
| `recruit/` | `PlayerState`, `Recruit` (the Recruit Phase and its actions), `RecruitContext` (what recruit hooks may do), `LegalActions` |
| `combat/` | `Combat` (one fight and its log), `CombatUnit`, `FightSide` (one side's bridge to its player), `FightAuras`, `FightArrivals` (who fills an emptied slot), `FightDeaths` (death resolution, the return protocol, the end) |
| `session/` | `GameSession` (the lobby and round flow), `Matchmaking` |
| `bots/` | `Bot`, `SimpleBot` (greedy), `RandomBot` (random legal play, for the soak) |

Content loads through `ContentSet` (`content/`) from folders: `src/content/<tribe>/` for the game, `tests/core/content/neutral/` (neutral test units) and `tests/core/content/test/` (the bridge test cards, one script per mechanic, ids prefixed `test_`). Test folders are not content. Adding a tribe: `docs/ideation-track-2/ADDING-A-TRIBE.md`.

## Phase order

A round, driven by a bot, a test or a UI:

1. `GameSession.start_round()`: round + 1; pairing (2.3: a seeded round-robin while all 8 live, then the least-repeating pairing over the last 3 rounds); the ghost for an odd player out (2.1.2); then each living player's start of turn (3.2.1): gold = carried + income, the upgrade discount from turn 2, the refresh count reset, the shop refilled (a frozen shop keeps its cards), gold earned in the last fight added, `Unit.turn_counters` cleared, start-of-turn triggers in reading order and then the player's standing mechanics.
2. `GameSession.act(player, action)` as often as the player likes (3.3). Actions are dictionaries: `buy`, `sell` (hand or board units), `play` (units and spells), `move`, `to_hand`, `refresh`, `freeze`, `upgrade`, `pick` (a Discover choice), `recruit_target` (a gained unit's pending target), `ability` (a board unit's activated ability, 3.3.1), `end_turn`. `act` returns `""` or why the action is illegal, and an illegal action changes nothing. `GameSession.legal_actions(player)` lists every legal action. After each action, triples form (7.3.1, after all summons) and auras and slot effects are recomputed (12.2.1, 8.5). Any sale is heard by `on_any_sold`.
   Unit Recruit effects use `on_recruited` through `_gain`, after the card enters hand; a full hand loses the card without its effect. Buy/pick actions list a `target`: an existing friendly unit's uid (hand or board), or `-1` for the new unit itself. Omitting it completes the gain and waits for a `recruit_target` action; other actions wait until that choice resolves. The UI uses this to aim after buying or picking. A golden formed by a triple recruits with its doubled numbers, and the Triple Reward spell is gained at formation. Playing the golden gives no reward. A gained copy that completes a triple merges without firing its own recruit effect; only the golden fires. Other copies recruit normally. End turn resolves pending targets to their own unit. Playing a unit fires no hooks; spells still call `on_played` when cast.

3. `end_turn` (3.4.1): End of Turn triggers, "this turn" ends, an unfrozen shop clears, gold is kept.
4. `GameSession.finish_round()`: ends any open turn; every pair fights (chapter 9), and right after each fight its live players' boards hear `after_fight` with a `FightReport`; the loser takes the round's small or big loss (10.1); eliminations after all fights, placed by health (10.2); the game ends with one player left or at round 50 (2.1.3).

Inside a fight (`Combat.run`): copy boards, slot effects, and the players' counters and heaps (`FightSide`) → auras → `on_combat_begin` → `combat_start` → first attacker (9.2.1) → Start of Combat (9.3; a set-up pass on both sides, then the main pass, random player first; only units there when it begins; deaths after each effect) → alternate attacks with the attack pointer (9.4.5). A unit whose turn comes may take it `instead_of_attack` (counted as an attack); otherwise each attack (9.6.1): step 1 `on_attacked` (an attacker it kills doesn't attack: no step 2, no exchange); step 2 `on_attack`, then `on_friendly_attack` for the attacker's friends (a `hit` here that kills the defender ends the attack); step 3 the exchange (cleave splash); step 4 `after_attack` (even when a friend's hit killed the defender); step 5 death resolution (9.7): dying units leave → step 1 `on_kill`, `on_any_death` → step 2 own death effects (`Q_DEATH_EFFECT_TIMES` times) and `on_friendly_death` counters → step 3 `after_friendly_death` → step 4 returns (the return protocol: `return_offer`, `return_priority`, `pay_return`, then `on_returned`; the only way to return) → step 5 `after_friendly_return` → Reserve, waiting summons, `after_death_round` → new deaths repeat. A side's `deaths` count goes up as each death reaches step 3. Pile-on hits asked for while friends hear an attack land together once all have heard it. Then end (9.9) or a limit (9.10, a tie). Every board change recalculates auras on both boards.

## Free zone moves and the work lock (C15 prototype)

`sell` accepts either `{"type": "sell", "slot": n}` or `{"type": "sell", "hand": n}`. Only units sell; the same value and sale listeners apply to both. A hand sale has no last-known board slot. `{"type": "to_hand", "slot": n}` moves the existing unit to hand for free, preserving its own buffs, grants, origin and turn counters. Its former slot is empty. Board auras and slot bonuses are recalculated; the move is not a gain, so it never recruits the unit. Full hands refuse the move.

A board unit with `worked_this_turn` cannot move back to hand; it may still move between board slots or be sold. `PlayerState.mark_worked` checks actual board membership, so a sold source retaining its old slot cannot be mistaken for the unit now standing there. Triples inherit the work flag but still pull locked board copies into hand: automatic tripling takes priority over the manual return lock (7.3.1). Start turn clears flags before the income query and start-turn effects can set them again.

`RecruitContext.invoke` scopes the active hook source through recursive listeners and death effects. Successful context mutations mark that source, rather than treating every `trigger` log as useful work. A lost generated card, failed summon, unchanged slot keyword or zero change does not lock its source. A successful Order marks its source when its use is consumed. The recruited source is exempt, including a golden placed on the board by the full-hand fallback; other listeners it causes remain eligible. Combat, after-fight work and continuous borrowed auras do not set this Recruit Phase flag.

Rules queries stay read-only. Their optional `used` array identifies effective contributing units; buy, refresh, upgrade and income code commits those contributors only when the action actually happens. `RecruitContext.ask` carries permanent-effect multiplier attribution into successful descendant mutations (Dirge, Mother and Midden); give-time slot buffs commit Sergeant Major directly. Redundant non-stacking copies and capped-away changes do not become contributors.

## Event schema

Every event is a JSON-shaped Dictionary with a `type`. Slots are 0–6 in reading order (`F1`–`F4` are 0–3, `B1`–`B3` are 4–6); `side` is 0 or 1; `uid` names one unit for the whole fight. Fights record `GameSession.fights[i].events`; everything else goes to `GameSession.events`, each event with `round` and, for player events, `player`.

**Fight log** (`Combat.events`):

| type | fields |
|---|---|
| `combat_start` | `players` [a, b], `first` side, `boards` [[unit view], [unit view]], `slots` [[slot view] × 7, ...], `counters` [{key: n}, {key: n}] and `heaps` [{name: size}, {name: size}] (each side's player numbers), `reserve` [[unit view], [unit view]], `outnumbered_by` [n, n]; unit view = `uid, recruit_uid` (the recruit card it copies; -1 for one made in the fight)`, id, side, slot, label, attack, health, golden, bought, keywords, grants` (mechanics with numbers an aura gave, `{"mechanic", <param>}`)`, effects` (its own mechanics with numbers: Fury 3, Thorns 4)`, totals` (one number per parameter for each mechanic with numbers, its own, given and granted together, combined as grants combine: printed Fury 1 and a given +1 Fury show as Fury 2)`, counters, uses` ({key: uses left})`, text, reminders`; slot view = `attack, health, keywords` (stored), `given_attack` (what it gives this fight), `percent` |
| `trigger` | `side, slot, uid, mechanic` (a hook acted; a return's trigger names the mechanic that brought the unit back) |
| `attack` | `side, slot, uid, target_side, target_slot, target_uid, out_of_turn` (9.4.12)`, takes_no_damage` |
| `instead_of_attack` | `side, slot, uid, mechanic` (the unit took its turn another way; counts toward the attack limit, 9.10.1) |
| `damage` | `side, slot, uid, amount` (> 0), `health` after, `source_uid` (-1 for none), `from_attack` (an attack's exchange or splash) |
| `prevented` | `side, slot, uid, amount, reason` (`takes_no_damage`, `absorbed`), `source_uid`: damage that did nothing (the Thorns a no-damage attack ignored, a shield) |
| `destroy` | `side, slot, uid, source_uid` (the unit whose effect destroyed it) |
| `buff` | `side, slot, uid, attack, health` (new values), `source_uid`, `permanent` (also written to the recruit unit) |
| `stats` | a unit view plus `slot_attack, slot_health, aura_attack, aura_health` (the borrowed parts) and `after` (the index of the event that caused it): its Attack, Health or keywords changed through an aura or slot effect. One follows every aura or slot change that changes what a unit shows (auras are recalculated after every board, buff, counter, heap or slot change); none for a unit before its summon or return event |
| `slot_percent` | `side, percent, source_uid`: this side's slots give `percent` of their Attack buff for the rest of the fight (the Edgewright) |
| `effect` | `side, slot, uid, mechanic, params, permanent, source_uid`: a unit was given a mechanic with numbers ("+2 Fury") |
| `uses` | `side, slot, uid, key, left, source_uid`: uses left on a unit changed ("5 a fight", Molt charges) |
| `hit` | `side, slot, uid, target_side, target_slot, target_uid` (followed by its `damage`; not attack damage) |
| `keyword` | `side, slot, uid, keyword, on`, `source_uid` |
| `counter` | `side, slot, uid, key, value, permanent, source_uid` (a unit's lasting number) |
| `player_counter` | `side, key, value, source_uid` |
| `heap_add` / `heap_remove` | `side, heap, id` / `ids`, `size` after, `source_uid` |
| `slot` | `side, slot, attack, health` (the change), `total` (slot view), `permanent`, `source_uid` |
| `gold` | `side, amount, next_turn` (gold earned in the fight) |
| `summon_waiting` | `side, id, source_uid` (no room yet; it lands after a death resolution, as a `summon` with `waited` true and its `payload`) |
| `reserve` | a unit view plus `source_uid` -1: a hand unit stepping into a slot a friend died in (`combat_start` lists each side's waiting `reserve`) |
| `heap_use` | `side, heap, count, ids, entries` (each entry's `n`)`, unused, source_uid` (entries used for this fight, named; the heap doesn't change) |
| `status` | `side, slot, uid, status, on, source_uid`. `on` false: a one-use keyword is used up, so the screen drops its pill (Divine Shield after its block, Venomous after its kill, Stealth ending, Reborn on the returned copy, a tribe's spent charge). The source is the unit whose damage it stopped, or that used it |
| `death` | `side, slot, uid` (the slot it left), `killer_uid` (whose damage or destroy effect last hit it; -1 for none) |
| `summon` | a unit view (with `keywords`, `golden`) plus `source_uid`, so a screen can draw it |
| `summon_failed` | `side, id` |
| `return` | a unit view of the new unit as it stands once its return resolved (after `pay_return` and `on_returned`; what they logged follows the event), `from_uid`, `mechanic` (the return that fired), `source_uid`. A return is its own event: not a `summon`, and not heard by `on_fight_enter` (SHARED-RULES 22) |
| `pass` | `side` |
| `combat_end` | `winner` (side, or -1 for a tie), `reason` (`board_empty`, `no_attacks`, `attack_limit`, `trigger_limit`), `starting` [n, n], `killed` [n, n] (starting units killed, 10.1.2), `attacks`, `triggers`, `survivors` [[uid], [uid]] |

**Game log** (`GameSession.events`): `round_start` (`pairs`), `turn_start` (`gold`, `shop`), `buy`, `sell`, `play`, `cast`, `move`, `refresh`, `freeze`, `upgrade`, `discover` (`options`), `discover_queued` (`waiting`), `pick`, `gain`, `card_lost`, `summon`, `summon_failed`, `triple`, `trigger`, `buff`, `gold`, `ability`, `shop_take`, `counter`, `turn_counter`, `player_counter`, `heap_add`, `heap_remove`, `slot`, `keyword`, `effect`, `turn_end`, `fight` (`players`, `winner`, `loser`, `damage`, `reason`), `eliminated` (`placement`, `health`), `game_end` (`placements`). `PlayerState.view()` and `Unit.view()` give the state a UI shows; `GameSession.view_for(player)` adds prices (refresh, upgrade, each shop card, each sell), the round, the current opponent and the legal actions in one call; `Recruit.ability_error(player, unit, bound)` says why an Order can't be used, so a screen can dim it. Views include unit `counters`, `effects`, `totals` and `text`, and the player's `counters`, `heaps`, `slots` and `standing`, under the names the mechanics chose, so a screen can show medals, a heap or slot buffs without knowing any tribe. The screens read these and the fight log, not the game log, which stays small. What `after_fight` changes on the real boards is in each fight's `after` list (`GameSession.fights`), so the screen after a fight can show it.

**Golden text (7.3.5).** Card data writes numbers as `{param}` placeholders ("+{amount}/+{amount}"). `Unit.view()["text"]` fills them from the bound parameters, already doubled on a golden for `NUMBER` and kept for `THRESHOLD`, so one text serves both. Where golden is not a plain doubling, an effect gives a parameter its own golden value (`{"mechanic": ..., "amount": 4, "golden": {"amount": 6}}`) and the card carries `"golden_text"`, which a golden copy shows instead of `text`. `"reminders": [...]` adds card-specific reminder lines to the view.

## How a mechanic plugs in

1. Write a script that `extends Mechanic` and overrides only the hooks it needs; `mechanic.gd` lists every hook with its rule step. Self hooks run for the unit's own text. Listener hooks ("a friendly unit …", "any …") run for every unit on that board in reading order and then for the player's standing mechanics with `unit = null`; `combat.listening_side` says whose standing mechanic is running (the core sets it on every such call, `side_query` included).
2. Declare its parameters once in `param_kinds()`: `NUMBER` (doubled on a golden, 7.3.5), `THRESHOLD` (never doubled) or `TEXT`. The library rejects card data with an unknown, missing or wrongly typed parameter.
3. Act only through the context. Recruit hooks get a `RecruitContext`: `trigger`, `buff` (this turn or permanent), `summon` (own slot first, golden), `gain_gold`, `discover`, `select`, `random_of`, `add_counter` / `add_unit_counter` / `add_turn_counter`, `heap_add` / `heap_spend` / `heap_take`, `slot_buff` (with an optional keyword), `give_keyword`, `give_effect` (a mechanic with numbers), `take_from_shop`, `run_death_effects`, `add_standing`, and `target_index` for a slot or shop target. Combat hooks get `Combat`: `trigger`, `buff` (`permanent` writes back), `deal_damage`, `damage_from_attack`, `damage_from_own_attack`, `destroy`, `hit`, `attack_now`, `summon` (`wait` for no room, `golden`), `run_death_effects`, `side_query`, `select`, `random_enemy`, `weakest_enemy`, `choose_target`, `units`, `unit_at`, `show_status`, `show_uses`, `effect_rng`, and `bridge(side)` (a `FightSide`: `counter` / `add_counter`, `add_unit_counter`, `heap` / `heap_add` / `heap_spend` / `heap_take` / `heap_use` / `heap_use_highest`, `slot` / `slot_buff` / `slot_attack_given` / `set_slot_attack_percent`, `give_keyword` / `give_effect`, `add_gold`, `deaths`, `state`, `real_unit`, `player`, `writes_back`). **Dying units** (0 Health or destroyed, waiting for the next death check) are left out of `units`, `select`, `random_enemy`, `weakest_enemy` and `choose_target`; `unit_at` still returns them. Per-fight limits go in `CombatUnit.fight_count` / `add_fight_count`, which a return carries (SHARED-RULES 21). Call `trigger(unit, id)` first: it logs the trigger and counts it against the limits (9.10.2). Keep no state on the script, since one instance serves every unit: a fight's state goes in `CombatUnit.state` or `FightSide.state`, a game's in `Unit.counters`, `Unit.turn_counters` or `PlayerState.counters`.
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
| An aura that sees the fight | Berserk (`outnumbered_aura`) | `aura(view, ...)`: `view.outnumbered_by`; also `view.counter`, `view.heap_size`, `view.count_tribe` |
| Lends: an aura from a unit's own numbers | Lender (`lend`) | `view.attack_at(source_slot)`, `view.max_health_at(source_slot)` (as it stands: permanent and slot buffs included) |
| A slot doubling that outlives its unit | Edgewright (`edgewright`) | Start of fight set-up pass: `bridge(side).set_slot_attack_percent(200, unit)` |
| Overrun | Overrunner (`overrun`) | `on_damage_dealt`: `combat.damage_from_own_attack()` (its own attack on its target, not its strike back or a splash), then `combat.choose_target(unit)` (never a dying unit) |
| Returns: Root and Molt on one unit | Rooter (`root`), Molter (`molt`), Twice-rooted | `return_offer`, `return_priority` (`RETURN_FIRST` for Root), `pay_return`; charges in `fight_count`; `show_uses` |
| Giving a mechanic with a number | Arms Master (`arms`), Furious (`fury`) | `ctx.give_effect(target, id, {"amount": n}, unit)`; in a fight `bridge(side).give_effect(...)` |
| Grants that take the lowest | `low_cost` | `grant_combine` returns `Combine.MIN` |
| Hand Reserve | Colonel (`colonel`) | `side_query` `Q_HAND_RESERVE` |
| An entry added in a fight | Briar (`fight_heap_watch`) | `on_heap_added_in_fight` |
| An Order usable only from some slots | Corporal (`corporal`) | `ability_usable(player, unit, params)` |
| Deaths counted as each resolves | Plague (`count_deaths`) | `after_friendly_death`: `bridge(side).deaths` |
| A friend's attack | Piler (`pile_on`) | `on_friendly_attack`: `combat.hit(unit, defender)` |
| Slot buffs | Driller (`drill_slot`), Slot Gift (`slot_gift`) | `ctx.slot_buff(slot, a, h, unit)`; a play or ability with `Target.SLOT` reads `ctx.target_index` |
| An ability with a cost and a target | Officer (`order_slot`) | `has_ability`, `ability_cost`, `ability_target`, `on_ability`; the slot gives Taunt through `slot_buff(..., &"taunt")` |
| An ability on a shop card | Burier (`bury`) | `Target.SHOP_UNIT`; `ctx.take_from_shop(i, unit)` then `ctx.heap_add` |
| A heap every sale feeds | `heap_on_sale` (standing) | `on_any_sold` with `unit = null`; given by `GameSession.give_standing` |
| Reading and spending the real heap in a fight | Grower (`grow`), Seeder (`seed_heap`), Rooter (`root`) | `combat.bridge(side).heap(...)`, `heap_add`, `heap_spend`; a paid return through `return_offer` and `pay_return` |
| A player number that lasts the game | Tider (`tide_on_death`, `tide_rider`) | `bridge(side).add_counter(&"tide", 1, unit)`; the aura reads `view.counter(&"tide")` |
| Side rules | Dirge (`death_twice`) | `side_query` answers `Q_DEATH_EFFECT_TIMES` |
| Attacks immediately (9.4.12) | Charger (`charge`) | `combat.attack_now(unit)` |
| Targeting override (9.5.7) | Raider (`back_row_raider`) | `combat_query` answers `Q_TARGET_ROW` with `ROW_BACK` |
| Waiting summons | Swarm Mother (`swarm_spawn`) | `combat.summon(..., wait = true)` |
| An aura that gives a keyword | Lender (`lend_keyword`) | `aura_keywords` |
| Any sale; death effects in the Recruit Phase | Eater (`eat`) | `on_any_sold`: permanent `ctx.buff`, `ctx.run_death_effects(sold)` (`on_recruit_death`) |
| Joining the fight | Greeter (`greet`) | `on_fight_enter` |
| Damage from attacks only | Plated (`plate`) | `absorb_damage(..., from_attack, ...)` |
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
| Returning as it stands | Oak (`root_full`) | `return_offer` and `return_as_recruit` |

Context methods shown in `tests/core/test_arrivals_and_slots.gd` without a card of their own: `ctx.give_card` (a Created card to hand), `ctx.slot_clear_keyword` / `FightSide.slot_clear_keyword` (moving a Guard post), `FightSide.slot_set` (a copy, not a buff given), `FightSide.heap_use` / `heap_unused` (entries used for this fight), `combat.hit(unit, target, percent)`, `combat.choose_target`, `Unit.has_death_effect` / `CombatUnit.has_death_effect`, `StatBlock.own_attack` / `own_health` (own stats, SHARED-RULES 43), `CombatUnit.bought`, `AuraContext.unit_counter`, and the sell event's `slot` (the sold unit keeps the slot it was sold from in `on_any_sold`).

Not shown by a test card but there: `Q_CANT_ATTACK`, `FightSide.add_gold` (paid next turn), `on_heap_added`, `after_friendly_return`, `on_any_death`, and a golden from a triple adding up its copies' counters. Tested in `tests/core/test_core_pass4.gd`: golden fight summons, heap marks by entry, `add_turn_counter`, own-slot-first recruit summons, golden text and golden parameter values, reminder lines, what the fight log tells a screen.

**Removed once the five tribes were in, with no caller left** (17 Nov): `Q_STRIKES_FIRST`, `move_unit` and the fight log's `move` event, `on_board_enter`, `after_friendly_attack`, `remove_keyword`, `ROW_ANY`, `Combine.MAX`, `FightSide.heap_used`, `CombatUnit.returned_by`, `view_for`'s `abilities`, the `class_name` scan and `MechanicRegistry.loud`, and the older return route (`Q_RETURN_HEALTH`, `return_health`, `Q_RETURN_AS_RECRUIT`; Reborn now offers through the protocol). `AuraContext.outnumbered()` is gone: `outnumbered_by` is the rule. Kept though no shipped card has them: the Battlegrounds keywords `divine_shield`, `reborn`, `venomous` and `stealth` and the stand-in effects, because the game's stand-in cards (`src/game/data/stand_in_units.json`) and the neutral test units use them. Per-parameter golden numbers (Pigeons, Locusts) and the `slot_buff` display id (Pigeons) are in use.

## Taken from the first run and left behind

Taken from the tag `archive/branches/ideation/main`, rewritten to the prototype lessons' "What to carry into real development" list: the session/recruit/combat split and the round flow; `CoreUtil`; `BoardGeometry`'s relations and summon table (now built from instance data); weighted card draws (now `ShopOdds`); round pairing with avoidance; the attack pointer, death passes and limits; the event log as the UI contract; the soak with fight counting and planted faults.

New against the lessons: stat layers, rule queries with a unit layer, combat queries in place of keyword names in `Combat`, status state on the unit, the selector library, combat sub-streams (`first`, `soc`, `target`, `effect`) over an owned hash and generator, geometry as instance data, typed mechanic parameters declared once.

Left behind: all tribe code (`pass3_*`, the per-tribe combat and bot files, tribe recruit helpers), all unit content and libraries, heroes and hero rules, slot effects, the effect-schema engine, scale overlays and field libraries.

## Checks

- `scripts/check.sh` runs the GUT tests (`tests/core/`, named by rule number), a 10-game soak with the planted-fault proof, and, when any tribe folder exists, a 5-game soak of the shipped tribes alone (`test_cards=0 neutral=0`). The main soak plays every tribe with the neutral and bridge test cards, every player's sales feeding a heap.
- The soak's invariants also cover the new state: every heap entry is a unit card; each player's heap size and slot-buff total equal what their logged events add up to (game log plus the live side of each fight), so a leak or a duplicate shows; and every unit that dies in a fight log was last shown at 0 Health or destroyed, so a replay never shows stale numbers. Every unit a fight event names was placed first by `combat_start`, `summon`, `reserve` or `return`, so a screen can draw it. Planted faults: `empty_library`, `heap_dup`, `slot_leak` (the slot ledger), `unlogged_damage` (the replay check), `unplaced_return` (the placement check).
- `scripts/soak.sh 300` is the long soak: 300 bot-only games, about 13,500 fights, about 4 minutes on one core. `scripts/soak_plant.sh` alone proves the planted faults.

## Shop and Discover odds

Each eligible unit has a fixed weight of 15, 15, 13, 11, 9, 7 or 5 at tiers 1–7.
Each eligible Tavern spell has a weight of 5, 7, 9, 11, 9 or 7 at tiers 1–6.
The session builds these tables from `GameConfig` and the lobby's drawable cards at creation.
Each shop slot draws independently from the matching card kind, up to the player's tier.
Discover uses the tier range named by its effect and excludes ids already shown in that offer.
An empty eligible set leaves a shop slot empty or ends that Discover's draw.

## Rules this core settles

The rulebook leaves these open or silent; the core takes the simplest reading. None is decided.

- **2.1.4–2.1.5 async play:** a live 8-player lobby, as 2.1.1–2.1.3 are written.
- **5.2.2, 5.2.5 tribes:** a lobby takes a list of tribes (empty = all); the test units have none.
- **6.1.6 shop slots as an upgrade, 5.2.8 traits, 8.3.2 minimum front row, 11.5.3 back-row access, 7.3.8 multiple-copy levels:** not added.
- **2.2.3 hero choices:** no heroes on this track.
- **Divine Shield against Venomous (11.2.5):** the shield takes the hit, so no damage is dealt and the Venomous stays unused.
- **Every triple grants its Triple Reward at formation (7.3.6),** whether the golden enters hand or the board. A full hand loses the spell (7.1.2). Its Discover tier is read when the spell is cast.
- **`SLOT_BUFF_PERCENT` reads the recruit board,** so in a fight a slot doubler that died still doubles (SHARED-RULES 14).
- **Losing aura or slot Health** (a lender dies, a slot buff is set lower) never takes a unit below 1 Health.
- **The Eighth Plague's count:** a side's `deaths` goes up as each death reaches 9.7.2 step 3, so of two deaths in one batch the first reads 1 and the second 2. Death effects (step 2) read the count before the batch.
- **A return's event** shows the unit once its return resolved (Molt's +2/+2 included); what `pay_return` and `on_returned` logged follows it. `on_fight_enter` does not hear a return (SHARED-RULES 22 reads "joins the fight" as summoned or stepping in).
- **A recruited unit may target any friendly unit in hand or on board, itself included** (7.2.3, 7.2.6). Playing a unit triggers nothing. A board unit's ability never aims at its own unit.
- **Lends read a second aura pass:** auras first see each unit's own stats plus its slot; if any aura read a unit's numbers, auras run again on those totals, so a lender lends what it shows. A chain of lenders deeper than one is not followed (the board shape has none).
- **Who fills an emptied slot** (SHARED-RULES 6): own death-effect summons and returns, then Reserve (fill-first slot, then reading order, hand order), then waiting summons in one line, then `after_death_round`, then the end check. Units in hand never count for Outnumbered.
- **A second Discover opened while one is shown** waits and is drawn when the first is picked.
- **Ending a turn with a Discover open or waiting** takes the first option of each, End of Turn ones included.

## Not done

- No UI and no tribe content.
- Conceding; player-level "after an attack" effects (9.6.1 step 6; no heroes or player modifiers).
- Free and effect refreshes (4.4.5–4.4.6); shop-wide buffs (12.1.3).
- Deaths are checked after each attack or effect, not after each damage event (9.6.3). Instead every selector and target chooser leaves dying units out (`units`, `select`, `random_enemy`, `weakest_enemy`, `choose_target`), and a hit on a dying unit does nothing (pile-on hits excepted: they land together).
- A unit in hand doesn't show what a standing aura would give it on the board (a Locust's Tide): auras reach the board only.
- A golden placed on the board by 7.3.7 loses its Triple Reward when the hand is full.
- A keyword an aura or slot gives mid-fight doesn't run its `on_combat_begin` (a Divine Shield given that way starts down); at the start of the fight it does.
- Hooks without a card of their own are tested in `tests/core/test_hooks_coverage.gd` (can't attack, fight gold, `combines` false, counters on a triple, `on_heap_added`, `on_any_death`, `after_friendly_return`, standing triggers, `MAX_ATTACK_DEPTH`).
