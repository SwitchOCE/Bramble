extends Mechanic
## King Speck: whenever this attacks, fill your empty slots with Cousins, one at a time outward
## from the King (8.4.2), before any Pile on. Golden: 4/4 Cousins. The core can't summon a golden
## token, so a golden King's Cousins are Cousins given +2/+2 for the fight.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func on_attack(
	combat: Combat, unit: CombatUnit, _defender: CombatUnit, params: MechanicParams
) -> void:
	if not combat.trigger(unit, &"mouse_king_speck"):
		return
	for _i: int in combat.geometry.slot_count:
		var cousin: CombatUnit = combat.summon(unit.side, MouseRules.COUSIN, unit.slot, false, unit)
		if cousin == null:
			break
		if params.golden:
			combat.buff(cousin, 2, 2, unit)
