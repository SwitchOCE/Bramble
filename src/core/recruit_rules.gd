# gdlint:disable=max-public-methods
# One public method per rule or action of chapters 3-8; splitting them would hide the list.
class_name RecruitRules
extends RefCounted
## The Recruit Phase actions of rulebook chapters 3-7 on one PlayerState, shared by the human
## and the bots. Actions return "" on success, else a short reason the UI can show. Every trigger
## goes through `events`, every change of gold through spend() or give_gold().

var library: UnitLibrary
var config: GameConfig
var pool: UnitPool
var events: RecruitEvents
var _next_iid: int = 1


static func create(
	unit_library: UnitLibrary, game_config: GameConfig, unit_pool: UnitPool
) -> RecruitRules:
	var rules := RecruitRules.new()
	rules.library = unit_library
	rules.config = game_config
	rules.pool = unit_pool
	rules.events = RecruitEvents.create(rules)
	return rules


## A fresh instance id for the game (6.2 iid).
func new_iid() -> int:
	_next_iid += 1
	return _next_iid - 1


func setup_player(player: PlayerState) -> void:
	player.health = config.get_int("starting_health")
	player.tier = 1
	player.gold = 0
	player.upgrade_cost = base_upgrade_cost(1)
	player.freezes_left = config.get_int("freeze_toggles_per_turn")


## 4.6.2: the base cost to upgrade from `tier` to the next; -1 at the top tier.
func base_upgrade_cost(tier: int) -> int:
	if tier >= UnitLibrary.TIERS:
		return -1
	return config.get_int_at("upgrade_costs", tier - 1)


## 6.1.1 units column.
func shop_size(tier: int) -> int:
	return config.get_int_at("shop_units_by_tier", tier - 1)


## 4.4.2-4.4.3: the cost of the next paid refresh.
func refresh_cost(player: PlayerState) -> int:
	var base: int = config.get_int("refresh_base_cost")
	var first_step: int = config.get_int("refresh_first_step_after")
	var step: int = maxi(1, config.get_int("refresh_step_length"))
	if player.paid_refreshes < first_step:
		return base
	@warning_ignore("integer_division")
	var steps: int = 1 + (player.paid_refreshes - first_step) / step
	return base + steps


## 3.2.1 start of the Recruit Phase on turn `round`.
func start_phase(player: PlayerState, round_number: int) -> void:
	player.round_number = round_number
	player.recruit_log.clear()
	player.gold += config.get_int_at("income_by_turn", round_number - 1) + player.gold_next_turn
	player.gold_next_turn = 0
	player.gold_spent_turn = 0
	if round_number >= 2 and player.tier < UnitLibrary.TIERS:
		var discount: int = config.get_int("upgrade_discount_per_turn")
		player.upgrade_cost = maxi(0, player.upgrade_cost - discount)
	player.paid_refreshes = 0
	player.freezes_left = config.get_int("freeze_toggles_per_turn")
	_reset_limits(player)
	_fill_shop(player)
	player.frozen = false
	events.fire(player, "start_of_turn")


## 3.4.1 end of the Recruit Phase: End of Turn effects on the board in reading order (step 1),
## then unfrozen shop cards return to the pool (5.3.2).
func end_phase(player: PlayerState) -> void:
	events.fire(player, "end_of_turn")
	if not player.frozen:
		_return_shop(player)


## After the round's fights (12.1.1): "next combat" buffs and combat-only keywords end, then
## "after combat" effects run.
func after_fights(player: PlayerState) -> void:
	for unit: RecruitUnit in player.owned_units():
		unit.clear_combat_layer()
	events.fire(player, "after_combat")


## Takes gold for an action the caller has checked it can afford (4.1.5).
func spend(player: PlayerState, cost: int) -> void:
	player.gold -= cost
	player.gold_spent_turn += cost
	player.gold_spent_game += cost
	if cost > 0:
		events.fire(player, "on_gold_spent", {"amount": cost})


## Gold from an effect: "now", or "next_turn" (it arrives in the next start-of-turn step 1).
func give_gold(player: PlayerState, amount: int, when: String = "now") -> void:
	if when == "next_turn":
		player.gold_next_turn += amount
	else:
		player.gold = maxi(0, player.gold + amount)
	player.log_event("gold", {"amount": amount, "when": when})


## 4.2 buy a shop unit into hand.
func buy(player: PlayerState, shop_index: int) -> String:
	if shop_index < 0 or shop_index >= player.shop.size():
		return "No unit there"
	var cost: int = config.get_int("unit_cost")
	if player.gold < cost:
		return "Not enough gold"
	if player.hand.size() >= config.get_int("hand_limit"):
		return "Hand is full"
	var unit: RecruitUnit = player.shop[shop_index]
	player.shop.remove_at(shop_index)
	unit.origin = RecruitUnit.ORIGIN_BOUGHT
	player.hand.append(unit)
	spend(player, cost)
	events.fire(player, "on_buy", {"subject": unit})
	check_triples(player)
	return ""


## 4.3 sell a board unit.
func sell(player: PlayerState, slot: int) -> String:
	if not BoardGeometry.is_valid(slot) or player.board[slot] == null:
		return "No unit there"
	var unit: RecruitUnit = player.board[slot]
	events.fire(player, "on_sell", {"subject": unit})
	var now_at: int = player.board.find(unit)
	if now_at < 0:
		return ""
	player.board[now_at] = null
	player.gold += sell_value(unit)
	pool.give_back(unit.def_id(), unit.pool_copies)
	return ""


## 4.3.3-4.3.4.
func sell_value(unit: RecruitUnit) -> int:
	if unit.from_triple or unit.origin == RecruitUnit.ORIGIN_BOUGHT:
		return config.get_int("sell_bought")
	return config.get_int("sell_created")


## 7.2 play a hand unit into an empty slot.
func play(player: PlayerState, hand_index: int, slot: int) -> String:
	if hand_index < 0 or hand_index >= player.hand.size():
		return "No unit there"
	if not BoardGeometry.is_valid(slot):
		return "No such slot"
	if player.board[slot] != null:
		return "That slot is taken"
	var unit: RecruitUnit = player.hand[hand_index]
	player.hand.remove_at(hand_index)
	player.board[slot] = unit
	player.log_event("play", {"unit": unit.def_id(), "slot": slot})
	if unit.reward_pending:
		unit.reward_pending = false
		_triple_reward(player)
	events.fire(player, "on_play", {"subject": unit})
	return ""


## 8.3.3 move into an empty slot, or swap two units. Free.
func move(player: PlayerState, from_slot: int, to_slot: int) -> String:
	if not BoardGeometry.is_valid(from_slot) or not BoardGeometry.is_valid(to_slot):
		return "No such slot"
	if player.board[from_slot] == null:
		return "No unit there"
	move_on_board(player, from_slot, to_slot)
	return ""


## 8.3.3: the move itself, also used by mechanics. False if nothing moved.
func move_on_board(player: PlayerState, from_slot: int, to_slot: int) -> bool:
	var unit: RecruitUnit = player.board[from_slot]
	if unit == null or from_slot == to_slot:
		return false
	player.board[from_slot] = player.board[to_slot]
	player.board[to_slot] = unit
	player.log_event("move", {"unit": unit.def_id(), "from": from_slot, "to": to_slot})
	events.fire(player, "on_move", {"subject": unit, "amount": from_slot})
	return true


## 4.4 refresh: a free refresh is used first (4.4.5), else gold.
func refresh(player: PlayerState) -> String:
	if player.free_refreshes > 0:
		player.free_refreshes -= 1
		replace_shop(player, false)
		return ""
	var cost: int = refresh_cost(player)
	if player.gold < cost:
		return "Not enough gold"
	player.paid_refreshes += 1
	spend(player, cost)
	replace_shop(player, true)
	return ""


## 4.4.6: the shop's cards are replaced, frozen or not. Costs nothing and counts toward nothing.
func replace_shop(player: PlayerState, paid: bool = false) -> void:
	_return_shop(player)
	player.frozen = false
	_fill_shop(player)
	events.fire(player, "on_refresh", {"paid": paid})


## 4.5.1 freeze toggles.
func toggle_freeze(player: PlayerState) -> String:
	if player.freezes_left <= 0:
		return "No freezes left this turn"
	player.frozen = not player.frozen
	player.freezes_left -= 1
	return ""


## 4.6 upgrade the tier. No shop refill (4.6.5).
func tier_up(player: PlayerState) -> String:
	if player.tier >= UnitLibrary.TIERS:
		return "Already at the top tier"
	if player.gold < player.upgrade_cost:
		return "Not enough gold"
	var cost: int = player.upgrade_cost
	player.tier += 1
	player.upgrade_cost = base_upgrade_cost(player.tier)
	spend(player, cost)
	events.fire(player, "on_tier_up")
	return ""


## 7.3.1: any three non-golden copies of a unit across board and hand combine at once. Call it
## whenever a unit reaches the hand or board in the Recruit Phase (7.3.2).
func check_triples(player: PlayerState) -> void:
	var found: bool = true
	while found:
		found = false
		var groups: Dictionary = {}
		for unit: RecruitUnit in player.owned_units():
			if unit.golden:
				continue
			var copies: Array = groups.get(unit.def_id(), [])
			copies.append(unit)
			groups[unit.def_id()] = copies
			if copies.size() >= 3:
				_combine(player, copies)
				found = true
				break


## 7.3.4: double base stats plus every copy's buffs and debuffs, summed from their layers, each
## stat at least the golden base. 7.3.7: on a full hand the golden takes the first vacated slot.
## 5.3.5: it holds the copies' pool copies.
func _combine(player: PlayerState, copies: Array) -> void:
	var first: RecruitUnit = copies[0]
	var golden := RecruitUnit.make(first.def, new_iid(), true)
	var vacated: Array[int] = []
	var any_bought: bool = false
	for entry: Variant in copies:
		var copy: RecruitUnit = entry
		golden.add_permanent(copy.perm_attack, copy.perm_health)
		golden.add_combat(copy.combat_attack, copy.combat_health)
		golden.pool_copies += copy.pool_copies
		any_bought = any_bought or copy.origin == RecruitUnit.ORIGIN_BOUGHT
		var slot: int = player.board.find(copy)
		if slot >= 0:
			player.board[slot] = null
			vacated.append(slot)
		else:
			player.hand.erase(copy)
	golden.perm_attack = maxi(0, golden.perm_attack)
	golden.perm_health = maxi(0, golden.perm_health)
	golden.origin = RecruitUnit.ORIGIN_BOUGHT if any_bought else RecruitUnit.ORIGIN_CREATED
	golden.from_triple = true
	golden.reward_pending = true
	if player.hand.size() < config.get_int("hand_limit") or vacated.is_empty():
		player.hand.append(golden)
	else:
		vacated.sort()
		player.board[vacated[0]] = golden
	player.log_event("triple", {"unit": golden.def_id()})
	events.fire(player, "on_triple", {"subject": golden})


## 7.3.6 as simplified in SPEC 9: a random pool unit of the tier above the player's (6 at 6)
## goes to hand, Created (4.3.2). Lost on a full hand (7.1.2), its copy back in the pool.
func _triple_reward(player: PlayerState) -> void:
	var tier: int = mini(player.tier + 1, UnitLibrary.TIERS)
	var def_id: String = pool.draw(tier, player.shop_rng, tier)
	if def_id == "":
		return
	if player.hand.size() >= config.get_int("hand_limit"):
		pool.give_back(def_id)
		return
	var unit := RecruitUnit.make(library.get_unit(def_id), new_iid())
	unit.origin = RecruitUnit.ORIGIN_CREATED
	unit.pool_copies = 1
	player.hand.append(unit)
	check_triples(player)


## 8.4: summons onto the recruit board, next to `source_slot` (-1 for no slot, 8.4.3). All of
## them arrive before a triple can form (7.3.2). A full board loses the rest (8.4.5). Created.
func summon_units(
	player: PlayerState, def_id: String, count: int, golden: bool, source_slot: int
) -> void:
	var unit_def: Dictionary = library.get_unit(def_id)
	if unit_def.is_empty():
		push_error("Summon of an unknown unit '%s'" % def_id)
		return
	var arrived: Array[RecruitUnit] = []
	for _index: int in count:
		var occupied: Array[bool] = []
		for unit: RecruitUnit in player.board:
			occupied.append(unit != null)
		var slot: int = BoardGeometry.summon_slot(occupied, source_slot, false)
		if slot < 0:
			break
		var unit := RecruitUnit.make(unit_def, new_iid(), golden)
		unit.origin = RecruitUnit.ORIGIN_CREATED
		player.board[slot] = unit
		arrived.append(unit)
		player.log_event("summon", {"unit": def_id, "slot": slot})
	for unit: RecruitUnit in arrived:
		events.fire(player, "on_summon", {"subject": unit})
	check_triples(player)


## Gives a player a card by id: a unit into hand, Created; with `from_pool` it takes a real copy
## and returns nothing if none is left (4.3.2). Lost on a full hand (7.1.2).
func give_card(player: PlayerState, card: String, from_pool: bool = false) -> void:
	var unit_def: Dictionary = library.get_unit(card)
	if unit_def.is_empty():
		push_error("Unknown card '%s'" % card)
		return
	if from_pool and not pool.take(card):
		return
	if not has_hand_space(player):
		if from_pool:
			pool.give_back(card)
		return
	var unit := RecruitUnit.make(unit_def, new_iid())
	unit.origin = RecruitUnit.ORIGIN_CREATED
	unit.pool_copies = 1 if from_pool else 0
	player.hand.append(unit)
	player.log_event("card", {"card": card})
	check_triples(player)


## 7.1.1: the hand holds up to the limit, counting every card in it.
func has_hand_space(player: PlayerState) -> bool:
	return player.hand.size() < config.get_int("hand_limit")


## Damage in the Recruit Phase is permanent. At 0 Health the unit is destroyed and its copies go
## back (5.3.7).
func damage_unit(player: PlayerState, unit: RecruitUnit, amount: int) -> void:
	unit.add_permanent(0, -amount)
	player.log_event("damage", {"target": unit.def_id(), "amount": amount})
	if unit.health > 0:
		return
	var slot: int = player.board.find(unit)
	if slot >= 0:
		player.board[slot] = null
		pool.give_back(unit.def_id(), unit.pool_copies)
		player.log_event("destroyed", {"target": unit.def_id(), "slot": slot})


## Applies what a fight sent back (12.1.1 "permanently"; gold and cards earned in combat).
func apply_carry(player: PlayerState, change: Dictionary) -> void:
	match str(change.get("op", "")):
		"buff":
			var unit: RecruitUnit = _unit_by_iid(player, CoreUtil.to_int(change["iid"]))
			if unit != null:
				unit.add_permanent(
					CoreUtil.to_int(change["attack"]), CoreUtil.to_int(change["health"])
				)
		"grant":
			var target: RecruitUnit = _unit_by_iid(player, CoreUtil.to_int(change["iid"]))
			if target != null:
				(
					target
					. grants
					. append(
						{
							"entry": change["entry"],
							"golden": change["golden"],
							"keyword": change["keyword"],
							"combat_only": false,
						}
					)
				)
		"gold_next_turn":
			player.gold_next_turn += CoreUtil.to_int(change["amount"])
		"add_card":
			for _index: int in CoreUtil.to_int(change["count"]):
				give_card(player, str(change["card"]), CoreUtil.to_bool(change["from_pool"]))


## 5.3.8: all pool copies a player holds go back (board, hand and shop).
func return_everything(player: PlayerState) -> void:
	for unit: RecruitUnit in player.owned_units():
		pool.give_back(unit.def_id(), unit.pool_copies)
	_return_shop(player)
	player.hand.clear()
	for slot: int in BoardGeometry.SLOTS:
		player.board[slot] = null


static func _unit_by_iid(player: PlayerState, iid: int) -> RecruitUnit:
	for unit: RecruitUnit in player.owned_units():
		if unit.iid == iid:
			return unit
	return null


## "limit" counts start over each turn.
static func _reset_limits(player: PlayerState) -> void:
	for unit: RecruitUnit in player.owned_units():
		unit.limits.clear()
	player.owner_limits.clear()


## 4.5.2: fill the shop's empty slots up to its size (a frozen shop keeps its cards).
func _fill_shop(player: PlayerState) -> void:
	var size: int = shop_size(player.tier)
	while player.shop.size() < size:
		var def_id: String = pool.draw(player.tier, player.shop_rng)
		if def_id == "":
			return
		var unit := RecruitUnit.make(library.get_unit(def_id), new_iid())
		unit.pool_copies = 1
		player.shop.append(unit)


## 5.3.2: shown cards return to the pool.
func _return_shop(player: PlayerState) -> void:
	for unit: RecruitUnit in player.shop:
		pool.give_back(unit.def_id(), unit.pool_copies)
	player.shop.clear()
