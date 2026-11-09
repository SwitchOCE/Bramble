extends GutTest
@warning_ignore_start("unsafe_call_argument")
## Authored Bog faces are independent checked copies of the resolved-rate generator.

const LEGACY := preload("res://tests/core/legacy_bog.gd")
const IDS: PackedStringArray = [
	"bridge_toad",
	"warty_nan",
	"young_pretender",
	"madame_bufo",
	"vaulting_hopkin",
	"peat_cutter",
	"gideon",
	"natterjack_chorus",
	"spitfire_sal",
	"tiddy_mun",
	"his_highness",
	"signor_ranocchio",
	"prima_donna",
	"jenny_greenteeth",
	"peat_king",
	"lantern_man",
	"prince_restored",
	"peatling",
]
const PROTOTYPES: PackedStringArray = [
	"marsh_frog",
	"mudwallow_toad",
	"common_toad",
	"crested_newt",
	"bitter_toad",
]
var library: UnitLibrary
var config: GameConfig


func before_each() -> void:
	library = UnitLibrary.load_dir()
	config = GameConfig.defaults()


func _raw(id: String) -> Dictionary:
	var parsed: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://content/units/" + id + ".json")
	)
	return parsed


func _card(id: String) -> Dictionary:
	var card: Dictionary = library.get_unit(id).duplicate(true)
	Pass3BogText.configure(card, config)
	return card


func test_sixteen_bog_units_and_two_tokens_use_the_native_contract() -> void:
	var pool_count: int = 0
	var tiers: Array[int] = [0, 0, 0, 0, 0, 0]
	for id: String in IDS:
		var card: Dictionary = library.get_unit(id)
		assert_true(Pass3BogText.is_native(card), id)
		if card["pool"]:
			pool_count += 1
			tiers[CoreUtil.to_int(card["tier"]) - 1] += 1
		else:
			assert_true(id in ["prince_restored", "peatling"])
		for entry: Dictionary in card["mechanics"]:
			assert_true(str(entry["id"]) in ["mire", "bitter", "snap", "vault", "pass3_bog"], id)
			if str(entry["id"]) == "pass3_bog":
				assert_eq(CoreUtil.to_int(entry["factor"]), 1)
			if str(entry["id"]) == "bitter":
				assert_true(entry.get("pass3", false), "explicit Bitter uses the proportional mode")
	assert_eq(pool_count, 16)
	assert_eq(tiers, [3, 3, 3, 3, 2, 2])


func test_authored_default_faces_match_generation_without_using_authored_words() -> void:
	for id: String in IDS:
		var raw: Dictionary = _raw(id)
		for golden: bool in [false, true]:
			var field: String = "golden_text" if golden else "text"
			var expected: String = str(raw[field])
			raw[field] = "Stale authored words."
			var generated: String = Pass3Text.face(raw, config, golden)
			assert_eq(generated, expected, id + " " + field)
			assert_eq(library.get_unit(id)[field], generated, id + " runtime face")
			assert_lte(generated.split(" ", false).size(), 22, id + " wording-guide maximum")


func test_tier_swap_and_removed_prototype_abilities_and_caps() -> void:
	var tiddy: Dictionary = library.get_unit("tiddy_mun")
	var jenny: Dictionary = library.get_unit("jenny_greenteeth")
	assert_eq([tiddy["tier"], tiddy["attack"], tiddy["health"]], [4, 3, 5])
	assert_eq([jenny["tier"], jenny["attack"], jenny["health"]], [5, 4, 7])
	for id: String in IDS:
		var card: Dictionary = _raw(id)
		assert_false(card.has("permanent_buff_cap"), id)
		for entry: Dictionary in card["mechanics"]:
			for key: String in ["limit", "lifetime", "once_per_enemy"]:
				assert_false(entry.has(key), id + " " + key)
			assert_ne(
				str(entry["id"]),
				"spell_discount",
				"the restored Prince keeps no prototype discount"
			)
	for id: String in PROTOTYPES:
		assert_false(library.get_unit(id)["pool"], id + " is retired")
	var hopkin: Dictionary = library.get_unit("vaulting_hopkin")
	assert_eq(
		CoreUtil.to_int(hopkin["mechanics"][1]["attack"]),
		0,
		"Vault supplies priority, not a flat bonus"
	)


func test_presets_keep_b_generous_and_only_raise_soak_in_c() -> void:
	var expected: Dictionary = {
		"bog_soak_keep": 2,
		"bog_golden_soak_keep": 4,
		"bog_nan_share": 0.5,
		"bog_golden_nan_share": 1.0,
		"bog_ranocchio_share": 0.5,
		"bog_golden_ranocchio_share": 1.0,
		"bog_tiddy_share": 0.5,
		"bog_golden_tiddy_share": 1.0,
		"bog_bitter_share": 0.25,
	}
	for preset: String in ["A", "B"]:
		config.set_value("pass3_preset", preset)
		for key: String in expected:
			assert_eq(Pass3Rates.number(config, key), float(expected[key]), preset + " " + key)
	config.set_value("pass3_preset", "C")
	assert_eq(Pass3Rates.integer(config, "bog_soak_keep"), 3)
	assert_eq(Pass3Rates.integer(config, "bog_golden_soak_keep"), 6)
	assert_eq(Pass3Rates.number(config, "bog_tiddy_share"), 0.5)
	assert_eq(Pass3Rates.number(config, "bog_nan_share"), 0.5)
	assert_string_contains(_card("bridge_toad")["details"], "+3/+3")
	assert_string_contains(_card("bridge_toad")["golden_details"], "+6/+6")


func test_changed_rates_rewrite_faces_details_and_keyword_reminders() -> void:
	for sample: Array in [
		["bog_nan_share", 0.25, "warty_nan", "a quarter of the Toll"],
		["bog_ranocchio_share", 0.25, "signor_ranocchio", "a quarter of its Attack"],
		["bog_tiddy_share", 0.25, "tiddy_mun", "a quarter of the Toll"],
		["bog_hopkin_share", 0.5, "vaulting_hopkin", "half the highest Attack"],
		["bog_frog_multiplier", 4.0, "his_highness", "multiply by 4"],
		["bog_kiss_period", 4, "prince_restored", "Every fourth kiss"],
		["bog_sal_toll_multiplier", 0.5, "spitfire_sal", "half the Toll"],
		["bog_cutter_gold", 2, "peat_cutter", "get 2 gold"],
		["bog_pretender_gold", 2, "young_pretender", "get 2 gold"],
		["bog_lantern_lures", 2, "lantern_man", "2 biggest enemies"],
		["bog_king_peatlings", 3, "peat_king", "3 times a fight"],
	]:
		config = GameConfig.defaults()
		config.set_value(str(sample[0]), sample[1])
		assert_string_contains(_card(str(sample[2]))["text"], str(sample[3]))
	config.set_value("bog_bitter_share", 0.5)
	config.set_value("bog_bitter_round_up", false)
	assert_string_contains(_card("peatling")["keyword_text_overrides"]["Bitter"], "half its Attack")
	assert_string_contains(_card("peatling")["details"], "round down")
	config.set_value("bog_soak_keep", 5)
	config.set_value("bog_golden_soak_keep", 10)
	assert_string_contains(_card("bridge_toad")["details"], "+5/+5")
	assert_string_contains(_card("bridge_toad")["golden_details"], "+10/+10")
	assert_string_contains(_card("bridge_toad")["keyword_text_overrides"]["Soak"], "+5/+5")
	assert_string_contains(_card("bridge_toad")["keyword_text_overrides"]["Soak"], "golden +10/+10")
	assert_lte(Pass3BogText.soak_reminder(config).split(" ", false).size(), 16)


func test_changed_json_defaults_are_visible_without_per_game_overrides() -> void:
	var original: Dictionary = Pass3Rates.defaults()
	Pass3Rates._defaults["bog_nan_share"] = 0.25
	Pass3Rates._defaults["bog_soak_keep"] = 5
	Pass3Rates._defaults["bog_golden_soak_keep"] = 10
	var changed := UnitLibrary.load_dir()
	Pass3Rates._defaults = original
	assert_string_contains(changed.get_unit("warty_nan")["text"], "a quarter of the Toll")
	assert_string_contains(changed.get_unit("bridge_toad")["details"], "+5/+5")
	assert_string_contains(changed.get_unit("bridge_toad")["golden_details"], "+10/+10")


func test_legacy_archive_restores_all_original_bog_and_old_wave1_definitions() -> void:
	var frozen: UnitLibrary = LEGACY.library()
	assert_eq(CoreUtil.to_int(frozen.get_unit("bridge_toad")["permanent_buff_cap"]), 3)
	assert_eq(CoreUtil.to_int(frozen.get_unit("tiddy_mun")["tier"]), 5)
	assert_eq(CoreUtil.to_int(frozen.get_unit("jenny_greenteeth")["tier"]), 4)
	assert_eq(str(frozen.get_unit("prince_restored")["mechanics"][1]["id"]), "spell_discount")
	assert_false(Pass3BogText.is_native(frozen.get_unit("bridge_toad")))
	assert_false(Pass3Text._is_pass3(frozen.get_unit("mr_redbreast")))
	for id: String in PROTOTYPES:
		assert_true(frozen.get_unit(id)["pool"], id + " remains in archived regressions")
	var data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass2_bog_units.json")
	)
	var archived_units: Array = data["units"]
	assert_eq(archived_units.size(), 23, "archive includes the original five prototypes")


func test_court_and_swamp_line_json_keeps_synthesis_priorities_and_policies() -> void:
	var lines: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tools/sim/lines/bog.json")
	)
	for line_name: String in ["bog_court", "bog_swamp"]:
		var line: Dictionary = lines[line_name]
		assert_eq(str(line["tribe"]), "bog")
		assert_eq(
			str(line["base_strategy"]), "bog_tongues" if line_name == "bog_court" else "bog_bitter"
		)
		assert_eq(str(line["kind"]), "engine_carry" if line_name == "bog_court" else "tempo")
		var priority: Array = line["priority"]
		var climb: Dictionary = line["climb"]
		var saving: Array = line["save"]
		var placement: Array = line["placement"]
		assert_eq(priority.size(), 16)
		assert_eq(climb.size(), 5)
		assert_false(saving.is_empty())
		assert_false(placement.is_empty())
	var hold: Dictionary = lines["bog_court"]["hold"]
	assert_true(hold.has("his_highness"))


func test_capstone_toll_dial_updates_normal_and_golden_faces_and_reader() -> void:
	for id: String in ["prima_donna", "jenny_greenteeth", "peat_king", "lantern_man"]:
		var ordinary: Dictionary = _card(id)
		assert_false(str(ordinary["text"]).contains("When played"))
		config.set_value("bog_capstone_gain_toll", true)
		var enabled: Dictionary = _card(id)
		for field: String in ["text", "golden_text"]:
			assert_true(str(enabled[field]).begins_with("When played: gain the Toll. "), id)
			assert_eq(str(enabled[field]).count("When played"), 1)
			assert_lte(str(enabled[field]).split(" ", false).size(), 22)
		for field: String in ["details", "golden_details"]:
			assert_string_contains(
				enabled[field], "permanently gain +Attack/+Health equal to the Toll"
			)
			assert_string_contains(enabled[field], "golden gains the same amount")
		config.set_value("bog_capstone_gain_toll", false)
		assert_eq(_card(id)["text"], ordinary["text"])
	config.set_value("bog_capstone_gain_toll", true)
	assert_false(str(_card("tiddy_mun")["text"]).contains("When played"))


func test_frog_and_tiddy_faces_match_the_accepted_any_unit_scope() -> void:
	var expected: Dictionary = {
		"his_highness":
		"Snap. Every third kiss: double the units beside this. First time: become the Prince.",
		"prince_restored": "Mire. Soak. Every third kiss: double the units beside this.",
		"tiddy_mun": "Start of Turn: the units beside this split half the Toll.",
	}
	for id: String in expected:
		assert_eq(_raw(id)["text"], expected[id])
		assert_eq(Pass3Text.face(_raw(id), config), expected[id])
		assert_false(str(_card(id)["golden_text"]).contains("Bog folk beside this"))
	assert_string_contains(_card("tiddy_mun")["details"], "occupied units")
	assert_string_contains(_card("natterjack_chorus")["text"], "Bog folk beside this")


func test_generated_default_rulings_are_delivered_to_normal_and_golden_views() -> void:
	var card: Dictionary = _raw("bridge_toad")
	Pass3BogText.configure(card, config)
	var normal: Dictionary = {}
	var golden: Dictionary = {}
	UnitLibrary.add_configured_rulings(normal, card)
	UnitLibrary.add_configured_rulings(golden, card, true)
	assert_string_contains(normal["configured_details"], "+2/+2")
	assert_string_contains(golden["configured_details"], "+4/+4")
	assert_string_contains(normal["configured_details"], "next Start of Turn")
	assert_eq(normal["configured_details"], card["details"])
	assert_eq(golden["configured_details"], card["golden_details"])
