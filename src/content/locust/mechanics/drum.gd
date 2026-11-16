extends Mechanic
## War-drummer. Whenever this attacks (every attack, out-of-turn ones too), from the front row
## only: a unit in the slots behind it (8.2.1) that has a death effect, at random if two, has
## its death effects resolve `times` times where it stands. Nothing died: no death counts, no
## "after a friendly unit dies", no return (ruling 31). Dirge-singer doubles each (ruling 33).


func param_kinds() -> Dictionary:
	return {"times": MechanicParams.Kind.NUMBER}


func on_attack(
	combat: Combat, unit: CombatUnit, _defender: CombatUnit, params: MechanicParams
) -> void:
	if not combat.geometry.front.has(unit.slot):
		return
	var behind: Array[CombatUnit] = []
	for friend: CombatUnit in combat.select(unit, "behind"):
		if friend.has_death_effect() and not friend.should_die():
			behind.append(friend)
	if behind.is_empty() or not combat.trigger(unit, &"locust_drum"):
		return
	var drummed: CombatUnit = behind[combat.effect_rng.index(behind.size())]
	for _i: int in params.num(&"times"):
		if drummed.gone:
			return
		combat.run_death_effects(drummed)
