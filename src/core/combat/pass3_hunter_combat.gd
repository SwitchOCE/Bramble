class_name Pass3HunterCombat
extends RefCounted
## Immutable prey prices and initial witnesses belong to the fight, not its changing slots.


static func factor(unit: CombatUnit, name: String) -> int:
	var result: int = 0
	for index: int in unit.params.size():
		if (
			unit.mechanic_ids[index] == "pass3_hunter"
			and str(unit.params[index].get("ability", "")) == name
		):
			result = maxi(
				result, CoreUtil.to_int(unit.params[index].get("factor", unit.golden_factor()))
			)
	return result


static func has(unit: CombatUnit, name: String) -> bool:
	return factor(unit, name) > 0


static func guards(combat: Combat) -> bool:
	return combat.config.get_bool("pass3_loop_guards")


static func triggers(combat: Combat, unit: CombatUnit, name: String) -> int:
	if guards(combat):
		return 1 if has(unit, name) else 0
	var count: int = 0
	for index: int in unit.params.size():
		if (
			unit.mechanic_ids[index] == "pass3_hunter"
			and str(unit.params[index].get("ability", "")) == name
		):
			count += 1
	return count


static func rate(combat: Combat, unit: CombatUnit, name: String, key: String) -> float:
	var golden: bool = factor(unit, name) > 1
	if golden and Pass3Rates.defaults().has("hunters_golden_" + key):
		return Pass3Rates.number(combat.config, "hunters_golden_" + key)
	var value: float = Pass3Rates.number(combat.config, "hunters_" + key)
	if golden and key.ends_with("_share"):
		value *= Pass3Rates.number(combat.config, "hunters_golden_take_multiplier")
	return value


static func prepare(combat: Combat) -> void:
	if combat.notes.has("hunter_prepared"):
		return
	combat.notes["hunter_prepared"] = true
	var initial: Array = [combat.units_of(0), combat.units_of(1)]
	var active: bool = false
	for side: int in 2:
		for unit: CombatUnit in initial[side]:
			active = (
				active or unit.has_mechanic("pass3_hunter") or _held_native(combat, unit.held_specs)
			)
	combat.notes["hunter_active"] = active
	if active:
		combat.notes["hunter_initial"] = initial
		combat.notes["hunter_prey"] = {}
		combat.notes["hunter_targets"] = {}
		combat.notes["hunter_marked"] = [[], []]


static func _held_native(combat: Combat, specs: Array) -> bool:
	for spec: Dictionary in specs:
		var definition: Dictionary = combat.library.get_unit(str(spec.get("def_id", "")))
		for entry: Dictionary in definition.get("mechanics", []):
			if str(entry.get("id", "")) == "pass3_hunter":
				return true
		var held: Array = spec.get("held", [])
		if _held_native(combat, held):
			return true
	return false


static func bell(combat: Combat) -> void:
	if not combat.notes.get("hunter_active", false):
		return
	var across: Dictionary = {}
	for side: int in 2:
		for unit: CombatUnit in combat.units_of(side):
			var enemy: CombatUnit = combat.unit_at(1 - side, BoardGeometry.across(unit.slot))
			across[unit.uid] = 0 if enemy == null else enemy.uid
		var enemies: Array[CombatUnit] = Pass3Combat.enemies(combat, side)
		for rank: int in enemies.size():
			_snapshot(combat, enemies[rank], rank)
	combat.notes["hunter_across"] = across


static func entered(combat: Combat, unit: CombatUnit) -> void:
	if combat.notes.get("hunter_active", false):
		_snapshot(combat, unit)


static func _snapshot(combat: Combat, unit: CombatUnit, rank: int = -1) -> void:
	var snapshots: Dictionary = combat.notes.get("hunter_prey", {})
	if snapshots.has(unit.uid):
		return
	snapshots[unit.uid] = {
		"id": unit.def_id(),
		"name": str(unit.def.get("name", "")),
		"attack": unit.attack,
		"health": unit.health,
		"perm_attack": unit.perm_attack,
		"perm_health": unit.perm_health,
		"pool": CoreUtil.to_bool(unit.def.get("pool", false)),
		"tier": unit.tier()
	}
	snapshots[unit.uid]["reading_rank"] = BoardGeometry.SLOTS + unit.uid if rank < 0 else rank
	var targets: Dictionary = combat.notes.get("hunter_targets", {})
	targets[unit.uid] = unit
	combat.notes["hunter_prey"] = snapshots
	combat.notes["hunter_targets"] = targets


static func prey(combat: Combat, unit: CombatUnit) -> Dictionary:
	var snapshots: Dictionary = combat.notes.get("hunter_prey", {})
	return snapshots.get(
		unit.uid,
		{
			"id": unit.def_id(),
			"name": str(unit.def.get("name", "")),
			"attack": unit.attack,
			"health": unit.max_health,
			"perm_attack": unit.perm_attack,
			"perm_health": unit.perm_health,
			"pool": CoreUtil.to_bool(unit.def.get("pool", false)),
			"tier": unit.tier()
		}
	)


static func target(combat: Combat, uid: int) -> CombatUnit:
	var targets: Dictionary = combat.notes.get("hunter_targets", {})
	return targets.get(uid)


static func marked(combat: Combat, hunter: CombatUnit, quarry: CombatUnit) -> void:
	if not combat.notes.get("hunter_active", false):
		return
	var rows: Array = combat.notes.get("hunter_marked", [[], []])
	var marks: Array = rows[hunter.side]
	if not marks.has(quarry.uid):
		marks.append(quarry.uid)
	combat.notes["hunter_marked"] = rows


static func shares(combat: Combat, snapshot: Dictionary, share: float) -> Vector2i:
	var minimum: int = Pass3Rates.integer(combat.config, "hunters_take_floor")
	return Vector2i(
		maxi(minimum, floori(CoreUtil.to_int(snapshot.get("attack", 0)) * share)),
		maxi(minimum, floori(CoreUtil.to_int(snapshot.get("health", 0)) * share))
	)


static func gain(
	combat: Combat,
	unit: CombatUnit,
	snapshot: Dictionary,
	share: float,
	source: CombatUnit,
	cause: String
) -> void:
	var amount: Vector2i = shares(combat, snapshot, share)
	if Pass3Rates.enabled(combat.config, "hunters_trophies_after_fight"):
		PendingGains.queue(combat, unit, amount.x, amount.y, source, cause)
	else:
		combat.buff(unit, amount.x, amount.y, source, true, cause)


static func reduce_hit(combat: Combat, hit: Hit) -> void:
	if not combat.notes.get("hunter_active", false) or hit.kind != Hit.ATTACK or hit.on_defender:
		return
	if hit.target != combat.reactions.current_attacker or combat.reactions.pack_joiners.is_empty():
		return
	var keep: float = 1.0
	for unit: CombatUnit in combat.units_of(hit.target.side):
		if has(unit, "agnes") and not unit.is_dead():
			keep = minf(keep, rate(combat, unit, "agnes", "agnes_hit_back"))
	if keep < 1.0:
		hit.amount = ceili(hit.amount * maxf(0.0, keep))
		hit.modifiers.append("Grey Agnes")


static func lethal(combat: Combat, hit: Hit) -> void:
	if combat.notes.get("hunter_active", false):
		hit.target.counters["hunter_attack_lethal"] = (
			1 if hit.kind == Hit.ATTACK and hit.on_defender else 0
		)
