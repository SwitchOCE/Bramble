extends Mechanic
## Master of Engines: start of fight (main pass), each friendly back-row unit (B1, B2, B3, any
## tribe, the Master too) Hits the enemy with the least Health with its own Attack as it stands,
## choosing again each time; `times` Hits each (golden: twice). A Needle Pikeman Hits too.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func param_kinds() -> Dictionary:
	return {"times": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if not combat.trigger(unit, &"mouse_engines"):
		return
	for engine: CombatUnit in combat.units(unit.side).duplicate():
		if combat.geometry.is_back(engine.slot):
			MouseRules.hit_weakest(combat, engine, params.num(&"times"))
