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
	return _forecast(board, gold)


static func layout_value(player: PlayerState, layout: Array[int]) -> float:
	var board: Array[RecruitUnit] = []
	for source: int in layout:
		board.append(player.board[source] if source >= 0 else null)
	return _forecast(board, player.gold)


static func _forecast(board: Array[RecruitUnit], gold: int) -> float:
	var own: Dictionary = {}
	for target: RecruitUnit in board:
		if target != null:
			own[target.get_instance_id()] = Vector2i(
				target.base_attack_now() + target.perm_attack,
				target.base_health_now() + target.perm_health
			)
	var total: float = 0.0
	var left: int = gold
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = board[slot]
		var params: Dictionary = _params(unit)
		if params.is_empty():
			continue
		var amount: int = maxi(0, left - CoreUtil.to_int(params["above"]))
		var cap: int = CoreUtil.to_int(params.get("most", 0))
		if cap > 0:
			amount = mini(amount, cap)
		left -= amount
		total += _gift(board, slot, amount, params, own)
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


static func _gift(
	board: Array[RecruitUnit], slot: int, burned: int, params: Dictionary, own: Dictionary
) -> float:
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
		var stats: Vector2i = own[target.get_instance_id()]
		var gift: Vector2i
		if params.has("share"):
			var share: float = CoreUtil.to_float(params["share"]) * burned
			gift = Vector2i(floori(stats.x * share), floori(stats.y * share))
		else:
			var steps: int = int(burned / 2.0)
			gift = Vector2i(steps, steps)
		own[target.get_instance_id()] = stats + gift
		total += gift.x + gift.y
	return total


static func _params(unit: RecruitUnit) -> Dictionary:
	if unit == null or unit.def.is_empty() or unit.def_id() != "charcoal_burner":
		return {}
	for mechanic: Variant in MechanicRegistry.compiled(unit.def):
		var compiled: CompiledMechanic = mechanic
		if compiled.id == "pass3_neutral":
			var native: Dictionary = compiled.params_for(unit.golden)
			if str(native.get("ability", "")) == "charcoal_burner":
				return {
					"above": native.get("above", 5),
					"most":
					(
						CoreUtil.to_int(native.get("cap", 6))
						* CoreUtil.to_int(native.get("factor", 1))
					),
					"share": native.get("share", 0.05)
				}
		if compiled.id != "effect":
			continue
		for step: Dictionary in MechanicRegistry.steps_of(compiled.params_for(unit.golden)):
			if str(step.get("effect", "")) == "burn_gold":
				return step
	return {}
