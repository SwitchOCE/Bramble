extends Mechanic
## Spoon Catapult: instead of attacking, Hit the enemy with the least Health. That uses its turn
## and counts toward the attack limit. Golden, or with "attacks twice" (Kettle-drummer), it Hits
## twice, choosing again. Told to attack out of turn, it makes an ordinary attack (the core's
## attack_now doesn't ask instead_of_attack).

const MouseRules := preload("res://src/content/mouse/mouse_rules.gd")


func param_kinds() -> Dictionary:
	return {"times": MechanicParams.Kind.NUMBER}


func instead_of_attack(combat: Combat, unit: CombatUnit, params: MechanicParams) -> bool:
	if MouseRules.least_health_enemy(combat, unit) == null:
		return false
	if not combat.trigger(unit, &"mouse_catapult"):
		return false
	var times: int = params.num(&"times")
	if unit.query(Q_ATTACKS, 1) >= 2:
		times = maxi(times, 2)
	MouseRules.hit_weakest(combat, unit, times)
	return true
