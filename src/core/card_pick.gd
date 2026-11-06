class_name CardPick
extends RefCounted
## The one "pick N from a pool" function (owner, direction-summary Engineering; rulebook 6.1.3;
## architecture-notes 7). The shop, Discover, the Triple Reward and effects all call run() with a
## spec: which pool, how copies are weighted, what may appear, and whether picks leave the pool.

## Each copy left is equally likely (6.1.3).
const COPIES: String = "copies"
## Each unit with a copy left is equally likely, however many copies it has.
const UNIFORM: String = "uniform"
## Copies, multiplied by tier_weights[tier - 1].
const TIER_WEIGHTED: String = "tier_weighted"

var count: int = 1
var algorithm: String = COPIES
var min_tier: int = 1
var max_tier: int = UnitLibrary.TIERS
## A card must have one of these tribes, if any are listed.
var tribes: PackedStringArray = []
var not_tribes: PackedStringArray = []
var exclude: PackedStringArray = []
## Optional extra rule: include.call(def_id) -> bool.
var include: Callable = Callable()
var tier_weights: Array[int] = []
## 6.2.2: the picks are different cards.
var distinct: bool = false
## True: picks leave the pool now (5.3.3). False: they stay, and the pool is only looked at.
var remove: bool = true


static func spec(how_many: int, top_tier: int, bottom_tier: int = 1) -> CardPick:
	var pick := CardPick.new()
	pick.count = how_many
	pick.max_tier = top_tier
	pick.min_tier = bottom_tier
	return pick


## Up to `count` card ids, fewer if the pool runs out (6.1.4, 6.2.3).
func run(pool: UnitPool, rng: RandomNumberGenerator) -> PackedStringArray:
	if _is_plain():
		return _run_plain(pool, rng)
	var ids: PackedStringArray = []
	var weights: Array[int] = []
	for id: String in pool.ids():
		var weight: int = _weight(pool, id)
		if weight > 0:
			ids.append(id)
			weights.append(weight)
	var out: PackedStringArray = []
	for _pick: int in count:
		var index: int = _draw_index(weights, rng)
		if index < 0:
			break
		var id: String = ids[index]
		out.append(id)
		if remove:
			pool.take(id)
		if distinct:
			weights[index] = 0
		else:
			weights[index] = _weight(pool, id) if remove else weights[index]
	return out


func _is_plain() -> bool:
	return (
		algorithm == COPIES
		and tribes.is_empty()
		and not_tribes.is_empty()
		and exclude.is_empty()
		and not include.is_valid()
		and not distinct
		and remove
	)


## The common case (every shop slot) needs no scan.
func _run_plain(pool: UnitPool, rng: RandomNumberGenerator) -> PackedStringArray:
	var out: PackedStringArray = []
	for _pick: int in count:
		var id: String = pool.draw(max_tier, rng, min_tier)
		if id == "":
			break
		out.append(id)
	return out


func _weight(pool: UnitPool, id: String) -> int:
	var copies: int = pool.copies_left(id)
	var tier: int = pool.tier_of(id)
	if copies <= 0 or tier < min_tier or tier > max_tier or exclude.has(id):
		return 0
	if not _tribes_fit(pool.tribes_of(id)):
		return 0
	if include.is_valid():
		var allowed: bool = include.call(id)
		if not allowed:
			return 0
	match algorithm:
		UNIFORM:
			return 1
		TIER_WEIGHTED:
			return copies * tier_weights[mini(tier - 1, tier_weights.size() - 1)]
	return copies


func _tribes_fit(card_tribes: Array) -> bool:
	for tribe: String in not_tribes:
		if card_tribes.has(tribe):
			return false
	if tribes.is_empty():
		return true
	for tribe: String in tribes:
		if card_tribes.has(tribe):
			return true
	return false


static func _draw_index(weights: Array[int], rng: RandomNumberGenerator) -> int:
	var total: int = 0
	for weight: int in weights:
		total += weight
	if total <= 0:
		return -1
	var roll: int = rng.randi_range(0, total - 1)
	for index: int in weights.size():
		if roll < weights[index]:
			return index
		roll -= weights[index]
	return -1
