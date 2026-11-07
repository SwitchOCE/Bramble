extends Mechanic
## Jack Daw: Start of Combat, takes a quarter of what the enemy across has gained on top of its card,
## at most `most` to each stat. If that took anything, `gold` next turn.

const PART: int = 4


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var enemy: CombatUnit = combat.unit_at(1 - unit.side, BoardGeometry.across(unit.slot))
	if enemy == null:
		return
	var most: int = CoreUtil.to_int(params.get("most", 4))
	@warning_ignore("integer_division")
	var attack: int = mini(most, maxi(0, enemy.attack - enemy.base_attack_now()) / PART)
	@warning_ignore("integer_division")
	var health: int = mini(most, maxi(0, enemy.health - enemy.base_health_now()) / PART)
	if attack <= 0 and health <= 0:
		return
	combat.trigger(unit, "jack_daw")
	combat.buff(enemy, -attack, -health, unit)
	combat.buff(unit, attack, health, unit)
	combat.carry_back(
		unit.side, {"op": "gold_next_turn", "amount": CoreUtil.to_int(params.get("gold", 1))}
	)
