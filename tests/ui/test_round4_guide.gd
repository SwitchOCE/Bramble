extends GutTest

const Guide := preload("res://src/ui/screens/how_to_play.gd")


func test_core_loop_precedes_card_keywords_and_covers_the_economy() -> void:
	var words: String = ""
	for index: int in 5:
		words += str(Guide.PAGES[index]["text"]).to_lower()
	for needed: String in [
		"3 gold",
		"4, 5",
		"10",
		"carries over",
		"tier up",
		"refresh",
		"freeze",
		"sell",
		"hero",
		"spells",
		"permanent",
		"golden",
		"discover"
	]:
		assert_true(needed in words, needed)
	assert_lte(Guide.PAGES.size(), 12, "core loop plus the tribe and travel examples")


func test_guide_pages_fit_the_phone_canvas() -> void:
	var guide: Guide = Guide.new()
	guide.set_anchors_preset(Control.PRESET_TOP_LEFT)
	guide.size = Vector2(2337, 1080)
	add_child_autofree(guide)
	guide._layout()
	for index: int in Guide.PAGES.size():
		guide.page = index
		guide._show_page()
		await get_tree().process_frame
		var body: Label = guide.get("_text")
		assert_lte(body.get_minimum_size().y, body.size.y, "page %d body" % index)
		var demo: Control = guide.get("_demo")
		for child: Node in demo.get_children():
			if child is Control:
				assert_lte(
					(child as Control).position.y + (child as Control).size.y,
					demo.size.y + 1,
					"page %d example" % index
				)
