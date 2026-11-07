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
	"easy_naive": ["easy", "naive"],
	"place_search": ["hard", "hard"],
	"place_rule": ["hard@rule", "hard"],
	"place_shuffled": ["hard@shuffled", "hard"],
	"place_shuffled_all": ["hard@shuffled_all", "hard"],
	"place_big": ["hard@search=200", "hard"],
	"blind_alone": ["hard@blind", "hard"],
	"blind_lobby": ["hard@blind", "hard@blind"],
	"blind_shuffled": ["hard@shuffled_blind", "hard@blind"],
}
## The focus Hard among the lobby a player meets at that difficulty. Naive and Easy follow no
## builds, so hard_naive and hard_easy already are those lobbies.
const LOBBIES: Dictionary = {
	"hard_lobby_normal": BotLevel.NORMAL,
	"hard_lobby_normal4": BotLevel.NORMAL,
	"hard_lobby_hard": BotLevel.HARD,
}
const SEATS: int = 8
## Normal shops less than Hard on purpose; this arm shows Hard's place if it didn't.
const NORMAL_AT_4: String = "hard_lobby_normal4"
## Test bot: a strategy that plays badly on purpose, proving the report catches a weak line.
const PLANTED: String = "plant_bad"


static func is_known(suite: String) -> bool:
	return _has_focus(suite) or suite == "spread" or suite == "plant"


## A test seat with far more search than a phone can afford; its turns aren't timed as Hard's.
static func is_big_search(bot: String) -> bool:
	return bot.contains("search=")


## The eight bot names, by seat.
static func seats(suite: String, game_seed: int) -> PackedStringArray:
	var out: PackedStringArray = []
	if LOBBIES.has(suite):
		out = PackedStringArray(BotLobby.seats(str(LOBBIES[suite])))
		if suite == NORMAL_AT_4:
			for seat: int in out.size():
				out[seat] = "%s@refreshes=4" % out[seat]
		out.insert(focus_seat(suite, game_seed), "hard")
		return out
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
	if not _has_focus(suite):
		return -1
	var rng := RandomNumberGenerator.new()
	rng.seed = ("seat|%d" % game_seed).hash()
	return rng.randi_range(0, SEATS - 1)


static func _has_focus(suite: String) -> bool:
	return LADDER.has(suite) or LOBBIES.has(suite)


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


## Applies "key:value;key:value" config overrides (bench.sh's BENCH_SET); ints, bools or strings.
## The keys must already exist in the config. Returns "" or the problem.
static func apply_settings(config: GameConfig, text: String) -> String:
	for pair: String in text.split(";", false):
		var parts: PackedStringArray = pair.split(":", true, 1)
		if parts.size() != 2 or config.get_value(parts[0]) == null:
			return "bad setting %s" % pair
		var raw: String = parts[1]
		if raw == "true" or raw == "false":
			config.set_value(parts[0], raw == "true")
		elif raw.is_valid_int():
			config.set_value(parts[0], raw.to_int())
		else:
			config.set_value(parts[0], raw)
	return ""
