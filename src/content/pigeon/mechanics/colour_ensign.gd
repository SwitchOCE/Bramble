extends Mechanic
## Colour Ensign: Start of fight (set-up pass): this slot copies your strongest slot's buff
## (Attack plus Health; first in reading order on a tie), for this fight, if it is bigger than
## its own. A copy is not a buff given (FightSide.slot_set), so the Sergeant Major doesn't double
## it; it stays on the slot for the fight after the Ensign dies. Golden: the slots next to it
## copy it too.


func start_of_combat_priority(_params: MechanicParams) -> int:
	return SOC_SETUP


func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	var side: FightSide = combat.bridge(unit.side)
	var best: int = -1
	var best_total: int = 0
	for index: int in side.slots.size():
		var total: int = side.slots[index].attack + side.slots[index].health
		if best < 0 or total > best_total:
			best = index
			best_total = total
	var targets: Array[int] = [unit.slot]
	if unit.golden:
		targets.append_array(combat.geometry.adjacent(unit.slot))
	var copied: SlotState = side.slots[best].duplicate_slot()
	var changes: Array[int] = []
	for slot: int in targets:
		if slot != best and best_total > side.slots[slot].attack + side.slots[slot].health:
			changes.append(slot)
	if changes.is_empty() or not combat.trigger(unit, &"pigeon_colour_ensign"):
		return
	for slot: int in changes:
		side.slot_set(slot, copied.attack, copied.health, false, unit)
