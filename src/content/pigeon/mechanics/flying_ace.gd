extends Mechanic


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER, "limit": MechanicParams.Kind.THRESHOLD}


func on_kill(combat: Combat, unit: CombatUnit, _victim: CombatUnit, params: MechanicParams) -> void:
	const ID: StringName = &"pigeon_flying_ace"
	if unit.fight_count(ID) < params.num(&"limit") and combat.trigger(unit, ID):
		unit.add_fight_count(ID)
		combat.bridge(unit.side).add_renown(unit.slot, params.num(&"amount"), unit)
