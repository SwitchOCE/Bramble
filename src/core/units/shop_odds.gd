class_name ShopOdds
extends RefCounted
## Fixed weights for one kind of offer: units or Tavern spells. Includes neutral cards
## and cards that match any lobby tribe. The table is built once from the lobby's library
## and config. The caller supplies the RNG and any exclusions for this draw.

var _order: Array[StringName] = []
var _tiers: Dictionary[StringName, int] = {}
var _weights: Dictionary[StringName, int] = {}


## Empty `lobby_tribes` lets every tribe in.
static func create(
	cards: Array[UnitDef], weights_by_tier: Array[int], lobby_tribes: PackedStringArray
) -> ShopOdds:
	var odds := ShopOdds.new()
	for card: UnitDef in cards:
		if card.tier < 1 or card.tier > weights_by_tier.size() or not _in_lobby(card, lobby_tribes):
			continue
		var weight: int = weights_by_tier[card.tier - 1]
		if weight <= 0:
			continue
		odds._order.append(card.id)
		odds._tiers[card.id] = card.tier
		odds._weights[card.id] = weight
	odds._order.make_read_only()
	odds._tiers.make_read_only()
	odds._weights.make_read_only()
	return odds


static func _in_lobby(card: UnitDef, lobby_tribes: PackedStringArray) -> bool:
	if lobby_tribes.is_empty() or card.tribes.is_empty():
		return true
	for tribe: String in lobby_tribes:
		if card.has_tribe(tribe):
			return true
	return false


func weight_of(card_id: StringName) -> int:
	return _weights.get(card_id, 0)


## Picks an eligible card in [min_tier, max_tier] in proportion to its fixed weight.
## Discover passes the ids it has already offered. &"" means no card qualifies.
func draw(min_tier: int, max_tier: int, rng: Rng, exclude: Array[StringName] = []) -> StringName:
	var total: int = 0
	for card_id: StringName in _order:
		var tier: int = _tiers[card_id]
		if tier >= min_tier and tier <= max_tier and not exclude.has(card_id):
			total += _weights[card_id]
	if total == 0:
		return &""
	var pick: int = rng.range_int(0, total - 1)
	for card_id: StringName in _order:
		var tier: int = _tiers[card_id]
		if tier < min_tier or tier > max_tier or exclude.has(card_id):
			continue
		var weight: int = _weights[card_id]
		if pick < weight:
			return card_id
		pick -= weight
	return &""
