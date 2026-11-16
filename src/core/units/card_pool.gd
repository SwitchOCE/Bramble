class_name CardPool
extends RefCounted
## One shared pool (rulebook 5.1): copies left per card, one pool for units and one for Tavern
## spells. Draws follow 6.1.3: one copy drawn uniformly from all copies left at or below a tier,
## so each card's chance is proportional to its copies left. 5.1.3 / 5.2.7: only cards with a
## lobby tribe, plus neutral cards. Adapted from the first run's UnitPool.

var _copies: Dictionary = {}
var _start: Dictionary = {}
var _tiers: Dictionary = {}
var _order: Array[StringName] = []


## `copies_by_tier` is 5.1.2's row for this kind of card. Empty `lobby_tribes` lets every
## tribe in.
static func create(
	cards: Array[UnitDef], copies_by_tier: Array[int], lobby_tribes: PackedStringArray
) -> CardPool:
	var pool := CardPool.new()
	for card: UnitDef in cards:
		if not _in_lobby(card, lobby_tribes):
			continue
		var copies: int = copies_by_tier[card.tier - 1] if card.tier <= copies_by_tier.size() else 0
		pool._order.append(card.id)
		pool._tiers[card.id] = card.tier
		pool._copies[card.id] = copies
		pool._start[card.id] = copies
	return pool


static func _in_lobby(card: UnitDef, lobby_tribes: PackedStringArray) -> bool:
	if lobby_tribes.is_empty() or card.tribes.is_empty():
		return true
	for tribe: String in lobby_tribes:
		if card.has_tribe(tribe):
			return true
	return false


func ids() -> Array[StringName]:
	return _order.duplicate()


func has_card(card_id: StringName) -> bool:
	return _copies.has(card_id)


func copies_left(card_id: StringName) -> int:
	return CoreUtil.to_int(_copies.get(card_id, 0))


## The copies the pool started with: copies left plus every copy out of it must equal this.
func starting_copies(card_id: StringName) -> int:
	return CoreUtil.to_int(_start.get(card_id, 0))


func tier_of(card_id: StringName) -> int:
	return CoreUtil.to_int(_tiers.get(card_id, 0))


func eligible_copies(min_tier: int, max_tier: int, exclude: Array[StringName] = []) -> int:
	var total: int = 0
	for card_id: StringName in _order:
		var tier: int = tier_of(card_id)
		if tier >= min_tier and tier <= max_tier and not exclude.has(card_id):
			total += copies_left(card_id)
	return total


## 6.1.3: takes one random copy with a tier in [min_tier, max_tier], each copy equally likely,
## skipping `exclude` (6.2.2: Discover options are different cards). &"" when none is left
## (6.1.4, 6.2.3).
func draw(min_tier: int, max_tier: int, rng: Rng, exclude: Array[StringName] = []) -> StringName:
	var total: int = eligible_copies(min_tier, max_tier, exclude)
	if total <= 0:
		return &""
	var pick: int = rng.range_int(0, total - 1)
	for card_id: StringName in _order:
		var tier: int = tier_of(card_id)
		if tier < min_tier or tier > max_tier or exclude.has(card_id):
			continue
		var count: int = copies_left(card_id)
		if pick < count:
			_copies[card_id] = count - 1
			return card_id
		pick -= count
	return &""


## Takes one copy of a specific card; false if none is left.
func take(card_id: StringName) -> bool:
	if copies_left(card_id) <= 0:
		return false
	_copies[card_id] = copies_left(card_id) - 1
	return true


## Returns `count` copies (5.3). Cards the pool never held are ignored (5.3.6).
func give_back(card_id: StringName, count: int = 1) -> void:
	if not _copies.has(card_id) or count <= 0:
		return
	_copies[card_id] = copies_left(card_id) + count


func total_left() -> int:
	var total: int = 0
	for card_id: StringName in _order:
		total += copies_left(card_id)
	return total
