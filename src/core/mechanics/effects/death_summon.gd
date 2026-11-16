extends Mechanic
## Own death effect (9.7.2 step 2): summon `count` copies of `card`, the first into this unit's
## slot (8.4.1), the rest by 8.4.2-8.4.4.


func param_kinds() -> Dictionary:
	return {"card": MechanicParams.Kind.TEXT, "count": MechanicParams.Kind.NUMBER}


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if not combat.trigger(unit, &"death_summon"):
		return
	for _i: int in params.num(&"count"):
		combat.summon(unit.side, StringName(params.text(&"card")), unit.slot, true, unit)


func has_death_effect() -> bool:
	return true
