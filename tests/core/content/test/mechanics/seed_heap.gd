extends Mechanic
## A death in the fight adds to the real heap: a copy of this card goes in.


func on_death(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	if combat.trigger(unit, &"test_seed_heap"):
		combat.bridge(unit.side).heap_add(&"test_heap", unit.def.id, unit.def.tier, unit)
