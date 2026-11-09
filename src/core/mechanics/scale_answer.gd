extends Mechanic


func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: Dictionary) -> void:
	if not combat.config.get_bool("scale_levers"):
		return
	var world := CombatWorld.make(combat, unit, unit.side, {}, "start_of_combat")
	var step: Dictionary = {
		"effect": "stat_fraction",
		"target": {"select": "biggest_enemy"},
		"operation": "reduce",
		"numerator": clampi(combat.config.get_int("scale_answer_percent"), 0, 100),
		"denominator": 100
	}
	combat.trigger(unit, "scale_answer")
	EffectRunner.run_step(step, {}, world)
