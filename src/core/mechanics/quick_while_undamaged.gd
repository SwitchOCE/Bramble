extends Mechanic
## Ermine Duellist (library entry 24): Quick while this has taken no damage this combat.


func strikes_first(unit: CombatUnit, _params: Dictionary) -> bool:
	return unit.is_undamaged()
