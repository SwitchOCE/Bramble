extends Mechanic
## A tempo steal from the enemy across. Neither side's Health changes, and no gold is earned.


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var enemy: CombatUnit = combat.unit_at(1 - unit.side, BoardGeometry.across(unit.slot))
	if enemy == null:
		return
	var attack: int = mini(enemy.attack, StatFraction.loss(enemy.attack, params, "attack"))
	if attack <= 0:
		return
	combat.trigger(unit, "jack_daw")
	combat.buff(enemy, -attack, 0, unit)
	combat.buff(unit, attack, 0, unit)
