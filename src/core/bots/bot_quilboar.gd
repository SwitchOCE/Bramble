class_name BotQuilboar
extends RefCounted
## Test-only Choose One policy. All actions use RecruitRules; Created cards retain sell value 0.

const STRATEGY: String = "quilboar_choose_one"
const CURVE: Array[int] = [2, 4, 6, 9, 11]
const PRIORITY: Array[String] = [
	"qb_turbo_hogrider",
	"qb_bramble_tunneler",
	"qb_gem_rat",
	"qb_sanguine_refiner",
	"qb_thorned_trailblazer",
	"qb_trench_fighter",
	"qb_sanguine_champion",
	"qb_fearless_foodie",
	"qb_snare_trapper",
	"qb_sly_infiltrator",
	"qb_crater_miner",
	"qb_razorfen_geomancer"
]
const ENGINES: Array[String] = [
	"qb_turbo_hogrider", "qb_bramble_tunneler", "qb_gem_rat", "qb_sanguine_refiner"
]
const COPY_LIMITS: Dictionary = {
	"qb_bramble_tunneler": 3, "qb_gem_rat": 2, "qb_turbo_hogrider": 2, "qb_sanguine_refiner": 2
}
const CYCLE_IID: String = "reference_cycle_iid"
const GEM_INDEX: String = "reference_gem_index"
const CYCLE_COUNT: String = "qb_units_cycled"
const MAX_CYCLES: int = 4
const MAX_FLEX: int = 2


static func strategy() -> Dictionary:
	return {
		"id": STRATEGY,
		"tribes": {"quilboar": 4},
		"curve": CURVE,
		"needs_tribes": ["quilboar"],
		"pin_only": true
	}


static func active(brain: BotBrain) -> bool:
	return (
		str(brain.value.strategy.get("id", "")) == STRATEGY
		and brain._rules != null
		and ReferenceQuilboar.allowed(brain._rules.config)
	)


static func committed(brain: BotBrain) -> bool:
	return brain._round_now >= 6 or _has(brain._player, "qb_gem_rat", "qb_bramble_tunneler")


static func cycling(brain: BotBrain) -> bool:
	return (
		brain._round_now >= 8
		and brain._player.tier >= 3
		and _has(brain._player, "qb_turbo_hogrider", "qb_bramble_tunneler")
	)


static func play_turn(brain: BotBrain) -> void:
	brain._settle()
	brain._opening_plan = "economy"
	brain._open_with_a_plan()
	_cast_items(brain, false)
	_climb(brain)
	_play_hand(brain)
	for _step: int in BotBrain.MAX_STEPS:
		_cast_items(brain, false)
		var offer: int = _offer(brain)
		if offer >= 0:
			if brain._rules.buy(brain._player, offer) != "":
				break
			brain._settle()
			_play_hand(brain)
			continue
		var cost: int = brain._rules.refresh_cost(brain._player)
		var spare: int = brain._player.gold - _reserve(brain)
		if (
			_cycle_count(brain._player) >= MAX_CYCLES
			or spare < cost + brain._rules.unit_cost(brain._player)
		):
			break
		if brain._rules.refresh(brain._player) != "":
			break
		brain._settle()
	_shop_spells(brain)
	brain._maybe_power()
	_play_hand(brain)
	_cast_items(brain, true)
	_arrange(brain)
	_confiscate(brain)
	brain._settle()


static func _climb(brain: BotBrain) -> void:
	var player: PlayerState = brain._player
	for _step: int in UnitLibrary.TIERS:
		if player.tier >= UnitLibrary.TIERS or brain._round_now < CURVE[player.tier - 1]:
			return
		var cost: int = brain._rules.tier_up_cost(player)
		if player.board_count() == 0 and player.gold - cost < brain._rules.unit_cost(player):
			return
		if brain._rules.tier_up(player) != "":
			return
		brain._settle()


static func _reserve(brain: BotBrain) -> int:
	var player: PlayerState = brain._player
	if player.tier >= UnitLibrary.TIERS or brain._round_now + 1 < CURVE[player.tier - 1]:
		return 0
	var income: int = brain._rules.config.get_int_at("income_by_turn", brain._round_now)
	var discount: int = brain._rules.config.get_int("upgrade_discount_per_turn")
	return maxi(0, brain._rules.tier_up_cost(player) - discount - income - player.gold_next_turn)


static func _offer(brain: BotBrain) -> int:
	var best: int = -1
	var most: float = 0.0
	var player: PlayerState = brain._player
	if not brain._rules.has_hand_space(player):
		return -1
	for index: int in player.shop.size():
		var unit: RecruitUnit = player.shop[index]
		if _cycle_count(player) >= MAX_CYCLES and cycling(brain) and _choose_card(unit):
			continue
		if brain._rules.unit_cost(player, unit) > player.gold - _reserve(brain):
			continue
		var keep: bool = _wants_copy(brain, unit)
		var cycle: bool = (
			cycling(brain) and _cycle_count(player) < MAX_CYCLES and _choose_card(unit)
		)
		if not keep and not cycle:
			continue
		var score: float = _worth(brain, unit)
		var flex_full: bool = not unit.has_tribe("quilboar") and _flex_count(player) >= MAX_FLEX
		var weakest: int = _weakest_flex(player) if flex_full else _sell_slot(brain, not cycle)
		var full: bool = player.board_count() >= 7
		full = full or flex_full or (cycling(brain) and _keeper_count(player) >= 6)
		if full and not cycle:
			if weakest < 0:
				continue
			score -= _worth(brain, player.board[weakest])
		if cycle:
			score += 20.0
		if score > most:
			most = score
			best = index
	return best


static func _wants_copy(brain: BotBrain, unit: RecruitUnit) -> bool:
	var copies: int = BotEval.copies_of(brain._player, unit.def_id())
	var limit: int = CoreUtil.to_int(COPY_LIMITS.get(unit.def_id(), 1))
	if copies >= limit and copies != 2:
		return false
	if committed(brain) and not unit.has_tribe("quilboar"):
		return false
	return true


static func _worth(brain: BotBrain, unit: RecruitUnit) -> float:
	var total: float = unit.attack + unit.health
	var rank: int = PRIORITY.find(unit.def_id())
	if rank >= 0:
		total += (PRIORITY.size() - rank) * (14.0 if committed(brain) else 2.0)
	if unit.has_tribe("quilboar"):
		total += 4.0
	if ENGINES.has(unit.def_id()):
		total += 1000.0
	if unit.golden:
		total += 100.0
	return total


static func _sell_slot(brain: BotBrain, keep_cycle: bool = false) -> int:
	var player: PlayerState = brain._player
	var cycle_iid: int = CoreUtil.to_int(player.owner_counters.get(CYCLE_IID, -1))
	var flex: int = _weakest_flex(player)
	if flex >= 0:
		return flex
	var best: int = -1
	var least: float = INF
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit == null or ENGINES.has(unit.def_id()):
			continue
		if unit.iid == cycle_iid:
			if not keep_cycle:
				return slot
			continue
		var worth: float = _worth(brain, unit)
		if worth < least:
			least = worth
			best = slot
	return best


static func _play_hand(brain: BotBrain) -> void:
	var player: PlayerState = brain._player
	for _step: int in BotBrain.MAX_STEPS:
		if player.hand.is_empty():
			return
		var index: int = _hand_first(brain)
		if index < 0:
			return
		var unit: RecruitUnit = player.hand[index]
		var created: bool = unit.origin == RecruitUnit.ORIGIN_CREATED and _choose_card(unit)
		var cycle: bool = _is_cycle(brain, unit)
		var slot: int = player.first_empty_slot()
		var flex_full: bool = not unit.has_tribe("quilboar") and _flex_count(player) >= MAX_FLEX
		if slot < 0 or flex_full or (cycling(brain) and not cycle and _keeper_count(player) >= 6):
			slot = -1
			var replace: int = _weakest_flex(player) if flex_full else _sell_slot(brain, not cycle)
			if (
				replace >= 0
				and (cycle or _worth(brain, unit) > _worth(brain, player.board[replace]))
			):
				if brain._rules.sell(player, replace) == "":
					slot = replace
		if slot < 0 or brain._rules.play(player, index, slot) != "":
			return
		if cycle:
			player.owner_limits[CYCLE_COUNT] = _cycle_count(player) + 1
		brain._settle()
		_cast_items(brain, false)
		if cycle or created:
			player.owner_counters[CYCLE_IID] = unit.iid
		if created:
			brain._rules.sell(player, slot)
			brain._settle()


static func _hand_first(brain: BotBrain) -> int:
	var player: PlayerState = brain._player
	var order: Array[String] = ENGINES.duplicate()
	order.append_array(["qb_fearless_foodie", "qb_crater_miner"])
	for id: String in order:
		for index: int in player.hand.size():
			var unit: RecruitUnit = player.hand[index]
			if unit.def_id() == id and not _cycle_blocked(brain, unit):
				return index
	for index: int in player.hand.size():
		if not _cycle_blocked(brain, player.hand[index]):
			return index
	return -1


static func _cycle_count(player: PlayerState) -> int:
	return CoreUtil.to_int(player.owner_limits.get(CYCLE_COUNT, 0))


static func _is_cycle(brain: BotBrain, unit: RecruitUnit) -> bool:
	return _choose_card(unit) and (cycling(brain) or unit.origin == RecruitUnit.ORIGIN_CREATED)


static func _cycle_blocked(brain: BotBrain, unit: RecruitUnit) -> bool:
	return _is_cycle(brain, unit) and _cycle_count(brain._player) >= MAX_CYCLES


static func _prefer_unit_for_both(brain: BotBrain) -> bool:
	var player: PlayerState = brain._player
	if player.first_empty_slot() < 0 and _sell_slot(brain) < 0:
		return false
	var available: bool = false
	for unit: RecruitUnit in player.board:
		if unit != null and unit.def_id() == "qb_thorned_trailblazer":
			var budget: int = (
				CoreUtil.to_int(player.quilboar_ref["trailblazer_both_per_turn"])
				* unit.golden_factor()
			)
			available = available or CoreUtil.to_int(unit.limits.get("qb_both", 0)) < budget
	if not available:
		return false
	for unit: RecruitUnit in player.hand:
		if (
			unit.def_id() in ["qb_fearless_foodie", "qb_crater_miner"]
			and not _cycle_blocked(brain, unit)
		):
			return true
	return false


static func _flex_count(player: PlayerState) -> int:
	var count: int = 0
	for unit: RecruitUnit in player.board:
		if unit != null and not unit.has_tribe("quilboar"):
			count += 1
	return count


static func _weakest_flex(player: PlayerState) -> int:
	var slot: int = -1
	var least: int = 2147483647
	for index: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[index]
		if unit != null and not unit.has_tribe("quilboar") and unit.attack + unit.health < least:
			least = unit.attack + unit.health
			slot = index
	return slot


static func _cast_items(brain: BotBrain, last: bool) -> void:
	var player: PlayerState = brain._player
	# Give Trailblazer's scarce combined choice to Foodie, then Miner, before a Gem Day.
	if _prefer_unit_for_both(brain):
		return
	# Otherwise Gem Days precede created Choose One units and purchased cycling units.
	for _step: int in BotBrain.MAX_STEPS:
		var index: int = _item(player, "qb_gem_day")
		if index < 0 or brain._rules.play_item(player, index) != "":
			break
		brain._settle()
	for index: int in range(player.items.size() - 1, -1, -1):
		if index >= player.items.size():
			continue
		var item: HandItem = player.items[index]
		if item.def_id() == "qb_gem_confiscation":
			continue
		var target: int = brain._aim_for(item.aim(), item.def)
		if item.def_id() == "qb_blood_gem":
			if not last and not _has_keeper(player):
				continue
			target = _gem_target(player)
			if target < 0:
				continue
		elif BotEval.item_gold(item.def) > 0 or not brain._ready_to_cast(item):
			continue
		elif brain.value.has_flag(item.def_id(), "cast_last") and not last:
			continue
		brain._rules.play_item(player, index, target)
		brain._settle()


static func _gem_target(player: PlayerState) -> int:
	var keepers: Array[int] = []
	var carry: int = _carry(player)
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit != null and ENGINES.has(unit.def_id()) and slot != carry:
			keepers.append(slot)
	if keepers.is_empty():
		return carry
	var step: int = CoreUtil.to_int(player.owner_counters.get(GEM_INDEX, 0))
	player.owner_counters[GEM_INDEX] = step + 1
	if step % 2 == 0:
		return carry
	@warning_ignore("integer_division")
	var other: int = step / 2
	return keepers[other % keepers.size()]


static func _carry(player: PlayerState) -> int:
	var best: int = -1
	var most: int = -1
	var keeper_found: bool = false
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit == null:
			continue
		if unit.def_id() == "qb_gem_rat":
			return slot
		var keeper: bool = ENGINES.has(unit.def_id())
		if keeper_found and not keeper:
			continue
		if keeper and not keeper_found:
			most = -1
			keeper_found = true
		if unit.attack + unit.health > most:
			most = unit.attack + unit.health
			best = slot
	return best


static func _shop_spells(brain: BotBrain) -> void:
	var player: PlayerState = brain._player
	for index: int in range(player.shop_spells.size() - 1, -1, -1):
		var item: HandItem = player.shop_spells[index]
		var wanted: bool = (
			item.def_id() == "qb_gem_confiscation" and _count_item(player, item.def_id()) < 5
		)
		wanted = wanted or (item.def_id() == "harvest_supper" and brain._round_now in [7, 9, 11])
		if wanted and brain._rules.spell_cost(player, item) <= player.gold - _reserve(brain):
			brain._rules.buy_spell(player, index)
			brain._settle()


static func _arrange(brain: BotBrain) -> void:
	var player: PlayerState = brain._player
	var assignments: Array = [
		["qb_bramble_tunneler", 4],
		["qb_sanguine_refiner", 5],
		["qb_turbo_hogrider", 2],
		["qb_sanguine_champion", 3]
	]
	for pair: Array in assignments:
		for slot: int in BoardGeometry.SLOTS:
			if player.board[slot] != null and player.board[slot].def_id() == pair[0]:
				brain._rules.move(player, slot, CoreUtil.to_int(pair[1]))
				break
	var carry: int = _carry(player)
	if carry >= 0:
		brain._rules.move(player, carry, 0)
	brain._settle()


static func _confiscate(brain: BotBrain) -> void:
	var player: PlayerState = brain._player
	var index: int = _item(player, "qb_gem_confiscation")
	var carry: int = _carry(player)
	if index < 0 or carry < 0:
		return
	var alive: int = CoreUtil.to_int(player.owner_counters.get("reference_alive", 8))
	if alive <= 3 and not player.owner_counters.get("reference_stolen", false):
		brain._rules.move(player, carry, 1)
		var neighbours: Array[int] = []
		for slot: int in BoardGeometry.SLOTS:
			if slot != 1 and player.board[slot] != null:
				neighbours.append(slot)
		neighbours.sort_custom(
			func(a: int, b: int) -> bool:
				return (
					player.board[a].attack + player.board[a].health
					> player.board[b].attack + player.board[b].health
				)
		)
		if neighbours.size() >= 2:
			var first: RecruitUnit = player.board[neighbours[0]]
			var second: RecruitUnit = player.board[neighbours[1]]
			brain._rules.move(player, player.board.find(first), 0)
			brain._rules.move(player, player.board.find(second), 2)
		if brain._rules.play_item(player, index, 1) == "":
			player.owner_counters["reference_stolen"] = true
	elif player.gold > _reserve(brain) and player.board[0] != null and player.board[1] == null:
		brain._rules.play_item(player, index, 0)
	brain._settle()


static func mode(brain: BotBrain, choice: Dictionary) -> int:
	var card: Dictionary = choice.get("card_def", {})
	var id: String = str(choice.get("item_id", card.get("id", "")))
	if id == "":
		var iid: int = CoreUtil.to_int(choice.get("source_iid", -1))
		for unit: RecruitUnit in brain._player.board:
			if unit != null and unit.iid == iid:
				id = unit.def_id()
	var size: bool = (
		(brain._round_now >= 9 or _has(brain._player, "qb_turbo_hogrider"))
		and not brain._rules.config.get_bool("reference_quilboar_freeze_size")
	)
	match id:
		"qb_gem_day":
			return 0 if brain._player.gem_attack_halves <= brain._player.gem_health_halves else 1
		"qb_crater_miner":
			return 1 if size else 0
		"qb_fearless_foodie":
			return 0 if size else 1
		"qb_sly_infiltrator":
			for unit: RecruitUnit in brain._player.shop:
				if _choose_card(unit):
					return 1
			return 0 if cycling(brain) else 1
		"qb_snare_trapper":
			return 1
	return 0


static func _choose_card(unit: RecruitUnit) -> bool:
	var tags: Array = unit.def.get("tags", [])
	var modes: Array = unit.def.get("modes", [])
	return tags.has("choose_one") or not modes.is_empty()


static func _has_keeper(player: PlayerState) -> bool:
	for unit: RecruitUnit in player.board:
		if unit != null and ENGINES.has(unit.def_id()):
			return true
	return false


static func _keeper_count(player: PlayerState) -> int:
	var cycle_iid: int = CoreUtil.to_int(player.owner_counters.get(CYCLE_IID, -1))
	var count: int = 0
	for unit: RecruitUnit in player.board:
		if unit != null and unit.iid != cycle_iid:
			count += 1
	return count


static func _has(player: PlayerState, first: String, second: String = "") -> bool:
	for unit: RecruitUnit in player.board:
		if unit != null and (unit.def_id() == first or unit.def_id() == second):
			return true
	return false


static func _item(player: PlayerState, id: String) -> int:
	for index: int in player.items.size():
		if player.items[index].def_id() == id:
			return index
	return -1


static func _count_item(player: PlayerState, id: String) -> int:
	var count: int = 0
	for item: HandItem in player.items:
		if item.def_id() == id:
			count += 1
	return count
