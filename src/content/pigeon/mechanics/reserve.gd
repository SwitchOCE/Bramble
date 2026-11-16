extends Mechanic
## Reserve: in a fight, this steps from the hand into a slot a friendly unit died in, the Guard
## post first (the core's FightArrivals does the stepping in; SHARED-RULES ruling 6).


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return 1 if query == Q_RESERVE else value
