extends Mechanic
## Weasel Second (library entry 24): Start of Combat, the units in front of this gain First Bite
## this combat ("the unit in front" becomes "the units in front" in the 4-3 brick, SPEC 4.2).


func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: Dictionary) -> void:
	var targets: Array[CombatUnit] = []
	for slot: int in BoardGeometry.in_front_of(unit.slot):
		var other: CombatUnit = combat.unit_at(unit.side, slot)
		if other != null:
			targets.append(other)
	if targets.is_empty():
		return
	combat.trigger(unit, "grant_first_bite_in_front")
	for other: CombatUnit in targets:
		combat.set_status(other, "first_bite", true, unit)
