class_name GameContent
extends RefCounted
## What a game is played with: the mechanic registry, the card library, the standing mechanics and
## the display table, built by the core's ContentSet from every tribe folder under src/content
## (docs/ideation-track-2/ADDING-A-TRIBE.md), plus what the core does not hold about a card: its
## art and which tribe folder it came from.
##   No tribe folder: the STAND-IN cards in src/game/data/stand_in_units.json (the core's neutral
##     test cards with text and the mock-ups' art), so the game still starts.
##   Tribes present: only their cards. The stand-in spells join only when no tribe has a spell,
##     drawn with the stand-in spell art.

const STAND_IN_PATH: String = "res://src/game/data/stand_in_units.json"
## Keywords and numbers never shown on a card (rules plumbing), whatever the content says.
const HIDDEN: PackedStringArray = ["triple_reward"]
## STAND-IN art for a unit with no picture yet: a plain glass panel in its tribe's colour, made
## by tools/game/stand_in_panels.py. Named relative to assets/glass/art, which is where
## GlassPieces.art looks; `neutral` serves a tribe the tool has no colour for.
const PANEL_ART: String = "../../game/stand-in/%s"
const PANEL_PATH: String = "res://assets/game/stand-in/%s.jpg"

var registry: MechanicRegistry
var library: UnitLibrary
## The lobby's tribes, one per tribe folder: [{folder, name}], `name` the tribe the folder's cards
## carry (what GameSession's lobby list matches) and what the start screen shows. Empty on the
## stand-ins.
var tribes: Array[Dictionary] = []
## Standing mechanics every player has.
var standing: Array[StringName] = []
## id -> {name, reminder, icon, hidden}: the content's display.json entries, merged.
var display: Dictionary = {}
## Load problems from ContentSet and the card library; the game must not be played with any.
var errors: PackedStringArray = []
## True when the game runs on the stand-in cards (no tribe folder).
var stand_ins: bool = false
## card id -> stand-in art name under assets/glass/art.
var _art: Dictionary = {}
## card id -> tribe folder, for its art under assets/units.
var _folder_of: Dictionary = {}


## The game's content: every tribe folder under src/content, or the stand-ins without one.
static func load_default() -> GameContent:
	return load_folders(ContentSet.folders_in(ContentSet.ROOT))


## Content from these folders (each with a tribe.json, as ContentSet.folders_in gives them). A
## folder with a non-empty prefix is a tribe; the shared folder (prefix "") is not.
static func load_folders(paths: PackedStringArray) -> GameContent:
	var content := GameContent.new()
	var loaded: ContentSet = ContentSet.load_folders(paths)
	content.registry = loaded.registry
	content.library = loaded.library
	content.standing = loaded.standing.duplicate()
	content.display = loaded.display.duplicate(true)
	content.errors.append_array(loaded.errors)
	for path: String in paths:
		content._read_folder(path)
	var stand_in: Array = CoreUtil.to_array(_json(STAND_IN_PATH).get("cards", []))
	var wanted: Array = []
	content.stand_ins = content.tribes.is_empty()
	var tribe_spells: bool = not content.library.pool_cards(true).is_empty()
	for raw: Variant in stand_in:
		var card: Dictionary = CoreUtil.to_dict(raw)
		var spell: bool = str(card.get("kind", "unit")) == "spell"
		if content.stand_ins or (spell and not tribe_spells):
			wanted.append(card)
			content._art[str(card.get("id", ""))] = str(card.get("art", ""))
	var before: int = content.library.errors.size()
	content.library.add_cards(wanted, content.registry)
	content.errors.append_array(content.library.errors.slice(before))
	return content


## A new lobby on this content. `lobby_tribes` (tribe names, as in `tribes`) empty means all.
func new_session(game_seed: int, lobby_tribes: PackedStringArray = []) -> GameSession:
	var session: GameSession = GameSession.create(game_seed, library, registry, null, lobby_tribes)
	session.display = display
	for mechanic_id: StringName in standing:
		session.give_standing(mechanic_id)
	return session


## The tribe names the start screen offers, in folder order.
func tribe_names() -> PackedStringArray:
	var out: PackedStringArray = []
	for tribe: Dictionary in tribes:
		out.append(str(tribe["name"]))
	return out


## The tribe folder a card came from, "" for a stand-in or the shared folder.
func folder_of(card_id: String) -> String:
	return str(_folder_of.get(card_id, ""))


## The art a screen draws for a card, as a name GlassPieces.art reads (relative to
## assets/glass/art): the tribe's own picture (GlassPieces.unit_art) when it exists, else the
## plain panel in the tribe's colour; a stand-in card keeps its mock-up art.
func art_for(card_id: String) -> String:
	var folder: String = folder_of(card_id)
	if folder == "":
		return str(_art.get(card_id, ""))
	if GlassPieces.unit_art(folder, card_id) != null:
		return "../../units/%s/%s" % [folder, card_id]
	if ResourceLoader.exists(PANEL_PATH % folder):
		return PANEL_ART % folder
	return PANEL_ART % "neutral"


## How a keyword, counter, heap or mark is named on screen; "" hides it.
func display_name(key: String) -> String:
	if HIDDEN.has(key):
		return ""
	var entry: Dictionary = CoreUtil.to_dict(display.get(key, {}))
	if not entry.is_empty():
		if CoreUtil.to_bool(entry.get("hidden", false)):
			return ""
		return str(entry.get("name", key))
	return key.replace("_", " ").capitalize()


## The reminder text for a key, "" for none.
func reminder(key: String) -> String:
	var entry: Dictionary = CoreUtil.to_dict(display.get(key, {}))
	return str(entry.get("reminder", ""))


## The icon a key names in its display entry, "" for none.
func icon(key: String) -> String:
	var entry: Dictionary = CoreUtil.to_dict(display.get(key, {}))
	return str(entry.get("icon", ""))


## The screens' display table: id -> {name, reminder, icon, hidden, shown}, the content's own
## entries with the flow's hidden plumbing added. `shown` is `not hidden`, for screens that read
## it.
func display_table() -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in display:
		var entry: Dictionary = CoreUtil.to_dict(display[key]).duplicate()
		var hidden: bool = CoreUtil.to_bool(entry.get("hidden", false)) or HIDDEN.has(str(key))
		entry["hidden"] = hidden
		entry["shown"] = not hidden
		out[str(key)] = entry
	for key: String in HIDDEN:
		out[key] = {"name": "", "reminder": "", "icon": "", "hidden": true, "shown": false}
	return out


func _read_folder(path: String) -> void:
	var manifest: Dictionary = _json(path + "/tribe.json")
	if str(manifest.get("prefix", "")) == "":
		return
	var folder: String = path.get_file()
	var counts: Dictionary = {}
	var cards: Array = CoreUtil.to_array(_json(path + "/units.json").get("cards", []))
	for raw: Variant in cards:
		var card: Dictionary = CoreUtil.to_dict(raw)
		_folder_of[str(card.get("id", ""))] = folder
		for tribe: Variant in CoreUtil.to_array(card.get("tribes", [])):
			counts[str(tribe)] = CoreUtil.to_int(counts.get(str(tribe), 0)) + 1
	var tribe_name: String = ""
	for each: Variant in counts:
		if tribe_name == "" or CoreUtil.to_int(counts[each]) > CoreUtil.to_int(counts[tribe_name]):
			tribe_name = str(each)
	if tribe_name == "":
		# a folder whose cards carry no tribe (the test content): named after the folder, and it
		# joins every lobby, as tribeless cards do
		tribe_name = folder.capitalize()
	tribes.append({"folder": folder, "name": tribe_name})


static func _json(file: String) -> Dictionary:
	if not FileAccess.file_exists(file):
		return {}
	return CoreUtil.to_dict(JSON.parse_string(FileAccess.get_file_as_string(file)))
