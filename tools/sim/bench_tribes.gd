class_name BenchTribes
extends RefCounted
## Last fight-start slots, independent of declared build. Exclude all source.kind=token
## units (including Eggs) from numerator and denominator; goldens count once. Away Birds
## and Belly contents add no slots. Neutral non-token units remain in the denominator.

const NONE: String = "no_tribe"


static func final_tribe(board: Array, library: UnitLibrary) -> String:
	return str(classify(board, library)["final_tribe"])


static func classify(board: Array, library: UnitLibrary) -> Dictionary:
	var counts: Dictionary = {}
	var occupied: int = 0
	var tokens: int = 0
	for entry: Variant in board:
		if entry == null:
			continue
		var unit: Dictionary = entry
		var definition: Dictionary = library.get_unit(str(unit["def_id"]))
		var source: Dictionary = definition.get("source", {})
		if str(source.get("kind", "")) == "token":
			tokens += 1
			continue
		occupied += 1
		for tribe: Variant in definition.get("tribes", []):
			counts[str(tribe)] = CoreUtil.to_int(counts.get(str(tribe), 0)) + 1
	var leaders: Array[String] = []
	var largest: int = 0
	for tribe: String in counts:
		var count: int = CoreUtil.to_int(counts[tribe])
		if count > largest:
			leaders = [tribe]
			largest = count
		elif count == largest:
			leaders.append(tribe)
	leaders.sort()
	var majority: String = NONE
	if leaders.size() == 1 and largest * 2 > occupied:
		majority = leaders[0]
	var reason: String = ""
	if majority == NONE:
		if occupied == 0:
			reason = "tokens_only" if tokens > 0 else "empty"
		elif largest == 0:
			reason = "neutral_only"
		elif leaders.size() > 1:
			reason = "tied_plurality"
		else:
			reason = "mixed"
	return {
		"final_tribe": majority,
		"plurality_tribe": "+".join(leaders) if not leaders.is_empty() else NONE,
		"plurality_share": float(largest) / occupied if occupied > 0 else 0.0,
		"no_tribe_reason": reason,
	}
