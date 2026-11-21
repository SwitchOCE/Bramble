class_name GameContent
extends RefCounted
## What a game is played with: the mechanic registry, the card library, the standing mechanics and
## the display table, built by the core's ContentSet from every tribe folder under src/content
## (docs/ideation-track-2/ADDING-A-TRIBE.md), plus what the core does not hold about a card: its
## art and which tribe folder it came from.
##   No tribe folder: the STAND-IN cards in src/game/data/stand_in_units.json (the core's neutral
##     test cards with text and the mock-ups' art), so the game still starts.
##   Tribes present: their cards and the shared neutral cards. Stand-in spells join only when
##     no tribe has a spell.

const STAND_IN_PATH: String = "res://src/game/data/stand_in_units.json"
## Keywords and numbers never shown on a card (rules plumbing), whatever the content says.
const HIDDEN: PackedStringArray = ["triple_reward"]
## STAND-IN art for a unit with no picture yet: a plain glass panel in its tribe's colour, made
## by tools/game/stand_in_panels.py. Named relative to assets/glass/art, which is where
## GlassPieces.art looks; `neutral` serves a tribe the tool has no colour for.
const PANEL_ART: String = "../../game/stand-in/%s"
const PANEL_PATH: String = "res://assets/game/stand-in/%s.jpg"
## STAND-IN art for a spell with none (the Triple Reward, a tribe spell): the mock-ups' spell art.
const SPELL_ART: String = "spell-1"
## STAND-IN reminders for the core's own words, which no tribe's display table names: a card
## whose text says one gets its line in the hover.
const CORE_TERMS: Dictionary = {"Discover": "Choose 1 of 3 cards to put in your hand."}
## Text for the core's own cards, which carry none.
const SYSTEM_TEXT: Dictionary = {"triple_reward": "Discover a unit from the tier above yours."}

## A bare id such as "renown": a reminder written as an id with no display entry is skipped.
static var _bare_id: RegEx = RegEx.create_from_string("^[a-z0-9_]+$")

var record_paths: PackedStringArray = []
var registry: MechanicRegistry
var library: UnitLibrary
## The lobby's tribes, one per tribe folder: [{folder, name}], `name` the tribe the folder's cards
## carry (what GameSession's lobby list matches) and what the start screen shows. Empty on the
## stand-ins.
var tribes: Array[Dictionary] = []
## Standing mechanics every player has (when their tribe is in the game; see new_session).
var standing: Array[StringName] = []
## id -> {name, reminder, icon, hidden}: the content's display.json entries, merged.
var display: Dictionary = {}
## Load problems from ContentSet and the card library; the game must not be played with any.
var errors: PackedStringArray = []
## True when the game runs on the stand-in cards (no tribe folder).
var stand_ins: bool = false
## card id -> stand-in art name under assets/glass/art.
var _art: Dictionary = {}
## standing mechanic id -> the tribe name (as in `tribes`) whose folder gives it.
var _standing_tribe: Dictionary = {}
## card id -> tribe folder, for its art under assets/units.
var _folder_of: Dictionary = {}
## card id -> its card data's `reminders`, as given (a "Name: reminder" line or a display id).
var _card_reminders: Dictionary = {}


## The game's content: every tribe folder under src/content, or the stand-ins without one.
static func load_default() -> GameContent:
	return load_folders(ContentSet.folders_in(ContentSet.ROOT))


## Content from these folders (each with a tribe.json, as ContentSet.folders_in gives them). A
## folder with a non-empty prefix is a tribe; the shared folder (prefix "") is not.
static func load_folders(paths: PackedStringArray) -> GameContent:
	var content := GameContent.new()
	content.record_paths = paths.duplicate()
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
	var tribe_spells: bool = not content.library.drawable_cards(true).is_empty()
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
## A tribe's standing mechanics (its counters and heaps: the Compost, the Tide) are given only
## when that tribe is in the lobby: a locust-only game has no Compost.
func new_session(game_seed: int, lobby_tribes: PackedStringArray = []) -> GameSession:
	var session: GameSession = GameSession.create(game_seed, library, registry, null, lobby_tribes)
	session.record_recipe = {
		"kind": "game", "paths": Array(record_paths), "tribes": Array(lobby_tribes)
	}
	session.display = display
	for mechanic_id: StringName in standing_for(lobby_tribes):
		session.give_standing(mechanic_id)
	return session


## A new lobby with a live seat 0 and recorded runs keyed by their destination seats.
func new_async_session(
	game_seed: int, runs_by_seat: Dictionary, lobby_tribes: PackedStringArray = []
) -> GameSession:
	var session: GameSession = new_session(game_seed, lobby_tribes)
	if session.set_runs(runs_by_seat) != OK:
		return null
	return session


## The standing mechanics a lobby of these tribes (names, as in `tribes`; empty means all) has.
func standing_for(lobby_tribes: PackedStringArray) -> Array[StringName]:
	var out: Array[StringName] = []
	for mechanic_id: StringName in standing:
		var tribe: String = str(_standing_tribe.get(mechanic_id, ""))
		if lobby_tribes.is_empty() or tribe == "" or lobby_tribes.has(tribe):
			out.append(mechanic_id)
	return out


## The tribe ids (folder names) the start screen offers, in folder order.
func tribe_ids() -> PackedStringArray:
	var out: PackedStringArray = []
	for tribe: Dictionary in tribes:
		out.append(str(tribe["folder"]))
	return out


## A tribe's display name by its id (folder), "" for none.
func tribe_name(tribe_id: String) -> String:
	for tribe: Dictionary in tribes:
		if str(tribe["folder"]) == tribe_id:
			return str(tribe["name"])
	return ""


## The names GameSession's lobby list matches (the cards' tribe) for these tribe ids.
func lobby_names(tribe_ids_wanted: PackedStringArray) -> PackedStringArray:
	var out: PackedStringArray = []
	for tribe_id: String in tribe_ids_wanted:
		var found: String = tribe_name(tribe_id)
		if found != "":
			out.append(found)
	return out


## Text for a card whose data has none: the core's Triple Reward (7.3.6).
func text_for(card_id: String) -> String:
	return str(SYSTEM_TEXT.get(card_id, ""))


## The mechanic ids a card prints (its keywords and effects), for the screens' pills and reminders.
func mechanics_of(card_id: String) -> Array:
	var out: Array = []
	var card: UnitDef = library.get_card(StringName(card_id)) if library != null else null
	if card == null:
		return out
	for keyword: StringName in card.keywords:
		if not out.has(String(keyword)):
			out.append(String(keyword))
	for spec: MechanicSpec in card.mechanics:
		if not out.has(String(spec.id)):
			out.append(String(spec.id))
	return out


## The flow's own reminder lines for a card, beside what the screens find from the display table:
## its card data's `reminders` (a display id read as "Name: reminder"), then each token its text
## names with that token's numbers ("Hopper: A 2/2 Locust."). `text` is the card's text as shown.
func reminders_for(card_id: String, text: String) -> Array:
	var out: Array = []
	for value: Variant in CoreUtil.to_array(_card_reminders.get(card_id, [])):
		var line: String = str(value)
		var entry: Dictionary = CoreUtil.to_dict(display.get(line, {}))
		if not entry.is_empty():
			if CoreUtil.to_bool(entry.get("hidden", false)) or str(entry.get("name", "")) == "":
				continue
			line = "%s: %s" % [entry["name"], entry.get("reminder", "")]
		elif _bare_id.search(line) != null:
			# an id with no display entry: nothing a player should read
			continue
		if line != "" and not out.has(line):
			out.append(line)
	for term: String in CORE_TERMS:
		if display_name(term.to_lower()) == "" and _names(text, term):
			var core_line: String = "%s: %s" % [term, CORE_TERMS[term]]
			if not out.has(core_line):
				out.append(core_line)
	for token_id: StringName in _token_ids():
		var token: UnitDef = library.get_card(token_id)
		if token == null or String(token_id) == card_id or not _names(text, token.name):
			continue
		var kind: String = token.types[0] if not token.types.is_empty() else "unit"
		var line: String = "%s: A %d/%d %s." % [token.name, token.attack, token.health, kind]
		if token.text != "" and not token.text.contains("{"):
			line += " " + token.text
		out.append(line)
	return out


func _token_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	if library == null:
		return out
	for card_id: StringName in library.ids():
		var card: UnitDef = library.get_card(card_id)
		if card != null and card.token:
			out.append(card_id)
	return out


## Whether text names a card ("Hopper", "Hoppers"), as a whole word.
static func _names(text: String, card_name: String) -> bool:
	if text == "" or card_name == "":
		return false
	var regex: RegEx = RegEx.create_from_string(
		"(?<![A-Za-z])" + card_name.replace("(", "\\(").replace(")", "\\)") + "s?(?![A-Za-z])"
	)
	return regex.search(text) != null


## The content folder a card came from, or "" for a stand-in.
func folder_of(card_id: String) -> String:
	return str(_folder_of.get(card_id, ""))


## The art a screen draws for a card, as a name GlassPieces.art reads (relative to
## assets/glass/art): the tribe's own picture (GlassPieces.unit_art) when it exists, else the
## plain panel in the tribe's colour; a stand-in card keeps its mock-up art.
func art_for(card_id: String) -> String:
	var folder: String = folder_of(card_id)
	if folder == "":
		var card: UnitDef = library.get_card(StringName(card_id)) if library != null else null
		if card != null and card.is_spell():
			return str(_art.get(card_id, SPELL_ART))
		return str(_art.get(card_id, ""))
	if GlassPieces.unit_art(folder, card_id) != null:
		return "../../units/%s/%s" % [folder, card_id]
	if ResourceLoader.exists(PANEL_PATH % folder):
		return PANEL_ART % folder
	return PANEL_ART % "neutral"


## How a keyword, counter, heap or mark is named on screen: its display entry's name; "" (not
## shown) when it is hidden or has no entry.
func display_name(key: String) -> String:
	if HIDDEN.has(key):
		return ""
	var entry: Dictionary = CoreUtil.to_dict(display.get(key, {}))
	if not entry.is_empty():
		if CoreUtil.to_bool(entry.get("hidden", false)):
			return ""
		return str(entry.get("name", ""))
	# no entry: not shown (no made-up names)
	return ""


## The reminder text for a key, "" for none.
func reminder(key: String) -> String:
	var entry: Dictionary = CoreUtil.to_dict(display.get(key, {}))
	return str(entry.get("reminder", ""))


## The icon a key names in its display entry, "" for none.
func icon(key: String) -> String:
	var entry: Dictionary = CoreUtil.to_dict(display.get(key, {}))
	return str(entry.get("icon", ""))


## The screens' display table: id -> {name, reminder, icon, hidden}, the content's own entries
## with the flow's hidden plumbing added.
func display_table() -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in display:
		var entry: Dictionary = CoreUtil.to_dict(display[key]).duplicate()
		entry["hidden"] = CoreUtil.to_bool(entry.get("hidden", false)) or HIDDEN.has(str(key))
		out[str(key)] = entry
	for key: String in HIDDEN:
		out[key] = {"name": "", "reminder": "", "icon": "", "hidden": true}
	return out


func _read_folder(path: String) -> void:
	var manifest: Dictionary = _json(path + "/tribe.json")
	var folder: String = path.get_file()
	var counts: Dictionary = {}
	var cards: Array = CoreUtil.to_array(_json(path + "/units.json").get("cards", []))
	for raw: Variant in cards:
		var card: Dictionary = CoreUtil.to_dict(raw)
		_folder_of[str(card.get("id", ""))] = folder
		var lines: Array = CoreUtil.to_array(card.get("reminders", []))
		if not lines.is_empty():
			_card_reminders[str(card.get("id", ""))] = lines
		for tribe: Variant in CoreUtil.to_array(card.get("tribes", [])):
			counts[str(tribe)] = CoreUtil.to_int(counts.get(str(tribe), 0)) + 1
	if str(manifest.get("prefix", "")) == "":
		return
	var named: String = ""
	for each: Variant in counts:
		if named == "" or CoreUtil.to_int(counts[each]) > CoreUtil.to_int(counts[named]):
			named = str(each)
	if named == "":
		# a folder whose cards carry no tribe (the test content): named after the folder, and it
		# joins every lobby, as tribeless cards do
		named = folder.capitalize()
	tribes.append({"folder": folder, "name": named})
	for value: Variant in CoreUtil.to_array(manifest.get("standing", [])):
		_standing_tribe[StringName(str(value))] = named


static func _json(file: String) -> Dictionary:
	if not FileAccess.file_exists(file):
		return {}
	return CoreUtil.to_dict(JSON.parse_string(FileAccess.get_file_as_string(file)))
