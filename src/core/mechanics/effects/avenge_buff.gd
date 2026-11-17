extends Mechanic
## A death counter (9.7.4, like HSBG's Avenge): each time `every` friendly units have died this
## combat, give all friendly units +attack/+health this combat. `every` is a threshold, so a
## golden copy keeps it (7.3.5).

const COUNT: StringName = &"avenge_count"


func param_kinds() -> Dictionary:
	return {
		"every": MechanicParams.Kind.THRESHOLD,
		"attack": MechanicParams.Kind.NUMBER,
		"health": MechanicParams.Kind.NUMBER,
	}


func on_friendly_death(
	combat: Combat, unit: CombatUnit, _dead: CombatUnit, params: MechanicParams
) -> void:
	var count: int = unit.state_int(COUNT) + 1
	unit.set_state(COUNT, count)
	var every: int = maxi(1, params.num(&"every"))
	if count % every != 0 or not combat.trigger(unit, &"avenge_buff"):
		return
	for friend: CombatUnit in combat.select(unit, "all"):
		combat.buff(friend, params.num(&"attack"), params.num(&"health"), unit)
