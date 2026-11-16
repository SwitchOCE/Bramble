extends Mechanic
## Root N: the first time this dies each fight, spend N Compost to return it (9.7.2 step 4). It
## comes back as it stands on the recruit board, at full Health (Q_RETURN_AS_RECRUIT); a unit
## with no recruit-board self comes back plain. Not a choice. With fewer than N entries, or no
## free slot, nothing is spent and it stays dead. Root from several sources returns once and
## pays the lowest cost: only the unit's first Root mechanic acts.

const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")
## Health that means "full" (the core takes damage = max Health - this, never below 0).
const FULL: int = 1 << 30


func param_kinds() -> Dictionary:
	return {"cost": MechanicParams.Kind.THRESHOLD}


func return_health(combat: Combat, unit: CombatUnit, health: int, params: MechanicParams) -> int:
	var hooks: Array[BoundMechanic] = unit.hooks()
	var first: BoundMechanic = Compost.first_root(hooks)
	if first == null or first.params != params or unit.returns > 0:
		return health
	var cost: int = Compost.root_cost(hooks)
	if combat.bridge(unit.side).heap(Compost.HEAP).size() < cost:
		return health
	unit.set_state(Compost.ROOTING, cost)
	return maxi(health, FULL)


func combat_query(unit: CombatUnit, query: StringName, value: int, params: MechanicParams) -> int:
	if query != Q_RETURN_AS_RECRUIT or unit.state_int(Compost.ROOTING) <= 0:
		return value
	var first: BoundMechanic = Compost.first_root(unit.hooks())
	return 1 if first != null and first.params == params else value


func on_returned(
	combat: Combat, gone: CombatUnit, back: CombatUnit, params: MechanicParams
) -> void:
	var cost: int = gone.state_int(Compost.ROOTING)
	var first: BoundMechanic = Compost.first_root(gone.hooks())
	if cost <= 0 or first == null or first.params != params:
		return
	gone.set_state(Compost.ROOTING, 0)
	combat.bridge(gone.side).heap_spend(Compost.HEAP, cost, gone)
	combat.show_status(back, first.id, false, gone)
