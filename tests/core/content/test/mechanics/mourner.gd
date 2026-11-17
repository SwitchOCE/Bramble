extends Mechanic
## Whenever any unit dies, +1 Attack this fight. As a standing mechanic (no unit) it only
## logs a side trigger (trigger_side).


func on_any_death(
	combat: Combat, unit: CombatUnit, _dead: CombatUnit, _params: MechanicParams
) -> void:
	if unit == null:
		combat.trigger_side(combat.listening_side, &"test_mourner")
	elif combat.trigger(unit, &"test_mourner"):
		combat.buff(unit, 1, 0, unit)
