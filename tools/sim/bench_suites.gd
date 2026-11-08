class_name BenchSuites
extends RefCounted
## Who sits where in each bench suite. Seats depend only on the suite and the game seed, so a run
## doesn't depend on how it's sharded. Seat 0 plays first in a round, so the focus seat and the
## strategy order are shuffled by seed.

const LADDER: Dictionary = {
	"hard_naive": ["hard", "naive"],
	"place_search": ["hard", "hard"],
	"place_rule": ["hard@rule", "hard"],
	"place_shuffled": ["hard@shuffled", "hard"],
	"place_big": ["hard@search=200", "hard"],
	"blind_alone": ["hard@blind", "hard"],
	"blind_lobby": ["hard@blind", "hard@blind"],
	"blind_shuffled": ["hard@shuffled_blind", "hard@blind"],
}
## The current best bot among the varied bots a player meets. Naive is a tools-only yardstick.
const LOBBIES: Dictionary = {
	"hard_lobby_hard": BotLevel.HARD,
}
## Add one entry for a candidate: its profile and a BotBrain subclass script. Keep the incumbent
## script unchanged while evaluating a candidate. Both receive the normal lobby build deal.
const BEST_BRAIN: GDScript = preload("res://src/core/bots/bot_brain.gd")
const REGISTRY: Dictionary = {
	"hard": {"profile": "hard", "script": BEST_BRAIN},
	"hard_stream":
	{
		"profile": "hard",
		"script": preload("res://tools/sim/hard_stream.gd"),
		"aa_with": "hard",
	},
	"carrier_upgrade": {"profile": "hard", "script": BEST_BRAIN},
	"rule": {"profile": "hard@rule", "script": BEST_BRAIN},
	"shuffled": {"profile": "hard@shuffled", "script": BEST_BRAIN},
}
const SEATS: int = 8
## Test bot: a strategy that plays badly on purpose, proving the report catches a weak line.
const PLANTED: String = "plant_bad"


static func is_known(suite: String) -> bool:
	return _has_focus(suite) or suite in ["spread", "plant", "head_to_head"]


## A test seat with far more search than a phone can afford; its turns aren't timed as Hard's.
static func is_big_search(bot: String) -> bool:
	return bot.contains("search=")


## The eight bot names, by seat.
static func seats(
	suite: String,
	game_seed: int,
	candidate: String = "hard",
	incumbent: String = "hard",
	leg: int = 0
) -> PackedStringArray:
	if suite == "head_to_head":
		var paired: PackedStringArray = []
		var sides: Array[int] = candidate_seats(game_seed, leg)
		for seat: int in SEATS:
			var name: String = candidate if sides.has(seat) else incumbent
			paired.append(name + ":varied")
		return paired
	var out: PackedStringArray = []
	if LOBBIES.has(suite):
		out = PackedStringArray(BotLobby.seats(str(LOBBIES[suite])))
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


## Same shuffled partition in both legs, with the four labels exchanged.
static func candidate_seats(game_seed: int, leg: int) -> Array[int]:
	var order: Array = range(SEATS)
	var rng := RandomNumberGenerator.new()
	rng.seed = ("head_to_head|%d" % game_seed).hash()
	_shuffle(order, rng)
	var out: Array[int] = []
	for index: int in range(4 * leg, 4 * leg + 4):
		out.append(CoreUtil.to_int(order[index]))
	return out


## Registry aliases survive the shared strategy deal, then select the policy implementation.
static func create_bot(bot_name: String) -> Bot:
	var alias: String = bot_name.get_slice(":", 0).get_slice("@", 0)
	if not REGISTRY.has(alias):
		return Bot.create(bot_name)
	var entry: Dictionary = REGISTRY[alias]
	var parts: PackedStringArray = str(entry["profile"]).split("@", true, 1)
	var named: PackedStringArray = bot_name.get_slice("@", 0).split(":", true, 1)
	var strategy: String = named[1] if named.size() > 1 else ""
	var resolved: String = parts[0] + (":" + strategy if strategy != "" else "")
	if parts.size() > 1:
		resolved += "@" + parts[1]
	elif bot_name.contains("@"):
		resolved += "@" + bot_name.get_slice("@", 1)
	var brain_script: GDScript = entry["script"]
	return BotBrain.from_name(resolved, brain_script)


static func comparison_kind(candidate: String, incumbent: String) -> String:
	if candidate == incumbent:
		return "bookkeeping"
	var entry: Dictionary = REGISTRY[candidate]
	var other: Dictionary = REGISTRY[incumbent]
	if str(entry.get("aa_with", "")) == incumbent or str(other.get("aa_with", "")) == candidate:
		return "rng_aa"
	return "promotion"
