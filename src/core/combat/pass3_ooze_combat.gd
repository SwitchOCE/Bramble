class_name Pass3OozeCombat
extends RefCounted
## Ooze combat dependencies and releases; recruit eating lives in Pass3Oozes.


static func ability(unit: CombatUnit, index: int) -> String:
	return (
		str(unit.params[index].get("ability", ""))
		if unit.mechanic_ids[index] == "pass3_ooze"
		else ""
	)


static func has(unit: CombatUnit, name: String) -> bool:
	for index: int in unit.scripts.size():
		if ability(unit, index) == name:
			return true
	return false


static func start(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var ability_name: String = str(params.get("ability", ""))
	if ability_name not in ["hasty_pudding", "granny_stir_up"]:
		return
	if combat.config.get_value("pass3_loop_guards") != false:
		var key: String = "ooze_start_" + ability_name
		if unit.limits.has(key):
			return
		unit.limits[key] = true
		params = strongest(unit, ability_name, params)
	match ability_name:
		"hasty_pudding":
			_hasty(combat, unit, params)
		"granny_stir_up":
			_granny(combat, unit, params)


## Printed plus meal-borrowed instances compete before either one changes the board.
static func strongest(unit: CombatUnit, ability_name: String, fallback: Dictionary) -> Dictionary:
	var best: Dictionary = fallback
	for index: int in unit.scripts.size():
		if ability(unit, index) != ability_name:
			continue
		var candidate: Dictionary = unit.params[index]
		if _strength(candidate, ability_name) > _strength(best, ability_name):
			best = candidate
	return best


static func _strength(params: Dictionary, ability_name: String) -> float:
	if ability_name == "hasty_pudding":
		return (
			CoreUtil.to_int(params.get("count", 1)) * 1000.0
			+ CoreUtil.to_float(params.get("share", 0.2))
		)
	return (
		CoreUtil.to_int(params.get("factor", 1))
		* CoreUtil.to_float(params.get("attack_multiplier", 1.0))
	)


static func death(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	if str(params.get("ability", "")) != "mrs_posset":
		return
	var killer: CombatUnit = CombatLanes.by_uid(combat, unit.killed_by)
	if killer == null or killer.side == unit.side or killer.is_dead():
		return
	var targets: Array[CombatUnit] = [killer]
	if CoreUtil.to_int(params.get("factor", 1)) > 1:
		for slot: int in BoardGeometry.adjacent(killer.slot):
			var target: CombatUnit = combat.unit_at(killer.side, slot)
			if target != null and not target.is_dead():
				targets.append(target)
	combat.trigger(unit, "mrs_posset")
	var share: float = CoreUtil.to_float(params.get("loss_share", 0.5))
	for target: CombatUnit in targets:
		combat.buff(
			target,
			-floori(target.attack * share),
			-maxi(0, mini(target.health - 1, floori(target.health * share))),
			unit
		)


static func friendly_death(
	combat: Combat, unit: CombatUnit, params: Dictionary, dead: CombatUnit
) -> void:
	if str(params.get("ability", "")) != "hasty_pudding":
		return
	if combat.config.get_value("pass3_loop_guards") != false:
		var key: String = "ooze_hasty_death_%d" % dead.uid
		if unit.limits.has(key):
			return
		unit.limits[key] = true
	var seen: int = CoreUtil.to_int(unit.counters.get("pass3_hasty_deaths", 0)) + 1
	unit.counters["pass3_hasty_deaths"] = seen
	if seen >= CoreUtil.to_int(params.get("after", 3)) and not unit.inside.is_empty():
		combat.trigger(unit, "hasty_release")
		CombatHeld.return_inside(combat, unit)


static func emerged(
	combat: Combat, fighter: CombatUnit, holder: CombatUnit, fields: Dictionary
) -> void:
	if holder == null or holder.side != fighter.side or not holder.has_tribe("Oozes"):
		return
	if not fields.get("came_out", false) and not fields.get("wobbly_drip", false):
		return
	for source: CombatUnit in combat.units_of(fighter.side):
		if source.is_dead():
			continue
		for index: int in source.scripts.size():
			if ability(source, index) != "moss_ooze":
				continue
			combat.trigger(source, "moss_ooze")
			combat.set_status(fighter, "shield", true, source)
			var params: Dictionary = source.params[index]
			if CoreUtil.to_int(params.get("factor", 1)) > 1:
				var reduction: int = CoreUtil.to_int(params.get("reduction", 25))
				fighter.counters["ooze_reduction"] = maxi(
					CoreUtil.to_int(fighter.counters.get("ooze_reduction", 0)), reduction
				)
				combat.set_status(fighter, "damage_reduction", true, source, {"percent": reduction})


static func _hasty(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	if not unit.held_specs.is_empty() or not unit.inside.is_empty():
		return
	var count: int = mini(CombatHeld.room(unit), CoreUtil.to_int(params.get("count", 1)))
	for _index: int in count:
		var candidates: Array[CombatUnit] = Pass3Combat.prefer_original_enemies(
			Pass3Combat.enemies(combat, unit.side), unit.side
		)
		var targets: Array[CombatUnit] = Pass3Combat.biggest(candidates)
		if targets.is_empty():
			break
		var target: CombatUnit = targets[0]
		var container: CombatUnit = _container(combat, target)
		if container == null:
			break
		# Read the selected enemy's current stats before swallowing changes its aura membership.
		var share: float = CoreUtil.to_float(params.get("share", 0.2))
		var attack: int = floori(target.attack * share)
		var health: int = floori(target.health * share)
		var biggest: Array[CombatUnit] = Pass3Combat.biggest(
			Pass3Combat.tribe(combat, unit.side, "Oozes")
		)
		combat.trigger(unit, "hasty_pudding")
		CombatHeld.swallow(combat, unit, container)
		if not biggest.is_empty():
			combat.buff(biggest[0], attack, health, unit, true)
	CombatHeld.check_sides(combat)


static func _granny(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var gain: int = 0
	for slot: int in BoardGeometry.touching(combat._occupied(unit.side), unit.slot):
		var other: CombatUnit = combat.unit_at(unit.side, slot)
		if other == null or other == unit or not other.has_tribe("Oozes"):
			continue
		gain += other.attack
		CombatHeld.swallow(combat, unit, other)
	if gain > 0:
		combat.trigger(unit, "granny_stir_up")
		combat.buff(
			unit,
			(
				floori(gain * CoreUtil.to_float(params.get("attack_multiplier", 1.0)))
				* CoreUtil.to_int(params.get("factor", 1))
			),
			0,
			unit
		)


static func _container(combat: Combat, target: CombatUnit) -> CombatUnit:
	if target.on_board:
		return target
	for holder: CombatUnit in combat.units_of(target.side):
		if Pass3Combat._holds(holder, target):
			return holder
	return null


## The half keeps current printed, granted and borrowed words; it receives no Belly contents.
static func split_copy(
	combat: Combat, unit: CombatUnit, spec: Dictionary, slot: int, limit: int, guarded: bool
) -> void:
	var copy := CombatUnit.make(unit.def, spec, combat._next_uid, unit.side)
	combat._next_uid += 1
	copy.slot = slot
	Pass3FairyCombat._copy_text(copy, unit)
	copy.borrowed_rules = unit.borrowed_rules.duplicate(true)
	if guarded:
		copy.counters["split"] = limit
		copy.counters["pass3_bubble_half"] = 1
	else:
		copy.counters.erase("split")
	combat._apply_slot_grants(copy)
	combat.enter_board(copy, unit, {"split": true, "copied": unit.uid})


## Replay-only damage variant: a unit that began inside counts once if still alive.
static func mark_starting_held(holder: CombatUnit) -> void:
	holder.held_specs = holder.held_specs.duplicate(true)
	for spec: Dictionary in holder.held_specs:
		spec["replay_starting_belly_survivor"] = true
		var inner: Array = spec.get("held", [])
		_mark_specs(inner)


static func _mark_specs(specs: Array) -> void:
	for spec: Dictionary in specs:
		spec["replay_starting_belly_survivor"] = true
		var inner: Array = spec.get("held", [])
		_mark_specs(inner)


static func held_survivors(combat: Combat, side: int) -> int:
	var count: int = 0
	for board: int in 2:
		for holder: CombatUnit in combat.units_of(board):
			count += _held_survivors(holder, side)
	return count


static func _held_survivors(holder: CombatUnit, side: int) -> int:
	var count: int = 0
	for spec: Dictionary in holder.held_specs:
		var fighter: CombatUnit = spec.get("_pass3_fighter")
		if fighter != null:
			if _starting_alive(fighter, side):
				count += 1
			count += _held_survivors(fighter, side)
		elif (
			holder.side == side
			and CoreUtil.to_bool(spec.get("replay_starting_belly_survivor", false))
		):
			count += 1
	for fighter: CombatUnit in holder.inside:
		if _starting_alive(fighter, side):
			count += 1
		count += _held_survivors(fighter, side)
	return count


static func _starting_alive(unit: CombatUnit, side: int) -> bool:
	return (
		unit.side == side
		and not unit.is_dead()
		and not unit.copied_this_fight
		and CoreUtil.to_bool(unit.counters.get("replay_starting_belly_survivor", false))
	)
