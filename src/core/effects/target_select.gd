class_name TargetSelect
extends RefCounted
## The selector library: every "which units" question a data effect or a script asks, in one
## place. `spec` is {"select", "of"?, "tribe"?, "not_tribe"?, "other"?, "golden"?, "tier_at_most"?,
## "row"?, "pick"?, "count"?}. Results are in reading order unless `pick` reorders them.


static func pick(spec: Dictionary, world: EffectWorld) -> Array[BoardUnit]:
	var units: Array[BoardUnit] = _filtered(
		_base(str(spec.get("select", "self")), spec, world), spec, world
	)
	var how: String = str(spec.get("pick", ""))
	if how == "":
		return units
	_order(units, how, world.selection_rng(how), CoreUtil.to_int(spec.get("count", 1)))
	var count: int = CoreUtil.to_int(spec.get("count", 1))
	if units.size() > count:
		units.resize(count)
	return units


## The slot a position selector is measured from: the source's, or "of": "subject" or "chosen".
static func _anchor(spec: Dictionary, world: EffectWorld) -> int:
	match str(spec.get("of", "self")):
		"subject":
			return world.subject_slot
		"chosen":
			return world.chosen_slot
	return world.source_slot


static func _base(select: String, spec: Dictionary, world: EffectWorld) -> Array[BoardUnit]:
	var anchor: int = _anchor(spec, world)
	match select:
		"other":
			return _one(world.other)
		"quarry":
			var fighter: CombatUnit = world.source as CombatUnit
			for enemy: BoardUnit in _all(world.enemy):
				var quarry: CombatUnit = enemy as CombatUnit
				if fighter != null and quarry != null and quarry.uid == fighter.quarry:
					return _one(quarry)
			return []
		"mired":
			var stuck: Array[BoardUnit] = []
			for enemy: BoardUnit in _all(world.enemy):
				var fighter: CombatUnit = enemy as CombatUnit
				if fighter != null and fighter.has_status("mired"):
					stuck.append(fighter)
			return stuck
		"self":
			return _one(world.source)
		"subject":
			return _one(world.subject)
		"chosen":
			return _one(world.chosen)
		"friendly":
			return _all(world.own)
		"others":
			return _without(_all(world.own), world.source)
		"enemies":
			return _all(world.enemy)
		"hand":
			return _all(world.hand)
		"shop":
			return _all(world.shop)
		"front_row":
			return _at(world.own, BoardGeometry.FRONT)
		"back_row":
			return _at(world.own, BoardGeometry.BACK)
		"smaller_row":
			return _at(world.own, _smaller_row(world))
		"enemy_front_row":
			return _at(world.enemy, BoardGeometry.FRONT)
		"enemy_back_row":
			return _at(world.enemy, BoardGeometry.BACK)
	return _relative(select, anchor, world)


static func _relative(select: String, anchor: int, world: EffectWorld) -> Array[BoardUnit]:
	if not BoardGeometry.is_valid(anchor):
		return []
	match select:
		"in_front":
			return _at(world.own, BoardGeometry.in_front_of(anchor))
		"behind":
			return _at(world.own, BoardGeometry.behind(anchor))
		"adjacent":
			return _at(world.own, BoardGeometry.adjacent(anchor))
		"neighbours":
			return _at(world.own, BoardGeometry.neighbours(anchor))
		"row":
			return _at(world.own, BoardGeometry.row_of(anchor))
		"row_ends":
			var ends: Array[int] = []
			for slot: int in BoardGeometry.row_of(anchor):
				if BoardGeometry.is_row_end(slot):
					ends.append(slot)
			return _at(world.own, ends)
		"across":
			if world.enemy.is_empty():
				return []
			var slots: Array[int] = [BoardGeometry.across(anchor)]
			return _at(world.enemy, slots)
		"facing":
			return _at(world.enemy, BoardGeometry.in_front_of(anchor))
		"touching":
			return _at(world.own, BoardGeometry.touching(world.occupied_slots(), anchor))
	push_error("Unknown selector '%s'" % select)
	return []


static func _one(unit: BoardUnit) -> Array[BoardUnit]:
	var out: Array[BoardUnit] = []
	if unit != null:
		out.append(unit)
	return out


static func _all(row: Array) -> Array[BoardUnit]:
	var out: Array[BoardUnit] = []
	for entry: Variant in row:
		if entry != null:
			var unit: BoardUnit = entry
			out.append(unit)
	return out


static func _at(row: Array, slots: Array[int]) -> Array[BoardUnit]:
	var out: Array[BoardUnit] = []
	for slot: int in slots:
		if slot < row.size() and row[slot] != null:
			var unit: BoardUnit = row[slot]
			out.append(unit)
	return out


static func _without(units: Array[BoardUnit], unit: BoardUnit) -> Array[BoardUnit]:
	units.erase(unit)
	return units


## Dying units waiting for death resolution can't be picked.
static func _filtered(
	units: Array[BoardUnit], spec: Dictionary, world: EffectWorld
) -> Array[BoardUnit]:
	var out: Array[BoardUnit] = []
	var tribe: String = str(spec.get("tribe", ""))
	var not_tribe: String = str(spec.get("not_tribe", ""))
	var other: bool = CoreUtil.to_bool(spec.get("other", false))
	for unit: BoardUnit in units:
		var taking_self: bool = (
			world.trigger == "on_take" and unit == world.source and unit == world.subject
		)
		if (unit.health <= 0 and not taking_self) or (other and unit == world.source):
			continue
		if tribe != "" and not unit.has_tribe(tribe):
			continue
		if not_tribe != "" and unit.has_tribe(not_tribe):
			continue
		if spec.has("golden") and unit.golden != CoreUtil.to_bool(spec["golden"]):
			continue
		if spec.has("tier_at_most") and unit.tier() > CoreUtil.to_int(spec["tier_at_most"]):
			continue
		if spec.has("row") and not _in_row(unit, str(spec["row"]), world):
			continue
		out.append(unit)
	return out


static func _in_row(unit: BoardUnit, row: String, world: EffectWorld) -> bool:
	var slot: int = world.own.find(unit)
	if slot < 0:
		slot = world.enemy.find(unit)
	return slot >= 0 and BoardGeometry.is_front(slot) == (row == "front")


## 1.2.2: random, and highest or lowest with ties broken at random.
static func _order(
	units: Array[BoardUnit], how: String, rng: RandomNumberGenerator, count: int
) -> void:
	if how == "first":
		return
	if how == "random":
		_shuffle(units, rng)
		return
	var groups: Dictionary = {}
	for unit: BoardUnit in units:
		var score: int = _value(unit, how)
		if not groups.has(score):
			groups[score] = []
		var group: Array = groups[score]
		group.append(unit)
	var scores: Array = groups.keys()
	scores.sort()
	scores.reverse()
	units.clear()
	for score: int in scores:
		var group: Array = groups[score]
		if units.size() < count:
			_shuffle(group, rng)
		for unit: BoardUnit in group:
			units.append(unit)


static func _shuffle(units: Array, rng: RandomNumberGenerator) -> void:
	for index: int in range(units.size() - 1, 0, -1):
		var chosen: int = rng.randi_range(0, index)
		var swap: Variant = units[index]
		units[index] = units[chosen]
		units[chosen] = swap


static func _value(unit: BoardUnit, how: String) -> int:
	match how:
		"biggest":
			return unit.attack + unit.health
		"highest_attack":
			return unit.attack
		"lowest_attack":
			return -unit.attack
		"highest_health":
			return unit.health
		"lowest_health":
			return -unit.health
	return 0


## The row with fewer units; a tie is the back row.
static func _smaller_row(world: EffectWorld) -> Array[int]:
	var front: int = _at(world.own, BoardGeometry.FRONT).size()
	var back: int = _at(world.own, BoardGeometry.BACK).size()
	return BoardGeometry.FRONT if front < back else BoardGeometry.BACK
