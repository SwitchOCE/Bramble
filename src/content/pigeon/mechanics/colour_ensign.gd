extends Mechanic
## Colour Ensign: Start of fight (set-up pass): this slot copies your highest Renown (the most
## on any of your slots) for this fight, if it is higher than its own. A copy is not Renown given
## (FightSide.copy_renown): nothing is kept after the fight, and it stays on the slot for the fight
## after the Ensign dies. Golden: the slots next to it copy it too.


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
