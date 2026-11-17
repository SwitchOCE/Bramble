class_name RecruitDuplicates
extends RefCounted
## Display-only preview of rulebook 7.3.1/7.3.3. Origin does not affect triples.

enum Mark { NONE, MATCH, TRIPLE }


static func marks(state: Dictionary) -> Dictionary:
	var offered: Dictionary = {}
	var copies: Dictionary = {}
	var normal: Dictionary = {}
	for zone: String in ["shop_units", "board", "hand"]:
		for raw: Variant in state.get(zone, []):
			var card: Dictionary = raw if raw is Dictionary else {}
			var id: String = _unit_id(raw)
			if id.is_empty():
				continue
			if zone == "shop_units":
				offered[id] = true
			copies[id] = GlassPieces.as_int(copies.get(id, 0)) + 1
			if _can_combine(card):
				normal[id] = GlassPieces.as_int(normal.get(id, 0)) + 1
	var out: Dictionary = {}
	for zone: String in ["shop_units", "board", "hand"]:
		var marked: Array[int] = []
		for raw: Variant in state.get(zone, []):
			var card: Dictionary = raw if raw is Dictionary else {}
			var id: String = _unit_id(raw)
			var mark: Mark = Mark.NONE
			if offered.has(id):
				# Brief 4: a match marks the shop card; owned copies glow only for a triple.
				if zone == "shop_units" and GlassPieces.as_int(copies.get(id, 0)) >= 2:
					mark = Mark.MATCH
				if _can_combine(card) and GlassPieces.as_int(normal.get(id, 0)) >= 3:
					mark = Mark.TRIPLE
			marked.append(mark)
		out["shop" if zone == "shop_units" else zone] = marked
	return out


static func _unit_id(raw: Variant) -> String:
	var card: Dictionary = raw if raw is Dictionary else {}
	if GlassPieces.as_bool(card.get("spell", false)):
		return ""
	return str(card.get("id", ""))


static func _can_combine(card: Dictionary) -> bool:
	return (
		GlassPieces.as_bool(card.get("combines", true))
		and not GlassPieces.as_bool(card.get("golden", false))
	)
