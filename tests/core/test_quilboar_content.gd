extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")
## Independent checks of the reference's authored contract, without loading its pool.

const ROOT: String = "res://content/reference/quilboar"
const CHOOSE_UNITS: Array[String] = [
	"qb_crater_miner",
	"qb_fearless_foodie",
	"qb_sly_infiltrator",
	"qb_snare_trapper",
	"qb_veteran_brigand",
]


func _read(relative: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOT.path_join(relative)))
	assert_true(value is Dictionary, relative)
	return value if value is Dictionary else {}


func test_tunneler_choose_one_inventory_and_phase_boundary() -> void:
	var actual: Array[String] = []
	for filename: String in DirAccess.get_files_at(ROOT.path_join("units")):
		if filename.get_extension() != "json":
			continue
		var card: Dictionary = _read("units/" + filename)
		assert_true(str(card["id"]).begins_with("qb_"))
		assert_eq(card["tribes"], ["quilboar"])
		if card.get("tags", []).has("choose_one"):
			actual.append(str(card["id"]))
		assert_false(str(card["id"]) in ["qb_bonker", "qb_geomagus_roogug", "qb_felboar"])
	actual.sort()
	var expected: Array[String] = CHOOSE_UNITS.duplicate()
	expected.sort()
	assert_eq(actual, expected, "Tunneler's specified five-card unit pool")
	var brigand: Dictionary = _read("units/qb_veteran_brigand.json")
	assert_false(brigand["modes"][0].get("unavailable", false))
	assert_true(brigand["modes"][1]["unavailable"], "Barrage is not silently simulated")


func test_all_reference_spells_are_exempt_and_confiscation_orders_the_steal() -> void:
	for filename: String in DirAccess.get_files_at(ROOT.path_join("spells")):
		if filename.get_extension() != "json":
			continue
		var card: Dictionary = _read("spells/" + filename)
		assert_true(card["scaling_exempt"], filename)
	var gem: Dictionary = _read("spells/qb_blood_gem.json")
	assert_false(gem["pool"])
	assert_eq(gem["cost"], 0.0)
	var day: Dictionary = _read("spells/qb_gem_day.json")
	assert_false(day["pool"])
	assert_eq(day["cost"], 0.0)
	assert_true(day["tags"].has("choose_one"))
	var confiscation: Dictionary = _read("spells/qb_gem_confiscation.json")
	assert_true(confiscation["pool"])
	assert_eq(confiscation["tier"], 4.0)
	assert_eq(confiscation["cost"], 1.0)
	assert_eq(confiscation["do"][0]["effect"], "gem")
	assert_eq(confiscation["do"][0]["count"], 3.0)
	assert_eq(confiscation["do"][1]["effect"], "steal_gems")
	assert_eq(confiscation["do"][1]["from"], "adjacent")


func test_budget_and_uncut_are_the_specified_distinct_arms() -> void:
	var raw: Dictionary = _read("rates.json")
	var rates: Dictionary = raw["quilboar_ref"]
	assert_eq(rates["B"]["gem_size_step"], 0.5)
	assert_eq(rates["C"]["gem_size_step"], 1.0)
	for preset: String in ["B", "C"]:
		assert_eq(rates[preset]["hogrider_every"], 1.0)
		assert_eq(rates[preset]["hogrider_gems"], 1.0)
		assert_eq(rates[preset]["hogrider_targets"], "other_quilboar")
		assert_eq(rates[preset]["tunneler_per_fight"], 1.0)
	assert_eq(rates["uncut"]["hogrider_gems"], 2.0)
	assert_eq(rates["uncut"]["hogrider_targets"], "all_quilboar")
	assert_null(rates["uncut"]["tunneler_per_fight"])
	assert_eq(rates["uncut"]["brigand_gems"], 3.0)
	for preset: String in ["A", "B", "C", "uncut"]:
		for stripped_key: String in ["most", "once", "limit", "uses_per_turn"]:
			assert_false(rates[preset].has(stripped_key), preset + " " + stripped_key)
	var guards: Dictionary = raw["quilboar_ref_loop_guards"]
	assert_true(guards["busker_created_spell_refund_once_per_turn"])
