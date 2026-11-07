extends Mechanic
## Cluricaun: your units standing on bands have +`attack` Attack, in both phases (BoardUpkeep shows
## it in the Recruit Phase).


func has_board_aura(_params: Dictionary) -> bool:
	return true


func board_aura(combat: Combat, unit: CombatUnit, params: Dictionary, out: Dictionary) -> void:
	var attack: int = CoreUtil.to_int(params.get("attack", 0))
	for slot: int in CombatMoves.bands_of(combat, unit.side):
		var standing: CombatUnit = combat.unit_at(unit.side, slot)
		if standing != null:
			var now: Vector2i = out.get(standing.uid, Vector2i.ZERO)
			out[standing.uid] = now + Vector2i(attack, 0)
