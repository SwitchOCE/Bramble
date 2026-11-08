extends BotBrain
## Second attempt: retire a low-tier carrier for live late text, including off-plan engines.
## Full current stats stay valuable; build preferences alone cannot make a carrier irreplaceable.
## Buying and making room use the same marginal comparison. No extra combat simulations.

const LATE_TIER: int = 4
const CARRIER_TIER: int = 3


func _unit_gain(unit: RecruitUnit) -> float:
	var base: float = super._unit_gain(unit)
	if _replacements >= MAX_STEPS:
		return base
	var plan: Dictionary = upgrade_plan(unit)
	return maxf(base, BotEval._number(plan.get("gain", 0.0)))


func _clear_slot_for(unit: RecruitUnit) -> int:
	var plan: Dictionary = upgrade_plan(unit)
	if plan.is_empty() or _replacements >= MAX_STEPS:
		return super._clear_slot_for(unit)
	var weakest: int = super._weakest_slot()
	var base_gain: float = super._replacement_gain(unit, weakest) if weakest >= 0 else 0.0
	# Compare alternatives on the same intrinsic scale, not against a bonus-inflated base score.
	if base_gain > 0.0 and _trade_gain(unit, weakest) >= BotEval._number(plan["gain"]):
		return super._clear_slot_for(unit)
	var slot: int = CoreUtil.to_int(plan["slot"])
	# Keep the old body in a Belly if the ordinary legal route permits that instead of a sale.
	var belly: int = BotHeld.best_belly(_player, value, _player.board[slot])
	if belly >= 0 and _rules.swallow(_player, HeldUnits.BOARD, slot, belly) == "":
		_settle()
		return slot if _player.board[slot] == null else -1
	if _rules.sell(_player, slot) != "":
		return -1
	_replacements += 1
	_settle()
	return slot if _player.board[slot] == null else -1


func upgrade_plan(unit: RecruitUnit) -> Dictionary:
	if unit.tier() < LATE_TIER or _room_left() > 0 or not unit.held.is_empty():
		return {}
	# Do not score a board replacement when this purchase will actually go into a Belly.
	if not _player.all_units().has(unit) and _buy_belly(unit) >= 0:
		return {}
	var pinned: Array[int] = BotPlacer.pinned_slots(_player)
	var best: Dictionary = {}
	var most: float = 0.0
	for slot: int in BoardGeometry.SLOTS:
		var old: RecruitUnit = _player.board[slot]
		if old == null or old.tier() > CARRIER_TIER or pinned.has(slot):
			continue
		if not old.held.is_empty() or not old.grants.is_empty() or HeldUnits.flies(old, _player):
			continue
		if not old.golden and BotEval.copies_of(_player, old.def_id()) >= 2:
			continue
		var board: Array[RecruitUnit] = _player.board.duplicate()
		board[slot] = unit
		if engine_text(unit, board, slot) <= 0.0:
			continue
		var gain: float = _trade_gain(unit, slot)
		if gain > most:
			most = gain
			best = {"slot": slot, "gain": gain}
	return best


func _trade_gain(unit: RecruitUnit, slot: int) -> float:
	var board: Array[RecruitUnit] = _player.board.duplicate()
	board[slot] = unit
	return (
		_intrinsic(unit, board, slot)
		+ BotCommitment.future_bonus(unit, _player)
		- _intrinsic(_player.board[slot], _player.board, slot)
		- level.replace_margin
	)


func _intrinsic(unit: RecruitUnit, board: Array[RecruitUnit], slot: int) -> float:
	var score: float = value.keep_value(unit) - value.build_bonus(unit.def)
	var text: float = engine_text(unit, board, slot)
	if text >= 0.0:
		score += text - (2.0 if unit.golden else 1.0) * value.text_value(unit)
	elif CoreUtil.to_int(unit.def.get("turns_repeat", 0)) > 0 and not unit.pays_again():
		# An exhausted periodic payout is not future text, even if its old hint still prices it.
		score -= (2.0 if unit.golden else 1.0) * value.text_value(unit)
	return score


## Cheap, explicit live-text models. -1 means retain Hard's ordinary hint, not zero text.
func engine_text(unit: RecruitUnit, board: Array[RecruitUnit], slot: int) -> float:
	if unit.has_mechanic_id("grizel"):
		var growth: float = _pack_growth(unit, board)
		return maxf(growth, value.text_value(unit) * unit.golden_factor()) if growth > 0.0 else 0.0
	if unit.has_mechanic_id("peat_king"):
		var summons: float = _peat_value(unit, board, slot)
		return (
			maxf(summons, value.text_value(unit) * unit.golden_factor()) if summons > 0.0 else 0.0
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
			for at: int in touching:
				total += (
					-20
					if board[at].has_mechanic_id("shy")
					else (
						CoreUtil.to_int(step.get("attack", 0))
						+ CoreUtil.to_int(step.get("health", 0))
					)
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


func _pack_growth(unit: RecruitUnit, board: Array[RecruitUnit]) -> float:
	if _player.health <= LOW_HEALTH:
		return 0.0
	var used: Array[int] = []
	var total: float = 0.0
	var attack: int = unit.mechanic_number("grizel", "attack")
	# Average growth over five/three combats, plus half a current-fight gift. This is a fixed
	# planning estimate; there are no extra fights or clock-dependent choices.
	var future: float = 2.5 if _player.health > SAFE_HEALTH else 1.5
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
			if not board[at].has_mechanic_id("shy") and board[at].can_gain_permanent():
				var growth: float = attack * future
				var cap: int = CoreUtil.to_int(board[at].def.get("permanent_buff_cap", 0))
				if cap > 0:
					growth = minf(
						growth, maxi(0, cap * board[at].golden_factor() - board[at].perm_attack)
					)
				total += growth
	return total


func _peat_value(unit: RecruitUnit, board: Array[RecruitUnit], slot: int) -> float:
	var marks: Dictionary = {}
	var vacancies: int = 0
	var enemy_attack: int = 0
	var seen: Array = _player.scout.get("specs", [])
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
	var token: Dictionary = _rules.library.get_unit("peatling")
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
