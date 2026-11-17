extends Mechanic
## Lieutenant: Start of fight (main pass), if this row is full, each unit in it gains
## temporary Health equal to a quarter of its effective slot Attack, rounded up (golden: half).
## Setup effects such as Edgewright and Colour Ensign count; this emits no damage or attacks.


func param_kinds() -> Dictionary:
	return {"percent": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var row: Array[int] = combat.geometry.row_of(unit.slot)
	var friends: Array[CombatUnit] = []
	for slot: int in row:
		var here: CombatUnit = combat.unit_at(unit.side, slot)
		if here == null or here.gone:
			return
		friends.append(here)
	if not combat.trigger(unit, &"pigeon_lieutenant"):
		return
	for friend: CombatUnit in friends:
		var amount: int = ceili(friend.stats.slot_attack * params.num(&"percent") / 100.0)
		if amount > 0:
			combat.buff(friend, 0, amount, unit)
