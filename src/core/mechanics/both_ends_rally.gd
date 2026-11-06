extends Mechanic
## Furrow Racer (library entry 45): whenever the other end of this unit's Both Ends pair pricks an
## attacker of this unit, give your units in this row +`attack` Attack this combat.

const OTHER_END: Dictionary = {0: 3, 3: 0, 4: 6, 6: 4}


func on_attack_declared(
	combat: Combat, unit: CombatUnit, params: Dictionary, attacker: CombatUnit, defender: CombatUnit
) -> void:
	if defender != unit or attacker.side == unit.side or not OTHER_END.has(unit.slot):
		return
	var other: CombatUnit = combat.unit_at(unit.side, CoreUtil.to_int(OTHER_END[unit.slot]))
	if other == null or not other.has_mechanic("both_ends"):
		return
	combat.trigger(unit, "both_ends_rally")
	var row: Array[int] = (
		BoardGeometry.FRONT if BoardGeometry.is_front(unit.slot) else BoardGeometry.BACK
	)
	for slot: int in row:
		var mate: CombatUnit = combat.unit_at(unit.side, slot)
		if mate != null:
			combat.buff(mate, CoreUtil.to_int(params.get("attack", 0)), 0, unit)
