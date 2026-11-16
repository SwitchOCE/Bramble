extends Mechanic
## King Speck: whenever this attacks, fill your empty slots with Cousins, one at a time outward
## from the King (8.4.2), before any Pile on. Golden: golden Cousins (4/4).

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func on_attack(
	combat: Combat, unit: CombatUnit, _defender: CombatUnit, params: MechanicParams
) -> void:
	if combat.trigger(unit, &"mouse_king_speck"):
		MouseRules.summon_cousins(combat, unit, combat.geometry.slot_count, params.golden)
