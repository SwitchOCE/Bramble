extends Mechanic
## Tourney Champion: Start of fight (main pass): this attacks the enemy with the most Attack, in
## either row, ignoring Guard (9.5.7; a tie goes to the first in reading order), and takes no
## damage from anything while that attack resolves.


func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	var target: CombatUnit = null
	for enemy: CombatUnit in combat.units(1 - unit.side):
		if enemy.should_die():
			continue
		if target == null or enemy.attack() > target.attack():
			target = enemy
	if target != null and combat.trigger(unit, &"badger_tourney"):
		combat.attack_now(unit, target, true)
