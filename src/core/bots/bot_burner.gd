class_name BotBurner
extends RefCounted
## The stats this turn's actual gold can buy through Charcoal Burner. No fixed gold reserve.


static func forecast(
	player: PlayerState, gold: int, extra: RecruitUnit = null, at: int = -1
) -> float:
	var board: Array[RecruitUnit] = player.board.duplicate()
	if BoardGeometry.is_valid(at):
		var source: int = board.find(extra)
		if source >= 0:
			board[source] = board[at]
		board[at] = extra
	var total: float = 0.0
	var left: int = gold
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = board[slot]
		var params: Dictionary = _params(unit)
		if params.is_empty():
			continue
		var amount: int = mini(
			maxi(0, left - CoreUtil.to_int(params["above"])), CoreUtil.to_int(params["most"])
		)
		left -= amount
		total += _gift(board, slot, amount)
	return total


static func spend_loss(player: PlayerState, cost: int) -> float:
	return maxf(0.0, forecast(player, player.gold) - forecast(player, maxi(0, player.gold - cost)))


static func purchase_value(unit: RecruitUnit, player: PlayerState, cost: int) -> float:
	if _params(unit).is_empty():
		return -1.0
	var gold: int = maxi(0, player.gold - cost)
	var best: float = 0.0
	var before: float = forecast(player, gold)
	for slot: int in BoardGeometry.FRONT:
		best = maxf(best, forecast(player, gold, unit, slot) - before)
	return best


static func owned_value(unit: RecruitUnit, player: PlayerState) -> float:
	var slot: int = player.board.find(unit)
	if _params(unit).is_empty():
		return 0.0
	if slot < 0:
		for holder: RecruitUnit in player.board:
			if holder != null and holder.held.has(unit):
				return 0.0
		return purchase_value(unit, player, 0)
	var before: float = forecast(player, player.gold)
	# Temporarily exclude it only in the forecast, never in the real board.
	var zero := RecruitUnit.new()
	return maxf(0.0, before - forecast(player, player.gold, zero, slot))


static func best_front_slot(player: PlayerState, unit: RecruitUnit, pinned: Array[int]) -> int:
	var source: int = player.board.find(unit)
	if source < 0 or pinned.has(source):
		return source
	var best: int = source
	var most: float = forecast(player, player.gold)
	for slot: int in BoardGeometry.FRONT:
		if pinned.has(slot):
			continue
		var score: float = forecast(player, player.gold, unit, slot)
		if score > most:
			best = slot
			most = score
	return best


static func _gift(board: Array[RecruitUnit], slot: int, burned: int) -> float:
	@warning_ignore("integer_division")
	var steps: int = burned / 2
	if steps <= 0:
		return 0.0
	var total: float = 0.0
	for behind: int in BoardGeometry.behind(slot):
		var target: RecruitUnit = board[behind]
		if (
			target == null
			or target.def.is_empty()
			or target.has_mechanic_id("shy")
			or not target.can_gain_permanent()
		):
			continue
		total += 2.0 * steps
	return total


static func _params(unit: RecruitUnit) -> Dictionary:
	if unit == null or unit.def.is_empty() or unit.def_id() != "charcoal_burner":
		return {}
	for mechanic: Variant in MechanicRegistry.compiled(unit.def):
		var compiled: CompiledMechanic = mechanic
		if compiled.id != "effect":
			continue
		for step: Dictionary in MechanicRegistry.steps_of(compiled.params_for(unit.golden)):
			if str(step.get("effect", "")) == "burn_gold":
				return step
	return {}
