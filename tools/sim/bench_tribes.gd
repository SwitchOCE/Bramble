class_name BenchTribes
extends RefCounted
## Classify the last fight's starting board, independently of a bot's declared build. A tribe must
## occupy strictly more than half the occupied slots. Mixed/tied/empty boards are no_tribe.
## Eggs occupy slots but have no tribe in the library; away Birds and Belly contents are
## not extra board slots. Use PlayerState.fought_specs, because GameLog omits Eggs.

const NONE: String = "no_tribe"


static func final_tribe(board: Array, library: UnitLibrary) -> String:
	var counts: Dictionary = {}
	var occupied: int = 0
	for entry: Variant in board:
		if entry == null:
			continue
		var unit: Dictionary = entry
		occupied += 1
		var definition: Dictionary = library.get_unit(str(unit["def_id"]))
		for tribe: Variant in definition.get("tribes", []):
			counts[str(tribe)] = CoreUtil.to_int(counts.get(str(tribe), 0)) + 1
	var majority: String = NONE
	for tribe: String in counts:
		if CoreUtil.to_int(counts[tribe]) * 2 > occupied:
			if majority != NONE:
				return NONE
			majority = tribe
	return majority
