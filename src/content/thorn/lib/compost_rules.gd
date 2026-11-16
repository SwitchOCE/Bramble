extends RefCounted
## The Briars' shared rules (docs/ideation-track-2/tribes/thorn/units.json "rules"), used by the
## thorn mechanics. Not a mechanic: it sits outside mechanics/ so the loader doesn't register it.
## Stateless; per-fight state goes on FightSide.state and CombatUnit.state under thorn_ keys.

## The Compost: one heap on each player for the whole game.
const HEAP: StringName = &"thorn_compost"
const BRIAR: String = "Briar"
## FightSide.state: the Compost entries (the heap's own entry dictionaries) copied this fight.
const COPIED: StringName = &"thorn_copied"
## CombatUnit.state on an Elder Mother copy: +N/+N for each Compost entry when it lands.
const ELDER_PER: StringName = &"thorn_elder_per"
## CombatUnit.state on a dying unit: the Root cost it will pay (set when its return is decided).
const ROOTING: StringName = &"thorn_rooting"
## Unit counter on a Pip made by a golden Crab-apple: its Seed adds 2.
const GOLDEN_PIP: StringName = &"thorn_golden_pip"
## Mechanics that give Root, and the cost each one asks.
const ROOT_IDS: Array[StringName] = [&"thorn_root", &"thorn_hedge_root"]


## True when `params` belongs to the first bound mechanic with this id on the unit (own text
## first, then aura grants). Keywords that add up (Thorns, Grow) act once, from the first.
static func is_first(
	hooks: Array[BoundMechanic], mechanic_id: StringName, params: MechanicParams
) -> bool:
	for bound: BoundMechanic in hooks:
		if bound.id == mechanic_id:
			return bound.params == params
	return false


## The sum of one parameter over every bound mechanic with this id (Thorns 2 + Thorns 6).
static func total(hooks: Array[BoundMechanic], mechanic_id: StringName, param: StringName) -> int:
	var sum: int = 0
	for bound: BoundMechanic in hooks:
		if bound.id == mechanic_id:
			sum += bound.params.num(param)
	return sum


## The unit's first Root mechanic (own Root before The Old Hedge's), or null.
static func first_root(hooks: Array[BoundMechanic]) -> BoundMechanic:
	for bound: BoundMechanic in hooks:
		if ROOT_IDS.has(bound.id):
			return bound
	return null


## Root from several sources returns once and pays the lowest cost. -1 when it has no Root.
static func root_cost(hooks: Array[BoundMechanic]) -> int:
	var best: int = -1
	for bound: BoundMechanic in hooks:
		if not ROOT_IDS.has(bound.id):
			continue
		var cost: int = 1 if bound.id == &"thorn_hedge_root" else bound.params.num(&"cost")
		best = cost if best < 0 else mini(best, cost)
	return best


## The highest-tier Compost entry not yet copied this fight, newest first on a tie; {} if none.
static func next_copy(side: FightSide) -> Dictionary:
	var copied: Array = side.state.get(COPIED, [])
	var entries: Array[Dictionary] = side.heap(HEAP).entries
	var best: Dictionary = {}
	for i: int in range(entries.size() - 1, -1, -1):
		var entry: Dictionary = entries[i]
		if copied.any(func(e: Variant) -> bool: return is_same(e, entry)):
			continue
		if best.is_empty() or CoreUtil.to_int(entry["tier"]) > CoreUtil.to_int(best["tier"]):
			best = entry
	return best


## Marks a Compost entry copied for this fight; it stays in the Compost (FightSide.heap_use logs
## it for the screen).
static func mark_copied(side: FightSide, entry: Dictionary, source: CombatUnit) -> void:
	var copied: Array = side.state.get(COPIED, [])
	copied.append(entry)
	side.state[COPIED] = copied
	if side.heap_unused(HEAP) > 0:
		side.heap_use(HEAP, 1, source)


## An Elder Mother copy that just landed gains +N/+N for each Compost entry, once.
static func elder_bonus(combat: Combat, entered: CombatUnit) -> void:
	var per: int = entered.state_int(ELDER_PER)
	if per <= 0:
		return
	entered.set_state(ELDER_PER, 0)
	var size: int = combat.bridge(entered.side).heap(HEAP).size()
	if size > 0 and combat.trigger(entered, &"thorn_elder_mother"):
		combat.buff(entered, per * size, per * size, null)


## The Briars on a recruit board, in reading order.
static func briars(player: PlayerState) -> Array[Unit]:
	var out: Array[Unit] = []
	for unit: Unit in player.board_units():
		if unit.def.has_tribe(BRIAR):
			out.append(unit)
	return out
