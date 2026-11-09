extends Mechanic
## Whirligig Beetle: Start of Combat, the enemy's rows swap places: F1 with B1, F2 with B2, F3 with
## B3; F4 stays. Each enemy moved takes `damage`.


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	combat.trigger(unit, "row_swap")
	var moved: Array[CombatUnit] = CombatMoves.swap_rows(
		combat, 1 - unit.side, Pass3Combat.has_content(combat)
	)
	for enemy: CombatUnit in moved:
		combat.deal_effect_damage(unit, enemy, CoreUtil.to_int(params.get("damage", 0)))
