extends Mechanic
## A player number raised in a fight that lasts the game: +1 "tide" when this dies.


func on_death(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	if combat.trigger(unit, &"test_tide_on_death"):
		combat.bridge(unit.side).add_counter(&"test_tide", 1, unit)
