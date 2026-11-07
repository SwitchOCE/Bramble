extends Mechanic
## Gideon answers with a temporary bonus for this counterattack alone.


func on_attacked_complete(
	combat: Combat, unit: CombatUnit, params: Dictionary, attacker: CombatUnit
) -> void:
	BogFolk.answer(combat, unit, attacker, false, CoreUtil.to_int(params.get("attack", 0)))
