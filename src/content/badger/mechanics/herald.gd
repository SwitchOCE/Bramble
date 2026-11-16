extends Mechanic
## Herald of the Charge: Start of fight (main pass): the units in front of this, any tribe,
## attack immediately, the left one first. Normal attacks: they take damage and their "whenever
## this attacks" effects trigger. A unit that can't attack doesn't.


func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	var slots: Array[int] = combat.geometry.in_front_of(unit.slot)
	slots.sort()
	var charging: Array[CombatUnit] = []
	for slot: int in slots:
		var front: CombatUnit = combat.unit_at(unit.side, slot)
		if front != null and not front.gone:
			charging.append(front)
	if charging.is_empty() or not combat.trigger(unit, &"badger_herald"):
		return
	for front: CombatUnit in charging:
		if not front.gone and not front.should_die():
			combat.attack_now(front)
