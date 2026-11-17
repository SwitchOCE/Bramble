class_name RecordState
extends RefCounted
## Complete persistent rules state, not the smaller UI views. Script variables are included
## automatically so a new counter or stat layer cannot silently escape the replay check.

const SESSION_SKIP: PackedStringArray = [
	"registry",
	"library",
	"recruit",
	"rules",
	"geometry",
	"display",
	"events",
	"fights",
	"keep_fight_events",
	"record",
	"record_recipe",
]


static func session_state(game: GameSession) -> Dictionary:
	var out: Dictionary = fields(game, SESSION_SKIP)
	out["recruit_rng"] = fields(game.recruit, ["session", "_session_ref"])
	return out


static func state_hash(game: GameSession) -> String:
	return JSON.stringify(session_state(game)).sha256_text()


static func fields(object: Object, skip: PackedStringArray = []) -> Dictionary:
	var out: Dictionary = {}
	for property: Dictionary in object.get_property_list():
		var key: String = str(property["name"])
		if (
			CoreUtil.to_int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE
			and not skip.has(key)
		):
			out[key] = value(object.get(key))
	return out


static func value(raw: Variant) -> Variant:
	# Godot parses JSON numbers as floats; keep integral rules numbers canonical on disk readback.
	if raw is float:
		var number: float = raw
		if number == floor(number):
			return int(number)
		return number
	if raw is UnitDef:
		var definition: UnitDef = raw
		return String(definition.id)
	if raw is BoundMechanic:
		var bound: BoundMechanic = raw
		return {"id": String(bound.id), "params": value(bound.params), "granted": bound.granted}
	if raw is Object:
		var object: Object = raw
		return fields(object)
	if raw is Dictionary:
		var dict: Dictionary = raw
		var out: Dictionary = {}
		for key: Variant in dict:
			out[str(key)] = value(dict[key])
		return out
	if raw is Array or raw is PackedStringArray or raw is PackedInt64Array:
		var out: Array = []
		for entry: Variant in raw:
			out.append(value(entry))
		return out
	if raw is Vector2i:
		var vector: Vector2i = raw
		return [vector.x, vector.y]
	if raw is StringName:
		return str(raw)
	return raw


## Enough to build a ghost, including Reserve, permanent buffs, granted effects and heaps.
static func fight_players(game: GameSession) -> Array:
	var out: Array = []
	for player: PlayerState in game.alive_players():
		var entry: Dictionary = {}
		for key: String in [
			"id", "tier", "board", "hand", "slots", "counters", "heaps", "standing"
		]:
			entry[key] = value(player.get(key))
		out.append(entry)
	if (
		game.ghost_player != null
		and game.pairings.any(func(pair: Array) -> bool: return pair.has(Matchmaking.GHOST))
	):
		var ghost: Dictionary = {}
		for key: String in ["tier", "slots", "counters", "heaps", "standing"]:
			ghost[key] = value(game.ghost_player.get(key))
		ghost["id"] = Matchmaking.GHOST
		ghost["of"] = game.ghost_of
		ghost["board"] = value(game.ghost_board)
		ghost["hand"] = value(game.ghost_hand)
		out.append(ghost)
	return out
