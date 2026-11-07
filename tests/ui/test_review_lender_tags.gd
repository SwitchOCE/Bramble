extends GutTest
## Review Ask 2: the bell's quarry lenders carry their existing keyword, rather than "At the".

const CardView := preload("res://src/ui/widgets/card_view.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")
const LENDERS: PackedStringArray = ["young_brock", "old_brock", "laird_of_sett"]


func test_plain_and_golden_lenders_show_their_existing_quarry_keyword() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	for id: String in LENDERS:
		for golden: bool in [false, true]:
			var view: Dictionary = UnitViews.from_def(library.get_unit(id), golden)
			assert_eq(CardView.chip_text(view), "Quarry", "%s, golden=%s" % [id, golden])
			assert_true(KeywordRules.named_on(view).has("Quarry"), "the tag has a rules reminder")


func test_lender_board_tiles_keep_the_keyword_when_the_full_rules_are_a_tap_away() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	for id: String in LENDERS:
		var card: CardView = CardView.new()
		add_child_autofree(card)
		card.show_unit(UnitViews.from_def(library.get_unit(id)), CardView.Mode.BOARD)
		card.set_card_width(162)
		assert_eq(card.chip_shown, "Quarry", id)
		assert_false(card.rules_shown, "the keyword names the long lender ability")


func test_a_card_without_a_keyword_keeps_its_existing_action_tag() -> void:
	assert_eq(CardView.chip_text({"text": "After this attacks, get an Acorn."}), "Acorns")
