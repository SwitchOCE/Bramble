extends Mechanic
## Once a fight, returns as its recruit unit stands, at full Health (Root).


func return_offer(_combat: Combat, unit: CombatUnit, _params: MechanicParams) -> int:
	return 999 if unit.returns == 0 else 0


func return_as_recruit(_params: MechanicParams) -> bool:
	return true
