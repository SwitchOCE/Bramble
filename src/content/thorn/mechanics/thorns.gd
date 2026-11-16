extends Mechanic
## Thorns N: whenever this is attacked, deal N damage to the attacker first (9.6.1 step 1). Not
## an attack and not a Hit. Thorns from several sources add up: the first Thorns on the unit
## deals the total. An attacker it kills doesn't attack (the core ends the attack). An attack
## that takes no damage takes none (the core's NO_DAMAGE). A kill is noted for Lone Hawthorn.

const Compost := preload("res://src/content/thorn/compost_rules.gd")


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_attacked(
	combat: Combat, unit: CombatUnit, attacker: CombatUnit, params: MechanicParams
) -> void:
	var hooks: Array[BoundMechanic] = unit.hooks()
	if not Compost.is_first(hooks, &"thorn_thorns", params):
		return
	var amount: int = Compost.total(hooks, &"thorn_thorns", &"amount")
	if amount <= 0 or attacker.gone or not combat.trigger(unit, &"thorn_thorns"):
		return
	combat.deal_damage(unit, attacker, amount)
	if attacker.should_die():
		combat.bridge(unit.side).set_state(kill_key(attacker), 1)


## FightSide.state key: this enemy unit was killed by this side's Thorns.
static func kill_key(attacker: CombatUnit) -> StringName:
	return StringName("thorn_thorns_kill_%d" % attacker.uid)
