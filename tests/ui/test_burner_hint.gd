extends GutTest

const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const Views := preload("res://src/ui/unit_views.gd")


func test_burner_explains_the_bank_or_buy_choice_for_normal_and_golden() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	var definition: Dictionary = library.get_unit("charcoal_burner")
	for golden: bool in [false, true]:
		var text: String = CardDetail.full_text_bbcode(Views.from_def(definition, golden))
		assert_string_contains(
			text, "Keep 17 gold to burn 12" if golden else "Keep 11 gold to burn 6"
		)
		assert_string_contains(
			text,
			"+6/+6 permanently; 5 gold remains" if golden else "+3/+3 permanently; 5 gold remains"
		)
		assert_string_contains(text, "spend that gold on a better buy")
		assert_string_contains(text, "F2 and F3 can reach two units behind")


func test_the_burner_example_is_card_local() -> void:
	var text: String = CardDetail.full_text_bbcode({"def_id": "other", "text": "No special rules."})
	assert_false(text.contains("Keep 11 gold"))
