class_name UnitPool
extends RefCounted
## The lobby's one shared pool (rulebook 5.1): copies left per unit. Draws follow 6.1.3: one
## copy drawn uniformly from all copies left at or below the player's tier.

## def_id -> copies left, in the library's order (tier then name) so draws are deterministic.
var _copies: Dictionary = {}
var _tiers: Dictionary = {}
var _order: PackedStringArray = []


static func create(library: UnitLibrary, config: GameConfig) -> UnitPool:
	var pool := UnitPool.new()
	var skeleton_only: bool = config.get_string("pool_filter") == "skeleton"
	for unit: Dictionary in library.pool_units():
		if skeleton_only and not unit["skeleton"]:
			continue
		var id: String = unit["id"]
		var tier: int = unit["tier"]
		pool._order.append(id)
		pool._tiers[id] = tier
		pool._copies[id] = config.get_int_at("pool_copies_by_tier", tier - 1)
	return pool


func copies_left(def_id: String) -> int:
	var count: int = _copies.get(def_id, 0)
	return count


func has_unit(def_id: String) -> bool:
	return _copies.has(def_id)


## Total copies left at or below `max_tier`.
func eligible_copies(max_tier: int) -> int:
	var total: int = 0
	for id: String in _order:
		var tier: int = _tiers[id]
		if tier <= max_tier:
			var count: int = _copies[id]
			total += count
	return total


## Takes one copy at or below `max_tier` out of the pool; "" when none is left (6.1.4).
func draw(max_tier: int, rng: RandomNumberGenerator) -> String:
	var total: int = eligible_copies(max_tier)
	if total <= 0:
		return ""
	var pick: int = rng.randi_range(0, total - 1)
	for id: String in _order:
		var tier: int = _tiers[id]
		if tier > max_tier:
			continue
		var count: int = _copies[id]
		if pick < count:
			_copies[id] = count - 1
			return id
		pick -= count
	return ""


## Takes one copy of a specific unit; false if none is left.
func take(def_id: String) -> bool:
	if copies_left(def_id) <= 0:
		return false
	_copies[def_id] = copies_left(def_id) - 1
	return true


## Returns `count` copies of a unit (5.3). Units the pool never held are ignored (5.3.6).
func give_back(def_id: String, count: int = 1) -> void:
	if not _copies.has(def_id) or count <= 0:
		return
	_copies[def_id] = copies_left(def_id) + count


func total_copies() -> int:
	return eligible_copies(UnitLibrary.TIERS)
