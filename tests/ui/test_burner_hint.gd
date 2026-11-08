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
			"units behind gain +6/+6; 5 remains" if golden else "units behind gain +3/+3; 5 remains"
		)


func test_the_burner_example_is_card_local() -> void:
	var text: String = CardDetail.full_text_bbcode({"def_id": "other", "text": "No special rules."})
	assert_false(text.contains("Keep 11 gold"))
