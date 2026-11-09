class_name UnitPool
extends RefCounted
## One shared pool (rulebook 5.1): copies left per card, for units or for spells. Draws follow
## 6.1.3: one copy drawn uniformly from all copies left at or below a tier.
## 5.1.3: only cards with a tribe in the lobby are in it, plus neutral cards (5.2.7).

## id -> copies left.
var _copies: Dictionary = {}
var _tiers: Dictionary = {}
var _tribes: Dictionary = {}
## Ids per tier index (tier - 1), in the library's order (tier then name), and copies left per
## tier, so a draw doesn't scan every card.
var _by_tier: Array[PackedStringArray] = []
var _left_by_tier: Array[int] = []
var _order: PackedStringArray = []


## The lobby's unit pool. `lobby_tribes` empty means every tribe is in.
static func create(
	library: UnitLibrary, config: GameConfig, lobby_tribes: PackedStringArray = []
) -> UnitPool:
	library = ScaleOverlay.library_for(library, config)
	var skeleton_only: bool = config.get_string("pool_filter") == "skeleton"
	var units: Array[Dictionary] = []
	for unit: Dictionary in library.pool_units(config.card_set()):
		if not skeleton_only or unit["skeleton"]:
			units.append(unit)
	for id: String in ScaleOverlay.selected_levers(config):
		var lever: Dictionary = library.get_unit(id)
		if not lever.is_empty() and not units.has(lever):
			units.append(lever)
	return from_cards(units, config, "pool_copies_by_tier", lobby_tribes)


## A pool of any cards with a "tier" (and optional "tribes"): `copies_key` is the config table of
## copies per tier (5.1.2 has one row for units and one for spells).
static func from_cards(
	cards: Array[Dictionary],
	config: GameConfig,
	copies_key: String,
	lobby_tribes: PackedStringArray
) -> UnitPool:
	var pool := UnitPool.new()
	pool._by_tier.resize(UnitLibrary.TIERS)
	pool._left_by_tier.resize(UnitLibrary.TIERS)
	for card: Dictionary in cards:
		var card_tribes: Array = card.get("tribes", [])
		if not _in_lobby(card_tribes, lobby_tribes):
			continue
		var id: String = card["id"]
		var tier: int = CoreUtil.to_int(card["tier"])
		var copies: int = config.get_int_at(copies_key, tier - 1)
		pool._order.append(id)
		pool._tiers[id] = tier
		pool._tribes[id] = card_tribes
		pool._copies[id] = copies
		pool._by_tier[tier - 1].append(id)
		pool._left_by_tier[tier - 1] += copies
	return pool


static func _in_lobby(card_tribes: Array, lobby_tribes: PackedStringArray) -> bool:
	if lobby_tribes.is_empty() or card_tribes.is_empty():
		return true
	for tribe: Variant in card_tribes:
		if lobby_tribes.has(str(tribe)):
			return true
	return false


func ids() -> PackedStringArray:
	return _order


func tier_of(def_id: String) -> int:
	var tier: int = _tiers.get(def_id, 0)
	return tier


func tribes_of(def_id: String) -> Array:
	var tribes: Array = _tribes.get(def_id, [])
	return tribes


func copies_left(def_id: String) -> int:
	var count: int = _copies.get(def_id, 0)
	return count


func has_unit(def_id: String) -> bool:
	return _copies.has(def_id)


## Total copies left at or below `max_tier` (and at or above `min_tier`).
func eligible_copies(max_tier: int, min_tier: int = 1) -> int:
	var total: int = 0
	for tier: int in range(maxi(min_tier, 1), mini(max_tier, UnitLibrary.TIERS) + 1):
		total += _left_by_tier[tier - 1]
	return total


## Takes one random copy at or below `max_tier` out of the pool, each copy equally likely; ""
## when none is left (6.1.4). `min_tier` narrows it (the Triple Reward draws one tier).
func draw(max_tier: int, rng: RandomNumberGenerator, min_tier: int = 1) -> String:
	var total: int = eligible_copies(max_tier, min_tier)
	if total <= 0:
		return ""
	var pick: int = rng.randi_range(0, total - 1)
	for tier: int in range(maxi(min_tier, 1), mini(max_tier, UnitLibrary.TIERS) + 1):
		if pick >= _left_by_tier[tier - 1]:
			pick -= _left_by_tier[tier - 1]
			continue
		for id: String in _by_tier[tier - 1]:
			var count: int = _copies[id]
			if pick < count:
				_copies[id] = count - 1
				_left_by_tier[tier - 1] -= 1
				return id
			pick -= count
	return ""


## Takes one random copy: first a tier by `odds` (weights by tier; empty tiers drop out),
## then each copy of that tier equally. Empty odds is draw(). "" when nothing is left.
func draw_by_odds(odds: Array, max_tier: int, rng: RandomNumberGenerator) -> String:
	if odds.is_empty():
		return draw(max_tier, rng)
	var total: int = 0
	for tier: int in range(1, mini(max_tier, odds.size()) + 1):
		if _left_by_tier[tier - 1] > 0:
			total += CoreUtil.to_int(odds[tier - 1])
	if total <= 0:
		return draw(max_tier, rng)
	var roll: int = rng.randi_range(0, total - 1)
	for tier: int in range(1, mini(max_tier, odds.size()) + 1):
		if _left_by_tier[tier - 1] <= 0:
			continue
		var weight: int = CoreUtil.to_int(odds[tier - 1])
		if roll < weight:
			return draw(tier, rng, tier)
		roll -= weight
	return ""


## Takes one copy of a specific card; false if none is left.
func take(def_id: String) -> bool:
	if copies_left(def_id) <= 0:
		return false
	_copies[def_id] = copies_left(def_id) - 1
	_left_by_tier[tier_of(def_id) - 1] -= 1
	return true


## Returns `count` copies of a card (5.3). Cards the pool never held are ignored (5.3.6).
func give_back(def_id: String, count: int = 1) -> void:
	if not _copies.has(def_id) or count <= 0:
		return
	_copies[def_id] = copies_left(def_id) + count
	_left_by_tier[tier_of(def_id) - 1] += count


func total_copies() -> int:
	return eligible_copies(UnitLibrary.TIERS)
