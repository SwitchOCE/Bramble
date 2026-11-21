extends Mechanic
## Tourney Champion: Start of fight (main pass): attacks the enemies with the most Attack,
## ignoring Guard (9.5.7). Ties are broken in reading order. These attacks take no damage.


func param_kinds() -> Dictionary:
	return {"targets": MechanicParams.Kind.NUMBER}


func text_params(params: MechanicParams) -> Dictionary:
	var count: int = params.num(&"targets")
	return {"top_enemies": "the enemy" if count == 1 else "the %d enemies" % count}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var enemies: Array[CombatUnit] = combat.units(1 - unit.side)
	enemies.sort_custom(
		func(a: CombatUnit, b: CombatUnit) -> bool:
			return a.slot < b.slot if a.attack() == b.attack() else a.attack() > b.attack()
	)
	var count: int = mini(params.num(&"targets"), enemies.size())
	if count <= 0 or not combat.trigger(unit, &"badger_tourney"):
		return
	for i: int in count:
		var target: CombatUnit = enemies[i]
		if not target.gone and not target.should_die():
			if not combat.attack_now(unit, target, true):
				break
