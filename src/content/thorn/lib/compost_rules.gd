extends RefCounted
## The Briars' shared rules (docs/ideation-track-2/tribes/thorn/units.json "rules"), used by the
## thorn mechanics. Not a mechanic: it sits outside mechanics/ so the loader doesn't register it.
## Stateless. The core marks which Compost entries were copied this fight
## (FightSide.heap_use_highest); Root's once a fight is a fight count (root.gd).

## The Compost: one heap on each player for the whole game.
const HEAP: StringName = &"thorn_compost"
const BRIAR: String = "Briar"
## CombatUnit.state on an Elder Mother copy: +N/+N for each Compost entry when it lands.
const ELDER_PER: StringName = &"thorn_elder_per"


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


## True when a side has an empty slot for a summon (a dying unit still holds its slot until the
## death check, as the core counts it).
static func has_room(combat: Combat, side_index: int) -> bool:
	for slot: int in combat.geometry.slot_count:
		if combat.unit_at(side_index, slot) == null:
			return true
	return false


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
