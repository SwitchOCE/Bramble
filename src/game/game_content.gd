class_name GameContent
extends RefCounted
## What a game is played with: the mechanic registry, the card library, and what the core does
## not hold about a card (its art) or a number (its display name). One seam: today it loads the
## STAND-IN cards in src/game/data/stand_in_units.json (the neutral test cards with text and
## the mock-ups' art); when the core's tribe content loader lands, `load_default` builds from it
## instead and `tribes` lists the tribes it found.

const STAND_IN_PATH: String = "res://src/game/data/stand_in_units.json"
## A tribe card's art, once the tribe workers add it: assets/units/<tribe>/<unit id>.jpg.
const UNIT_ART: String = "res://assets/units/%s/%s.jpg"
## Keywords and numbers never shown on a card (rules plumbing).
const HIDDEN: PackedStringArray = ["triple_reward"]

var registry: MechanicRegistry
var library: UnitLibrary
## Tribes the lobby can be made of; empty while only the stand-in cards exist.
var tribes: PackedStringArray = []
## Lobby set-up the content needs, such as a standing mechanic every player has.
var standing: Array[StringName] = []
## card id -> stand-in art name under assets/glass/art.
var _art: Dictionary = {}
## card id -> tribe folder, for its art under assets/units.
var _tribe_of: Dictionary = {}
## key -> display name, for keywords, counters, heaps and slot marks.
var _names: Dictionary = {}


static func load_default() -> GameContent:
	var content := GameContent.new()
	content.registry = MechanicRegistry.with_built_ins()
	content.library = UnitLibrary.from_file(STAND_IN_PATH, content.registry)
	var parsed: Dictionary = CoreUtil.to_dict(
		JSON.parse_string(FileAccess.get_file_as_string(STAND_IN_PATH))
	)
	for raw: Variant in CoreUtil.to_array(parsed.get("cards", [])):
		var card: Dictionary = CoreUtil.to_dict(raw)
		content._art[str(card.get("id", ""))] = str(card.get("art", ""))
	return content


## A new lobby on this content. `lobby_tribes` empty means every tribe.
func new_session(game_seed: int, lobby_tribes: PackedStringArray = []) -> GameSession:
	var session: GameSession = GameSession.create(game_seed, library, registry, null, lobby_tribes)
	for mechanic_id: StringName in standing:
		session.give_standing(mechanic_id)
	return session


## The art a screen draws for a card: the tribe's own picture when it exists, else the stand-in
## name under assets/glass/art. GlassPieces.art reads names under assets/glass/art, so a tribe
## picture is named by a path relative to that folder.
func art_for(card_id: String) -> String:
	var tribe: String = str(_tribe_of.get(card_id, ""))
	if tribe != "" and ResourceLoader.exists(UNIT_ART % [tribe, card_id]):
		return "../../units/%s/%s" % [tribe, card_id]
	return str(_art.get(card_id, ""))


## How a keyword, counter, heap or mark is named on screen; "" hides it.
func display_name(key: String) -> String:
	if HIDDEN.has(key):
		return ""
	if _names.has(key):
		return str(_names[key])
	return key.replace("_", " ").capitalize()
