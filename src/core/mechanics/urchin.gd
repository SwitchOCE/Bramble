extends Mechanic
## Dr Urchin: Bristle `n`. After this pricks, Pass right +`attack` Attack this combat.


func on_damage_taken(combat: Combat, unit: CombatUnit, params: Dictionary, hit: Hit) -> void:
	if hit.kind != Hit.ATTACK or hit.source.side == unit.side or hit.amount <= 0:
		return
	combat.queue_thorns(unit, hit.source, CoreUtil.to_int(params.get("n", 0)))
	combat.pass_buff(unit, CoreUtil.to_int(params.get("attack", 0)), 0)
