extends Mechanic
## Bitter Toad (library entry 75): whenever this deals damage to an enemy, that enemy gains
## Nightshade. Golden (hard-coded, as the library's golden text): an enemy that deals damage to
## this gains it too.


func on_damage_dealt(combat: Combat, unit: CombatUnit, _params: Dictionary, hit: Hit) -> void:
	_give(combat, unit, hit.target)


func on_damage_taken(combat: Combat, unit: CombatUnit, _params: Dictionary, hit: Hit) -> void:
	if unit.golden:
		_give(combat, unit, hit.source)


func _give(combat: Combat, unit: CombatUnit, enemy: CombatUnit) -> void:
	if enemy.side == unit.side or enemy.health <= 0 or enemy.has_status("nightshade"):
		return
	combat.trigger(unit, "nightshade_on_hit")
	combat.set_status(enemy, "nightshade", true, unit)
