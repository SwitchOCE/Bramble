class_name BotLobby
extends RefCounted
## Who a player meets at a difficulty. The game, tools/play and the bench all seat bots from here.
## Levels that follow builds get "level:varied" seats, which GameSession turns into different
## builds once it knows the lobby's tribes: a lobby of seven of one build is a worse game.

const VARIED: String = "varied"
const SEATS: int = 7


## The bot names for a difficulty (a BotLevel name).
static func seats(difficulty: String) -> Array:
	var seat: String = difficulty
	if BotLevel.of(difficulty).uses_builds:
		seat = "%s:%s" % [difficulty, VARIED]
	var out: Array = []
	for _seat: int in SEATS:
		out.append(seat)
	return out


## Replaces each varied seat with a build open in this lobby. Seeded; no build repeats until every
## open build has been dealt.
static func resolve(
	names: PackedStringArray, lobby_tribes: PackedStringArray, rng: RandomNumberGenerator
) -> PackedStringArray:
	var out: PackedStringArray = []
	var deck: Array = []
	var marker: String = ":%s" % VARIED
	for bot_name: String in names:
		if not bot_name.contains(marker):
			out.append(bot_name)
			continue
		if deck.is_empty():
			deck = _shuffled_builds(lobby_tribes, rng)
		out.append(bot_name.replace(marker, ":%s" % str(deck.pop_back())))
	return out


static func _shuffled_builds(lobby_tribes: PackedStringArray, rng: RandomNumberGenerator) -> Array:
	var ids: Array = []
	for entry: Dictionary in BotKnowledge.shared().open_strategies(Array(lobby_tribes)):
		ids.append(str(entry["id"]))
	for index: int in range(ids.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var swap: Variant = ids[index]
		ids[index] = ids[other]
		ids[other] = swap
	return ids
