extends Mechanic
## Count the Mice once and put the buff on those units.


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if not combat.trigger(unit, &"mouse_standard_bearer"):
		return
	var mice: Array[CombatUnit] = combat.units(unit.side).filter(
		func(friend: CombatUnit) -> bool: return friend.def.has_tribe("Mouse")
	)
	var bonus: int = mice.size() * params.num(&"attack")
	for friend: CombatUnit in mice:
		combat.buff(friend, bonus, 0, unit)
