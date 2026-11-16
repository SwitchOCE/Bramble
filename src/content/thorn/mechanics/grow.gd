extends Mechanic
## Grow N: Start of fight (main pass): gain +N/+N for every 2 units in your Compost, this fight.
## Grow from several sources adds up before the trigger: the first Grow on the unit gains the
## total. Units that arrive later don't Grow (the core runs only units there when it began).

const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var hooks: Array[BoundMechanic] = unit.hooks()
	if not Compost.is_first(hooks, &"thorn_grow", params):
		return
	@warning_ignore("integer_division")
	var pairs: int = combat.bridge(unit.side).heap(Compost.HEAP).size() / 2
	var gain: int = Compost.total(hooks, &"thorn_grow", &"amount") * pairs
	if gain > 0 and combat.trigger(unit, &"thorn_grow"):
		combat.buff(unit, gain, gain, unit)
