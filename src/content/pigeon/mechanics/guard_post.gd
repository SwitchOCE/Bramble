extends Mechanic
## Guard post: a slot keyword (8.5). The Grenadier Guard's Order puts it on a slot together with
## Guard (taunt), so the unit standing there has both. A player has one; setting a new one clears
## the old. It is also a standing mechanic of every player: it answers which slot Reserve units
## fill first (Q_FILL_FIRST) from the side's slots, so an empty post is filled first.

const ID: StringName = &"pigeon_guard_post"


## The slot holding the Guard post, or -1.
static func post_of(slots: Array[SlotState]) -> int:
	for index: int in slots.size():
		if slots[index].keywords.has(ID):
			return index
	return -1


func side_query(
	combat: Combat, unit: CombatUnit, query: StringName, value: int, _params: MechanicParams
) -> int:
	if query != Q_FILL_FIRST or value >= 0:
		return value
	var side: int = unit.side if unit != null else combat.listening_side
	if side < 0:
		return value
	return post_of(combat.bridge(side).slots)
