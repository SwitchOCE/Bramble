extends Mechanic
## Hedge Lancer: Start of fight (main pass): this attacks immediately and takes no damage from
## anything while that attack resolves (SHARED-RULES 26). Its later attacks are normal.


func param_kinds() -> Dictionary:
	return {"attacks": MechanicParams.Kind.NUMBER}


func text_params(params: MechanicParams) -> Dictionary:
	return {"attack_repeats": UnitText.repeat_suffix(params.num(&"attacks"))}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if combat.trigger(unit, &"badger_lance"):
		for _i: int in params.num(&"attacks"):
			if not combat.attack_now(unit, null, true):
				break
