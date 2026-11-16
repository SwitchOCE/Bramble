extends Mechanic
## The Eighth Plague's count: after a friendly unit dies, records the side's death count as that
## death resolves (FightSide.deaths).

const SEEN: StringName = &"test_counts"


func after_friendly_death(
	combat: Combat, unit: CombatUnit, _dead: CombatUnit, _params: MechanicParams
) -> void:
	if unit == null or not combat.trigger(unit, &"test_count_deaths"):
		return
	var seen: Array = unit.state.get(SEEN, [])
	seen.append(combat.bridge(unit.side).deaths)
	unit.state[SEEN] = seen
