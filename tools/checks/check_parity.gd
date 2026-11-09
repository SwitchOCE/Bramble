extends SceneTree
## Shop-pool parity for triage step 2b. Use the game's loader and set filtering, before lobby
## rotation. Warn during measurement; PARITY_STRICT=1 makes mismatches fail after pass 2.

const TRIBES: PackedStringArray = [
	"Birds", "Bog folk", "Fairies", "Hedgerow folk", "Hunters", "Oozes"
]
const TARGET: Array[int] = [3, 3, 3, 3, 2, 2]
const NEUTRALS: String = "Neutrals"


func _initialize() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	if not library.load_errors().is_empty():
		for problem: String in library.load_errors():
			printerr("parity: load error: %s" % problem)
		quit(1)
		return
	var card_set: String = GameConfig.full_game().card_set()
	var units: Array[Dictionary] = library.pool_units(card_set)
	var counts: Dictionary = count_pool(units)
	print(
		"parity: full_game set=%s, %d shop units (before lobby rotation)" % [card_set, units.size()]
	)
	print("parity: tribe | total | T1 T2 T3 T4 T5 T6; target 16 at 3/3/3/3/2/2")
	var names: Array = counts.keys()
	names.sort()
	for tribe: String in names:
		var tiers: Array = counts[tribe]
		var total: int = 0
		for count: int in tiers:
			total += count
		print("parity: %s | %d | %s" % [tribe, total, tiers])
	var gaps: PackedStringArray = mismatches(counts)
	if gaps.is_empty():
		print("parity: all tribes meet the target; neutrals are reported without a target")
	else:
		var mode: String = "FAIL" if OS.get_environment("PARITY_STRICT") == "1" else "WARN"
		print("parity: %s: off target: %s" % [mode, ", ".join(gaps)])
	quit(exit_status(counts, OS.get_environment("PARITY_STRICT")))


## Input is UnitLibrary.pool_units(), so tokens and other sets never enter these counts.
## A dual-tribe unit counts once for each tribe, matching UnitLibrary.tribes_in_rotation().
static func count_pool(units: Array[Dictionary]) -> Dictionary:
	var counts: Dictionary = {NEUTRALS: [0, 0, 0, 0, 0, 0]}
	for tribe: String in TRIBES:
		counts[tribe] = [0, 0, 0, 0, 0, 0]
	for unit: Dictionary in units:
		var tribes: Array = unit["tribes"]
		if tribes.is_empty():
			counts[NEUTRALS][CoreUtil.to_int(unit["tier"]) - 1] += 1
		for tribe: String in tribes:
			if not counts.has(tribe):
				counts[tribe] = [0, 0, 0, 0, 0, 0]
			counts[tribe][CoreUtil.to_int(unit["tier"]) - 1] += 1
	return counts


static func mismatches(counts: Dictionary) -> PackedStringArray:
	var gaps: PackedStringArray = []
	for tribe: String in counts:
		if tribe != NEUTRALS and counts[tribe] != TARGET:
			gaps.append(tribe)
	gaps.sort()
	return gaps


static func exit_status(counts: Dictionary, strict: String) -> int:
	return 1 if strict == "1" and not mismatches(counts).is_empty() else 0
