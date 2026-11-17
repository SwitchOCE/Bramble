class_name RecruitDuplicates
extends RefCounted
## Display-only preview of rulebook 7.3.1/7.3.3. Origin does not affect triples.

enum Mark { NONE, MATCH, TRIPLE }


static func marks(state: Dictionary) -> Dictionary:
	var owned: Dictionary = {}
	var normal: Dictionary = {}
	for zone: String in ["board", "hand"]:
		for raw: Variant in state.get(zone, []):
			var card: Dictionary = raw if raw is Dictionary else {}
			var id: String = _unit_id(raw)
			if id.is_empty():
				continue
			owned[id] = true
			if not GlassPieces.as_bool(card.get("golden", false)):
				normal[id] = GlassPieces.as_int(normal.get(id, 0)) + 1
	var triples: Dictionary = {}
	var shop: Array[int] = []
	for raw: Variant in state.get("shop_units", []):
		var card: Dictionary = raw if raw is Dictionary else {}
		var id: String = _unit_id(raw)
		var mark: Mark = Mark.NONE
		if owned.has(id):
			mark = Mark.MATCH
			if (
				not GlassPieces.as_bool(card.get("golden", false))
				and GlassPieces.as_int(normal.get(id, 0)) == 2
			):
				mark = Mark.TRIPLE
				triples[id] = true
		shop.append(mark)
	var out: Dictionary = {"shop": shop}
	for zone: String in ["board", "hand"]:
		var marked: Array[int] = []
		for raw: Variant in state.get(zone, []):
			var card: Dictionary = raw if raw is Dictionary else {}
			var combines: bool = (
				triples.has(_unit_id(raw)) and not GlassPieces.as_bool(card.get("golden", false))
			)
			marked.append(Mark.TRIPLE if combines else Mark.NONE)
		out[zone] = marked
	return out


static func _unit_id(raw: Variant) -> String:
	var card: Dictionary = raw if raw is Dictionary else {}
	if GlassPieces.as_bool(card.get("spell", false)):
		return ""
	return str(card.get("id", ""))
