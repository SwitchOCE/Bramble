class_name BotCarrier
extends RefCounted
## Promoted carrier-retirement policy; same decisions as the frozen carrier_upgrade trial.

const LATE_TIER: int = 4
const CARRIER_TIER: int = 3


static func unit_gain(brain: BotBrain, unit: RecruitUnit) -> float:
	var base: float = brain._ordinary_unit_gain(unit)
	if brain._replacements >= BotBrain.MAX_STEPS:
		return base
	var plan: Dictionary = upgrade_plan(brain, unit)
	return maxf(base, BotEval._number(plan.get("gain", 0.0)))


static func clear_slot_for(brain: BotBrain, unit: RecruitUnit) -> int:
	var plan: Dictionary = upgrade_plan(brain, unit)
	if plan.is_empty() or brain._replacements >= BotBrain.MAX_STEPS:
		return brain._ordinary_clear_slot_for(unit)
	var weakest: int = brain._weakest_slot()
	var base_gain: float = brain._replacement_gain(unit, weakest) if weakest >= 0 else 0.0
	# Compare alternatives on the same intrinsic scale, not against a bonus-inflated base score.
	if base_gain > 0.0 and _trade_gain(brain, unit, weakest) >= BotEval._number(plan["gain"]):
		return brain._ordinary_clear_slot_for(unit)
	var slot: int = CoreUtil.to_int(plan["slot"])
	# Keep the old body in a Belly if the ordinary legal route permits that instead of a sale.
	var belly: int = BotHeld.best_belly(brain._player, brain.value, brain._player.board[slot])
	if belly >= 0 and brain._rules.swallow(brain._player, HeldUnits.BOARD, slot, belly) == "":
		brain._settle()
		return slot if brain._player.board[slot] == null else -1
	if brain._rules.sell(brain._player, slot) != "":
		return -1
	brain._replacements += 1
	brain._settle()
	return slot if brain._player.board[slot] == null else -1


static func upgrade_plan(brain: BotBrain, unit: RecruitUnit) -> Dictionary:
	if unit.tier() < LATE_TIER or brain._room_left() > 0 or not unit.held.is_empty():
		return {}
	# Do not score a board replacement when this purchase will actually go into a Belly.
	if not brain._player.all_units().has(unit) and brain._buy_belly(unit) >= 0:
		return {}
	var pinned: Array[int] = BotPlacer.pinned_slots(brain._player)
	var best: Dictionary = {}
	var most: float = 0.0
	for slot: int in BoardGeometry.SLOTS:
		var old: RecruitUnit = brain._player.board[slot]
		if old == null or old.tier() > CARRIER_TIER or pinned.has(slot):
			continue
		if (
			not old.held.is_empty()
			or not old.grants.is_empty()
			or HeldUnits.flies(old, brain._player)
		):
			continue
		if not old.golden and BotEval.copies_of(brain._player, old.def_id()) >= 2:
			continue
		var board: Array[RecruitUnit] = brain._player.board.duplicate()
		board[slot] = unit
		if engine_text(brain, unit, board, slot) <= 0.0:
			continue
		var gain: float = _trade_gain(brain, unit, slot)
		if gain > most:
			most = gain
			best = {"slot": slot, "gain": gain}
	return best


static func _trade_gain(brain: BotBrain, unit: RecruitUnit, slot: int) -> float:
	var board: Array[RecruitUnit] = brain._player.board.duplicate()
	board[slot] = unit
	return (
		_intrinsic(brain, unit, board, slot)
		+ BotCommitment.future_bonus(unit, brain._player)
		- _intrinsic(brain, brain._player.board[slot], brain._player.board, slot)
		- brain.level.replace_margin
	)


static func _intrinsic(
	brain: BotBrain, unit: RecruitUnit, board: Array[RecruitUnit], slot: int
) -> float:
	var score: float = brain.value.keep_value(unit) - brain.value.build_bonus(unit.def)
	var text: float = engine_text(brain, unit, board, slot)
	if text >= 0.0:
		score += text - (2.0 if unit.golden else 1.0) * brain.value.text_value(unit)
	elif CoreUtil.to_int(unit.def.get("turns_repeat", 0)) > 0 and not unit.pays_again():
		# An exhausted periodic payout is not future text, even if its old hint still prices it.
		score -= (2.0 if unit.golden else 1.0) * brain.value.text_value(unit)
	return score


## Cheap, explicit live-text models. -1 means retain Hard's ordinary hint, not zero text.
static func engine_text(
	brain: BotBrain, unit: RecruitUnit, board: Array[RecruitUnit], slot: int
) -> float:
	if unit.has_mechanic_id("grizel"):
		var growth: float = _pack_growth(brain, unit, board)
		return (
			maxf(growth, brain.value.text_value(unit) * unit.golden_factor())
			if growth > 0.0
			else 0.0
		)
	if unit.has_mechanic_id("peat_king"):
		var summons: float = _peat_value(brain, unit, board, slot)
		return (
			maxf(summons, brain.value.text_value(unit) * unit.golden_factor())
			if summons > 0.0
			else 0.0
		)
	var occupied: Array[bool] = []
	for body: RecruitUnit in board:
		occupied.append(body != null)
	var touching: Array[int] = BoardGeometry.touching(occupied, slot)
	var total: float = 0.0
	var modeled: bool = false
	for entry: Variant in MechanicRegistry.compiled(unit.def):
		var compiled: CompiledMechanic = entry
		var params: Dictionary = compiled.params_for(unit.golden)
		if compiled.id != "effect" or str(params.get("trigger", "")) != "start_of_combat":
			continue
		for step: Dictionary in MechanicRegistry.steps_of(params):
			var target: Dictionary = step.get("target", {})
			if str(step.get("effect", "")) != "buff" or str(target.get("select", "")) != "touching":
				continue
			modeled = true
			if not _touching_conditions(params, touching.size()):
				continue
			for _at: int in touching:
				total += (
					CoreUtil.to_int(step.get("attack", 0)) + CoreUtil.to_int(step.get("health", 0))
				)
	return total if modeled else -1.0


static func _touching_conditions(params: Dictionary, count: int) -> bool:
	var conditions: Array = params.get("if", [])
	for condition: Dictionary in conditions:
		var target: Dictionary = condition.get("target", {})
		if str(condition.get("kind", "")) != "count" or str(target.get("select", "")) != "touching":
			return false
		if count < CoreUtil.to_int(condition.get("at_least", 0)):
			return false
		if count > CoreUtil.to_int(condition.get("at_most", BoardGeometry.SLOTS)):
			return false
	return true


static func _pack_growth(brain: BotBrain, unit: RecruitUnit, board: Array[RecruitUnit]) -> float:
	if brain._player.health <= BotBrain.LOW_HEALTH:
		return 0.0
	var used: Array[int] = []
	var total: float = 0.0
	var attack: int = unit.mechanic_number("grizel", "attack")
	# Average growth over five/three combats, plus half a current-fight gift. This is a fixed
	# planning estimate; there are no extra fights or clock-dependent choices.
	var future: float = 2.5 if brain._player.health > BotBrain.SAFE_HEALTH else 1.5
	for leader: int in BoardGeometry.SLOTS:
		if board[leader] == null or used.has(leader) or board[leader].attack <= 0:
			continue
		if CoreUtil.to_bool(_params(board[leader], "pack").get("repeat", false)):
			var supported: bool = false
			for next: int in BoardGeometry.adjacent(leader):
				if board[next] != null and board[next].attack > 0:
					supported = (
						supported
						or not CoreUtil.to_bool(_params(board[next], "pack").get("repeat", false))
					)
			if supported:
				continue
		var group: Array[int] = [leader]
		for next: int in BoardGeometry.adjacent(leader):
			if board[next] != null and board[next].has_mechanic_id("pack") and not used.has(next):
				group.append(next)
				if not CoreUtil.to_bool(_params(board[next], "pack").get("repeat", false)):
					used.append(next)
		used.append(leader)
		if group.size() <= 1:
			continue
		for at: int in group:
			if board[at].can_gain_permanent():
				var growth: float = attack * future
				var cap: int = CoreUtil.to_int(board[at].def.get("permanent_buff_cap", 0))
				if cap > 0:
					growth = minf(
						growth, maxi(0, cap * board[at].golden_factor() - board[at].perm_attack)
					)
				total += growth
	return total


static func _peat_value(
	brain: BotBrain, unit: RecruitUnit, board: Array[RecruitUnit], slot: int
) -> float:
	var marks: Dictionary = {}
	var vacancies: int = 0
	var enemy_attack: int = 0
	var seen: Array = brain._player.scout.get("specs", [])
	for spec: Variant in seen:
		if spec != null:
			var enemy: Dictionary = spec
			enemy_attack = maxi(enemy_attack, CoreUtil.to_int(enemy.get("attack", 0)))
	for at: int in BoardGeometry.SLOTS:
		var body: RecruitUnit = board[at]
		if body == null:
			vacancies += 1
			continue
		if (
			at != slot
			and BoardGeometry.is_front(at)
			and (seen.is_empty() or body.health <= enemy_attack)
		):
			vacancies += 1
		if body.has_mechanic_id("mire"):
			marks[at] = true
			if CoreUtil.to_bool(_params(body, "mire").get("spread", false)):
				for next: int in BoardGeometry.adjacent(at):
					marks[next] = true
	var live_marks: int = 0
	for at: Variant in marks:
		if seen.is_empty() or (CoreUtil.to_int(at) < seen.size() and seen[at] != null):
			live_marks += 1
	var count: int = mini(unit.mechanic_number("peat_king", "limit"), mini(vacancies, live_marks))
	var token: Dictionary = brain._rules.library.get_unit("peatling")
	var factor: int = 2 if unit.golden else 1
	var body_value: int = (
		factor * (CoreUtil.to_int(token["attack"]) + CoreUtil.to_int(token["health"]))
	)
	var bitter: int = 0
	for entry: Variant in MechanicRegistry.compiled(token):
		var compiled: CompiledMechanic = entry
		if compiled.id == "bitter":
			bitter = CoreUtil.to_int(compiled.params_for(unit.golden).get("n", 0))
	return count * (body_value + bitter)


static func _params(unit: RecruitUnit, id: String) -> Dictionary:
	for entry: Variant in MechanicRegistry.compiled(unit.def):
		var compiled: CompiledMechanic = entry
		if compiled.id == id:
			return compiled.params_for(unit.golden)
	return {}
