class_name SoakCopyCheck
extends RefCounted
## Directed text-transfer cases that random games can miss. Every soak runs these first.


static func problems(library: UnitLibrary) -> PackedStringArray:
	var out: PackedStringArray = []
	for golden: bool in [false, true]:
		var ours: Array = []
		var theirs: Array = []
		ours.resize(BoardGeometry.SLOTS)
		theirs.resize(BoardGeometry.SLOTS)
		ours[0] = {"def_id": "cradle_fetch", "golden": golden}
		ours[4] = {"def_id": "cradle_fetch", "golden": golden}
		theirs[4] = {"def_id": "mag_pye", "golden": golden}
		var rng := RandomNumberGenerator.new()
		rng.seed = 1
		var combat := Combat.create(library, GameConfig.defaults(), rng)
		var result: Dictionary = combat.run([ours, theirs], [1, 1], [0, 1], 0)
		var copies: int = 0
		var stolen: int = 0
		var ended: int = 0
		var events: Array = result["events"]
		for event: Dictionary in events:
			match str(event["type"]):
				"summon":
					copies += 1
				"text_taken":
					stolen += 1
				"combat_end":
					ended += 1
		if (
			copies != 0
			or stolen != 1
			or ended != 1
			or result["reason"] == Combat.REASON_TRIGGER_LIMIT
		):
			out.append(
				(
					"copy/text-transfer regression (golden=%s): %d copies, %d steals, %d ends, %s"
					% [golden, copies, stolen, ended, result["reason"]]
				)
			)
	return out
