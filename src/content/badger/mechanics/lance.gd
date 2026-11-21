extends Mechanic
## Hedge Lancer: its first attacks take no damage while they resolve (SHARED-RULES 26).

const LANCE: StringName = &"badger_lance"


func param_kinds() -> Dictionary:
	return {"attacks": MechanicParams.Kind.NUMBER}


func text_params(params: MechanicParams) -> Dictionary:
	var count: int = params.num(&"attacks")
	return {
		"when_attacking": "time this attacks" if count == 1 else "%d times this attacks" % count,
	}


func protect_attack(combat: Combat, unit: CombatUnit, params: MechanicParams) -> bool:
	if unit.fight_count(LANCE) >= params.num(&"attacks") or not combat.trigger(unit, LANCE):
		return false
	unit.add_fight_count(LANCE)
	return true
