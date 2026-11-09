# gdlint:disable=class-variable-name
# REGISTRY is the existing public API; profile tables can now extend it at run time.
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
const FREE_CHOICE_BRAIN := preload("res://tools/sim/free_choice.gd")
const LINE_BRAIN := preload("res://tools/sim/line_brain.gd")
const BASE_REGISTRY: Dictionary = {
	"hard": {"profile": "hard", "script": BEST_BRAIN},
	"hard_field": {"profile": "hard", "script": preload("res://tools/sim/field_hard.gd")},
	"hard_stream":
	{
		"profile": "hard",
		"script": preload("res://tools/sim/hard_stream.gd"),
		"aa_with": "hard",
	},
	"free_choice": {"profile": "hard", "script": FREE_CHOICE_BRAIN},
	"free_choice_plain": {"profile": "hard", "script": FREE_CHOICE_BRAIN},
	"carrier_upgrade": {"profile": "hard", "script": BEST_BRAIN},
	"rule": {"profile": "hard@rule", "script": BEST_BRAIN},
	"shuffled": {"profile": "hard@shuffled", "script": BEST_BRAIN},
}
const SEATS: int = 8
## Ensemble candidate: over the swapped legs, exactly the all-line lobby's eight profiles.
const LINE_MIXTURE: String = "line_mixture"
## Historical tribal-only composition for a real, equal-placement strength comparison.
const TRIBAL_MIXTURE: String = "tribal_mixture"
## Test bot: a strategy that plays badly on purpose, proving the report catches a weak line.
const PLANTED: String = "plant_bad"
static var REGISTRY: Dictionary = _registry()


static func _registry() -> Dictionary:
	var out: Dictionary = BASE_REGISTRY.duplicate()
	for id: String in LinePolicies.profiles():
		out[id] = {"profile": "hard@blind", "script": LINE_BRAIN}
	for id: String in LinePolicies.ALIASES:
		if not out.has(id):
			out[id] = {"profile": "hard@blind", "script": LINE_BRAIN}
	for id: String in LinePolicies.BASES:
		out[id] = {"profile": "hard@blind", "script": LINE_BRAIN}
	for id: String in ["line_tempo", "line_engine"]:
		out[id] = {"profile": "hard@blind", "script": LINE_BRAIN}
	return out


static func reload_lines(path: String) -> void:
	LinePolicies.load_profiles(path)
	REGISTRY = _registry()


static func is_known(suite: String) -> bool:
	return (
		_has_focus(suite)
		or suite in ["spread", "plant", "head_to_head", "free_choice", "free_choice_plain", "lines"]
	)


static func is_candidate(bot: String, suite: String) -> bool:
	return REGISTRY.has(bot) or (bot in [LINE_MIXTURE, TRIBAL_MIXTURE] and suite == "head_to_head")


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
	if suite == "lines":
		var line_order: Array = [
			"hard_field:varied",
			"line_engine:varied",
			"hard_field:varied",
			"line_engine:varied",
			"line_tempo:varied",
			"line_engine:varied",
			"line_tempo:varied",
			"line_fast",
		]
		var line_rng := RandomNumberGenerator.new()
		line_rng.seed = ("lines|%d" % game_seed).hash()
		_shuffle(line_order, line_rng)
		return PackedStringArray(line_order)
	if suite == "head_to_head":
		var paired: PackedStringArray = []
		var sides: Array[int] = candidate_seats(game_seed, leg)
		var mixture: PackedStringArray = []
		if candidate == LINE_MIXTURE or incumbent == LINE_MIXTURE:
			mixture = seats("lines", game_seed)
		var tribal: PackedStringArray = []
		if candidate == TRIBAL_MIXTURE or incumbent == TRIBAL_MIXTURE:
			var roles: Array = [
				"line_tempo",
				"line_engine",
				"line_tempo",
				"line_engine",
				"line_tempo",
				"line_engine",
				"line_tempo",
				"line_fast"
			]
			var tribal_rng := RandomNumberGenerator.new()
			tribal_rng.seed = ("lines|%d" % game_seed).hash()
			_shuffle(roles, tribal_rng)
			tribal = PackedStringArray(roles)
		for seat: int in SEATS:
			var name: String = candidate if sides.has(seat) else incumbent
			if name == LINE_MIXTURE:
				name = mixture[seat].get_slice(":", 0)
			elif name == TRIBAL_MIXTURE:
				name = tribal[seat]
			paired.append(name + ":varied")
		return paired
	var out: PackedStringArray = []
	if suite in ["free_choice", "free_choice_plain"]:
		for _seat: int in SEATS:
			out.append(suite)
		return out
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
	if brain_script == LINE_BRAIN:
		var line_id: String = LinePolicies.resolve(alias, strategy)
		var policy: Dictionary = LinePolicies.profiles()[line_id]
		if CoreUtil.to_int(policy.get("policy_version", 1)) >= 2:
			brain_script = preload("res://tools/sim/committed_line_brain.gd")
	var brain: BotBrain = BotBrain.from_name(resolved, brain_script)
	if brain is LineBrain:
		var line_brain: LineBrain = brain
		line_brain.configure_line(LinePolicies.resolve(alias, strategy))
	if alias == "free_choice_plain":
		brain.value = preload("res://tools/sim/plain_eval.gd").new()
		brain.value.level = brain.level
		brain.value.knowledge = brain.knowledge
	return brain


static func comparison_kind(candidate: String, incumbent: String) -> String:
	if candidate == incumbent:
		return "bookkeeping"
	if candidate in [LINE_MIXTURE, TRIBAL_MIXTURE] or incumbent in [LINE_MIXTURE, TRIBAL_MIXTURE]:
		return "promotion"
	var entry: Dictionary = REGISTRY[candidate]
	var other: Dictionary = REGISTRY[incumbent]
	if str(entry.get("aa_with", "")) == incumbent or str(other.get("aa_with", "")) == candidate:
		return "rng_aa"
	return "promotion"
