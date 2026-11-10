class_name BotNeutral
extends RefCounted
## Current neutral text reads actual recipients and upcoming plays; archived cards keep their hints.


static func params(unit: RecruitUnit, ability: String = "") -> Dictionary:
	if unit == null or unit.def.is_empty():
		return {}
	for compiled: CompiledMechanic in MechanicRegistry.compiled(unit.def):
		if compiled.id != "pass3_neutral":
			continue
		var entry: Dictionary = compiled.params_for(unit.golden)
		if ability == "" or str(entry.get("ability", "")) == ability:
			return entry
	return {}


static func _at(player: PlayerState, layout: Array[int], slot: int) -> RecruitUnit:
	return player.board[layout[slot]] if layout[slot] >= 0 else null


static func _identity(player: PlayerState) -> Array[int]:
	var layout: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		layout.append(slot if player.board[slot] != null else -1)
	return layout


static func text_value(unit: RecruitUnit, player: PlayerState) -> float:
	var entry: Dictionary = params(unit)
	if player == null or entry.is_empty():
		return -1.0
	match str(entry.get("ability", "")):
		"shieldbug", "ballooning_spider":
			for holder: RecruitUnit in player.board:
				if holder != null and holder.held.has(unit):
					return 0.0
			var layout: Array[int] = _identity(player)
			var source: int = player.board.find(unit)
			if source >= 0:
				return _support(player, layout, source, str(entry["ability"]))
			var best: float = 0.0
			for slot: int in BoardGeometry.FRONT:
				best = maxf(best, _support(player, layout, slot, str(entry["ability"])))
			return best
		"whirligig_beetle":
			return _whirligig(player, entry)
		"click_beetle":
			var other: int = 1
			for source: RecruitUnit in player.board:
				if source != unit:
					other = maxi(other, _repeats(source))
			return maxi(0, _repeats(unit) - other) * _play_potential(player)
	return -1.0


static func _support(player: PlayerState, layout: Array[int], slot: int, ability: String) -> float:
	var total: float = 0.0
	for behind: int in BoardGeometry.behind(slot):
		var target: RecruitUnit = _at(player, layout, behind)
		if target == null:
			continue
		var covered: bool = false
		for other: int in BoardGeometry.FRONT:
			if (
				other != slot
				and BoardGeometry.behind(other).has(behind)
				and not params(_at(player, layout, other), ability).is_empty()
			):
				covered = true
		if covered:
			continue
		if ability == "shieldbug":
			if not target.has_mechanic_id("shield"):
				total += target.health * 0.5
		elif not target.has_mechanic_id("back_strike") and target.attack > 0:
			var seen: Array = player.scout.get("specs", [])
			var back: bool = seen.is_empty()
			for enemy: int in BoardGeometry.BACK:
				back = back or (enemy < seen.size() and seen[enemy] != null)
			if back:
				total += target.attack * 0.35
	return total


static func _whirligig(player: PlayerState, entry: Dictionary) -> float:
	var enemy: Array = player.scout.get("specs", [])
	var slots: Array = player.scout.get("slots", [])
	var share: float = CoreUtil.to_float(
		entry.get(
			(
				"golden_health_share"
				if CoreUtil.to_int(entry.get("factor", 1)) > 1
				else "health_share"
			),
			0.1
		)
	)
	var total: float = 0.0
	for front: int in 3:
		var back: int = front + 4
		var skip: bool = false
		if slots.size() > back:
			var first: Array = slots[front]
			var second: Array = slots[back]
			var a: Vector2i = BoardUpkeep.ring_value(first)
			var b: Vector2i = BoardUpkeep.ring_value(second)
			skip = a != b
		if skip:
			continue
		for slot: int in [front, back]:
			if slot < enemy.size() and enemy[slot] != null:
				var spec: Dictionary = enemy[slot]
				var health: int = CoreUtil.to_int(spec.get("health", 1))
				total += mini(maxi(0, health - 1), floori(health * share))
	return total


static func _repeats(unit: RecruitUnit) -> int:
	var entry: Dictionary = params(unit, "click_beetle")
	if entry.is_empty():
		return 1
	return CoreUtil.to_int(
		entry.get("golden_repeats" if CoreUtil.to_int(entry.get("factor", 1)) > 1 else "repeats", 2)
	)


static func _on_play(unit: RecruitUnit, homecoming: bool, player: PlayerState) -> float:
	var total: float = 0.0
	for compiled: CompiledMechanic in MechanicRegistry.compiled(unit.def):
		var entry: Dictionary = compiled.params_for(unit.golden)
		if compiled.id == "effect" and str(entry.get("trigger", "")) == "on_play":
			for step: Dictionary in MechanicRegistry.steps_of(entry):
				total += BotEval._effect_value(step) * unit.golden_factor()
		elif compiled.id == "pass3_hedgerow" and str(entry.get("ability", "")) == "mr_crumb":
			total += (
				2.0
				* CoreUtil.to_float(entry.get("pass", 1))
				* CoreUtil.to_int(entry.get("factor", 1))
			)
		elif compiled.id == "pass3_bird" and str(entry.get("ability", "")) == "goose":
			total += 12.0 * unit.golden_factor()
	if homecoming and unit.def_id() == "chiffchaff":
		total *= CoreUtil.to_float(
			player.pass3_rates.get(
				(
					"birds_golden_homecoming_multiplier"
					if unit.golden
					else "birds_homecoming_multiplier"
				),
				2.0
			)
		)
	return total


static func _play_potential(player: PlayerState) -> float:
	var total: float = 0.0
	for unit: RecruitUnit in player.hand:
		total += _on_play(unit, false, player)
	for trip: Dictionary in player.away:
		var unit: RecruitUnit = trip["unit"]
		total += _on_play(unit, true, player) / maxi(1, CoreUtil.to_int(trip.get("left", 1)))
	for unit: RecruitUnit in player.board:
		if unit != null and unit.has_mechanic_id("fly_south"):
			total += 0.5 * _on_play(unit, true, player)
	return total


static func keep_engine(player: PlayerState, unit: RecruitUnit, value: BotEval) -> bool:
	if not value.level.reads_text or params(unit).is_empty():
		return false
	if not params(unit, "charcoal_burner").is_empty():
		return BotBurner.owned_value(unit, player) > 0.0
	if params(unit, "click_beetle").is_empty() or _play_potential(player) <= 0.0:
		return false
	for other: RecruitUnit in player.board:
		if other != null and other != unit and _repeats(other) >= _repeats(unit):
			if _repeats(other) > _repeats(unit) or other.iid < unit.iid:
				return false
	return true


static func _positional(unit: RecruitUnit) -> bool:
	return (
		not params(unit, "shieldbug").is_empty()
		or not params(unit, "ballooning_spider").is_empty()
		or not params(unit, "charcoal_burner").is_empty()
	)


static func _score(player: PlayerState, layout: Array[int]) -> float:
	var total: float = BotBurner.layout_value(player, layout)
	for slot: int in BoardGeometry.FRONT:
		var unit: RecruitUnit = _at(player, layout, slot)
		for ability: String in ["shieldbug", "ballooning_spider"]:
			if not params(unit, ability).is_empty():
				total += _support(player, layout, slot, ability)
	return total


static func arrange(
	player: PlayerState, value: BotEval, layout: Array[int], pinned: Array[int]
) -> void:
	if not value.level.reads_text:
		return
	var native: bool = false
	for unit: RecruitUnit in player.board:
		native = native or _positional(unit)
	if not native:
		return
	for _pass: int in 2:
		for source: int in BoardGeometry.SLOTS:
			if pinned.has(source) or not _positional(_at(player, layout, source)):
				continue
			var best: int = source
			var most: float = _score(player, layout)
			for target: int in BoardGeometry.FRONT:
				if pinned.has(target):
					continue
				BotPlacer._swap(layout, source, target)
				var score: float = _score(player, layout)
				BotPlacer._swap(layout, source, target)
				if score > most + 0.01:
					best = target
					most = score
			if best != source:
				BotPlacer._swap(layout, source, best)


static func search_pins(player: PlayerState, layout: Array[int]) -> Array[int]:
	var out: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		if _positional(_at(player, layout, slot)):
			out.append(slot)
			for behind: int in BoardGeometry.behind(slot):
				out.append(behind)
	return out
