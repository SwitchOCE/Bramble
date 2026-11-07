class_name BotKnowledge
extends RefCounted
## What bots know that the rules don't say: strategies and card hints, as data in content/bots/.
## Generic preferences live here; shared lane and adjacency rules live in BotLanes.
## Format: content/bots/README.md.

const STRATEGY_DIR: String = "res://content/bots/strategies"
const CARDS_FILE: String = "res://content/bots/cards.json"

static var _shared: BotKnowledge = null

## Strategy id -> its definition, in id order.
var strategies: Dictionary = {}
## Card or hero id -> its hints.
var cards: Dictionary = {}
var heroes: Dictionary = {}


static func shared() -> BotKnowledge:
	if _shared == null:
		_shared = BotKnowledge.new()
		_shared._load()
	return _shared


## A card's hints ({} when there are none).
func card(card_id: String) -> Dictionary:
	var entry: Dictionary = cards.get(card_id, {})
	return entry


func hero(hero_id: String) -> Dictionary:
	var entry: Dictionary = heroes.get(hero_id, {})
	return entry


## A strategy by id ({} when unknown).
func strategy(strategy_id: String) -> Dictionary:
	var entry: Dictionary = strategies.get(strategy_id, {})
	return entry


## The strategies a bot may choose by itself, playable in these tribes (empty means all).
func open_strategies(lobby_tribes: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var ids: Array = strategies.keys()
	ids.sort()
	for strategy_id: Variant in ids:
		var entry: Dictionary = strategies[strategy_id]
		if CoreUtil.to_bool(entry.get("pin_only", false)):
			continue
		if tribes_available(entry, lobby_tribes):
			out.append(entry)
	return out


## True when the lobby has every tribe the strategy names as needed.
static func tribes_available(entry: Dictionary, lobby_tribes: Array) -> bool:
	if lobby_tribes.is_empty():
		return true
	var needs: Array = entry.get("needs_tribes", [])
	for tribe: Variant in needs:
		if not lobby_tribes.has(tribe):
			return false
	return true


func _load() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CARDS_FILE))
	if typeof(raw) == TYPE_DICTIONARY:
		var data: Dictionary = raw
		cards = data.get("cards", {})
		heroes = data.get("heroes", {})
	else:
		push_error("BotKnowledge: can't read %s" % CARDS_FILE)
	var dir: DirAccess = DirAccess.open(STRATEGY_DIR)
	if dir == null:
		push_error("BotKnowledge: can't open %s" % STRATEGY_DIR)
		return
	var names: PackedStringArray = dir.get_files()
	names.sort()
	for file_name: String in names:
		if file_name.get_extension() != "json":
			continue
		var text: String = FileAccess.get_file_as_string(STRATEGY_DIR.path_join(file_name))
		var parsed: Variant = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("BotKnowledge: can't read %s" % file_name)
			continue
		var entry: Dictionary = parsed
		strategies[str(entry["id"])] = entry
