extends GutTest

const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const Views := preload("res://src/ui/unit_views.gd")


func test_burner_explains_the_bank_or_buy_choice_for_normal_and_golden() -> void:
	var library: UnitLibrary = TestLibraries.current()
	var definition: Dictionary = library.get_unit("charcoal_burner")
	for golden: bool in [false, true]:
		var view: Dictionary = Views.from_def(definition, golden)
		var detail := CardDetail.new()
		add_child_autofree(detail)
		detail.size = Vector2(620, 1000)
		detail.show_unit(view)
		var notes: RichTextLabel = detail.get("_notes")
		assert_string_contains(notes.text, "[url=kw:Details]")
		assert_false(notes.text.contains("Keep 11 gold"))
		assert_false(notes.text.contains("Keep 17 gold"))
		assert_false(detail.reminder.visible, "worked examples stay behind Details until asked")
		notes.meta_hover_started.emit("kw:Details")
		assert_true(detail.reminder.visible, "the reader exposes the worked example")
		assert_eq(detail.reminder.keyword, "Details")
		var reminder_text: RichTextLabel = detail.reminder.get("_text")
		var text: String = reminder_text.get_parsed_text()
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
	var details: String = CardDetail.reminder_for("Details", {"def_id": "other", "text": ""})
	assert_false(details.contains("Keep 11 gold"))
	assert_false(details.contains("Keep 17 gold"))
