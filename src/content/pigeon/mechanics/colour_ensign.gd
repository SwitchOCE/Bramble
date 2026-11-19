extends Mechanic


func start_of_combat_priority(_params: MechanicParams) -> int:
	return SOC_SETUP


func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	var side: FightSide = combat.bridge(unit.side)
	var highest: int = 0
	for slot: SlotState in side.slots:
		highest = maxi(highest, slot.renown)
	var targets: Array[int] = [unit.slot]
	if unit.golden:
		targets.append_array(combat.geometry.adjacent(unit.slot))
	var changes: Array[int] = []
	for slot: int in targets:
		if side.slot(slot).renown < highest:
			changes.append(slot)
	if changes.is_empty() or not combat.trigger(unit, &"pigeon_colour_ensign"):
		return
	for slot: int in changes:
		side.copy_renown(slot, highest, unit)
