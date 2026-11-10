extends GutTest
## Compact Hunter tags follow current abilities; archived lenders retain their Quarry tags.

const CombatFace := preload("res://src/ui/widgets/combat_face.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")
const LEGACY := preload("res://tests/core/legacy_hunters.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const LENDERS: PackedStringArray = ["young_brock", "old_brock", "laird_of_sett"]


func test_legacy_plain_and_golden_lenders_keep_quarry_in_the_reader() -> void:
	var library: UnitLibrary = LEGACY.library()
	for id: String in LENDERS:
		for golden: bool in [false, true]:
			var view: Dictionary = UnitViews.from_def(library.get_unit(id), golden)
			assert_eq(CardView.chip_text(view), "")
			assert_true(KeywordRules.named_on(view).has("Quarry"))
			assert_string_contains(CardDetail.full_text_bbcode(view), "Quarry")


func test_native_hunter_faces_use_the_reader_for_current_and_golden_abilities() -> void:
	var library: UnitLibrary = ScaleOverlay.library_for(
		TestLibraries.current(), GameConfig.full_game()
	)
	for id: String in ["young_brock", "lodger", "madame_ermeline", "old_brock", "laird_of_sett"]:
		for golden: bool in [false, true]:
			var view: Dictionary = UnitViews.from_def(library.get_unit(id), golden)
			var card := CardView.new()
			add_child_autofree(card)
			card.show_unit(view, CardView.Mode.BOARD)
			card.set_card_width(162)
			assert_eq(card.chip_shown, "", id)
			assert_false(card.rules_shown)
			assert_false(CardDetail.full_text_bbcode(view).is_empty(), id)


func test_native_lent_hunts_use_the_existing_quarry_reader_reminder() -> void:
	var library: UnitLibrary = TestLibraries.current()
	for id: String in ["old_brock", "old_isegrim"]:
		for golden: bool in [false, true]:
			var view: Dictionary = UnitViews.from_def(library.get_unit(id), golden)
			assert_true(KeywordRules.named_on(view).has("Quarry"), id)
	assert_false(
		KeywordRules.named_on({"text": "Hunters grow."}).has("Quarry"),
		"a tribe name is not a Hunt instruction"
	)


func test_borrowed_trigger_marks_follow_current_rules_without_card_identity() -> void:
	assert_eq(
		CombatFace.recruit_trigger_kind(
			{"def_id": "field_vole", "text": "After this attacks: get an Acorn."}
		),
		"spark"
	)
	assert_eq(
		CombatFace.recruit_trigger_kind(
			{"def_id": "laird_of_sett", "text": "When played: get 1 gold."}
		),
		""
	)
	assert_eq(CombatFace.recruit_trigger_kind({"text": "End of Turn: get a Pelt."}), "spark")
