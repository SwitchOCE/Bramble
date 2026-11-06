extends Mechanic
## Rotate (library entry 36), Lead Goose: after this attacks, if it is alive and in the front row,
## it swaps with the friendly unit behind it with the most Health. The unit that comes forward
## gains +`forward_attack` Attack this combat, and attacks next (it is unflagged).


func on_after_attacking(
	combat: Combat, unit: CombatUnit, params: Dictionary, _defender: CombatUnit
) -> void:
	var forward: CombatUnit = combat.rotate_with_healthiest_behind(unit)
	if forward != null:
		combat.buff(forward, CoreUtil.to_int(params.get("forward_attack", 0)), 0, unit)
