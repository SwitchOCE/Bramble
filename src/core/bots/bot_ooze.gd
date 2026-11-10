class_name BotOoze
extends RefCounted
## Food is a permanent investment; engine pieces are bodies, not spare Belly reserves.

const ENGINES: Array[String] = [
	"stone_soup", "dishwater_nell", "aunt_aspic", "elder_ooze", "cut_and_come_again"
]


static func active(player: PlayerState) -> bool:
	if player == null:
		return false
	for unit: RecruitUnit in player.board:
		if unit != null and unit.has_mechanic_id("pass3_ooze"):
			return true
	return false


static func build(value: BotEval) -> bool:
	var tribes: Dictionary = value.strategy.get("tribes", {})
	return BotEval._number(tribes.get("Oozes", 0)) > 0.0


static func tempo(value: BotEval) -> bool:
	var id: String = str(value.strategy.get("id", ""))
	return id in ["oozes_second_helpings", "line_oozes_tempo"]


static func has(unit: RecruitUnit, ability: String) -> bool:
	return unit != null and Pass3Oozes.has(unit, ability)


static func _rate(player: PlayerState, key: String, fallback: float) -> float:
	return CoreUtil.to_float(player.pass3_rates.get(key, fallback))


static func _body(unit: RecruitUnit) -> int:
	return unit.base_attack_now() + unit.perm_attack + unit.base_health_now() + unit.perm_health


static func _meal_size(unit: RecruitUnit) -> int:
	var soup: Vector2i = unit.get_meta("ooze_soup_bonus", Vector2i.ZERO)
	return _body(unit) + soup.x + soup.y


static func carry(player: PlayerState, room: bool = false) -> RecruitUnit:
	var best: RecruitUnit = null
	for unit: RecruitUnit in player.board:
		if unit == null or not Pass3Oozes.is_digest(unit) or (room and HeldUnits.room(unit) <= 0):
			continue
		if best == null or _body(unit) > _body(best):
			best = unit
	return best


static func wants_hasty(player: PlayerState) -> bool:
	if player.scout.is_empty():
		return false
	var total: int = 0
	var biggest: int = 0
	for entry: Variant in player.scout.get("specs", []):
		if entry == null:
			continue
		var enemy: Dictionary = entry
		var size: int = (
			CoreUtil.to_int(enemy.get("attack", 0)) + CoreUtil.to_int(enemy.get("health", 0))
		)
		total += size
		biggest = maxi(biggest, size)
	return total > 0 and biggest >= total * 0.35


static func _scouted_answer(player: PlayerState) -> bool:
	for entry: Variant in player.scout.get("specs", []):
		if entry == null:
			continue
		var spec: Dictionary = entry
		if (
			str(spec.get("def_id", ""))
			in ["hasty_pudding", "lantern_man", "old_isegrim", "seven_whistlers", "belladonna"]
		):
			return true
	return false


static func _best_copy(player: PlayerState, unit: RecruitUnit) -> bool:
	for other: RecruitUnit in player.board:
		if other != null and other != unit and other.def_id() == unit.def_id():
			if other.golden and not unit.golden:
				return false
			if other.golden == unit.golden and other.iid < unit.iid:
				return false
	return true


static func keep_engine(player: PlayerState, unit: RecruitUnit, value: BotEval) -> bool:
	if not active(player) or not build(value) or not unit.has_tribe("Oozes"):
		return false
	if unit == carry(player):
		return true
	if has(unit, "aunt_aspic") and tempo(value):
		return false
	if unit.def_id() in ENGINES and _best_copy(player, unit):
		return true
	if has(unit, "little_dollop") and player.round_number >= 8:
		return _best_copy(player, unit)
	return false


static func text_value(unit: RecruitUnit, player: PlayerState, value: BotEval) -> float:
	if player == null or not unit.has_mechanic_id("pass3_ooze"):
		return -1.0
	var biggest: RecruitUnit = Pass3Oozes.biggest(player)
	var size: int = _body(biggest) if biggest != null else 0
	var factor: int = unit.golden_factor()
	var committed: bool = build(value)
	if has(unit, "stone_soup"):
		var read_size: int = size
		if unit.golden:
			var oozes: Array[RecruitUnit] = Pass3Oozes.ranked(player)
			var reads: int = CoreUtil.to_int(player.pass3_rates.get("oozes_golden_soup_reads", 2))
			read_size = 0
			for ooze: RecruitUnit in oozes.slice(0, reads):
				read_size += _body(ooze)
		return (
			read_size * _rate(player, "oozes_soup_share", 0.125) * 4.0
			+ (12.0 if committed else 0.0)
		)
	if has(unit, "dishwater_nell"):
		return (maxf(6.0, size * 0.15) * factor) if biggest != null else 0.0
	if has(unit, "aunt_aspic"):
		if tempo(value):
			return 0.0
		return (
			(maxf(6.0, size * _rate(player, "oozes_aspic_bonus", 0.75) * 0.3) * factor)
			if carry(player) != null
			else 0.0
		)
	if has(unit, "elder_ooze"):
		return (
			(maxf(10.0, size * _rate(player, "oozes_elder_share", 0.5) * 0.6) * factor)
			if carry(player) != null
			else 0.0
		)
	if has(unit, "cut_and_come_again"):
		return size * _rate(player, "oozes_slice_share", 0.2) * 2.0 * factor
	if has(unit, "hasty_pudding"):
		return (
			(size * _rate(player, "oozes_hasty_share", 1.0 / 3.0) + 16.0) * factor
			if wants_hasty(player)
			else 4.0 * factor
		)
	if has(unit, "granny_stir_up"):
		return size * 0.5 * factor if committed else 4.0 * factor
	if Pass3Oozes.is_digest(unit):
		return (10.0 if committed else 3.0) * factor
	# Unmodeled text still uses BotEval's authored hint or the plain arm's tier fallback.
	return -1.0


## Return -1 when the ordinary purchasing path should judge this card.
static func meal_gain(brain: BotBrain, meal: RecruitUnit) -> float:
	var player: PlayerState = brain._player
	if not brain.level.reads_text or not active(player) or not build(brain.value):
		return -1.0
	if meal.has_tribe("Oozes") or BotEval.copies_of(player, meal.def_id()) >= 2:
		return -1.0
	var belly: int = food_belly(player, brain.value, meal)
	if belly < 0:
		return -1.0
	# The same stats become permanent next turn, before the next Soup and Nell meal.
	var printed: int = maxi(0, meal.base_attack_now()) + maxi(0, meal.base_health_now())
	return float(_meal_size(meal) + printed * (Pass3Oozes.eat_multiplier(player) - 1))


static func food_belly(player: PlayerState, value: BotEval, meal: RecruitUnit) -> int:
	if not active(player) or not build(value) or not value.level.reads_text:
		return -1
	if player.board_count() < 3 or meal.has_tribe("Oozes") or not meal.held.is_empty():
		return -1
	var eater: RecruitUnit = carry(player, true)
	return player.board.find(eater) if eater != null else -1


static func _needs_live_pot(player: PlayerState, unit: RecruitUnit) -> bool:
	if not Pass3Oozes.is_digest(unit):
		return false
	var pot: RecruitUnit = carry(player)
	if pot == null:
		return true
	return has(pot, "little_dollop") and not pot.golden and not has(unit, "little_dollop")


static func best_belly(player: PlayerState, value: BotEval, unit: RecruitUnit) -> int:
	# A Belly reserve cannot digest. The first pot and a Dollop upgrade must stand on board.
	if _needs_live_pot(player, unit):
		return -1
	if unit.def_id() == "slice":
		if tempo(value):
			return -1
		for offer: RecruitUnit in player.shop:
			if not offer.has_tribe("Oozes") and _meal_size(offer) >= _meal_size(unit):
				return -1
	var food: int = food_belly(player, value, unit)
	if food >= 0:
		return food
	if (
		keep_engine(player, unit, value)
		or (unit.has_mechanic_id("pass3_ooze") and unit.def_id() in ENGINES)
	):
		return -1
	if not tempo(value):
		return -1
	var best: int = -1
	for slot: int in BoardGeometry.FRONT:
		var holder: RecruitUnit = player.board[slot]
		if holder == null or holder == unit or HeldUnits.room(holder) <= 0:
			continue
		if Pass3Oozes.is_digest(holder) or (has(holder, "hasty_pudding") and wants_hasty(player)):
			continue
		if best < 0 or holder.held.size() < player.board[best].held.size():
			best = slot
	return best


static func hand_belly(brain: BotBrain, meal: RecruitUnit) -> int:
	if not active(brain._player) or not build(brain.value) or meal.def_id() != "slice":
		return -1
	if tempo(brain.value):
		return -1
	var largest: int = 0
	for unit: RecruitUnit in brain._player.shop:
		if not unit.has_tribe("Oozes"):
			largest = maxi(largest, _meal_size(unit))
	return food_belly(brain._player, brain.value, meal) if _meal_size(meal) > largest else -1


## An empty first Dollop transfers whole into the newly found carry. A second stomach waits
## three actual recruit phases; scouted biggest-enemy answers keep the concentration split.
static func prepare(brain: BotBrain) -> void:
	var player: PlayerState = brain._player
	if not brain.level.reads_text or not active(player) or not build(brain.value):
		return
	var eater: RecruitUnit = carry(player, true)
	if eater == null:
		return
	if has(eater, "little_dollop"):
		var replacement: RecruitUnit = null
		for other: RecruitUnit in player.board:
			if other == null or not Pass3Oozes.is_digest(other) or has(other, "little_dollop"):
				continue
			if (
				HeldUnits.room(other) > 0
				and (replacement == null or _body(other) > _body(replacement))
			):
				replacement = other
		if replacement == null:
			return
		eater = replacement
	for slot: int in BoardGeometry.SLOTS:
		var dollop: RecruitUnit = player.board[slot]
		if dollop == null or dollop == eater or not has(dollop, "little_dollop") or dollop.golden:
			continue
		if not dollop.held.is_empty():
			continue
		var age: int = (
			player.round_number
			- CoreUtil.to_int(dollop.counters.get("bot_stomach_since", player.round_number))
		)
		if player.round_number >= 8 and _body(dollop) <= _body(eater):
			if not dollop.counters.has("bot_stomach_since"):
				dollop.counters["bot_stomach_since"] = player.round_number
			if age < 3 or _scouted_answer(player):
				continue
		brain._rules.swallow(player, HeldUnits.BOARD, slot, player.board.find(eater))
		brain._settle()
		return


static func feed(brain: BotBrain) -> void:
	var player: PlayerState = brain._player
	if not brain.level.reads_text or not active(player) or not build(brain.value):
		return
	prepare(brain)
	for _step: int in BoardGeometry.SLOTS:
		var best: int = -1
		var largest: int = -1
		for index: int in player.shop.size():
			var unit: RecruitUnit = player.shop[index]
			var slot: int = food_belly(player, brain.value, unit)
			if slot < 0 or unit.poached_offer or not unit.held.is_empty():
				continue
			var cost: int = HeldUnits.swallow_cost(brain._rules, player, player.board[slot], unit)
			if player.gold - brain._held_back() >= cost and _meal_size(unit) > largest:
				largest = _meal_size(unit)
				best = index
		if best < 0:
			return
		var belly: int = food_belly(player, brain.value, player.shop[best])
		if brain._rules.swallow(player, HeldUnits.SHOP, best, belly) != "":
			return
		brain._settle()


static func freeze(brain: BotBrain) -> bool:
	var player: PlayerState = brain._player
	if not active(player) or not build(brain.value):
		return false
	# Free meals outrank generic shop quality. Only protect a real triple or a Figgy match.
	for unit: RecruitUnit in player.shop:
		var wanted: bool = BotEval.copies_of(player, unit.def_id()) >= 2
		for holder: RecruitUnit in player.board:
			if not has(holder, "figgy_duff"):
				continue
			for inside: RecruitUnit in holder.held:
				wanted = wanted or (inside.def_id() == unit.def_id() and not inside.golden)
		if wanted:
			brain._rules.toggle_freeze(player)
			break
	return true


static func _put(layout: Array[int], origin: int, destination: int, pinned: Array[int]) -> void:
	if origin < 0 or destination < 0:
		return
	var at: int = layout.find(origin)
	if at < 0 or at == destination or pinned.has(at) or pinned.has(destination):
		return
	var previous: int = layout[destination]
	layout[destination] = origin
	layout[at] = previous


static func arrange(
	player: PlayerState, value: BotEval, layout: Array[int], pinned: Array[int]
) -> void:
	if not active(player) or not build(value):
		return
	var eater: RecruitUnit = carry(player)
	if eater == null:
		return
	var aspic: int = -1
	var nell: int = -1
	var granny: int = -1
	var soup: int = -1
	for slot: int in BoardGeometry.SLOTS:
		if has(player.board[slot], "aunt_aspic"):
			aspic = slot
		if has(player.board[slot], "dishwater_nell"):
			nell = slot
		if has(player.board[slot], "granny_stir_up"):
			granny = slot
		if has(player.board[slot], "stone_soup"):
			soup = slot
	if tempo(value):
		_put(layout, player.board.find(eater), 5, pinned)
		_put(layout, nell, 6, pinned)
		_put(layout, soup, 4, pinned)
	else:
		_put(layout, player.board.find(eater), 1 if aspic >= 0 else 5, pinned)
		_put(layout, aspic, 4, pinned)
		_put(layout, nell, 5 if aspic >= 0 else 4, pinned)
		for slot: int in BoardGeometry.SLOTS:
			if player.board[slot] != eater and has(player.board[slot], "little_dollop"):
				_put(layout, slot, 0, pinned)
				break
	if granny < 0 and not tempo(value) and has(eater, "bubble_and_squeak"):
		var gap: int = layout.find(-1)
		if gap >= 0 and not pinned.has(gap) and not pinned.has(2):
			layout[gap] = layout[2]
			layout[2] = -1
	if granny >= 0:
		_put(layout, granny, 1, pinned)
		# Compact the occupied zigzag around Granny; a gap must not strand the carry.
		var ordered: Array[int] = []
		for destination: int in BoardGeometry.ZIGZAG:
			if layout[destination] >= 0:
				ordered.append(layout[destination])
		if pinned.is_empty():
			layout.fill(-1)
			for index: int in ordered.size():
				layout[BoardGeometry.ZIGZAG[index]] = ordered[index]


static func max_bodies(
	player: PlayerState, value: BotEval, can_replace: Callable = Callable()
) -> int:
	if not active(player) or not build(value) or not has(carry(player), "bubble_and_squeak"):
		return BoardGeometry.SLOTS
	for unit: RecruitUnit in player.board:
		if has(unit, "granny_stir_up"):
			return BoardGeometry.SLOTS
	var protected: int = 0
	for unit: RecruitUnit in player.board:
		if unit == null:
			continue
		var kept: bool = (
			not can_replace.call(unit)
			if can_replace.is_valid()
			else keep_engine(player, unit, value)
		)
		protected += int(kept)
	# A split gap is for a spare body. It must not block the next permanent engine piece.
	return BoardGeometry.SLOTS if protected >= 6 else BoardGeometry.SLOTS - 1


static func search_pins(player: PlayerState, value: BotEval, layout: Array[int]) -> Array[int]:
	var out: Array[int] = []
	if active(player) and build(value):
		for slot: int in BoardGeometry.SLOTS:
			if layout[slot] >= 0:
				out.append(slot)
	return out
