extends Mechanic
## The Attack loss is a live aura, tied to Jenny and to the enemy standing in her mud.


func has_board_aura(_params: Dictionary) -> bool:
	return true


func board_aura(combat: Combat, unit: CombatUnit, params: Dictionary, out: Dictionary) -> void:
	for enemy: CombatUnit in combat.units_of(1 - unit.side):
		if CombatLanes.maker_of(combat, enemy) == unit:
			var bonus: Vector2i = out.get(enemy.uid, Vector2i.ZERO)
			out[enemy.uid] = bonus - Vector2i(CoreUtil.to_int(params.get("attack", 0)), 0)


func on_attacked_complete(
	combat: Combat, unit: CombatUnit, _params: Dictionary, attacker: CombatUnit
) -> void:
	BogFolk.answer(combat, unit, attacker, true, 0)
