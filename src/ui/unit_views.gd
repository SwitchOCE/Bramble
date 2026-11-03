extends RefCounted
## Builds display views from raw unit files (SPEC 3) for screens that show units outside a game
## (the sandbox and its library). Display only: golden doubles base stats and shows golden_text,
## as the core's views do (SPEC 4.4, 6.3).

const Data := preload("res://src/ui/view_data.gd")


static func from_def(def: Dictionary, golden: bool = false, uid: int = -1) -> Dictionary:
	var factor: int = 2 if golden else 1
	var attack: int = Data.i(def, "attack", 0) * factor
	var health: int = Data.i(def, "health", 1) * factor
	var text_key: String = "golden_text" if golden else "text"
	var source: Dictionary = Data.d(def, "source")
	var keyword_text: Array = []
	var note: String = str(source.get("note", "")) if source.get("note") != null else ""
	var keywords: Array = Data.a(def, "keywords")
	if not keywords.is_empty() and not note.is_empty():
		keyword_text.append({"keyword": str(keywords[0]), "text": note})
	return {
		"uid": uid,
		"def_id": str(def.get("id", "")),
		"name": str(def.get("name", "")),
		"tier": Data.i(def, "tier", 1),
		"tribes": Data.a(def, "tribes"),
		"attack": attack,
		"health": health,
		"max_health": health,
		"golden": golden,
		"text": str(def.get(text_key, def.get("text", ""))),
		"keywords": keywords,
		"keyword_text": keyword_text,
		"statuses": [],
		"counters": {},
	}
