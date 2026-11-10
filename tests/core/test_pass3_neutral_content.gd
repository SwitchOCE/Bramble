extends GutTest
## Fixed authored faces, bodies and live sweep parameters; six cached raw definitions, no games.
@warning_ignore_start("unsafe_call_argument")

const BODIES: Dictionary = {
	"ballooning_spider": [3, 4, 3],
	"charcoal_burner": [4, 4, 6],
	"whirligig_beetle": [6, 6, 8],
	"shieldbug": [3, 2, 5],
	"click_beetle": [5, 3, 7],
	"pipistrelle_echo": [5, 3, 6],
}
const FACES: Dictionary = {
	"ballooning_spider":
	[
		"The units behind this have Swoop.",
		"The units behind this have Swoop.",
	],
	"charcoal_burner":
	[
		(
			"End of Turn: burn up to 6 of your gold above 5. The units behind this gain "
			+ "a twentieth of their stats per gold."
		),
		(
			"End of Turn: burn up to 12 of your gold above 5. The units behind this gain "
			+ "a twentieth of their stats per gold."
		),
	],
	"whirligig_beetle":
	[
		(
			"Start of Combat: swap enemy rows without improving Rings. "
			+ "Each enemy moved loses a tenth of its Health."
		),
		(
			"Start of Combat: swap enemy rows without improving Rings. "
			+ "Each enemy moved loses a fifth of its Health."
		),
	],
	"shieldbug":
	[
		"Start of Combat: give the units behind this Shield.",
		"Start of Combat: give the units behind this Shield.",
	],
	"click_beetle":
	[
		"Your When played effects trigger twice.",
		"Your When played effects trigger three times.",
	],
}
var authored: Dictionary = {}
var config: GameConfig


func before_all() -> void:
	for id: String in BODIES:
		var card: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://content/units/" + id + ".json")
		)
		authored[id] = card


func before_each() -> void:
	config = GameConfig.full_game()
	config.set_value("pass3_preset", "B")


func _card(id: String) -> Dictionary:
	var source: Dictionary = authored[id]
	return source.duplicate(true)


func _configured(id: String) -> Dictionary:
	var card: Dictionary = _card(id)
	Pass3Text.configure(card, config)
	return card


func _native(card: Dictionary, golden: bool = false) -> Dictionary:
	for entry: Dictionary in card["mechanics"]:
		if str(entry["id"]) == "pass3_neutral":
			return MechanicRegistry.params_for(entry, golden)
	return {}


func test_authored_normal_and_golden_faces_match_fixed_b_and_independent_generation() -> void:
	for id: String in FACES:
		var raw: Dictionary = _card(id)
		var configured: Dictionary = _configured(id)
		for golden: bool in [false, true]:
			var field: String = "golden_text" if golden else "text"
			var expected: String = str(FACES[id][1 if golden else 0])
			assert_eq(raw[field], expected, id + " authored " + field)
			raw[field] = "Stale authored face must never influence generation."
			assert_eq(Pass3Text.face(raw, config, golden), expected, id + " generated " + field)
			assert_eq(configured[field], expected, id + " configured " + field)
			assert_eq(CoreUtil.to_int(_native(configured, golden)["factor"]), 2 if golden else 1)


func test_all_six_keep_expected_tiers_bodies_and_golden_double_bodies() -> void:
	for id: String in BODIES:
		var card: Dictionary = _card(id)
		var expected: Array = BODIES[id]
		assert_eq(CoreUtil.to_int(card["tier"]), expected[0], id)
		assert_true(card["pool"], id + " stays in the shop pool")
		assert_eq(card["tribes"], [], id + " is neutral")
		for golden: bool in [false, true]:
			var unit: RecruitUnit = RecruitUnit.make(card, 1, golden)
			var factor: int = 2 if golden else 1
			assert_eq(unit.base_attack_now(), CoreUtil.to_int(expected[1]) * factor, id)
			assert_eq(unit.base_health_now(), CoreUtil.to_int(expected[2]) * factor, id)
		if id != "pipistrelle_echo":
			assert_eq(card["mechanics"].size(), 1, id + " has one native ability")
			assert_eq(_native(card)["ability"], id)


func test_burner_live_dials_change_both_faces_and_preserve_static_share_on_golden() -> void:
	config.set_value("neutrals_burner_cap", 4)
	config.set_value("neutrals_burner_above", 3)
	config.set_value("neutrals_burner_share", 0.1)
	var card: Dictionary = _configured("charcoal_burner")
	for golden: bool in [false, true]:
		var face: String = str(card["golden_text" if golden else "text"])
		assert_string_contains(face, "up to 8" if golden else "up to 4")
		assert_string_contains(face, "above 3")
		assert_string_contains(face, "a tenth of their stats per gold")
		var entry: Dictionary = _native(card, golden)
		assert_eq(CoreUtil.to_int(entry["cap"]), 4)
		assert_eq(CoreUtil.to_int(entry["above"]), 3)
		assert_eq(CoreUtil.to_float(entry["share"]), 0.1)
		assert_eq(CoreUtil.to_int(entry["factor"]), 2 if golden else 1)


func test_click_normal_and_golden_repeat_dials_change_independently() -> void:
	config.set_value("neutrals_click_repeats", 4)
	var card: Dictionary = _configured("click_beetle")
	assert_eq(card["text"], "Your When played effects trigger four times.")
	assert_eq(card["golden_text"], "Your When played effects trigger three times.")
	config.set_value("neutrals_golden_click_repeats", 5)
	card = _configured("click_beetle")
	assert_eq(card["text"], "Your When played effects trigger four times.")
	assert_eq(card["golden_text"], "Your When played effects trigger five times.")
	for golden: bool in [false, true]:
		var entry: Dictionary = _native(card, golden)
		assert_eq(CoreUtil.to_int(entry["repeats"]), 4)
		assert_eq(CoreUtil.to_int(entry["golden_repeats"]), 5)
		assert_eq(CoreUtil.to_int(entry["factor"]), 2 if golden else 1)


func test_whirligig_normal_and_golden_share_dials_change_independently() -> void:
	config.set_value("neutrals_whirligig_health_share", 0.25)
	var card: Dictionary = _configured("whirligig_beetle")
	assert_string_contains(card["text"], "a quarter of its Health")
	assert_string_contains(card["golden_text"], "a fifth of its Health")
	config.set_value("neutrals_golden_whirligig_health_share", 0.5)
	card = _configured("whirligig_beetle")
	assert_string_contains(card["text"], "a quarter of its Health")
	assert_string_contains(card["golden_text"], "half of its Health")
	for golden: bool in [false, true]:
		var entry: Dictionary = _native(card, golden)
		assert_eq(CoreUtil.to_float(entry["health_share"]), 0.25)
		assert_eq(CoreUtil.to_float(entry["golden_health_share"]), 0.5)
		assert_eq(CoreUtil.to_int(entry["factor"]), 2 if golden else 1)


func test_retained_echo_keeps_its_existing_text_mechanic_and_b_c_spell_scaling() -> void:
	for preset: String in ["B", "C"]:
		config.set_value("pass3_preset", preset)
		var card: Dictionary = _configured("pipistrelle_echo")
		assert_false(
			Pass3NeutralText.is_native(card), "Echo retains its original scaling-ready rule"
		)
		assert_eq(card["mechanics"], [{"id": "echo"}])
		for golden: bool in [false, true]:
			assert_eq(
				card["golden_text" if golden else "text"],
				"Spells you aim at this also hit the units beside it."
			)
		assert_eq(
			Pass3Rates.integer(config, "scale_hero_spell_percent"), 20 if preset == "C" else 10
		)


func test_uncapped_burner_survives_registration_and_grows_small_bodies() -> void:
	config.set_value("card_size_caps", false)
	var library := UnitLibrary.new()
	for id: String in ["charcoal_burner", "shieldbug"]:
		assert_eq(library.register_unit(authored[id]), "")
	var configured: UnitLibrary = ScaleOverlay.library_for(library, config)
	var card: Dictionary = configured.get_unit("charcoal_burner")
	assert_false(str(card["text"]).contains("up to"))
	var player := PlayerState.new()
	player.board[1] = RecruitUnit.make(card, 1)
	player.board[4] = RecruitUnit.make(configured.get_unit("shieldbug"), 2)
	assert_eq(BotBurner.forecast(player, 101), 33.0)
