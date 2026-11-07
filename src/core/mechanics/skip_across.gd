extends Mechanic
## Turnip Scarecrow: Start of Combat, the enemy across from this skips its first `skips` attacks. It
## shares Pin's status, with a count. An empty slot across means nothing happens.


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var enemy: CombatUnit = combat.unit_at(1 - unit.side, BoardGeometry.across(unit.slot))
	if enemy == null:
		return
	combat.trigger(unit, "skip_across")
	combat.set_status(
		enemy, "stalled", true, unit, {"skips": CoreUtil.to_int(params.get("skips", 1))}
	)
