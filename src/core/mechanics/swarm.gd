extends Mechanic
## Swarm (library entry 25): when a Swarm unit attacks, every other Swarm unit in its row that
## can attack and hasn't attacked this cycle joins in on the same target and is flagged. The
## target hits back only the leader; each joiner's damage is its own hit (SPEC 4.2).


func joiners(combat: Combat, unit: CombatUnit, _params: Dictionary) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	var front: bool = BoardGeometry.is_front(unit.slot)
	for other: CombatUnit in combat.units_of(unit.side):
		if other == unit or other.flagged or BoardGeometry.is_front(other.slot) != front:
			continue
		if other.has_mechanic("swarm") and other.attack > 0:
			out.append(other)
	if not out.is_empty():
		combat.trigger(unit, "swarm")
		for other: CombatUnit in out:
			other.flagged = true
	return out
