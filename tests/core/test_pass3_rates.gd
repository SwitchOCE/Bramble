extends GutTest
@warning_ignore_start("unsafe_call_argument")
## A harness rate sweep changes both rules and the words a player reads.

var library: UnitLibrary
var config: GameConfig


func before_each() -> void:
	library = UnitLibrary.load_dir()
	config = GameConfig.defaults()


func _card(id: String) -> Dictionary:
	var raw: Dictionary = library.get_unit(id)
	if raw.is_empty():
		raw = library.get_card(id)
	var card: Dictionary = raw.duplicate(true)
	Pass3Text.configure(card, config)
	return card


func test_authored_defaults_are_preserved_exactly() -> void:
	for raw: Dictionary in library.all_units() + library.all_cards():
		var card: Dictionary = raw.duplicate(true)
		Pass3Text.configure(card, config)
		assert_eq(card, raw, str(raw.get("id", "")))


func test_proportional_rates_and_permanence_change_the_display() -> void:
	config.set_value("birds_redbreast_share", 0.2)
	config.set_value("birds_cuckoo_share", 0.15)
	config.set_value("birds_jack_daw_share", 0.3)
	config.set_value("birds_jack_daw_permanent", false)
	assert_string_contains(_card("mr_redbreast")["text"], "20%")
	assert_string_contains(_card("mr_redbreast")["golden_text"], "40%")
	assert_string_contains(_card("cuckoo")["golden_text"], "30%")
	assert_string_contains(_card("jack_daw")["text"], "30%")
	assert_false(str(_card("jack_daw")["text"]).contains("permanently"))


func test_flight_reminders_distinguish_swallow_and_golden_tern() -> void:
	config.set_value("birds_trip_turns", 4)
	config.set_value("birds_swallow_trip_turns", 2)
	config.set_value("birds_golden_tern_trip_turns", 3)
	config.set_value("birds_homecoming_multiplier", 1.75)
	config.set_value("birds_golden_homecoming_multiplier", 2.5)
	var swallow: Dictionary = _card("one_swallow")
	var tern: Dictionary = _card("old_tern")
	assert_string_contains(swallow["details"], "2 turns")
	assert_string_contains(tern["details"], "4 turns")
	assert_string_contains(tern["golden_details"], "3 turns")
	assert_string_contains(tern["details"], "1.75×")
	assert_string_contains(tern["golden_details"], "2.5×")
	assert_string_contains(tern["details"], "missed fight")
	for entry: Dictionary in swallow["keyword_text"]:
		if entry["keyword"] == "Fly South":
			assert_string_contains(entry["text"], "2 turns")
			assert_false(str(entry["text"]).contains("double"))


func test_ring_growth_copy_and_countdown_rates_are_visible() -> void:
	config.set_value("fairies_ring_growth", 0.5)
	config.set_value("fairies_fetch_share", 0.75)
	config.set_value("fairies_monarch_period", 2)
	config.set_value("fairies_monarch_multiplier", 1.5)
	config.set_value("fairies_golden_monarch_multiplier", 2.5)
	assert_string_contains(_card("cluricaun")["text"], "+0.5/+0.5")
	assert_string_contains(_card("cluricaun")["golden_text"], "+1/+1")
	assert_string_contains(_card("cradle_fetch")["text"], "75%")
	assert_string_contains(_card("fairy_monarch")["text"], "Every 2nd End of Turn")
	assert_string_contains(_card("fairy_monarch")["text"], "1.5")
	assert_string_contains(_card("fairy_monarch")["golden_text"], "2.5")


func test_counts_and_other_named_rates_remain_readable_in_sweeps() -> void:
	for sample: Array in [
		["birds_stork_gold_step", 8, "mrs_stork", "8 gold"],
		["birds_stork_recalls", 2, "mrs_stork", "2 Birds"],
		["birds_dunnock_turns", 2, "mrs_dunnock", "2 turns"],
		["birds_dunnock_targets", 2, "mrs_dunnock", "2 biggest Birds"],
		["birds_golden_egg_multiplier", 3, "golden_egg", "by 3"],
		["birds_tom_tit_reduction", 25, "tom_tit", "25%"],
		["birds_lump_multiplier", 1.5, "great_lump", "1.5 times"],
		["birds_ratchet_multiplier", 1.5, "gabble_ratchet", "1.5 times"],
		["birds_whistlers_loss_share", 0.25, "seven_whistlers", "25%"],
		["fairies_lob_turns", 4, "lob_lie_by_the_fire", "4 turns"],
		["fairies_reel_moves", 3, "reel_mistress", "3 times per Ring"],
		["fairies_queen_period", 2, "queen_of_elfland", "Every 2nd"],
		["fairies_queen_rings", 2, "queen_of_elfland", "2 times"]
	]:
		config = GameConfig.defaults()
		config.set_value(str(sample[0]), sample[1])
		assert_string_contains(_card(str(sample[2]))["text"], str(sample[3]))


func test_sale_switch_removes_the_inactive_trigger_and_updates_borrowed_text() -> void:
	config.set_value("fairies_annis_sale", false)
	var annis: Dictionary = _card("old_moth_annis")
	assert_false(str(annis["text"]).contains("after you sell"))
	assert_string_contains(annis["text"], "End of Turn:")
	config.set_value("fairies_lob_growth", 2)
	var lob: Dictionary = _card("lob_lie_by_the_fire")
	assert_string_contains(lob["mechanic_text"]["1"]["text"], "+2/+2")
	assert_false(str(lob["mechanic_text"]["1"]["text"]).begins_with("Shy."))


func test_disabling_generic_limits_keeps_pass3_loop_guards_in_rate_text() -> void:
	config.set_value("card_rate_limits", false)
	config.set_value("birds_golden_egg_multiplier", 3)
	config.set_value("fairies_reel_moves", 3)
	assert_string_contains(_card("golden_egg")["text"], "Once per Bird.")
	assert_string_contains(_card("gabble_ratchet")["details"], "Once per Nest a fight.")
	assert_string_contains(_card("reel_mistress")["text"], "3 times per Ring.")
	assert_string_contains(_card("fairy_monarch")["details"], "Extra triggers never")


func test_private_library_applies_sweep_words_without_changing_source() -> void:
	config.set_value("birds_homecoming_multiplier", 1.75)
	config.set_value("birds_swallow_trip_turns", 3)
	config.set_value("fairies_ring_growth", 0.5)
	var swept: UnitLibrary = ScaleOverlay.library_for(library, config)
	assert_string_contains(swept.get_unit("cluricaun")["text"], "+0.5/+0.5")
	assert_string_contains(library.get_unit("cluricaun")["text"], "+0.25/+0.25")
	var swallow := RecruitUnit.make(swept.get_unit("one_swallow"), 1)
	assert_eq(swallow.flight_turns(), 3)
	for entry: Dictionary in swallow.view()["keyword_text"]:
		if entry["keyword"] == "Fly South":
			assert_string_contains(entry["text"], "3 turns")


func test_bench_selected_slice_pool_enables_pass3_content() -> void:
	config.set_value("pool_filter", "slice")
	assert_false(config.get_bool("pass3_content"))
	var rules := RecruitRules.create(library, config, UnitPool.create(library, config))
	var player := PlayerState.new()
	rules.setup_player(player)
	assert_true(config.get_bool("pass3_content"))
	assert_true(player.pass3_content)
	assert_true(player.pass3_fairies)


func test_disabled_golden_egg_creation_removes_goose_payoff_words() -> void:
	config.set_value("birds_golden_egg_enabled", false)
	assert_eq(_card("mother_goose")["text"], "Fly South.")
	assert_eq(_card("mother_goose")["golden_text"], "Fly South.")
