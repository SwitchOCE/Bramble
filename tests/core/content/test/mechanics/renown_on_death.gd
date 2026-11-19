extends Mechanic
## After a friendly unit dies, give its slot 1 Renown (FightSide.add_renown: from the next fight).


func after_friendly_death(
	combat: Combat, unit: CombatUnit, dead: CombatUnit, _params: MechanicParams
) -> void:
	if unit != null and combat.trigger(unit, &"test_renown_on_death"):
		combat.bridge(unit.side).add_renown(dead.slot, 1, unit)
