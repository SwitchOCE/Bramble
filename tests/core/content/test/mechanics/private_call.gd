extends Mechanic
## After a round of deaths, a Sprout steps in (Combat.step_in) to the first slot a friend died in
## this round that is still empty, as a Private would; once a fight.

const DONE: StringName = &"test_private_call_done"
const EMPTIED: StringName = &"test_private_call_slots"


func after_friendly_death(
	_combat: Combat, unit: CombatUnit, dead: CombatUnit, _params: MechanicParams
) -> void:
	if unit == null or unit.state_int(DONE) != 0:
		return
	var slots: Array = unit.state.get(EMPTIED, [])
	slots.append(dead.slot)
	unit.state[EMPTIED] = slots


func after_death_round(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	if unit == null or unit.state_int(DONE) != 0:
		return
	var slots: Array = unit.state.get(EMPTIED, [])
	unit.state.erase(EMPTIED)
	for value: Variant in slots:
		var slot: int = CoreUtil.to_int(value)
		if combat.unit_at(unit.side, slot) != null:
			continue
		if combat.trigger(unit, &"test_private_call"):
			unit.set_state(DONE, 1)
			combat.step_in(unit.side, &"tk_sprout", slot, unit)
		return
