extends RefCounted
## Identity-only comparison of the board a scout showed with its recruit board at fight time.
## Sold, tripled and swallowed copies count as gone; a same-named replacement is a new identity.


static func compare(seen: Array, actual: Array, library: UnitLibrary) -> Dictionary:
	var out: Dictionary = {
		"all": _counts(), "mirers": _counts(), "top_attack": _counts(), "exact": true
	}
	var strongest: int = -1
	for entry: Variant in seen:
		if entry is Dictionary:
			var card: Dictionary = entry
			strongest = maxi(strongest, CoreUtil.to_int(card.get("attack", 0)))
	for slot: int in BoardGeometry.SLOTS:
		var old: Dictionary = _entry(seen, slot)
		var now: Dictionary = _entry(actual, slot)
		if old.get("iid", 0) != now.get("iid", 0):
			out["exact"] = false
		if old.is_empty():
			continue
		var iid: int = CoreUtil.to_int(old["iid"])
		var destination: int = -1
		for candidate: int in actual.size():
			if CoreUtil.to_int(_entry(actual, candidate).get("iid", 0)) == iid:
				destination = candidate
				break
		var result: String = (
			"gone" if destination < 0 else ("same" if destination == slot else "moved")
		)
		_add(out, "all", result)
		var def: Dictionary = library.get_unit(str(old["def_id"]))
		var keywords: Array = def.get("keywords", [])
		if keywords.has("Mire"):
			_add(out, "mirers", result)
		if CoreUtil.to_int(old.get("attack", 0)) == strongest:
			_add(out, "top_attack", result)
	return out


static func _entry(board: Array, slot: int) -> Dictionary:
	return board[slot] if slot < board.size() and board[slot] is Dictionary else {}


static func _counts() -> Dictionary:
	return {"units": 0, "same": 0, "moved": 0, "gone": 0}


static func _add(report: Dictionary, group: String, result: String) -> void:
	var counts: Dictionary = report[group]
	counts["units"] += 1
	counts[result] += 1
