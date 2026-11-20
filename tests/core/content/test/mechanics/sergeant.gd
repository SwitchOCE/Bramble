extends Mechanic
## After each round of deaths (after Reserve), summon a Sprout; once a
## fight.

const DONE: StringName = &"test_sergeant_done"


func after_death_round(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	if unit == null or unit.state_int(DONE) != 0:
		return
	if combat.trigger(unit, &"test_sergeant"):
		unit.set_state(DONE, 1)
		combat.summon(unit.side, &"tk_sprout", -1, false, unit)
