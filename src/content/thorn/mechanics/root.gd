extends Mechanic
## Root N: the first time this dies each fight, spend N Compost to return it (9.7.2 step 4),
## through the core's return protocol. Once a fight for each unit (a fight count, carried across
## any return), not a choice. It offers when the Compost holds N entries; the core picks Root
## before a Molt (RETURN_FIRST), so a unit with both uses Molt only when the Compost can't pay
## or its Root is used. It comes back as it stands on the recruit board at full Health; a unit
## with no recruit-board self (a token, a copy) comes back plain. With no free slot the core
## returns nothing and nothing is spent. Root from several sources (its own and The Old Hedge's)
## returns once and pays the lowest cost: aura grants combine by MIN, and of the Roots left only
## the cheapest offers.

const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")
## Fight count on the unit: its Root was used this fight.
const USED: StringName = &"thorn_root_used"
## Health that means "full" (the core takes damage = max Health - this, never below 0).
const FULL: int = 1 << 30


func param_kinds() -> Dictionary:
	return {"cost": MechanicParams.Kind.THRESHOLD}


func grant_combine(_param: StringName) -> Combine:
	return Combine.MIN


func return_offer(combat: Combat, unit: CombatUnit, params: MechanicParams) -> int:
	if unit.fight_count(USED) > 0 or not _cheapest(unit, params):
		return 0
	if combat.bridge(unit.side).heap(Compost.HEAP).size() < params.num(&"cost"):
		return 0
	return FULL


func return_priority(_params: MechanicParams) -> int:
	return RETURN_FIRST


func return_as_recruit(_params: MechanicParams) -> bool:
	return true


func pay_return(combat: Combat, gone: CombatUnit, back: CombatUnit, params: MechanicParams) -> void:
	back.add_fight_count(USED)
	var cost: int = params.num(&"cost")
	if cost > 0:
		combat.bridge(gone.side).heap_spend(Compost.HEAP, cost, gone)
	combat.show_status(back, &"thorn_root", false, gone)


## True when `params` is the unit's cheapest Root (the first of the cheapest, in hook order).
static func _cheapest(unit: CombatUnit, params: MechanicParams) -> bool:
	var best: BoundMechanic = null
	for bound: BoundMechanic in unit.hooks():
		if bound.id != &"thorn_root":
			continue
		if best == null or bound.params.num(&"cost") < best.params.num(&"cost"):
			best = bound
	return best != null and best.params == params
