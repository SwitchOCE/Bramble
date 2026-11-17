# gdlint: disable=max-public-methods
# The context is the whole API a Recruit Phase hook may use, so it is one class on purpose.
class_name RecruitContext
extends RefCounted
## What a Recruit Phase hook may do, for one player during one action. Mechanics call these and
## never touch the player, the pool or the log directly. Counts triggers against the per-action
## limit (9.10.2).

var session: GameSession
var player: PlayerState
var rng: Rng
## A SLOT or SHOP_UNIT target of the card or ability being resolved (Mechanic.Target); -1 if none.
var target_index: int = -1
var _recruit: Recruit
var _triggers: int = 0
var _limit: int = 1000


func _init(game: GameSession, recruit: Recruit, who: PlayerState) -> void:
	session = game
	_recruit = recruit
	player = who
	rng = recruit.effect_rng(who)
	_limit = game.config.action_trigger_limit


func geometry() -> BoardGeometry:
	return session.geometry


## Call before a hook acts: logs the trigger. False once the action's trigger limit is reached,
## and the hook must then do nothing.
func trigger(unit: Unit, mechanic_id: StringName) -> bool:
	if _triggers >= _limit:
		return false
	_triggers += 1
	session.log_event(
		{
			"type": "trigger",
			"player": player.id,
			"uid": unit.uid if unit != null else -1,
			"mechanic": String(mechanic_id)
		}
	)
	return true


func triggers_used() -> int:
	return _triggers


## 12.1.1: `permanent` for the rest of the game, otherwise this turn.
func buff(unit: Unit, attack: int, health: int, permanent: bool, source: Unit) -> void:
	if permanent:
		unit.stats.perm_attack += attack
		unit.stats.perm_health += health
	else:
		unit.stats.turn_attack += attack
		unit.stats.turn_health += health
	var event: Dictionary = {
		"type": "buff",
		"player": player.id,
		"uid": unit.uid,
		"attack": unit.attack(),
		"health": unit.health(),
		"source_uid": source.uid if source != null else -1,
		"duration": "permanent" if permanent else "turn",
	}
	session.log_event(event)


func gain_gold(amount: int, source: Unit) -> void:
	player.gold = maxi(0, player.gold + amount)
	session.log_event(
		{
			"type": "gold",
			"player": player.id,
			"amount": amount,
			"gold": player.gold,
			"source_uid": source.uid if source != null else -1
		}
	)


## 8.4.7 a summon in the Recruit Phase: placed by 8.4, Created (4.3.1). Null when it fails.
## `own_slot_first` for a unit's own effect that summons into its own slot when that is empty (an
## eaten unit's death effect: the slot the sold unit left, 8.4.1); `golden` for a golden token.
func summon(
	card_id: StringName, source_slot: int, own_slot_first: bool = false, golden: bool = false
) -> Unit:
	return _recruit.summon(self, card_id, source_slot, own_slot_first, golden)


## 6.2 Discover a unit with a tier in [min_tier, max_tier].
func discover(min_tier: int, max_tier: int) -> void:
	_recruit.offer_discover(player, min_tier, max_tier)


## The units on this player's board for a selector (Selectors), in reading order.
func select(unit: Unit, selector: String) -> Array[Unit]:
	var out: Array[Unit] = []
	for slot: int in Selectors.slots(session.geometry, unit.slot, player.occupied(), selector):
		out.append(player.board[slot])
	return out


func random_of(units: Array[Unit]) -> Unit:
	if units.is_empty():
		return null
	return units[rng.index(units.size())]


## --- Lasting state (12.1.1 "this game") -----------------------------------------------------


## A player-level number that lasts the game (PlayerState.counters).
func add_counter(key: StringName, amount: int, source: Unit) -> void:
	session.registry.check_name(key, "player counter")
	player.counters[key] = player.counter(key) + amount
	_log({"type": "player_counter", "key": String(key), "value": player.counter(key)}, source)
	_recruit.refresh_auras(player)


## A number on a unit for this turn only (Unit.turn_counters; "ate this turn"), logged as
## `turn_counter`. Cleared at the start of each turn.
func add_turn_counter(unit: Unit, key: StringName, amount: int, source: Unit) -> void:
	session.registry.check_name(key, "turn counter")
	unit.turn_counters[key] = unit.turn_counter(key) + amount
	_log(
		{
			"type": "turn_counter",
			"uid": unit.uid,
			"key": String(key),
			"value": unit.turn_counter(key),
		},
		source
	)


## A number on a unit that lasts the game (Unit.counters).
func add_unit_counter(unit: Unit, key: StringName, amount: int, source: Unit) -> void:
	session.registry.check_name(key, "unit counter")
	unit.counters[key] = unit.counter(key) + amount
	_log(
		{
			"type": "counter",
			"uid": unit.uid,
			"key": String(key),
			"value": unit.counter(key),
			"permanent": true
		},
		source
	)


## An entry into one of the player's heaps; "whenever an entry goes in" listeners hear it.
func heap_add(heap_name: StringName, card_id: StringName, source: Unit) -> void:
	session.registry.check_name(heap_name, "heap")
	var tier: int = session.library.get_card(card_id).tier if session.library.has(card_id) else 1
	player.heap(heap_name).add(card_id, tier)
	_log(
		{
			"type": "heap_add",
			"heap": String(heap_name),
			"id": String(card_id),
			"size": player.heap(heap_name).size()
		},
		source
	)
	_recruit.notify(self, &"on_heap_added", [heap_name, card_id])
	_recruit.refresh_auras(player)


## Spends the `count` lowest entries; false, and nothing spent, when there are fewer.
func heap_spend(heap_name: StringName, count: int, source: Unit) -> bool:
	var spent: Array[StringName] = player.heap(heap_name).spend_lowest(count)
	if spent.is_empty():
		return false
	_heap_removed(heap_name, spent, source)
	return true


## Takes the highest entry; &"" when the heap is empty.
func heap_take(heap_name: StringName, source: Unit) -> StringName:
	var card_id: StringName = player.heap(heap_name).take_highest()
	if card_id != &"":
		_heap_removed(heap_name, [card_id] as Array[StringName], source)
	return card_id


func _heap_removed(heap_name: StringName, ids: Array[StringName], source: Unit) -> void:
	_log(
		{
			"type": "heap_remove",
			"heap": String(heap_name),
			"ids": ids.map(func(c: StringName) -> String: return String(c)),
			"size": player.heap(heap_name).size()
		},
		source
	)
	_recruit.refresh_auras(player)


## 8.5 a slot buff given in the Recruit Phase, and optionally a keyword the slot gives; it
## lasts the game (8.5.3).
func slot_buff(
	slot: int, attack: int, health: int, source: Unit, keyword: StringName = &""
) -> void:
	var percent: int = session.rules.slot_buff_percent(player)
	attack = int(attack * percent / 100.0)
	health = int(health * percent / 100.0)
	var here: SlotState = player.slots[slot]
	here.attack += attack
	here.health += health
	if keyword != &"" and not here.keywords.has(keyword):
		here.keywords.append(keyword)
	_log(
		{
			"type": "slot",
			"slot": slot,
			"attack": attack,
			"health": health,
			"total": here.view(),
			"permanent": true
		},
		source
	)
	_recruit.refresh_auras(player)


## Clears a keyword from a slot for good (moving a Guard post).
func slot_clear_keyword(slot: int, keyword: StringName, source: Unit) -> void:
	var here: SlotState = player.slots[slot]
	here.keywords.erase(keyword)
	_log(
		{
			"type": "slot",
			"slot": slot,
			"attack": 0,
			"health": 0,
			"total": here.view(),
			"permanent": true
		},
		source
	)
	_recruit.refresh_auras(player)


## A new copy of a card into the hand (a Created card: no pool copy, sells for nothing, 4.3.1).
## Lost if the hand is full (7.1.2). Returns it, or null.
func give_card(card_id: StringName, source: Unit) -> Unit:
	if not session.library.has(card_id):
		return null
	var made: Unit = session.new_unit(session.library.get_card(card_id), false)
	_log({"type": "give_card", "uid": made.uid, "id": String(card_id)}, source)
	return made if _recruit._gain(player, made) else null


## 11.1.1 a unit gains a keyword for good. False if it had it or the keyword is unknown.
func give_keyword(unit: Unit, keyword: StringName, source: Unit) -> bool:
	if not unit.grant(session.registry, keyword):
		return false
	_log({"type": "keyword", "uid": unit.uid, "keyword": String(keyword), "on": true}, source)
	return true


## A unit gains a mechanic with parameters for good ('Give a unit "+1 Fury"', Master-at-Arms):
## `raw` holds its parameters as card data does. The numbers are the giver's: a golden target
## never doubles them (pass the giver's params.num value). Logged as `effect`. False when the
## mechanic is unknown or the parameters are wrong.
func give_effect(unit: Unit, mechanic_id: StringName, raw: Dictionary, source: Unit) -> bool:
	if not unit.grant_effect(session.registry, mechanic_id, raw):
		return false
	_log(
		{
			"type": "effect",
			"uid": unit.uid,
			"mechanic": String(mechanic_id),
			"params": raw.duplicate()
		},
		source
	)
	_recruit.refresh_auras(player)
	return true


## Takes a unit card out of the shop: its pool copy goes back (5.3.7) and its id is returned
## (&"" for an empty slot). What happens to it next is the mechanic's (a heap entry, say).
func take_from_shop(index: int, source: Unit) -> StringName:
	if index < 0 or index >= player.shop_units.size():
		return &""
	var card_id: StringName = player.shop_units[index]
	if card_id == PlayerState.NO_CARD:
		return &""
	player.shop_units[index] = PlayerState.NO_CARD
	session.units.give_back(card_id)
	_log({"type": "shop_take", "index": index, "id": String(card_id)}, source)
	return card_id


## A unit's death effects in the Recruit Phase, without a death (Mechanic.on_recruit_death).
func run_death_effects(unit: Unit) -> void:
	_recruit.run_death_effects(self, unit)


## Gives the player a standing mechanic (no unit) once; false if it has it or it's unknown.
func add_standing(mechanic_id: StringName) -> bool:
	if player.has_standing(mechanic_id) or not session.registry.has(mechanic_id):
		return false
	player.standing.append(session.registry.bind(MechanicSpec.new(mechanic_id), false, false))
	_recruit.refresh_auras(player)
	return true


func _log(event: Dictionary, source: Unit) -> void:
	event["player"] = player.id
	event["source_uid"] = source.uid if source != null else -1
	session.log_event(event)
