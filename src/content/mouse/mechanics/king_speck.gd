extends Mechanic
## King Speck replaces a fallen Mouse with a Cousin carrying that Mouse's own Attack.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func param_kinds() -> Dictionary:
	return {"limit": MechanicParams.Kind.NUMBER}


func after_friendly_death(
	combat: Combat, unit: CombatUnit, dead: CombatUnit, params: MechanicParams
) -> void:
	if (
		unit == null
		or unit == dead
		or not MouseRules.is_mouse(dead.def)
		or combat.unit_at(unit.side, dead.slot) != null
	):
		return
	if MouseRules.charge(combat, unit, &"mouse_king_speck", params.num(&"limit")):
		combat.summon(
			unit.side,
			MouseRules.COUSIN,
			dead.slot,
			true,
			unit,
			{},
			params.golden,
			dead.stats.own_attack()
		)
