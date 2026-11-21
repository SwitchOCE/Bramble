extends Mechanic
## Wing Commander gives permanent Renown to a friendly Sortie Pigeon's slot after it kills.

const SORTIE: StringName = &"pigeon_sortie"
const WING: StringName = &"pigeon_wing_commander"


func param_kinds() -> Dictionary:
	return {"limit": MechanicParams.Kind.NUMBER, "amount": MechanicParams.Kind.NUMBER}


func on_kill(combat: Combat, unit: CombatUnit, victim: CombatUnit, params: MechanicParams) -> void:
	on_friendly_kill(combat, unit, unit, victim, params)


func on_friendly_kill(
	combat: Combat,
	unit: CombatUnit,
	killer: CombatUnit,
	_victim: CombatUnit,
	params: MechanicParams
) -> void:
	var limit: int = params.num(&"limit")
	if (
		unit == null
		or unit.fight_count(WING) >= limit
		or not killer.def.has_tribe("Pigeon")
		or not killer.has_mechanic(SORTIE)
		or not combat.trigger(unit, WING)
	):
		return
	unit.add_fight_count(WING)
	combat.bridge(unit.side).add_renown(killer.slot, params.num(&"amount"), unit)
	combat.show_uses(unit, &"pigeon_wing_commander_uses", limit - unit.fight_count(WING), unit)
