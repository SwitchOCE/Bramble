class_name HitReactor
extends Mechanic
## Base of "after this survives a hit": a hit taken while attacking or defending counts once the
## exchange and its deaths are over and this is still standing.


func on_damage_taken(_combat: Combat, unit: CombatUnit, _params: Dictionary, hit: Hit) -> void:
	if hit.amount > 0:
		unit.counters[hit_counter()] = 1


func on_survived_attack(
	combat: Combat, unit: CombatUnit, params: Dictionary, _attacker: CombatUnit
) -> void:
	_check(combat, unit, params)


func on_after_attack(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	_check(combat, unit, params)


## The counter noting a hit; each mechanic has its own, as Frumenty can hold two.
func hit_counter() -> String:
	return "was_hit"


func after_hit(_combat: Combat, _unit: CombatUnit, _params: Dictionary) -> void:
	pass


func _check(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	if unit.counters.erase(hit_counter()) and unit.on_board and unit.health > 0:
		after_hit(combat, unit, params)
