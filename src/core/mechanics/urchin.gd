extends Mechanic
## Dr Urchin: Bristle `n`. After this pricks, Pass +`attack` Attack immediately this combat.


func on_damage_taken(combat: Combat, unit: CombatUnit, params: Dictionary, hit: Hit) -> void:
	if hit.kind != Hit.ATTACK or hit.source.side == unit.side or hit.amount <= 0:
		return
	var struck: CombatUnit = hit.source
	if combat.reactions.pack_joiners.has(struck):
		struck = combat.reactions.current_attacker
	combat.queue_thorns(unit, struck, CoreUtil.to_int(params.get("n", 0)))
	CombatMoves.pass_buff(combat, unit, CoreUtil.to_int(params.get("attack", 0)), 0)
