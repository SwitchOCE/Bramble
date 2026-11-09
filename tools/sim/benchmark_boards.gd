extends RefCounted
## Translate the hand-written step 2c snapshots without running a recruit phase. Supplied stats
## already include standing auras: remove the reconstructed aura before Combat rebuilds it.
## Missing prose-only state is reported, never filled with a guessed stronger board.

const INPUT: String = "res://docs/ideation/evidence/benchmark-boards.json"
const ROUNDS: Array[int] = [3, 6, 9, 12]
const ROLLS: Array[String] = ["average", "high", "low"]
const TRIBES: Array[String] = ["Hedgerow folk", "Fairies", "Birds", "Hunters", "Oozes", "Bog folk"]
const NEST_NAMES: Dictionary = {
	"Chiffchaff": "chiffchaff",
	"Tom Tit": "tom_tit",
	"Old Tern": "old_tern",
	"Mother Goose": "mother_goose",
	"Goose": "mother_goose",
	"Jay": "mrs_jay",
	"Barn Owl": "barn_owl"
}


static func board_id(source: Dictionary) -> String:
	return (
		"%s-r%d-%s"
		% [str(source["tribe"]).to_lower().replace(" ", "_"), source["round"], source["roll"]]
	)


static func load_all(library: UnitLibrary, path: String = INPUT) -> Dictionary:
	var result: Dictionary = {"boards": [], "errors": [], "path": path}
	var errors: Array = result["errors"]
	var boards: Array = result["boards"]
	if not FileAccess.file_exists(path):
		errors.append("Missing input: " + path)
		return result
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		errors.append("Invalid JSON: " + parser.get_error_message())
		return result
	if not parser.data is Dictionary:
		errors.append("Input must contain a boards array")
		return result
	var data: Dictionary = parser.data
	if not data.get("boards") is Array:
		errors.append("Input must contain a boards array")
		return result
	var source_boards: Array = data["boards"]
	result["base_commit"] = data.get("base_commit", "")
	result["sha256"] = FileAccess.get_sha256(path)
	var seen: Dictionary = {}
	for value: Variant in source_boards:
		if not value is Dictionary:
			errors.append("Each board must be an object")
			continue
		var source: Dictionary = value
		var translated: Dictionary = translate(source, library)
		var problems: Array = translated["errors"]
		errors.append_array(problems)
		if not problems.is_empty():
			continue
		var id: String = translated["id"]
		if seen.has(id):
			errors.append("Duplicate board: " + id)
		seen[id] = true
		boards.append(translated)
	for tribe: String in TRIBES:
		for round_number: int in ROUNDS:
			for roll: String in ROLLS:
				var id: String = board_id({"tribe": tribe, "round": round_number, "roll": roll})
				if not seen.has(id):
					errors.append("Missing board: " + id)
	if source_boards.size() != 72:
		errors.append("Expected 72 boards, got %d" % source_boards.size())
	return result


static func translate(source: Dictionary, library: UnitLibrary) -> Dictionary:
	var out: Dictionary = {"errors": [], "unrepresentable": [], "assumptions": []}
	var errors: Array = out["errors"]
	for key: String in ["tribe", "round", "roll", "tier", "rank", "stat_total", "slots"]:
		if not source.has(key):
			errors.append("Board missing field: " + key)
	if not errors.is_empty():
		return out
	if not source["slots"] is Dictionary:
		errors.append("slots must be an object")
		return out
	var source_slots: Dictionary = source["slots"]
	out["id"] = board_id(source)
	out["source"] = source.duplicate(true)
	var board: Array = []
	var slots: Array = []
	board.resize(BoardGeometry.SLOTS)
	for slot: int in BoardGeometry.SLOTS:
		slots.append([])
		var label: String = BoardGeometry.LABELS[slot]
		if not source_slots.has(label):
			errors.append("%s: missing slot %s" % [out["id"], label])
			continue
		var entry: Variant = source_slots[label]
		if entry == null:
			continue
		if not entry is Dictionary:
			errors.append("%s: %s must be null or a unit" % [out["id"], label])
			continue
		var unit_entry: Dictionary = entry
		board[slot] = _spec(unit_entry, library, errors, label)
	for label: String in source_slots:
		if not BoardGeometry.LABELS.has(label):
			errors.append("%s: unknown slot %s" % [out["id"], label])
	if not errors.is_empty():
		return out
	out["specs"] = board
	out["slot_effects"] = slots
	out["rules"] = {"bands": [], "nests": [], "ammo": [], "larder": 0, "goose": 0}
	out["stat_total"] = stat_total(board)
	if out["stat_total"] != CoreUtil.to_int(source["stat_total"]):
		errors.append("%s: supplied stat_total does not match bodies/Bellies" % out["id"])
	_auxiliary_state(out, library)
	_normalize_auras(out, library)
	return out


static func stat_total(board: Array) -> int:
	var total: int = 0
	for value: Variant in board:
		if value == null:
			continue
		var spec: Dictionary = value
		total += CoreUtil.to_int(spec["attack"]) + CoreUtil.to_int(spec["health"])
		var held: Array = spec.get("held", [])
		total += stat_total(held)
	return total


static func _spec(
	entry: Dictionary, library: UnitLibrary, errors: Array, location: String
) -> Dictionary:
	var def_id: String = str(entry.get("unit", ""))
	var unit_def: Dictionary = library.get_unit(def_id)
	if unit_def.is_empty():
		errors.append("%s: unknown unit %s" % [location, def_id])
		return {}
	for key: String in ["attack", "health"]:
		var value: Variant = entry.get(key)
		if not (value is int or value is float):
			errors.append("%s: %s must be an integer" % [location, key])
			return {}
		var number: float = value
		if number != floorf(number):
			errors.append("%s: %s must be an integer" % [location, key])
			return {}
	if CoreUtil.to_int(entry["attack"]) < 0 or CoreUtil.to_int(entry["health"]) < 1:
		errors.append("%s: Attack must be nonnegative and Health positive" % location)
	var unit := RecruitUnit.make(unit_def, 0)
	unit.golden = CoreUtil.to_bool(entry.get("golden", false))
	for value: Variant in entry.get("belly", []):
		var inner: Dictionary = value
		var inner_spec: Dictionary = _spec(inner, library, errors, location + "/belly")
		if inner_spec.is_empty():
			continue
		var held := RecruitUnit.make(library.get_unit(str(inner_spec["def_id"])), 0)
		held.golden = CoreUtil.to_bool(inner_spec["golden"])
		# borrowed_text() only needs the definition and golden flag.
		unit.held.append(held)
	var spec: Dictionary = unit.combat_spec()
	spec["attack"] = CoreUtil.to_int(entry["attack"])
	spec["health"] = CoreUtil.to_int(entry["health"])
	if entry.has("belly"):
		var inside: Array = []
		for inner: Dictionary in entry["belly"]:
			inside.append(_spec(inner, library, errors, location + "/belly"))
		spec["held"] = inside
	# Only these persistent counters are accepted by CombatUnit.make.
	for key: String in ["hex", "kisses", "paid_pie", "egg_full_attack", "egg_full_health"]:
		if entry.has(key):
			spec[key] = CoreUtil.to_int(entry[key])
	for value: Variant in entry.get("keywords", []):
		var keyword: String = str(value)
		if keyword.begins_with("Hex "):
			var total: int = keyword.trim_prefix("Hex ").to_int()
			spec["hex"] = maxi(0, total - unit.mechanic_number("hex", "n"))
	return spec


static func _auxiliary_state(out: Dictionary, library: UnitLibrary) -> void:
	var source: Dictionary = out["source"]
	var source_slots: Dictionary = source["slots"]
	var rules: Dictionary = out["rules"]
	var buffs: String = str(source.get("buffs", ""))
	var missing: Array = out["unrepresentable"]
	var bands: Array = []
	bands.resize(BoardGeometry.SLOTS)
	bands.fill(0)
	var has_full_bands: bool = false
	for slot: int in BoardGeometry.SLOTS:
		var value: Variant = source_slots[BoardGeometry.LABELS[slot]]
		if value == null:
			continue
		var entry: Dictionary = value
		var keywords: String = _keywords(entry)
		if keywords.contains("7 painted"):
			has_full_bands = true
		elif keywords.contains("painted") and str(entry["unit"]) == "rainbow_chaser":
			missing.append(
				"Painted count is given without slot identities; bonus stays in snapshot."
			)
		_ring(out, slot, keywords)
		_nest(out, slot, keywords, library)
		if str(entry["unit"]) == "his_highness" and not entry.has("kisses"):
			missing.append(
				"%s: prior kisses unspecified; starts at 0." % BoardGeometry.LABELS[slot]
			)
	if not has_full_bands and buffs.to_lower().contains("chaser (+14/+14)"):
		has_full_bands = true
		var assumptions: Array = out["assumptions"]
		assumptions.append("Golden Chaser +14/+14 implies all seven painted slots.")
	if has_full_bands:
		bands.fill(1)
		rules["bands"] = bands
	if source["tribe"] == "Fairies":
		missing.append(
			"Complete Ring layout/amounts unspecified; only numeric slot annotations load."
		)
		if CoreUtil.to_int(source["round"]) == 3 and source["roll"] == "average":
			out["slot_effects"][2] = [_ring_effect(1, 1)]
			var assumptions: Array = out["assumptions"]
			assumptions.append("F3 Ring +1/+1 is explicit in the board's buffs prose.")
	if buffs.contains("away") and (buffs.contains("Goose") or buffs.contains("goose")):
		rules["goose"] = 1
	if source["tribe"] == "Birds":
		var count: int = _nest_count(source)
		var nests: Array = rules["nests"]
		if count > nests.size():
			missing.append(
				(
					"%d of %d Nests lack slot/bird data; their triggers cannot load."
					% [count - nests.size(), count]
				)
			)
		if buffs.contains("Redwing"):
			(
				missing
				. append(
					"Egg full-stat prose may conflict with same-row Redwing adjacency; exact bodies kept."
				)
			)
	_larder(out)


static func _ring(out: Dictionary, slot: int, keywords: String) -> void:
	var pattern := RegEx.new()
	pattern.compile("Rings? \\+(\\d+)/\\+(\\d+)")
	var found: RegExMatch = pattern.search(keywords)
	if found == null:
		var terms: PackedStringArray = keywords.split("; ")
		if terms.has("Ring") or terms.has("Rings"):
			out["slot_effects"][slot] = [_ring_effect(0, 0)]
			var missing: Array = out["unrepresentable"]
			(
				missing
				. append(
					(
						"%s: Ring amount unspecified; zero-stat presence marker, bonus stays in snapshot."
						% BoardGeometry.LABELS[slot]
					)
				)
			)
		return
	var attack: int = found.get_string(1).to_int()
	var health: int = found.get_string(2).to_int()
	if keywords.contains("incl. Monarch"):
		attack -= 1
		health -= 1
	out["slot_effects"][slot] = [_ring_effect(attack, health)]


static func _keywords(entry: Dictionary) -> String:
	var words: Array = entry.get("keywords", [])
	return "; ".join(PackedStringArray(words))


static func _ring_effect(attack: int, health: int) -> Dictionary:
	return {"name": "Ring", "attack": attack, "health": health, "golden": false}


static func _nest(out: Dictionary, slot: int, keywords: String, library: UnitLibrary) -> void:
	var id: String = ""
	for name: String in NEST_NAMES:
		if keywords.contains("Egg of " + name) or keywords.contains(name + "'s Nest"):
			id = NEST_NAMES[name]
	if keywords.contains("Goose's Egg"):
		id = "mother_goose"
	if id == "":
		return
	var unit_def: Dictionary = library.get_unit(id)
	var bird: Dictionary = {
		"def_id": id, "golden": false, "attack": unit_def["attack"], "health": unit_def["health"]
	}
	var rules: Dictionary = out["rules"]
	var nests: Array = rules["nests"]
	nests.append(
		{
			"slot": slot,
			"def_id": id,
			"attack": unit_def["attack"],
			"health": unit_def["health"],
			"spec": bird
		}
	)
	var missing: Array = out["unrepresentable"]
	missing.append(
		(
			"%s: away %s's buffs/golden flag unspecified; printed normal body used."
			% [BoardGeometry.LABELS[slot], id]
		)
	)
	if id == "mother_goose":
		out["rules"]["goose"] = 1


static func _nest_count(source: Dictionary) -> int:
	var count: int = 0
	var slots: Dictionary = source["slots"]
	for value: Variant in slots.values():
		if value == null:
			continue
		var entry: Dictionary = value
		var words: String = _keywords(entry)
		for number: int in range(1, 5):
			if words.contains("%d Nests" % number) or words.contains("Nest (%d)" % number):
				count = maxi(count, number)
	var buffs: String = str(source.get("buffs", ""))
	for text: String in ["Two Nests", "Three Nests", "Four Nests"]:
		if buffs.contains(text):
			var number: int = {"Two Nests": 2, "Three Nests": 3, "Four Nests": 4}[text]
			count = maxi(count, number)
	return count


static func _larder(out: Dictionary) -> void:
	var source: Dictionary = out["source"]
	var slots: Dictionary = source["slots"]
	var missing: Array = out["unrepresentable"]
	var buffs: String = str(source.get("buffs", ""))
	var pattern := RegEx.new()
	pattern.compile("(\\d+) gold.*Acorns held")
	var prose_value: RegExMatch = pattern.search(buffs)
	if prose_value != null:
		out["rules"]["larder"] = prose_value.get_string(1).to_int()
	for slot: int in BoardGeometry.SLOTS:
		var value: Variant = slots[BoardGeometry.LABELS[slot]]
		if value == null:
			continue
		var entry: Dictionary = value
		var words: String = _keywords(entry)
		if str(entry["unit"]) == "honorary_treasurer":
			var found: RegExMatch = pattern.search(words)
			if found != null:
				out["rules"]["larder"] = found.get_string(1).to_int()
			elif prose_value == null:
				missing.append("Held Acorn value unspecified; Treasurer bonus stays in snapshot.")
		if str(entry["unit"]) == "sergeant_at_conkers":
			if buffs.contains("1-gold Acorn") or words.contains("3 damage across"):
				out["rules"]["ammo"] = [1]
			elif not words.contains("no Acorn"):
				missing.append("Conkers' smallest held Acorn unspecified; no ammo loaded.")


static func _normalize_auras(out: Dictionary, library: UnitLibrary) -> void:
	var empty: Array = []
	empty.resize(BoardGeometry.SLOTS)
	var rng := RandomNumberGenerator.new()
	var combat := Combat.create(library, GameConfig.full_game(), rng)
	combat.log_events = false
	combat.side_rules = [out["rules"], {}]
	combat.slot_effects = [out["slot_effects"], []]
	combat._slots_active = BoardUpkeep.any_slot_effects(combat.slot_effects)
	CombatSetup.apply(combat, [out["specs"], empty])
	CombatAuras.recalc(combat, false)
	for unit: CombatUnit in combat.units_of(0):
		var spec: Dictionary = out["specs"][unit.slot]
		spec["attack"] = CoreUtil.to_int(spec["attack"]) - unit.aura_attack
		spec["health"] = CoreUtil.to_int(spec["health"]) - unit.aura_health
