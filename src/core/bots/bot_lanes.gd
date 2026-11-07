class_name BotLanes
extends RefCounted
## Cheap, deterministic improvements against the public scout. Scores every lane together, so
## two Hunters don't exchange good matchups for one shared guess at the biggest enemy.

const PASSES: int = 3
const MOVE_COST: float = 2.0
const WRONG_ROW: float = 80.0


static func arrange(
	player: PlayerState, value: BotEval, layout: Array[int], pinned: Array[int]
) -> void:
	if not value.level.reads_text or not _has_position_text(player):
		return
	# A greedy swap considers both displaced units and the neighbours they would leave behind.
	# Exact ties keep the current layout and never consume the bot's random stream.
	for _pass: int in PASSES:
		var best: float = score(player, value, layout)
		var chosen: Vector2i = Vector2i(-1, -1)
		for a: int in BoardGeometry.SLOTS:
			for b: int in range(a + 1, BoardGeometry.SLOTS):
				if pinned.has(a) or pinned.has(b) or (layout[a] < 0 and layout[b] < 0):
					continue
				BotPlacer._swap(layout, a, b)
				var candidate: float = score(player, value, layout)
				BotPlacer._swap(layout, a, b)
				if candidate > best + 0.01:
					best = candidate
					chosen = Vector2i(a, b)
		if chosen.x < 0:
			return
		BotPlacer._swap(layout, chosen.x, chosen.y)


## Also used by combat search: it must not undo the cheap matching merely on a noisy fight.
static func score(player: PlayerState, value: BotEval, layout: Array[int]) -> float:
	var total: float = 0.0
	var patches: Array[int] = _patches(player, layout)
	var snap: bool = _has_mechanic(player, "snap")
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = _at(player, layout, slot)
		if unit == null:
			continue
		if layout[slot] != slot:
			total -= MOVE_COST
		if unit.has_mechanic_id("shy"):
			total -= 100.0 * BotPlacer._shy_cost(player, value, layout, slot)
		var row: String = value.row_of(unit)
		# Mirers explicitly choose either row; the scout, rather than the printed default,
		# decides whether they hold a front attacker or expose a carry to Snap.
		if not unit.has_mechanic_id("mire"):
			if row == "front" and BoardGeometry.is_back(slot):
				total -= WRONG_ROW
			if row == "back" and BoardGeometry.is_front(slot):
				total -= WRONG_ROW
		var quarry: int = _quarry_slot(player, layout, slot)
		if quarry >= 0 and not player.scout.is_empty():
			total += _hunt_score(player, value, layout, unit, slot, quarry)
		for enemy: int in BoardGeometry.SLOTS:
			if patches[enemy] == slot:
				total += _mire_score(player, unit, enemy, snap)
		total += _support_score(player, layout, unit, slot, patches)
		if unit.has_mechanic_id("teind"):
			var tithe: float = value.keep_value(unit)
			for behind: int in BoardGeometry.behind(slot):
				var victim: RecruitUnit = _at(player, layout, behind)
				if victim != null:
					tithe = minf(tithe, value.keep_value(victim))
			total -= 3.0 * tithe
	return total


static func positional(unit: RecruitUnit) -> bool:
	for id: String in ["mire", "quarry", "lend_quarry", "laird", "bog_aura", "pack", "pounce"]:
		if unit.has_mechanic_id(id):
			return true
	return unit.has_mechanic_id("jenny")


static func _has_position_text(player: PlayerState) -> bool:
	for unit: RecruitUnit in player.board:
		if unit != null and positional(unit):
			return true
	return false


static func _has_mechanic(player: PlayerState, id: String) -> bool:
	for unit: RecruitUnit in player.board:
		if unit != null and unit.has_mechanic_id(id):
			return true
	return false


static func _at(player: PlayerState, layout: Array[int], slot: int) -> RecruitUnit:
	return player.board[layout[slot]] if layout[slot] >= 0 else null


static func _params(unit: RecruitUnit, id: String) -> Dictionary:
	for entry: Variant in MechanicRegistry.compiled(unit.def):
		var compiled: CompiledMechanic = entry
		if compiled.id == id:
			return compiled.params_for(unit.golden)
	return {}


## Prefer the scouted Egg body; old saves with only a Nest slot fall back to 0/2.
static func _enemy(player: PlayerState, slot: int) -> Dictionary:
	var specs: Array = player.scout.get("specs", [])
	if slot < specs.size() and specs[slot] != null:
		var spec: Dictionary = specs[slot]
		return spec
	var nests: Array = player.scout.get("nests", [])
	if nests.has(slot):
		return {"def_id": HeldUnits.EGG, "attack": 0, "health": 2, "egg": true}
	return {}


static func _egg(enemy: Dictionary) -> bool:
	return (
		str(enemy.get("def_id", "")) == HeldUnits.EGG or CoreUtil.to_bool(enemy.get("egg", false))
	)


static func _stat(enemy: Dictionary, key: String) -> int:
	return CoreUtil.to_int(enemy.get(key, 0))


## Predict bell marks in the engine's order: own Quarry first, then lenders in reading order.
static func _quarry_slot(player: PlayerState, layout: Array[int], slot: int) -> int:
	var unit: RecruitUnit = _at(player, layout, slot)
	if unit == null:
		return -1
	if (
		unit.has_mechanic_id("quarry")
		and not _enemy(player, slot).is_empty()
		and not _egg(_enemy(player, slot))
	):
		return slot
	for source: int in BoardGeometry.SLOTS:
		var lender: RecruitUnit = _at(player, layout, source)
		if lender == null or not lender.has_mechanic_id("lend_quarry"):
			continue
		var params: Dictionary = _params(lender, "lend_quarry")
		var select: String = str(params.get("select", "adjacent"))
		var selected: bool = select == "friendly"
		if select == "neighbours":
			selected = BoardGeometry.neighbours(source).has(slot)
		elif select == "adjacent":
			selected = BoardGeometry.adjacent(source).has(slot)
		var target: int = slot if CoreUtil.to_bool(params.get("own_across", false)) else source
		if selected and not _enemy(player, target).is_empty() and not _egg(_enemy(player, target)):
			return target
	return -1


static func _hunt_score(
	player: PlayerState,
	value: BotEval,
	layout: Array[int],
	unit: RecruitUnit,
	slot: int,
	quarry: int
) -> float:
	var enemy: Dictionary = _enemy(player, quarry)
	if enemy.is_empty() or _egg(enemy):
		return -8.0
	var attack: int = _stat(enemy, "attack")
	var health: int = _stat(enemy, "health")
	var hit: int = unit.attack
	for next: int in BoardGeometry.adjacent(slot):
		var joiner: RecruitUnit = _at(player, layout, next)
		if joiner != null and joiner.has_mechanic_id("pack"):
			hit += joiner.attack
	var kill: bool = hit >= health
	match unit.def_id():
		"little_nip":
			return (24.0 if kill else -minf(16.0, health - hit)) + 0.1 * attack
		"sable":
			var bonus: int = (6 if unit.golden else 3) if attack > unit.attack else 0
			return (
				(18.0 if attack > unit.attack else 0.0)
				+ (8.0 if hit + bonus >= health else 0.0)
				+ 0.2 * attack
			)
		"toll_bard":
			return 7.0 * minf(3.0, float(health) / maxi(1, hit)) + 0.2 * attack
		"mistress_russet":
			return _poach_score(player, value, enemy) + (8.0 if kill else 0.0)
		"old_lutra":
			return (
				(12.0 if BoardGeometry.is_back(quarry) else 0.0)
				+ 0.5 * attack
				+ (6.0 if kill else 0.0)
			)
	return minf(12.0, 0.5 * attack + hit) + (5.0 if kill else 0.0)


static func _poach_score(player: PlayerState, value: BotEval, enemy: Dictionary) -> float:
	if value.library == null:
		return 0.0
	var card: Dictionary = value.library.get_unit(str(enemy.get("def_id", "")))
	if card.is_empty() or not CoreUtil.to_bool(card.get("pool", false)):
		return -12.0
	if CoreUtil.to_int(card.get("tier", 0)) > player.tier:
		return -12.0
	return 0.8 * value.def_value(card, player)


## Patch ownership follows reading order, including spread and loaned Mire.
static func _patches(player: PlayerState, layout: Array[int]) -> Array[int]:
	var makers: Array[int] = [-1, -1, -1, -1, -1, -1, -1]
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = _at(player, layout, slot)
		if unit == null:
			continue
		var mire: bool = unit.has_mechanic_id("mire")
		for next: int in BoardGeometry.adjacent(slot):
			var lender: RecruitUnit = _at(player, layout, next)
			if lender != null and CoreUtil.to_bool(_params(lender, "bog_aura").get("mire", false)):
				mire = true
		if not mire:
			continue
		var targets: Array[int] = [slot]
		if CoreUtil.to_bool(_params(unit, "mire").get("spread", false)):
			targets.append_array(BoardGeometry.adjacent(slot))
		for target: int in targets:
			if makers[target] < 0:
				makers[target] = slot
	return makers


static func _mire_score(player: PlayerState, unit: RecruitUnit, slot: int, snap: bool) -> float:
	if player.scout.is_empty():
		return 0.0
	var enemy: Dictionary = _enemy(player, slot)
	if enemy.is_empty() or _egg(enemy):
		return -10.0
	var attack: int = _stat(enemy, "attack")
	var total: float = 0.7 * attack + 2.0
	if snap and BoardGeometry.is_back(slot):
		total += 8.0 + 0.6 * attack
	match unit.def_id():
		"madame_bufo":
			total += 0.9 * attack + (8.0 if attack >= unit.health else 0.0)
		"bridge_toad":
			var biggest: int = 0
			for other: int in BoardGeometry.SLOTS:
				biggest = maxi(biggest, _stat(_enemy(player, other), "attack"))
			if attack == biggest:
				total += 15.0
		"gideon":
			total += 10.0 if attack < unit.health else -6.0
	return total


static func _support_score(
	player: PlayerState, layout: Array[int], unit: RecruitUnit, slot: int, patches: Array[int]
) -> float:
	var total: float = 0.0
	for next: int in BoardGeometry.adjacent(slot):
		var neighbour: RecruitUnit = _at(player, layout, next)
		if neighbour == null:
			continue
		if unit.has_mechanic_id("pack") and not neighbour.has_mechanic_id("pack"):
			total += 3.0 + 0.5 * neighbour.attack
			if _quarry_slot(player, layout, next) >= 0:
				total += 4.0
		if unit.has_mechanic_id("jenny"):
			total += 0.8 * neighbour.attack
		if unit.has_mechanic_id("bog_aura") and patches[next] >= 0:
			total += minf(6.0, 0.5 * neighbour.health)
	if unit.has_mechanic_id("pounce"):
		for next: int in BoardGeometry.neighbours(slot):
			if _quarry_slot(player, layout, next) >= 0:
				total += 3.0
	if unit.has_mechanic_id("lend_quarry"):
		var params: Dictionary = _params(unit, "lend_quarry")
		var targets: Array[int] = BoardGeometry.adjacent(slot)
		if str(params.get("select", "")) == "neighbours":
			targets = BoardGeometry.neighbours(slot)
		var enemy: Dictionary = _enemy(player, slot)
		for target: int in targets:
			var borrower: RecruitUnit = _at(player, layout, target)
			if borrower != null and not borrower.has_mechanic_id("quarry"):
				total += 3.0 + 0.5 * borrower.attack
				if not enemy.is_empty() and not _egg(enemy):
					total += 2.0 + 0.15 * _stat(enemy, "attack")
	return total
