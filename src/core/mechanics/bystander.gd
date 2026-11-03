extends Mechanic
## Bystander (library entry 13): whenever an enemy unit attacks one of your other units, this
## gains +`attack`/+`health` this combat. Once per attack, Peck included (SPEC 4.2).


func on_attack_declared(
	combat: Combat, unit: CombatUnit, params: Dictionary, attacker: CombatUnit, defender: CombatUnit
) -> void:
	if attacker.side == unit.side or defender.side != unit.side or defender == unit:
		return
	combat.trigger(unit, "bystander")
	var attack: int = CoreUtil.to_int(params.get("attack", 0))
	combat.buff(unit, attack, CoreUtil.to_int(params.get("health", 0)), unit)
