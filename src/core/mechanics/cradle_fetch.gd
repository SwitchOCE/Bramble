extends Mechanic
## Cradle Fetch: Start of Combat, this becomes a copy of the unit behind it: its printed stats and
## text, not its buffs. Its Start of Combat text fires. F2 and F3 copy the left one if both stand
## there; another Fetch can't be copied. Golden: the copy gains +`golden_bonus` to both.


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	for slot: int in BoardGeometry.behind(unit.slot):
		var other: CombatUnit = combat.unit_at(unit.side, slot)
		if other != null and not other.has_mechanic("cradle_fetch"):
			combat.trigger(unit, "cradle_fetch")
			CombatMoves.become_copy(
				combat,
				unit,
				other,
				CoreUtil.to_int(params.get("golden_bonus", 0)) if unit.golden else 0
			)
			return
