class_name BotHedgerow
extends RefCounted
## The Supper holds food for the wake; the Parish compounds its smallest bodies.

const TRIBE: String = "Hedgerow folk"
const SUPPER_BUYS: Array[String] = [
	"alderman_dozey", "dr_urchin", "squire_lollop", "goodman_hayward"
]
const PARISH_ENGINES: Array[String] = [
	"mrs_mallow", "standing_committee", "squire_lollop", "goodman_hayward"
]


static func build(value: BotEval) -> bool:
	var tribes: Dictionary = value.strategy.get("tribes", {})
	return (
		value.level.reads_text
		and value.library != null
		and Pass3HedgerowText.is_native(value.library.get_unit("mr_crumb"))
		and BotEval._number(tribes.get(TRIBE, 0)) > 0.0
	)


static func active(player: PlayerState) -> bool:
	for unit: RecruitUnit in player.board:
		if unit != null and unit.has_mechanic_id("pass3_hedgerow"):
			return true
	return false


static func has(unit: RecruitUnit, ability: String) -> bool:
	return unit != null and Pass3Hedgerow.has(unit, ability)


static func parish(value: BotEval) -> bool:
	return str(value.strategy.get("id", "")).contains("parish")


static func treasury(value: BotEval) -> bool:
	return str(value.strategy.get("id", "")).contains("treasury")


static func holds(player: PlayerState, value: BotEval) -> bool:
	return build(value) and active(player) and not parish(value)


static func _rate(player: PlayerState, key: String, fallback: float) -> float:
	return CoreUtil.to_float(player.pass3_rates.get(key, fallback))


static func body(unit: RecruitUnit) -> int:
	return unit.attack + unit.health if unit != null else 0


static func find(player: PlayerState, ability: String) -> RecruitUnit:
	var best: RecruitUnit = null
	for unit: RecruitUnit in player.board:
		if has(unit, ability) and (best == null or body(unit) > body(best)):
			best = unit
	return best


static func ranked(player: PlayerState) -> Array[RecruitUnit]:
	return Pass3Hedgerow.ranked(player)


static func move_ready(player: PlayerState, unit: RecruitUnit) -> bool:
	if not has(unit, "alderman_dozey") or find(player, "dr_urchin") == null:
		return false
	if (
		CoreUtil.to_int(unit.counters.get("hedgerow_last_wake_round", -99))
		!= player.round_number - 1
	):
		return false
	var units: Array[RecruitUnit] = ranked(player)
	return not units.is_empty() and body(unit) >= 3 * body(units[int(units.size() / 2.0)])


static func clock_pinned(player: PlayerState, unit: RecruitUnit) -> bool:
	return (
		has(unit, "sleeping_partner")
		or (has(unit, "alderman_dozey") and not move_ready(player, unit))
	)


static func gap(player: PlayerState, value: BotEval) -> bool:
	if not build(value) or parish(value) or treasury(value):
		return false
	var dozey: RecruitUnit = find(player, "alderman_dozey")
	return dozey == null or (player.board.find(dozey) != 3 and not move_ready(player, dozey))


static func max_bodies(player: PlayerState, value: BotEval) -> int:
	return 6 if gap(player, value) else BoardGeometry.SLOTS


static func cash_purchase(player: PlayerState, value: BotEval, unit: RecruitUnit) -> bool:
	if not holds(player, value):
		return true
	if treasury(value):
		return (
			unit.def_id()
			in ["honorary_treasurer", "old_mother_mast", "goodman_hayward", "dr_urchin"]
		)
	return unit.def_id() in SUPPER_BUYS


static func wants_purchase(player: PlayerState, value: BotEval, unit: RecruitUnit) -> bool:
	if not build(value) or not unit.has_mechanic_id("pass3_hedgerow"):
		return true
	if not parish(value) and not treasury(value):
		if has(unit, "sleeping_partner") and player.round_number > 3:
			return BotEval.copies_of(player, unit.def_id()) >= 2
		if has(unit, "mr_pym") and player.round_number > 6:
			return BotEval.copies_of(player, unit.def_id()) >= 2
		if has(unit, "alderman_dozey") and BotEval.copies_of(player, unit.def_id()) >= 2:
			var carry: RecruitUnit = find(player, "alderman_dozey")
			return (
				carry == null
				or (
					CoreUtil.to_int(carry.counters.get("hedgerow_last_wake_round", -99))
					== player.round_number - 1
				)
			)
	return true


static func keep_engine(player: PlayerState, unit: RecruitUnit, value: BotEval) -> bool:
	if not build(value) or not unit.has_mechanic_id("pass3_hedgerow"):
		return false
	var id: String = unit.def_id()
	if parish(value):
		return id in PARISH_ENGINES
	if treasury(value):
		return id in ["honorary_treasurer", "old_mother_mast", "goodman_hayward", "dr_urchin"]
	if has(unit, "alderman_dozey") or id in ["squire_lollop", "goodman_hayward"]:
		return true
	# Only the useful route copy stays. Early feeders retire as their replacement arrives.
	if unit != find(player, id):
		return false
	if has(unit, "dr_urchin"):
		return find(player, "alderman_dozey") != null or player.round_number <= 7
	if has(unit, "sleeping_partner"):
		var period: int = maxi(1, int(_rate(player, "hedgerow_partner_period", 3)))
		return player.tier < 6 or unit.turns_in_slot % period != 0
	if has(unit, "mr_pym"):
		return player.tier < 4
	if has(unit, "mrs_sorrel"):
		return find(player, "old_mother_mast") == null and find(player, "goodman_hayward") == null
	if has(unit, "mrs_mallow"):
		return player.tier < 4
	if has(unit, "beadle_warrenby"):
		return find(player, "old_mother_mast") == null
	if has(unit, "old_mother_mast"):
		return player.larder() >= 5
	return id == "standing_committee"


static func text_value(unit: RecruitUnit, player: PlayerState, value: BotEval) -> float:
	if player == null or not unit.has_mechanic_id("pass3_hedgerow"):
		return -1.0
	var units: Array[RecruitUnit] = ranked(player)
	var smallest: int = body(units[0]) if not units.is_empty() else body(unit)
	var biggest: int = body(units[-1]) if not units.is_empty() else body(unit)
	var count: int = maxi(1, units.size())
	var factor: int = unit.golden_factor()
	var committed: bool = build(value)
	if has(unit, "mrs_mallow"):
		return (
			smallest
			* (_rate(player, "hedgerow_mallow_multiplier", 2) - 1.0)
			* _rate(player, "hedgerow_mallow_targets", 2)
			* factor
			* 2.0
		)
	if has(unit, "standing_committee"):
		return smallest * _rate(player, "hedgerow_committee_share", 0.25) * count * factor * 2.0
	if has(unit, "squire_lollop"):
		return (
			biggest
			* _rate(player, "hedgerow_lollop_share", 0.1)
			* maxi(0, count - 1)
			* factor
			* 2.0
		)
	if has(unit, "alderman_dozey"):
		return (
			(
				body(unit) * 0.8
				+ 2.0 * player.larder() * _rate(player, "hedgerow_dozey_food_per_gold", 2)
			)
			if committed and not parish(value) and not treasury(value)
			else 0.0
		)
	if has(unit, "honorary_treasurer"):
		return player.larder() * 2.0 * _rate(player, "hedgerow_treasurer_per_gold", 1) * factor
	if has(unit, "goodman_hayward"):
		return (
			maxf(4.0, player.larder() * 2.0)
			* count
			* _rate(player, "hedgerow_hayward_per_gold", 1)
			* factor
		)
	if has(unit, "dr_urchin"):
		return biggest * 0.35 * factor
	if has(unit, "sleeping_partner"):
		return count * _rate(player, "hedgerow_partner_acorns", 2) * BotEval.GOLD_POINTS * factor
	if has(unit, "old_mother_mast"):
		return minf(5.0, player.larder() / 5.0) * BotEval.GOLD_POINTS * factor * 2.0
	if has(unit, "mrs_clover"):
		return (
			body(unit) * _rate(player, "hedgerow_clover_share", 1) * factor
			if parish(value)
			else 2.0
		)
	if has(unit, "mr_crumb"):
		return body(unit) * _rate(player, "hedgerow_crumb_sell_share", 1) * factor
	if has(unit, "beadle_warrenby"):
		return count * 2.0 * _rate(player, "hedgerow_beadle_pass", 2) * factor
	return (8.0 if committed else 3.0) * factor


static func prepare(brain: BotBrain) -> void:
	if not build(brain.value) or not active(brain._player):
		return
	if parish(brain.value):
		cash_all(brain)
		_sell_runt(brain)
	elif (
		treasury(brain.value)
		and brain._player.round_number >= 13
		and find(brain._player, "goodman_hayward") != null
	):
		if not brain._player.has_meta("hedgerow_cashed_out"):
			cash_all(brain)
			brain._player.set_meta("hedgerow_cashed_out", true)


static func cash_all(brain: BotBrain) -> void:
	for _step: int in brain._player.items.size():
		var indexes: Array[int] = brain._items_by_gold()
		if indexes.is_empty():
			return
		if brain._rules.play_item(brain._player, indexes[0], -1) != "":
			return
		brain._settle()


static func feed(brain: BotBrain) -> bool:
	if not build(brain.value) or not active(brain._player):
		return false
	if parish(brain.value):
		cash_all(brain)
		return true
	if treasury(brain.value):
		return true
	var carry: RecruitUnit = find(brain._player, "alderman_dozey")
	if carry == null or not Pass3Hedgerow.wake_due(carry, brain._player):
		return true
	var slot: int = brain._player.board.find(carry)
	for _step: int in brain._player.items.size():
		var indexes: Array[int] = brain._items_by_gold()
		if indexes.is_empty():
			break
		if brain._rules.play_item(brain._player, indexes[-1], slot) != "":
			break
		brain._settle()
	return true


static func _sell_runt(brain: BotBrain) -> void:
	var player: PlayerState = brain._player
	if find(player, "standing_committee") == null:
		return
	var units: Array[RecruitUnit] = ranked(player)
	var sizes: Dictionary = {}
	var due: Dictionary = {}
	for unit: RecruitUnit in units:
		sizes[unit.iid] = body(unit)
	# Two Mallows may choose the same tiny Kit again, rather than four different runts.
	for source: RecruitUnit in player.board:
		if not has(source, "mrs_mallow"):
			continue
		units.sort_custom(
			func(a: RecruitUnit, b: RecruitUnit) -> bool:
				if sizes[a.iid] == sizes[b.iid]:
					return (
						BoardGeometry.ZIGZAG.find(player.board.find(a))
						< BoardGeometry.ZIGZAG.find(player.board.find(b))
					)
				return sizes[a.iid] < sizes[b.iid]
		)
		var entry: Dictionary = Pass3Hedgerow.params(source, "mrs_mallow")
		var count: int = (
			CoreUtil.to_int(entry.get("targets", 2)) * CoreUtil.to_int(entry.get("factor", 1))
		)
		for index: int in mini(count, units.size()):
			var unit: RecruitUnit = units[index]
			due[unit.iid] = true
			sizes[unit.iid] = sizes[unit.iid] * CoreUtil.to_float(entry.get("multiplier", 2))
	for unit: RecruitUnit in units:
		if unit.def_id() == "kit" and not due.has(unit.iid):
			brain._rules.sell(player, player.board.find(unit))
			brain._settle()


static func hold_hand(brain: BotBrain, unit: RecruitUnit) -> bool:
	if not build(brain.value):
		return false
	if unit.def_id() in PARISH_ENGINES and find(brain._player, unit.def_id()) != null:
		if brain._room_left() <= 0 and brain._best_replacement_slot(unit) < 0:
			return true
	if parish(brain.value) or not has(unit, "alderman_dozey"):
		return false
	if find(brain._player, "alderman_dozey") == null:
		return false
	for slot: int in BoardGeometry.BACK:
		if brain._player.board[slot] == null:
			return false
	return true


## Put the new carry down before selling Crumb, so the real sold Pass reaches him.
static func prepare_play(brain: BotBrain, unit: RecruitUnit) -> void:
	var player: PlayerState = brain._player
	if not build(brain.value) or parish(brain.value) or not has(unit, "alderman_dozey"):
		return
	if find(player, "alderman_dozey") != null or not has(player.board[6], "mr_crumb"):
		return
	var destination: int = -1
	for slot: int in [0, 1, 2, 4, 5]:
		if player.board[slot] == null:
			destination = slot
			break
	if destination < 0:
		var weakest: int = brain._weakest_slot()
		if weakest >= 0 and not has(player.board[weakest], "mr_crumb"):
			destination = brain._sell_replacement(weakest)
	if destination >= 0:
		brain._rules.move(player, 6, destination)
		brain._settle()


static func after_play(brain: BotBrain) -> void:
	if not build(brain.value) or parish(brain.value):
		return
	var carry: RecruitUnit = find(brain._player, "alderman_dozey")
	var crumb: RecruitUnit = find(brain._player, "mr_crumb")
	if carry != null and crumb != null and body(crumb) >= body(carry) * 0.2:
		brain._rules.sell(brain._player, brain._player.board.find(crumb))
		brain._settle()


static func play_slot(player: PlayerState, unit: RecruitUnit, value: BotEval) -> int:
	var order: Array[int] = BoardGeometry.ZIGZAG.duplicate()
	if has(unit, "sleeping_partner"):
		order = [4, 0, 1, 5, 2, 6]
	elif has(unit, "alderman_dozey") or (has(unit, "mr_crumb") and not parish(value)):
		order = [6, 5, 4, 2, 1, 0]
	elif has(unit, "mrs_sorrel") and not parish(value):
		order = [5, 4, 0, 1, 2, 6]
	elif has(unit, "dr_urchin"):
		order = [5, 4, 1, 0, 2, 6, 3]
	for slot: int in order:
		if (
			player.board[slot] == null
			and (slot != 3 or not gap(player, value) or has(unit, "alderman_dozey"))
		):
			return slot
	return -1


static func arrange(
	player: PlayerState, value: BotEval, layout: Array[int], pinned: Array[int]
) -> void:
	if not build(value):
		return
	var assigned: Array[int] = []
	layout.fill(-1)
	for slot: int in pinned:
		if player.board[slot] != null:
			layout[slot] = slot
			assigned.append(slot)
	var carry: RecruitUnit = find(player, "alderman_dozey")
	var destinations: Array[int] = BoardGeometry.ZIGZAG.duplicate()
	if parish(value):
		destinations = destinations.slice(0, player.board_count())
		for slot: int in pinned:
			if not destinations.has(slot):
				destinations.append(slot)
		var units: Array[RecruitUnit] = ranked(player)
		if not units.is_empty():
			_place_in_layout(layout, assigned, player.board.find(units[-1]), destinations[-1])
	elif treasury(value):
		_place_in_layout(layout, assigned, _source(player, "honorary_treasurer"), 3)
	elif carry != null:
		_place_in_layout(
			layout,
			assigned,
			player.board.find(carry),
			3 if move_ready(player, carry) or player.board.find(carry) == 3 else 6
		)
	else:
		_place_in_layout(layout, assigned, _source(player, "mr_crumb"), 6)
	_place_in_layout(layout, assigned, _source(player, "sleeping_partner"), 4)
	if not parish(value) or destinations.has(5):
		_place_in_layout(layout, assigned, _source(player, "dr_urchin"), 5)
	if not parish(value):
		_place_in_layout(layout, assigned, _source(player, "mrs_sorrel"), 5)
	if gap(player, value):
		destinations.erase(3)
	for source: int in BoardGeometry.SLOTS:
		if player.board[source] == null or assigned.has(source):
			continue
		for destination: int in destinations:
			if layout[destination] < 0:
				_place_in_layout(layout, assigned, source, destination)
				break
	# An off-route seventh body still needs a legal destination until an actual sale replaces it.
	for source: int in BoardGeometry.SLOTS:
		if player.board[source] != null and not assigned.has(source):
			for destination: int in BoardGeometry.ZIGZAG:
				if layout[destination] < 0:
					_place_in_layout(layout, assigned, source, destination)
					break


static func _place_in_layout(
	layout: Array[int], assigned: Array[int], source: int, destination: int
) -> void:
	if source >= 0 and not assigned.has(source) and layout[destination] < 0:
		layout[destination] = source
		assigned.append(source)


static func search_pins(player: PlayerState, value: BotEval, layout: Array[int]) -> Array[int]:
	var out: Array[int] = []
	if build(value) and player.round_number >= 4 and player.board_count() >= 3:
		for slot: int in BoardGeometry.SLOTS:
			if layout[slot] >= 0:
				out.append(slot)
	return out


static func aim(
	player: PlayerState, value: BotEval, legal: Array[int], card_def: Dictionary = {}
) -> int:
	if (
		str(card_def.get("aim", ""))
		not in [
			HandItem.AIM_UNIT,
			HandItem.AIM_TRIBE_UNIT,
			HandItem.AIM_FRONT_UNIT,
			HandItem.AIM_BACK_UNIT
		]
	):
		return -1
	if not build(value) or not active(player):
		return -1
	if parish(value):
		for unit: RecruitUnit in ranked(player):
			var slot: int = player.board.find(unit)
			if legal.has(slot):
				return slot
	var carry: RecruitUnit = find(
		player, "honorary_treasurer" if treasury(value) else "alderman_dozey"
	)
	return player.board.find(carry) if carry != null and legal.has(player.board.find(carry)) else -1


static func _source(player: PlayerState, ability: String) -> int:
	var unit: RecruitUnit = find(player, ability)
	return player.board.find(unit) if unit != null else -1


static func offer_cash(brain: BotBrain, offer: Dictionary) -> bool:
	if not holds(brain._player, brain.value):
		return true
	if CoreUtil.to_bool(offer.get("spell", false)):
		return false
	return cash_purchase(
		brain._player, brain.value, brain._player.shop[CoreUtil.to_int(offer["index"])]
	)


## Legacy eaters retain their existing policy when the native Long Sleep route is absent.
static func feed_eaters(brain: BotBrain) -> void:
	if feed(brain) or not brain.level.reads_text:
		return
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = brain._player.board[slot]
		if unit == null or unit.eat_rate() <= 0 or not unit.can_gain_permanent():
			continue
		var goal: int = CoreUtil.to_int(unit.def.get("turns_goal", 0))
		if goal > 0 and unit.turns_in_slot < goal - 1:
			continue
		if goal > 0 and unit.turns_in_slot >= goal and brain._hold_value(1) > 0.0:
			continue
		for _step: int in brain._player.items.size():
			if not unit.can_gain_permanent():
				break
			var indexes: Array[int] = brain._items_by_gold()
			if indexes.is_empty():
				return
			if brain._rules.play_item(brain._player, indexes[-1], slot) != "":
				return


static func item_indexes(player: PlayerState) -> Array[int]:
	var out: Array[int] = []
	for index: int in player.items.size():
		if BotEval.item_gold(player.items[index].def) > 0:
			out.append(index)
	out.sort_custom(
		func(a: int, b: int) -> bool:
			return BotEval.item_gold(player.items[a].def) < BotEval.item_gold(player.items[b].def)
	)
	return out


static func hold_value(brain: BotBrain, gold: int) -> float:
	var per_gold: float = BotEval._number(brain.value.strategy.get("larder_value", 0.0))
	for unit: RecruitUnit in brain._player.board:
		if unit != null:
			per_gold += BotEval._number(
				brain.knowledge.card(unit.def_id()).get("larder_value", 0.0)
			)
	return gold * per_gold


static func purchase_gain(brain: BotBrain, unit: RecruitUnit, ordinary: float) -> float:
	if not build(brain.value) or not unit.has_mechanic_id("pass3_hedgerow"):
		return ordinary
	var buys_copy: bool = (
		has(unit, "squire_lollop") or (parish(brain.value) and unit.def_id() in PARISH_ENGINES)
	)
	if buys_copy and (has(unit, "squire_lollop") or find(brain._player, unit.def_id()) != null):
		return maxf(
			ordinary, brain.value.buy_value(unit, brain._player, brain._unit_offer_cost(unit))
		)
	return ordinary


## Food held for a wake cannot back an ordinary refresh or consume the next climb's gold.
static func refresh_budget(brain: BotBrain, cost: int) -> int:
	var player: PlayerState = brain._player
	var cash: int = player.gold + (0 if holds(player, brain.value) else player.larder())
	return cash - cost - brain._held_back()
