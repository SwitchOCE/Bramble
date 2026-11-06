extends Mechanic
## Ichneumon Wasp: an enemy this damages with an attack dies after its next attack.


func on_damage_dealt(combat: Combat, unit: CombatUnit, _params: Dictionary, hit: Hit) -> void:
	if hit.kind == Hit.ATTACK and hit.amount > 0 and hit.target.on_board:
		combat.set_status(hit.target, "parasite", true, unit)
