extends Mechanic
## Gleaner. After a friendly unit dies (9.7.2 step 3, not its own), deal `amount` damage to the
## enemy with the most Health left, either row; a tie goes to the first in reading order.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func after_friendly_death(
	combat: Combat, unit: CombatUnit, _dead: CombatUnit, params: MechanicParams
) -> void:
	if unit == null:
		return
	var target: CombatUnit = null
	for enemy: CombatUnit in combat.units(1 - unit.side):
		if target == null or enemy.health() > target.health():
			target = enemy
	if target != null and combat.trigger(unit, &"locust_glean"):
		combat.deal_damage(unit, target, params.num(&"amount"))
