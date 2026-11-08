extends RefCounted
## A card's second layer: the rulings kept off its face (docs/ideation/wording-guide.md). They live
## in the card's file as `details` (and `golden_details` when numbers double), read here by def_id
## so every view of the card shows them without the core carrying them.

const DIRS: PackedStringArray = ["res://content/units", "res://content/spells", "res://content/heroes"]

static var _cache: Dictionary = {}


## The rulings for this view's card, golden ones for a golden unit; "" when it has none.
static func for_view(view: Dictionary) -> String:
	var def: Dictionary = _def(str(view.get("def_id", "")))
	if def.is_empty():
		return ""
	var details: String = str(def.get("details", ""))
	if bool(view.get("golden", false)):
		return str(def.get("golden_details", details))
	return details


static func _def(id: String) -> Dictionary:
	if id.is_empty():
		return {}
	if _cache.has(id):
		return _cache[id]
	var found: Dictionary = {}
	for dir: String in DIRS:
		var path: String = dir.path_join(id + ".json")
		if FileAccess.file_exists(path):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if parsed is Dictionary:
				found = parsed
			break
	_cache[id] = found
	return found
