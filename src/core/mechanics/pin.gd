extends Mechanic
## Pin (library entry 11): an enemy that takes damage from this (attacking or attacked) skips
## its next turn in the attack order. Doesn't stack; applies even if this dies in the exchange.


func on_damage_dealt(combat: Combat, unit: CombatUnit, _params: Dictionary, hit: Hit) -> void:
	var enemy: CombatUnit = hit.target
	if enemy.side == unit.side or enemy.health <= 0 or enemy.has_status("stalled"):
		return
	combat.trigger(unit, "pin")
	combat.set_status(enemy, "stalled", true, unit)
