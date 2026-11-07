extends Mechanic
## The Gabble Ratchet: when a unit on a Nest dies (an Egg too), its bird lands there for this fight
## with its own stats. Golden: double Attack.


func hears_allies(_params: Dictionary) -> bool:
	return true


func on_friendly_death(
	combat: Combat, unit: CombatUnit, params: Dictionary, dead: CombatUnit
) -> void:
	var nest: Dictionary = CombatHeld.nest_at(combat, unit.side, dead.slot)
	if not nest.is_empty():
		CombatHeld.land_bird(
			combat, unit, nest, dead.slot, CoreUtil.to_int(params.get("factor", 1))
		)
