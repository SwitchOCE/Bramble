class_name BotLobby
extends RefCounted
## The shared best-strength lobby. The game, tools/play and the bench all seat bots from here.
## Builds get "level:varied" seats, which GameSession turns into different
## builds once it knows the lobby's tribes: a lobby of seven of one build is a worse game.

const VARIED: String = "varied"
const SEATS: int = 7


## Best-policy seats by default; Naive is a tools-only yardstick.
static func seats(profile: String = BotLevel.HARD) -> Array:
	var seat: String = profile
	if BotLevel.of(profile).uses_builds:
		seat = "%s:%s" % [profile, VARIED]
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
