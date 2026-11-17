extends Mechanic
## Master of Engines: reinforce only the leftmost back-row unit, then ask for its one Ambush.
## A unit whose allowance was spent is not replaced with another shooter.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	for engine: CombatUnit in combat.units(unit.side):
		if combat.geometry.is_back(engine.slot):
			if combat.trigger(unit, &"mouse_engines"):
				combat.buff(engine, params.num(&"attack"), 0, unit)
				MouseRules.ambush_weakest(combat, engine, &"mouse_ambush")
			return
