extends Mechanic
## Lieutenant: a full row commands one ordinary attack per snapshotted unit, in reading order.
## Across is an explicit target override; an empty or dying target is skipped without fallback.
## The command survives its source, but replacements do not inherit a snapshotted place.


func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	var friends: Array[CombatUnit] = []
	for slot: int in combat.geometry.row_of(unit.slot):
		var here: CombatUnit = combat.unit_at(unit.side, slot)
		if here == null or here.gone or here.should_die():
			return
		friends.append(here)
	if not combat.trigger(unit, &"pigeon_lieutenant"):
		return
	for friend: CombatUnit in friends:
		if friend.gone or friend.should_die():
			continue
		var target: CombatUnit = combat.unit_at(
			1 - friend.side, combat.geometry.across(friend.slot)
		)
		if target == null or target.gone or target.should_die():
			continue
		combat.attack_now(friend, target)
