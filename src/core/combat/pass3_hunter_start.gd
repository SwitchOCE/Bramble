class_name Pass3HunterStart
extends RefCounted
## Across identities are fixed at the bell; the biggest hunt waits for the settled opening.


static func late(id: String, params: Dictionary) -> bool:
	return id == "pass3_hunter" and str(params.get("ability", "")) in ["isegrim", "old_brock"]


static func begin_dispatch(unit: CombatUnit) -> void:
	unit.limits.erase("hunter_sable_applied")
	unit.limits.erase("ooze_start_hasty_pudding")
	unit.limits.erase("ooze_start_granny_stir_up")


static func sable(combat: Combat, unit: CombatUnit) -> void:
	if not Pass3HunterCombat.has(unit, "sable"):
		return
	if Pass3HunterCombat.guards(combat) and unit.limits.has("hunter_sable_applied"):
		return
	var quarry: CombatUnit = Pass3HunterCombat.target(combat, unit.quarry)
	if quarry == null:
		return
	unit.limits["hunter_sable_applied"] = true
	var snap: Dictionary = Pass3HunterCombat.prey(combat, quarry)
	var strike: int = floori(
		(
			CoreUtil.to_int(snap["attack"])
			* Pass3HunterCombat.rate(combat, unit, "sable", "sable_strike")
		)
	)
	combat.trigger(unit, "pass3_hunter:sable")
	combat.buff(unit, strike, 0, unit, false, "Sable")


static func finish_marks(combat: Combat) -> void:
	if not combat.notes.get("hunter_active", false):
		return
	# Own biggest hunts precede every new loan, independent of the random opening side.
	for side: int in 2:
		for unit: CombatUnit in combat.units_of(side):
			if (
				not Pass3HunterCombat.has(unit, "isegrim")
				or unit.is_dead()
				or not _starting_source(combat, unit)
			):
				continue
			if unit.quarry == 0:
				var enemies: Array[CombatUnit] = []
				for enemy: CombatUnit in Pass3Combat.enemies(combat, side):
					if not enemy.is_dead() and enemy.def_id() != HeldUnits.EGG:
						enemies.append(enemy)
				enemies = Pass3Combat.prefer_original_enemies(enemies, side)
				var biggest: Array[CombatUnit] = Pass3Combat.biggest(enemies)
				if not biggest.is_empty():
					CombatLanes._mark(combat, unit, biggest[0], unit)
					unit.quarry_reach = true
	# Lenders compete in reading order; all loans are Hunter-only under amendment 2.
	for side: int in 2:
		for source: CombatUnit in combat.units_of(side):
			if source.is_dead() or not _starting_source(combat, source):
				continue
			if Pass3HunterCombat.has(source, "isegrim"):
				_lend(
					combat,
					source,
					Pass3HunterCombat.target(combat, source.quarry),
					Pass3HunterCombat.factor(source, "isegrim") > 1
				)
			if Pass3HunterCombat.has(source, "old_brock"):
				var across: Dictionary = combat.notes.get("hunter_across", {})
				_lend(
					combat,
					source,
					Pass3HunterCombat.target(combat, CoreUtil.to_int(across.get(source.uid, 0))),
					true
				)
	# A Sable with an empty across slot may only now have received her quarry.
	for side: int in 2:
		for unit: CombatUnit in combat.units_of(side):
			if not unit.is_dead() and not unit.limits.has("hunter_sable_applied"):
				sable(combat, unit)


static func _starting_source(combat: Combat, unit: CombatUnit) -> bool:
	var initial: Array = combat.notes.get("hunter_initial", [[], []])
	var first: Array = initial[0]
	var second: Array = initial[1]
	return unit.copied_this_fight or first.has(unit) or second.has(unit)


static func _lend(combat: Combat, source: CombatUnit, quarry: CombatUnit, wide: bool) -> void:
	if quarry == null or quarry.is_dead() or quarry.side == source.side:
		return
	var slots: Array[int] = (
		BoardGeometry.neighbours(source.slot) if wide else BoardGeometry.adjacent(source.slot)
	)
	for slot: int in slots:
		var hunter: CombatUnit = combat.unit_at(source.side, slot)
		if (
			hunter == null
			or hunter.is_dead()
			or not hunter.has_tribe("Hunters")
			or hunter.quarry != 0
		):
			continue
		CombatLanes._mark(combat, hunter, quarry, source)
		hunter.quarry_reach = true
		combat.trigger(source, "pass3_hunter:lend")
	var cut: float = Pass3Rates.number(combat.config, "hunters_isegrim_health_cut")
	if cut > 0 and Pass3HunterCombat.has(source, "isegrim"):
		var loss: int = mini(maxi(0, quarry.health - 1), floori(quarry.health * cut))
		if quarry.on_board:
			CombatMoves.lose_health(combat, quarry, loss, "Isegrim")
		else:
			quarry.lose_health(loss)
