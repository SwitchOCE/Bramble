extends GutTest
@warning_ignore_start("unsafe_call_argument")
## Native Hunter content has independent authored faces, rate-driven words and frozen legacy data.

const LEGACY := preload("res://tests/core/legacy_hunters.gd")
const IDS: PackedStringArray = [
	"little_nip",
	"wick",
	"young_brock",
	"sable",
	"toll_bard",
	"mistress_russet",
	"brother_wolf",
	"lodger",
	"old_lutra",
	"madame_ermeline",
	"old_brock",
	"grey_agnes",
	"grizel",
	"mountain_glutton",
	"laird_of_sett",
	"old_isegrim",
]
const PROTOTYPES: PackedStringArray = [
	"fox_cub",
	"fox_notary",
	"weasel_second",
	"sett_warden",
	"stoat_captain",
	"ermine_duellist",
	"old_badger",
]
const BODIES: Dictionary = {
	"little_nip": [1, 2, 2],
	"wick": [1, 2, 2],
	"young_brock": [1, 2, 3],
	"sable": [2, 2, 3],
	"toll_bard": [2, 2, 4],
	"mistress_russet": [2, 3, 3],
	"brother_wolf": [3, 3, 5],
	"lodger": [3, 4, 4],
	"old_lutra": [3, 3, 5],
	"madame_ermeline": [4, 3, 7],
	"old_brock": [4, 3, 6],
	"grey_agnes": [4, 4, 6],
	"grizel": [5, 5, 8],
	"mountain_glutton": [5, 5, 7],
	"laird_of_sett": [6, 6, 9],
	"old_isegrim": [6, 7, 10],
}
var library: UnitLibrary
var config: GameConfig


func before_each() -> void:
	library = UnitLibrary.load_dir()
	config = GameConfig.defaults()


func _raw(id: String) -> Dictionary:
	var data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://content/units/" + id + ".json")
	)
	return data


func _card(id: String) -> Dictionary:
	var card: Dictionary = library.get_unit(id).duplicate(true)
	Pass3HunterText.configure(card, config)
	return card


func test_sixteen_native_hunters_keep_the_tier_spread_and_rebuilt_bodies() -> void:
	var counts: Array[int] = [0, 0, 0, 0, 0, 0]
	var native_count: int = 0
	for card: Dictionary in library.pool_units("slice"):
		var tribes: Array = card["tribes"]
		if not tribes.has("Hunters"):
			continue
		native_count += 1
		counts[CoreUtil.to_int(card["tier"]) - 1] += 1
		var id: String = str(card["id"])
		assert_true(IDS.has(id))
		assert_true(Pass3HunterText.is_native(card), id)
		assert_eq(
			[
				CoreUtil.to_int(card["tier"]),
				CoreUtil.to_int(card["attack"]),
				CoreUtil.to_int(card["health"])
			],
			BODIES[id],
			id
		)
		var native_entries: int = 0
		for entry: Dictionary in card["mechanics"]:
			assert_true(str(entry["id"]) in ["quarry", "pack", "pass3_hunter"], id)
			if str(entry["id"]) == "pass3_hunter":
				native_entries += 1
				assert_eq(CoreUtil.to_int(entry["factor"]), 1)
		assert_eq(native_entries, 1, id + " has one native ability")
		var keywords: Array = card["keywords"]
		assert_false(keywords.has("Pounce"))
		assert_false(keywords.has("Cleave"))
	assert_eq(native_count, 16)
	assert_eq(counts, [3, 3, 3, 3, 2, 2])
	assert_eq(library.get_unit("toll_bard")["name"], "The Lane-Bard", "stable id, amended name")


func test_authored_default_faces_match_generation_without_reading_authored_words() -> void:
	for id: String in IDS:
		var raw: Dictionary = _raw(id)
		for golden: bool in [false, true]:
			var field: String = "golden_text" if golden else "text"
			var expected: String = str(raw[field])
			raw[field] = "Stale authored words."
			var generated: String = Pass3Text.face(raw, config, golden)
			assert_eq(generated, expected, id + " " + field)
			assert_eq(library.get_unit(id)[field], generated, id + " runtime")
			assert_lte(generated.split(" ", false).size(), 22, id + " face word budget")


func test_paper_b_and_c_rates_differ_only_in_the_nine_shares_and_a35_pelts() -> void:
	var expected: Dictionary = {
		"hunters_nip_share": 2.0 / 3.0,
		"hunters_sable_share": 2.0 / 3.0,
		"hunters_lutra_share": 2.0 / 3.0,
		"hunters_glutton_share": 2.0 / 3.0,
		"hunters_lodger_share": 2.0 / 3.0,
		"hunters_wick_share": 1.0 / 3.0,
		"hunters_grizel_share": 1.0 / 3.0,
		"hunters_pelt_share": 1.0 / 3.0,
		"hunters_russet_buff_share": 2.0 / 3.0,
		"hunters_golden_russet_buff_share": 1.0,
		"hunters_ermeline_pelts": 1,
		"hunters_golden_ermeline_pelts": 2,
		"hunters_laird_multiplier": 2,
		"hunters_golden_laird_multiplier": 3,
		"hunters_golden_take_multiplier": 2.0,
		"hunters_sable_strike": 1.0,
		"hunters_golden_sable_strike": 2.0,
		"hunters_agnes_hit_back": 0.5,
		"hunters_golden_agnes_hit_back": 0.25,
		"hunters_isegrim_health_cut": 0,
		"hunters_russet_copies": 1,
		"hunters_lane_bard_gold": 1,
		"hunters_golden_lane_bard_gold": 2,
		"hunters_lane_bard_triggers": 2,
		"hunters_take_floor": 1,
		"hunters_young_brock_share": 1.0,
		"hunters_trophies_after_fight": true,
	}
	var c_changes: Dictionary = {
		"hunters_nip_share": 0.75,
		"hunters_sable_share": 0.75,
		"hunters_lutra_share": 0.75,
		"hunters_glutton_share": 1.0,
		"hunters_lodger_share": 1.0,
		"hunters_wick_share": 0.5,
		"hunters_grizel_share": 0.5,
		"hunters_pelt_share": 0.5,
		"hunters_russet_buff_share": 0.75,
		# A3.5 step 0 (DECISIONS 10 Nov): Ermeline's Pelts join the path.
		"hunters_ermeline_pelts": 2,
		"hunters_golden_ermeline_pelts": 4,
	}
	for preset_id: String in ["B", "C"]:
		config.set_value("pass3_preset", preset_id)
		var values: Dictionary = expected.duplicate()
		if preset_id == "C":
			values.merge(c_changes, true)
		for key: String in values:
			assert_true(config._values.has(key), key + " is a registered nullable sweep dial")
			assert_null(config.get_value(key))
			if values[key] is bool:
				assert_eq(Pass3Rates.enabled(config, key), values[key], key)
			else:
				assert_eq(Pass3Rates.number(config, key), CoreUtil.to_float(values[key]), key)
	var c_map: Dictionary = Pass3Rates._presets["C"]
	var hunter_c_count: int = 0
	for key: String in c_map:
		if key.begins_with("hunters_"):
			hunter_c_count += 1
	assert_eq(hunter_c_count, 11)


func test_golden_shares_and_geometry_have_their_distinct_meanings() -> void:
	assert_string_contains(_card("little_nip")["text"], "two thirds")
	assert_string_contains(_card("little_nip")["golden_text"], "four thirds")
	assert_string_contains(_card("wick")["golden_text"], "two thirds")
	assert_string_contains(_card("mistress_russet")["golden_text"], "with its buffs")
	assert_string_contains(_card("young_brock")["text"], "beside this")
	assert_string_contains(_card("young_brock")["golden_text"], "next to this")
	assert_eq(_card("old_brock")["text"], _card("old_brock")["golden_text"])
	assert_eq(_card("brother_wolf")["text"], _card("brother_wolf")["golden_text"])
	assert_string_contains(_card("old_isegrim")["text"], "Hunters beside it")
	assert_string_contains(_card("old_isegrim")["golden_text"], "Hunters next to it")
	assert_string_contains(_card("madame_ermeline")["golden_text"], "two Pelts")
	assert_string_contains(_card("laird_of_sett")["golden_text"], "3 times")
	config.set_value("pass3_preset", "C")
	assert_string_contains(_card("little_nip")["text"], "three quarters")
	assert_string_contains(_card("little_nip")["golden_text"], "three halves")
	assert_string_contains(_card("mountain_glutton")["golden_text"], "twice the quarry's stats")
	assert_string_contains(_card("grizel")["golden_text"], "gain the target's stats")


func test_rate_sweeps_rewrite_faces_and_reader_rulings() -> void:
	for sample: Array in [
		["hunters_nip_share", 0.5, "little_nip", "half the quarry's stats"],
		["hunters_wick_share", 0.5, "wick", "half the target's stats"],
		["hunters_sable_strike", 0.5, "sable", "half its quarry's Attack"],
		["hunters_russet_buff_share", 0.5, "mistress_russet", "half its buffs"],
		["hunters_russet_copies", 2, "mistress_russet", "2 copies"],
		["hunters_lodger_share", 0.5, "lodger", "half the quarry's stats"],
		["hunters_lutra_share", 0.5, "old_lutra", "half the quarry's stats"],
		["hunters_ermeline_pelts", 3, "madame_ermeline", "three Pelts"],
		["hunters_lane_bard_gold", 3, "toll_bard", "get 3 gold"],
		["hunters_lane_bard_triggers", 3, "toll_bard", "3 times a fight"],
		["hunters_agnes_hit_back", 0.25, "grey_agnes", "a quarter of the hit back"],
		["hunters_grizel_share", 0.5, "grizel", "half the target's stats"],
		["hunters_glutton_share", 0.5, "mountain_glutton", "half the quarry's stats"],
		["hunters_laird_multiplier", 3, "laird_of_sett", "3 times"],
		["hunters_young_brock_share", 0.5, "young_brock", "half its stats"],
	]:
		config = GameConfig.defaults()
		config.set_value(str(sample[0]), sample[1])
		assert_string_contains(_card(str(sample[2]))["text"], str(sample[3]))
	config.set_value("hunters_take_floor", 2)
	assert_string_contains(_card("little_nip")["details"], "at least +2/+2")
	config.set_value("hunters_trophies_after_fight", false)
	assert_string_contains(_card("little_nip")["details"], "during the fight")
	config.set_value("hunters_isegrim_health_cut", 0.25)
	assert_string_contains(_card("old_isegrim")["details"], "a quarter of its Health")


func test_borrowed_fragments_and_default_readers_keep_the_resolved_numbers() -> void:
	var card: Dictionary = _card("little_nip")
	var fragments: Dictionary = card["mechanic_text"]
	var fragment: Dictionary = fragments["1"]
	assert_eq(fragment["id"], "pass3_hunter")
	assert_true(str(fragment["text"]).begins_with("Take: gain two thirds"))
	assert_string_contains(fragment["golden_text"], "four thirds")
	var normal: Dictionary = {}
	var golden: Dictionary = {}
	UnitLibrary.add_configured_rulings(normal, card)
	UnitLibrary.add_configured_rulings(golden, card, true)
	assert_string_contains(normal["configured_details"], "next Start of Turn")
	assert_string_contains(golden["configured_details"], "next Start of Turn")
	assert_string_contains(_card("madame_ermeline")["keyword_text_overrides"]["Pelt"], "a third")
	config.set_value("pass3_preset", "C")
	assert_string_contains(_card("madame_ermeline")["keyword_text_overrides"]["Pelt"], "half")
	config.set_value("hunters_golden_take_multiplier", 1.5)
	assert_string_contains(_card("little_nip")["golden_text"], "nine eighths")


func test_edited_json_default_rates_generate_words_without_per_game_overrides() -> void:
	var original: Dictionary = Pass3Rates.defaults()
	Pass3Rates._defaults["hunters_nip_share"] = 0.5
	Pass3Rates._defaults["hunters_pelt_share"] = 0.5
	var changed := UnitLibrary.load_dir()
	Pass3Rates._defaults = original
	assert_string_contains(changed.get_unit("little_nip")["text"], "half the quarry's stats")
	assert_string_contains(changed.get_unit("little_nip")["golden_text"], "gain the quarry's stats")
	var card: Dictionary = changed.get_unit("madame_ermeline")
	var overrides: Dictionary = card["keyword_text_overrides"]
	assert_string_contains(overrides["Pelt"], "half")


func test_archive_restores_all_twenty_three_old_hunters_and_prototype_pool_flags() -> void:
	var frozen: UnitLibrary = LEGACY.library()
	for id: String in PROTOTYPES:
		assert_false(library.get_unit(id)["pool"], id + " is retired from the current pool")
		assert_true(
			frozen.get_unit(id)["pool"], id + " remains available in the frozen regression pool"
		)
	assert_eq(CoreUtil.to_int(frozen.get_unit("little_nip")["health"]), 3)
	assert_eq(CoreUtil.to_int(frozen.get_unit("laird_of_sett")["health"]), 5)
	assert_eq(frozen.get_unit("lodger")["mechanics"][0]["id"], "pounce")
	assert_eq(frozen.get_unit("toll_bard")["name"], "The Toll-Bard")
	assert_false(Pass3HunterText.is_native(frozen.get_unit("little_nip")))
	var data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass2_hunters_units.json")
	)
	var archived: Array = data["units"]
	assert_eq(archived.size(), 23)
