extends Mechanic
## Start of Combat, reading the real heap: +amount/+amount for each entry, this fight.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var size: int = combat.bridge(unit.side).heap(&"test_heap").size()
	if size > 0 and combat.trigger(unit, &"test_grow"):
		var amount: int = params.num(&"amount") * size
		combat.buff(unit, amount, amount, unit)
