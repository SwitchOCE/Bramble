extends GutTest
@warning_ignore_start("unsafe_call_argument")
## Fixed card definitions exercise every native face and dial without running a lobby.

const BODIES: Dictionary = {
	"little_dollop": [1, 1, 2],
	"mrs_posset": [1, 2, 1],
	"wee_wobbly": [1, 1, 4],
	"stone_soup": [2, 2, 3],
	"dishwater_nell": [2, 2, 3],
	"moss_ooze": [2, 2, 4],
	"aunt_aspic": [3, 2, 4],
	"bubble_and_squeak": [3, 3, 4],
	"sixpenny_pie": [3, 2, 5],
	"frumenty": [4, 2, 3],
	"figgy_duff": [4, 3, 5],
	"mr_syllabub": [4, 3, 6],
	"elder_ooze": [5, 4, 8],
	"hasty_pudding": [5, 3, 9],
	"granny_stir_up": [6, 4, 8],
	"cut_and_come_again": [6, 4, 6],
}
var library: UnitLibrary
var config: GameConfig


func before_each() -> void:
	config = GameConfig.defaults()
	library = UnitLibrary.load_dir()


func _raw(id: String) -> Dictionary:
	var card: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://content/units/" + id + ".json")
	)
	return card


func _params(card: Dictionary, id: String, golden: bool = false) -> Dictionary:
	for entry: Dictionary in card["mechanics"]:
		if str(entry["id"]) == id:
			return MechanicRegistry.params_for(entry, golden)
	return {}


func test_sixteen_native_oozes_have_the_designed_tiers_and_bodies() -> void:
	var counts: Array[int] = [0, 0, 0, 0, 0, 0]
	for id: String in BODIES:
		var card: Dictionary = library.get_unit(id)
		assert_true(Pass3OozeText.is_native(card), id)
		assert_eq([card["tier"], card["attack"], card["health"]], BODIES[id], id)
		counts[CoreUtil.to_int(card["tier"]) - 1] += 1
		for golden: bool in [false, true]:
			var unit: RecruitUnit = RecruitUnit.make(card, 1, golden)
			var factor: int = 2 if golden else 1
			assert_eq(unit.attack, CoreUtil.to_int(card["attack"]) * factor, id)
			assert_eq(unit.health, CoreUtil.to_int(card["health"]) * factor, id)
	assert_eq(counts, [3, 3, 3, 3, 2, 2])
	assert_true(library.unbuilt_units().is_empty())


func test_authored_normal_and_golden_faces_equal_resolved_b_generation() -> void:
	for id: String in BODIES:
		var raw: Dictionary = _raw(id)
		for golden: bool in [false, true]:
			var key: String = "golden_text" if golden else "text"
			var authored: String = str(raw[key])
			raw[key] = "This stale text must not drive generation."
			assert_eq(Pass3Text.face(raw, config, golden), authored, id + " " + key)
			assert_eq(library.get_unit(id)[key], authored, id + " runtime")


func test_all_twenty_three_ooze_dials_match_the_paper_b_and_c_values() -> void:
	var paper: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://docs/ideation/content/pass3/presets.json")
	)
	for preset: String in ["B", "C"]:
		config.set_value("pass3_preset", preset)
		var count: int = 0
		var expected: Dictionary = paper[preset]
		var resolved: Dictionary = Pass3Rates.resolved(config)
		for key: String in expected:
			if key.begins_with("oozes_"):
				assert_eq(resolved[key], expected[key], preset + " " + key)
				count += 1
		assert_eq(count, 23)


func test_soup_and_elder_c_faces_name_the_wider_shares_without_golden_fraction_doubling() -> void:
	config.set_value("pass3_preset", "C")
	var soup: Dictionary = library.get_unit("stone_soup").duplicate(true)
	Pass3OozeText.configure(soup, config)
	assert_eq(soup["text"], "Shop units gain a sixth of your biggest Ooze's stats.")
	assert_eq(soup["golden_text"], "Shop units gain a sixth of your two biggest Oozes' stats.")
	var elder: Dictionary = library.get_unit("elder_ooze").duplicate(true)
	Pass3OozeText.configure(elder, config)
	assert_eq(
		elder["text"],
		"After your biggest Ooze eats a non-Ooze: your other Oozes gain three quarters of its stats."
	)
	assert_eq(
		elder["golden_text"],
		"After your biggest Ooze eats a non-Ooze: your other Oozes gain three halves of its stats."
	)


func test_overrides_drive_belly_discount_split_drips_pie_and_replay_parameters_and_faces() -> void:
	for key: String in [
		"oozes_dollop_belly",
		"oozes_dollop_discount",
		"oozes_bubble_belly",
		"oozes_bubble_splits",
		"oozes_wobbly_drip",
		"oozes_pie_gold",
		"oozes_syllabub_fires"
	]:
		config.set_value(key, 3)
	var dollop: Dictionary = library.get_unit("little_dollop").duplicate(true)
	Pass3OozeText.configure(dollop, config)
	assert_eq(_params(dollop, "belly", true)["size"], 6)
	assert_eq(_params(dollop, "belly_discount", true)["gold"], 6)
	assert_eq(dollop["golden_text"], "Belly 6. Digest. Buying into this costs 6 gold less.")
	var bubble: Dictionary = library.get_unit("bubble_and_squeak").duplicate(true)
	Pass3OozeText.configure(bubble, config)
	assert_eq(_params(bubble, "bubble", true)["splits"], 6)
	assert_true(str(bubble["golden_text"]).contains("Belly 6."))
	assert_true(str(bubble["golden_text"]).contains("six times a fight."))
	var wobbly: Dictionary = library.get_unit("wee_wobbly").duplicate(true)
	Pass3OozeText.configure(wobbly, config)
	assert_eq(_params(wobbly, "wobbly", true)["drip"], 6)
	assert_true(str(wobbly["golden_text"]).contains("6/6 Drip"))
	var pie: Dictionary = library.get_unit("sixpenny_pie").duplicate(true)
	Pass3OozeText.configure(pie, config)
	assert_eq(_params(pie, "pie", true)["per_unit"], 3)
	assert_true(str(pie["golden_text"]).contains("3 gold per unit"))
	var syllabub: Dictionary = library.get_unit("mr_syllabub").duplicate(true)
	Pass3OozeText.configure(syllabub, config)
	assert_eq(_params(syllabub, "syllabub", true)["times"], 6)
	assert_true(str(syllabub["golden_text"]).ends_with("six times."))


func test_native_count_rates_widen_golden_targets_but_keep_compounding_fractions() -> void:
	for pair: Array in [
		["dishwater_nell", "count", "oozes_nell_meals"],
		["frumenty", "meals", "oozes_frumenty_meals"],
		["hasty_pudding", "count", "oozes_hasty_swallows"],
		["cut_and_come_again", "count", "oozes_slice_count"],
	]:
		config.set_value(str(pair[2]), 3)
		var card: Dictionary = library.get_unit(str(pair[0])).duplicate(true)
		Pass3OozeText.configure(card, config)
		assert_eq(_params(card, "pass3_ooze", true)[pair[1]], 6, str(pair[0]))
		if str(pair[0]) == "hasty_pudding":
			assert_eq(_params(card, "belly", true)["size"], 6, "swallow dial also widens capacity")
	var hasty: Dictionary = library.get_unit("hasty_pudding")
	assert_eq(_params(hasty, "pass3_ooze", true)["share"], 0.2)
	assert_eq(_params(hasty, "pass3_ooze", true)["after"], 3)
	assert_eq(_params(library.get_unit("mrs_posset"), "pass3_ooze", true)["loss_share"], 0.5)


func test_slice_is_a_created_tribeless_textless_body_and_prototypes_wait_for_part_four() -> void:
	var slice: Dictionary = library.get_unit("slice")
	assert_false(slice["pool"])
	assert_eq(slice["tribes"], [])
	assert_eq(slice["mechanics"], [])
	assert_eq(slice["text"], "")
	assert_eq(slice["golden_text"], "")
	for id: String in ["dewdrop_ooze", "bramble_ooze", "bog_ooze", "great_ooze"]:
		assert_true(library.get_unit(id)["pool"], id + " retires in the final separate commit")


func test_reviewed_reader_details_match_current_stats_shy_and_elder_spacing() -> void:
	for golden: bool in [false, true]:
		var hasty: String = Pass3OozeText.details(_raw("hasty_pudding"), config, golden)
		assert_string_contains(hasty, "current stats as it is swallowed")
		assert_string_contains(hasty, "including Rings, auras, tribe bonuses and combat buffs")
		assert_string_contains(
			Pass3OozeText.details(_raw("stone_soup"), config, golden), "Shy gets none."
		)
		assert_string_contains(
			Pass3OozeText.details(_raw("elder_ooze"), config, golden),
			"No sale gold. Only other Oozes"
		)
