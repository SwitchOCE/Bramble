extends Mechanic
## Mark (X) (library entry 40): Start of Combat, mark the enemy slot across from this. For the
## rest of combat each enemy unit that enters that slot takes `damage`; the unit already there
## is not hurt. Combat deals the damage when a unit enters the slot.


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	combat.trigger(unit, "mark")
	combat.add_mark(
		unit,
		1 - unit.side,
		BoardGeometry.across(unit.slot),
		CoreUtil.to_int(params.get("damage", 0))
	)
