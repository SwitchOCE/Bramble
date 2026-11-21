class_name RecruitDuplicates
extends RefCounted
## Display-only preview of rulebook 7.3.1/7.3.3. Origin does not affect triples.

enum Mark { NONE, MATCH, TRIPLE, OWNED_EDGE }


static func marks(state: Dictionary) -> Dictionary:
	var owned: Dictionary = {}
	var combining_copies: Dictionary = {}
	for zone: String in ["board", "hand"]:
		for raw: Variant in state.get(zone, []):
			var card: Dictionary = raw if raw is Dictionary else {}
			var id: String = _unit_id(card)
			if id.is_empty() or GlassPieces.as_bool(card.get("golden", false)):
				continue
			owned[id] = true
			if _can_combine(card):
				combining_copies[id] = GlassPieces.as_int(combining_copies.get(id, 0)) + 1

	var shop: Array[int] = []
	var triple_offers: Dictionary = {}
	for raw: Variant in state.get("shop_units", []):
		var card: Dictionary = raw if raw is Dictionary else {}
		var id: String = _unit_id(card)
		var mark: Mark = Mark.NONE
		if GlassPieces.as_int(combining_copies.get(id, 0)) >= 2 and _can_combine(card):
			mark = Mark.TRIPLE
			triple_offers[id] = true
		elif owned.has(id):
			mark = Mark.MATCH
		shop.append(mark)

	var out: Dictionary = {"shop": shop}
	for zone: String in ["board", "hand"]:
		var marked: Array[int] = []
		for raw: Variant in state.get(zone, []):
			var card: Dictionary = raw if raw is Dictionary else {}
			var edge: bool = triple_offers.has(_unit_id(card)) and _can_combine(card)
			marked.append(Mark.OWNED_EDGE if edge else Mark.NONE)
		out[zone] = marked
	return out


static func _unit_id(card: Dictionary) -> String:
	if GlassPieces.as_bool(card.get("spell", false)):
		return ""
	return str(card.get("id", ""))


static func _can_combine(card: Dictionary) -> bool:
	return (
		GlassPieces.as_bool(card.get("combines", true))
		and not GlassPieces.as_bool(card.get("golden", false))
	)
