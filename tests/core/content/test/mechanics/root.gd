extends Mechanic
## A paid return through the return protocol (SHARED-RULES 17): once a fight, if `cost` entries
## of the test heap can be spent, it offers to come back with 1 Health, before any plain return
## (RETURN_FIRST). Only the chosen offer pays, in pay_return.

const ONCE: StringName = &"test_root_used"


func param_kinds() -> Dictionary:
	return {"cost": MechanicParams.Kind.THRESHOLD}


func return_offer(combat: Combat, unit: CombatUnit, params: MechanicParams) -> int:
	if unit.fight_count(ONCE) > 0:
		return 0
	if combat.bridge(unit.side).heap(&"test_heap").size() < params.num(&"cost"):
		return 0
	return 1


func return_priority(_params: MechanicParams) -> int:
	return RETURN_FIRST


func pay_return(combat: Combat, gone: CombatUnit, back: CombatUnit, params: MechanicParams) -> void:
	back.add_fight_count(ONCE)
	combat.bridge(gone.side).heap_spend(&"test_heap", params.num(&"cost"), gone)
	combat.show_status(back, &"test_root", false, gone)
