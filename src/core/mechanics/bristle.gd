extends Mechanic
## Bristle (N) (library entry 7): an enemy that damages this during an attack takes N thorn
## damage after the exchange, before deaths are checked. Thorns never trigger thorns.


func on_damage_taken(combat: Combat, unit: CombatUnit, params: Dictionary, hit: Hit) -> void:
	if hit.kind != Hit.ATTACK or hit.source.side == unit.side or hit.amount <= 0:
		return
	combat.queue_thorns(unit, hit.source, CoreUtil.to_int(params.get("n", 0)))
