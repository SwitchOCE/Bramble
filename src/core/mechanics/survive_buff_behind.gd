extends Mechanic
## Sett Warden (library entry 1): whenever this survives being attacked (still on the board after
## that attack's death resolution, SPEC 4.2), the units behind this gain +`attack` Attack this
## combat.


func on_survived_attack(
	combat: Combat, unit: CombatUnit, params: Dictionary, _attacker: CombatUnit
) -> void:
	var behind: Array[CombatUnit] = []
	for slot: int in BoardGeometry.behind(unit.slot):
		var other: CombatUnit = combat.unit_at(unit.side, slot)
		if other != null:
			behind.append(other)
	if behind.is_empty():
		return
	combat.trigger(unit, "survive_buff_behind")
	for other: CombatUnit in behind:
		combat.buff(other, CoreUtil.to_int(params.get("attack", 0)), 0, unit)
