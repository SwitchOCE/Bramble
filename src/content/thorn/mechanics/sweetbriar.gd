extends Mechanic
## Whenever a unit goes into your Compost, gain +N/+N permanently (Sweetbriar). Every entry, in
## either phase: a sale, a Bury, a Seed, a Thorns kill with Lone Hawthorn. In a fight the gain is
## on the unit in the fight and on the recruit board at once.

const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_heap_added(
	ctx: RecruitContext, unit: Unit, heap: StringName, _card_id: StringName, params: MechanicParams
) -> void:
	if unit == null or heap != Compost.HEAP or not ctx.trigger(unit, &"thorn_sweetbriar"):
		return
	var amount: int = params.num(&"amount")
	ctx.buff(unit, amount, amount, true, unit)


func on_heap_added_in_fight(
	combat: Combat, unit: CombatUnit, heap: StringName, _card_id: StringName, params: MechanicParams
) -> void:
	if unit == null or heap != Compost.HEAP or not combat.trigger(unit, &"thorn_sweetbriar"):
		return
	var amount: int = params.num(&"amount")
	combat.buff(unit, amount, amount, unit, true)
