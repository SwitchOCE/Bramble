extends Mechanic
## Sweetbriar: whenever an entry goes into your heap in a fight, gain +1/+1 permanently.


func on_heap_added_in_fight(
	combat: Combat,
	unit: CombatUnit,
	_heap: StringName,
	_card_id: StringName,
	_params: MechanicParams
) -> void:
	if unit != null and combat.trigger(unit, &"test_fight_heap_watch"):
		combat.buff(unit, 1, 1, unit, true)
