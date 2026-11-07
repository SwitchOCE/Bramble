extends Mechanic
## Bristle (N) (library entry 7): an enemy that damages this during an attack takes N thorn
## damage after the exchange, before deaths are checked. Thorns never trigger thorns.


func on_damage_taken(combat: Combat, unit: CombatUnit, params: Dictionary, hit: Hit) -> void:
	if hit.kind != Hit.ATTACK or hit.source.side == unit.side or hit.amount <= 0:
		return
	var struck: CombatUnit = hit.source
	if combat.reactions.pack_joiners.has(struck):
		struck = combat.reactions.current_attacker
	combat.queue_thorns(unit, struck, CoreUtil.to_int(params.get("n", 0)))
