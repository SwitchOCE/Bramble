extends Mechanic
## Her killer pays after Bitter, whether it killed her while attacking or striking back.


func on_death(combat: Combat, unit: CombatUnit, _params: Dictionary) -> void:
	var killer: CombatUnit = CombatLanes.by_uid(combat, unit.killed_by)
	if killer == null or CombatLanes.maker_of(combat, killer) != unit:
		return
	@warning_ignore("integer_division")
	var loss: int = killer.attack / 2
	if loss > 0:
		combat.trigger(unit, "bufo")
		combat.buff(killer, -loss, 0, unit)
