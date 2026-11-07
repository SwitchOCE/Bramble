extends Mechanic
## Changeling: Start of Combat, trade places with the enemy across. Each fights for its new side
## until the borrowed unit has attacked once; then they trade back. A golden Changeling's borrowed
## unit gains +`golden_bonus`/+`golden_bonus` this combat.


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var enemy: CombatUnit = combat.unit_at(1 - unit.side, BoardGeometry.across(unit.slot))
	if enemy == null:
		return
	combat.trigger(unit, "changeling")
	CombatMoves.borrow_across(
		combat, unit, enemy, CoreUtil.to_int(params.get("golden_bonus", 0)) if unit.golden else 0
	)
