extends Mechanic
## Rotate (library entry 36), Barnacle Goose Matriarch: as Rotate, and both units that swap gain
## +`attack`/+`health` this combat.


func on_after_attacking(
	combat: Combat, unit: CombatUnit, params: Dictionary, _defender: CombatUnit
) -> void:
	var forward: CombatUnit = combat.rotate_with_healthiest_behind(unit)
	if forward == null:
		return
	var attack: int = CoreUtil.to_int(params.get("attack", 0))
	var health: int = CoreUtil.to_int(params.get("health", 0))
	combat.buff(forward, attack, health, unit)
	combat.buff(unit, attack, health, unit)
