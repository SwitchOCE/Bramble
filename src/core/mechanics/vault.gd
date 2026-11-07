extends Mechanic
## AttackOrder puts a back-row vaulter first each cycle; the Attack bonus follows its row.


func aura(_combat: Combat, unit: CombatUnit, params: Dictionary) -> Vector2i:
	return (
		Vector2i(CoreUtil.to_int(params.get("attack", 0)), 0)
		if BoardGeometry.is_back(unit.slot)
		else Vector2i.ZERO
	)
