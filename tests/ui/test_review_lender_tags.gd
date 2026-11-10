extends GutTest
## Compact Hunter tags follow current abilities; archived lenders retain their Quarry tags.

const CardView := preload("res://src/ui/widgets/card_view.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")
const LEGACY := preload("res://tests/core/legacy_hunters.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const LENDERS: PackedStringArray = ["young_brock", "old_brock", "laird_of_sett"]


func test_legacy_plain_and_golden_lenders_keep_their_quarry_keyword() -> void:
	var library: UnitLibrary = LEGACY.library()
	for id: String in LENDERS:
		for golden: bool in [false, true]:
			var view: Dictionary = UnitViews.from_def(library.get_unit(id), golden)
			assert_eq(CardView.chip_text(view), "Quarry", "%s, golden=%s" % [id, golden])
			assert_true(KeywordRules.named_on(view).has("Quarry"), "the tag has a rules reminder")


func test_legacy_lender_board_tiles_keep_their_quarry_tag() -> void:
	var library: UnitLibrary = LEGACY.library()
	for id: String in LENDERS:
		var card: CardView = CardView.new()
		add_child_autofree(card)
		card.show_unit(UnitViews.from_def(library.get_unit(id)), CardView.Mode.BOARD)
		card.set_card_width(162)
		assert_eq(card.chip_shown, "Quarry", id)
		assert_false(card.rules_shown, "the keyword names the long lender ability")


func test_a_card_without_a_keyword_keeps_its_existing_action_tag() -> void:
	assert_eq(CardView.chip_text({"text": "After this attacks, get an Acorn."}), "Acorns")


func test_native_hunter_tags_name_the_current_plain_and_golden_abilities() -> void:
	var library: UnitLibrary = ScaleOverlay.library_for(
		TestLibraries.current(), GameConfig.full_game()
	)
	var expected: Dictionary = {
		"young_brock": ["Sale growth", "Sale growth"],
		"lodger": ["Take growth", "Take growth"],
		"madame_ermeline": ["Pelt", "Pelt"],
		"old_brock": ["Quarry", "Quarry"],
		"laird_of_sett": ["Take twice", "Take 3 times"],
	}
	for id: String in expected:
		var tags: Array = expected[id]
		for golden: bool in [false, true]:
			var view: Dictionary = UnitViews.from_def(library.get_unit(id), golden)
			var tag: String = CardView.chip_text(view)
			var expected_tag: String = str(tags[1 if golden else 0])
			assert_eq(tag, expected_tag, id)
			assert_lte(tag.length(), 16, "the existing board tag stays compact")
			var card: CardView = CardView.new()
			add_child_autofree(card)
			card.show_unit(view, CardView.Mode.BOARD)
			card.set_card_width(162)
			assert_eq(card.chip_shown, tag, id + " board tile")
			assert_false(
				CardDetail.reminder_for("Details", view).is_empty(),
				"full rulings stay in the reader"
			)


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


func test_action_tags_follow_changed_or_borrowed_rules_without_using_card_identity() -> void:
	assert_eq(
		CardView.chip_text({"def_id": "field_vole", "text": "Your 'Take:' text triggers once."}),
		"Take once"
	)
	assert_eq(
		CardView.chip_text({"def_id": "laird_of_sett", "text": "When played: get 1 gold."}),
		"On play"
	)
	assert_eq(
		CardView.chip_text({"text": "After each fight: get two Pelts of your biggest quarry."}),
		"Pelt"
	)
