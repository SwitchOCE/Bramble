extends RefCounted
## A card's second layer: the rulings kept off its face (docs/ideation/wording-guide.md). They live
## in the card's file as `details` (and `golden_details` when numbers double), read here by def_id
## as a fallback. Views carry configured replacements only when an overlay changes them.

const DIRS: PackedStringArray = [
	"res://content/units", "res://content/spells", "res://content/heroes"
]

static var _cache: Dictionary = {}


## The rulings for this view's card, golden ones for a golden unit; "" when it has none.
static func for_view(view: Dictionary) -> String:
	var current: String = str(view.get("details", ""))
	if view.has("configured_details"):
		var configured: String = str(view["configured_details"])
		if current.is_empty() or configured.contains(current):
			return configured
		return (current + " " + configured).strip_edges()
	var def: Dictionary = _def(str(view.get("def_id", "")))
	if def.is_empty():
		return current
	var details: String = str(def.get("details", ""))
	if view.get("golden", false) == true:
		details = str(def.get("golden_details", details))
	return (current + " " + details).strip_edges()


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
