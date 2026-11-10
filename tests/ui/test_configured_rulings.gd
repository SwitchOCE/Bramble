extends GutTest
## The existing Details tap reads the configured rules before any effect has fired.
@warning_ignore_start("unsafe_call_argument")

const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardRulings := preload("res://src/ui/card_rulings.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")


func _open_details(view: Dictionary) -> String:
	var reader := CardDetail.new()
	add_child_autofree(reader)
	reader.show_unit(view)
	var notes: RichTextLabel = reader.get("_notes")
	assert_string_contains(
		notes.text, "[url=kw:Details]", "the existing reader offers its Details tap"
	)
	var slip: Control = reader.get("reminder")
	slip.call("_on_clicked", "kw:Details")
	assert_true(slip.visible)
	var words: RichTextLabel = slip.get("_text")
	return words.text


func test_spell_details_tap_uses_configured_percentage_without_stale_or_duplicate_rules() -> void:
	var config := GameConfig.full_game()
	config.set_value("scale_hero_spell_percent", 25)
	var library: UnitLibrary = ScaleOverlay.library_for(TestLibraries.current(), config)
	var item := HandItem.make(library.get_card("harvest_supper"), 1)
	var view: Dictionary = item.view()
	var words: String = _open_details(view)
	assert_string_contains(words, "25%")
	assert_string_contains(words, "lower of your board's average Attack and Health")
	assert_eq(words.count("Units summoned in fights don't get it."), 1)
	assert_false(words.contains("10%"))
	assert_false(view.has("pending_attack"), "the ruling is available before a reward exists")


func test_take_and_bite_timing_reach_recruit_and_combat_readers_before_a_reward() -> void:
	var library: UnitLibrary = ScaleOverlay.library_for(
		TestLibraries.current(), GameConfig.full_game()
	)
	for id: String in ["little_nip", "bridge_toad"]:
		for golden: bool in [false, true]:
			var definition: Dictionary = library.get_unit(id)
			var recruit := RecruitUnit.make(definition, 1, golden)
			var views: Array[Dictionary] = [
				recruit.view(),
				CombatUnit.make(definition, recruit.combat_spec(), 1, 0).view(),
				UnitViews.from_def(definition, golden),
			]
			for view: Dictionary in views:
				assert_false(view.has("pending_attack"))
				assert_false(view.has("pending_health"))
				var words: String = _open_details(view)
				assert_string_contains(words, "next Start of Turn", id)
				assert_eq(
					words.count("next Start of Turn"),
					1,
					"golden fallback does not duplicate rulings"
				)


func test_unchanged_cards_keep_their_exact_view_shape_and_raw_ruling_fallback() -> void:
	var source := TestLibraries.current()
	var configured: UnitLibrary = ScaleOverlay.library_for(source, GameConfig.full_game())
	var raw: Dictionary = source.get_unit("field_vole")
	var changed: Dictionary = configured.get_unit("field_vole")
	var recruit := RecruitUnit.make(changed, 1)
	assert_false(recruit.view().has("configured_details"))
	assert_eq(recruit.view(), RecruitUnit.make(raw, 1).view())
	assert_eq(CombatUnit.make(changed, {}, 1, 0).view(), CombatUnit.make(raw, {}, 1, 0).view())
	var dynamic: Dictionary = {"def_id": "harvest_supper", "details": "Current state."}
	assert_string_contains(CardRulings.for_view(dynamic), "Current state.")
	assert_string_contains(CardRulings.for_view(dynamic), "Units summoned in fights don't get it.")


func test_configured_golden_details_override_raw_with_dynamic_details_retained_once() -> void:
	var source: Dictionary = {
		"id": "custom", "details": "Normal source.", "golden_details": "Golden source."
	}
	var card: Dictionary = source.duplicate(true)
	card["configured_rulings"] = {"golden_details": "Configured golden."}
	var view: Dictionary = {"def_id": "custom", "golden": true, "details": "Current state."}
	UnitLibrary.add_configured_rulings(view, card, true)
	assert_eq(CardRulings.for_view(view), "Current state. Configured golden.")
	view["details"] = "Configured golden."
	assert_eq(
		CardRulings.for_view(view), "Configured golden.", "identical dynamic details appear once"
	)
	var normal: Dictionary = {}
	UnitLibrary.add_configured_rulings(normal, card, false)
	assert_false(normal.has("configured_details"), "normal rules were not changed")


func test_hero_session_and_recruit_view_keep_configured_reader_rules() -> void:
	var config := GameConfig.full_game()
	config.set_value("scale_hero_spell_percent", 25)
	var library: UnitLibrary = ScaleOverlay.library_for(TestLibraries.current(), config)
	var hero: Dictionary = GameSession._hero_card(library.get_hero("brother_bracken"))
	var view: Dictionary = RecruitView.hero_card(hero)
	var words: String = _open_details(view)
	assert_string_contains(words, "25%")
	assert_string_contains(words, "recipient's corresponding stat")
	assert_false(words.contains("10%"))
	var unchanged: Dictionary = GameSession._hero_card(library.get_hero("dame_hoolet"))
	assert_false(unchanged.has("configured_details"))
	assert_false(RecruitView.hero_card(unchanged).has("configured_details"))


func test_short_scaled_faces_leave_formula_minima_and_caps_in_phone_details() -> void:
	CardView.window_override = Vector2(1688, 780)
	for rate: int in [10, 25]:
		var config := GameConfig.full_game()
		config.set_value("scale_hero_spell_percent", rate)
		var library: UnitLibrary = ScaleOverlay.library_for(TestLibraries.current(), config)
		var views: Array[Dictionary] = []
		for id: String in ["brother_bracken", "old_mother_mousewife"]:
			views.append(RecruitView.hero_card(GameSession._hero_card(library.get_hero(id))))
		for id: String in ["harvest_supper", "elderflower_cordial"]:
			views.append(HandItem.make(library.get_card(id), 1).view())
		for view: Dictionary in views:
			var face: String = view["text"]
			assert_false(face.contains("minimum"), face)
			assert_false(face.contains("up to"), face)
			assert_lte(face.length(), 125, face)
			assert_lte(face.split(" ", false).size(), 22, face)
			var words: String = _open_details(view)
			assert_string_contains(words, "%d%%" % rate)
			assert_string_contains(words, "minimum")
			if view["def_id"] == "brother_bracken":
				assert_string_contains(words, "up to +5/+5")
			if view["def_id"] == "elderflower_cordial":
				assert_string_contains(words, "+1/+2 in the front row")
				assert_string_contains(words, "+2/+1 in the back row")
	CardView.window_override = Vector2.ZERO
