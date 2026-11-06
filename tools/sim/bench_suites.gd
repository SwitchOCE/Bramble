class_name BenchSuites
extends RefCounted
## Who sits where in each bench suite. Seats depend only on the suite and the game seed, so a run
## doesn't depend on how it's sharded. Seat 0 plays first in a round, so the focus seat and the
## strategy order are shuffled by seed.

const LADDER: Dictionary = {
	"hard_naive": ["hard", "naive"],
	"hard_easy": ["hard", "easy"],
	"hard_normal": ["hard", "normal"],
	"normal_easy": ["normal", "easy"],
	"normal_naive": ["normal", "naive"],
	"easy_naive": ["easy", "naive"],
	"place_search": ["hard", "hard"],
	"place_rule": ["hard@rule", "hard"],
	"place_shuffled": ["hard@shuffled", "hard"],
}
const SEATS: int = 8
## Test bot: a strategy that plays badly on purpose, proving the report catches a weak line.
const PLANTED: String = "plant_bad"


static func is_known(suite: String) -> bool:
	return LADDER.has(suite) or suite == "spread" or suite == "plant"


## The eight bot names, by seat.
static func seats(suite: String, game_seed: int) -> PackedStringArray:
	var out: PackedStringArray = []
	if LADDER.has(suite):
		var pair: Array = LADDER[suite]
		for _seat: int in SEATS:
			out.append(str(pair[1]))
		out[focus_seat(suite, game_seed)] = str(pair[0])
		return out
	var names: Array = _strategy_names()
	var rng := RandomNumberGenerator.new()
	rng.seed = ("%s|%d" % [suite, game_seed]).hash()
	_shuffle(names, rng)
	if suite == "plant":
		names.push_front(PLANTED)
	for seat: int in SEATS:
		out.append("hard:%s" % names[seat % names.size()])
	var order: Array = Array(out)
	_shuffle(order, rng)
	return PackedStringArray(order)


## The seat under test in a one-against-seven suite; -1 otherwise.
static func focus_seat(suite: String, game_seed: int) -> int:
	if not LADDER.has(suite):
		return -1
	var rng := RandomNumberGenerator.new()
	rng.seed = ("seat|%d" % game_seed).hash()
	return rng.randi_range(0, SEATS - 1)


static func _strategy_names() -> Array:
	var names: Array = []
	var known: Dictionary = BotKnowledge.shared().strategies
	for strategy_id: Variant in known:
		var entry: Dictionary = known[strategy_id]
		if not CoreUtil.to_bool(entry.get("pin_only", false)):
			names.append(str(strategy_id))
	names.sort()
	return names


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for index: int in range(items.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var swap: Variant = items[index]
		items[index] = items[other]
		items[other] = swap
