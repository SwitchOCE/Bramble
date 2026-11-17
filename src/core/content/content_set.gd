class_name ContentSet
extends RefCounted
## The one game set-up: builds the mechanic registry, the card library, the standing mechanics
## and the display table from content folders, so adding a tribe adds files only
## (docs/ideation-track-2/ADDING-A-TRIBE.md). A content folder holds:
##   tribe.json    {"prefix": "badger_", "standing": ["badger_..."]}  (prefix "" for shared)
##   mechanics/    one script per mechanic; its id is prefix + file name ("fury.gd" ->
##                 "badger_fury")
##   units.json    {"cards": [...]}, as UnitLibrary reads it
##   display.json  {"id": {"name", "reminder", "icon", "hidden"}} for keywords and counters
## Every problem (a duplicate id, a card naming an unknown mechanic) is collected in `errors`.

## Where the game's own content lives: shared keywords and one folder per tribe.
const ROOT: String = "res://src/content"
## The only folder whose tribe.json may have no prefix.
const SHARED: String = "shared"
## Display entries the core owns, shared by every tribe (a slot buff, mice and pigeons).
const CORE_DISPLAY: Dictionary = {
	"slot_buff":
	{
		"name": "Slot buff",
		"reminder": "Stays on the slot. Any unit standing there has it.",
		"icon": "slot_buff",
		"hidden": false,
	},
}

var registry: MechanicRegistry
var library: UnitLibrary
## Mechanic id, counter, heap or keyword name -> {"name", "reminder", "icon", "hidden"}.
var display: Dictionary = {}
## Standing mechanics every player gets (GameSession.give_standing).
var standing: Array[StringName] = []
## Folder names loaded, in order.
var folders: PackedStringArray = []
var errors: PackedStringArray = []


## The content folders under `root` (each with a tribe.json), sorted; `only` keeps those named
## (plus "shared", always).
static func folders_in(root: String, only: PackedStringArray = []) -> PackedStringArray:
	var out: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(root)
	if dir == null:
		return out
	for name: String in dir.get_directories():
		if not FileAccess.file_exists("%s/%s/tribe.json" % [root, name]):
			continue
		if only.is_empty() or only.has(name) or name == "shared":
			out.append("%s/%s" % [root, name])
	out.sort()
	return out


## Loads the folders in order: every folder's mechanics first, then every folder's cards.
static func load_folders(paths: PackedStringArray) -> ContentSet:
	var made := ContentSet.new()
	made.registry = MechanicRegistry.with_built_ins()
	made.library = UnitLibrary.with_system_cards(made.registry)
	made.display = CORE_DISPLAY.duplicate(true)
	for path: String in paths:
		made._load_mechanics(path)
	for mechanic_id: StringName in made.standing:
		if not made.registry.has(mechanic_id):
			made.errors.append("standing mechanic %s is not registered" % mechanic_id)
	for path: String in paths:
		made._load_cards(path)
	made.errors.append_array(made.registry.errors)
	made.errors.append_array(made.library.errors)
	return made


## A new game on this content, with the standing mechanics given to every player.
func session(
	game_seed: int, config: GameConfig = null, lobby_tribes: PackedStringArray = []
) -> GameSession:
	var made: GameSession = GameSession.create(game_seed, library, registry, config, lobby_tribes)
	made.display = display
	for mechanic_id: StringName in standing:
		made.give_standing(mechanic_id)
	return made


func _load_mechanics(path: String) -> void:
	var manifest: Dictionary = _json(path + "/tribe.json")
	var prefix: String = CoreUtil.to_text(manifest.get("prefix", ""))
	folders.append(path.get_file())
	if prefix == "" and path.get_file() != SHARED:
		errors.append("%s: tribe.json has no prefix (only the shared folder may have none)" % path)
	elif prefix != "" and registry.prefixes.has(prefix):
		errors.append("%s: the prefix %s is already used by another folder" % [path, prefix])
	elif prefix != "":
		registry.prefixes.append(prefix)
	var own: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(path + "/mechanics")
	if dir != null:
		var files: PackedStringArray = dir.get_files()
		files.sort()
		for file: String in files:
			var script_file: String = file.trim_suffix(".remap")
			if not script_file.ends_with(".gd"):
				continue
			var script: GDScript = load("%s/mechanics/%s" % [path, script_file])
			var instance: Object = script.new() if script != null else null
			var mechanic: Mechanic = instance as Mechanic
			var mechanic_id := StringName(prefix + script_file.get_basename())
			if mechanic == null:
				errors.append(
					(
						"%s: mechanics/%s does not extend Mechanic; put helper code in lib/"
						% [path, script_file]
					)
				)
				continue
			if registry.register(mechanic_id, mechanic) and prefix != "":
				own.append(String(mechanic_id))
	for value: Variant in CoreUtil.to_array(manifest.get("standing", [])):
		standing.append(StringName(str(value)))
	var table: Dictionary = _json(path + "/display.json") if _has(path, "display.json") else {}
	for key: Variant in table:
		if display.has(str(key)):
			errors.append("%s: display id %s is already used" % [path, key])
		if not str(key).begins_with(prefix):
			errors.append("%s: display id %s lacks the prefix %s" % [path, key, prefix])
		display[str(key)] = table[key]
	for mechanic_name: String in own:
		if not display.has(mechanic_name):
			errors.append("%s: mechanic %s has no display entry" % [path, mechanic_name])


func _load_cards(path: String) -> void:
	if _has(path, "units.json"):
		var cards: Dictionary = _json(path + "/units.json")
		library.add_cards(CoreUtil.to_array(cards.get("cards", [])), registry)


static func _has(path: String, file: String) -> bool:
	return FileAccess.file_exists("%s/%s" % [path, file])


func _json(file: String) -> Dictionary:
	var parsed: Dictionary = CoreUtil.to_dict(
		JSON.parse_string(FileAccess.get_file_as_string(file))
	)
	if parsed.is_empty():
		errors.append("%s is missing or not a JSON object" % file)
	return parsed
