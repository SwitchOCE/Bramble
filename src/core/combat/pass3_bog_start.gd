class_name Pass3BogStart
extends RefCounted
## Bog's dependent opening runs after ordinary buffs, before the remaining late answers.


static func dependent(id: String, params: Dictionary) -> bool:
	return id == "pass3_bog" and str(params.get("ability", "")) in ["lantern", "jenny", "sal"]


static func invoke(combat: Combat, unit: CombatUnit, name: String) -> void:
	if name not in ["lantern", "jenny", "sal"]:
		return
	match name:
		"lantern":
			_lantern(combat, unit)
		"jenny":
			_jenny(combat, unit)
		"sal":
			_sal(combat, unit)


static func stage(combat: Combat, first: int, name: String) -> void:
	for side: int in [first, 1 - first]:
		for unit: CombatUnit in combat.units_of(side):
			if Pass3BogCombat.has(unit, name) and not unit.is_dead():
				invoke(combat, unit, name)
				combat._resolve_deaths(side)
				combat.reactions.drain(combat)


static func patches(combat: Combat) -> void:
	if not combat.notes.get("bog_active", false):
		return
	for side: int in 2:
		for unit: CombatUnit in combat.units_of(side):
			if not Pass3BogCombat.has_mire(combat, unit):
				continue
			var across: int = BoardGeometry.across(unit.slot)
			CombatLanes._patch(combat, unit, across)
			var mire: Dictionary = CombatLanes.parameters(unit, "mire")
			if mire.get("spread", false):
				var count: int = maxi(
					1, Pass3Rates.integer(combat.config, "bog_prima_donna_patches")
				)
				for slot: int in BoardGeometry.adjacent(across):
					if count <= 1:
						break
					CombatLanes._patch(combat, unit, slot)
					count -= 1
	CombatLanes.sync_mire(combat)
	combat._recalc_auras(true)


static func _candidates(combat: Combat, source: CombatUnit, row_only: bool) -> Array[CombatUnit]:
	var candidates: Array[CombatUnit] = []
	var reserved: Array = combat.notes.get("bog_lantern_targets", [])
	for enemy: CombatUnit in Pass3Combat.enemies(combat, source.side):
		if enemy.is_dead() or (row_only and not BoardGeometry.row_of(source.slot).has(enemy.slot)):
			continue
		if row_only and reserved.has(enemy.uid):
			continue
		candidates.append(enemy)
	return Pass3Combat.prefer_original_enemies(candidates, source.side)


static func _lantern(combat: Combat, source: CombatUnit) -> void:
	var count: int = roundi(Pass3BogCombat.rate(combat, source, "lantern", "lantern_lures"))
	var targets: Array[CombatUnit] = Pass3Combat.biggest(_candidates(combat, source, false), count)
	var reserved: Array = combat.notes.get("bog_lantern_targets", [])
	for target: CombatUnit in targets:
		reserved.append(target.uid)
		combat.trigger(source, "pass3_bog:lantern")
		if target.on_board:
			CombatLanes._patch(combat, source, target.slot)
		else:
			_defer(combat, source, target, "lantern")
	combat.notes["bog_lantern_targets"] = reserved
	CombatLanes.sync_mire(combat)


static func _jenny(combat: Combat, source: CombatUnit) -> void:
	var count: int = Pass3Rates.integer(combat.config, "bog_jenny_pulls")
	for target: CombatUnit in Pass3Combat.biggest(_candidates(combat, source, true), count):
		combat.trigger(source, "pass3_bog:jenny")
		if target.on_board:
			_pull(combat, source, target)
		else:
			_defer(combat, source, target, "jenny")


static func _pull(combat: Combat, source: CombatUnit, target: CombatUnit) -> void:
	var destination: int = BoardGeometry.across(source.slot)
	var origin: int = target.slot
	if destination == origin:
		return
	var row: Array = combat.sides[target.side]
	var other: CombatUnit = combat.unit_at(target.side, destination)
	row[destination] = target
	row[origin] = other
	target.slot = destination
	combat.emit_event("relocate", {"uid": target.uid, "side": target.side, "slot": destination})
	if other != null:
		other.slot = origin
		combat.emit_event("relocate", {"uid": other.uid, "side": other.side, "slot": origin})
	combat.emit_event("bog_pull", {"source": source.uid, "target": target.uid})
	CombatLanes.sync_mire(combat)
	combat._recalc_auras(true)


static func _defer(combat: Combat, source: CombatUnit, target: CombatUnit, name: String) -> void:
	var pending: Array = combat.notes.get("bog_pending_targets", [])
	pending.append({"source": source, "target": target, "ability": name})
	combat.notes["bog_pending_targets"] = pending
	combat.emit_event("bog_bind", {"source": source.uid, "target": target.uid, "ability": name})


static func entered(combat: Combat, unit: CombatUnit) -> void:
	if not combat.notes.get("bog_active", false):
		return
	if Pass3BogCombat.has(unit, "frog"):
		unit.counters["kisses"] = combat.notes.get("bog_kisses", [0, 0])[unit.side]
		unit.counters["bog_kiss_period"] = Pass3Rates.integer(combat.config, "bog_kiss_period")
	var pending: Array = combat.notes.get("bog_pending_targets", [])
	var retained: Array = []
	for entry: Dictionary in pending:
		var source: CombatUnit = entry["source"]
		if entry["target"] != unit:
			retained.append(entry)
			continue
		if not source.on_board or source.is_dead() or source.side == unit.side:
			continue
		if str(entry["ability"]) == "lantern":
			CombatLanes._patch(combat, source, unit.slot)
		else:
			_pull(combat, source, unit)
	combat.notes["bog_pending_targets"] = retained
	CombatLanes.sync_mire(combat)
	_starting(unit)


static func snapshot(combat: Combat) -> void:
	if not combat.notes.get("bog_active", false):
		return
	for side: int in 2:
		for unit: CombatUnit in Pass3Combat.enemies(combat, side):
			_starting(unit)


static func _starting(unit: CombatUnit) -> void:
	unit.counters["bog_start_attack"] = unit.attack
	unit.counters["bog_start_health"] = unit.max_health


static func _sal(combat: Combat, source: CombatUnit) -> void:
	var targets: Array[CombatUnit] = []
	for enemy: CombatUnit in combat.units_of(1 - source.side):
		if enemy.has_status("mired"):
			targets.append(enemy)
	if targets.is_empty():
		return
	var rules: Dictionary = combat.side_rules[source.side]
	var toll: int = CoreUtil.to_int(rules.get("bog_toll", 0))
	var share: int = floori(
		toll * Pass3BogCombat.rate(combat, source, "sal", "sal_toll_multiplier") / targets.size()
	)
	combat.trigger(source, "pass3_bog:sal")
	for target: CombatUnit in targets:
		combat.deal_effect_damage(source, target, share)
