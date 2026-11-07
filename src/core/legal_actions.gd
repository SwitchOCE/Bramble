class_name LegalActions
extends RefCounted
## What the player may do right now, from the state alone: [{"action", "args": [ints]}]. Shop and
## hand are indexes into the state's lists; a spell or hand card has its own action name. Used by
## tools/play and available to any bot or screen. Every entry listed succeeds if taken (tested).


static func of(state: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match str(state["phase"]):
		"game_over":
			return out
	var pending: Variant = state["pending_choice"]
	if pending != null:
		var choice: Dictionary = pending
		var options: Array = choice["options"]
		for index: int in options.size():
			out.append(_entry("choose", [index]))
		return out
	_shop(state, out)
	_hand(state, out)
	_board(state, out)
	_swallows(state, out)
	_economy(state, out)
	out.append(_entry("end_turn", []))
	return out


static func _entry(action: String, args: Array) -> Dictionary:
	return {"action": action, "args": args}


static func _shop(state: Dictionary, out: Array[Dictionary]) -> void:
	var gold: int = state["gold"]
	var hand: Array = state["hand"]
	var items: Array = state["hand_items"]
	var limit: int = state["hand_limit"]
	if hand.size() + items.size() >= limit:
		return
	var shop: Array = state["shop"]
	var may_buy: bool = CoreUtil.to_int(state.get("buys_left", -1)) != 0
	for index: int in shop.size():
		var unit: Dictionary = shop[index]
		if may_buy and CoreUtil.to_int(unit["cost"]) <= gold:
			out.append(_entry("buy", [index]))
	var spells: Array = state["shop_spells"]
	for index: int in spells.size():
		var spell: Dictionary = spells[index]
		if CoreUtil.to_int(spell["cost"]) <= gold:
			out.append(_entry("buy_spell", [index]))


static func _hand(state: Dictionary, out: Array[Dictionary]) -> void:
	var board: Array = state["board"]
	var hand: Array = state["hand"]
	for index: int in hand.size():
		for slot: int in BoardGeometry.SLOTS:
			if board[slot] == null:
				out.append(_entry("play", [index, slot]))
	var items: Array = state["hand_items"]
	for index: int in items.size():
		var item: Dictionary = items[index]
		if str(item["def_id"]) == "harvest_supper" and state.get("harvest_supper_used", false):
			continue
		_aimed(out, "play_item", [index], str(item["aim"]), state)
		if CoreUtil.to_int(item.get("gold_value", 0)) > 0:
			_onto_eaters(out, index, board)


## An Acorn item may also be played onto a unit that eats it.
static func _onto_eaters(out: Array[Dictionary], index: int, board: Array) -> void:
	for slot: int in BoardGeometry.SLOTS:
		if board[slot] != null:
			var unit: Dictionary = board[slot]
			if unit.get("eats_items", false):
				out.append(_entry("play_item", [index, slot]))


## Every legal target of an aim, as the last argument of the action. A shop aim gives a shop index.
static func _aimed(
	out: Array[Dictionary], action: String, first: Array, aim: String, state: Dictionary
) -> void:
	if aim == HandItem.AIM_NONE:
		out.append(_entry(action, first + [-1]))
		return
	if aim == HandItem.AIM_SHOP_UNIT:
		var shop: Array = state["shop"]
		for index: int in shop.size():
			out.append(_entry(action, first + [index]))
		return
	var board: Array = state["board"]
	for slot: int in BoardGeometry.SLOTS:
		if aim == HandItem.AIM_TRIBE_UNIT:
			if board[slot] != null:
				var unit: Dictionary = board[slot]
				if _tribe_can_grow(unit, state):
					out.append(_entry(action, first + [slot]))
		elif _slot_fits(aim, slot, board[slot] != null):
			out.append(_entry(action, first + [slot]))


static func _slot_fits(aim: String, slot: int, taken: bool) -> bool:
	match aim:
		HandItem.AIM_ANY_SLOT:
			return true
		HandItem.AIM_UNIT:
			return taken
		HandItem.AIM_EMPTY_SLOT:
			return not taken
		HandItem.AIM_FRONT_UNIT:
			return taken and BoardGeometry.is_front(slot)
		HandItem.AIM_BACK_UNIT:
			return taken and BoardGeometry.is_back(slot)
	return false


static func _board(state: Dictionary, out: Array[Dictionary]) -> void:
	var board: Array = state["board"]
	for slot: int in BoardGeometry.SLOTS:
		if board[slot] == null:
			continue
		out.append(_entry("sell", [slot]))
		for other: int in BoardGeometry.SLOTS:
			if other != slot:
				out.append(_entry("move", [slot, other]))


## Belly: anything that fits, into any Ooze with room. A shop unit also needs its price and a buy.
static func _swallows(state: Dictionary, out: Array[Dictionary]) -> void:
	var board: Array = state["board"]
	var gold: int = state["gold"]
	var may_buy: bool = CoreUtil.to_int(state.get("buys_left", -1)) != 0
	var shop: Array = state["shop"]
	var hand: Array = state["hand"]
	for slot: int in BoardGeometry.SLOTS:
		if board[slot] == null:
			continue
		var ooze: Dictionary = board[slot]
		var inside: Array = ooze.get("held", [])
		if CoreUtil.to_int(ooze.get("belly", 0)) <= inside.size():
			continue
		for index: int in shop.size():
			var unit: Dictionary = shop[index]
			var cost: int = CoreUtil.to_int(unit["cost"]) - CoreUtil.to_int(ooze["belly_discount"])
			if may_buy and maxi(0, cost) <= gold:
				out.append(_entry("swallow", [HeldUnits.SHOP, index, slot]))
		for index: int in hand.size():
			out.append(_entry("swallow", [HeldUnits.HAND, index, slot]))
		for other: int in BoardGeometry.SLOTS:
			if other != slot and board[other] != null:
				var unit: Dictionary = board[other]
				var holding: Array = unit.get("held", [])
				if holding.is_empty():
					out.append(_entry("swallow", [HeldUnits.BOARD, other, slot]))


static func _economy(state: Dictionary, out: Array[Dictionary]) -> void:
	var gold: int = state["gold"]
	if CoreUtil.to_int(state["refresh_cost"]) <= gold:
		out.append(_entry("refresh", []))
	if CoreUtil.to_int(state["freezes_left"]) > 0:
		out.append(_entry("toggle_freeze", []))
	if CoreUtil.to_int(state["tier"]) < UnitLibrary.TIERS:
		if CoreUtil.to_int(state["tier_up_cost"]) <= gold:
			out.append(_entry("tier_up", []))
	var hero: Variant = state["hero"]
	if hero == null:
		return
	var power: Dictionary = hero
	var active: bool = str(power["kind"]) == HeroRules.ACTIVATED
	if (
		active
		and CoreUtil.to_int(power["uses_left"]) > 0
		and CoreUtil.to_int(power["cost"]) <= gold
		and power.get("usable", true)
	):
		_aimed(out, "use_power", [], str(power["aim"]), state)


static func _tribe_can_grow(unit: Dictionary, state: Dictionary) -> bool:
	var bonuses: Dictionary = state.get("tribe_bonuses", {})
	for tribe: Variant in unit["tribes"]:
		if CoreUtil.to_int(bonuses.get(tribe, 0)) < TribeBonus.CAP:
			return true
	return false
