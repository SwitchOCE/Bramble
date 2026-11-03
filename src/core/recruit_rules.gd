class_name RecruitRules
extends RefCounted
## The Recruit Phase actions of rulebook chapters 3-7 on one PlayerState, shared by the human
## and the bots. Actions return "" on success, else a short reason the UI can show.

var library: UnitLibrary
var config: GameConfig
var pool: UnitPool
var _next_iid: int = 1


static func create(
	unit_library: UnitLibrary, game_config: GameConfig, unit_pool: UnitPool
) -> RecruitRules:
	var rules := RecruitRules.new()
	rules.library = unit_library
	rules.config = game_config
	rules.pool = unit_pool
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
	player.gold += config.get_int_at("income_by_turn", round_number - 1)
	if round_number >= 2 and player.tier < UnitLibrary.TIERS:
		var discount: int = config.get_int("upgrade_discount_per_turn")
		player.upgrade_cost = maxi(0, player.upgrade_cost - discount)
	player.paid_refreshes = 0
	player.freezes_left = config.get_int("freeze_toggles_per_turn")
	_fill_shop(player)
	player.frozen = false


## 3.4.1 end of the Recruit Phase: End of Turn effects on the board in reading order (step 1),
## then unfrozen shop cards return to the pool (5.3.2).
func end_phase(player: PlayerState) -> void:
	var clamp_at: int = config.get_int("stat_clamp")
	for unit: RecruitUnit in player.board:
		if unit == null:
			continue
		var entries: Array = unit.def["mechanics"]
		for entry: Dictionary in entries:
			var mechanic: Mechanic = MechanicRegistry.get_mechanic(str(entry["id"]))
			if mechanic != null:
				mechanic.on_end_of_turn(
					player, unit, MechanicRegistry.params_for(entry, unit.golden)
				)
		unit.attack = mini(unit.attack, clamp_at)
		unit.health = mini(unit.health, clamp_at)
	if not player.frozen:
		_return_shop(player)


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
	player.gold -= cost
	unit.origin = RecruitUnit.ORIGIN_BOUGHT
	player.hand.append(unit)
	return ""


## 4.3 sell a board unit.
func sell(player: PlayerState, slot: int) -> String:
	if not BoardGeometry.is_valid(slot) or player.board[slot] == null:
		return "No unit there"
	var unit: RecruitUnit = player.board[slot]
	player.board[slot] = null
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
	return ""


## 8.3.3 move into an empty slot, or swap two units. Free.
func move(player: PlayerState, from_slot: int, to_slot: int) -> String:
	if not BoardGeometry.is_valid(from_slot) or not BoardGeometry.is_valid(to_slot):
		return "No such slot"
	if player.board[from_slot] == null:
		return "No unit there"
	var other: RecruitUnit = player.board[to_slot]
	player.board[to_slot] = player.board[from_slot]
	player.board[from_slot] = other
	return ""


## 4.4 paid refresh.
func refresh(player: PlayerState) -> String:
	var cost: int = refresh_cost(player)
	if player.gold < cost:
		return "Not enough gold"
	player.gold -= cost
	player.paid_refreshes += 1
	_return_shop(player)
	player.frozen = false
	_fill_shop(player)
	return ""


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
	player.gold -= player.upgrade_cost
	player.tier += 1
	player.upgrade_cost = base_upgrade_cost(player.tier)
	return ""


## 5.3.8: all pool copies a player holds go back (board, hand and shop).
func return_everything(player: PlayerState) -> void:
	for unit: RecruitUnit in player.owned_units():
		pool.give_back(unit.def_id(), unit.pool_copies)
	_return_shop(player)
	player.hand.clear()
	for slot: int in BoardGeometry.SLOTS:
		player.board[slot] = null


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
