extends Mechanic
## 9.7.2 step 3 and 9.4.9: after a friend in front of this dies, this steps into its slot.


func after_friendly_death(
	combat: Combat, unit: CombatUnit, dead: CombatUnit, _params: MechanicParams
) -> void:
	if unit == null or not combat.geometry.in_front_of(unit.slot).has(dead.slot):
		return
	if combat.unit_at(unit.side, dead.slot) == null and combat.trigger(unit, &"test_step_up"):
		combat.move_unit(unit, dead.slot)
