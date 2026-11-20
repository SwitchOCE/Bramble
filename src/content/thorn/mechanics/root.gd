extends Mechanic
## Root N: the first time this dies each fight, spend N Compost to return it (9.7.2 step 4),
## through the core's return protocol. By default once a fight for each unit (a fight count,
## carried across any return). It offers when the Compost holds N entries; the core picks Root
## before a Molt (RETURN_FIRST), so a unit with both uses Molt only when the Compost can't pay
## or its Root is used. It comes back as it stands on the recruit board at full Health; a unit
## with no recruit-board self (a token, a copy) comes back plain. With no free slot the core
## returns nothing and nothing is spent. Root from several sources (its own and The Old Hedge's)
## shares one usage count. Of the Roots with charges left, only the cheapest offers. Aura
## grants combine by lowest cost and highest cap.

const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")
## Fight count on the unit: its Root was used this fight.
const USED: StringName = &"thorn_root_used"
## Health that means "full" (the core takes damage = max Health - this, never below 0).
const FULL: int = 1 << 30


func param_kinds() -> Dictionary:
	return {"cost": MechanicParams.Kind.THRESHOLD, "charges": MechanicParams.Kind.NUMBER}


func optional_params() -> PackedStringArray:
	return ["charges"]


func text_params(params: MechanicParams) -> Dictionary:
	return root_words(params.num(&"charges", 1))


static func root_words(charges: int) -> Dictionary:
	return {
		"root_repeats": "" if charges == 1 else ", %s each fight" % UnitText.repeat_count(charges)
	}


func shown_params(params: MechanicParams) -> Dictionary:
	return {"cost": params.num(&"cost")}


func grant_combine(param: StringName) -> Combine:
	return Combine.MAX if param == &"charges" else Combine.MIN


func return_offer(combat: Combat, unit: CombatUnit, params: MechanicParams) -> int:
	if _cheapest(unit) != params:
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
	if _cheapest(back) == null:
		combat.show_status(back, &"thorn_root", false, gone)


## The cheapest Root with charges left. Ties go to the first in hook order.
static func _cheapest(unit: CombatUnit) -> MechanicParams:
	var best: MechanicParams = null
	for bound: BoundMechanic in unit.hooks():
		if bound.id != &"thorn_root":
			continue
		if unit.fight_count(USED) >= bound.params.num(&"charges", 1):
			continue
		if best == null or bound.params.num(&"cost") < best.num(&"cost"):
			best = bound.params
	return best
